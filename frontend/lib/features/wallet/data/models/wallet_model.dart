import '../../domain/entities/wallet.dart';

class WalletModel extends Wallet {
  const WalletModel({
    required super.id,
    required super.name,
    required super.currency,
    required super.balance,
    required super.isDefault,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'],
      name: json['name'],
      currency: json['currency'],
      balance: (json['balance'] as num).toDouble(),
      isDefault: json['is_default'],
    );
  }
}
