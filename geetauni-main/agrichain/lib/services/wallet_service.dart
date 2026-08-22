import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'blockchain_service.dart';

/// Enhanced wallet service for blockchain wallet connection and transaction handling
class WalletService {
  static const String _collection = 'wallets';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Wallet connection status
  static bool _isConnected = false;
  static String? _connectedAddress;
  static String? _connectedNetwork;
  static double _balance = 0.0;

  // Stream controllers for real-time updates
  static final StreamController<WalletConnectionState> _connectionController =
      StreamController<WalletConnectionState>.broadcast();
  static final StreamController<double> _balanceController =
      StreamController<double>.broadcast();

  // Getters
  static bool get isConnected => _isConnected;
  static String? get connectedAddress => _connectedAddress;
  static String? get connectedNetwork => _connectedNetwork;
  static double get balance => _balance;

  // Streams
  static Stream<WalletConnectionState> get connectionStream =>
      _connectionController.stream;
  static Stream<double> get balanceStream => _balanceController.stream;

  /// Connect to blockchain wallet (MetaMask, WalletConnect, etc.)
  static Future<WalletConnectionResult> connectWallet({
    WalletType walletType = WalletType.metamask,
    String? userId,
  }) async {
    try {
      // Simulate wallet connection process
      await Future.delayed(const Duration(seconds: 2));

      // Get blockchain network info
      final blockchainResult = await BlockchainService.connectWallet();

      if (blockchainResult['success'] == true) {
        _isConnected = true;
        _connectedAddress = blockchainResult['address'];
        _connectedNetwork = blockchainResult['network'];
        _balance = double.tryParse(blockchainResult['balance']) ?? 0.0;

        // Create wallet record in Firestore
        if (userId != null) {
          await _saveWalletInfo(userId, {
            'address': _connectedAddress,
            'network': _connectedNetwork,
            'walletType': walletType.name,
            'balance': _balance,
            'connectedAt': FieldValue.serverTimestamp(),
            'isActive': true,
          });
        }

        // Notify listeners
        _connectionController.add(WalletConnectionState.connected);
        _balanceController.add(_balance);

        if (kDebugMode) {
          print('✅ Wallet connected successfully');
          print('Address: $_connectedAddress');
          print('Network: $_connectedNetwork');
          print('Balance: $_balance');
        }

        return WalletConnectionResult(
          success: true,
          address: _connectedAddress!,
          network: _connectedNetwork!,
          balance: _balance,
          walletType: walletType,
        );
      } else {
        throw Exception('Failed to connect to blockchain network');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Wallet connection failed: $e');
      }

      _connectionController.add(WalletConnectionState.disconnected);

      return WalletConnectionResult(success: false, error: e.toString());
    }
  }

  /// Disconnect wallet
  static Future<void> disconnectWallet({String? userId}) async {
    _isConnected = false;
    _connectedAddress = null;
    _connectedNetwork = null;
    _balance = 0.0;

    if (userId != null) {
      await _updateWalletStatus(userId, false);
    }

    _connectionController.add(WalletConnectionState.disconnected);
    _balanceController.add(0.0);

    if (kDebugMode) {
      print('🔌 Wallet disconnected');
    }
  }

  /// Get wallet balance
  static Future<double> getWalletBalance() async {
    if (!_isConnected) {
      throw Exception('Wallet not connected');
    }

    try {
      // Simulate balance fetch
      await Future.delayed(const Duration(milliseconds: 500));

      // Add some randomness to simulate real balance changes
      final variation = (Random().nextDouble() - 0.5) * 0.1;
      _balance = (_balance + variation).clamp(0.0, double.infinity);

      _balanceController.add(_balance);
      return _balance;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get wallet balance: $e');
      }
      throw Exception('Failed to get wallet balance: $e');
    }
  }

  /// Send transaction
  static Future<TransactionResult> sendTransaction({
    required String to,
    required double amount,
    String? data,
    double? gasLimit,
    double? gasPrice,
    String? userId,
  }) async {
    if (!_isConnected) {
      throw Exception('Wallet not connected');
    }

    if (amount > _balance) {
      throw Exception('Insufficient balance');
    }

    try {
      // Simulate transaction processing
      await Future.delayed(const Duration(seconds: 3));

      final txHash = _generateTransactionHash();
      final gasUsed = gasLimit ?? (Random().nextDouble() * 50000 + 21000);
      final gasFee = (gasUsed * (gasPrice ?? 20)) / 1e9; // Convert to ETH/MATIC

      // Update balance
      _balance -= (amount + gasFee);
      _balanceController.add(_balance);

      // Save transaction record
      if (userId != null) {
        await _saveTransactionRecord(userId, {
          'hash': txHash,
          'from': _connectedAddress,
          'to': to,
          'amount': amount,
          'gasUsed': gasUsed,
          'gasFee': gasFee,
          'status': 'confirmed',
          'timestamp': FieldValue.serverTimestamp(),
          'network': _connectedNetwork,
          'data': data,
        });
      }

      if (kDebugMode) {
        print('✅ Transaction sent successfully');
        print('Hash: $txHash');
        print('Amount: $amount');
        print('Gas fee: $gasFee');
      }

      return TransactionResult(
        success: true,
        hash: txHash,
        gasUsed: gasUsed,
        gasFee: gasFee,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Transaction failed: $e');
      }

      return TransactionResult(success: false, error: e.toString());
    }
  }

  /// Sign message
  static Future<String> signMessage(String message) async {
    if (!_isConnected) {
      throw Exception('Wallet not connected');
    }

    try {
      // Simulate message signing
      await Future.delayed(const Duration(seconds: 1));

      // Generate mock signature
      final signature = _generateSignature(message);

      if (kDebugMode) {
        print('✅ Message signed successfully');
        print('Message: $message');
        print('Signature: $signature');
      }

      return signature;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Message signing failed: $e');
      }
      throw Exception('Failed to sign message: $e');
    }
  }

  /// Get transaction history
  static Future<List<TransactionRecord>> getTransactionHistory(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .doc(userId)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionRecord(
          id: doc.id,
          hash: data['hash'] ?? '',
          from: data['from'] ?? '',
          to: data['to'] ?? '',
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          gasUsed: (data['gasUsed'] as num?)?.toDouble() ?? 0.0,
          gasFee: (data['gasFee'] as num?)?.toDouble() ?? 0.0,
          status: data['status'] ?? 'pending',
          timestamp:
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          network: data['network'] ?? '',
          data: data['data'],
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get transaction history: $e');
      }
      return [];
    }
  }

  /// Get user's wallet info
  static Future<WalletInfo?> getUserWalletInfo(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();

      if (doc.exists) {
        final data = doc.data()!;
        return WalletInfo(
          address: data['address'] ?? '',
          network: data['network'] ?? '',
          walletType: WalletType.values.firstWhere(
            (type) => type.name == data['walletType'],
            orElse: () => WalletType.metamask,
          ),
          balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
          isActive: data['isActive'] ?? false,
          connectedAt: (data['connectedAt'] as Timestamp?)?.toDate(),
        );
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get wallet info: $e');
      }
      return null;
    }
  }

  // Private helper methods
  static Future<void> _saveWalletInfo(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _firestore
        .collection(_collection)
        .doc(userId)
        .set(data, SetOptions(merge: true));
  }

  static Future<void> _updateWalletStatus(String userId, bool isActive) async {
    await _firestore.collection(_collection).doc(userId).update({
      'isActive': isActive,
      'disconnectedAt': isActive ? null : FieldValue.serverTimestamp(),
    });
  }

  static Future<void> _saveTransactionRecord(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _firestore
        .collection(_collection)
        .doc(userId)
        .collection('transactions')
        .add(data);
  }

  static String _generateTransactionHash() {
    const chars = '0123456789abcdef';
    final random = Random();
    return '0x${List.generate(64, (index) => chars[random.nextInt(chars.length)]).join()}';
  }

  static String _generateSignature(String message) {
    const chars = '0123456789abcdef';
    final random = Random();
    return '0x${List.generate(130, (index) => chars[random.nextInt(chars.length)]).join()}';
  }

  /// Dispose streams
  static void dispose() {
    _connectionController.close();
    _balanceController.close();
  }
}

// Enums and Data Classes
enum WalletType { metamask, walletConnect, coinbase, trustWallet, other }

enum WalletConnectionState { disconnected, connecting, connected, error }

class WalletConnectionResult {
  final bool success;
  final String? address;
  final String? network;
  final double? balance;
  final WalletType? walletType;
  final String? error;

  WalletConnectionResult({
    required this.success,
    this.address,
    this.network,
    this.balance,
    this.walletType,
    this.error,
  });
}

class TransactionResult {
  final bool success;
  final String? hash;
  final double? gasUsed;
  final double? gasFee;
  final String? error;

  TransactionResult({
    required this.success,
    this.hash,
    this.gasUsed,
    this.gasFee,
    this.error,
  });
}

class TransactionRecord {
  final String id;
  final String hash;
  final String from;
  final String to;
  final double amount;
  final double gasUsed;
  final double gasFee;
  final String status;
  final DateTime timestamp;
  final String network;
  final String? data;

  TransactionRecord({
    required this.id,
    required this.hash,
    required this.from,
    required this.to,
    required this.amount,
    required this.gasUsed,
    required this.gasFee,
    required this.status,
    required this.timestamp,
    required this.network,
    this.data,
  });
}

class WalletInfo {
  final String address;
  final String network;
  final WalletType walletType;
  final double balance;
  final bool isActive;
  final DateTime? connectedAt;

  WalletInfo({
    required this.address,
    required this.network,
    required this.walletType,
    required this.balance,
    required this.isActive,
    this.connectedAt,
  });
}
