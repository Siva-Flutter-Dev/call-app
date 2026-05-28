import 'package:flutter/foundation.dart';

class AuthManager {

  AuthManager._();

  static final AuthManager instance = AuthManager._();

  final ValueNotifier<bool> isAppLoggedIn = ValueNotifier(false);
  final ValueNotifier<String> loggedInEmail = ValueNotifier("");
  final ValueNotifier<String> loggedInPassword = ValueNotifier("");

  bool get isLoggedIn => isAppLoggedIn.value;
  String get email => loggedInEmail.value;
  String get password => loggedInPassword.value;

  ValueNotifier<bool> get appLoggedInListener => isAppLoggedIn;

  void updateLoginStatus(bool value) {
    isAppLoggedIn.value = value;
  }

  void updateLoginEmail(String value) {
    loggedInEmail.value = value;
  }

  void updateLoginPassword(String value) {
    loggedInPassword.value = value;
  }
}