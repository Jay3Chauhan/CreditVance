import '../../domain/entities/user.dart';

/// DTO for User profile
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    super.isBiometricEnabled,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 1,
      email: json['email'] as String? ?? 'user@cardsage.app',
      fullName: json['full_name'] as String? ?? 'Elite Cardholder',
      isBiometricEnabled: json['is_biometric_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'is_biometric_enabled': isBiometricEnabled,
      };
}
