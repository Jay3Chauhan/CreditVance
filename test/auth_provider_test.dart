import 'package:flutter_test/flutter_test.dart';
import 'package:cardsage/core/network/api_result.dart';
import 'package:cardsage/core/utils/view_state.dart';
import 'package:cardsage/features/auth/domain/entities/user.dart';
import 'package:cardsage/features/auth/data/repositories/auth_repository.dart';
import 'package:cardsage/features/auth/presentation/providers/auth_provider.dart';

class MockAuthRepository implements AuthRepository {
  bool authenticated = false;
  User? currentUser;

  @override
  bool get isAuthenticated => authenticated;

  @override
  Future<ApiResult<User>> login(String email, String password) async {
    if (password == 'wrong') {
      return const ApiFailure('Invalid email or password');
    }
    authenticated = true;
    currentUser = User(id: 42, email: email, fullName: 'Test User');
    return ApiSuccess(currentUser!);
  }

  @override
  Future<ApiResult<User>> register(String email, String password, String fullName) async {
    if (email == 'existing@cardsage.app') {
      return const ApiFailure('Email already registered');
    }
    authenticated = true;
    currentUser = User(id: 43, email: email, fullName: fullName);
    return ApiSuccess(currentUser!);
  }

  @override
  Future<ApiResult<User>> loginAsDemo() async {
    authenticated = true;
    currentUser = const User(id: 1, email: 'jay@cardsage.app', fullName: 'Jay (Vault Owner)');
    return ApiSuccess(currentUser!);
  }

  @override
  Future<ApiResult<User>> getMe() async {
    if (currentUser != null) {
      return ApiSuccess(currentUser!);
    }
    return const ApiFailure('Not found');
  }

  @override
  Future<void> logout() async {
    authenticated = false;
    currentUser = null;
  }
}

void main() {
  group('AuthProvider State Machine Tests', () {
    late MockAuthRepository mockRepo;
    late AuthProvider authProvider;

    setUp(() {
      mockRepo = MockAuthRepository();
      authProvider = AuthProvider(mockRepo);
    });

    test('Initializes with demo user and loaded state', () async {
      await authProvider.init();
      expect(authProvider.state, ViewState.loaded);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user?.fullName, 'Jay (Vault Owner)');
    });

    test('Logs out cleanly and resets authentication status', () async {
      await authProvider.init();
      expect(authProvider.isAuthenticated, isTrue);

      await authProvider.logout();
      expect(authProvider.user, isNull);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.state, ViewState.loaded);
    });

    test('Handles successful login and updates user state', () async {
      final success = await authProvider.login('custom@cardsage.app', 'CorrectPassword!');
      expect(success, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user?.email, 'custom@cardsage.app');
      expect(authProvider.state, ViewState.loaded);
    });

    test('Handles failed login with error message and error state', () async {
      final success = await authProvider.login('test@cardsage.app', 'wrong');
      expect(success, isFalse);
      expect(authProvider.state, ViewState.error);
      expect(authProvider.errorMessage, 'Invalid email or password');
    });

    test('Handles registration and updates state', () async {
      final success = await authProvider.register('new@cardsage.app', 'Secret123!', 'New Member');
      expect(success, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user?.fullName, 'New Member');
    });
  });
}
