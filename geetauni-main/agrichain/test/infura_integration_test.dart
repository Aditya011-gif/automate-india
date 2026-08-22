import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:agrichain/services/blockchain_service.dart';
import 'package:agrichain/config/app_config.dart';

void main() {
  group('Infura Integration Tests', () {
    test('should have valid Infura configuration', () {
      // Test that Infura project ID is configured and not a placeholder
      expect(AppConfig.infuraProjectId, isNotEmpty);
      expect(AppConfig.infuraProjectId, isNot('YOUR_INFURA_PROJECT_ID'));
      expect(AppConfig.infuraProjectId.length, greaterThan(10)); // Real Infura IDs are longer
      
      // Test that RPC URLs are properly formatted
      expect(AppConfig.ethereumMainnetUrl, contains('infura.io'));
      expect(AppConfig.polygonMainnetUrl, contains('infura.io'));
      expect(AppConfig.ethereumSepoliaUrl, contains('sepolia.infura.io'));
      expect(AppConfig.polygonMumbaiUrl, contains('polygon-mumbai.infura.io'));
      
      // Test that the project ID is included in RPC URLs
      expect(AppConfig.polygonMumbaiUrl, contains(AppConfig.infuraProjectId));
    });

    test('should select correct network based on environment', () {
      // Test network selection logic
      final currentRpcUrl = BlockchainService.currentRpcUrl;
      final currentChainId = BlockchainService.currentChainId;
      
      expect(currentRpcUrl, isNotEmpty);
      expect(currentChainId, greaterThan(0));
      
      if (kDebugMode) {
        // In debug mode, should use testnet
        expect(currentRpcUrl, contains('mumbai'));
        expect(currentChainId, equals(AppConfig.mumbaiChainId));
      } else {
        // In production mode, should use mainnet
        expect(currentRpcUrl, contains('polygon-mainnet'));
        expect(currentChainId, equals(AppConfig.polygonChainId));
      }
    });

    test('should provide complete network information', () {
      final networkInfo = BlockchainService.networkInfo;
      
      expect(networkInfo, isA<Map<String, dynamic>>());
      expect(networkInfo['rpcUrl'], isNotEmpty);
      expect(networkInfo['chainId'], isA<int>());
      expect(networkInfo['networkName'], isNotEmpty);
      expect(networkInfo['provider'], equals('Infura'));
      expect(networkInfo['isTestnet'], isA<bool>());
    });

    test('should connect to wallet with Infura configuration', () async {
      final walletConnection = await BlockchainService.connectWallet();
      
      expect(walletConnection['success'], isTrue);
      expect(walletConnection['address'], isNotEmpty);
      expect(walletConnection['balance'], isNotEmpty);
      expect(walletConnection['network'], isNotEmpty);
      expect(walletConnection['chainId'], isA<int>());
      expect(walletConnection['rpcUrl'], contains('infura.io'));
      expect(walletConnection['provider'], equals('Infura'));
      expect(walletConnection['isTestnet'], isA<bool>());
    });

    test('should test Infura connection successfully', () async {
      final connectionTest = await BlockchainService.testInfuraConnection();
      
      expect(connectionTest['success'], isTrue);
      expect(connectionTest['connected'], isTrue);
      expect(connectionTest['network'], isNotEmpty);
      expect(connectionTest['chainId'], isA<int>());
      expect(connectionTest['rpcUrl'], contains('infura.io'));
      expect(connectionTest['provider'], equals('Infura'));
      expect(connectionTest['latestBlock'], isA<int>());
      expect(connectionTest['gasPrice'], contains('Gwei'));
      expect(connectionTest['responseTime'], contains('ms'));
      expect(connectionTest['timestamp'], isNotEmpty);
    });

    test('should provide network configuration details', () {
      final networkConfig = BlockchainService.getNetworkConfig();
      
      expect(networkConfig, isA<Map<String, dynamic>>());
      expect(networkConfig['infuraProjectId'], contains('***')); // Should be masked
      expect(networkConfig['availableNetworks'], isA<Map<String, dynamic>>());
      expect(networkConfig['currentNetwork'], isA<Map<String, dynamic>>());
      expect(networkConfig['contractAddresses'], isA<Map<String, dynamic>>());
      
      // Test available networks structure
      final availableNetworks = networkConfig['availableNetworks'];
      expect(availableNetworks['ethereum'], isA<Map<String, dynamic>>());
      expect(availableNetworks['polygon'], isA<Map<String, dynamic>>());
      
      // Test Ethereum networks
      final ethereumNetworks = availableNetworks['ethereum'];
      expect(ethereumNetworks['mainnet'], contains('mainnet.infura.io'));
      expect(ethereumNetworks['sepolia'], contains('sepolia.infura.io'));
      expect(ethereumNetworks['goerli'], contains('goerli.infura.io'));
      
      // Test Polygon networks
      final polygonNetworks = availableNetworks['polygon'];
      expect(polygonNetworks['mainnet'], contains('polygon-mainnet.infura.io'));
      expect(polygonNetworks['mumbai'], contains('polygon-mumbai.infura.io'));
    });

    test('should handle NFT minting with network context', () async {
      final nftResult = await BlockchainService.mintCropNFT(
        cropName: 'Test Crop',
        farmerAddress: '0x742d35Cc6634C0532925a3b8D4C9db7f8e',
        ipfsHash: 'QmTestHash123',
        metadata: {
          'cropType': 'Wheat',
          'harvestDate': '2024-01-15',
          'location': 'Test Farm',
        },
      );
      
      expect(nftResult['success'], isTrue);
      expect(nftResult['tokenId'], isNotEmpty);
      expect(nftResult['transactionHash'], isNotEmpty);
      expect(nftResult['contractAddress'], isNotEmpty);
      expect(nftResult['ipfsHash'], equals('QmTestHash123'));
      expect(nftResult['gasUsed'], isNotEmpty);
      expect(nftResult['blockNumber'], isA<int>());
    });

    test('should validate chain IDs are correct', () {
      expect(AppConfig.ethereumChainId, equals(1));
      expect(AppConfig.polygonChainId, equals(137));
      expect(AppConfig.sepoliaChainId, equals(11155111));
      expect(AppConfig.mumbaiChainId, equals(80001));
    });

    test('should have proper timeout configuration', () {
      expect(AppConfig.blockchainTimeout, isA<Duration>());
      expect(AppConfig.blockchainTimeout.inSeconds, greaterThan(0));
    });
  });

  group('Infura Error Handling Tests', () {
    test('should handle connection test errors gracefully', () async {
      // This test simulates error handling in the connection test
      // In a real implementation, you might mock network failures
      final connectionTest = await BlockchainService.testInfuraConnection();
      
      // Should always return a valid response structure
      expect(connectionTest, isA<Map<String, dynamic>>());
      expect(connectionTest.containsKey('success'), isTrue);
      expect(connectionTest.containsKey('timestamp'), isTrue);
      
      if (!connectionTest['success']) {
        expect(connectionTest.containsKey('error'), isTrue);
        expect(connectionTest['connected'], isFalse);
      }
    });
  });

  group('Infura Security Tests', () {
    test('should mask sensitive information in network config', () {
      final networkConfig = BlockchainService.getNetworkConfig();
      final maskedProjectId = networkConfig['infuraProjectId'];
      
      // Should contain asterisks to mask the project ID
      expect(maskedProjectId, contains('***'));
      expect(maskedProjectId.length, lessThan(AppConfig.infuraProjectId.length));
    });

    test('should not expose project secret in configuration', () {
      final networkConfig = BlockchainService.getNetworkConfig();
      
      // Should not contain project secret
      expect(networkConfig.toString(), isNot(contains('secret')));
      expect(networkConfig.toString(), isNot(contains('Secret')));
    });
  });
}