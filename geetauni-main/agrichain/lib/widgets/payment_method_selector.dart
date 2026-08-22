import 'package:flutter/material.dart';

import '../services/mock_payment_service.dart';
import '../config/config_manager.dart';

/// Payment Method Selector Widget
///
/// Provides a UI for selecting payment methods and processing payments
/// using the mock payment service for hackathon demonstrations.
class PaymentMethodSelector extends StatefulWidget {
  final double amount;
  final String description;
  final Function(Map<String, dynamic>) onPaymentSuccess;
  final Function(String) onPaymentFailure;
  final Map<String, dynamic>? metadata;

  const PaymentMethodSelector({
    super.key,
    required this.amount,
    required this.description,
    required this.onPaymentSuccess,
    required this.onPaymentFailure,
    this.metadata,
  });

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  final ConfigManager _configManager = ConfigManager();
  PaymentMethodType _selectedMethod = PaymentMethodType.upi;
  bool _isProcessing = false;

  // Form controllers
  final _upiController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  String? _selectedBank;
  String? _selectedWallet;

  @override
  void initState() {
    super.initState();
    _configManager.initialize();
  }

  @override
  void dispose() {
    _upiController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildPaymentMethodTabs(),
            const SizedBox(height: 16),
            _buildPaymentForm(),
            const SizedBox(height: 24),
            _buildPayButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Details',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Amount to Pay:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              '₹${widget.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.description,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: PaymentMethodType.values.map((method) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_getMethodDisplayName(method)),
                  selected: _selectedMethod == method,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedMethod = method;
                      });
                    }
                  },
                  avatar: Icon(_getMethodIcon(method), size: 18),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentForm() {
    switch (_selectedMethod) {
      case PaymentMethodType.upi:
        return _buildUpiForm();
      case PaymentMethodType.card:
        return _buildCardForm();
      case PaymentMethodType.netBanking:
        return _buildNetBankingForm();
      case PaymentMethodType.wallet:
        return _buildWalletForm();
      case PaymentMethodType.cashOnDelivery:
        return _buildCashOnDeliveryForm();
    }
  }

  Widget _buildUpiForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('UPI Payment', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextFormField(
          controller: _upiController,
          decoration: const InputDecoration(
            labelText: 'UPI ID',
            hintText: 'example@paytm',
            prefixIcon: Icon(Icons.account_balance_wallet),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 8),
        Text(
          'Popular UPI Apps: PhonePe, Google Pay, Paytm, BHIM',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Card Payment', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cardNumberController,
          decoration: const InputDecoration(
            labelText: 'Card Number',
            hintText: '4111 1111 1111 1111',
            prefixIcon: Icon(Icons.credit_card),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                decoration: const InputDecoration(
                  labelText: 'MM/YY',
                  hintText: '12/25',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                decoration: const InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cardHolderController,
          decoration: const InputDecoration(
            labelText: 'Cardholder Name',
            hintText: 'John Doe',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 8),
        Text(
          'Test Cards: 4111111111111111 (Visa), 5555555555554444 (Mastercard)',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildNetBankingForm() {
    final banks = [
      'State Bank of India',
      'HDFC Bank',
      'ICICI Bank',
      'Axis Bank',
      'Punjab National Bank',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Net Banking', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedBank,
          decoration: const InputDecoration(
            labelText: 'Select Bank',
            prefixIcon: Icon(Icons.account_balance),
            border: OutlineInputBorder(),
          ),
          items: banks.map((bank) {
            return DropdownMenuItem(value: bank, child: Text(bank));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedBank = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildWalletForm() {
    final wallets = [
      'Paytm',
      'PhonePe',
      'Amazon Pay',
      'Mobikwik',
      'Freecharge',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Wallet Payment', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedWallet,
          decoration: const InputDecoration(
            labelText: 'Select Wallet',
            prefixIcon: Icon(Icons.account_balance_wallet),
            border: OutlineInputBorder(),
          ),
          items: wallets.map((wallet) {
            return DropdownMenuItem(value: wallet, child: Text(wallet));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedWallet = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCashOnDeliveryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cash on Delivery',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            border: Border.all(color: Colors.orange[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.orange[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You will pay ₹${widget.amount.toStringAsFixed(2)} in cash when the order is delivered.',
                  style: TextStyle(color: Colors.orange[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isProcessing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Processing...'),
                ],
              )
            : Text(
                'Pay ₹${widget.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!_validateForm()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Create payment order first
      final orderResponse = await MockPaymentService.createPaymentOrder(
        amount: widget.amount,
        currency: 'INR',
        description: widget.description,
        metadata: widget.metadata,
      );

      final orderId = orderResponse['order_id'];
      Map<String, dynamic> paymentResponse;

      // Process payment based on selected method
      switch (_selectedMethod) {
        case PaymentMethodType.upi:
          paymentResponse = await MockPaymentService.processUpiPayment(
            orderId: orderId,
            upiId: _upiController.text.trim(),
            amount: widget.amount,
          );
          break;
        case PaymentMethodType.card:
          final expiry = _expiryController.text.split('/');
          paymentResponse = await MockPaymentService.processCardPayment(
            orderId: orderId,
            cardNumber: _cardNumberController.text.replaceAll(' ', ''),
            expiryMonth: expiry.isNotEmpty ? expiry[0] : '12',
            expiryYear: expiry.length > 1 ? expiry[1] : '25',
            cvv: _cvvController.text,
            cardHolderName: _cardHolderController.text,
            amount: widget.amount,
          );
          break;
        case PaymentMethodType.netBanking:
          paymentResponse = await MockPaymentService.processNetBankingPayment(
            orderId: orderId,
            bankCode: _selectedBank ?? 'SBI',
            amount: widget.amount,
          );
          break;
        case PaymentMethodType.wallet:
          paymentResponse = await MockPaymentService.processWalletPayment(
            orderId: orderId,
            walletType: _selectedWallet ?? 'Paytm',
            walletId: 'user@${_selectedWallet?.toLowerCase()}',
            amount: widget.amount,
          );
          break;
        case PaymentMethodType.cashOnDelivery:
          // For COD, we just create a successful response
          paymentResponse = {
            'status': 'success',
            'transaction_id': 'COD_${DateTime.now().millisecondsSinceEpoch}',
            'order_id': orderId,
            'payment_method': 'Cash on Delivery',
            'amount': widget.amount,
            'currency': 'INR',
            'processed_at': DateTime.now().toIso8601String(),
            'mock': true,
          };
          break;
      }

      if (paymentResponse['status'] == 'success') {
        widget.onPaymentSuccess(paymentResponse);
      } else {
        widget.onPaymentFailure(
          paymentResponse['error']['message'] ?? 'Payment failed',
        );
      }
    } catch (e) {
      widget.onPaymentFailure('Payment processing error: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  bool _validateForm() {
    switch (_selectedMethod) {
      case PaymentMethodType.upi:
        if (_upiController.text.trim().isEmpty) {
          _showError('Please enter UPI ID');
          return false;
        }
        break;
      case PaymentMethodType.card:
        if (_cardNumberController.text.trim().isEmpty ||
            _expiryController.text.trim().isEmpty ||
            _cvvController.text.trim().isEmpty ||
            _cardHolderController.text.trim().isEmpty) {
          _showError('Please fill all card details');
          return false;
        }
        break;
      case PaymentMethodType.netBanking:
        if (_selectedBank == null) {
          _showError('Please select a bank');
          return false;
        }
        break;
      case PaymentMethodType.wallet:
        if (_selectedWallet == null) {
          _showError('Please select a wallet');
          return false;
        }
        break;
      case PaymentMethodType.cashOnDelivery:
        // No validation needed for COD
        break;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _getMethodDisplayName(PaymentMethodType method) {
    switch (method) {
      case PaymentMethodType.upi:
        return 'UPI';
      case PaymentMethodType.card:
        return 'Card';
      case PaymentMethodType.netBanking:
        return 'Net Banking';
      case PaymentMethodType.wallet:
        return 'Wallet';
      case PaymentMethodType.cashOnDelivery:
        return 'COD';
    }
  }

  IconData _getMethodIcon(PaymentMethodType method) {
    switch (method) {
      case PaymentMethodType.upi:
        return Icons.account_balance_wallet;
      case PaymentMethodType.card:
        return Icons.credit_card;
      case PaymentMethodType.netBanking:
        return Icons.account_balance;
      case PaymentMethodType.wallet:
        return Icons.wallet;
      case PaymentMethodType.cashOnDelivery:
        return Icons.money;
    }
  }
}
