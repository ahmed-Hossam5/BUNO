/// Stand-in for the real auth backend: validates input and simulates a
/// short network delay. Nothing is sent anywhere and no account is stored.
class MockAuth {
  MockAuth._();

  static const _latency = Duration(milliseconds: 700);

  /// E-mail the last code was "sent" to (shown on the verification page).
  static String pendingEmail = '';

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  static bool isValidEmail(String v) => _email.hasMatch(v.trim());
  static bool isValidPassword(String v) => v.length >= 8;

  static Future<void> signIn(String email, String password) => Future.delayed(_latency);

  static Future<void> signUp(String name, String email, String password) async {
    pendingEmail = email.trim();
    await Future<void>.delayed(_latency);
  }

  /// Sign in with Apple (iCloud). A real build would call the native
  /// AuthenticationServices sheet here.
  static Future<void> signInWithApple() => Future.delayed(_latency);

  /// Any 4-digit code passes in this mock.
  static Future<bool> verifyCode(String code) async {
    await Future<void>.delayed(_latency);
    return code.length == 4;
  }

  static Future<void> resendCode() => Future.delayed(_latency);
}
