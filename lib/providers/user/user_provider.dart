import 'package:flutter/material.dart';
import 'package:where_ma_money_go/models/user.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isEmailVerified => _user?.isEmailVerified ?? false;
  String get displayName => _user?.name ?? _user?.email ?? '';

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void updateEmailVerified() {
    if (_user != null) {
      _user = _user!.copyWith(isEmailVerified: true);
      notifyListeners();
    }
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
