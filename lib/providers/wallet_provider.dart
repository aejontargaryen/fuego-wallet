// Copyright (c) 2025-2026 Fuego Developers
// Copyright (c) 2025-2026 Elderfire Privacy Group

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logging/logging.dart';
import '../models/wallet.dart';
import '../models/network_config.dart';
import '../models/fuego_constants.dart';
import '../models/deposit_model.dart';
import '../models/fee_pool_model.dart';
import '../models/swap_model.dart';
import '../models/supply_stats_model.dart';
import '../models/alias_model.dart';
import '../services/fuego_rpc_service.dart';
import '../services/security_service.dart';
import '../services/cli_service.dart';

class WalletProvider extends ChangeNotifier {
  static final Logger _logger = Logger('WalletProvider');
  final FuegoRPCService _rpcService;
  final SecurityService _securityService;
  
  Wallet? _wallet;
  List<WalletTransaction> _transactions = [];
  bool _isLoading = false;
  bool _isConnected = false;
  bool _isSyncing = false;
  bool _isMining = false;
  String? _error;
  String? _nodeUrl;
  Timer? _syncTimer;
  NetworkConfig _networkConfig = NetworkConfig.mainnet;

  // Mining status
  int _miningSpeed = 0;
  int _miningThreads = 1;

  // Network status
  ConnectivityResult _connectivityResult = ConnectivityResult.none;

  // ── CD/Deposit State ──
  List<DepositModel> _deposits = [];
  bool _depositsLoading = false;

  // ── Fee Pool State ──
  FeePoolModel? _feePool;

  // ── Supply Stats ──
  SupplyStats? _supplyStats;

  // ── Swap State ──
  List<SwapOffer> _swapOffers = [];
  List<SwapTrade> _recentTrades = [];
  SwapPrice? _currentPrice;

  // ── Alias ──
  FireAlias? _myAlias;

  WalletProvider({
    FuegoRPCService? rpcService,
    SecurityService? securityService,
  }) : _rpcService = rpcService ?? FuegoRPCService(),
       _securityService = securityService ?? SecurityService() {
    _initConnectivity();
    // Wire up CLI service to use RPC
    CLIService.setRPCService(_rpcService);
  }

  // ═══════════════════════════════════════════════════════════════════
  //  GETTERS
  // ═══════════════════════════════════════════════════════════════════

  Wallet? get wallet => _wallet;
  List<WalletTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  bool get isSyncing => _isSyncing;
  bool get isMining => _isMining;
  String? get error => _error;
  String? get nodeUrl => _nodeUrl;
  int get miningSpeed => _miningSpeed;
  int get miningThreads => _miningThreads;
  ConnectivityResult get connectivityResult => _connectivityResult;
  NetworkConfig get networkConfig => _networkConfig;

  bool get hasWallet => _wallet != null;
  bool get isWalletSynced => _wallet?.synced ?? false;
  double get syncProgress => _wallet?.syncProgress ?? 0.0;

  // CD/Deposit getters
  List<DepositModel> get deposits => _deposits;
  List<DepositModel> get activeDeposits =>
      _deposits.where((d) => d.isActive).toList();
  List<DepositModel> get maturedDeposits =>
      _deposits.where((d) => d.isMatured).toList();
  List<DepositModel> get burnDeposits =>
      _deposits.where((d) => d.isBurn).toList();
  bool get depositsLoading => _depositsLoading;

  // Fee pool getters
  FeePoolModel? get feePool => _feePool;

  // Supply getters
  SupplyStats? get supplyStats => _supplyStats;

  // Swap getters
  List<SwapOffer> get swapOffers => _swapOffers;
  List<SwapTrade> get recentTrades => _recentTrades;
  SwapPrice? get currentPrice => _currentPrice;

  // Alias getter
  FireAlias? get myAlias => _myAlias;

  // ═══════════════════════════════════════════════════════════════════
  //  PRIVATE KEY ACCESS (requires PIN)
  // ═══════════════════════════════════════════════════════════════════

  Future<String?> getPrivateKeyForBurn(String pin) async {
    try {
      _logger.info('Attempting to get private key for burn transaction');
      
      final isValidPin = await _securityService.verifyPIN(pin);
      if (!isValidPin) {
        _logger.warning('Invalid PIN provided for private key access');
        throw Exception('Invalid PIN');
      }

      final keys = await _securityService.getWalletKeys(pin);
      if (keys == null || _wallet == null) {
        _logger.severe('Wallet keys not found');
        throw Exception('Wallet keys not found');
      }

      _logger.info('Private key accessed successfully for burn transaction');
      return keys['spendKey'];
    } catch (e) {
      _logger.severe('Failed to get private key: $e');
      _setError('Failed to get private key: $e');
      return null;
    }
  }

  String? getPrivateKey() {
    if (_wallet == null) {
      _setError('Wallet not loaded');
      return null;
    }
    if (!isWalletSynced) {
      _setError('Wallet must be synced to access private key');
      return null;
    }
    return _wallet?.spendKey;
  }

  bool isValidPrivateKey(String privateKey) {
    return privateKey.isNotEmpty && privateKey.length >= 32;
  }

  void clearSensitiveData() {
    _wallet = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  CONNECTIVITY
  // ═══════════════════════════════════════════════════════════════════

  void _initConnectivity() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _connectivityResult = result;
      notifyListeners();
      
      if (result != ConnectivityResult.none) {
        _checkConnection();
      } else {
        _isConnected = false;
        notifyListeners();
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  //  WALLET MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════

  Future<bool> createWallet({
    required String pin,
    String? mnemonic,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final seed = mnemonic ?? SecurityService.generateMnemonic();
      
      if (!SecurityService.validateMnemonic(seed)) {
        throw Exception('Invalid mnemonic phrase');
      }

      await _securityService.storeWalletSeed(seed, pin);
      await _securityService.setPIN(pin);

      // TODO: Derive real CryptoNote keys from mnemonic via Rust FFI
      // This is a critical security item — placeholder keys are NOT safe
      const viewKey = 'view_key_pending_derivation';
      const spendKey = 'spend_key_pending_derivation';
      
      await _securityService.storeWalletKeys(
        viewKey: viewKey,
        spendKey: spendKey,
        pin: pin,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> restoreWallet({
    required String mnemonic,
    required String pin,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      if (!SecurityService.validateMnemonic(mnemonic)) {
        throw Exception('Invalid mnemonic phrase');
      }

      await _securityService.storeWalletSeed(mnemonic, pin);
      await _securityService.setPIN(pin);

      // TODO: Derive real CryptoNote keys from mnemonic via Rust FFI
      const viewKey = 'restored_view_key_pending_derivation';
      const spendKey = 'restored_spend_key_pending_derivation';
      
      await _securityService.storeWalletKeys(
        viewKey: viewKey,
        spendKey: spendKey,
        pin: pin,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> unlockWallet(String pin) async {
    _setLoading(true);
    _clearError();

    try {
      final isValidPin = await _securityService.verifyPIN(pin);
      if (!isValidPin) {
        throw Exception('Invalid PIN');
      }

      final keys = await _securityService.getWalletKeys(pin);
      if (keys == null) {
        throw Exception('Wallet keys not found');
      }

      await refreshWallet();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> lockWallet() async {
    _wallet = null;
    _transactions.clear();
    _deposits.clear();
    _feePool = null;
    _supplyStats = null;
    _swapOffers.clear();
    _recentTrades.clear();
    _currentPrice = null;
    _myAlias = null;
    _stopSyncTimer();
    notifyListeners();
  }

  Future<bool> hasWalletData() async {
    return await _securityService.hasWalletData();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  WALLET REFRESH
  // ═══════════════════════════════════════════════════════════════════

  Future<void> refreshWallet() async {
    if (!_isConnected) {
      await _checkConnection();
      if (!_isConnected) {
        _setError('Not connected to Fuego node');
        return;
      }
    }

    try {
      _setLoading(true);
      _clearError();

      final balance = await _rpcService.getBalance();
      final address = await _rpcService.getAddress();
      
      _wallet = balance.copyWith(address: address);
      
      if (!isWalletSynced) {
        _startSyncTimer();
      }

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshTransactions() async {
    try {
      final txs = await _rpcService.getTransactions();
      _transactions = txs;
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh transactions: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SEND TRANSACTION
  // ═══════════════════════════════════════════════════════════════════

  Future<String?> sendTransaction({
    required String address,
    required double amount,
    String? paymentId,
    int? mixins,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Resolve Fire Alias if it's not a standard address
      String resolvedAddress = address;
      if (!address.toLowerCase().startsWith(_networkConfig.addressPrefix.toLowerCase())) {
        try {
          final alias = await _rpcService.getAlias(address);
          if (alias.found) {
            resolvedAddress = alias.address;
          } else {
            throw Exception('Alias "$address" not found');
          }
        } catch (_) {
          // Not an alias, validate as address
          if (!address.toLowerCase().startsWith(_networkConfig.addressPrefix.toLowerCase())) {
            throw Exception('Invalid address or alias: "$address"');
          }
        }
      }

      final atomicAmount = FuegoConstants.toAtomic(amount);
      
      final request = SendTransactionRequest(
        address: resolvedAddress,
        amount: atomicAmount,
        paymentId: paymentId ?? '',
        fee: FuegoConstants.MINIMUM_FEE,
        mixins: mixins ?? FuegoConstants.MIN_TX_MIXIN_SIZE_V10,
      );

      final txHash = await _rpcService.sendTransaction(request);
      
      await refreshWallet();
      await refreshTransactions();
      
      _setLoading(false);
      return txHash;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  Future<String> generatePaymentId() async {
    return await _rpcService.generatePaymentId();
  }

  Future<String> createIntegratedAddress(String paymentId) async {
    return await _rpcService.createIntegratedAddress(paymentId);
  }

  // ═══════════════════════════════════════════════════════════════════
  //  CD (FUEGOCD) OPERATIONS
  // ═══════════════════════════════════════════════════════════════════

  /// Refresh all deposits from the wallet.
  Future<void> refreshDeposits() async {
    _depositsLoading = true;
    notifyListeners();

    try {
      _deposits = await _rpcService.getAllDeposits();
      _depositsLoading = false;
      notifyListeners();
    } catch (e) {
      _depositsLoading = false;
      _setError('Failed to refresh deposits: $e');
    }
  }

  /// Create a new FuegoCD.
  Future<String?> createDeposit({
    required int amount,
    required int term,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final address = await _rpcService.getAddress();

      final response = await _rpcService.createDeposit(
        amount: amount,
        term: term,
        sourceAddress: address,
      );

      final txHash = response['transactionHash'] as String?;

      await refreshWallet();
      await refreshDeposits();

      _setLoading(false);
      return txHash;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  /// Withdraw a matured CD + interest.
  Future<String?> withdrawDeposit(int depositId) async {
    _setLoading(true);
    _clearError();

    try {
      final txHash = await _rpcService.withdrawDeposit(depositId);

      await refreshWallet();
      await refreshDeposits();

      _setLoading(false);
      return txHash;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  /// Estimate yield for a prospective CD.
  Future<Map<String, dynamic>?> estimateCDYield({
    required int amount,
    int? currentHeight,
  }) async {
    try {
      return await _rpcService.estimateCDYield(
        amount: amount,
        creationHeight: currentHeight ?? (_wallet?.blockchainHeight ?? 0),
      );
    } catch (e) {
      _setError('Failed to estimate yield: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BURN (HEAT MINTING) OPERATIONS
  // ═══════════════════════════════════════════════════════════════════

  /// Execute a standard burn (0.8 XFG → HEAT).
  Future<String?> burnStandard() async {
    _setLoading(true);
    _clearError();

    try {
      final address = await _rpcService.getAddress();
      final result = await CLIService.executeStandardBurn(
        sourceAddress: address,
      );

      await refreshWallet();
      await refreshDeposits();

      _setLoading(false);
      return result.transactionHash;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  /// Execute a large burn (800 XFG → HEAT).
  Future<String?> burnLarge() async {
    _setLoading(true);
    _clearError();

    try {
      final address = await _rpcService.getAddress();
      final result = await CLIService.executeLargeBurn(
        sourceAddress: address,
      );

      await refreshWallet();
      await refreshDeposits();

      _setLoading(false);
      return result.transactionHash;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  FEE POOL & SUPPLY
  // ═══════════════════════════════════════════════════════════════════

  /// Refresh fee pool info from daemon.
  Future<void> refreshFeePool() async {
    try {
      _feePool = await _rpcService.getFeePoolInfo();
      notifyListeners();
    } catch (e) {
      // Fee pool may not be available on all nodes
      _logger.warning('Failed to fetch fee pool: $e');
    }
  }

  /// Refresh dynamic supply overview.
  Future<void> refreshSupplyStats() async {
    try {
      _supplyStats = await _rpcService.getDynamicSupplyOverview();
      notifyListeners();
    } catch (e) {
      _logger.warning('Failed to fetch supply stats: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SWAP OPERATIONS
  // ═══════════════════════════════════════════════════════════════════

  /// Refresh swap offers for a given pair.
  Future<void> refreshSwapOffers(SwapPair pair) async {
    try {
      _swapOffers = await _rpcService.getSwapOffers(pair);
      notifyListeners();
    } catch (e) {
      _logger.warning('Failed to fetch swap offers: $e');
    }
  }

  /// Refresh recent trades for a given pair.
  Future<void> refreshRecentTrades(SwapPair pair, {int limit = 50}) async {
    try {
      _recentTrades = await _rpcService.getSwapTrades(pair, limit: limit);
      notifyListeners();
    } catch (e) {
      _logger.warning('Failed to fetch trades: $e');
    }
  }

  /// Refresh swap price for a given pair.
  Future<void> refreshSwapPrice(SwapPair pair) async {
    try {
      _currentPrice = await _rpcService.getSwapPrice(pair);
      notifyListeners();
    } catch (e) {
      _logger.warning('Failed to fetch swap price: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  FIRE ALIAS OPERATIONS
  // ═══════════════════════════════════════════════════════════════════

  /// Resolve a Fire Alias to an address.
  Future<FireAlias?> resolveAlias(String alias) async {
    try {
      final result = await _rpcService.getAlias(alias);
      return result.found ? result : null;
    } catch (e) {
      _logger.warning('Failed to resolve alias: $e');
      return null;
    }
  }

  /// Look up alias for current wallet address.
  Future<void> refreshMyAlias() async {
    if (_wallet?.address == null || _wallet!.address.isEmpty) return;

    try {
      final result = await _rpcService.getAliasByAddress(_wallet!.address);
      _myAlias = result.found ? result : null;
      notifyListeners();
    } catch (e) {
      // User may not have an alias
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  MINING OPERATIONS
  // ═══════════════════════════════════════════════════════════════════

  Future<void> startMining({int threads = 1}) async {
    try {
      _miningThreads = threads;
      final success = await _rpcService.startMining(threads: threads);
      
      if (success) {
        _isMining = true;
        _startMiningStatusTimer();
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to start mining: $e');
    }
  }

  Future<void> stopMining() async {
    try {
      await _rpcService.stopMining();
      _isMining = false;
      _miningSpeed = 0;
      notifyListeners();
    } catch (e) {
      _setError('Failed to stop mining: $e');
    }
  }

  Future<void> refreshMiningStatus() async {
    try {
      final status = await _rpcService.getMiningStatus();
      _isMining = status['active'] as bool;
      _miningSpeed = status['speed'] as int;
      _miningThreads = status['threads'] as int;
      notifyListeners();
    } catch (e) {
      // Mining might not be supported
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  CONNECTION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════

  Future<void> connectToNode(String url) async {
    _setLoading(true);

    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      final port = uri.port == 80 || uri.port == 443
          ? _networkConfig.daemonRpcPort
          : uri.port;

      _rpcService.updateNode(host, port: port);
      _nodeUrl = url;

      await _checkConnection();

      if (_isConnected && hasWallet) {
        await refreshWallet();
      }
    } catch (e) {
      _setError('Invalid node URL: $e');
    }

    _setLoading(false);
  }

  Future<void> updateNetworkConfig(NetworkConfig config) async {
    _networkConfig = config;
    _rpcService.updateNetworkConfig(config);
    
    if (_nodeUrl != null) {
      final uri = Uri.parse(_nodeUrl!);
      final newUrl = '${uri.scheme}://${uri.host}:${config.daemonRpcPort}';
      _nodeUrl = newUrl;
    }
    
    notifyListeners();
  }

  Future<void> _checkConnection() async {
    try {
      _isConnected = await _rpcService.testConnection();
    } catch (e) {
      _isConnected = false;
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  MESSAGING
  // ═══════════════════════════════════════════════════════════════════

  Future<bool> sendMessage({
    required String recipientAddress,
    required String message,
    bool selfDestruct = false,
    int? destructTime,
  }) async {
    try {
      final success = await _rpcService.sendMessage(
        recipientAddress: recipientAddress,
        message: message,
        selfDestruct: selfDestruct,
        destructTime: destructTime,
      );
      return success;
    } catch (e) {
      _setError('Failed to send message: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> loadMessages() async {
    try {
      final messages = await _rpcService.getMessages();
      return messages.map((msg) {
        return {
          'id': msg['id'] ?? '',
          'type': msg['type'] ?? 'received',
          'address': msg['address'] ?? '',
          'content': msg['content'] ?? '',
          'preview': _generateMessagePreview(msg['content'] as String? ?? ''),
          'timestamp': msg['timestamp'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'unread': msg['unread'] ?? false,
          'self_destruct': msg['self_destruct'] ?? false,
          'attachment': msg['attachment'] ?? false,
        };
      }).toList();
    } catch (e) {
      _setError('Failed to load messages: $e');
      return [];
    }
  }

  String _generateMessagePreview(String content) {
    if (content.isEmpty) return 'Encrypted message';
    if (content.length <= 50) return content;
    return '${content.substring(0, 50)}...';
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TIMERS
  // ═══════════════════════════════════════════════════════════════════

  void _startSyncTimer() {
    if (_syncTimer?.isActive == true) return;
    
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_wallet != null && !isWalletSynced) {
        _refreshSyncStatus();
      } else {
        _stopSyncTimer();
      }
    });
  }

  void _stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _isSyncing = false;
    notifyListeners();
  }

  void _startMiningStatusTimer() {
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isMining) {
        refreshMiningStatus();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _refreshSyncStatus() async {
    try {
      _isSyncing = true;
      final info = await _rpcService.getInfo();
      final balance = await _rpcService.getBalance();
      
      if (_wallet != null) {
        _wallet = _wallet!.copyWith(
          blockchainHeight: info['height'] as int,
          localHeight: balance.localHeight,
          synced: ((info['height'] as int) - balance.localHeight) <= 1,
        );
      }
      
      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _rpcService.dispose();
    super.dispose();
  }
}