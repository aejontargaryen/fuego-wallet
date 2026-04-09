// Copyright (c) 2025-2026 Fuego Developers
// Copyright (c) 2025-2026 Elderfire Privacy Group

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/cli_service.dart';
import '../../providers/wallet_provider.dart';
import '../../models/deposit_model.dart';
import '../../models/fuego_constants.dart';
import '../../utils/theme.dart';

class BurnDepositsScreen extends StatefulWidget {
  const BurnDepositsScreen({super.key});

  @override
  _BurnDepositsScreenState createState() => _BurnDepositsScreenState();
}

class _BurnDepositsScreenState extends State<BurnDepositsScreen> {
  bool _isProcessing = false;
  String? _selectedBurnTier;

  @override
  void initState() {
    super.initState();
    _selectedBurnTier = 'Standard Burn (0.8 XFG)';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshBurns();
    });
  }

  Future<void> _refreshBurns() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    await walletProvider.refreshDeposits();
  }

  Future<void> _executeBurn() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    // PIN verification dialog
    final pin = await _showPinDialog();
    if (pin == null) return;

    final isValid = await walletProvider.getPrivateKeyForBurn(pin);
    if (isValid == null) {
      _showErrorSnackBar('Invalid PIN');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      String? txHash;
      final denominations = CLIService.getBurnDenominations(
        testnet: walletProvider.networkConfig.isTestnet,
      );
      final burnAmount = denominations[_selectedBurnTier];

      if (burnAmount == null) {
        throw Exception('Invalid burn tier selected');
      }

      // Check balance
      final wallet = walletProvider.wallet;
      if (wallet == null || wallet.unlockedBalance < burnAmount) {
        throw Exception(
          'Insufficient balance. Need ${FuegoConstants.formatXFG(burnAmount)} '
          'but only have ${wallet != null ? FuegoConstants.formatXFG(wallet.unlockedBalance) : "0"} available');
      }

      // Route to standard or large burn
      if (burnAmount >= FuegoConstants.AMOUNT_TIER_3) {
        txHash = await walletProvider.burnLarge();
      } else {
        txHash = await walletProvider.burnStandard();
      }

      if (txHash != null) {
        _showSuccessDialog(txHash, burnAmount);
      } else {
        _showErrorSnackBar(walletProvider.error ?? 'Burn failed');
      }
    } catch (e) {
      _showErrorSnackBar('Burn failed: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<String?> _showPinDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Enter PIN', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter your PIN',
            hintStyle: TextStyle(color: AppTheme.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade800),
    );
  }

  void _showSuccessDialog(String txHash, int burnAmount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Row(
          children: [
            Icon(Icons.local_fire_department, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Burn Successful', style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Amount Burned', FuegoConstants.formatXFG(burnAmount)),
            const SizedBox(height: 8),
            _infoRow('HEAT Minted', '${CLIService.calculateHeatTokens(burnAmount)} HEAT'),
            const SizedBox(height: 8),
            _infoRow('TX Hash', '${txHash.substring(0, 16)}...'),
            const SizedBox(height: 16),
            const Text(
              'Your XFG has been permanently burned. '
              'The equivalent HEAT tokens will be claimable on the target chain.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mint Ξmbers (Burn XFG → HEAT)'),
        backgroundColor: AppTheme.surfaceColor,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, _) {
          final burnDeposits = walletProvider.burnDeposits;
          final isTestnet = walletProvider.networkConfig.isTestnet;
          final denominations = CLIService.getBurnDenominations(testnet: isTestnet);

          return RefreshIndicator(
            onRefresh: _refreshBurns,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Burn Action Card ──
                  _buildBurnActionCard(denominations, walletProvider),
                  const SizedBox(height: 24),
                  // ── Burn History ──
                  const Text(
                    'Burn History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (walletProvider.depositsLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (burnDeposits.isEmpty)
                    _buildEmptyState()
                  else
                    ...burnDeposits.map((d) => _buildBurnCard(d)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBurnActionCard(
    Map<String, int> denominations,
    WalletProvider walletProvider,
  ) {
    return Card(
      color: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_fire_department, color: AppTheme.primaryColor, size: 28),
                SizedBox(width: 10),
                Text(
                  'Burn XFG to Mint Ξmbers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Permanently burn XFG to mint HEAT tokens. This is irreversible.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedBurnTier,
              dropdownColor: AppTheme.surfaceColor,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Burn Tier',
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.textMuted.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: denominations.keys
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedBurnTier = value),
            ),
            if (_selectedBurnTier != null) ...[
              const SizedBox(height: 12),
              _buildBurnPreview(denominations[_selectedBurnTier]!),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _executeBurn,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.local_fire_department),
                label: Text(_isProcessing ? 'Burning...' : 'Execute Burn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBurnPreview(int burnAmount) {
    final heatTokens = CLIService.calculateHeatTokens(burnAmount);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _infoRow('Burn Amount', FuegoConstants.formatXFG(burnAmount)),
          const SizedBox(height: 4),
          _infoRow('HEAT Minted', '$heatTokens'),
          const SizedBox(height: 4),
          _infoRow('Fee', FuegoConstants.formatXFG(
            FuegoConstants.getBankingFee(
              FuegoConstants.classifyTier(burnAmount),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBurnCard(DepositModel deposit) {
    return Card(
      color: AppTheme.surfaceColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepOrange.withOpacity(0.2),
          child: const Icon(Icons.local_fire_department, color: Colors.deepOrange),
        ),
        title: Text(
          deposit.formattedAmount,
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Burned at block ${deposit.height} • ${deposit.tierLabel}',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.deepOrange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'BURNED',
            style: TextStyle(
              color: Colors.deepOrange,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.local_fire_department_outlined,
              size: 64, color: AppTheme.textMuted.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'No Burns Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Burn XFG to mint HEAT tokens on the target chain.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
