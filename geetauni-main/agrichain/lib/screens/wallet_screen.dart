import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/enhanced_app_bar.dart';
import '../services/firebase_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _firebaseTransactions = [];
  bool _isLoadingTransactions = false;

  @override
  void initState() {
    super.initState();
    _loadTransactionsFromFirebase();
  }

  Future<void> _loadTransactionsFromFirebase() async {
    setState(() {
      _isLoadingTransactions = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final currentUser = appState.currentUser;
      if (currentUser == null) return;
      final userId = currentUser.id;

      debugPrint('🔄 Loading transactions from Firebase for user: $userId');

      final transactions = await _firebaseService.getUserTransactions(
        userId,
        limit: 20,
      );

      setState(() {
        _firebaseTransactions = transactions;
      });

      debugPrint('✅ Loaded ${transactions.length} transactions from Firebase');
    } catch (e) {
      debugPrint('❌ Error loading transactions from Firebase: $e');
    } finally {
      setState(() {
        _isLoadingTransactions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final user = appState.currentUser;

        return Scaffold(
          backgroundColor: AppTheme.lightGrey,
          appBar: const EnhancedAppBar(
            title: 'Wallet',
            subtitle: 'Manage your funds',
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wallet Balance Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${(user?.walletBalance ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.token,
                            color: Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${0} AgriTokens', // TODO: Add agriTokens property to FirestoreUser model
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.add,
                        label: 'Add Funds',
                        onTap: () => _showAddFundsDialog(context, appState),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.send,
                        label: 'Send',
                        onTap: () => _showSendDialog(context, appState),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.history,
                        label: 'History',
                        onTap: () => _showTransactionHistory(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent Transactions
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGrey,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTransactionsList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.darkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_isLoadingTransactions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Combine Firebase transactions with mock data for demo
    final mockTransactions = [
      {
        'type': 'purchase',
        'description': 'Purchased Organic Wheat',
        'amount': -2500.0,
        'date': DateTime.now().subtract(const Duration(hours: 2)),
        'status': 'completed',
        'isDebit': true,
      },
      {
        'type': 'bid',
        'description': 'Bid placed on Premium Rice',
        'amount': -3000.0,
        'date': DateTime.now().subtract(const Duration(hours: 5)),
        'status': 'pending',
        'isDebit': true,
      },
      {
        'type': 'refund',
        'description': 'Auction refund - Lost bid',
        'amount': 2800.0,
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'status': 'completed',
        'isDebit': false,
      },
      {
        'type': 'deposit',
        'description': 'Wallet top-up',
        'amount': 10000.0,
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'status': 'completed',
        'isDebit': false,
      },
    ];

    // Convert Firebase transactions to display format
    final firebaseTransactions = _firebaseTransactions.map((transaction) {
      return {
        'type': transaction['type'] ?? 'unknown',
        'description': transaction['description'] ?? 'Transaction',
        'amount': (transaction['amount'] as num?)?.toDouble() ?? 0.0,
        'date': transaction['createdAt'] != null
            ? (transaction['createdAt'] as dynamic).toDate()
            : DateTime.now(),
        'status': transaction['status'] ?? 'completed',
        'isDebit': transaction['isDebit'] ?? false,
      };
    }).toList();

    // Combine and sort transactions
    final allTransactions = [...firebaseTransactions, ...mockTransactions];
    allTransactions.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );

    final transactions = allTransactions.take(10).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final isDebit =
            transaction['isDebit'] as bool? ??
            (transaction['amount'] as double) < 0;
        final isPositive = !isDebit;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTransactionIcon(transaction['type'] as String),
                  color: isPositive ? AppTheme.primaryGreen : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction['description'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(transaction['date'] as DateTime),
                      style: TextStyle(color: AppTheme.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPositive ? '+' : '-'}₹${(transaction['amount'] as double).abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isPositive ? AppTheme.primaryGreen : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: transaction['status'] == 'completed'
                          ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      transaction['status'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: transaction['status'] == 'completed'
                            ? AppTheme.primaryGreen
                            : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'purchase':
        return Icons.shopping_cart;
      case 'bid':
        return Icons.gavel;
      case 'refund':
        return Icons.refresh;
      case 'deposit':
        return Icons.add_circle;
      default:
        return Icons.account_balance_wallet;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    }
  }

  void _showAddFundsDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Funds'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount (₹)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                appState.updateWalletBalance(amount);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Added ₹${amount.toStringAsFixed(2)} to wallet',
                    ),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showSendDialog(BuildContext context, AppState appState) {
    final amountController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Recipient Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null &&
                  amount > 0 &&
                  addressController.text.isNotEmpty) {
                if ((appState.currentUser?.walletBalance ?? 0.0) >= amount) {
                  appState.updateWalletBalance(-amount);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sent ₹${amount.toStringAsFixed(2)}'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Insufficient balance'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showTransactionHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Transaction History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [_buildTransactionsList()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
