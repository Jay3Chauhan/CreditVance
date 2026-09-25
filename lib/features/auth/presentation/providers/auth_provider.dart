import 'package:flutter/foundation.dart';
import '../../../../core/utils/view_state.dart';
import '../../domain/entities/user.dart';
import '../../data/repositories/auth_repository.dart';

/// Provider for User Session and Authentication.
/// Strictly Zero setState: Uses Provider & ChangeNotifier.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider(this._repository);

  ViewState _state = ViewState.initial;
  ViewState get state => _state;

  User? _user;
  User? get user => _user;

  bool get isAuthenticated => _user != null && _repository.isAuthenticated;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    if (_repository.isAuthenticated) {
      final res = await _repository.getMe();
      if (res.isSuccess) {
        _user = res.dataOrNull;
      } else {
        _user = null;
      }
    } else {
      // Auto-load demo user on first boot for seamless experience
      final res = await _repository.loginAsDemo();
      if (res.isSuccess) {
        _user = res.dataOrNull;
      }
    }
    _setState(ViewState.loaded);
  }

  Future<bool> login(String email, String password) async {
    _setState(ViewState.loading);
    _errorMessage = null;
    final res = await _repository.login(email, password);

    if (res.isSuccess) {
      _user = res.dataOrNull;
      _errorMessage = null;
      _setState(ViewState.loaded);
      return true;
    } else {
      _errorMessage = res.errorOrNull ?? 'Login failed';
      _setState(ViewState.error);
      return false;
    }
  }

  Future<bool> loginAsDemo() async {
    _setState(ViewState.loading);
    _errorMessage = null;
    final res = await _repository.loginAsDemo();

    if (res.isSuccess) {
      _user = res.dataOrNull;
      _errorMessage = null;
      _setState(ViewState.loaded);
      return true;
    } else {
      _errorMessage = res.errorOrNull ?? 'Failed to load demo account';
      _setState(ViewState.error);
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName) async {
    _setState(ViewState.loading);
    _errorMessage = null;
    final res = await _repository.register(email, password, fullName);

    if (res.isSuccess) {
      _user = res.dataOrNull;
      _errorMessage = null;
      _setState(ViewState.loaded);
      return true;
    } else {
      _errorMessage = res.errorOrNull ?? 'Registration failed';
      _setState(ViewState.error);
      return false;
    }
  }

  Future<void> logout() async {
    _setState(ViewState.loading);
    await _repository.logout();
    _user = null;
    _errorMessage = null;
    _setState(ViewState.loaded);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }
}
