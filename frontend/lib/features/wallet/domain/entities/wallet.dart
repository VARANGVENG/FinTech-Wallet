class Wallet {
  final int id;
  final String name;
  final String currency;
  final double balance;
  final bool isDefault;

  const Wallet({
    required this.id,
    required this.name,
    required this.currency,
    required this.balance,
    required this.isDefault,
  });
}
