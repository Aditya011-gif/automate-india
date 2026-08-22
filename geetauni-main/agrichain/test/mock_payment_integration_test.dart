import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrichain/services/mock_payment_service.dart';
import 'package:agrichain/config/config_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Mock Payment Integration Tests', () {
    late ConfigManager configManager;

    setUpAll(() async {
      // Mock SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      
      configManager = ConfigManager();
      await configManager.initialize();
    });

    group('Payment Configuration', () {
      test('should use mock payment in development', () async {
        // Ensure ConfigManager is initialized for this test
        if (!configManager.isInitialized) {
          await configManager.initialize();
        }
        final paymentConfig = configManager.getPaymentConfig();
        
        expect(paymentConfig['useMockPayment'], isTrue);
        expect(paymentConfig['mockGatewayName'], equals('AgriChain Mock Payment Gateway'));
        expect(paymentConfig['supportedMethods'], isNotEmpty);
        expect(paymentConfig['successRate'], equals(0.95));
      });

      test('should have all required mock configuration', () async {
        // Ensure ConfigManager is initialized for this test
        if (!configManager.isInitialized) {
          await configManager.initialize();
        }
        final paymentConfig = configManager.getPaymentConfig();
        
        expect(paymentConfig['mockMerchantId'], isNotNull);
        expect(paymentConfig['mockApiKey'], isNotNull);
        expect(paymentConfig['enableTestMode'], isTrue);
        expect(paymentConfig['simulateDelay'], isTrue);
      });
    });

    group('Payment Order Creation', () {
      test('should create payment order successfully', () async {
        final orderResponse = await MockPaymentService.createPaymentOrder(
          amount: 1000.0,
          currency: 'INR',
          description: 'Test payment for integration',
        );

        expect(orderResponse['order_id'], isNotNull);
        expect(orderResponse['amount'], equals(1000.0));
        expect(orderResponse['currency'], equals('INR'));
        expect(orderResponse['status'], equals('created'));
        expect(orderResponse['mock'], isTrue);
        expect(orderResponse['payment_methods'], isNotEmpty);
      });

      test('should include metadata in payment order', () async {
        final metadata = {'user_id': '123', 'product_id': 'ABC'};
        final orderResponse = await MockPaymentService.createPaymentOrder(
          amount: 500.0,
          currency: 'INR',
          description: 'Test with metadata',
          metadata: metadata,
        );

        expect(orderResponse['metadata'], equals(metadata));
      });
    });

    group('UPI Payment Processing', () {
      test('should process UPI payment successfully', () async {
        final orderResponse = await MockPaymentService.createPaymentOrder(
          amount: 1500.0,
          currency: 'INR',
          description: 'UPI payment test',
        );

        final paymentResponse = await MockPaymentService.processUpiPayment(
          orderId: orderResponse['order_id'],
          upiId: 'test@paytm',
          amount: 1500.0,
        );

        expect(paymentResponse['status'], isIn(['success', 'failed']));
        expect(paymentResponse['transaction_id'], isNotNull);
        expect(paymentResponse['payment_method'], equals('UPI'));
        expect(paymentResponse['amount'], equals(1500.0));
        expect(paymentResponse['mock'], isTrue);
      });

      test('should handle UPI payment with different providers', () async {
        final upiIds = ['farmer@paytm', 'buyer@gpay', 'merchant@phonepe'];
        
        for (final upiId in upiIds) {
          final orderResponse = await MockPaymentService.createPaymentOrder(
            amount: 1000.0,
            currency: 'INR',
            description: 'UPI test for $upiId',
          );

          final paymentResponse = await MockPaymentService.processUpiPayment(
            orderId: orderResponse['order_id'],
            upiId: upiId,
            amount: 1000.0,
          );

          expect(paymentResponse['upi_id'], equals(upiId));
          expect(paymentResponse['transaction_id'], isNotNull);
        }
      });
    });

    group('Card Payment Processing', () {
      test('should process valid card payment successfully', () async {
        final orderResponse = await MockPaymentService.createPaymentOrder(
          amount: 2000.0,
          currency: 'INR',
          description: 'Card payment test',
        );

        final paymentResponse = await MockPaymentService.processCardPayment(
          orderId: orderResponse['order_id'],
          cardNumber: '4111111111111111', // Test Visa card
          expiryMonth: '12',
          expiryYear: '25',
          cvv: '123',
          cardHolderName: 'Test User',
          amount: 2000.0,
        );

        if (paymentResponse['status'] == 'success') {
          expect(paymentResponse['card_details']['last_4_digits'], equals('1111'));
          expect(paymentResponse['card_details']['card_type'], equals('Visa'));
          expect(paymentResponse['gateway_response']['response_code'], equals('00'));
        }
        
        expect(paymentResponse['payment_method'], equals('Card'));
        expect(paymentResponse['mock'], isTrue);
      });

      test('should handle different card types', () async {
        final testCards = [
          {'number': '4111111111111111', 'type': 'Visa'},
          {'number': '5555555555554444', 'type': 'Mastercard'},
          {'number': '378282246310005', 'type': 'American Express'},
        ];

        for (final card in testCards) {
          final orderResponse = await MockPaymentService.createPaymentOrder(
            amount: 1000.0,
            currency: 'INR',
            description: 'Card type test',
          );

          final paymentResponse = await MockPaymentService.processCardPayment(
            orderId: orderResponse['order_id'],
            cardNumber: card['number']!,
            expiryMonth: '12',
            expiryYear: '25',
            cvv: '123',
            cardHolderName: 'Test User',
            amount: 1000.0,
          );

          if (paymentResponse['status'] == 'success') {
            expect(paymentResponse['card_details']['card_type'], equals(card['type']));
          }
        }
      });

      test('should reject invalid card details', () async {
        final orderResponse = await MockPaymentService.createPaymentOrder(
          amount: 1000.0,
          currency: 'INR',
          description: 'Invalid card test',
        );

        final paymentResponse = await MockPaymentService.processCardPayment(
          orderId: orderResponse['order_id'],
          cardNumber: '1234567890123456', // Invalid card
          expiryMonth: '12',
          expiryYear: '25',
          cvv: '12', // Invalid CVV
          cardHolderName: 'Test User',
          amount: 1000.0,
        );

        expect(paymentResponse['status'], equals('failed'));
        expect(paymentResponse['error']['code'], equals('CARD_DECLINED'));
      });
    });

    group('Net Banking Payment Processing', () {
      test('should process net banking payment successfully', () async {
        final orderResponse = await MockPaymentService.createPaymentOrder(
          amount: 3000.0,
          currency: 'INR',
          description: 'Net banking test',
        );

        final paymentResponse = await MockPaymentService.processNetBankingPayment(
          orderId: orderResponse['order_id'],
          bankCode: 'SBI',
          amount: 3000.0,
        );

        expect(paymentResponse['status'], isIn(['success', 'failed']));
        expect(paymentResponse['payment_method'], equals('Net Banking'));
        expect(paymentResponse['amount'], equals(3000.0));
        expect(paymentResponse['mock'], isTrue);

        if (paymentResponse['status'] == 'success') {
          expect(paymentResponse['bank_details'], isNotNull);
          expect(paymentResponse['gateway_response']['response_code'], equals('00'));
        }
      });
    });

    group('Wallet Payment Processing', () {
      test('should process wallet payment successfully', () async {
        final orderResponse = await MockPaymentService.createPaymentOrder(
          amount: 800.0,
          currency: 'INR',
          description: 'Wallet payment test',
        );

        final paymentResponse = await MockPaymentService.processWalletPayment(
          orderId: orderResponse['order_id'],
          walletType: 'Paytm',
          walletId: 'user@paytm',
          amount: 800.0,
        );

        expect(paymentResponse['status'], isIn(['success', 'failed']));
        expect(paymentResponse['payment_method'], equals('Wallet'));
        expect(paymentResponse['amount'], equals(800.0));
        expect(paymentResponse['mock'], isTrue);

        if (paymentResponse['status'] == 'success') {
          expect(paymentResponse['wallet_details']['wallet_type'], equals('Paytm'));
          expect(paymentResponse['wallet_details']['wallet_id'], equals('user@paytm'));
        }
      });
    });

    group('Payment Status and History', () {
      test('should get payment status', () async {
        final status = await MockPaymentService.getPaymentStatus('TXN_123456');
        
        expect(status['transaction_id'], equals('TXN_123456'));
        expect(status['status'], isIn(['success', 'failed', 'pending']));
        expect(status['amount'], isA<double>());
        expect(status['currency'], equals('INR'));
        expect(status['mock'], isTrue);
      });

      test('should get transaction history', () async {
        final history = await MockPaymentService.getTransactionHistory(limit: 5);
        
        expect(history, isA<List>());
        expect(history.length, equals(5));
        
        for (final transaction in history) {
          expect(transaction['transaction_id'], isNotNull);
          expect(transaction['amount'], isA<double>());
          expect(transaction['status'], isIn(['success', 'failed']));
          expect(transaction['mock'], isTrue);
        }
      });

      test('should get payment analytics', () async {
        final analytics = await MockPaymentService.getPaymentAnalytics();
        
        expect(analytics['total_transactions'], isA<int>());
        expect(analytics['successful_transactions'], isA<int>());
        expect(analytics['success_rate'], isA<String>());
        expect(analytics['total_amount'], isA<double>());
        expect(analytics['payment_method_breakdown'], isA<Map>());
        expect(analytics['mock'], isTrue);
      });
    });

    group('Refund Processing', () {
      test('should process refund successfully', () async {
        final refundResponse = await MockPaymentService.refundPayment(
          transactionId: 'TXN_123456',
          refundAmount: 500.0,
          reason: 'Customer request',
        );

        expect(refundResponse['refund_id'], isNotNull);
        expect(refundResponse['transaction_id'], equals('TXN_123456'));
        expect(refundResponse['refund_amount'], equals(500.0));
        expect(refundResponse['status'], equals('processed'));
        expect(refundResponse['reason'], equals('Customer request'));
        expect(refundResponse['mock'], isTrue);
      });
    });

    group('Service Status', () {
      test('should return service status', () {
        final status = MockPaymentService.getServiceStatus();
        
        expect(status['service'], equals('AgriChain Mock Payment Gateway'));
        expect(status['status'], equals('active'));
        expect(status['mode'], equals('mock'));
        expect(status['supported_methods'], isNotEmpty);
        expect(status['uptime'], isNotNull);
        expect(status['mock'], isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle payment failures gracefully', () async {
        // Test multiple payments to trigger some failures (5% failure rate)
        int successCount = 0;
        int failureCount = 0;
        
        for (int i = 0; i < 5; i++) {
          final orderResponse = await MockPaymentService.createPaymentOrder(
            amount: 1000.0,
            currency: 'INR',
            description: 'Failure test $i',
          );

          final paymentResponse = await MockPaymentService.processUpiPayment(
            orderId: orderResponse['order_id'],
            upiId: 'test@paytm',
            amount: 1000.0,
          );

          if (paymentResponse['status'] == 'success') {
            successCount++;
          } else {
            failureCount++;
            expect(paymentResponse['error'], isNotNull);
            expect(paymentResponse['error']['code'], isNotNull);
            expect(paymentResponse['error']['message'], isNotNull);
          }
        }

        // Should have some failures due to 5% failure rate
        expect(successCount, greaterThan(0));
        print('Success: $successCount, Failures: $failureCount');
      });
    });

    group('Performance Tests', () {
      test('should handle concurrent payment requests', () async {
        final futures = <Future>[];
        
        for (int i = 0; i < 10; i++) {
          futures.add(
            MockPaymentService.createPaymentOrder(
              amount: 1000.0 + i,
              currency: 'INR',
              description: 'Concurrent test $i',
            ),
          );
        }

        final results = await Future.wait(futures);
        
        expect(results.length, equals(10));
        for (final result in results) {
          expect(result['order_id'], isNotNull);
          expect(result['mock'], isTrue);
        }
      });

      test('should complete payments within reasonable time', () async {
        final stopwatch = Stopwatch()..start();
        
        final orderResponse = await MockPaymentService.createPaymentOrder(
          amount: 1000.0,
          currency: 'INR',
          description: 'Performance test',
        );

        final paymentResponse = await MockPaymentService.processUpiPayment(
          orderId: orderResponse['order_id'],
          upiId: 'test@paytm',
          amount: 1000.0,
        );

        stopwatch.stop();
        
        expect(paymentResponse['transaction_id'], isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(6000)); // Should complete within 6 seconds
        print('Payment completed in ${stopwatch.elapsedMilliseconds}ms');
      });
    });
  });
}