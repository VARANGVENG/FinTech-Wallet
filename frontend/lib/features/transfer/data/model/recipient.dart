class Recipient {
  final int id;
  final String fullName;
  final String email;

  const Recipient({
    required this.id,
    required this.fullName,
    required this.email,
  });

  factory Recipient.fromJson(Map<String, dynamic> json) {
    return Recipient(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
    );
  }
}