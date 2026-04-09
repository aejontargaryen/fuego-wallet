// Copyright (c) 2025-2026 Fuego Developers
// Copyright (c) 2025-2026 Elderfire Privacy Group
//
// Core protocol constants from CryptoNoteConfig.h
// These values MUST stay in sync with the C++ daemon/walletd.

class FuegoConstants {
  FuegoConstants._(); // non-instantiable

  // ── Currency ──
  static const int COIN = 10000000; // 7 decimal places
  static const int DECIMAL_POINT = 7;
  static const int MONEY_SUPPLY = 80000088000008; // 8M8 total supply

  // ── Fees (BMv10+) ──
  static const int MINIMUM_FEE = 8000; // 0.0008 XFG flat fee
  static const int MINIMUM_FEE_V2 = 80000; // 0.008 XFG  (legacy v9)
  static const int MINIMUM_FEE_V1 = 800000; // 0.08 XFG   (legacy pre-v9)

  // ── Ring size (mixin) ──
  static const int MIN_TX_MIXIN_SIZE_V10 = 8; // v10+ enforced minimum
  static const int MIN_TX_MIXIN_SIZE_V2 = 2; // legacy
  static const int MAX_TX_MIXIN_SIZE = 18;

  // ── Mainnet CD/Burn Tiers (atomic units) ──
  static const int AMOUNT_TIER_0 = 8000000; // 0.8 XFG
  static const int AMOUNT_TIER_1 = 80000000; // 8 XFG
  static const int AMOUNT_TIER_2 = 800000000; // 80 XFG
  static const int AMOUNT_TIER_3 = 8000000000; // 800 XFG

  // ── Mainnet Banking Fees (0.1% of tier) ──
  static const int BANK_FEE_TIER_0 = 8000; // 0.0008 XFG
  static const int BANK_FEE_TIER_1 = 80000; // 0.008 XFG
  static const int BANK_FEE_TIER_2 = 800000; // 0.08 XFG
  static const int BANK_FEE_TIER_3 = 8000000; // 0.8 XFG

  // ── Testnet CD/Burn Tiers ──
  static const int TEST_AMOUNT_TIER_0 = 800000; // 0.08 TEST
  static const int TEST_AMOUNT_TIER_1 = 8000000; // 0.8 TEST
  static const int TEST_AMOUNT_TIER_2 = 80000000; // 8 TEST
  static const int TEST_AMOUNT_TIER_3 = 800000000; // 80 TEST

  // ── Testnet Banking Fees ──
  static const int TEST_BANK_FEE_TIER_0 = 800;
  static const int TEST_BANK_FEE_TIER_1 = 8000;
  static const int TEST_BANK_FEE_TIER_2 = 80000;
  static const int TEST_BANK_FEE_TIER_3 = 800000;

  // ── Epochs ──
  static const int EPOCH_DURATION_BLOCKS = 900; // mainnet: ~5 days
  static const int TESTNET_EPOCH_DURATION_BLOCKS = 10;

  // ── CD Terms (blocks) ──
  static const int CD_MIN_TERM =
      EPOCH_DURATION_BLOCKS; //16000;        // ~3 months (180 blocks/day)
  static const int CD_MAX_TERM = 65000; // ~1 year
  static const int TESTNET_CD_MIN_TERM = 8;
  static const int TESTNET_CD_MAX_TERM = 42;

  // ── Burn ──
  static const int DEPOSIT_TERM_FOREVER =
      4294967295; // uint32 max — burn marker

  // ── Dust Threshold ──
  static const int DEFAULT_DUST_THRESHOLD = 1000; // 0.0001 XFG (v10+)
  static const int DEFAULT_DUST_THRESHOLD_V9 = 20000; // 0.002 XFG (legacy)

  // ── Fee Pool / Swap Fees ──
  static const int SWAP_FEE_RATE_BPS = 100; // 1% of swap amount
  static const int SWAP_FEE_RATE_DIVISOR = 10000;
  static const int SWAP_FEE_CD_SHARE_PCT = 80; // 80% → CD yield pool
  static const int SWAP_FEE_TREASURY_SHARE_PCT = 20; // 20% → treasury

  // ── Fire Alias ──
  static const int ALIAS_REGISTRATION_FEE = COIN; // 1 XFG

  // ── Address Prefixes (base58 prefix value) ──
  static const int ADDRESS_PREFIX_MAINNET = 1753191; // "fire"
  static const int ADDRESS_PREFIX_TESTNET = 1075740; // "TEST"

  // ── Block Timing ──
  static const int DIFFICULTY_TARGET = 480; // 8 minutes
  static const int BLOCKS_PER_DAY = 180; // 24*60*60 / 480

  // ── Network Ports ──
  static const int MAINNET_P2P_PORT = 10808;
  static const int MAINNET_RPC_PORT = 18180;
  static const int TESTNET_P2P_PORT = 20808;
  static const int TESTNET_RPC_PORT = 28280;

  // ── Upgrade Heights ──
  static const int UPGRADE_HEIGHT_V10 = 999999; // Dynamigo

  // ── Dev Fund (alias registration fees go here) ──
  static const String DEV_FUND_ADDRESS =
      'fireVHx639SLMhzmBoJ8drTXbVyv2eRG6A8aMLc1taTiRNwk8pnwXpBDUSjH1dT5fg7yVVZrKkvm31CmigAMdVDg7sgxJmAUNp';

  // ── Helpers ──

  /// Convert atomic units to XFG display value.
  static double toXFG(int atomicUnits) => atomicUnits / COIN;

  /// Convert XFG display value to atomic units.
  static int toAtomic(double xfg) => (xfg * COIN).round();

  /// Format atomic units as XFG string with 7 decimals.
  static String formatXFG(int atomicUnits) {
    return '${toXFG(atomicUnits).toStringAsFixed(DECIMAL_POINT)} XFG';
  }

  /// Get the tier amounts for the given network.
  static List<int> getTierAmounts({bool testnet = false}) {
    if (testnet) {
      return [
        TEST_AMOUNT_TIER_0,
        TEST_AMOUNT_TIER_1,
        TEST_AMOUNT_TIER_2,
        TEST_AMOUNT_TIER_3
      ];
    }
    return [AMOUNT_TIER_0, AMOUNT_TIER_1, AMOUNT_TIER_2, AMOUNT_TIER_3];
  }

  /// Get the banking fee for a given tier.
  static int getBankingFee(int tier, {bool testnet = false}) {
    final fees = testnet
        ? [
            TEST_BANK_FEE_TIER_0,
            TEST_BANK_FEE_TIER_1,
            TEST_BANK_FEE_TIER_2,
            TEST_BANK_FEE_TIER_3
          ]
        : [BANK_FEE_TIER_0, BANK_FEE_TIER_1, BANK_FEE_TIER_2, BANK_FEE_TIER_3];
    if (tier < 0 || tier >= fees.length) return fees[0];
    return fees[tier];
  }

  /// Classify an amount into its tier index (0-3), or -1 if invalid.
  static int classifyTier(int amount, {bool testnet = false}) {
    final tiers = getTierAmounts(testnet: testnet);
    for (int i = tiers.length - 1; i >= 0; i--) {
      if (amount >= tiers[i]) return i;
    }
    return -1;
  }

  /// Get CD term range for the network.
  static ({int min, int max}) getCDTermRange({bool testnet = false}) {
    if (testnet) return (min: TESTNET_CD_MIN_TERM, max: TESTNET_CD_MAX_TERM);
    return (min: CD_MIN_TERM, max: CD_MAX_TERM);
  }

  /// Estimate days from block count.
  static double blocksToDays(int blocks) => blocks / BLOCKS_PER_DAY;

  /// Estimate blocks from days.
  static int daysToBlocks(double days) => (days * BLOCKS_PER_DAY).round();
}
