// Copyright (c) 2025-2026 Fuego Developers
// Copyright (c) 2025-2026 Elderfire Privacy Group

import 'dart:async';
import 'package:logging/logging.dart';
import '../models/fuego_constants.dart';
import 'fuego_rpc_service.dart';

/// Analytics for burn operations.
class BurnProofAnalytics {
  static final Logger _logger = Logger('BurnProofService');

  static void logBurnExecution(BurnResult result) {
    _logger.info('Burn Executed: '
      'Amount: ${result.burnAmountXFG} XFG, '
      'Type: ${result.burnType}, '
      'TX Hash: ${result.transactionHash}');
  }

  static void logBurnError(dynamic error, StackTrace stackTrace) {
    _logger.severe('Burn Execution Failed', error, stackTrace);
  }
}

/// Result of a burn deposit operation.
class BurnResult {
  final String transactionHash;
  final int burnAmount;         // atomic units
  final String burnType;        // 'standard' or 'large'
  final DateTime timestamp;

  const BurnResult({
    required this.transactionHash,
    required this.burnAmount,
    required this.burnType,
    required this.timestamp,
  });

  double get burnAmountXFG => FuegoConstants.toXFG(burnAmount);

  Map<String, dynamic> toJson() => {
    'transactionHash': transactionHash,
    'burnAmount': burnAmount,
    'burnType': burnType,
    'timestamp': timestamp.toIso8601String(),
  };

  factory BurnResult.fromJson(Map<String, dynamic> json) => BurnResult(
    transactionHash: json['transactionHash'] as String,
    burnAmount: json['burnAmount'] as int,
    burnType: json['burnType'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

/// Service for burn and deposit operations.
/// Routes all operations through the PaymentGate wallet RPC.
class CLIService {
  static final Logger _logger = Logger('CLIService');
  static FuegoRPCService? _rpcService;

  /// Set the RPC service instance for burn operations.
  static void setRPCService(FuegoRPCService rpcService) {
    _rpcService = rpcService;
  }

  /// Burn denominations — corrected to match CryptoNoteConfig.h.
  static Map<String, int> getBurnDenominations({bool testnet = false}) {
    if (testnet) {
      return {
        'Standard Burn (0.08 TEST)': FuegoConstants.TEST_AMOUNT_TIER_0,
        'Large Burn (80 TEST)': FuegoConstants.TEST_AMOUNT_TIER_3,
      };
    }
    return {
      'Standard Burn (0.8 XFG)': FuegoConstants.AMOUNT_TIER_0,
      'Large Burn (800 XFG)': FuegoConstants.AMOUNT_TIER_3,
    };
  }

  /// Execute a standard burn (Tier 0: 0.8 XFG) via wallet RPC.
  static Future<BurnResult> executeStandardBurn({
    required String sourceAddress,
    String metadata = '',
  }) async {
    _ensureRPCService();

    try {
      final response = await _rpcService!.createBurnDeposit(
        amount: FuegoConstants.AMOUNT_TIER_0,
        sourceAddress: sourceAddress,
        metadata: metadata,
      );

      final result = BurnResult(
        transactionHash: response['transactionHash'] as String? ?? '',
        burnAmount: FuegoConstants.AMOUNT_TIER_0,
        burnType: 'standard',
        timestamp: DateTime.now(),
      );

      BurnProofAnalytics.logBurnExecution(result);
      return result;
    } catch (e, stackTrace) {
      BurnProofAnalytics.logBurnError(e, stackTrace);
      rethrow;
    }
  }

  /// Execute a large burn (Tier 3: 800 XFG) via wallet RPC.
  static Future<BurnResult> executeLargeBurn({
    required String sourceAddress,
    String metadata = '',
  }) async {
    _ensureRPCService();

    try {
      final response = await _rpcService!.createBurnDepositLarge(
        sourceAddress: sourceAddress,
        metadata: metadata,
      );

      final result = BurnResult(
        transactionHash: response['transactionHash'] as String? ?? '',
        burnAmount: FuegoConstants.AMOUNT_TIER_3,
        burnType: 'large',
        timestamp: DateTime.now(),
      );

      BurnProofAnalytics.logBurnExecution(result);
      return result;
    } catch (e, stackTrace) {
      BurnProofAnalytics.logBurnError(e, stackTrace);
      rethrow;
    }
  }

  /// Execute a burn of any supported tier via wallet RPC.
  static Future<BurnResult> executeBurn({
    required String sourceAddress,
    required int amount,
    String metadata = '',
  }) async {
    if (amount == FuegoConstants.AMOUNT_TIER_3 ||
        amount == FuegoConstants.TEST_AMOUNT_TIER_3) {
      return executeLargeBurn(
        sourceAddress: sourceAddress,
        metadata: metadata,
      );
    }

    _ensureRPCService();

    try {
      final response = await _rpcService!.createBurnDeposit(
        amount: amount,
        sourceAddress: sourceAddress,
        metadata: metadata,
      );

      final result = BurnResult(
        transactionHash: response['transactionHash'] as String? ?? '',
        burnAmount: amount,
        burnType: amount >= FuegoConstants.AMOUNT_TIER_3 ? 'large' : 'standard',
        timestamp: DateTime.now(),
      );

      BurnProofAnalytics.logBurnExecution(result);
      return result;
    } catch (e, stackTrace) {
      BurnProofAnalytics.logBurnError(e, stackTrace);
      rethrow;
    }
  }

  /// Calculates HEAT token amount based on burn amount.
  /// Burn ratio: 1 XFG = 10,000,000 HEAT (same decimal base).
  static int calculateHeatTokens(int burnAmountAtomic) {
    // HEAT is 1:1 with atomic XFG units for standard burns
    return burnAmountAtomic;
  }

  static void _ensureRPCService() {
    if (_rpcService == null) {
      throw StateError(
        'CLIService.setRPCService() must be called before executing burns');
    }
  }
}
