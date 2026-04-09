// Copyright (c) 2025-2026 Fuego Developers
// Copyright (c) 2025-2026 Elderfire Privacy Group
//
// Atomic swap models — orderbook, trades, pricing, swap status.
// Maps to daemon RPC: /get_swap_offers, /get_swap_price,
// /get_swap_trades, /list_swaps, /get_swap_status

import 'fuego_constants.dart';

/// Swap pair identifiers.
enum SwapPair {
  xfgBtc(0, 'XFG/BTC'),
  xfgEth(1, 'XFG/ETH'),
  xfgBch(2, 'XFG/BCH'),
  xfgXmr(3, 'XFG/XMR');

  const SwapPair(this.value, this.label);
  final int value;
  final String label;

  static SwapPair fromValue(int v) =>
      SwapPair.values.firstWhere((p) => p.value == v, orElse: () => SwapPair.xfgBtc);
}

/// An offer on the atomic swap orderbook.
class SwapOffer {
  final String offerId;
  final int xfgAmount;       // atomic units
  final int rateNum;
  final SwapPair pair;
  final String makerPubKey;  // hex
  final int timestamp;
  final int ttlBlocks;
  final int postedHeight;

  const SwapOffer({
    required this.offerId,
    required this.xfgAmount,
    required this.rateNum,
    required this.pair,
    required this.makerPubKey,
    required this.timestamp,
    required this.ttlBlocks,
    required this.postedHeight,
  });

  factory SwapOffer.fromJson(Map<String, dynamic> json) {
    return SwapOffer(
      offerId: json['offerId'] as String? ?? '',
      xfgAmount: json['xfgAmount'] as int? ?? 0,
      rateNum: json['rateNum'] as int? ?? 0,
      pair: SwapPair.fromValue(json['pair'] as int? ?? 0),
      makerPubKey: json['makerPubKey'] as String? ?? '',
      timestamp: json['timestamp'] as int? ?? 0,
      ttlBlocks: json['ttlBlocks'] as int? ?? 0,
      postedHeight: json['postedHeight'] as int? ?? 0,
    );
  }

  double get xfgAmountDisplay => FuegoConstants.toXFG(xfgAmount);
  String get formattedAmount => FuegoConstants.formatXFG(xfgAmount);

  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
}

/// A completed swap trade.
class SwapTrade {
  final SwapPair pair;
  final int xfgAmount;      // atomic units
  final int ctrAmount;      // counter-asset atomic units
  final String rate;         // double as string
  final int blockHeight;
  final int timestamp;

  const SwapTrade({
    required this.pair,
    required this.xfgAmount,
    required this.ctrAmount,
    required this.rate,
    required this.blockHeight,
    required this.timestamp,
  });

  factory SwapTrade.fromJson(Map<String, dynamic> json) {
    return SwapTrade(
      pair: SwapPair.fromValue(json['pair'] as int? ?? 0),
      xfgAmount: json['xfgAmount'] as int? ?? 0,
      ctrAmount: json['ctrAmount'] as int? ?? 0,
      rate: json['rate'] as String? ?? '0',
      blockHeight: json['blockHeight'] as int? ?? 0,
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }

  double get xfgAmountDisplay => FuegoConstants.toXFG(xfgAmount);

  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
}

/// A price source contributing to the composite rate.
class PriceSource {
  final String name;
  final SwapPair pair;
  final String weight;
  final String rate;
  final int updatedAt;
  final bool stale;

  const PriceSource({
    required this.name,
    required this.pair,
    required this.weight,
    required this.rate,
    required this.updatedAt,
    required this.stale,
  });

  factory PriceSource.fromJson(Map<String, dynamic> json) {
    return PriceSource(
      name: json['name'] as String? ?? '',
      pair: SwapPair.fromValue(json['pair'] as int? ?? 0),
      weight: json['weight'] as String? ?? '0',
      rate: json['rate'] as String? ?? '0',
      updatedAt: json['updatedAt'] as int? ?? 0,
      stale: json['stale'] as bool? ?? false,
    );
  }
}

/// Swap price snapshot (TWAP, composite, USD range).
class SwapPrice {
  final String twap;
  final String seedRate;
  final String compositeRate;
  final int sourceCount;
  final List<PriceSource> sources;
  final String xfgUsdLow;
  final String xfgUsdHigh;
  final String xfgUsdMid;

  const SwapPrice({
    required this.twap,
    required this.seedRate,
    required this.compositeRate,
    required this.sourceCount,
    required this.sources,
    required this.xfgUsdLow,
    required this.xfgUsdHigh,
    required this.xfgUsdMid,
  });

  factory SwapPrice.fromJson(Map<String, dynamic> json) {
    return SwapPrice(
      twap: json['twap'] as String? ?? '0',
      seedRate: json['seedRate'] as String? ?? '0',
      compositeRate: json['compositeRate'] as String? ?? '0',
      sourceCount: json['sourceCount'] as int? ?? 0,
      sources: (json['sources'] as List<dynamic>?)
              ?.map((s) => PriceSource.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      xfgUsdLow: json['xfgUsdLow'] as String? ?? '0',
      xfgUsdHigh: json['xfgUsdHigh'] as String? ?? '0',
      xfgUsdMid: json['xfgUsdMid'] as String? ?? '0',
    );
  }

  double? get usdMid => double.tryParse(xfgUsdMid);
}

/// Status of a persisted swap (from list_swaps / get_swap_status).
class SwapStatus {
  final String swapId;
  final String state;
  final String pairLabel;
  final String role;         // "maker" or "taker"
  final int xfgAmount;
  final String ctrAddress;
  final String peerEndpoint;
  final int createdAt;
  final int updatedAt;
  final bool isTerminal;

  const SwapStatus({
    required this.swapId,
    required this.state,
    required this.pairLabel,
    required this.role,
    required this.xfgAmount,
    required this.ctrAddress,
    required this.peerEndpoint,
    required this.createdAt,
    required this.updatedAt,
    required this.isTerminal,
  });

  factory SwapStatus.fromJson(Map<String, dynamic> json) {
    return SwapStatus(
      swapId: json['swap_id'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pairLabel: json['pair'] as String? ?? '',
      role: json['role'] as String? ?? '',
      xfgAmount: json['xfg_amount'] as int? ?? 0,
      ctrAddress: json['ctr_address'] as String? ?? '',
      peerEndpoint: json['peer_endpoint'] as String? ?? '',
      createdAt: json['created_at'] as int? ?? 0,
      updatedAt: json['updated_at'] as int? ?? 0,
      isTerminal: json['is_terminal'] as bool? ?? false,
    );
  }

  double get xfgAmountDisplay => FuegoConstants.toXFG(xfgAmount);
}
