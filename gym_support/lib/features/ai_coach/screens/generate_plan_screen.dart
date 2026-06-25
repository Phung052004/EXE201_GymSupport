import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/backend_api.dart';
import '../../../core/services/session_store.dart';

class GeneratePlanScreen extends StatefulWidget {
  final String email;
  final String name;
  final String gender;
  final String age;
  final String weight;
  final String height;
  final String goal;
  final bool embedded;

  const GeneratePlanScreen({
    super.key,
    this.email = '',
    this.name = '',
    this.gender = '',
    this.age = '',
    this.weight = '',
    this.height = '',
    this.goal = '',
    this.embedded = false,
  });

  @override
  State<GeneratePlanScreen> createState() => _GeneratePlanScreenState();
}

class _GeneratePlanScreenState extends State<GeneratePlanScreen> {
  final TextEditingController _healthController = TextEditingController();
  late Future<Map<String, dynamic>?> _profileFuture;

  String _goal = 'AI Decide';
  String _experience = 'AI Decide';
  int? _daysPerWeek;
  final Set<String> _trainingDays = {};
  String _intensity = 'AI Decide';
  String _condition = 'AI Decide';

  bool _loading = false;
  bool _applying = false;
  String? _error;
  Map<String, dynamic>? _result;
  List<Map<String, dynamic>> _suggestions = const [];

  static const _aiDecide = 'AI Decide';
  static const _goals = [
    _aiDecide,
    'Tăng cơ',
    'Giảm mỡ',
    'Tăng sức mạnh',
    'Duy trì sức khỏe',
    'Cải thiện sức bền',
  ];
  static const _experiences = [
    _aiDecide,
    'Mới bắt đầu',
    'Đã tập dưới 1 năm',
    'Trung cấp',
    'Nâng cao',
  ];
  static const _intensities = [
    _aiDecide,
    'Nhẹ',
    'Vừa',
    'Cao',
    'Rất cao',
  ];
  static const _conditions = [
    _aiDecide,
    'Tập tại gym đầy đủ máy',
    'Tập tại nhà với tạ đơn',
    'Tập tại nhà không dụng cụ',
    'Ít thời gian, buổi tập ngắn',
  ];
  static const _days = {
    'Monday': 'Thứ 2',
    'Tuesday': 'Thứ 3',
    'Wednesday': 'Thứ 4',
    'Thursday': 'Thứ 5',
    'Friday': 'Thứ 6',
    'Saturday': 'Thứ 7',
    'Sunday': 'CN',
  };

  @override
  void initState() {
    super.initState();
    _goal = widget.goal.trim().isEmpty ? _aiDecide : widget.goal.trim();
    _profileFuture = _loadProfile();
  }

  @override
  void dispose() {
    _healthController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    final email = await _currentEmail();
    if (email.isEmpty) {
      return {
        'name': widget.name,
        'gender': widget.gender,
        'age': widget.age,
        'weight': widget.weight,
        'height': widget.height,
        'goal': widget.goal,
      };
    }

    final profile = await BackendApi.getOnboardingProfileByEmail(email);
    if (profile != null) {
      final profileGoal = profile['goal']?.toString() ?? '';
      final profileExperience = profile['experienceLevel']?.toString() ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          if (profileGoal.isNotEmpty) _goal = profileGoal;
          if (profileExperience.isNotEmpty) _experience = profileExperience;
        });
      });
    }
    return profile;
  }

  Future<String> _currentEmail() async {
    if (widget.email.trim().isNotEmpty) return widget.email.trim();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(SessionStore.emailKey) ?? '';
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _suggestions = const [];
    });

    try {
      final res = await BackendApi.generatePlan(
        goal: _goal == _aiDecide ? '' : _goal,
        experienceLevel: _experience == _aiDecide ? '' : _experience,
        daysPerWeek: _daysPerWeek,
        trainingDays: _trainingDays.toList(),
        intensity: _intensity == _aiDecide ? '' : _intensity,
        trainingCondition: _condition == _aiDecide ? '' : _condition,
        healthIssues: _healthController.text.trim(),
      );

      final rawSuggestions = res['suggestions'];
      final suggestions = rawSuggestions is List
          ? rawSuggestions
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _result = res;
        _suggestions = suggestions;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _applyPlan() async {
    if (_suggestions.isEmpty) return;
    setState(() {
      _applying = true;
      _error = null;
    });

    try {
      await BackendApi.applyAiSuggestions({'suggestions': _suggestions});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu lịch tập AI vào hệ thống')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error =
            'Không thể lưu lịch trực tiếp. Tài khoản cần Premium hoặc backend đang từ chối lưu.\n$error',
      );
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = ListView(
        padding: EdgeInsets.fromLTRB(
          22,
          widget.embedded ? 10 : 20,
          22,
          26,
        ),
        children: [
          if (!widget.embedded) ...[
            _header(),
            const SizedBox(height: 18),
          ],
          FutureBuilder<Map<String, dynamic>?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              return _profileCard(snapshot.data, snapshot.connectionState);
            },
          ),
          const SizedBox(height: 18),
          _stepTitle('1', 'Mục tiêu tập luyện'),
          _choiceWrap(_goals, _goal, (value) => setState(() => _goal = value)),
          _stepTitle('2', 'Kinh nghiệm tập luyện'),
          _choiceWrap(
            _experiences,
            _experience,
            (value) => setState(() => _experience = value),
          ),
          _stepTitle('3', 'Số buổi trong tuần'),
          _daysPerWeekSelector(),
          _stepTitle('4', 'Thứ mấy'),
          _trainingDaySelector(),
          _stepTitle('5', 'Mức độ tập'),
          _choiceWrap(
            _intensities,
            _intensity,
            (value) => setState(() => _intensity = value),
          ),
          _stepTitle('6', 'Điều kiện tập luyện'),
          _choiceWrap(
            _conditions,
            _condition,
            (value) => setState(() => _condition = value),
          ),
          _stepTitle('7', 'Vấn đề sức khỏe'),
          _healthField(),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loading ? null : _generate,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(PhosphorIconsBold.sparkle),
            label: Text(_loading ? 'Đang tạo lịch...' : 'Tạo lịch tập'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textDark,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            _errorBox(_error!),
          ],
          if (_result != null) ...[
            const SizedBox(height: 18),
            _resultCard(),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _suggestions.isEmpty || _applying ? null : _applyPlan,
              icon: const Icon(PhosphorIconsBold.floppyDisk),
              label: Text(_applying ? 'Đang lưu...' : 'Lưu lịch này'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceSelected,
                foregroundColor: AppColors.textDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ],
    );
    return widget.embedded ? content : SafeArea(child: content);
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            PhosphorIconsBold.notepad,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Workout Plan',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Chọn thông tin, AI tự lên lịch tập',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileCard(
    Map<String, dynamic>? profile,
    ConnectionState connectionState,
  ) {
    final loading = connectionState == ConnectionState.waiting;
    final name = profile?['name']?.toString() ?? widget.name;
    final weight = profile?['weight']?.toString() ?? widget.weight;
    final height = profile?['height']?.toString() ?? widget.height;
    final bmi = profile?['bmi']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsBold.magnifyingGlass, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loading ? 'Đang tải hồ sơ...' : (name.isEmpty ? 'Hồ sơ của bạn' : name),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _metric('Cân nặng', weight.isEmpty ? '--' : '$weight kg')),
              const SizedBox(width: 10),
              Expanded(child: _metric('Chiều cao', height.isEmpty ? '--' : '$height cm')),
              const SizedBox(width: 10),
              Expanded(child: _metric('BMI', bmi.isEmpty ? '--' : bmi)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepTitle(String step, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: AppColors.primary,
            child: Text(
              step,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceWrap(
    List<String> options,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final active = option == selected;
        return ChoiceChip(
          label: Text(option),
          selected: active,
          onSelected: (_) => onSelected(option),
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          labelStyle: TextStyle(
            color: active ? AppColors.textDark : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
          side: BorderSide(
            color: active ? AppColors.primary : AppColors.outline,
          ),
        );
      }).toList(),
    );
  }

  Widget _daysPerWeekSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _smallChip(_aiDecide, _daysPerWeek == null, () {
          setState(() {
            _daysPerWeek = null;
            _trainingDays.clear();
          });
        }),
        for (final dayCount in [2, 3, 4, 5, 6])
          _smallChip('$dayCount buổi', _daysPerWeek == dayCount, () {
            setState(() {
              _daysPerWeek = dayCount;
              if (_trainingDays.length > dayCount) {
                final keep = _trainingDays.take(dayCount).toSet();
                _trainingDays
                  ..clear()
                  ..addAll(keep);
              }
            });
          }),
      ],
    );
  }

  Widget _trainingDaySelector() {
    final aiSelected = _trainingDays.isEmpty;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _smallChip(_aiDecide, aiSelected, () {
          setState(() => _trainingDays.clear());
        }),
        ..._days.entries.map((entry) {
          final active = _trainingDays.contains(entry.key);
          return _smallChip(entry.value, active, () {
            setState(() {
              if (active) {
                _trainingDays.remove(entry.key);
              } else {
                final maxDays = _daysPerWeek;
                if (maxDays != null && _trainingDays.length >= maxDays) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Chỉ chọn tối đa $maxDays buổi')),
                  );
                  return;
                }
                _trainingDays.add(entry.key);
              }
            });
          });
        }),
      ],
    );
  }

  Widget _smallChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: selected ? AppColors.textDark : AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.outline),
    );
  }

  Widget _healthField() {
    return TextField(
      controller: _healthController,
      maxLines: 3,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: 'Ví dụ: đau lưng dưới, chấn thương gối, huyết áp cao...',
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _resultCard() {
    final response =
        _result?['response']?.toString() ??
        _result?['aiResponse']?.toString() ??
        '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lịch AI đề xuất',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            response.isEmpty ? 'AI đã tạo dữ liệu lịch tập.' : response,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_suggestions.length} thao tác sẵn sàng để lưu',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
