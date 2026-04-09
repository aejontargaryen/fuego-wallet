import 'package:flutter_test/flutter_test.dart';
import 'package:xfg_wallet/providers/wallet_provider.dart';
import 'package:xfg_wallet/services/fuego_rpc_service.dart';
import 'package:xfg_wallet/models/wallet.dart';
import 'package:xfg_wallet/models/fee_pool_model.dart';
import 'package:xfg_wallet/models/supply_stats_model.dart';
import 'package:xfg_wallet/models/swap_model.dart';
import 'package:xfg_wallet/models/network_config.dart';

class MockFuegoRPCService extends FuegoRPCService {
  MockFuegoRPCService() : super(networkConfig: NetworkConfig.mainnet);

  bool feePoolCalled = false;
  bool supplyStatsCalled = false;
  bool swapPriceCalled = false;
  bool _throwError = false;

  void throwOnNextCall() {
    _throwError = true;
  }

  @override
  Future<FeePoolModel> getFeePoolInfo() async {
    feePoolCalled = true;
    if (_throwError) throw Exception('Fee pool error');
    return const FeePoolModel(
      feePoolBalance: 1000000000,
      currentEpochSwapFees: 50000000,
      totalCDLocked: 5000000000,
      currentEpochNumber: 42,
    );
  }

  @override
  Future<SupplyStats> getDynamicSupplyOverview() async {
    supplyStatsCalled = true;
    if (_throwError) throw Exception('Supply stats error');
    return const SupplyStats(
      baseTotalSupply: 1000000000000,
      realTotalSupply: 990000000000,
      totalDepositAmount: 50000000000,
      circulatingSupply: 940000000000,
      etherealXfg: 10000000000,
      currentDepositAmount: 40000000000,
      burnPercentage: 1.0,
      depositPercentage: 5.0,
      circulatingPercentage: 94.0,
    );
  }

  @override
  Future<SwapPrice> getSwapPrice(SwapPair pair) async {
    swapPriceCalled = true;
    if (_throwError) throw Exception('Swap price error');
    return const SwapPrice(
      twap: '0.00000445',
      seedRate: '0.00000448',
      compositeRate: '0.00000450',
      sourceCount: 3,
      sources: [],
      xfgUsdLow: '0.14',
      xfgUsdHigh: '0.16',
      xfgUsdMid: '0.15',
    );
  }

  @override
  Future<Wallet> getBalance() async {
    return const Wallet(
      balance: 50000000, 
      unlockedBalance: 50000000, // 5 XFG 
      address: 'fire1test',
      lockedDepositBalance: 50000000, // 5 XFG locked in CDs
      synced: true,
      blockchainHeight: 100,
      localHeight: 100,
      viewKey: 'mock_view_key',
      spendKey: 'mock_spend_key',
    );
  }

  @override
  Future<String> getAddress() async {
    return 'fire1test';
  }

  @override
  Future<bool> testConnection() async {
    return true; // Used by refreshWallet
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WalletProvider provider;
  late MockFuegoRPCService mockRPC;

  setUp(() {
    mockRPC = MockFuegoRPCService();
    provider = WalletProvider(rpcService: mockRPC);
  });

  group('WalletProvider State Transitions', () {
    test('Initial state is correct', () {
      expect(provider.isSyncing, false);
      expect(provider.wallet, isNull);
    });

    test('Refresh protocol stats updates state successfully', () async {
      await provider.refreshFeePool();
      await provider.refreshSupplyStats();
      await provider.refreshSwapPrice(SwapPair.xfgBtc);
      
      expect(mockRPC.feePoolCalled, true);
      expect(mockRPC.supplyStatsCalled, true);
      expect(mockRPC.swapPriceCalled, true);
      
      expect(provider.feePool, isNotNull);
      expect(provider.feePool!.feePoolBalance, 1000000000);
      
      expect(provider.supplyStats, isNotNull);
      expect(provider.supplyStats!.realTotalSupply, 990000000000);
      
      expect(provider.currentPrice, isNotNull);
      expect(provider.currentPrice!.compositeRate, '0.00000450');
    });

    test('Refresh protocol stats handles errors silently', () async {
      mockRPC.throwOnNextCall();
      await provider.refreshFeePool();
      
      expect(provider.feePool, isNull);
    });
    
    test('refreshWallet updates wallet state properly', () async {
      // simulate being connected
      await provider.connectToNode('http://localhost:18180');
      
      await provider.refreshWallet();
      
      expect(provider.wallet, isNotNull);
      expect(provider.wallet!.totalBalanceXFG, 10.0);
      expect(provider.wallet!.unlockedBalanceXFG, 5.0);
      expect(provider.wallet!.lockedDepositXFG, 5.0);
      expect(provider.wallet!.address, 'fire1test');
    });
  });
}
