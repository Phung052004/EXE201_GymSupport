import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const String emailKey = 'session_email';
  static const String tokenKey = 'session_token';
  static const String userIdKey = 'session_user_id';
  static const String roleKey = 'session_role';
  static const String customerIdKey = 'session_customer_id';
  static const String profileCompleteKey = 'session_profile_complete';

  static Future<void> savePendingEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(emailKey, email);
    await prefs.remove(tokenKey);
    await prefs.remove(userIdKey);
    await prefs.remove(roleKey);
    await prefs.remove(customerIdKey);
    await prefs.setBool(profileCompleteKey, false);
  }

  static Future<void> saveAuth({
    required String email,
    required String token,
    String? userId,
    String? role,
    String? customerId,
    bool profileComplete = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(emailKey, email);
    await prefs.setString(tokenKey, token);
    if (userId != null) await prefs.setString(userIdKey, userId);
    if (role != null) await prefs.setString(roleKey, role);
    if (customerId != null) await prefs.setString(customerIdKey, customerId);
    await prefs.setBool(profileCompleteKey, profileComplete);
  }

  static Future<void> saveCustomerId(String customerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(customerIdKey, customerId);
  }

  static Future<void> markProfileComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(profileCompleteKey, true);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(emailKey);
    await prefs.remove(tokenKey);
    await prefs.remove(userIdKey);
    await prefs.remove(roleKey);
    await prefs.remove(customerIdKey);
    await prefs.remove(profileCompleteKey);
  }
}
