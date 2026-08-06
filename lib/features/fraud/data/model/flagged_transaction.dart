/// The suspicious-transaction details shown on the Fraud Alert screen —
/// merchant, amount, date, and masked card, matching the mockup exactly.
/// Deliberately its own model, not `TransactionHistoryModel` — this
/// scenario's example data (ElectroMart Online, $1,245.00) doesn't
/// correspond to any existing mock transaction, so there's no real
/// transaction to reuse the model from.
class FlaggedTransaction {
  final String merchant;
  final double amount;
  final DateTime date;
  final String cardLast4;

  const FlaggedTransaction({
    required this.merchant,
    required this.amount,
    required this.date,
    required this.cardLast4,
  });
}
