import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BackendApi {
  static Uri get _baseUri {
    // Development host: set this to your PC's LAN IP when testing on a real device.
    // For your setup use 10.87.40.163 (Wi‑Fi). If you're using the Android emulator,
    // keep using 10.0.2.2 instead.
    const devHost = '10.87.40.163:3000';

    if (kIsWeb) {
      return Uri.parse('http://localhost:3000');
    }

    // If you want emulator behavior, change this to 10.0.2.2:3000
    return Uri.parse('http://$devHost');
  }

  static Future<void> saveOnboardingProfile({
    required String email,
    required String name,
    required String gender,
    required String age,
    required String weight,
    required String height,
    required String bmi,
    required String goal,
    required String schedule,
  }) async {
    final response = await http.post(
      _baseUri.resolve('/api/profiles'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'name': name,
        'gender': gender,
        'age': age,
        'weight': weight,
        'height': height,
        'bmi': bmi,
        'goal': goal,
        'schedule': schedule,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = jsonDecode(response.body);
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Không thể lưu hồ sơ người dùng');
    }
  }

  static Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await http.post(
      _baseUri.resolve('/api/auth/register'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'name': name}),
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Không thể đăng ký tài khoản');
    }

    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _baseUri.resolve('/api/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Không thể đăng nhập');
    }

    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>?> getOnboardingProfileByEmail(
    String email,
  ) async {
    final response = await http.get(
      _baseUri.resolve('/api/profiles/${Uri.encodeComponent(email)}'),
    );

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = jsonDecode(response.body);
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Không thể tải hồ sơ người dùng');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final profile = decoded['profile'];
      if (profile is Map<String, dynamic>) {
        return profile;
      }
    }

    return null;
  }

  static Future<Map<String, dynamic>?> getWorkoutPlanByEmail(String email) async {
    final response = await http.get(
      _baseUri.resolve('/api/workout-plan/${Uri.encodeComponent(email)}'),
    );

    if (response.statusCode == 404) return null;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = jsonDecode(response.body);
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Không thể tải workout plan');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded['data'] as Map<String, dynamic>?;
    return null;
  }

  static Future<Map<String, dynamic>> generatePlan({
    required String name,
    required String gender,
    required String age,
    required String weight,
    required String height,
    required String goal,
    required int daysPerWeek,
    String? email,
  }) async {
    final response = await http.post(
      _baseUri.resolve('/api/generate-plan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'gender': gender,
        'age': age,
        'weight': weight,
        'height': height,
        'goal': goal,
        'daysPerWeek': daysPerWeek,
        if (email != null) 'email': email,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = jsonDecode(response.body);
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Không thể tạo lịch tập');
    }

    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> uploadScanImage({
    required List<int> bytes,
    required String filename,
    String? email,
  }) async {
    final uri = _baseUri.resolve('/api/scan-equipment');
    final request = http.MultipartRequest('POST', uri);
    if (email != null) request.fields['email'] = email;
    request.files.add(
      http.MultipartFile.fromBytes('image', bytes, filename: filename),
    );

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    final decoded = jsonDecode(resp.body);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Không thể upload ảnh');
    }

    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }
}
