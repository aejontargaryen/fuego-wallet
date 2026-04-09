// Copyright (c) 2025-2026 Fuego Developers
// Copyright (c) 2025-2026 Elderfire Privacy Group
//
// Fee pool model — atomic swap fees → CD yield pool.
// Maps to daemon RPC: /get_fee_pool_info

import 'fuego_constants.dart';

class FeePoolModel {
  final int feePoolBalance;             // total XFG available for CD interest payouts
  final int currentEpochSwapFees;       // swap fees collected this epoch
  final int totalCDLocked;              // total XFG locked in active CDs
  final int currentEpochNumber;
  final int activeEfierCount;           // legacy — may be 0
  final int efierSwapRewardPerBlock;    // legacy — may be 0

  const FeePoolModel({
    required this.feePoolBalance,
    required this.currentEpochSwapFees,
    required this.totalCDLocked,
    required this.currentEpochNumber,
    this.activeEfierCount = 0,
    this.efierSwapRewardPerBlock = 0,
  });

  factory FeePoolModel.fromJson(Map<String, dynamic> json) {
    return FeePoolModel(
      feePoolBalance: json['fee_pool_balance'] as int? ?? 0,
      currentEpochSwapFees: json['current_epoch_swap_fees'] as int? ?? 0,
      totalCDLocked: json['total_cd_locked'] as int? ?? 0,
      currentEpochNumber: json['current_epoch_number'] as int? ?? 0,
      activeEfierCount: json['active_efier_count'] as int? ?? 0,
      efierSwapRewardPerBlock: json['efier_swap_reward_per_block'] as int? ?? 0,
    );
  }

  double get feePoolXFG => FuegoConstants.toXFG(feePoolBalance);
  double get currentEpochSwapFeesXFG => FuegoConstants.toXFG(currentEpochSwapFees);
  double get totalCDLockedXFG => FuegoConstants.toXFG(totalCDLocked);

  /// Percentage of swap fees that flow to CD yield (80%).
  double get cdYieldShareXFG =>
      FuegoConstants.toXFG((currentEpochSwapFees * FuegoConstants.SWAP_FEE_CD_SHARE_PCT) ~/ 100);

  String get formattedPoolBalance => FuegoConstants.formatXFG(feePoolBalance);
  String get formattedCDLocked => FuegoConstants.formatXFG(totalCDLocked);

  @override
  String toString() =>
      'FeePool(balance: $formattedPoolBalance, epoch: $currentEpochNumber, '
      'cdLocked: $formattedCDLocked)';
}

/// Summary of a past epoch's fee distribution.
class EpochSummary {
  final int epochNumber;
  final int swapFeesCollected;
  final int totalCDLockedAtStart;
  final int feeRateFixedPoint;
  final int totalFeesDistributed;
  final int activeEfierCount;

  const EpochSummary({
    required this.epochNumber,
    required this.swapFeesCollected,
    required this.totalCDLockedAtStart,
    required this.feeRateFixedPoint,
    required this.totalFeesDistributed,
    this.activeEfierCount = 0,
  });

  factory EpochSummary.fromJson(Map<String, dynamic> json) {
    return EpochSummary(
      epochNumber: json['epoch_number'] as int? ?? 0,
      swapFeesCollected: json['swap_fees_collected'] as int? ?? 0,
      totalCDLockedAtStart: json['total_cd_locked_at_start'] as int? ?? 0,
      feeRateFixedPoint: json['fee_rate_fixed_point'] as int? ?? 0,
      totalFeesDistributed: json['total_fees_distributed'] as int? ?? 0,
      activeEfierCount: json['active_efier_count'] as int? ?? 0,
    );
  }

  double get swapFeesXFG => FuegoConstants.toXFG(swapFeesCollected);
  double get distributedXFG => FuegoConstants.toXFG(totalFeesDistributed);
}
