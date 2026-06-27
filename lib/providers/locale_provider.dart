import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class LocaleProvider extends ChangeNotifier {
  LocaleProvider() : _locale = Locale(StorageService().getLanguage());

  Locale _locale;

  Locale get locale => _locale;

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    await StorageService().saveLanguage(locale.languageCode);
    notifyListeners();
  }
}
