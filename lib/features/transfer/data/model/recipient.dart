/// Plain data model for a transfer recipient — no Flutter/UI imports, same
/// reasoning as [PaymentMethod]: reusable by the data, domain, and widget
/// layers without dragging `package:flutter` into layers that shouldn't need it.
class Recipient {
  final String id;
  final String name;
  final String subtitle;
  final bool isFrequent;

  const Recipient({
    required this.id,
    required this.name,
    required this.subtitle,
    this.isFrequent = false,
  });

  factory Recipient.fromJson(Map<String, dynamic> json) {
    return Recipient(
      id: json['id'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String,
      isFrequent: json['isFrequent'] as bool? ?? false,
    );
  }
}
