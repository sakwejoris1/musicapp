import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _secure = const FlutterSecureStorage();
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveToken(String token) =>
      _secure.write(key: AppConstants.keyToken, value: token);

  Future<String?> getToken() =>
      _secure.read(key: AppConstants.keyToken);

  Future<void> deleteToken() =>
      _secure.delete(key: AppConstants.keyToken);

  Future<void> saveUser(UserModel user) =>
      _prefs.setString(AppConstants.keyUser, jsonEncode(user.toJson()));

  UserModel? getUser() {
    final data = _prefs.getString(AppConstants.keyUser);
    if (data == null) return null;
    return UserModel.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }

  Future<void> clearUser() => _prefs.remove(AppConstants.keyUser);

  Future<void> saveLanguage(String lang) =>
      _prefs.setString(AppConstants.keyLanguage, lang);

  String getLanguage() => _prefs.getString(AppConstants.keyLanguage) ?? 'en';

  Future<void> addPurchase(String itemId) async {
    final purchases = getPurchases();
    if (!purchases.contains(itemId)) {
      purchases.add(itemId);
      await _prefs.setStringList(AppConstants.keyPurchases, purchases);
    }
  }

  List<String> getPurchases() =>
      _prefs.getStringList(AppConstants.keyPurchases) ?? [];

  bool hasPurchased(String itemId) => getPurchases().contains(itemId);

  Future<void> clearAll() async {
    await _secure.deleteAll();
    await _prefs.clear();
  }
}
