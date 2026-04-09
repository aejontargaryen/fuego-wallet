// Copyright (c) 2025-2026 Fuego Developers
// Copyright (c) 2025-2026 Elderfire Privacy Group
//
// Fire Alias model — on-chain alias → address mapping.
// Maps to daemon RPC: /get_alias, /get_alias_by_address

class FireAlias {
  final String alias;
  final String address;
  final String addressHash;
  final int registeredBlock;
  final int aliasType;       // 0=regular
  final bool found;

  const FireAlias({
    required this.alias,
    required this.address,
    this.addressHash = '',
    required this.registeredBlock,
    this.aliasType = 0,
    required this.found,
  });

  factory FireAlias.fromJson(Map<String, dynamic> json) {
    return FireAlias(
      alias: json['alias'] as String? ?? '',
      address: json['address'] as String? ?? '',
      addressHash: json['address_hash'] as String? ?? '',
      registeredBlock: json['registered_block'] as int? ?? 0,
      aliasType: json['alias_type'] as int? ?? 0,
      found: json['found'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'alias': alias,
    'address': address,
    'address_hash': addressHash,
    'registered_block': registeredBlock,
    'alias_type': aliasType,
    'found': found,
  };

  /// True if this is a regular user alias (not legacy EFier type).
  bool get isRegular => aliasType == 0;

  @override
  String toString() => 'FireAlias($alias → ${address.substring(0, 12)}...)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FireAlias && other.alias == alias;

  @override
  int get hashCode => alias.hashCode;
}
