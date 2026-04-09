// Copyright (c) 2025-2026 Fuego Developers
// Copyright (c) 2025-2026 Elderfire Privacy Group

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/network_config.dart';

class WalletDaemonService {
  static Process? _walletdProcess;
  static bool _isRunning = false;
  static NetworkConfig _networkConfig = NetworkConfig.mainnet;
  static String? _walletdPath;
  static String? _walletPath;
  static String? _daemonAddress;
  static int? _daemonPort;
  static final List<String> _logBuffer = [];
  static const int _maxLogLines = 500;

  /// Initialize the wallet daemon service
  static Future<void> initialize({
    required String daemonAddress,
    required int daemonPort,
    String? walletPath,
    NetworkConfig? networkConfig,
  }) async {
    _daemonAddress = daemonAddress;
    _daemonPort = daemonPort;
    _walletPath = walletPath;
    _networkConfig = networkConfig ?? NetworkConfig.mainnet;
    
    // Extract walletd binary
    _walletdPath = await _extractWalletdBinary();
    
    debugPrint('WalletDaemonService initialized');
    debugPrint('Network: ${_networkConfig.name}');
    debugPrint('Daemon: $_daemonAddress:$_daemonPort');
    debugPrint('Walletd port: ${_networkConfig.walletRpcPort}');
    debugPrint('Walletd binary: $_walletdPath');
    debugPrint('Wallet path: $_walletPath');
  }

  /// Extract the walletd binary from assets
  static Future<String> _extractWalletdBinary() async {
    final Directory appDir = await getApplicationSupportDirectory();
    final String binaryName = Platform.isWindows
        ? 'fuego-walletd-windows.exe'
        : Platform.isMacOS
            ? 'fuego-walletd-macos'
            : 'fuego-walletd-linux';

    final String binDir = path.join(appDir.path, 'bin');
    await Directory(binDir).create(recursive: true);

    final File binaryFile = File(path.join(binDir, 'fuego-walletd'));

    // Extract from assets if not already extracted
    if (!await binaryFile.exists()) {
      try {
        await binaryFile.create(recursive: true);
        await binaryFile.writeAsBytes(
          await rootBundle.load('assets/bin/$binaryName').then((data) => data.buffer.asUint8List())
        );
      } catch (e) {
        debugPrint('Warning: walletd binary not bundled in assets: $e');
        // Check if the binary exists on the system PATH
        try {
          final which = await Process.run('which', ['fuego-walletd']);
          if (which.exitCode == 0) {
            return which.stdout.toString().trim();
          }
        } catch (execError) {
          debugPrint('Failed to execute which command: $execError');
        }
        debugPrint('Running in UI-only or external RPC mode. Skipping walletd process.');
        return '';
      }
    }

    // Set executable permissions for non-Windows platforms
    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', binaryFile.path]);
    }

    return binaryFile.path;
  }

  /// Start the wallet daemon
  static Future<bool> startWalletd({
    String? walletPath,
    String? password,
  }) async {
    if (_isRunning) {
      debugPrint('Walletd is already running');
      return true;
    }

    if (_walletdPath == null) {
      throw Exception('WalletDaemonService not initialized');
    }

    if (_walletdPath!.isEmpty) {
      debugPrint('Skipping walletd start: running in UI-only/external RPC mode');
      return false; // Assuming it will be managed externally
    }

    try {
      // Prepare command arguments
      final List<String> args = [
        '--daemon-address', '$_daemonAddress',
        '--daemon-port', '$_daemonPort',
        '--rpc-bind-port', '${_networkConfig.walletRpcPort}',
        '--log-level', '1',
        '--non-interactive',
      ];

      // Add testnet flag if applicable
      if (_networkConfig.isTestnet) {
        args.add('--testnet');
      }

      // Add wallet path if provided
      if (walletPath != null) {
        args.addAll(['--wallet-file', walletPath]);
      }

      // Add password if provided
      if (password != null) {
        args.addAll(['--password', password]);
      }

      debugPrint('Starting walletd with args: $args');

      // Start the process
      _walletdProcess = await Process.start(_walletdPath!, args);

      // Listen to stdout and stderr
      _walletdProcess!.stdout.transform(utf8.decoder).listen((data) {
        _appendLog('stdout: $data');
        debugPrint('Walletd stdout: $data');
      });

      _walletdProcess!.stderr.transform(utf8.decoder).listen((data) {
        _appendLog('stderr: $data');
        debugPrint('Walletd stderr: $data');
      });

      // Monitor process exit
      _walletdProcess!.exitCode.then((code) {
        _isRunning = false;
        _appendLog('Walletd exited with code $code');
        debugPrint('Walletd exited with code $code');
      });

      // Wait a moment for startup
      await Future.delayed(const Duration(seconds: 3));

      // Check if process is still running by trying to get exit code
      // If the process has already exited, exitCode completes immediately
      final exitCodeFuture = _walletdProcess!.exitCode;
      final result = await Future.any([
        exitCodeFuture.then((code) => false),
        Future.delayed(const Duration(milliseconds: 500), () => true),
      ]);

      if (result) {
        _isRunning = true;
        debugPrint('Walletd started successfully');
        return true;
      } else {
        debugPrint('Walletd failed to start (process exited immediately)');
        _walletdProcess = null;
        return false;
      }
    } catch (e) {
      debugPrint('Error starting walletd: $e');
      return false;
    }
  }

  /// Stop the wallet daemon
  static Future<void> stopWalletd() async {
    if (!_isRunning || _walletdProcess == null) {
      return;
    }

    try {
      _walletdProcess!.kill();
      await _walletdProcess!.exitCode.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // Force kill if it doesn't exit cleanly
          _walletdProcess!.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
      _walletdProcess = null;
      _isRunning = false;
      debugPrint('Walletd stopped');
    } catch (e) {
      debugPrint('Error stopping walletd: $e');
      _walletdProcess = null;
      _isRunning = false;
    }
  }

  /// Check if walletd is running
  static bool get isRunning => _isRunning;

  /// Get the walletd port
  static int get port => _networkConfig.walletRpcPort;

  /// Get the walletd URL
  static String get url => 'http://localhost:${_networkConfig.walletRpcPort}';

  /// Get current network configuration
  static NetworkConfig get networkConfig => _networkConfig;

  /// Get recent log output
  static List<String> get recentLogs => List.unmodifiable(_logBuffer);

  /// Restart walletd with new parameters
  static Future<bool> restartWalletd({
    String? walletPath,
    String? password,
  }) async {
    await stopWalletd();
    await Future.delayed(const Duration(seconds: 1));
    return await startWalletd(walletPath: walletPath, password: password);
  }

  /// Create a new wallet
  static Future<bool> createWallet({
    required String walletPath,
    required String password,
  }) async {
    if (_walletdPath == null) {
      throw Exception('WalletDaemonService not initialized');
    }

    if (_walletdPath!.isEmpty) {
      debugPrint('Skipping walletd create: running in UI-only/external RPC mode');
      return true; // We pretend success in UI-only mode
    }

    try {
      final List<String> args = [
        '--daemon-address', '$_daemonAddress',
        '--daemon-port', '$_daemonPort',
        '--wallet-file', walletPath,
        '--password', password,
        '--generate-new-wallet',
        '--non-interactive',
      ];

      // Add testnet flag if applicable
      if (_networkConfig.isTestnet) {
        args.add('--testnet');
      }

      debugPrint('Creating wallet with args: $args');

      final ProcessResult result = await Process.run(_walletdPath!, args);

      if (result.exitCode == 0) {
        debugPrint('Wallet created successfully');
        return true;
      } else {
        debugPrint('Wallet creation failed: ${result.stderr}');
        return false;
      }
    } catch (e) {
      debugPrint('Error creating wallet: $e');
      return false;
    }
  }

  /// Open an existing wallet
  static Future<bool> openWallet({
    required String walletPath,
    required String password,
  }) async {
    return await startWalletd(
      walletPath: walletPath,
      password: password,
    );
  }

  /// Update network configuration (requires restart)
  static Future<void> updateNetworkConfig(NetworkConfig config) async {
    final wasRunning = _isRunning;
    if (wasRunning) {
      await stopWalletd();
    }
    _networkConfig = config;
    if (wasRunning && _walletPath != null) {
      await startWalletd(walletPath: _walletPath);
    }
  }

  static void _appendLog(String line) {
    _logBuffer.add('${DateTime.now().toIso8601String()} $line');
    if (_logBuffer.length > _maxLogLines) {
      _logBuffer.removeRange(0, _logBuffer.length - _maxLogLines);
    }
  }
}
