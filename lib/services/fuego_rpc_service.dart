// Copyright (c) 2025-2026 Fuego Developers
// Copyright (c) 2025-2026 Elderfire Privacy Group

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import '../models/wallet.dart';
import '../models/network_config.dart';
import '../models/fuego_constants.dart';
import '../models/deposit_model.dart';
import '../models/fee_pool_model.dart';
import '../models/swap_model.dart';
import '../models/supply_stats_model.dart';
import '../models/alias_model.dart';

class FuegoRPCService {
  final Dio _dio;
  String _baseUrl;
  final String? _password;
  NetworkConfig _networkConfig;

  FuegoRPCService({
    String host = 'localhost',
    int? port,
    String? password,
    NetworkConfig? networkConfig,
    Dio? dio,
  })  : _networkConfig = networkConfig ?? NetworkConfig.mainnet,
        _password = password,
        _baseUrl = 'http://$host:${port ?? (networkConfig ?? NetworkConfig.mainnet).daemonRpcPort}',
        _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        ));

  // ── Connection Management ──

  void updateNode(String host, {int? port}) {
    _baseUrl = 'http://$host:${port ?? _networkConfig.daemonRpcPort}';
  }

  void updateNetworkConfig(NetworkConfig config) {
    _networkConfig = config;
    final uri = Uri.parse(_baseUrl);
    _baseUrl = 'http://${uri.host}:${config.daemonRpcPort}';
  }

  NetworkConfig get networkConfig => _networkConfig;
  String get currentNodeUrl => _baseUrl;

  /// Get default remote nodes from network config.
  List<String> get defaultRemoteNodes => _networkConfig.defaultDaemonNodes;

  // ═══════════════════════════════════════════════════════════════════
  //  DAEMON RPC METHODS (via /json_rpc on daemon port)
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getInfo() async {
    return _makeDaemonRPCCall('getinfo', {});
  }

  Future<int> getHeight() async {
    final response = await _makeDaemonRPCCall('getheight', {});
    return response['height'] as int;
  }

  Future<Map<String, dynamic>> getBlockHash(int height) async {
    return _makeDaemonRPCCall('on_getblockhash', [height]);
  }

  Future<Map<String, dynamic>> getBlock(String hash) async {
    return _makeDaemonRPCCall('getblock', {'hash': hash});
  }

  // ── Fee Pool ──

  /// Get fee pool state: balance, epoch swap fees, total CD locked, epoch #.
  Future<FeePoolModel> getFeePoolInfo() async {
    final response = await _makeDaemonHTTPCall('/get_fee_pool_info');
    return FeePoolModel.fromJson(response);
  }

  /// Get past epoch summaries.
  Future<List<EpochSummary>> getEpochHistory({int count = 10}) async {
    final response = await _makeDaemonHTTPCall('/get_epoch_history', body: {'count': count});
    final epochs = response['epochs'] as List? ?? [];
    return epochs.map((e) => EpochSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Estimate CD yield for a given amount and creation height.
  Future<Map<String, dynamic>> estimateCDYield({
    required int amount,
    required int creationHeight,
    int currentHeight = 0,
  }) async {
    return _makeDaemonHTTPCall('/estimate_cd_yield', body: {
      'amount': amount,
      'creation_height': creationHeight,
      'current_height': currentHeight,
    });
  }

  /// Get treasury balance.
  Future<int> getTreasuryBalance() async {
    final response = await _makeDaemonHTTPCall('/get_treasury_info');
    return response['treasury_balance'] as int? ?? 0;
  }

  /// Get total burned XFG (ethereal flame).
  Future<Map<String, dynamic>> getEthernalFlame() async {
    return _makeDaemonHTTPCall('/get_ethernal_flame');
  }

  // ── Swap Orderbook ──

  /// Get swap offers for a given pair.
  Future<List<SwapOffer>> getSwapOffers(SwapPair pair) async {
    final response = await _makeDaemonHTTPCall('/get_swap_offers', body: {
      'pair': pair.value,
    });
    final offers = response['offers'] as List? ?? [];
    return offers.map((o) => SwapOffer.fromJson(o as Map<String, dynamic>)).toList();
  }

  /// Get swap price (TWAP, composite, USD range).
  Future<SwapPrice> getSwapPrice(SwapPair pair) async {
    final response = await _makeDaemonHTTPCall('/get_swap_price', body: {
      'pair': pair.value,
    });
    return SwapPrice.fromJson(response);
  }

  /// Get recent swap trades.
  Future<List<SwapTrade>> getSwapTrades(SwapPair pair, {int limit = 50}) async {
    final response = await _makeDaemonHTTPCall('/get_swap_trades', body: {
      'pair': pair.value,
      'limit': limit,
    });
    final trades = response['trades'] as List? ?? [];
    return trades.map((t) => SwapTrade.fromJson(t as Map<String, dynamic>)).toList();
  }

  /// List all persisted swaps.
  Future<List<SwapStatus>> listSwaps() async {
    final response = await _makeDaemonHTTPCall('/list_swaps');
    final swaps = response['swaps'] as List? ?? [];
    return swaps.map((s) => SwapStatus.fromJson(s as Map<String, dynamic>)).toList();
  }

  /// Get status of a single swap.
  Future<SwapStatus> getSwapStatus(String swapId) async {
    final response = await _makeDaemonHTTPCall('/get_swap_status', body: {
      'swap_id': swapId,
    });
    return SwapStatus.fromJson(response);
  }

  // ── Fire Alias ──

  /// Resolve a Fire Alias to an address.
  Future<FireAlias> getAlias(String alias) async {
    final response = await _makeDaemonHTTPCall('/get_alias', body: {
      'alias': alias,
    });
    return FireAlias.fromJson(response);
  }

  /// Reverse lookup: address → alias.
  Future<FireAlias> getAliasByAddress(String address) async {
    final response = await _makeDaemonHTTPCall('/get_alias_by_address', body: {
      'address': address,
    });
    return FireAlias.fromJson(response);
  }

  /// Get all registered aliases.
  Future<List<FireAlias>> getAllAliases() async {
    final response = await _makeDaemonHTTPCall('/get_all_aliases');
    final aliases = response['aliases'] as List? ?? [];
    return aliases.map((a) => FireAlias.fromJson(a as Map<String, dynamic>)).toList();
  }

  // ── Commitment Stats (bridge) ──

  Future<Map<String, dynamic>> getCommitmentStats() async {
    return _makeDaemonHTTPCall('/get_commitment_stats');
  }

  // ── Mining ──

  Future<bool> startMining({String? address, int threads = 1}) async {
    try {
      final minerAddress = address ?? await getAddress();
      await _makeDaemonRPCCall('start_mining', {
        'miner_address': minerAddress,
        'threads_count': threads,
      });
      return true;
    } catch (e) {
      throw FuegoRPCException('Failed to start mining: $e');
    }
  }

  Future<bool> stopMining() async {
    try {
      await _makeDaemonRPCCall('stop_mining', {});
      return true;
    } catch (e) {
      throw FuegoRPCException('Failed to stop mining: $e');
    }
  }

  Future<Map<String, dynamic>> getMiningStatus() async {
    try {
      final info = await getInfo();
      return {
        'active': (info['mining_speed'] as int? ?? 0) > 0,
        'speed': info['mining_speed'] as int? ?? 0,
        'threads': info['threads_count'] as int? ?? 0,
      };
    } catch (e) {
      throw FuegoRPCException('Failed to get mining status: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  WALLET RPC METHODS (via /json_rpc on walletd port)
  // ═══════════════════════════════════════════════════════════════════

  // ── Balance & Address ──

  Future<Wallet> getBalance() async {
    try {
      final response = await _makeWalletRPCCall('getBalance', {});
      final info = await getInfo();

      return Wallet(
        address: '',
        viewKey: '',
        spendKey: '',
        balance: response['availableBalance'] as int? ?? 0,
        unlockedBalance: response['lockedAmount'] as int? ?? 0,
        lockedDepositBalance: response['lockedDepositBalance'] as int? ?? 0,
        unlockedDepositBalance: response['unlockedDepositBalance'] as int? ?? 0,
        blockchainHeight: info['height'] as int? ?? 0,
        localHeight: response['blockCount'] as int? ?? 0,
        synced: ((info['height'] as int? ?? 0) - (response['blockCount'] as int? ?? 0)) <= 1,
      );
    } catch (e) {
      throw FuegoRPCException('Failed to get balance: $e');
    }
  }

  Future<String> getAddress() async {
    try {
      final response = await _makeWalletRPCCall('getAddresses', {});
      final addresses = response['addresses'] as List;
      return addresses.isNotEmpty ? addresses.first : '';
    } catch (e) {
      throw FuegoRPCException('Failed to get address: $e');
    }
  }

  // ── Wallet Status ──

  /// Get wallet status (depositCount, peerCount, networkId, etc.).
  Future<Map<String, dynamic>> getWalletStatus() async {
    return _makeWalletRPCCall('getStatus', {});
  }

  // ── Transactions ──

  Future<List<WalletTransaction>> getTransactions({
    int blockCount = 1000000,
    int firstBlockIndex = 0,
  }) async {
    try {
      final response = await _makeWalletRPCCall('getTransactions', {
        'blockCount': blockCount,
        'firstBlockIndex': firstBlockIndex,
      });

      final items = response['items'] as List;
      return items.map((item) {
        final transactions = item['transactions'] as List;
        return transactions.map((tx) => WalletTransaction(
          txid: tx['transactionHash'] as String,
          amount: tx['amount'] as int,
          fee: tx['fee'] as int,
          paymentId: tx['paymentId'] as String? ?? '',
          blockHeight: item['blockHash'] != null ? (item['blockIndex'] as int) : 0,
          timestamp: tx['timestamp'] as int,
          isSpending: (tx['amount'] as int) < 0,
          address: tx['transfers']?.isNotEmpty == true
              ? tx['transfers'][0]['address'] as String?
              : null,
          confirmations: tx['confirmations'] as int? ?? 0,
          firstDepositId: tx['firstDepositId'] as int? ?? -1,
          depositCount: tx['depositCount'] as int? ?? 0,
        )).toList();
      }).expand((x) => x).toList();
    } catch (e) {
      throw FuegoRPCException('Failed to get transactions: $e');
    }
  }

  Future<String> sendTransaction(SendTransactionRequest request) async {
    // Validate address prefix
    final expectedPrefix = _networkConfig.addressPrefix.toLowerCase();
    if (!request.address.toLowerCase().startsWith(expectedPrefix)) {
      throw FuegoRPCException(
        'Address must start with "$expectedPrefix" on ${_networkConfig.name}');
    }

    // Enforce v10+ minimum mixin
    if (request.mixins < FuegoConstants.MIN_TX_MIXIN_SIZE_V10) {
      throw FuegoRPCException(
        'Ring size must be at least ${FuegoConstants.MIN_TX_MIXIN_SIZE_V10}');
    }

    try {
      final response = await _makeWalletRPCCall('sendTransaction', {
        'destinations': [
          {
            'amount': request.amount,
            'address': request.address,
          }
        ],
        'fee': request.fee,
        'anonymity': request.mixins,
        'paymentId': request.paymentId.isNotEmpty ? request.paymentId : null,
      });

      return response['transactionHash'] as String;
    } catch (e) {
      throw FuegoRPCException('Failed to send transaction: $e');
    }
  }

  // ── Integrated Address & Payment ID ──

  Future<String> createIntegratedAddress(String paymentId) async {
    if (paymentId.length != 64 || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(paymentId)) {
      throw FuegoRPCException('Invalid payment ID: must be 64 hex characters');
    }

    try {
      final address = await getAddress();
      final response = await _makeWalletRPCCall('create_integrated', {
        'address': address,
        'payment_id': paymentId,
      });
      return response['integrated_address'] as String;
    } catch (e) {
      throw FuegoRPCException('Failed to create integrated address: $e');
    }
  }

  Future<String> generatePaymentId() async {
    final bytes = List<int>.generate(
        32, (i) => DateTime.now().millisecondsSinceEpoch + i);
    return sha256.convert(bytes).toString().substring(0, 64);
  }

  // ── FuegoCD (On-chain Deposits) ──

  /// Create an on-chain FuegoCD deposit.
  Future<Map<String, dynamic>> createDeposit({
    required int amount,
    required int term,
    required String sourceAddress,
  }) async {
    // Validate tier
    final tier = FuegoConstants.classifyTier(amount, testnet: _networkConfig.isTestnet);
    if (tier < 0) {
      throw FuegoRPCException(
        'Amount must match a valid tier: ${FuegoConstants.getTierAmounts(testnet: _networkConfig.isTestnet)}');
    }

    // Validate term
    final range = _networkConfig.cdTermRange;
    if (term < range.min || term > range.max) {
      throw FuegoRPCException(
        'Term must be between ${range.min} and ${range.max} blocks');
    }

    try {
      return await _makeWalletRPCCall('createDeposit', {
        'amount': amount,
        'term': term,
        'sourceAddress': sourceAddress,
      });
    } catch (e) {
      throw FuegoRPCException('Failed to create deposit: $e');
    }
  }

  /// Withdraw a matured CD deposit + interest.
  Future<String> withdrawDeposit(int depositId) async {
    try {
      final response = await _makeWalletRPCCall('withdrawDeposit', {
        'depositId': depositId,
      });
      return response['transactionHash'] as String;
    } catch (e) {
      throw FuegoRPCException('Failed to withdraw deposit: $e');
    }
  }

  /// Get details of a single deposit.
  Future<DepositModel> getDeposit(int depositId) async {
    try {
      final response = await _makeWalletRPCCall('getDeposit', {
        'depositId': depositId,
      });
      return DepositModel.fromJson({
        'depositId': depositId,
        ...response,
      });
    } catch (e) {
      throw FuegoRPCException('Failed to get deposit: $e');
    }
  }

  /// Get all deposits by iterating over depositCount from getStatus.
  Future<List<DepositModel>> getAllDeposits() async {
    try {
      final status = await getWalletStatus();
      final depositCount = status['depositCount'] as int? ?? 0;
      final deposits = <DepositModel>[];

      for (int i = 0; i < depositCount; i++) {
        try {
          final deposit = await getDeposit(i);
          deposits.add(deposit);
        } catch (_) {
          // Skip deposits that can't be retrieved (spent/invalid)
        }
      }

      return deposits;
    } catch (e) {
      throw FuegoRPCException('Failed to get deposits: $e');
    }
  }

  // ── Burn Deposits (HEAT Minting) ──

  /// Standard burn: 0.8 XFG → HEAT.
  Future<Map<String, dynamic>> createBurnDeposit({
    required int amount,
    required String sourceAddress,
    String metadata = '',
  }) async {
    try {
      return await _makeWalletRPCCall('createBurnDeposit', {
        'amount': amount,
        'sourceAddress': sourceAddress,
        if (metadata.isNotEmpty) 'metadata': metadata,
      });
    } catch (e) {
      throw FuegoRPCException('Failed to create burn deposit: $e');
    }
  }

  /// Large burn: 800 XFG → HEAT.
  Future<Map<String, dynamic>> createBurnDepositLarge({
    required String sourceAddress,
    String metadata = '',
  }) async {
    try {
      return await _makeWalletRPCCall('createBurnDepositLarge', {
        'sourceAddress': sourceAddress,
        if (metadata.isNotEmpty) 'metadata': metadata,
      });
    } catch (e) {
      throw FuegoRPCException('Failed to create large burn deposit: $e');
    }
  }

  // ── Supply Stats ──

  /// Get dynamic supply overview (base, real, circulating, burned, deposits).
  Future<SupplyStats> getDynamicSupplyOverview() async {
    try {
      final response = await _makeWalletRPCCall('getDynamicSupplyOverview', {});
      return SupplyStats.fromJson(response);
    } catch (e) {
      throw FuegoRPCException('Failed to get supply overview: $e');
    }
  }

  /// Get money supply stats.
  Future<Map<String, dynamic>> getMoneySupplyStats() async {
    return _makeWalletRPCCall('getMoneySupplyStats', {});
  }

  // ── View Key ──

  Future<String> getViewKey() async {
    try {
      final response = await _makeWalletRPCCall('getViewKey', {});
      return response['viewSecretKey'] as String? ?? '';
    } catch (e) {
      throw FuegoRPCException('Failed to get view key: $e');
    }
  }

  // ── Fusion ──

  Future<Map<String, dynamic>> estimateFusion({
    required int threshold,
    List<String> addresses = const [],
  }) async {
    return _makeWalletRPCCall('estimateFusion', {
      'threshold': threshold,
      'addresses': addresses,
    });
  }

  Future<String> sendFusionTransaction({
    required int threshold,
    int anonymity = 0,
    List<String> addresses = const [],
    String destinationAddress = '',
  }) async {
    try {
      final response = await _makeWalletRPCCall('sendFusionTransaction', {
        'threshold': threshold,
        'anonymity': anonymity,
        'addresses': addresses,
        'destinationAddress': destinationAddress,
      });
      return response['transactionHash'] as String;
    } catch (e) {
      throw FuegoRPCException('Failed to send fusion transaction: $e');
    }
  }

  // ── Messages ──

  Future<bool> sendMessage({
    required String recipientAddress,
    required String message,
    bool selfDestruct = false,
    int? destructTime,
  }) async {
    try {
      await _makeDaemonRPCCall('send_message', {
        'recipient': recipientAddress,
        'message': message,
        'self_destruct': selfDestruct,
        'destruct_time': destructTime,
      });
      return true;
    } catch (e) {
      throw FuegoRPCException('Failed to send message: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMessages() async {
    try {
      final response = await _makeDaemonRPCCall('get_messages', {});
      return List<Map<String, dynamic>>.from(response['messages'] as List);
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  CONNECTION TEST
  // ═══════════════════════════════════════════════════════════════════

  Future<bool> testConnection() async {
    try {
      await getInfo();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PRIVATE TRANSPORT METHODS
  // ═══════════════════════════════════════════════════════════════════

  /// JSON-RPC call to daemon (json_rpc endpoint).
  Future<Map<String, dynamic>> _makeDaemonRPCCall(
    String method,
    dynamic params,
  ) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/json_rpc',
        data: json.encode({
          'jsonrpc': '2.0',
          'id': DateTime.now().millisecondsSinceEpoch,
          'method': method,
          'params': params,
        }),
      );

      final data = response.data as Map<String, dynamic>;

      if (data.containsKey('error')) {
        throw FuegoRPCException(data['error']['message'] as String);
      }

      return data['result'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw FuegoRPCException('Network error: ${e.message}');
    }
  }

  /// Direct HTTP call to daemon (non-json_rpc endpoints like /get_fee_pool_info).
  Future<Map<String, dynamic>> _makeDaemonHTTPCall(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl$endpoint',
        data: body != null ? json.encode(body) : '{}',
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return json.decode(data.toString()) as Map<String, dynamic>;
    } on DioException catch (e) {
      throw FuegoRPCException('Network error on $endpoint: ${e.message}');
    }
  }

  /// JSON-RPC call to walletd (PaymentGate service).
  Future<Map<String, dynamic>> _makeWalletRPCCall(
    String method,
    Map<String, dynamic> params,
  ) async {
    try {
      final walletUrl = 'http://localhost:${_networkConfig.walletRpcPort}';

      final response = await _dio.post(
        '$walletUrl/json_rpc',
        data: json.encode({
          'jsonrpc': '2.0',
          'id': DateTime.now().millisecondsSinceEpoch,
          'method': method,
          'params': params,
        }),
      );

      final data = response.data as Map<String, dynamic>;

      if (data.containsKey('error')) {
        throw FuegoRPCException(data['error']['message'] as String);
      }

      return data['result'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw FuegoRPCException('Wallet service error: ${e.message}');
    }
  }

  void dispose() {
    _dio.close();
  }
}

class FuegoRPCException implements Exception {
  final String message;

  FuegoRPCException(this.message);

  @override
  String toString() => 'FuegoRPCException: $message';
}
