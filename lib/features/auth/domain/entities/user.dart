/// User profile domain entity
class User {
  final int id;
  final String email;
  final String fullName;
  final bool isBiometricEnabled;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.isBiometricEnabled = true,
  });
}
