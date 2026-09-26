import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import '../utils/clipboard_helper.dart';

/// Outcome of a biometric-protected vault operation.
enum VaultStatus {
  success,
  cancelled,
  notFound,
  lockedOut,
  notEnrolled,
  error;

  bool get isSuccess => this == VaultStatus.success;

  String get message {
    switch (this) {
      case VaultStatus.success:
        return 'Done';
      case VaultStatus.cancelled:
        return 'Verification cancelled';
      case VaultStatus.notFound:
        return 'No card number saved for this card. Edit the card to add it.';
      case VaultStatus.lockedOut:
        return 'Too many attempts. Unlock your phone and try again.';
      case VaultStatus.notEnrolled:
        return 'Set up a screen lock or fingerprint on your phone first.';
      case VaultStatus.error:
        return 'Could not access the secure vault.';
    }
  }
}

/// Decrypted card secrets. Kept in memory only for the reveal window.
class VaultSecrets {
  final String pan;
  final String cvv;
  final String expiry;

  const VaultSecrets({required this.pan, this.cvv = '', this.expiry = ''});
}

/// Zero-knowledge hardware vault.
///
/// PAN, CVV and expiry are written only to Android Keystore-backed storage /
/// iOS Keychain and are never sent to any server.
class SecureVaultService {
  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  SecureVaultService({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
            ),
        _localAuth = localAuth ?? LocalAuthentication();

  static String _key(int id, String field) => 'vault_card_${id}_$field';

  Future<void> saveCardSecrets({
    required int userCardId,
    required String cardNumber,
    String? cvv,
    String? expiry,
  }) async {
    final cleanPan = cardNumber.replaceAll(RegExp(r'\D'), '');
    await _storage.write(key: _key(userCardId, 'pan'), value: cleanPan);
    if (cvv != null && cvv.isNotEmpty) {
      await _storage.write(key: _key(userCardId, 'cvv'), value: cvv);
    }
    if (expiry != null && expiry.isNotEmpty) {
      await _storage.write(key: _key(userCardId, 'exp'), value: expiry);
    }
  }

  /// Moves secrets when a locally created card receives a server id.
  Future<void> moveCardSecrets(int fromId, int toId) async {
    if (fromId == toId) return;
    for (final field in ['pan', 'cvv', 'exp']) {
      final value = await _storage.read(key: _key(fromId, field));
      if (value != null) {
        await _storage.write(key: _key(toId, field), value: value);
        await _storage.delete(key: _key(fromId, field));
      }
    }
  }

  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Prompts for biometrics or device credential.
  Future<VaultStatus> authenticate({required String reason}) async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) {
        // Emulators / devices with no lock screen: the data is still
        // hardware-encrypted, so allow access rather than locking users out.
        return VaultStatus.success;
      }
      final ok = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
      return ok ? VaultStatus.success : VaultStatus.cancelled;
    } on PlatformException catch (e) {
      switch (e.code) {
        case auth_error.lockedOut:
        case auth_error.permanentlyLockedOut:
          return VaultStatus.lockedOut;
        case auth_error.notEnrolled:
        case auth_error.passcodeNotSet:
          return VaultStatus.notEnrolled;
        case auth_error.notAvailable:
          return VaultStatus.success;
        default:
          return VaultStatus.error;
      }
    } catch (_) {
      return VaultStatus.error;
    }
  }

  Future<VaultStatus> copyCardNumber(
    int userCardId, {
    required Duration clearAfter,
    String reason = 'Confirm it\'s you to copy the card number',
  }) async {
    final pan = await _storage.read(key: _key(userCardId, 'pan'));
    if (pan == null || pan.isEmpty) return VaultStatus.notFound;

    final auth = await authenticate(reason: reason);
    if (!auth.isSuccess) return auth;

    await ClipboardHelper.instance.copyWithAutoClear(pan, duration: clearAfter);
    return VaultStatus.success;
  }

  /// Copies a single field (cvv / exp) after verification.
  Future<VaultStatus> copyField(
    int userCardId,
    String field, {
    required Duration clearAfter,
    required String reason,
  }) async {
    final value = await _storage.read(key: _key(userCardId, field));
    if (value == null || value.isEmpty) return VaultStatus.notFound;
    final auth = await authenticate(reason: reason);
    if (!auth.isSuccess) return auth;
    await ClipboardHelper.instance.copyWithAutoClear(value, duration: clearAfter);
    return VaultStatus.success;
  }

  Future<(VaultStatus, VaultSecrets?)> readSecrets(
    int userCardId, {
    String reason = 'Confirm it\'s you to view card details',
  }) async {
    final pan = await _storage.read(key: _key(userCardId, 'pan'));
    if (pan == null || pan.isEmpty) return (VaultStatus.notFound, null);

    final auth = await authenticate(reason: reason);
    if (!auth.isSuccess) return (auth, null);

    final cvv = await _storage.read(key: _key(userCardId, 'cvv'));
    final exp = await _storage.read(key: _key(userCardId, 'exp'));
    return (VaultStatus.success, VaultSecrets(pan: pan, cvv: cvv ?? '', expiry: exp ?? ''));
  }

  Future<bool> hasCardSecrets(int userCardId) async {
    final pan = await _storage.read(key: _key(userCardId, 'pan'));
    return pan != null && pan.isNotEmpty;
  }

  Future<void> deleteCardSecrets(int userCardId) async {
    for (final field in ['pan', 'cvv', 'exp']) {
      await _storage.delete(key: _key(userCardId, field));
    }
  }

  Future<void> clearAll() => _storage.deleteAll();
}
