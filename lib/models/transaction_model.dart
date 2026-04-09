// Copyright (c) 2025-2026 Fuego Developers
// Copyright (c) 2025-2026 Elderfire Privacy Group

import 'fuego_constants.dart';

/// Transaction types in the Fuego protocol.
enum TransactionType {
  transfer,
  burn,
  depositCreate,
  depositWithdraw,
  fusion,
  unknown;

  static TransactionType fromString(String s) {
    switch (s.toLowerCase()) {
      case 'burn': return TransactionType.burn;
      case 'deposit_create': return TransactionType.depositCreate;
      case 'deposit_withdraw': return TransactionType.depositWithdraw;
      case 'fusion': return TransactionType.fusion;
      case 'transfer': return TransactionType.transfer;
      default: return TransactionType.unknown;
    }
  }

  String get label {
    switch (this) {
      case TransactionType.transfer: return 'Transfer';
      case TransactionType.burn: return 'Burn → HEAT';
      case TransactionType.depositCreate: return 'Open CD';
      case TransactionType.depositWithdraw: return 'Withdraw CD';
      case TransactionType.fusion: return 'Fusion';
      case TransactionType.unknown: return 'Unknown';
    }
  }
}

class TransactionModel {
  final String id;
  final String fromAddress;
  final String? toAddress;
  final String amount;
  final String fee;
  final String timestamp;
  final String status;
  final TransactionType type;
  final String? txHash;
  final String? memo;
  final int firstDepositId;
  final int depositCount;

  TransactionModel({
    required this.id,
    required this.fromAddress,
    this.toAddress,
    required this.amount,
    required this.fee,
    required this.timestamp,
    required this.status,
    required this.type,
    this.txHash,
    this.memo,
    this.firstDepositId = -1,
    this.depositCount = 0,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      fromAddress: json['from_address'] ?? '',
      toAddress: json['to_address'],
      amount: json['amount'] ?? '0',
      fee: json['fee'] ?? '0',
      timestamp: json['timestamp'] ?? '',
      status: json['status'] ?? 'pending',
      type: TransactionType.fromString(json['type'] ?? 'transfer'),
      txHash: json['tx_hash'],
      memo: json['memo'],
      firstDepositId: json['first_deposit_id'] as int? ?? -1,
      depositCount: json['deposit_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_address': fromAddress,
      'to_address': toAddress,
      'amount': amount,
      'fee': fee,
      'timestamp': timestamp,
      'status': status,
      'type': type.name,
      'tx_hash': txHash,
      'memo': memo,
      'first_deposit_id': firstDepositId,
      'deposit_count': depositCount,
    };
  }

  /// True if this is a burn transaction.
  bool get isBurnTransaction => type == TransactionType.burn;

  /// True if this transaction involves a deposit.
  bool get hasDeposit => depositCount > 0;

  /// True if this is a CD-related transaction.
  bool get isCDTransaction =>
      type == TransactionType.depositCreate ||
      type == TransactionType.depositWithdraw;

  /// Get formatted amount for display.
  String get formattedAmount {
    final amountDouble = double.tryParse(amount) ?? 0.0;
    return '${amountDouble.toStringAsFixed(FuegoConstants.DECIMAL_POINT)} XFG';
  }

  /// Get formatted fee for display.
  String get formattedFee {
    final feeDouble = double.tryParse(fee) ?? 0.0;
    return '${feeDouble.toStringAsFixed(4)} XFG';
  }

  /// Get formatted timestamp for display.
  String get formattedTimestamp {
    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
          '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, type: ${type.label}, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}