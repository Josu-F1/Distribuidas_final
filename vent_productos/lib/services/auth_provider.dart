import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _databaseId;
  String? _firebaseUid;
  String? _email;
  String? _nombres;
  String? _apellidos;

  String? get token => _token;
  String? get uid => _databaseId; // Para compatibilidad
  String? get databaseId => _databaseId;
  String? get firebaseUid => _firebaseUid;
  String? get email => _email;
  String? get nombres => _nombres;
  String? get apellidos => _apellidos;
  String get nombreCompleto => ('${_nombres ?? ''} ${_apellidos ?? ''}').trim().isNotEmpty
      ? ('${_nombres ?? ''} ${_apellidos ?? ''}').trim()
      : 'Cliente Móvil';
  bool get isAuthenticated => _token != null;

  void setToken(String token, String databaseId, String firebaseUid, {String? email, String? nombres, String? apellidos}) {
    _token = token;
    _databaseId = databaseId;
    _firebaseUid = firebaseUid;
    _email = email;
    _nombres = nombres;
    _apellidos = apellidos;
    notifyListeners();
  }

  void logout() {
    _token = null;
    _databaseId = null;
    _firebaseUid = null;
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
