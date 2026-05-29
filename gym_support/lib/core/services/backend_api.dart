import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/exercise.dart';

class BackendApi {
  static Uri get _baseUri {
    const devHost = String.fromEnvironment(
      'BACKEND_HOST',
      defaultValue: '10.87.40.163:3000',
    );

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
    required String confirmPassword,
    required String name,
  }) async {
    final response = await http.post(
      _baseUri.resolve('/api/auth/register'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'name': name,
      }),
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

  static Future<Map<String, dynamic>> updateOnboardingProfile({
    required String email,
    String? goal,
    String? schedule,
  }) async {
    final response = await http.put(
      _baseUri.resolve('/api/profiles/${Uri.encodeComponent(email)}'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (goal != null) 'goal': goal,
        if (schedule != null) 'schedule': schedule,
      }),
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Không thể cập nhật hồ sơ');
    }

    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>?> getWorkoutPlanByEmail(
    String email,
  ) async {
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
    if (decoded is Map<String, dynamic>) {
      return decoded['data'] as Map<String, dynamic>?;
    }
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

  static Future<List<Exercise>> getExercises({
    String? query,
    String? muscle,
  }) async {
    final params = <String, String>{};
    if (query != null && query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }
    if (muscle != null && muscle.trim().isNotEmpty) {
      params['muscle'] = muscle.trim();
    }

    final uri = _baseUri.replace(
      path: '/api/exercises',
      queryParameters: params.isEmpty ? null : params,
    );
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Không thể tải danh sách bài tập');
    }

    final decoded = jsonDecode(response.body);
    final exercises = decoded is Map<String, dynamic>
        ? decoded['exercises']
        : null;
    if (exercises is List) {
      return exercises
          .whereType<Map>()
          .map((item) => Exercise.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return const <Exercise>[];
  }

  static Future<Map<String, dynamic>> getDashboardSummary(String email) async {
    final response = await http.get(
      _baseUri.resolve('/api/dashboard/${Uri.encodeComponent(email)}'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = jsonDecode(response.body);
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Không thể tải dữ liệu tổng quan');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final dashboard = decoded['dashboard'];
      if (dashboard is Map<String, dynamic>) {
        return dashboard;
      }
    }

    return <String, dynamic>{};
  }

  static Future<String> sendAiCoachMessage({
    required String message,
    String? email,
  }) async {
    final response = await http.post(
      _baseUri.resolve('/api/ai/chat'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message, if (email != null) 'email': email}),
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final messageText = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw Exception(messageText ?? 'Không thể kết nối AI coach');
    }

    if (decoded is Map<String, dynamic>) {
      return decoded['reply']?.toString() ?? 'Mình có thể giúp gì thêm?';
    }

    return 'Mình có thể giúp gì thêm?';
  }

  static Future<Map<String, dynamic>> getHomeSummary(String email) async {
    final response = await http.get(
      _baseUri.resolve('/api/home/${Uri.encodeComponent(email)}'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = jsonDecode(response.body);
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Không thể tải dữ liệu home');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final home = decoded['home'];
      if (home is Map<String, dynamic>) {
        return home;
      }
    }

    return <String, dynamic>{};
  }

  static Future<Map<String, dynamic>?> getWorkoutSession(String email) async {
    final response = await http.get(
      _baseUri.resolve('/api/workout/session/${Uri.encodeComponent(email)}'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = jsonDecode(response.body);
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Không thể tải workout session');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded['session'] as Map<String, dynamic>?;
    }
    return null;
  }

  static Future<Map<String, dynamic>> saveWorkoutSession({
    required String email,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final response = await http.post(
      _baseUri.resolve('/api/workout/session'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'exercises': exercises}),
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Không thể lưu workout session');
    }

    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> updateWorkoutExercise({
    required String email,
    required String exerciseId,
    required String sets,
    required String reps,
  }) async {
    final response = await http.put(
      _baseUri.resolve(
        '/api/workout/session/${Uri.encodeComponent(email)}/exercise',
      ),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'exerciseId': exerciseId, 'sets': sets, 'reps': reps}),
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Không thể cập nhật bài tập');
    }

    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> completeWorkout({
    required String email,
  }) async {
    final response = await http.post(
      _baseUri.resolve('/api/workout/complete'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Không thể hoàn tất workout');
    }

    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  static Future<List<Map<String, dynamic>>> getWorkoutHistory({
    required String email,
    int limit = 20,
  }) async {
    final response = await http.get(
      _baseUri.resolve(
        '/api/workout/history/${Uri.encodeComponent(email)}?limit=$limit',
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = jsonDecode(response.body);
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Không thể tải lịch sử workout');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final history = decoded['history'];
      if (history is List) {
        return history
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    return <Map<String, dynamic>>[];
  }
}
