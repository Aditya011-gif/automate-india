import 'dart:async';
import 'dart:math';

/// Mock Payment Service for Hackathon Demo
///
/// This service simulates payment gateway functionality for demonstration purposes.
/// It provides realistic payment flows, transaction handling, and response simulation
/// without requiring actual payment gateway integration.
class MockPaymentService {
  static const String _tag = 'MockPaymentService';

  // Mock payment gateway configuration
  static const String mockGatewayName = 'AgriChain Mock Payment Gateway';
  static const String mockMerchantId = 'MOCK_MERCHANT_AGRICHAIN_001';
  static const String mockApiKey = 'MOCK_API_KEY_12345';

  // Supported payment methods
  static const List<String> supportedPaymentMethods = [
    'UPI',
    'Credit Card',
    'Debit Card',
    'Net Banking',
    'Wallet',
    'Cash on Delivery',
  ];

  // Mock UPI IDs for demo
  static const List<String> mockUpiIds = [
    'farmer@paytm',
    'buyer@gpay',
    'merchant@phonepe',
    'supplier@amazonpay',
    'trader@bhim',
  ];

  // Mock bank accounts
  static const List<Map<String, String>> mockBankAccounts = [
    {
      'bankName': 'State Bank of India',
      'accountNumber': '****1234',
      'ifsc': 'SBIN0001234',
      'accountHolder': 'Rajesh Kumar',
    },
    {
      'bankName': 'HDFC Bank',
      'accountNumber': '****5678',
      'ifsc': 'HDFC0001234',
      'accountHolder': 'Priya Sharma',
    },
    {
      'bankName': 'ICICI Bank',
      'accountNumber': '****9012',
      'ifsc': 'ICIC0001234',
      'accountHolder': 'Amit Singh',
    },
  ];

  /// Create a payment order
  static Future<Map<String, dynamic>> createPaymentOrder({
    required double amount,
    required String currency,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1500));

    final orderId = _generateOrderId();
    final timestamp = DateTime.now();

    return {
      'order_id': orderId,
      'amount': amount,
      'currency': currency,
      'description': description,
      'status': 'created',
      'created_at': timestamp.toIso8601String(),
      'expires_at': timestamp
          .add(const Duration(minutes: 15))
          .toIso8601String(),
      'payment_methods': supportedPaymentMethods,
      'metadata': metadata ?? {},
      'mock': true,
      'gateway': mockGatewayName,
    };
  }

  /// Process UPI payment
  static Future<Map<String, dynamic>> processUpiPayment({
    required String orderId,
    required String upiId,
    required double amount,
  }) async {
    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 3));

    // Simulate 95% success rate
    final isSuccess = Random().nextDouble() > 0.05;
    final transactionId = _generateTransactionId();

    if (isSuccess) {
      return {
        'status': 'success',
        'transaction_id': transactionId,
        'order_id': orderId,
        'payment_method': 'UPI',
        'upi_id': upiId,
        'amount': amount,
        'currency': 'INR',
        'gateway_response': {
          'response_code': '00',
          'response_message': 'Transaction Successful',
          'bank_reference': 'UPI${Random().nextInt(999999999)}',
        },
        'processed_at': DateTime.now().toIso8601String(),
        'mock': true,
      };
    } else {
      return {
        'status': 'failed',
        'transaction_id': transactionId,
        'order_id': orderId,
        'payment_method': 'UPI',
        'upi_id': upiId,
        'amount': amount,
        'currency': 'INR',
        'error': {
          'code': 'PAYMENT_FAILED',
          'message': 'Transaction declined by bank',
          'description': 'Insufficient balance or invalid UPI PIN',
        },
        'processed_at': DateTime.now().toIso8601String(),
        'mock': true,
      };
    }
  }

  /// Process card payment
  static Future<Map<String, dynamic>> processCardPayment({
    required String orderId,
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required String cardHolderName,
    required double amount,
  }) async {
    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 4));

    // Validate mock card details
    final isValidCard = _validateMockCard(cardNumber, cvv);
    final transactionId = _generateTransactionId();

    if (isValidCard) {
      return {
        'status': 'success',
        'transaction_id': transactionId,
        'order_id': orderId,
        'payment_method': 'Card',
        'card_details': {
          'last_4_digits': cardNumber.substring(cardNumber.length - 4),
          'card_type': _getCardType(cardNumber),
          'card_holder_name': cardHolderName,
        },
        'amount': amount,
        'currency': 'INR',
        'gateway_response': {
          'response_code': '00',
          'response_message': 'Transaction Approved',
          'auth_code': 'AUTH${Random().nextInt(999999)}',
          'bank_reference': 'CARD${Random().nextInt(999999999)}',
        },
        'processed_at': DateTime.now().toIso8601String(),
        'mock': true,
      };
    } else {
      return {
        'status': 'failed',
        'transaction_id': transactionId,
        'order_id': orderId,
        'payment_method': 'Card',
        'amount': amount,
        'currency': 'INR',
        'error': {
          'code': 'CARD_DECLINED',
          'message': 'Card payment declined',
          'description': 'Invalid card details or insufficient funds',
        },
        'processed_at': DateTime.now().toIso8601String(),
        'mock': true,
      };
    }
  }

  /// Process net banking payment
  static Future<Map<String, dynamic>> processNetBankingPayment({
    required String orderId,
    required String bankCode,
    required double amount,
  }) async {
    // Simulate bank redirect and processing delay
    await Future.delayed(const Duration(seconds: 5));

    // Simulate 90% success rate for net banking
    final isSuccess = Random().nextDouble() > 0.1;
    final transactionId = _generateTransactionId();
    final bankAccount =
        mockBankAccounts[Random().nextInt(mockBankAccounts.length)];

    if (isSuccess) {
      return {
        'status': 'success',
        'transaction_id': transactionId,
        'order_id': orderId,
        'payment_method': 'Net Banking',
        'bank_details': {
          'bank_name': bankAccount['bankName'],
          'account_number': bankAccount['accountNumber'],
          'ifsc': bankAccount['ifsc'],
        },
        'amount': amount,
        'currency': 'INR',
        'gateway_response': {
          'response_code': '00',
          'response_message': 'Transaction Successful',
          'bank_reference': 'NB${Random().nextInt(999999999)}',
        },
        'processed_at': DateTime.now().toIso8601String(),
        'mock': true,
      };
    } else {
      return {
        'status': 'failed',
        'transaction_id': transactionId,
        'order_id': orderId,
        'payment_method': 'Net Banking',
        'amount': amount,
        'currency': 'INR',
        'error': {
          'code': 'BANK_DECLINED',
          'message': 'Net banking transaction failed',
          'description': 'Session timeout or insufficient balance',
        },
        'processed_at': DateTime.now().toIso8601String(),
        'mock': true,
      };
    }
  }

  /// Process wallet payment
  static Future<Map<String, dynamic>> processWalletPayment({
    required String orderId,
    required String walletType,
    required String walletId,
    required double amount,
  }) async {
    // Simulate wallet processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Simulate 98% success rate for wallets
    final isSuccess = Random().nextDouble() > 0.02;
    final transactionId = _generateTransactionId();

    if (isSuccess) {
      return {
        'status': 'success',
        'transaction_id': transactionId,
        'order_id': orderId,
        'payment_method': 'Wallet',
        'wallet_details': {'wallet_type': walletType, 'wallet_id': walletId},
        'amount': amount,
        'currency': 'INR',
        'gateway_response': {
          'response_code': '00',
          'response_message': 'Wallet payment successful',
          'wallet_reference': 'WAL${Random().nextInt(999999999)}',
        },
        'processed_at': DateTime.now().toIso8601String(),
        'mock': true,
      };
    } else {
      return {
        'status': 'failed',
        'transaction_id': transactionId,
        'order_id': orderId,
        'payment_method': 'Wallet',
        'amount': amount,
        'currency': 'INR',
        'error': {
          'code': 'WALLET_INSUFFICIENT_BALANCE',
          'message': 'Insufficient wallet balance',
          'description': 'Please add money to your wallet and try again',
        },
        'processed_at': DateTime.now().toIso8601String(),
        'mock': true,
      };
    }
  }

  /// Get payment status
  static Future<Map<String, dynamic>> getPaymentStatus(
    String transactionId,
  ) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    // For demo purposes, assume most transactions are successful
    final statuses = ['success', 'success', 'success', 'failed', 'pending'];
    final status = statuses[Random().nextInt(statuses.length)];

    return {
      'transaction_id': transactionId,
      'status': status,
      'amount':
          1000.0 +
          Random().nextDouble() * 9000, // Random amount between 1000-10000
      'currency': 'INR',
      'payment_method':
          supportedPaymentMethods[Random().nextInt(
            supportedPaymentMethods.length,
          )],
      'created_at': DateTime.now()
          .subtract(Duration(minutes: Random().nextInt(60)))
          .toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'mock': true,
    };
  }

  /// Refund payment
  static Future<Map<String, dynamic>> refundPayment({
    required String transactionId,
    required double refundAmount,
    String? reason,
  }) async {
    // Simulate refund processing delay
    await Future.delayed(const Duration(seconds: 3));

    final refundId = _generateRefundId();

    return {
      'refund_id': refundId,
      'transaction_id': transactionId,
      'refund_amount': refundAmount,
      'currency': 'INR',
      'status': 'processed',
      'reason': reason ?? 'Customer request',
      'processed_at': DateTime.now().toIso8601String(),
      'estimated_settlement': DateTime.now()
          .add(const Duration(days: 3))
          .toIso8601String(),
      'mock': true,
    };
  }

  /// Get transaction history
  static Future<List<Map<String, dynamic>>> getTransactionHistory({
    int limit = 10,
    int offset = 0,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1200));

    final transactions = <Map<String, dynamic>>[];

    for (int i = 0; i < limit; i++) {
      final transactionId = _generateTransactionId();
      final amount =
          500.0 +
          Random().nextDouble() * 4500; // Random amount between 500-5000
      final status = [
        'success',
        'success',
        'success',
        'failed',
      ][Random().nextInt(4)];
      final paymentMethod =
          supportedPaymentMethods[Random().nextInt(
            supportedPaymentMethods.length,
          )];

      transactions.add({
        'transaction_id': transactionId,
        'amount': amount,
        'currency': 'INR',
        'status': status,
        'payment_method': paymentMethod,
        'description': _generateTransactionDescription(),
        'created_at': DateTime.now()
            .subtract(Duration(days: Random().nextInt(30)))
            .toIso8601String(),
        'mock': true,
      });
    }

    return transactions;
  }

  /// Get payment analytics
  static Future<Map<String, dynamic>> getPaymentAnalytics() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1000));

    final totalTransactions = 150 + Random().nextInt(350);
    final successfulTransactions =
        (totalTransactions * (0.85 + Random().nextDouble() * 0.1)).round();
    final totalAmount = 50000.0 + Random().nextDouble() * 200000;

    return {
      'total_transactions': totalTransactions,
      'successful_transactions': successfulTransactions,
      'failed_transactions': totalTransactions - successfulTransactions,
      'success_rate': (successfulTransactions / totalTransactions * 100)
          .toStringAsFixed(2),
      'total_amount': totalAmount,
      'average_transaction_amount': (totalAmount / totalTransactions)
          .toStringAsFixed(2),
      'payment_method_breakdown': {
        'UPI': '45%',
        'Card': '25%',
        'Net Banking': '15%',
        'Wallet': '10%',
        'Cash on Delivery': '5%',
      },
      'period': 'Last 30 days',
      'mock': true,
    };
  }

  /// Check service status
  static Map<String, dynamic> getServiceStatus() {
    return {
      'service': mockGatewayName,
      'status': 'active',
      'mode': 'mock',
      'supported_methods': supportedPaymentMethods,
      'uptime': '99.9%',
      'last_updated': DateTime.now().toIso8601String(),
      'mock': true,
    };
  }

  // Private helper methods

  static String _generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'ORDER_${timestamp}_$random';
  }

  static String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'TXN_${timestamp}_$random';
  }

  static String _generateRefundId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'REFUND_${timestamp}_$random';
  }

  static bool _validateMockCard(String cardNumber, String cvv) {
    // Mock validation - accept test card numbers
    final testCards = [
      '4111111111111111', // Visa test card
      '5555555555554444', // Mastercard test card
      '378282246310005', // Amex test card
    ];

    return testCards.contains(cardNumber) && cvv.length >= 3;
  }

  static String _getCardType(String cardNumber) {
    if (cardNumber.startsWith('4')) return 'Visa';
    if (cardNumber.startsWith('5')) return 'Mastercard';
    if (cardNumber.startsWith('3')) return 'American Express';
    return 'Unknown';
  }

  static String _generateTransactionDescription() {
    final descriptions = [
      'Purchase of organic vegetables',
      'Payment for wheat procurement',
      'Rice supply chain payment',
      'Fertilizer purchase',
      'Farm equipment rental',
      'Seed purchase payment',
      'Crop insurance premium',
      'Marketplace transaction',
    ];

    return descriptions[Random().nextInt(descriptions.length)];
  }
}

/// Mock Payment Response Models
class MockPaymentResponse {
  final bool success;
  final Map<String, dynamic> data;
  final String? error;
  final bool isMock;

  MockPaymentResponse({
    required this.success,
    required this.data,
    this.error,
    this.isMock = true,
  });

  factory MockPaymentResponse.success(Map<String, dynamic> data) {
    return MockPaymentResponse(success: true, data: data, isMock: true);
  }

  factory MockPaymentResponse.error(String error) {
    return MockPaymentResponse(
      success: false,
      data: {},
      error: error,
      isMock: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'error': error,
      'mock': isMock,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Payment Method Types
enum PaymentMethodType { upi, card, netBanking, wallet, cashOnDelivery }

/// Payment Status Types
enum PaymentStatus {
  created,
  pending,
  processing,
  success,
  failed,
  cancelled,
  refunded,
}
