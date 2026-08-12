import 'package:kku_ottae/features/auth/domain/auth_repository.dart';
import 'package:kku_ottae/features/auth/domain/auth_user.dart';

typedef FakeSignInHandler =
    Future<AuthUser> Function(String email, String password);
typedef FakePasswordResetHandler = Future<void> Function(String email);

final class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    FakeSignInHandler? signIn,
    FakePasswordResetHandler? sendPasswordResetEmail,
  }) : _signIn = signIn ?? _unexpectedSignIn,
       _sendPasswordResetEmail =
           sendPasswordResetEmail ?? _sendPasswordResetSuccessfully;

  final FakeSignInHandler _signIn;
  final FakePasswordResetHandler _sendPasswordResetEmail;

  final List<({String email, String password})> signInRequests = [];
  final List<String> passwordResetRequests = [];

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

  static Future<AuthUser> _unexpectedSignIn(String email, String password) {
    throw StateError('Unexpected sign-in request for $email.');
  }

  static Future<void> _sendPasswordResetSuccessfully(String email) async {}
}
