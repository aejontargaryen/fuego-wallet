// Copyright (c) 2025-2026 Fuego Developers
// Copyright (c) 2025-2026 Elderfire Privacy Group
//
// Dynamic supply statistics model.
// Maps to wallet RPC: getDynamicSupplyOverview

import 'fuego_constants.dart';

class SupplyStats {
  final int baseTotalSupply;        // all XFG ever created (coinbase emissions)
  final int realTotalSupply;        // base - burned
  final int totalDepositAmount;     // locked in CDs (minus burns)
  final int circulatingSupply;      // real - deposits
  final int etherealXfg;            // burned forever (eternal flame)
  final int currentDepositAmount;   // current amount in all deposits

  // Percentages
  final double burnPercentage;
  final double depositPercentage;
  final double circulatingPercentage;

  const SupplyStats({
    required this.baseTotalSupply,
    required this.realTotalSupply,
    required this.totalDepositAmount,
    required this.circulatingSupply,
    required this.etherealXfg,
    required this.currentDepositAmount,
    required this.burnPercentage,
    required this.depositPercentage,
    required this.circulatingPercentage,
  });

  factory SupplyStats.fromJson(Map<String, dynamic> json) {
    return SupplyStats(
      baseTotalSupply: json['baseTotalSupply'] as int? ?? 0,
      realTotalSupply: json['realTotalSupply'] as int? ?? 0,
      totalDepositAmount: json['totalDepositAmount'] as int? ?? 0,
      circulatingSupply: json['circulatingSupply'] as int? ?? 0,
      etherealXfg: json['ethereal_xfg'] as int? ?? json['etherealXfg'] as int? ?? 0,
      currentDepositAmount: json['currentDepositAmount'] as int? ?? 0,
      burnPercentage: (json['burnPercentage'] as num?)?.toDouble() ?? 0.0,
      depositPercentage: (json['depositPercentage'] as num?)?.toDouble() ?? 0.0,
      circulatingPercentage: (json['circulatingPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // ── XFG display values ──
  double get baseTotalXFG => FuegoConstants.toXFG(baseTotalSupply);
  double get realTotalXFG => FuegoConstants.toXFG(realTotalSupply);
  double get depositsXFG => FuegoConstants.toXFG(totalDepositAmount);
  double get circulatingXFG => FuegoConstants.toXFG(circulatingSupply);
  double get burnedXFG => FuegoConstants.toXFG(etherealXfg);

  // ── Formatted strings ──
  String get formattedBase => FuegoConstants.formatXFG(baseTotalSupply);
  String get formattedReal => FuegoConstants.formatXFG(realTotalSupply);
  String get formattedDeposits => FuegoConstants.formatXFG(totalDepositAmount);
  String get formattedCirculating => FuegoConstants.formatXFG(circulatingSupply);
  String get formattedBurned => FuegoConstants.formatXFG(etherealXfg);

  /// Percentage of total supply that has been emitted so far.
  double get emissionProgress =>
      baseTotalSupply > 0 ? (baseTotalSupply / FuegoConstants.MONEY_SUPPLY) * 100 : 0;

  @override
  String toString() =>
      'SupplyStats(circulating: $formattedCirculating, '
      'burned: $formattedBurned [${burnPercentage.toStringAsFixed(2)}%])';
}
