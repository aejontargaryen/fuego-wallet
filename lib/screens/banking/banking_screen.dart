import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/wallet_provider.dart';
import '../../utils/theme.dart';
import '../../models/fuego_constants.dart';
import 'supply_dashboard_screen.dart';
import 'burn_deposits_screen.dart';

class BankingScreen extends StatefulWidget {
  const BankingScreen({super.key});

  @override
  State<BankingScreen> createState() => _BankingScreenState();
}

class _BankingScreenState extends State<BankingScreen> {
  final _numberFormat = NumberFormat('#,##0.00', 'en_US');

  void _showCreateDepositSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _CreateDepositSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'CD Yield Banking',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Supply Stats',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SupplyDashboardScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          final feePool = walletProvider.feePool;
          final deposits = walletProvider.deposits;
          final unlockedDep = walletProvider.wallet?.unlockedDepositBalance ?? 0;
          final lockedDep = walletProvider.wallet?.lockedDepositBalance ?? 0;

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                walletProvider.refreshDeposits(),
                walletProvider.refreshFeePool(),
              ]);
            },
            color: AppTheme.primaryColor,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card - Fee Pool Info
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.account_balance,
                              color: Colors.white,
                              size: 32,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Global Fee Pool',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Reserve',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  feePool != null 
                                    ? '${_numberFormat.format(feePool.feePoolBalance / FuegoConstants.COIN)} XFG' 
                                    : 'Loading...',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Your Active CDs',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_numberFormat.format((lockedDep + unlockedDep) / FuegoConstants.COIN)} XFG',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showCreateDepositSheet,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Open CD'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const BurnDepositsScreen()),
                            );
                          },
                          icon: const Icon(Icons.local_fire_department),
                          label: const Text('Mint Ξmbers'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Deposits List
                  const Text(
                    'Your CD Deposits',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (deposits.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.textMuted.withOpacity(0.3),
                        ),
                      ),
                      width: double.infinity,
                      child: const Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: AppTheme.textMuted,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No Active CD Deposits',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Deposit XFG to start earning interest',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: deposits.length,
                      itemBuilder: (context, index) {
                        final deposit = deposits[index];
                        final amount = deposit.amount / FuegoConstants.COIN;
                        
                        // Fuego CDs are meant to be block-based, we map unlockingHeight to approximate time
                        final blocksRemaining = deposit.unlockHeight - (walletProvider.wallet?.blockchainHeight ?? 0);
                        final isMatured = blocksRemaining <= 0;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: AppTheme.surfaceColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppTheme.textMuted.withOpacity(0.3),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_numberFormat.format(amount)} XFG',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isMatured 
                                            ? const Color(0xFF4CAF50).withOpacity(0.1) 
                                            : AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isMatured ? 'Matured' : 'Locked',
                                        style: TextStyle(
                                          color: isMatured ? const Color(0xFF4CAF50) : AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.timer, size: 16, color: AppTheme.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      isMatured 
                                        ? 'Ready to withdraw' 
                                        : '~$blocksRemaining blocks remaining',
                                      style: const TextStyle(color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                                if (isMatured) ...[
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        walletProvider.withdrawDeposit(deposit.depositId);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF4CAF50),
                                        side: const BorderSide(color: Color(0xFF4CAF50)),
                                      ),
                                      child: const Text('Withdraw CD & Interest'),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CreateDepositSheet extends StatefulWidget {
  const _CreateDepositSheet();

  @override
  State<_CreateDepositSheet> createState() => _CreateDepositSheetState();
}

class _CreateDepositSheetState extends State<_CreateDepositSheet> {
  int _selectedTermMonths = 1;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New FuegoCD',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Select Term Length',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Months selection
          Row(
            children: [
              _buildTermChip(1, '1 Month'),
              const SizedBox(width: 8),
              _buildTermChip(3, '3 Months'),
              const SizedBox(width: 8),
              _buildTermChip(6, '6 Months'),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Select Tier',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildTierCard(
            amount: 8000,
            description: 'Standard Tier CD',
            onTap: () => _submitDeposit(8000),
          ),
          const SizedBox(height: 12),
          _buildTierCard(
            amount: 80000,
            description: 'Mid Tier CD',
            onTap: () => _submitDeposit(80000),
          ),
          const SizedBox(height: 12),
          _buildTierCard(
            amount: 800000,
            description: 'Whale Tier CD',
            onTap: () => _submitDeposit(800000),
          ),
        ],
      ),
    );
  }

  Widget _buildTermChip(int months, String label) {
    final isSelected = _selectedTermMonths == months;
    return GestureDetector(
      onTap: () => setState(() => _selectedTermMonths = months),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTierCard({
    required int amount,
    required String description,
    required VoidCallback onTap,
  }) {
    final numberFormat = NumberFormat('#,##0', 'en_US');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.textMuted.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${numberFormat.format(amount)} XFG',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  void _submitDeposit(int amount) async {
    final term = _selectedTermMonths; // months
    Navigator.of(context).pop();

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    if (!walletProvider.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not connected to daemon'), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Creating CD Deposit...'),
          ],
        ),
      ),
    );

    try {
      await walletProvider.createDeposit(amount: amount, term: term);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CD Deposit Created!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
