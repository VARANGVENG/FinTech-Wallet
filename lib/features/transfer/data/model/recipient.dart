/// Plain data model for a transfer recipient — no Flutter/UI imports, same
/// reasoning as [PaymentMethod]: reusable by the data, domain, and widget
/// layers without dragging `package:flutter` into layers that shouldn't need it.
class Recipient {
  final String id;
  final String name;
  final String email;

  const Recipient({
    required this.id,
    required this.name,
    required this.email,
  });

  /// Factory for when recipient data comes back from a backend as JSON,
  /// e.g. `GET /api/users/search`. One place that knows how to turn raw
  /// JSON into a [Recipient], same convention as `PaymentMethod.fromJson`.
  factory Recipient.fromJson(Map<String, dynamic> json) {
    return Recipient(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}