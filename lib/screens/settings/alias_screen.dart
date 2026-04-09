import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/wallet_provider.dart';
import '../../utils/theme.dart';
import '../../models/fuego_constants.dart';

class AliasScreen extends StatefulWidget {
  const AliasScreen({super.key});

  @override
  State<AliasScreen> createState() => _AliasScreenState();
}

class _AliasScreenState extends State<AliasScreen> {
  final _aliasController = TextEditingController();
  bool _isRegistering = false;

  @override
  void dispose() {
    _aliasController.dispose();
    super.dispose();
  }

  Future<void> _registerAlias() async {
    final alias = _aliasController.text.trim();
    if (alias.isEmpty) return;

    setState(() => _isRegistering = true);
    
    try {
      // TODO: Implement registerAlias in WalletProvider via RPC
      // For now, we'll show a "coming soon" or logic skeleton
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alias registration coming in next update'), backgroundColor: Colors.blue),
      );
    } finally {
      setState(() => _isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Fire Alias',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          final myAlias = walletProvider.myAlias;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Personalized Handle',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Instead of long "fire..." addresses, use a simple handle like "tuke" for messaging and transfers.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 32),

                if (myAlias != null)
                  _buildMyAliasCard(myAlias.alias)
                else
                  _buildRegisterSection(),

                const SizedBox(height: 40),
                _buildInfoSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyAliasCard(String alias) {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          const Icon(Icons.verified, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          Text(
            '@$alias',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Active on Fuego Mainnet',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.textMuted.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Register an Alias',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _aliasController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. tuke',
              hintStyle: const TextStyle(color: AppTheme.textMuted),
              prefixText: '@',
              prefixStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Registration Fee:',
                style: TextStyle(color: AppTheme.textMuted),
              ),
              Text(
                '${FuegoConstants.toXFG(FuegoConstants.ALIAS_REGISTRATION_FEE)} XFG',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isRegistering ? null : _registerAlias,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isRegistering
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Register Now',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoItem(
          icon: Icons.security,
          title: 'Decentralized Identity',
          description: 'Aliases are stored directly on the Fuego blockchain, linked to your master address.',
        ),
        const SizedBox(height: 16),
        _buildInfoItem(
          icon: Icons.history,
          title: 'One-time Payment',
          description: 'The 1 XFG fee covers registration for life. No annual renewals or central authority.',
        ),
        const SizedBox(height: 16),
        _buildInfoItem(
          icon: Icons.swap_horiz,
          title: 'Transferable',
          description: 'You will be able to sell or transfer your alias securely in future updates.',
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryColor.withOpacity(0.6), size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
