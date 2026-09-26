import 'package:flutter/foundation.dart';
import '../../../../core/network/api_result.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';

enum AuthStatus { unknown, signedOut, guest, signedIn }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider(this._repository);

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;

  User? _user;
  User? get user => _user;

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.signedIn || _status == AuthStatus.guest;
  bool get isGuest => _status == AuthStatus.guest;
  bool get isSignedIn => _status == AuthStatus.signedIn;

  /// Synchronously restores the persisted session, then refreshes the
  /// profile in the background.
  void restore() {
    final restored = _repository.restoreSession();
    _user = restored;
    _status = restored == null
        ? AuthStatus.signedOut
        : restored.isGuest
            ? AuthStatus.guest
            : AuthStatus.signedIn;
    notifyListeners();
    if (_status == AuthStatus.signedIn) _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    final result = await _repository.refreshProfile();
    if (result case ApiSuccess(:final data)) {
      _user = data;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) =>
      _run(() => _repository.login(email, password));

  Future<bool> register(String email, String password, String fullName) =>
      _run(() => _repository.register(email, password, fullName));

  Future<bool> _run(Future<ApiResult<User>> Function() action) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    final result = await action();
    _isBusy = false;
    return result.when(
      success: (u) {
        _user = u;
        _status = AuthStatus.signedIn;
        notifyListeners();
        return true;
      },
      failure: (message, _) {
        _errorMessage = message;
        notifyListeners();
        return false;
      },
    );
  }

  Future<void> continueAsGuest() async {
    _user = await _repository.continueAsGuest();
    _errorMessage = null;
    _status = AuthStatus.guest;
    notifyListeners();
  }

  Future<void> exitGuest() async {
    await _repository.exitGuest();
    _user = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  /// Invoked by the API client when a token-bearing request returns 401.
  void handleSessionExpired() {
    if (_status != AuthStatus.signedIn) return;
    _errorMessage = 'Your session expired. Please sign in again.';
    logout();
  }
}
