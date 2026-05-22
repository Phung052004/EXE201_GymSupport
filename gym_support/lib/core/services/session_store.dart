import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const String emailKey = 'session_email';
  static const String tokenKey = 'session_token';
  static const String profileCompleteKey = 'session_profile_complete';

  static Future<void> savePendingEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(emailKey, email);
    await prefs.remove(tokenKey);
    await prefs.setBool(profileCompleteKey, false);
  }

  static Future<void> saveAuth({
    required String email,
    required String token,
    bool profileComplete = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(emailKey, email);
    await prefs.setString(tokenKey, token);
    await prefs.setBool(profileCompleteKey, profileComplete);
  }

  static Future<void> markProfileComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(profileCompleteKey, true);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(emailKey);
    await prefs.remove(tokenKey);
    await prefs.remove(profileCompleteKey);
  }
}
