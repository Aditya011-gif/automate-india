import 'dart:math';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class BlockchainService {
  // Network Configuration using Infura
  static String get ethereumRpcUrl => AppConfig.ethereumRpcUrl;
  static String get polygonRpcUrl => AppConfig.polygonRpcUrl;
  static String get ethereumSepoliaUrl => AppConfig.ethereumSepoliaUrl;
  static String get polygonMumbaiUrl => AppConfig.polygonMumbaiUrl;

  // Dynamic RPC URL selection based on environment
  static String get currentRpcUrl {
    if (kDebugMode) {
      // Use testnet for development
      return polygonMumbaiUrl; // Mumbai testnet via Infura
    } else {
      // Use mainnet for production
      return polygonRpcUrl; // Polygon mainnet via Infura
    }
  }

  // Chain ID configuration
  static int get currentChainId {
    if (kDebugMode) {
      return AppConfig.mumbaiChainId; // Mumbai testnet
    } else {
      return AppConfig.polygonChainId; // Polygon mainnet
    }
  }

  // Contract addresses
  static const String _nftContractAddress =
      '0x742d35Cc6634C0532925a3b8D4C9db7f8e';
  static const String _loanContractAddress =
      '0x9876543210abcdef1234567890abcdef12345678';
  static const String _marketplaceContractAddress =
      '0xabcdef1234567890abcdef1234567890abcdef12';

  // Network info
  static Map<String, dynamic> get networkInfo {
    return {
      'rpcUrl': currentRpcUrl,
      'chainId': currentChainId,
      'networkName': kDebugMode ? 'Polygon Mumbai Testnet' : 'Polygon Mainnet',
      'isTestnet': kDebugMode,
      'provider': 'Infura',
    };
  }

  // Instance methods for AddCropScreen
  Future<String> uploadImageToIPFS(String imagePath) async {
    await Future.delayed(const Duration(seconds: 2));
    return _generateIPFSHash();
  }

  Future<String> mintNFT(
    String owner,
    String name,
    String description,
    String ipfsHash,
  ) async {
    await Future.delayed(const Duration(seconds: 3));
    final tokenId = Random().nextInt(999999) + 100000;
    return 'NFT$tokenId';
  }

  Future<String> createSellOrder(
    String cropId,
    double price,
    String quantity,
    String nftTokenId,
  ) async {
    await Future.delayed(const Duration(seconds: 2));
    final orderId = Random().nextInt(999999) + 100000;
    return 'ORDER$orderId';
  }

  Future<String> submitLoanApplication(
    double amount,
    String collateralNFT,
    int termMonths,
  ) async {
    await Future.delayed(const Duration(seconds: 2));
    final loanId = Random().nextInt(999999) + 100000;
    return 'LOAN$loanId';
  }

  // Simulate wallet connection with Infura network configuration
  static Future<Map<String, dynamic>> connectWallet() async {
    await Future.delayed(const Duration(seconds: 2));

    final network = networkInfo;

    if (kDebugMode) {
      print('Connecting to blockchain via Infura:');
      print('RPC URL: ${network['rpcUrl']}');
      print('Chain ID: ${network['chainId']}');
      print('Network: ${network['networkName']}');
    }

    return {
      'success': true,
      'address': '0x742d35Cc6634C0532925a3b8D4C9db7f8e',
      'balance': kDebugMode ? '2.45' : '0.85', // Test MATIC vs real MATIC
      'network': network['networkName'],
      'chainId': network['chainId'],
      'rpcUrl': network['rpcUrl'],
      'provider': network['provider'],
      'isTestnet': network['isTestnet'],
    };
  }

  // Test Infura connectivity and network status
  static Future<Map<String, dynamic>> testInfuraConnection() async {
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate network call

      final network = networkInfo;

      if (kDebugMode) {
        print('Testing Infura connection...');
        print('RPC URL: ${network['rpcUrl']}');
        print('Chain ID: ${network['chainId']}');
      }

      // Simulate successful connection test
      final blockNumber = Random().nextInt(1000000) + 5000000;
      final gasPrice = (Random().nextDouble() * 50 + 10).toStringAsFixed(2);

      return {
        'success': true,
        'connected': true,
        'network': network['networkName'],
        'chainId': network['chainId'],
        'rpcUrl': network['rpcUrl'],
        'provider': network['provider'],
        'isTestnet': network['isTestnet'],
        'latestBlock': blockNumber,
        'gasPrice': '$gasPrice Gwei',
        'responseTime': '${Random().nextInt(500) + 100}ms',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'success': false,
        'connected': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Get current network configuration
  static Map<String, dynamic> getNetworkConfig() {
    return {
      'infuraProjectId': AppConfig.infuraProjectId.replaceRange(
        8,
        null,
        '***',
      ), // Hide most of the ID
      'availableNetworks': {
        'ethereum': {
          'mainnet': AppConfig.ethereumMainnetUrl,
          'sepolia': AppConfig.ethereumSepoliaUrl,
          'goerli': AppConfig.ethereumGoerliUrl,
        },
        'polygon': {
          'mainnet': AppConfig.polygonMainnetUrl,
          'mumbai': AppConfig.polygonMumbaiUrl,
        },
      },
      'currentNetwork': networkInfo,
      'contractAddresses': {
        'nft': _nftContractAddress,
        'loan': _loanContractAddress,
        'marketplace': _marketplaceContractAddress,
      },
    };
  }

  // Simulate NFT minting for crop certificates
  static Future<Map<String, dynamic>> mintCropNFT({
    required String cropName,
    required String farmerAddress,
    required String ipfsHash,
    required Map<String, dynamic> metadata,
  }) async {
    await Future.delayed(const Duration(seconds: 3));

    final tokenId = Random().nextInt(999999) + 100000;
    final transactionHash = _generateTransactionHash();

    return {
      'success': true,
      'tokenId': tokenId.toString(),
      'transactionHash': transactionHash,
      'contractAddress': _nftContractAddress,
      'ipfsHash': ipfsHash,
      'gasUsed': '0.0021',
      'blockNumber': Random().nextInt(1000000) + 5000000,
    };
  }

  // Simulate loan application on smart contract
  static Future<Map<String, dynamic>> applyForLoan({
    required String borrowerAddress,
    required double loanAmount,
    required String collateralNFTId,
    required int durationDays,
  }) async {
    await Future.delayed(const Duration(seconds: 4));

    final loanId = Random().nextInt(99999) + 10000;
    final transactionHash = _generateTransactionHash();
    final interestRate = 8.5 + (Random().nextDouble() * 3.0); // 8.5% - 11.5%

    return {
      'success': true,
      'loanId': loanId.toString(),
      'transactionHash': transactionHash,
      'contractAddress': _loanContractAddress,
      'interestRate': interestRate.toStringAsFixed(2),
      'collateralLocked': true,
      'gasUsed': '0.0035',
      'blockNumber': Random().nextInt(1000000) + 5000000,
    };
  }

  // Simulate loan repayment
  static Future<Map<String, dynamic>> repayLoan({
    required String loanId,
    required double amount,
    required String borrowerAddress,
  }) async {
    await Future.delayed(const Duration(seconds: 3));

    final transactionHash = _generateTransactionHash();

    return {
      'success': true,
      'loanId': loanId,
      'transactionHash': transactionHash,
      'amountPaid': amount,
      'collateralReleased': amount >= 1000, // Simulate full repayment
      'gasUsed': '0.0028',
      'blockNumber': Random().nextInt(1000000) + 5000000,
    };
  }

  // Simulate marketplace order on blockchain
  static Future<Map<String, dynamic>> createMarketplaceOrder({
    required String buyerAddress,
    required String sellerAddress,
    required String cropNFTId,
    required double amount,
    required int quantity,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    final orderId = Random().nextInt(999999) + 100000;
    final transactionHash = _generateTransactionHash();

    return {
      'success': true,
      'orderId': orderId.toString(),
      'transactionHash': transactionHash,
      'contractAddress': _marketplaceContractAddress,
      'escrowLocked': true,
      'gasUsed': '0.0025',
      'blockNumber': Random().nextInt(1000000) + 5000000,
    };
  }

  // Simulate order completion and payment release
  static Future<Map<String, dynamic>> completeOrder({
    required String orderId,
    required String buyerAddress,
    required String sellerAddress,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    final transactionHash = _generateTransactionHash();

    return {
      'success': true,
      'orderId': orderId,
      'transactionHash': transactionHash,
      'paymentReleased': true,
      'nftTransferred': true,
      'gasUsed': '0.0032',
      'blockNumber': Random().nextInt(1000000) + 5000000,
    };
  }

  // Simulate IPFS upload for crop images and metadata
  static Future<Map<String, dynamic>> uploadToIPFS({
    required String imagePath,
    required Map<String, dynamic> metadata,
  }) async {
    await Future.delayed(const Duration(seconds: 3));

    final ipfsHash = _generateIPFSHash();

    return {
      'success': true,
      'ipfsHash': ipfsHash,
      'gatewayUrl': 'https://ipfs.io/ipfs/$ipfsHash',
      'pinned': true,
      'size': '${Random().nextInt(500) + 100}KB',
    };
  }

  // Get transaction details
  static Future<Map<String, dynamic>> getTransactionDetails(
    String txHash,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    return {
      'hash': txHash,
      'status': 'confirmed',
      'blockNumber': Random().nextInt(1000000) + 5000000,
      'gasUsed': '0.00${Random().nextInt(50) + 15}',
      'timestamp': DateTime.now().subtract(
        Duration(minutes: Random().nextInt(60)),
      ),
      'confirmations': Random().nextInt(100) + 12,
    };
  }

  // Get NFT details
  static Future<Map<String, dynamic>> getNFTDetails(String tokenId) async {
    await Future.delayed(const Duration(seconds: 1));

    return {
      'tokenId': tokenId,
      'owner': '0x742d35Cc6634C0532925a3b8D4C9db7f8e',
      'contractAddress': _nftContractAddress,
      'metadata': {
        'name': 'Crop Certificate #$tokenId',
        'description': 'Digital certificate for organic crop verification',
        'image': 'https://ipfs.io/ipfs/${_generateIPFSHash()}',
        'attributes': [
          {'trait_type': 'Crop Type', 'value': 'Organic Wheat'},
          {'trait_type': 'Harvest Date', 'value': '2024-12-15'},
          {'trait_type': 'Location', 'value': 'Punjab, India'},
          {'trait_type': 'Quality Grade', 'value': 'A+'},
        ],
      },
      'transferHistory': [
        {
          'from': '0x0000000000000000000000000000000000000000',
          'to': '0x742d35Cc6634C0532925a3b8D4C9db7f8e',
          'timestamp': DateTime.now().subtract(const Duration(days: 5)),
          'txHash': _generateTransactionHash(),
        },
      ],
    };
  }

  // Simulate legal agreement signing and blockchain storage
  static Future<Map<String, dynamic>> signLegalAgreement({
    required String agreementType,
    required String agreementHash,
    required String signerAddress,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    final transactionHash = _generateTransactionHash();

    return {
      'success': true,
      'agreementType': agreementType,
      'agreementHash': agreementHash,
      'transactionHash': transactionHash,
      'timestamp': DateTime.now(),
      'signerAddress': signerAddress,
      'blockNumber': Random().nextInt(1000000) + 5000000,
      'gasUsed': '0.0018',
    };
  }

  // Get loan pool statistics
  static Future<Map<String, dynamic>> getLoanPoolStats() async {
    await Future.delayed(const Duration(seconds: 1));

    return {
      'totalPoolValue': 2500000.0, // ₹25,00,000
      'activeLoans': 156,
      'totalBorrowed': 1800000.0, // ₹18,00,000
      'averageAPR': 9.2,
      'defaultRate': 2.1,
      'totalCollateral': 2200000.0, // ₹22,00,000
      'availableForLending': 700000.0, // ₹7,00,000
    };
  }

  // Utility functions
  static String _generateTransactionHash() {
    const chars = '0123456789abcdef';
    final random = Random();
    return '0x${List.generate(64, (index) => chars[random.nextInt(chars.length)]).join()}';
  }

  static String _generateIPFSHash() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return 'Qm${List.generate(44, (index) => chars[random.nextInt(chars.length)]).join()}';
  }

  // Simulate gas estimation
  static Future<Map<String, dynamic>> estimateGas({
    required String operation,
    required Map<String, dynamic> parameters,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final gasEstimates = {
      'mintNFT': 85000,
      'applyLoan': 120000,
      'repayLoan': 95000,
      'createOrder': 75000,
      'completeOrder': 110000,
      'signAgreement': 65000,
    };

    final gasLimit = gasEstimates[operation] ?? 80000;
    final gasPrice = 20 + Random().nextInt(30); // 20-50 gwei
    final estimatedCost = (gasLimit * gasPrice) / 1e9; // Convert to MATIC

    return {
      'gasLimit': gasLimit,
      'gasPrice': '$gasPrice gwei',
      'estimatedCost': '${estimatedCost.toStringAsFixed(6)} MATIC',
      'estimatedCostUSD':
          '\$${(estimatedCost * 0.85).toStringAsFixed(4)}', // Assuming 1 MATIC = $0.85
    };
  }

  // Network status
  static Future<Map<String, dynamic>> getNetworkStatus() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return {
      'network': networkInfo['networkName'],
      'chainId': currentChainId,
      'blockNumber': Random().nextInt(1000000) + 5000000,
      'gasPrice': '${20 + Random().nextInt(30)} gwei',
      'isConnected': true,
      'rpcUrl': currentRpcUrl,
    };
  }

  // NFT Transfer Operations
  static Future<Map<String, dynamic>> transferNFT({
    required String tokenId,
    required String fromAddress,
    required String toAddress,
    required String nftType, // 'land' or 'crop'
  }) async {
    try {
      // Simulate blockchain NFT transfer
      await Future.delayed(const Duration(seconds: 2));

      final txHash =
          '0x${Random().nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0')}';

      return {
        'success': true,
        'transactionHash': txHash,
        'blockNumber': Random().nextInt(1000000) + 18000000,
        'gasUsed': Random().nextInt(50000) + 21000,
        'transferDetails': {
          'tokenId': tokenId,
          'from': fromAddress,
          'to': toAddress,
          'nftType': nftType,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}

// Data models for blockchain operations
class NFTMetadata {
  final String name;
  final String description;
  final String image;
  final List<NFTAttribute> attributes;

  NFTMetadata({
    required this.name,
    required this.description,
    required this.image,
    required this.attributes,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'image': image,
      'attributes': attributes.map((attr) => attr.toJson()).toList(),
    };
  }
}

class NFTAttribute {
  final String traitType;
  final String value;

  NFTAttribute({required this.traitType, required this.value});

  Map<String, dynamic> toJson() {
    return {'trait_type': traitType, 'value': value};
  }
}

class LoanTerms {
  final double amount;
  final double interestRate;
  final int durationDays;
  final String collateralNFTId;
  final double collateralValue;

  LoanTerms({
    required this.amount,
    required this.interestRate,
    required this.durationDays,
    required this.collateralNFTId,
    required this.collateralValue,
  });

  double get totalRepayment =>
      amount * (1 + (interestRate / 100) * (durationDays / 365));
  double get monthlyPayment => totalRepayment / (durationDays / 30);
}

class BlockchainTransaction {
  final String hash;
  final String type;
  final DateTime timestamp;
  final String status;
  final double gasUsed;
  final int blockNumber;

  BlockchainTransaction({
    required this.hash,
    required this.type,
    required this.timestamp,
    required this.status,
    required this.gasUsed,
    required this.blockNumber,
  });
}
