// Copyright (c) 2025-2026 Fuego Developers
// Copyright (c) 2025-2026 Elderfire Privacy Group
//
// On-chain FuegoCD (XFG-CD) deposit model.
// Maps to PaymentGate GetDeposit RPC response.

import 'fuego_constants.dart';

class DepositModel {
  final int depositId;
  final int amount;                    // atomic units
  final int term;                      // blocks (or DEPOSIT_TERM_FOREVER for burns)
  final int interest;                  // earned interest in atomic units
  final int height;                    // creation block height
  final int unlockHeight;              // maturity block height
  final String creatingTransactionHash;
  final String spendingTransactionHash;
  final bool locked;
  final String address;

  const DepositModel({
    required this.depositId,
    required this.amount,
    required this.term,
    required this.interest,
    required this.height,
    required this.unlockHeight,
    required this.creatingTransactionHash,
    required this.spendingTransactionHash,
    required this.locked,
    required this.address,
  });

  factory DepositModel.fromJson(Map<String, dynamic> json) {
    return DepositModel(
      depositId: json['depositId'] as int? ?? 0,
      amount: json['amount'] as int? ?? 0,
      term: json['term'] as int? ?? 0,
      interest: json['interest'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      unlockHeight: json['unlockHeight'] as int? ?? 0,
      creatingTransactionHash: json['creatingTransactionHash'] as String? ?? '',
      spendingTransactionHash: json['spendingTransactionHash'] as String? ?? '',
      locked: json['locked'] as bool? ?? true,
      address: json['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'depositId': depositId,
    'amount': amount,
    'term': term,
    'interest': interest,
    'height': height,
    'unlockHeight': unlockHeight,
    'creatingTransactionHash': creatingTransactionHash,
    'spendingTransactionHash': spendingTransactionHash,
    'locked': locked,
    'address': address,
  };

  // ── Computed Properties ──

  double get amountXFG => FuegoConstants.toXFG(amount);
  double get interestXFG => FuegoConstants.toXFG(interest);

  /// True if this is a permanent burn deposit (term = 4294967295).
  bool get isBurn => term == FuegoConstants.DEPOSIT_TERM_FOREVER;

  /// True if the CD has matured and can be withdrawn.
  bool get isMatured => !locked && !isBurn;

  /// True if the CD is active (locked + not a burn).
  bool get isActive => locked && !isBurn;

  /// Tier index (0-3) based on amount. -1 if not a standard tier.
  int get tier => FuegoConstants.classifyTier(amount);

  /// Human-readable tier label.
  String get tierLabel {
    switch (tier) {
      case 0: return 'Tier 0 (0.8 XFG)';
      case 1: return 'Tier 1 (8 XFG)';
      case 2: return 'Tier 2 (80 XFG)';
      case 3: return 'Tier 3 (800 XFG)';
      default: return 'Custom';
    }
  }

  /// Remaining blocks until maturity. 0 if matured or burn.
  int remainingBlocks(int currentHeight) {
    if (isBurn || !locked) return 0;
    final remaining = unlockHeight - currentHeight;
    return remaining > 0 ? remaining : 0;
  }

  /// Estimated days until maturity.
  double remainingDays(int currentHeight) {
    return FuegoConstants.blocksToDays(remainingBlocks(currentHeight));
  }

  /// Term duration in days.
  double get termDays => FuegoConstants.blocksToDays(term);

  /// Progress toward maturity (0.0 to 1.0).
  double progress(int currentHeight) {
    if (isBurn) return 1.0;
    if (!locked) return 1.0;
    final elapsed = currentHeight - height;
    if (term <= 0) return 1.0;
    return (elapsed / term).clamp(0.0, 1.0);
  }

  /// Formatted amount string.
  String get formattedAmount => FuegoConstants.formatXFG(amount);

  /// Formatted interest string.
  String get formattedInterest => FuegoConstants.formatXFG(interest);

  /// Status string for display.
  String get statusLabel {
    if (isBurn) return 'Burned';
    if (isMatured) return 'Matured';
    if (locked) return 'Locked';
    return 'Withdrawn';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepositModel && other.depositId == depositId;

  @override
  int get hashCode => depositId.hashCode;

  @override
  String toString() =>
      'DepositModel(id: $depositId, amount: $formattedAmount, '
      'term: $term, status: $statusLabel)';
}
