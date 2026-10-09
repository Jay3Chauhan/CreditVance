/// User profile domain entity.
class User {
  final int id;
  final String email;
  final String fullName;
  final bool isActive;
  final bool isGuest;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.isActive = true,
    this.isGuest = false,
  });

  static const User guest = User(id: 0, email: '', fullName: 'Guest', isGuest: true);

  String get firstName {
    final n = fullName.trim();
    if (n.isEmpty) return isGuest ? 'there' : email.split('@').first;
    return n.split(RegExp(r'\s+')).first;
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return email.isNotEmpty ? email[0].toUpperCase() : 'G';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
