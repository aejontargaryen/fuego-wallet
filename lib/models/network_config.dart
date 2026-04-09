// Copyright (c) 2025-2026 Fuego Developers
// Copyright (c) 2025-2026 Elderfire Privacy Group
//
// Network configuration — seed nodes and ports from CryptoNoteConfig.h

import 'fuego_constants.dart';

enum NetworkType {
  mainnet,
  testnet,
}

class NetworkConfig {
  final NetworkType type;
  final String name;
  final String addressPrefix;
  final String networkId;
  final int p2pPort;
  final int daemonRpcPort;
  final int walletRpcPort;
  final List<String> seedNodes;

  const NetworkConfig({
    required this.type,
    required this.name,
    required this.addressPrefix,
    required this.networkId,
    required this.p2pPort,
    required this.daemonRpcPort,
    required this.walletRpcPort,
    required this.seedNodes,
  });

  // Mainnet configuration — values from CryptoNoteConfig.h
  static const NetworkConfig mainnet = NetworkConfig(
    type: NetworkType.mainnet,
    name: 'Fuego Mainnet',
    addressPrefix: 'fire',
    networkId: 'fuego-mainnet',
    p2pPort: FuegoConstants.MAINNET_P2P_PORT,     // 10808
    daemonRpcPort: FuegoConstants.MAINNET_RPC_PORT, // 18180
    walletRpcPort: 18181,                           // PaymentGate convention: rpc+1
    seedNodes: [
      '207.244.247.64:10808',
      '195.88.57.158:10808',
      '80.89.228.157:10808',
      '216.145.84.248:10808',
    ],
  );

  // Testnet configuration — values from CryptoNoteConfig.h
  static const NetworkConfig testnet = NetworkConfig(
    type: NetworkType.testnet,
    name: 'Fuego Testnet',
    addressPrefix: 'TEST',
    networkId: 'fuego-testnet',
    p2pPort: FuegoConstants.TESTNET_P2P_PORT,       // 20808
    daemonRpcPort: FuegoConstants.TESTNET_RPC_PORT,  // 28280
    walletRpcPort: 28281,                             // PaymentGate convention: rpc+1
    seedNodes: [
      '195.88.57.158:20808',
      '216.145.84.248:20808',
      '80.89.228.157:20808',
      '207.244.247.64:20808',
    ],
  );

  // Get configuration by type
  static NetworkConfig getConfig(NetworkType type) {
    switch (type) {
      case NetworkType.mainnet:
        return mainnet;
      case NetworkType.testnet:
        return testnet;
    }
  }

  // Get all available configurations
  static List<NetworkConfig> getAllConfigs() {
    return [mainnet, testnet];
  }

  // Get default daemon RPC endpoints (for remote node connection)
  List<String> get defaultDaemonNodes {
    return seedNodes.map((seed) {
      final host = seed.split(':').first;
      return '$host:$daemonRpcPort';
    }).toList();
  }

  bool get isTestnet => type == NetworkType.testnet;
  bool get isMainnet => type == NetworkType.mainnet;

  String get networkInfo => '$name ($networkId)';
  String get defaultSeedNode => seedNodes.isNotEmpty ? seedNodes.first : '';

  /// Get CD term range for this network.
  ({int min, int max}) get cdTermRange =>
      FuegoConstants.getCDTermRange(testnet: isTestnet);

  /// Get tier amounts for this network.
  List<int> get tierAmounts =>
      FuegoConstants.getTierAmounts(testnet: isTestnet);

  /// Get minimum fee for this network.
  int get minimumFee => FuegoConstants.MINIMUM_FEE;

  /// Get minimum mixin for this network.
  int get minimumMixin => FuegoConstants.MIN_TX_MIXIN_SIZE_V10;

  @override
  String toString() {
    return 'NetworkConfig(type: $type, name: $name, '
        'p2p: $p2pPort, rpc: $daemonRpcPort, walletRpc: $walletRpcPort)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NetworkConfig && other.type == type;
  }

  @override
  int get hashCode => type.hashCode;
}
