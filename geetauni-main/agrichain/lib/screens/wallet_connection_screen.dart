import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wallet_service.dart';
import '../providers/app_state.dart';

class WalletConnectionScreen extends StatefulWidget {
  const WalletConnectionScreen({super.key});

  @override
  State<WalletConnectionScreen> createState() => _WalletConnectionScreenState();
}

class _WalletConnectionScreenState extends State<WalletConnectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  WalletConnectionState _connectionState = WalletConnectionState.disconnected;
  String? _errorMessage;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();

    // Listen to wallet connection state
    WalletService.connectionStream.listen((state) {
      if (mounted) {
        setState(() {
          _connectionState = state;
          if (state == WalletConnectionState.connected) {
            _isConnecting = false;
            _errorMessage = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade50, Colors.white, Colors.blue.shade50],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),

                    const SizedBox(height: 40),

                    // Connection Status
                    _buildConnectionStatus(),

                    const SizedBox(height: 40),

                    // Wallet Options
                    Expanded(child: _buildWalletOptions()),

                    // Footer
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back, color: Colors.green.shade700),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.account_balance_wallet,
            size: 48,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Connect Your Wallet',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect your blockchain wallet to access\nNFT features and secure transactions',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    if (_connectionState == WalletConnectionState.connected) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.green.shade700, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wallet Connected',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  if (WalletService.connectedAddress != null)
                    Text(
                      '${WalletService.connectedAddress!.substring(0, 6)}...${WalletService.connectedAddress!.substring(WalletService.connectedAddress!.length - 4)}',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${WalletService.balance.toStringAsFixed(4)} ${WalletService.connectedNetwork?.contains('Polygon') == true ? 'MATIC' : 'ETH'}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildWalletOptions() {
    final walletOptions = [
      {
        'type': WalletType.metamask,
        'name': 'MetaMask',
        'description': 'Connect using MetaMask wallet',
        'icon': Icons.extension,
        'color': Colors.orange,
      },
      {
        'type': WalletType.walletConnect,
        'name': 'WalletConnect',
        'description': 'Scan with WalletConnect to connect',
        'icon': Icons.qr_code_scanner,
        'color': Colors.blue,
      },
      {
        'type': WalletType.coinbase,
        'name': 'Coinbase Wallet',
        'description': 'Connect using Coinbase Wallet',
        'icon': Icons.account_balance,
        'color': Colors.indigo,
      },
      {
        'type': WalletType.trustWallet,
        'name': 'Trust Wallet',
        'description': 'Connect using Trust Wallet',
        'icon': Icons.security,
        'color': Colors.teal,
      },
    ];

    return ListView.builder(
      itemCount: walletOptions.length,
      itemBuilder: (context, index) {
        final option = walletOptions[index];
        return _buildWalletOption(option);
      },
    );
  }

  Widget _buildWalletOption(Map<String, dynamic> option) {
    final isConnected = _connectionState == WalletConnectionState.connected;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isConnected ? null : () => _connectWallet(option['type']),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isConnected
                    ? Colors.grey.shade300
                    : option['color'].withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: option['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(option['icon'], color: option['color'], size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isConnected
                              ? Colors.grey.shade500
                              : Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option['description'],
                        style: TextStyle(
                          color: isConnected
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isConnecting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (isConnected)
                  Icon(Icons.check_circle, color: Colors.green.shade600)
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        if (_connectionState == WalletConnectionState.connected) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _disconnectWallet,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Disconnect Wallet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          'Your wallet connection is secure and encrypted.\nWe never store your private keys.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _connectWallet(WalletType walletType) async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final result = await WalletService.connectWallet(
        walletType: walletType,
        userId: appState.currentUser?.id,
      );

      if (result.success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Wallet connected successfully!'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Failed to connect wallet';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _disconnectWallet() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await WalletService.disconnectWallet(userId: appState.currentUser?.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                const SizedBox(width: 8),
                Text('Wallet disconnected'),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disconnect wallet: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
