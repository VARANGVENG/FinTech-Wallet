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