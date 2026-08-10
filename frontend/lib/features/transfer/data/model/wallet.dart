/// A wallet/account a transfer can draw from — e.g. "NovaPay Wallet" or
/// "Savings Wallet". Same "plain data, no Flutter imports" shape as every
/// other model in this app.
class Wallet {
  final String id;
  final String name;
  final double balance;

  const Wallet({
    required this.id,
    required this.name,
    required this.balance,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      name: json['name'] as String,
      balance: (json['balance'] as num).toDouble(),
    );
  }
}