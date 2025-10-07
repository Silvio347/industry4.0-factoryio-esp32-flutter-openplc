import '../models/user.dart';

class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  User? currentUser;
  void logout() => currentUser = null;
}
