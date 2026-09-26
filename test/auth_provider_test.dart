import 'package:cardsage/core/network/api_result.dart';
import 'package:cardsage/features/auth/data/repositories/auth_repository.dart';
import 'package:cardsage/features/auth/domain/entities/user.dart';
import 'package:cardsage/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements AuthRepository {
  User? session;
  bool guest = false;

  @override
  Future<ApiResult<User>> login(String email, String password) async {
    if (password == 'wrong') return const ApiFailure('Incorrect email or password', statusCode: 401);
    session = User(id: 42, email: email, fullName: 'Test User');
    return ApiSuccess(session!);
  }

  @override
  Future<ApiResult<User>> register(String email, String password, String fullName) async {
    if (email == 'existing@creditvance.app') return const ApiFailure('An account with this email already exists');
    session = User(id: 43, email: email, fullName: fullName);
    return ApiSuccess(session!);
  }

  @override
  Future<User> continueAsGuest() async {
    guest = true;
    return User.guest;
  }

  @override
  Future<void> exitGuest() async => guest = false;

  @override
  User? restoreSession() => guest ? User.guest : session;

  @override
  Future<ApiResult<User>> refreshProfile() async =>
      session == null ? const ApiFailure('No session') : ApiSuccess(session!);

  @override
  Future<void> logout() async {
    session = null;
    guest = false;
  }
}

void main() {
  group('AuthProvider', () {
    late FakeAuthRepository repo;
    late AuthProvider auth;

    setUp(() {
      repo = FakeAuthRepository();
      auth = AuthProvider(repo);
    });

    test('restores to signed out when there is no session', () {
      auth.restore();
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.isAuthenticated, isFalse);
    });

    test('restores a persisted signed-in session', () {
      repo.session = const User(id: 1, email: 'a@b.co', fullName: 'Aarav Sharma');
      auth.restore();
      expect(auth.status, AuthStatus.signedIn);
      expect(auth.user?.initials, 'AS');
      expect(auth.user?.firstName, 'Aarav');
    });

    test('successful login signs in', () async {
      final ok = await auth.login('custom@creditvance.app', 'CorrectPassword!');
      expect(ok, isTrue);
      expect(auth.status, AuthStatus.signedIn);
      expect(auth.user?.email, 'custom@creditvance.app');
      expect(auth.isBusy, isFalse);
    });

    test('failed login keeps user signed out and exposes the error', () async {
      auth.restore();
      final ok = await auth.login('test@creditvance.app', 'wrong');
      expect(ok, isFalse);
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.errorMessage, 'Incorrect email or password');
    });

    test('register signs in with the new name', () async {
      final ok = await auth.register('new@creditvance.app', 'Secret123!', 'New Member');
      expect(ok, isTrue);
      expect(auth.user?.fullName, 'New Member');
    });

    test('guest mode and exiting guest mode', () async {
      await auth.continueAsGuest();
      expect(auth.status, AuthStatus.guest);
      expect(auth.isAuthenticated, isTrue);
      await auth.exitGuest();
      expect(auth.status, AuthStatus.signedOut);
    });

    test('session expiry signs out a signed-in user only', () async {
      await auth.login('x@y.co', 'ok');
      auth.handleSessionExpired();
      await Future<void>.delayed(Duration.zero);
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.errorMessage, contains('expired'));

      await auth.continueAsGuest();
      auth.handleSessionExpired();
      expect(auth.status, AuthStatus.guest);
    });

    test('validators', () {
      expect(AuthRepositoryImpl.validateEmail('bad'), isNotNull);
      expect(AuthRepositoryImpl.validateEmail('ok@mail.com'), isNull);
      expect(AuthRepositoryImpl.validatePassword('short', isSignUp: true), isNotNull);
      expect(AuthRepositoryImpl.validatePassword('longenough', isSignUp: true), isNull);
    });
  });
}
