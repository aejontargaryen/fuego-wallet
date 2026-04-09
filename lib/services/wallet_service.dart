// Copyright (c) 2025-2026 Fuego Developers
// Copyright (c) 2025-2026 Elderfire Privacy Group
//
// DEPRECATED: Use FuegoRPCService instead.
// This file exists only for backward compatibility during migration.
// All new code should use FuegoRPCService directly via WalletProvider.

import 'fuego_rpc_service.dart';

@Deprecated('Use FuegoRPCService via WalletProvider instead')
class WalletService {
  final FuegoRPCService _rpcService;

  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal() : _rpcService = FuegoRPCService();

  FuegoRPCService get rpcService => _rpcService;
}
