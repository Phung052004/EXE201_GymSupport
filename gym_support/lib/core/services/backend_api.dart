import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/exercise.dart';
import 'session_store.dart';

class BackendApi {
  static const String _quickWorkoutPlanKey = 'quick_workout_plan_id';
  static const String _quickWorkoutSessionKey = 'quick_workout_session_id';
  static const String _currentWorkoutPlanKey = 'current_workout_plan_id';
  static const String _currentWorkoutSessionKey = 'current_workout_session_id';
  static const String _currentWorkoutIsQuickKey = 'current_workout_is_quick';

  static Uri get _baseUri {
    const devHost = String.fromEnvironment(
      'BACKEND_HOST',
      defaultValue: '10.0.2.2:5028',
    );

    return Uri.parse('http://$devHost');
  }

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (!auth) return headers;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(SessionStore.tokenKey);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static dynamic _decode(http.Response response) {
    if (response.body.trim().isEmpty) return null;
    return jsonDecode(response.body);
  }

  static String _messageFrom(dynamic decoded, String fallback) {
    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('message')) return decoded['message'].toString();
      if (decoded.containsKey('Message')) return decoded['Message'].toString();
      if (decoded.containsKey('error')) return decoded['error'].toString();
      if (decoded.containsKey('errors')) {
        final errs = decoded['errors'];
        if (errs is Map) return errs.values.first.toString();
        if (errs is List) return errs.first.toString();
        return errs.toString();
      }
    }
    return fallback;
  }

  static T? _value<T>(Map<String, dynamic> map, String key) {
    final lowerKey = key.substring(0, 1).toLowerCase() + key.substring(1);
    final upperKey = key.substring(0, 1).toUpperCase() + key.substring(1);
    final value = map[lowerKey] ?? map[upperKey] ?? map[key];
    return value is T ? value : null;
  }

  static Future<dynamic> _get(String path, {bool auth = false}) async {
    final response = await http.get(
      _baseUri.resolve(path),
      headers: await _headers(auth: auth),
    );
    final decoded = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_messageFrom(decoded, 'Không thể tải dữ liệu'));
    }
    return decoded;
  }

  static Future<dynamic> _post(
    String path, {
    Object? body,
    bool auth = false,
  }) async {
    final response = await http.post(
      _baseUri.resolve(path),
      headers: await _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
    final decoded = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = _messageFrom(decoded, 'Lỗi ${response.statusCode}');
      throw Exception(msg);
    }
    return decoded;
  }

  static Future<dynamic> _put(
    String path, {
    Object? body,
    bool auth = false,
  }) async {
    final response = await http.put(
      _baseUri.resolve(path),
      headers: await _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
    final decoded = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_messageFrom(decoded, 'Không thể cập nhật dữ liệu'));
    }
    return decoded;
  }

  static Future<void> _delete(String path, {bool auth = false}) async {
    final response = await http.delete(
      _baseUri.resolve(path),
      headers: await _headers(auth: auth),
    );
    final decoded = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_messageFrom(decoded, 'Không thể xóa dữ liệu'));
    }
  }

  static Future<String?> currentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(SessionStore.userIdKey);
  }

  static Future<String?> currentToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(SessionStore.tokenKey);
  }

  static Future<String?> getMeUserId() async {
    final decoded = await _get('/api/auth/me', auth: true);
    if (decoded is Map<String, dynamic>) {
      return _value<String>(decoded, 'userId');
    }
    return null;
  }

  static Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String confirmPassword,
    required String name,
  }) async {
    if (password != confirmPassword) {
      throw Exception('Mật khẩu xác nhận không khớp');
    }

    final decoded = await _post(
      '/api/auth/register/customer',
      body: {'email': email, 'password': password, 'fullName': name},
    );
    
    if (decoded is Map<String, dynamic>) {
      return {
        ...decoded,
        'userId': _value<String>(decoded, 'userId'),
        'token': _value<String>(decoded, 'token'),
      };
    }
    return <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final decoded = await _post(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );

    if (decoded is Map<String, dynamic>) {
      // Normalize common keys
      return {
        ...decoded,
        'userId': _value<String>(decoded, 'userId'),
        'token': _value<String>(decoded, 'token'),
        'role': _value<String>(decoded, 'role'),
      };
    }

    return <String, dynamic>{};
  }

  static Future<Map<String, dynamic>?> getCustomerByUserId(
    String userId,
  ) async {
    try {
      final decoded = await _get(
        '/api/Customer/user/${Uri.encodeComponent(userId)}',
        auth: true,
      );
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getOnboardingProfileByEmail(
    String email,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(SessionStore.userIdKey);
    if (userId == null || userId.isEmpty) return null;

    final userDecoded = await _get('/api/User/${Uri.encodeComponent(userId)}');
    final user = userDecoded is Map<String, dynamic>
        ? userDecoded
        : <String, dynamic>{};
    final customer = await getCustomerByUserId(userId);
    if (customer == null) return null;

    final fullName = user['fullName']?.toString() ?? user['FullName']?.toString() ?? email;
    final userEmail = user['email']?.toString() ?? user['Email']?.toString() ?? email;
    
    final gender = customer['gender']?.toString() ?? customer['Gender']?.toString();
    final age = customer['age'] is int 
        ? customer['age'] as int 
        : int.tryParse(customer['age']?.toString() ?? customer['Age']?.toString() ?? '0') ?? 0;
    
    final heightCm = customer['heightCm'] is num 
        ? (customer['heightCm'] as num).toInt() 
        : int.tryParse(customer['heightCm']?.toString() ?? customer['HeightCm']?.toString() ?? '0') ?? 0;
        
    final weightKg = customer['weightKg'] is num 
        ? (customer['weightKg'] as num).toInt() 
        : int.tryParse(customer['weightKg']?.toString() ?? customer['WeightKg']?.toString() ?? '0') ?? 0;

    final bmiVal = customer['bmi'] is num 
        ? (customer['bmi'] as num).toDouble() 
        : double.tryParse(customer['bmi']?.toString() ?? customer['Bmi']?.toString() ?? '0') ?? 0;
    
    final bmi = bmiVal > 0 ? bmiVal : _calculateBmi(weightKg.toDouble(), heightCm.toDouble());

    final goal = customer['goal']?.toString() ?? customer['Goal']?.toString();
    final experienceLevel = customer['experienceLevel']?.toString() ?? customer['ExperienceLevel']?.toString();
    final injuryNotes = customer['injuryNotes']?.toString() ?? customer['InjuryNotes']?.toString();
    final customerId = customer['id']?.toString() ?? customer['Id']?.toString();

    if (customerId != null) {
      await SessionStore.saveCustomerId(customerId);
    }

    return {
      'id': customerId,
      'userId': userId,
      'fullName': fullName,
      'email': userEmail,
      'gender': gender ?? '',
      'age': age,
      'bmi': bmi,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'goal': goal ?? '',
      'experienceLevel': experienceLevel ?? '',
      'injuryNotes': injuryNotes ?? '',
      // Backward compatibility for existing UI if needed, but primarily following new schema
      'name': fullName,
      'weight': weightKg > 0 ? weightKg.toString() : '',
      'height': heightCm > 0 ? heightCm.toString() : '',
      'schedule': experienceLevel ?? '',
    };
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
    String? injuryNotes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(SessionStore.userIdKey);
    if (userId == null || userId.isEmpty) {
      throw Exception('Vui lòng đăng nhập sau khi xác minh email');
    }

    final weightVal = double.tryParse(weight) ?? 0;
    final heightVal = double.tryParse(height) ?? 0;

    final payload = {
      'userId': userId,
      'gender': gender,
      'age': int.tryParse(age) ?? 0,
      'bmi': _calculateBmi(weightVal, heightVal),
      'heightCm': heightVal.toInt(),
      'weightKg': weightVal.toInt(),
      'goal': goal,
      'experienceLevel': schedule,
      'injuryNotes': injuryNotes ?? '',
    };

    await _put('/api/User/$userId', body: {'fullName': name, 'email': email});

    final customer = await getCustomerByUserId(userId);
    if (customer == null) {
      final created = await _post(
        '/api/Customer',
        auth: true,
        body: payload,
      );
      if (created is Map<String, dynamic>) {
        final id = created['id']?.toString() ?? created['Id']?.toString();
        if (id != null) await SessionStore.saveCustomerId(id);
      }
      return;
    }

    final customerId = customer['id']?.toString() ?? customer['Id']?.toString();
    if (customerId == null || customerId.isEmpty) {
      throw Exception('Không tìm thấy hồ sơ customer');
    }
    await _put('/api/Customer/$customerId', auth: true, body: payload);
    await SessionStore.saveCustomerId(customerId);
  }

  static Future<Map<String, dynamic>> updateBodyMetrics({
    required String weight,
    required String height,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(SessionStore.userIdKey);
    var customerId = prefs.getString(SessionStore.customerIdKey);
    if (userId == null || userId.isEmpty) {
      throw Exception('Không tìm thấy hồ sơ người dùng');
    }

    if (customerId == null || customerId.isEmpty) {
      final customer = await getCustomerByUserId(userId);
      customerId = customer == null ? null : _value<String>(customer, 'id');
      if (customerId != null) await SessionStore.saveCustomerId(customerId);
    }

    if (customerId == null || customerId.isEmpty) {
      throw Exception('Không tìm thấy hồ sơ customer');
    }

    final weightKg = int.tryParse(weight);
    final heightCm = int.tryParse(height);
    if (weightKg == null ||
        weightKg <= 0 ||
        heightCm == null ||
        heightCm <= 0) {
      throw Exception('Vui lòng nhập cân nặng và chiều cao hợp lệ');
    }

    final bmi = _calculateBmi(weightKg.toDouble(), heightCm.toDouble());
    await _put(
      '/api/Customer/$customerId',
      auth: true,
      body: {'heightCm': heightCm, 'weightKg': weightKg, 'bmi': bmi},
    );

    return {
      'success': true,
      'weight': weightKg.toString(),
      'height': heightCm.toString(),
      'bmi': bmi == 0 ? '--' : bmi.toStringAsFixed(1),
    };
  }

  static Future<Map<String, dynamic>> updateOnboardingProfile({
    required String email,
    String? goal,
    String? schedule,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(SessionStore.userIdKey);
    final customerId = prefs.getString(SessionStore.customerIdKey);
    if (userId == null || customerId == null) {
      throw Exception('Không tìm thấy hồ sơ người dùng');
    }

    final payload = <String, dynamic>{};
    if (goal != null) payload['goal'] = goal;
    if (schedule != null) payload['experienceLevel'] = schedule;

    await _put('/api/Customer/$customerId', auth: true, body: payload);
    return {'success': true};
  }

  static double _calculateBmi(double weightKg, double heightCm) {
    if (weightKg <= 0 || heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  static Future<List<Map<String, dynamic>>> getMuscles() async {
    final decoded = await _get('/api/muscles');
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  static Future<List<String>> getMuscleCategories() async {
    final decoded = await _get('/api/muscles/categories');
    if (decoded is List) {
      return decoded.map((e) => e.toString()).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getMusclesByCategory(String category) async {
    final decoded = await _get('/api/muscles/by-category?category=${Uri.encodeComponent(category)}');
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> getMuscleById(String id) async {
    final decoded = await _get('/api/muscles/$id');
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  static Future<List<Exercise>> getExercises({
    String? query,
    String? muscleId,
    String? category,
  }) async {
    final Map<String, String> queryParams = {};
    if (category != null) queryParams['category'] = category;
    if (muscleId != null) queryParams['muscleId'] = muscleId;
    
    final uri = _baseUri.resolve('/api/exercises').replace(queryParameters: queryParams);
    
    final response = await http.get(
      uri,
      headers: await _headers(auth: false),
    );
    
    final decoded = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_messageFrom(decoded, 'Không thể tải bài tập'));
    }

    final list = decoded is List ? decoded : const [];
    final exercises = list.whereType<Map>().map((item) {
      final json = Map<String, dynamic>.from(item);
      return Exercise.fromJson(json);
    }).toList();

    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      return exercises.where((e) => e.name.toLowerCase().contains(q)).toList();
    }
    
    return exercises;
  }

  static Future<Map<String, dynamic>> getExerciseById(String id) async {
    final decoded = await _get('/api/exercises/$id');
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  static Future<List<Map<String, dynamic>>> _getExerciseRows() async {
    final decoded = await _get('/api/exercises');
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  static Future<List<Map<String, dynamic>>> getWorkoutPlansByUser([
    String? userId,
  ]) async {
    final resolvedUserId = userId ?? await currentUserId();
    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final decoded = await _get('/api/workoutplans/user/$resolvedUserId', auth: true);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  static Future<Map<String, dynamic>?> getActiveWorkoutPlan() async {
    final userId = await currentUserId();
    if (userId == null) return null;
    try {
      final decoded = await _get('/api/workoutplans/user/$userId/active', auth: true);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}

    try {
      final plans = await getWorkoutPlansByUser(userId);
      for (final plan in plans) {
        if (_value<bool>(plan, 'isActive') == true) return plan;
      }
      if (plans.isNotEmpty) return plans.first;
    } catch (_) {}
    return null;
  }

  static Future<void> activateWorkoutPlan(String planId) async {
    await _post('/api/workoutplans/$planId/activate', auth: true, body: {});
  }

  static Future<void> deactivateWorkoutPlan(String planId) async {
    await _post('/api/workoutplans/$planId/deactivate', auth: true, body: {});
  }

  static Future<Map<String, dynamic>> getWorkoutPlanById(String id) async {
    final decoded = await _get('/api/workoutplans/$id', auth: true);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> createWorkoutPlan(Map<String, dynamic> payload) async {
    final decoded = await _post(
      '/api/workoutplans',
      auth: true,
      body: payload,
    );
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> createRoutineWithSessions(
    Map<String, dynamic> payload,
  ) async {
    final decoded = await _post(
      '/api/workoutplans/create-routine',
      auth: true,
      body: payload,
    );
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  static Future<void> deleteWorkoutPlan(String id) =>
      _delete('/api/workoutplans/$id');

  static Future<Map<String, dynamic>> addWorkoutPlanSession({
    required String planId,
    required String dayOfWeek,
    required String focus,
  }) async {
    final decoded = await _post(
      '/api/workoutplans/$planId/sessions',
      body: {'dayOfWeek': dayOfWeek, 'focus': focus},
    );
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> addExerciseToPlanSession({
    required String planId,
    required String sessionId,
    required String exerciseId,
    required String exerciseName,
    required int sets,
    required String reps,
    String notes = '',
  }) async {
    final decoded = await _post(
      '/api/workoutplans/$planId/sessions/$sessionId/exercises',
      body: {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'sets': sets,
        'reps': reps,
        'notes': notes,
      },
    );
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> startWorkout({
    required String planId,
    required String sessionId,
  }) async {
    final userId = await currentUserId();
    if (userId == null) throw Exception('Vui lòng đăng nhập');
    final decoded = await _post(
      '/api/workout-session-logs/start',
      auth: true,
      body: {
        'userId': userId,
        'workoutPlanId': planId,
        'planSessionId': sessionId,
      },
    );
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  static Future<Map<String, dynamic>> getWorkoutSessionDetail(String logId) async {
    final decoded = await _get('/api/workout-session-logs/$logId', auth: true);
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  static Future<Map<String, dynamic>> saveSetLog({
    required String logId,
    required String exerciseId,
    required int setNumber,
    required int reps,
    required double weight,
    String? note,
  }) async {
    final decoded = await _post(
      '/api/workout-session-logs/$logId/exercises/$exerciseId/sets',
      auth: true,
      body: {
        'setNumber': setNumber,
        'reps': reps,
        'weight': weight,
        'note': note,
      },
    );
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  static Future<Map<String, dynamic>> createRoutinePlan({
    required String name,
    required String goal,
    required int daysPerWeek,
    required List<Exercise> exercises,
  }) async {
    if (exercises.isEmpty) {
      throw Exception('Vui lòng chọn ít nhất 1 bài tập');
    }

    final safeDays = daysPerWeek.clamp(1, 7);
    final buckets = List.generate(safeDays, (_) => <Exercise>[]);
    for (var i = 0; i < exercises.length; i += 1) {
      buckets[i % safeDays].add(exercises[i]);
    }

    return createRoutinePlanByDays(
      name: name,
      goal: goal,
      daysPerWeek: safeDays,
      exercisesByDay: buckets,
    );
  }

  static Future<Map<String, dynamic>> createRoutinePlanByDays({
    required String name,
    required String goal,
    required int daysPerWeek,
    required List<List<Exercise>> exercisesByDay,
  }) async {
    final safeDays = daysPerWeek.clamp(1, 7);
    final normalizedDays = List.generate(
      safeDays,
      (index) => index < exercisesByDay.length
          ? List<Exercise>.from(exercisesByDay[index])
          : <Exercise>[],
    );

    final totalExercises = normalizedDays.fold<int>(
      0,
      (total, dayExercises) => total + dayExercises.length,
    );
    if (totalExercises == 0) {
      throw Exception('Vui lòng chọn ít nhất 1 bài tập');
    }

    final plan = await createWorkoutPlan({
      'userId': await currentUserId(),
      'name': name,
      'goal': goal,
      'daysPerWeek': safeDays,
    });
    final planId = _value<String>(plan, 'id') ?? '';
    if (planId.isEmpty) {
      throw Exception('Không tạo được workout plan');
    }

    final days = _routineDaysStartingToday(safeDays);
    for (var i = 0; i < safeDays; i += 1) {
      final dayExercises = normalizedDays[i];
      final focus = dayExercises.isEmpty
          ? 'Recovery'
          : dayExercises.map((item) => item.muscleGroup).toSet().join(' / ');
      final updatedPlan = await addWorkoutPlanSession(
        planId: planId,
        dayOfWeek: days[i],
        focus: focus,
      );

      final sessions = _value<List>(updatedPlan, 'sessions') ?? const [];
      final session = sessions.isNotEmpty && sessions.last is Map
          ? Map<String, dynamic>.from(sessions.last as Map)
          : <String, dynamic>{};
      final sessionId = _value<String>(session, 'id') ?? '';
      if (sessionId.isEmpty) continue;

      for (final exercise in dayExercises) {
        final parts = _splitSetsAndReps(exercise.setsAndReps);
        await addExerciseToPlanSession(
          planId: planId,
          sessionId: sessionId,
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          sets: parts.$1,
          reps: parts.$2,
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_quickWorkoutPlanKey);
    await prefs.remove(_quickWorkoutSessionKey);
    await prefs.remove(_currentWorkoutPlanKey);
    await prefs.remove(_currentWorkoutSessionKey);
    await prefs.remove(_currentWorkoutIsQuickKey);

    return plan;
  }

  static List<String> _routineDaysStartingToday(int daysPerWeek) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const offsetsByDays = {
      1: [0],
      2: [0, 3],
      3: [0, 2, 4],
      4: [0, 2, 4, 6],
      5: [0, 1, 2, 4, 5],
      6: [0, 1, 2, 3, 4, 5],
      7: [0, 1, 2, 3, 4, 5, 6],
    };

    final todayIndex = DateTime.now().weekday - 1;
    final safeDays = daysPerWeek.clamp(1, 7);
    final offsets = offsetsByDays[safeDays] ?? offsetsByDays[3]!;
    return offsets.map((offset) => names[(todayIndex + offset) % 7]).toList();
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
    final reply = await sendAiCoachMessage(
      message:
          'Hãy tạo đề xuất lịch tập $daysPerWeek ngày/tuần cho $name. '
          'Thông tin: giới tính $gender, tuổi $age, cân nặng ${weight}kg, '
          'chiều cao ${height}cm, mục tiêu $goal. '
          'Hãy trình bày lịch tập chi tiết theo từng ngày và hỏi tôi xác nhận trước khi lưu.',
    );

    return {
      'data': {'aiResponse': reply},
    };
  }

  static Future<Map<String, dynamic>?> getWorkoutPlanByEmail(
    String email,
  ) async {
    final plans = await getWorkoutPlansByUser();
    return plans.isEmpty ? null : plans.first;
  }

  static Future<Map<String, dynamic>?> _quickPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final quickPlanId = prefs.getString(_quickWorkoutPlanKey);
    final plans = await getWorkoutPlansByUser();
    if (quickPlanId != null) {
      for (final plan in plans) {
        if (_value<String>(plan, 'id') == quickPlanId) return plan;
      }
    }
    for (final plan in plans) {
      if ((_value<String>(plan, 'name') ?? '') == 'Quick Workout') {
        await prefs.setString(
          _quickWorkoutPlanKey,
          _value<String>(plan, 'id')!,
        );
        return plan;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _activeRoutinePlan() async {
    final plans = await getWorkoutPlansByUser();
    final activePlans = plans.where((plan) {
      final isActive = _value<bool>(plan, 'isActive') ?? true;
      final name = (_value<String>(plan, 'name') ?? '').trim().toLowerCase();
      return isActive && name != 'quick workout';
    }).toList();
    if (activePlans.isNotEmpty) return activePlans.last;
    return null;
  }

  static Map<String, dynamic>? _selectWorkoutSession(
    Map<String, dynamic> plan,
  ) {
    final sessions = _value<List>(plan, 'sessions') ?? _value<List>(plan, 'workoutDays') ?? const [];
    final sessionMaps = sessions
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    if (sessionMaps.isEmpty) return null;

    final today = _todayName();
    for (final session in sessionMaps) {
      final dayOfWeek = (_value<String>(session, 'dayOfWeek') ?? _value<String>(session, 'weekday') ?? '').trim();
      final exercises = _value<List>(session, 'exercises') ?? const [];
      if (_matchesToday(dayOfWeek, today) && exercises.isNotEmpty) {
        return session;
      }
    }

    for (final session in sessionMaps) {
      final exercises = _value<List>(session, 'exercises') ?? const [];
      if (exercises.isNotEmpty) return session;
    }

    return sessionMaps.first;
  }

  static Future<void> _rememberCurrentWorkout({
    required String planId,
    required String sessionId,
    required bool isQuick,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentWorkoutPlanKey, planId);
    await prefs.setString(_currentWorkoutSessionKey, sessionId);
    await prefs.setBool(_currentWorkoutIsQuickKey, isQuick);
  }

  static Future<Map<String, dynamic>?> getWorkoutSession(String email) async {
    var isQuick = false;
    var plan = await _activeRoutinePlan();
    plan ??= await _quickPlan();
    isQuick =
        (_value<String>(plan ?? {}, 'name') ?? '').trim().toLowerCase() ==
        'quick workout';
    if (plan == null) return null;

    final session = _selectWorkoutSession(plan);
    if (session == null) return null;

    final planId = _value<String>(plan, 'id') ?? '';
    final sessionId = _value<String>(session, 'id') ?? '';
    if (planId.isNotEmpty && sessionId.isNotEmpty) {
      await _rememberCurrentWorkout(
        planId: planId,
        sessionId: sessionId,
        isQuick: isQuick,
      );
    }

    final exercises = (_value<List>(session, 'exercises') ?? const [])
        .whereType<Map>()
        .map((item) {
          final row = Map<String, dynamic>.from(item);
          return {
            'exerciseId': _value<String>(row, 'exerciseId'),
            'name': _value<String>(row, 'exerciseName') ?? 'Exercise',
            'muscleGroup': _value<String>(row, 'muscleGroup') ?? 'Unknown',
            'sets': _value<num>(row, 'sets')?.toString() ?? '3',
            'reps': _value<String>(row, 'reps') ?? '10',
          };
        })
        .toList();

    final dayOfWeek = _value<String>(session, 'dayOfWeek') ?? '';
    return {
      'day': dayOfWeek.isEmpty ? 'Today' : _displayDay(dayOfWeek),
      'focus': _value<String>(session, 'focus') ?? '',
      'exercises': exercises,
    };
  }

  static Future<Map<String, dynamic>> saveWorkoutSession({
    required String email,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final existing = await _quickPlan();
    final existingId = existing == null ? null : _value<String>(existing, 'id');
    if (existingId != null) {
      await deleteWorkoutPlan(existingId);
    }

    if (exercises.isEmpty) return {'success': true};

    final prefs = await SharedPreferences.getInstance();
    final plan = await createWorkoutPlan({
      'userId': await currentUserId(),
      'name': 'Quick Workout',
      'goal': 'Custom',
      'daysPerWeek': 1,
    });
    final planId = _value<String>(plan, 'id') ?? '';
    await prefs.setString(_quickWorkoutPlanKey, planId);
    final updatedPlan = await addWorkoutPlanSession(
      planId: planId,
      dayOfWeek: 'Today',
      focus: 'Quick Workout',
    );
    final sessions = _value<List>(updatedPlan, 'sessions') ?? const [];
    final session = sessions.isNotEmpty && sessions.last is Map
        ? Map<String, dynamic>.from(sessions.last as Map)
        : <String, dynamic>{};
    final sessionId = _value<String>(session, 'id') ?? '';
    await prefs.setString(_quickWorkoutSessionKey, sessionId);
    await _rememberCurrentWorkout(
      planId: planId,
      sessionId: sessionId,
      isQuick: true,
    );

    for (final exercise in exercises) {
      final exerciseId = exercise['exerciseId']?.toString() ?? '';
      if (exerciseId.isEmpty) continue;
      final parts = _splitSetsAndReps(exercise['setsAndReps']?.toString());
      await addExerciseToPlanSession(
        planId: planId,
        sessionId: sessionId,
        exerciseId: exerciseId,
        exerciseName: exercise['name']?.toString() ?? 'Exercise',
        sets: parts.$1,
        reps: parts.$2,
      );
    }

    return {'success': true};
  }

  static (int, String) _splitSetsAndReps(String? value) {
    if (value == null) return (3, '10');
    final setsMatch = RegExp(r'(\d+)\s*sets?').firstMatch(value);
    final repsMatch = RegExp(r'x\s*([0-9\-]+)').firstMatch(value);
    return (
      int.tryParse(setsMatch?.group(1) ?? '') ?? 3,
      repsMatch?.group(1) ?? '10',
    );
  }

  static Future<Map<String, dynamic>> updateWorkoutExercise({
    required String email,
    required String exerciseId,
    required String sets,
    required String reps,
  }) async {
    final session = await getWorkoutSession(email);
    final exercises = <Map<String, dynamic>>[];
    for (final item in (session?['exercises'] as List? ?? const [])) {
      if (item is! Map) continue;
      final row = Map<String, dynamic>.from(item);
      exercises.add({
        'exerciseId': row['exerciseId'],
        'name': row['name'],
        'setsAndReps': row['exerciseId'] == exerciseId
            ? '$sets sets x $reps reps'
            : '${row['sets'] ?? 3} sets x ${row['reps'] ?? 10} reps',
      });
    }
    return saveWorkoutSession(email: email, exercises: exercises);
  }

  static Future<Map<String, dynamic>> completeWorkout({
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final planId =
        prefs.getString(_currentWorkoutPlanKey) ??
        prefs.getString(_quickWorkoutPlanKey);
    final sessionId =
        prefs.getString(_currentWorkoutSessionKey) ??
        prefs.getString(_quickWorkoutSessionKey);
    final isQuick =
        prefs.getBool(_currentWorkoutIsQuickKey) ??
        (planId != null && planId == prefs.getString(_quickWorkoutPlanKey));
    final userId = prefs.getString(SessionStore.userIdKey);
    if (userId == null || userId.isEmpty) {
      return {'success': true};
    }

    String? logId;
    Map<String, dynamic>? finishedLog;
    try {
      if (planId != null && sessionId != null) {
        final started = await _post(
          '/api/workout-session-logs/start',
          body: {
            'userId': userId,
            'workoutPlanId': planId,
            'planSessionId': sessionId,
          },
        );
        logId = started is Map<String, dynamic>
            ? _value<String>(started, 'id')
            : null;
      }
    } catch (_) {
      try {
        final active = await _get('/api/workout-session-logs/active/$userId');
        logId = active is Map<String, dynamic>
            ? _value<String>(active, 'id')
            : null;
      } catch (_) {
        logId = null;
      }
    }

    try {
      if (logId != null && logId.isNotEmpty) {
        final decoded = await _put('/api/workout-session-logs/$logId/finish');
        if (decoded is Map<String, dynamic>) {
          finishedLog = decoded;
        }
      }
    } catch (_) {
      // Keep the user's UI flow moving if a stale session cannot be finished.
    }

    if (isQuick && planId != null && planId.isNotEmpty) {
      try {
        await deleteWorkoutPlan(planId);
      } catch (_) {
        // The history log already keeps the workout snapshot.
      }
    }

    await prefs.remove(_quickWorkoutPlanKey);
    await prefs.remove(_quickWorkoutSessionKey);
    await prefs.remove(_currentWorkoutPlanKey);
    await prefs.remove(_currentWorkoutSessionKey);
    await prefs.remove(_currentWorkoutIsQuickKey);
    return {
      'success': true,
      'log': finishedLog,
      'totalDurationSeconds':
          _value<num>(finishedLog ?? {}, 'totalDurationSeconds')?.toInt() ?? 0,
      'totalSets': _value<num>(finishedLog ?? {}, 'totalSets')?.toInt() ?? 0,
      'totalExpGained':
          _value<num>(finishedLog ?? {}, 'totalExpGained')?.toInt() ?? 0,
    };
  }

  static Future<List<Map<String, dynamic>>> getWorkoutHistory({
    required String email,
    int limit = 20,
  }) async {
    final userId = await currentUserId();
    if (userId == null || userId.isEmpty) return <Map<String, dynamic>>[];
    final decoded = await _get(
      '/api/workout-session-logs/user/$userId/history',
    );
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .take(limit)
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  static Future<Map<String, dynamic>> _exerciseDetailMaps() async {
    final muscles = await getMuscles();
    final muscleById = {
      for (final item in muscles)
        if ((_value<String>(item, 'id') ?? '').isNotEmpty)
          _value<String>(item, 'id')!: item,
    };

    final exercises = await _getExerciseRows();
    final exerciseById = <String, Map<String, dynamic>>{};
    final primaryMuscleByExerciseId = <String, String>{};

    for (final exercise in exercises) {
      final id = _value<String>(exercise, 'id');
      if (id == null || id.isEmpty) continue;
      exerciseById[id] = exercise;

      final impacts = _value<List>(exercise, 'muscleImpacts') ?? const [];
      if (impacts.isEmpty || impacts.first is! Map) continue;

      final impact = Map<String, dynamic>.from(impacts.first as Map);
      final muscleId = _value<String>(impact, 'muscleId');
      final muscle = muscleId == null ? null : muscleById[muscleId];
      primaryMuscleByExerciseId[id] =
          _value<String>(muscle ?? {}, 'name') ??
          _value<String>(muscle ?? {}, 'category') ??
          'Unknown';
    }

    return {
      'exerciseById': exerciseById,
      'muscleById': muscleById,
      'primaryMuscleByExerciseId': primaryMuscleByExerciseId,
    };
  }

  static Future<Map<String, dynamic>> uploadScanImage({
    required List<int> bytes,
    required String filename,
    String? email,
    String mode = 'equipment_info',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _baseUri.resolve('/api/ai/analyze-image'),
    );
    request.fields['mode'] = mode;
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: filename,
        contentType: _contentTypeFor(filename),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final decoded = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_messageFrom(decoded, 'Không thể phân tích ảnh'));
    }

    final data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    return data;
  }

  static MediaType _contentTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  static Future<String> sendAiCoachMessage({
    required String message,
    String? email,
  }) async {
    final userId = await currentUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('Vui lòng đăng nhập để sử dụng AI Coach');
    }

    final decoded = await _post(
      '/api/ai/chat',
      body: {'userId': userId, 'message': message},
    );

    if (decoded is Map<String, dynamic>) {
      return _value<String>(decoded, 'response') ??
          _value<String>(decoded, 'reply') ??
          'Mình có thể giúp gì thêm?';
    }
    return 'Mình có thể giúp gì thêm?';
  }

  static Future<List<Map<String, dynamic>>> getAiHistory() async {
    final userId = await currentUserId();
    if (userId == null || userId.isEmpty) return <Map<String, dynamic>>[];
    final decoded = await _get('/api/ai/history/$userId');
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  static Future<Map<String, dynamic>> getDashboardSummary(String email) async {
    final history = await getWorkoutHistory(email: email, limit: 100);
    final plans = await getWorkoutPlansByUser();
    return {'workoutCount': history.length, 'planCount': plans.length};
  }

  static Future<Map<String, dynamic>> getHomeSummary(String email) async {
    final userId = await currentUserId();
    if (userId == null || userId.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = await _get('/api/home/$userId', auth: true);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    final history = await getWorkoutHistory(email: email, limit: 120);
    final plans = await getWorkoutPlansByUser(userId);
    final customer = await getCustomerByUserId(userId);
    final exerciseMaps = await _exerciseDetailMaps();
    final todayPlan = _todaySessionFromPlans(plans, exerciseMaps);
    final nutrition = _nutritionFromCustomer(customer);
    final muscleProgress = _muscleProgressFromData(
      history: history,
      exerciseMaps: exerciseMaps,
    );

    return {
      'history': history,
      'plans': plans,
      'todayPlan': todayPlan,
      'nutrition': nutrition,
      'muscleProgress': muscleProgress,
      'streak': _calculateStreak(history),
      'workoutCount': _completedWorkoutCount(history),
    };
  }

  static int _completedWorkoutCount(List<Map<String, dynamic>> history) {
    return history.where((item) {
      final status = (_value<String>(item, 'status') ?? '').toUpperCase();
      return status == 'COMPLETED';
    }).length;
  }

  static int _calculateStreak(List<Map<String, dynamic>> history) {
    final completedDays = <DateTime>{};
    for (final item in history) {
      final status = (_value<String>(item, 'status') ?? '').toUpperCase();
      if (status != 'COMPLETED') continue;

      final rawDate =
          _value<String>(item, 'endTime') ?? _value<String>(item, 'startTime');
      final parsed = rawDate == null ? null : DateTime.tryParse(rawDate);
      if (parsed == null) continue;

      final local = parsed.toLocal();
      completedDays.add(DateTime(local.year, local.month, local.day));
    }

    var streak = 0;
    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);
    if (!completedDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (completedDays.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static Map<String, dynamic>? _todaySessionFromPlans(
    List<Map<String, dynamic>> plans,
    Map<String, dynamic> exerciseMaps,
  ) {
    final activePlans = plans.where((plan) {
      final isActive = _value<bool>(plan, 'isActive');
      return isActive ?? true;
    }).toList();

    final usablePlans = activePlans.isEmpty ? plans : activePlans;
    if (usablePlans.isEmpty) return null;

    final today = _todayName();
    final exerciseById =
        exerciseMaps['exerciseById'] as Map<String, Map<String, dynamic>>;
    final primaryMuscleByExerciseId =
        exerciseMaps['primaryMuscleByExerciseId'] as Map<String, String>;

    Map<String, dynamic>? selectedSession;
    for (final plan in usablePlans) {
      final sessions = _value<List>(plan, 'sessions') ?? const [];
      for (final rawSession in sessions.whereType<Map>()) {
        final session = Map<String, dynamic>.from(rawSession);
        final dayOfWeek = (_value<String>(session, 'dayOfWeek') ?? '').trim();
        if (_matchesToday(dayOfWeek, today)) {
          selectedSession = session;
          break;
        }
      }
      if (selectedSession != null) break;
    }

    if (selectedSession == null) {
      for (final plan in usablePlans) {
        final sessions = _value<List>(plan, 'sessions') ?? const [];
        if (sessions.length == 1 && sessions.first is Map) {
          final session = Map<String, dynamic>.from(sessions.first as Map);
          final dayOfWeek = (_value<String>(session, 'dayOfWeek') ?? '')
              .trim()
              .toLowerCase();
          if (dayOfWeek == 'today') {
            selectedSession = session;
            break;
          }
        }
      }
    }

    if (selectedSession == null) return null;

    final exercises = (_value<List>(selectedSession, 'exercises') ?? const [])
        .whereType<Map>()
        .map((item) {
          final row = Map<String, dynamic>.from(item);
          final exerciseId = _value<String>(row, 'exerciseId') ?? '';
          final catalog = exerciseById[exerciseId];
          return {
            'id': exerciseId,
            'name':
                _value<String>(row, 'exerciseName') ??
                _value<String>(catalog ?? {}, 'name') ??
                'Exercise',
            'muscle': primaryMuscleByExerciseId[exerciseId] ?? 'Unknown',
            'sets': _value<num>(row, 'sets')?.toString() ?? '3',
            'reps': _value<String>(row, 'reps') ?? '10',
            'notes': _value<String>(row, 'notes') ?? '',
          };
        })
        .toList();

    return {
      'day': _displayDay(_value<String>(selectedSession, 'dayOfWeek') ?? today),
      'focus': _value<String>(selectedSession, 'focus') ?? '',
      'exercises': exercises,
    };
  }

  static bool _matchesToday(String dayOfWeek, String today) {
    final normalized = dayOfWeek.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    if (normalized == 'today') return true;
    return normalized == today.toLowerCase() ||
        normalized == _englishDayToVietnamese(today).toLowerCase() ||
        normalized == _englishDayToVietnameseNoAccent(today).toLowerCase();
  }

  static String _todayName() {
    switch (DateTime.now().weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
      default:
        return 'Sunday';
    }
  }

  static String _englishDayToVietnamese(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return 'Thứ 2';
      case 'tuesday':
        return 'Thứ 3';
      case 'wednesday':
        return 'Thứ 4';
      case 'thursday':
        return 'Thứ 5';
      case 'friday':
        return 'Thứ 6';
      case 'saturday':
        return 'Thứ 7';
      case 'sunday':
      default:
        return 'Chủ nhật';
    }
  }

  static String _englishDayToVietnameseNoAccent(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return 'Thu 2';
      case 'tuesday':
        return 'Thu 3';
      case 'wednesday':
        return 'Thu 4';
      case 'thursday':
        return 'Thu 5';
      case 'friday':
        return 'Thu 6';
      case 'saturday':
        return 'Thu 7';
      case 'sunday':
      default:
        return 'Chu nhat';
    }
  }

  static String _displayDay(String day) {
    if (day.toLowerCase() == 'today') return 'Today';
    return '${_englishDayToVietnamese(day)} - $day';
  }

  static Future<Map<String, dynamic>> getSubscription() async {
    final userId = await currentUserId();
    if (userId == null) return {};
    try {
      final decoded = await _get('/api/Subscription/user/$userId', auth: true);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  static Map<String, dynamic> _nutritionFromCustomer(
    Map<String, dynamic>? customer,
  ) {
    if (customer == null) {
      return {'calories': '—', 'protein': '—', 'water': '—'};
    }

    // Using camelCase keys as requested
    final weight = (customer['weightKg'] ?? customer['WeightKg']) is num 
        ? (customer['weightKg'] ?? customer['WeightKg'] as num).toDouble() 
        : 0.0;
    final height = (customer['heightCm'] ?? customer['HeightCm']) is num 
        ? (customer['heightCm'] ?? customer['HeightCm'] as num).toDouble() 
        : 0.0;
    final age = (customer['age'] ?? customer['Age']) is num 
        ? (customer['age'] ?? customer['Age'] as num).toDouble() 
        : 0.0;
    final gender = (customer['gender'] ?? customer['Gender'] ?? '').toString().toLowerCase();
    final goal = (customer['goal'] ?? customer['Goal'] ?? '').toString().toLowerCase();

    if (weight <= 0 || height <= 0 || age <= 0) {
      return {
        'calories': '—',
        'protein': weight > 0 ? '${(weight * 1.8).round()}g' : '—',
        'water': weight > 0
            ? '${(weight * 35 / 1000).toStringAsFixed(1)}L'
            : '—',
      };
    }

    final bmr = gender.contains('nữ') || gender.contains('female')
        ? 10 * weight + 6.25 * height - 5 * age - 161
        : 10 * weight + 6.25 * height - 5 * age + 5;
    var calories = bmr * 1.45;
    if (goal.contains('giảm') || goal.contains('lose')) {
      calories -= 300;
    } else if (goal.contains('tăng cơ') ||
        goal.contains('strength') ||
        goal.contains('muscle')) {
      calories += 250;
    }

    return {
      'calories': '${calories.round()} kcal',
      'protein': '${(weight * 1.8).round()}g',
      'water': '${(weight * 35 / 1000).toStringAsFixed(1)}L',
    };
  }

  static List<Map<String, dynamic>> _muscleProgressFromData({
    required List<Map<String, dynamic>> history,
    required Map<String, dynamic> exerciseMaps,
  }) {
    final expByMuscle = <String, int>{};

    for (final log in history) {
      final gains = _value<List>(log, 'muscleExpGains') ?? const [];
      for (final rawGain in gains.whereType<Map>()) {
        final gain = Map<String, dynamic>.from(rawGain);
        final name = _value<String>(gain, 'muscleName');
        if (name == null || name.isEmpty) continue;
        expByMuscle[name] =
            (expByMuscle[name] ?? 0) +
            (_value<num>(gain, 'expGained')?.toInt() ?? 0);
      }
    }

    if (expByMuscle.isEmpty) {
      final primaryMuscleByExerciseId =
          exerciseMaps['primaryMuscleByExerciseId'] as Map<String, String>;
      final exerciseCounts = <String, int>{};
      for (final log in history) {
        final status = (_value<String>(log, 'status') ?? '').toUpperCase();
        if (status != 'COMPLETED') continue;

        final exercises = _value<List>(log, 'exercises') ?? const [];
        for (final rawExercise in exercises.whereType<Map>()) {
          final exercise = Map<String, dynamic>.from(rawExercise);
          final exerciseId = _value<String>(exercise, 'exerciseId');
          final muscle = exerciseId == null
              ? null
              : primaryMuscleByExerciseId[exerciseId];
          if (muscle == null || muscle == 'Unknown') continue;
          exerciseCounts[muscle] = (exerciseCounts[muscle] ?? 0) + 1;
        }
      }
      exerciseCounts.forEach((muscle, count) {
        expByMuscle[muscle] = count * 25;
      });
    }

    final items =
        expByMuscle.entries.map((entry) {
          final exp = entry.value;
          final level = (exp ~/ 100) + 1;
          final progressXp = exp % 100;
          return {
            'name': entry.key,
            'level': 'Lv $level',
            'progress': progressXp / 100,
            'xp': '$progressXp/100 XP',
          };
        }).toList()..sort((a, b) {
          final axp = int.tryParse(a['xp'].toString().split('/').first) ?? 0;
          final bxp = int.tryParse(b['xp'].toString().split('/').first) ?? 0;
          return bxp.compareTo(axp);
        });

    return items;
  }
}
