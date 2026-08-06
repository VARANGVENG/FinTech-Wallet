import 'dart:ui';

/// Turns a full name into up to 2 uppercase initials — e.g. "Michael
/// Johnson" → "MJ", "Admin" → "A". Used anywhere an avatar shows initials
/// instead of a photo (Profile, RecipientCard).
extension NameInitials on String {
  String get initials {
    final parts = trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

/// Deterministically picks a color from a small fixed palette based on
/// this string's hash — the same name always maps to the same color, so
/// avatars stay visually consistent across sessions. Deliberately not
/// backend data: which color an avatar gets is a presentational choice,
/// not something a server should need to own or store.
extension AvatarColor on String {
  Color get avatarColor {
    const palette = [
      Color(0xFF4B5EF5), // blue
      Color(0xFF9B59B6), // purple
      Color(0xFF2ECC71), // green
      Color(0xFFE67E22), // orange
      Color(0xFFE74C3C), // red
      Color(0xFF16A085), // teal
    ];
    return palette[hashCode.abs() % palette.length];
  }
}