import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userUid;
  String? _email;
  String? _nombres;
  String? _apellidos;

  String? get token => _token;
  String? get uid => _userUid;
  String? get email => _email;
  String? get nombres => _nombres;
  String? get apellidos => _apellidos;
  String get nombreCompleto => ('${_nombres ?? ''} ${_apellidos ?? ''}').trim().isNotEmpty
      ? ('${_nombres ?? ''} ${_apellidos ?? ''}').trim()
      : 'Cliente Móvil';
  bool get isAuthenticated => _token != null;

  void setToken(String token, String uid, {String? email, String? nombres, String? apellidos}) {
    _token = token;
    _userUid = uid;
    _email = email;
    _nombres = nombres;
    _apellidos = apellidos;
    notifyListeners();
  }

  void logout() {
    _token = null;
    _userUid = null;
    _email = null;
    _nombres = null;
    _apellidos = null;
    notifyListeners();
  }

  Map<String, String> get headers {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }
}
