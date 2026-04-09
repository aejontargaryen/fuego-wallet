import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/wallet_provider.dart';
import '../../utils/theme.dart';
import '../../models/fuego_constants.dart';

class SupplyDashboardScreen extends StatelessWidget {
  const SupplyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0.00', 'en_US');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Network Supply',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          final stats = walletProvider.supplyStats;

          return RefreshIndicator(
            onRefresh: () => walletProvider.refreshSupplyStats(),
            color: AppTheme.primaryColor,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCard(
                    title: 'Total Base Supply',
                    value: stats != null ? stats.formattedBase : 'Loading...',
                    subtitle: 'Max: ${numberFormat.format(FuegoConstants.MONEY_SUPPLY / FuegoConstants.COIN)} XFG',
                    icon: Icons.pie_chart,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildStatCard(
                    title: 'Real Total Supply',
                    value: stats != null ? stats.formattedReal : 'Loading...',
                    subtitle: 'Base supply minus burns',
                    icon: Icons.show_chart,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),

                  _buildStatCard(
                    title: 'Fees Collected (Reserve)',
                    value: stats != null ? stats.formattedDeposits : 'Loading...',
                    subtitle: 'Cumulative swap fees in pool',
                    icon: Icons.account_balance,
                    color: AppTheme.successColor,
                  ),
                  const SizedBox(height: 16),

                  _buildStatCard(
                    title: 'CDs Total Locked',
                    value: stats != null ? stats.formattedDeposits : 'Loading...',
                    subtitle: 'Tokens currently earning yield',
                    icon: Icons.lock,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),

                  _buildStatCard(
                    title: 'Burned Supply',
                    value: stats != null ? stats.formattedBurned : 'Loading...',
                    subtitle: 'Permanently removed from XFG',
                    icon: Icons.local_fire_department,
                    color: Colors.red,
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
