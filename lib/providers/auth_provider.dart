import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final _api = ApiService();
  final _storage = StorageService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isArtist => _user?.isArtist ?? false;

  Future<void> init() async {
    await _storage.init();
    final token = await _storage.getToken();
    if (token != null) {
      final cached = _storage.getUser();
      if (cached != null) {
        _user = cached;
        _status = AuthStatus.authenticated;
        notifyListeners();
      }
      try {
        final data = await _api.getMe();
        _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        await _storage.saveUser(_user!);
        _status = AuthStatus.authenticated;
      } catch (_) {
        await _storage.deleteToken();
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.login(email, password);
      await _storage.saveToken(data['token'] as String);
      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _storage.saveUser(_user!);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.register(data);
      await _storage.saveToken(res['token'] as String);
      _user = UserModel.fromJson(res['user'] as Map<String, dynamic>);
      await _storage.saveUser(_user!);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.deleteToken();
    await _storage.clearUser();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> updateUser(UserModel updated) async {
    _user = updated;
    await _storage.saveUser(updated);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
