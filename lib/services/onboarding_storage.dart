import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStorage {
  static const _catNameKey = 'cat_name';
  static const _personalitiesKey = 'cat_personalities';
  static const _hasAccountKey = 'has_account';
  static const _isLoggedInKey = 'is_logged_in';

  static Future<String?> getCatName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_catNameKey);
  }

  static Future<void> saveCatName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_catNameKey, name);
  }

  static Future<List<String>> getPersonalities() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_personalitiesKey) ?? [];
  }

  static Future<void> savePersonalities(List<String> personalities) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_personalitiesKey, personalities);
  }

  static Future<bool> hasAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasAccountKey) ?? false;
  }

  static Future<void> setHasAccount(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasAccountKey, value);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, value);
  }
}
