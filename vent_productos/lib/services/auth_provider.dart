import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userUid;
  String? _email;

  String? get token => _token;
  String? get uid => _userUid;
  String? get email => _email;
  bool get isAuthenticated => _token != null;

  void setToken(String token, String uid, {String? email}) {
    _token = token;
    _userUid = uid;
    _email = email;
    notifyListeners();
  }

  void logout() {
    _token = null;
    _userUid = null;
    _email = null;
    notifyListeners();
  }

  Map<String, String> get headers {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }
}
