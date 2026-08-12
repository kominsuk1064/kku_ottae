import 'package:kku_ottae/features/auth/domain/auth_repository.dart';
import 'package:kku_ottae/features/auth/domain/auth_user.dart';

typedef FakeSignInHandler =
    Future<AuthUser> Function(String email, String password);
typedef FakePasswordResetHandler = Future<void> Function(String email);
typedef FakeCreateUserHandler =
    Future<AuthUser> Function(String email, String password);
typedef FakeEmailVerificationHandler = Future<void> Function();
typedef FakeReloadCurrentUserHandler = Future<AuthUser> Function();

final class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    FakeSignInHandler? signIn,
    FakePasswordResetHandler? sendPasswordResetEmail,
    FakeCreateUserHandler? createUser,
    FakeEmailVerificationHandler? sendEmailVerification,
    FakeReloadCurrentUserHandler? reloadCurrentUser,
  }) : _signIn = signIn ?? _unexpectedSignIn,
       _sendPasswordResetEmail =
           sendPasswordResetEmail ?? _sendPasswordResetSuccessfully,
       _createUser = createUser ?? _unexpectedCreateUser,
       _sendEmailVerification =
           sendEmailVerification ?? _unexpectedEmailVerification,
       _reloadCurrentUser = reloadCurrentUser ?? _unexpectedReloadCurrentUser;

  final FakeSignInHandler _signIn;
  final FakePasswordResetHandler _sendPasswordResetEmail;
  final FakeCreateUserHandler _createUser;
  final FakeEmailVerificationHandler _sendEmailVerification;
  final FakeReloadCurrentUserHandler _reloadCurrentUser;

  final List<({String email, String password})> signInRequests = [];
  final List<String> passwordResetRequests = [];
  final List<({String email, String password})> createUserRequests = [];
  int emailVerificationRequestCount = 0;
  int reloadCurrentUserRequestCount = 0;

  @override
  Future<AuthUser> signIn({required String email, required String password}) {
    signInRequests.add((email: email, password: password));
    return _signIn(email, password);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    passwordResetRequests.add(email);
    return _sendPasswordResetEmail(email);
  }

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) {
    createUserRequests.add((email: email, password: password));
    return _createUser(email, password);
  }

  @override
  Future<void> sendEmailVerification() {
    emailVerificationRequestCount++;
    return _sendEmailVerification();
  }

  @override
  Future<AuthUser> reloadCurrentUser() {
    reloadCurrentUserRequestCount++;
    return _reloadCurrentUser();
  }

  static Future<AuthUser> _unexpectedSignIn(String email, String password) {
    throw StateError('Unexpected sign-in request for $email.');
  }

  static Future<void> _sendPasswordResetSuccessfully(String email) async {}

  static Future<AuthUser> _unexpectedCreateUser(String email, String password) {
    throw StateError('Unexpected create-user request for $email.');
  }

  static Future<void> _unexpectedEmailVerification() {
    throw StateError('Unexpected email-verification request.');
  }

  static Future<AuthUser> _unexpectedReloadCurrentUser() {
    throw StateError('Unexpected current-user reload request.');
  }
}
