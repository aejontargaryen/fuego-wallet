import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/wallet_provider.dart';
import '../../utils/theme.dart';
import '../../models/swap_model.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  final _amountController = TextEditingController();
  SwapPair _selectedPair = SwapPair.xfgBtc;
  final bool _isSwapping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshOffers();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _refreshOffers() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    await walletProvider.refreshSwapOffers(_selectedPair);
    await walletProvider.refreshSwapPrice(_selectedPair);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Atomic Swap',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          final offers = walletProvider.swapOffers;
          final price = walletProvider.currentPrice;

          return RefreshIndicator(
            onRefresh: _refreshOffers,
            color: AppTheme.primaryColor,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPairHeader(walletProvider),
                  const SizedBox(height: 24),
                  _buildSwapInputCard(price),
                  const SizedBox(height: 32),
                  const Text(
                    'Active Offers (Fee Pool Driven)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (offers.isEmpty)
                    _buildEmptyState()
                  else
                    ...offers.map((offer) => _buildOfferCard(offer)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPairHeader(WalletProvider walletProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trading Pair',
                style: TextStyle(color: AppTheme.textMuted),
              ),
              DropdownButton<SwapPair>(
                value: _selectedPair,
                dropdownColor: AppTheme.surfaceColor,
                underline: const SizedBox(),
                items: SwapPair.values.map((pair) {
                  return DropdownMenuItem(
                    value: pair,
                    child: Text(
                      pair.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPair = value);
                    _refreshOffers();
                  }
                },
              ),
            ],
          ),
          const Divider(height: 32, thickness: 0.5, color: AppTheme.textMuted),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Wallet Balance',
                style: TextStyle(color: AppTheme.textMuted),
              ),
              Text(
                '${walletProvider.wallet?.unlockedBalanceXFG.toStringAsFixed(7) ?? '0.0000000'} XFG',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwapInputCard(SwapPrice? price) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Swap XFG',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(color: AppTheme.textMuted),
              suffixText: 'XFG',
              suffixStyle: TextStyle(fontSize: 18, color: AppTheme.primaryColor),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rate:', style: TextStyle(color: AppTheme.textMuted)),
              Text(
                price != null 
                  ? '1 XFG = ${price.compositeRate} ${_selectedPair.label.split('/').last}' 
                  : 'Fetching rate...',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSwapping ? null : () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSwapping
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Initiate Atomic Swap',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(SwapOffer offer) {
    return Card(
      color: AppTheme.surfaceColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.textMuted.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount: ${offer.xfgAmountDisplay} XFG',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Rate: 1 XFG = 0.00...${offer.rateNum}', // Simplified display
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Take Offer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.swap_calls, size: 48, color: AppTheme.textMuted.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'No offers for this pair',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
