// GENERATED CODE - DO NOT MODIFY BY HAND
// Regenerate with: flutter pub run build_runner build

part of 'wallet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Wallet _$WalletFromJson(Map<String, dynamic> json) => Wallet(
      address: json['address'] as String,
      viewKey: json['viewKey'] as String,
      spendKey: json['spendKey'] as String,
      balance: (json['balance'] as num).toInt(),
      unlockedBalance: (json['unlockedBalance'] as num).toInt(),
      lockedDepositBalance: (json['lockedDepositBalance'] as num?)?.toInt() ?? 0,
      unlockedDepositBalance: (json['unlockedDepositBalance'] as num?)?.toInt() ?? 0,
      blockchainHeight: (json['blockchainHeight'] as num).toInt(),
      localHeight: (json['localHeight'] as num).toInt(),
      synced: json['synced'] as bool,
    );

Map<String, dynamic> _$WalletToJson(Wallet instance) => <String, dynamic>{
      'address': instance.address,
      'viewKey': instance.viewKey,
      'spendKey': instance.spendKey,
      'balance': instance.balance,
      'unlockedBalance': instance.unlockedBalance,
      'lockedDepositBalance': instance.lockedDepositBalance,
      'unlockedDepositBalance': instance.unlockedDepositBalance,
      'blockchainHeight': instance.blockchainHeight,
      'localHeight': instance.localHeight,
      'synced': instance.synced,
    };

WalletTransaction _$WalletTransactionFromJson(Map<String, dynamic> json) =>
    WalletTransaction(
      txid: json['txid'] as String,
      amount: (json['amount'] as num).toInt(),
      fee: (json['fee'] as num).toInt(),
      paymentId: json['paymentId'] as String,
      blockHeight: (json['blockHeight'] as num).toInt(),
      timestamp: (json['timestamp'] as num).toInt(),
      isSpending: json['isSpending'] as bool,
      address: json['address'] as String?,
      confirmations: (json['confirmations'] as num).toInt(),
      firstDepositId: (json['firstDepositId'] as num?)?.toInt() ?? -1,
      depositCount: (json['depositCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$WalletTransactionToJson(WalletTransaction instance) =>
    <String, dynamic>{
      'txid': instance.txid,
      'amount': instance.amount,
      'fee': instance.fee,
      'paymentId': instance.paymentId,
      'blockHeight': instance.blockHeight,
      'timestamp': instance.timestamp,
      'isSpending': instance.isSpending,
      'address': instance.address,
      'confirmations': instance.confirmations,
      'firstDepositId': instance.firstDepositId,
      'depositCount': instance.depositCount,
    };

SendTransactionRequest _$SendTransactionRequestFromJson(
        Map<String, dynamic> json) =>
    SendTransactionRequest(
      address: json['address'] as String,
      amount: (json['amount'] as num).toInt(),
      paymentId: json['paymentId'] as String,
      fee: (json['fee'] as num?)?.toInt() ?? FuegoConstants.MINIMUM_FEE,
      mixins: (json['mixins'] as num?)?.toInt() ?? FuegoConstants.MIN_TX_MIXIN_SIZE_V10,
    );

Map<String, dynamic> _$SendTransactionRequestToJson(
        SendTransactionRequest instance) =>
    <String, dynamic>{
      'address': instance.address,
      'amount': instance.amount,
      'paymentId': instance.paymentId,
      'fee': instance.fee,
      'mixins': instance.mixins,
    };