import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:xfg_wallet/services/fuego_rpc_service.dart';
import 'package:xfg_wallet/models/swap_model.dart';
import 'package:xfg_wallet/models/network_config.dart';
import 'package:xfg_wallet/models/wallet.dart';

class MockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;
  MockAdapter(this.handler);
  
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) {
    return handler(options);
  }
  
  @override
  void close({bool force = false}) {}
}

void main() {
  late FuegoRPCService service;
  late Dio dio;

  setUp(() {
    dio = Dio();
  });

  group('FuegoRPCService - XFG Protocol Methods', () {
    test('getFeePoolInfo returns valid FeePoolModel', () async {
      dio.httpClientAdapter = MockAdapter((options) async {
        expect(options.path, endsWith('/get_fee_pool_info'));
        return ResponseBody.fromString(
          json.encode({
            'fee_pool_balance': 1000000000,
            'current_epoch_swap_fees': 50000000,
            'total_cd_locked': 5000000000,
            'current_epoch_number': 42,
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          },
        );
      });

      service = FuegoRPCService(networkConfig: NetworkConfig.mainnet, dio: dio);
      final feePool = await service.getFeePoolInfo();
      
      expect(feePool.feePoolBalance, 1000000000);
      expect(feePool.currentEpochNumber, 42);
      expect(feePool.feePoolXFG, 100.0);
    });

    test('getSwapPrice returns valid SwapPrice', () async {
      dio.httpClientAdapter = MockAdapter((options) async {
        expect(options.path, endsWith('/get_swap_price'));
        expect(options.data, '{"pair":0}'); // SwapPair.xfgBtc.value is 0
        return ResponseBody.fromString(
          json.encode({
            'id': 1,
            'pair': '0',
            'compositeRate': '0.00000450',
            'xfgUsdMid': '0.15',
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          },
        );
      });

      service = FuegoRPCService(networkConfig: NetworkConfig.mainnet, dio: dio);
      final price = await service.getSwapPrice(SwapPair.xfgBtc);
      
      expect(price.compositeRate, '0.00000450');
      expect(price.usdMid, 0.15);
    });

    test('getDynamicSupplyOverview parses wallet RPC response', () async {
      dio.httpClientAdapter = MockAdapter((options) async {
        try {
          expect(options.path, endsWith('/json_rpc'));
          final data = json.decode(options.data as String);
          expect(data['method'], 'getDynamicSupplyOverview');
          
          return ResponseBody.fromString(
            json.encode({
              'jsonrpc': '2.0',
              'id': 1,
              'result': {
                'baseTotalSupply': 1000000000000,
                'realTotalSupply': 990000000000,
                'totalDepositAmount': 50000000000,
                'circulatingSupply': 940000000000,
                'ethereal_xfg': 10000000000,
                'currentDepositAmount': 40000000000,
              }
            }),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json']
            },
          );
        } catch (e) {
          print('Error in mock: $e');
          rethrow;
        }
      });

      service = FuegoRPCService(networkConfig: NetworkConfig.mainnet, dio: dio);
      final stats = await service.getDynamicSupplyOverview();
      
      expect(stats.baseTotalSupply, 1000000000000);
      expect(stats.burnedXFG, 1000.0);
    });

    test('sendTransaction validates ring size 8+', () async {
      service = FuegoRPCService(networkConfig: NetworkConfig.mainnet, dio: Dio());
      const request = SendTransactionRequest(
        address: 'fire1abc',
        amount: 1000000,
        paymentId: '',
        mixins: 7, // Too low
      );

      expect(
        () => service.sendTransaction(request),
        throwsA(isA<FuegoRPCException>().having(
          (e) => e.message, 'message', contains('at least 8'))),
      );
    });

    test('sendTransaction validates fire prefix', () async {
      service = FuegoRPCService(networkConfig: NetworkConfig.mainnet, dio: Dio());
      const request = SendTransactionRequest(
        address: 'bad1abc', // Not starting with fire
        amount: 1000000,
        paymentId: '',
        mixins: 8,
      );

      expect(
        () => service.sendTransaction(request),
        throwsA(isA<FuegoRPCException>().having(
          (e) => e.message, 'message', contains('must start with "fire"'))),
      );
    });

    test('getAlias returns valid FireAlias', () async {
      dio.httpClientAdapter = MockAdapter((options) async {
        expect(options.path, endsWith('/get_alias'));
        expect(options.data, '{"alias":"tuke"}');
        
        return ResponseBody.fromString(
          json.encode({
            'alias': 'tuke',
            'address': 'fire1tukeaddress',
            'status': 'active',
            'height': 1000,
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          },
        );
      });

      service = FuegoRPCService(networkConfig: NetworkConfig.mainnet, dio: dio);
      final alias = await service.getAlias('tuke');
      
      expect(alias.alias, 'tuke');
      expect(alias.address, 'fire1tukeaddress');
    });
  });
}
