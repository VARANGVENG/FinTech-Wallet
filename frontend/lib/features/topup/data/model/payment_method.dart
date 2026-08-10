/// Identifies which kind of payment method a tile represents.
/// Using an enum (instead of raw strings) means the compiler catches typos
/// and the `when`/`switch` below is exhaustive-checked by the IDE.
enum PaymentMethodType { linkedBank, debitCard, applePay }

/// Plain data model for a single payment method row.
///
/// This is intentionally a "dumb" model with no Flutter/UI imports so it can
/// be reused by the API layer, tests, and the widget layer without dragging
/// in `package:flutter`.
class PaymentMethod {
  final PaymentMethodType type;
  final String title;
  final String subtitle;
  final String iconAsset; // path or icon identifier resolved by the UI layer

  const PaymentMethod({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.iconAsset,
  });

  /// Factory used when the list of methods comes back from a backend as JSON,
  /// e.g. `GET /api/payment-methods`. Keeping this on the model (rather than
  /// in the widget or the API service) means there is exactly one place that
  /// knows how to turn raw JSON into a [PaymentMethod].
  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      type: PaymentMethodType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PaymentMethodType.linkedBank,
      ),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      iconAsset: json['iconAsset'] as String? ?? '',
    );
  }
}