import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  static const String _prefKey = 'selected_language';

  LanguageProvider() {
    _loadFromPrefs();
  }

  Locale get currentLocale => _currentLocale;

  String get languageName {
    switch (_currentLocale.languageCode) {
      case 'hi': return 'Hindi';
      case 'mr': return 'Marathi';
      default: return 'English';
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!['en', 'hi', 'mr'].contains(locale.languageCode)) return;
    
    _currentLocale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_prefKey);
    if (languageCode != null) {
      _currentLocale = Locale(languageCode);
      notifyListeners();
    }
  }
}
