import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/constants/app_images.dart';
import 'package:gym_support/core/constants/app_theme.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/models/workout_models.dart';
import 'package:gym_support/features/workout/screens/select_exercise_screen.dart';

class BuildRoutineScreen extends StatefulWidget {
  final String goal;
  final String schedule;
  final bool embedded;
  final Future<void> Function()? onRoutineSaved;

  const BuildRoutineScreen({
    super.key,
    required this.goal,
    required this.schedule,
    this.embedded = false,
    this.onRoutineSaved,
  });

  @override
  State<BuildRoutineScreen> createState() => _BuildRoutineScreenState();
}

class _BuildRoutineScreenState extends State<BuildRoutineScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  final _nameController = TextEditingController();
  final _goalController = TextEditingController();

  int _selectedDayIndex = 0;
  final List<WorkoutDayData> _dayDataList = [];
  bool _isSaving = false;

  static const _allChips = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  static const _chipToEnglish = {
    'T2': 'Monday', 'T3': 'Tuesday', 'T4': 'Wednesday',
    'T5': 'Thursday', 'T6': 'Friday', 'T7': 'Saturday', 'CN': 'Sunday',
  };
  final Set<String> _selectedChips = {'T2', 'T3', 'T4'};

  int get _daysPerWeek => _selectedChips.length;
  List<String> get _orderedSelectedChips =>
      _allChips.where((c) => _selectedChips.contains(c)).toList();

  static const _steps = ['Thông tin', 'Lịch tập', 'Bài tập', 'Xác nhận'];

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Lịch tập của tôi';
    _goalController.text = widget.goal;
    _rebuildDaysList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _rebuildDaysList() {
    final ordered = _orderedSelectedChips;
    final existing = <String, WorkoutDayData>{};
    for (final day in _dayDataList) {
      existing[day.chipLabel] = day;
    }
    _dayDataList.clear();
    for (int i = 0; i < ordered.length; i++) {
      final chip = ordered[i];
      final prev = existing[chip];
      _dayDataList.add(WorkoutDayData(
        dayNumber: i + 1,
        chipLabel: chip,
        weekday: _chipToEnglish[chip]!,
        dayName: prev?.dayName ?? 'Buổi tập ${i + 1}',
        exercises: prev?.exercises ?? [],
      ));
    }
    if (_selectedDayIndex >= _dayDataList.length) {
      _selectedDayIndex = _dayDataList.isEmpty ? 0 : _dayDataList.length - 1;
    }
  }

  void _toggleChip(String chip) {
    setState(() {
      if (_selectedChips.contains(chip)) {
        if (_selectedChips.length == 1) return;
        _selectedChips.remove(chip);
      } else {
        if (_selectedChips.length == 7) return;
        _selectedChips.add(chip);
      }
      _rebuildDaysList();
    });
  }

  Future<void> _addExercise(int dayIndex) async {
    final result = await Navigator.push<WorkoutExercise>(
      context,
      MaterialPageRoute(builder: (_) => const SelectExerciseScreen()),
    );
    if (result != null) setState(() => _dayDataList[dayIndex].exercises.add(result));
  }

  void _removeExercise(int dayIndex, int exIndex) {
    setState(() => _dayDataList[dayIndex].exercises.removeAt(exIndex));
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_nameController.text.trim().isEmpty) {
          _showError('Vui lòng nhập tên lịch tập');
          return false;
        }
        return true;
      case 1:
        return true;
      case 2:
        for (int i = 0; i < _dayDataList.length; i++) {
          if (_dayDataList[i].exercises.isEmpty) {
            setState(() {
              _selectedDayIndex = i;
            });
            _showError('Buổi ${i + 1} (${_dayDataList[i].chipLabel}) chưa có bài tập');
            return false;
          }
        }
        return true;
      default:
        return true;
    }
  }

  void _next() {
    if (!_validateStep(_currentStep)) return;
    if (_currentStep < 3) _goToStep(_currentStep + 1);
  }

  void _back() {
    if (_currentStep > 0) _goToStep(_currentStep - 1);
  }

  Future<void> _saveRoutine() async {
    setState(() => _isSaving = true);
    try {
      final userId = await BackendApi.currentUserId();
      if (userId == null || userId.isEmpty) throw Exception('Vui lòng đăng nhập');
      final payload = {
        'userId': userId,
        'name': _nameController.text.trim(),
        'goal': _goalController.text.trim(),
        'daysPerWeek': _daysPerWeek,
        'sessions': _dayDataList.map((day) => {
          'dayOfWeek': day.weekday,
          'focus': day.dayName,
          'exercises': day.exercises.map((ex) => {
            'exerciseId': ex.exerciseId,
            'exerciseName': ex.exerciseName,
            'sets': ex.sets,
            'reps': ex.reps,
            'notes': ex.note,
          }).toList(),
        }).toList(),
      };
      await BackendApi.createRoutineWithSessions(payload);
      if (!mounted) return;
      if (widget.onRoutineSaved != null) {
        await widget.onRoutineSaved!();
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Lỗi lưu lịch tập: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        _buildStepHeader(),
        _buildProgressBar(),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StepInfo(nameCtrl: _nameController, goalCtrl: _goalController),
              _StepSchedule(
                allChips: _allChips,
                selectedChips: _selectedChips,
                onToggle: _toggleChip,
                daysPerWeek: _daysPerWeek,
              ),
              _StepExercises(
                dayDataList: _dayDataList,
                selectedDayIndex: _selectedDayIndex,
                onSelectDay: (i) => setState(() => _selectedDayIndex = i),
                onAddExercise: _addExercise,
                onRemoveExercise: _removeExercise,
              ),
              _StepConfirm(
                name: _nameController.text,
                goal: _goalController.text,
                dayDataList: _dayDataList,
              ),
            ],
          ),
        ),
        _buildBottomNav(),
      ],
    );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: body),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Column(
        children: [
          _buildAppBar(),
          Expanded(child: body),
        ],
      )),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: _currentStep == 0
                ? () => Navigator.pop(context)
                : _back,
            icon: const Icon(PhosphorIconsBold.caretLeft,
                color: AppColors.textSecondary, size: 20),
          ),
          const Expanded(
            child: Text(
              'Xây dựng lịch tập',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: List.generate(_steps.length, (i) {
          final done = i < _currentStep;
          final active = i == _currentStep;
          return Expanded(
            child: GestureDetector(
              onTap: i < _currentStep ? () => _goToStep(i) : null,
              child: Column(
                children: [
                  Row(
                    children: [
                      if (i > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: i <= _currentStep
                                ? AppColors.primary
                                : AppColors.outline,
                          ),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: active || done ? AppTheme.cyanGradient : null,
                          color: active || done ? null : AppColors.surface2,
                          border: Border.all(
                            color: active || done ? AppColors.primary : AppColors.outline,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: done
                              ? const Icon(PhosphorIconsBold.check,
                                  color: AppColors.textDark, size: 14)
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: active
                                        ? AppColors.textDark
                                        : AppColors.textTertiary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                      if (i < _steps.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: i < _currentStep
                                ? AppColors.primary
                                : AppColors.outline,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _steps[i],
                    style: TextStyle(
                      color: active ? AppColors.primary : AppColors.textTertiary,
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: LinearProgressIndicator(
          value: (_currentStep + 1) / _steps.length,
          backgroundColor: AppColors.surface2,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 4,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final isLast = _currentStep == 3;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _back,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.outline),
                    foregroundColor: AppColors.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  child: const Text(
                    'Quay lại',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _isSaving ? null : AppTheme.cyanGradient,
                  color: _isSaving ? AppColors.surface2 : null,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : (isLast ? _saveRoutine : _next),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    foregroundColor: AppColors.textDark,
                    disabledForegroundColor: AppColors.textSecondary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: AppColors.textSecondary, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLast ? 'Lưu lịch tập' : 'Tiếp theo',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              isLast
                                  ? PhosphorIconsBold.check
                                  : PhosphorIconsBold.arrowRight,
                              size: 18,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Thông tin ─────────────────────────────────────────────────────────

class _StepInfo extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController goalCtrl;
  const _StepInfo({required this.nameCtrl, required this.goalCtrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 110,
                  child: CachedNetworkImage(
                    imageUrl: AppImages.workoutBanner,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    placeholder: (_, __) => Container(color: AppColors.surface2),
                    errorWidget: (_, __, ___) => Image.asset(AppImages.workoutBannerLocal, fit: BoxFit.cover),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 110,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xEE003D4D), Color(0xAA001820)],
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Bước 1', style: TextStyle(
                          color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text('Thông tin lịch tập', style: TextStyle(
                          color: AppColors.textPrimary, fontSize: 20,
                          fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        SizedBox(height: 2),
                        Text('Đặt tên và mục tiêu cho lịch tập', style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _FieldCard(
            label: 'Tên lịch tập',
            hint: 'VD: Lịch tập Gym 3 buổi/tuần',
            icon: PhosphorIconsBold.pencilSimple,
            iconColor: AppColors.primary,
            controller: nameCtrl,
          ),
          const SizedBox(height: 16),
          _FieldCard(
            label: 'Mục tiêu',
            hint: 'VD: Tăng sức mạnh, Giảm mỡ...',
            icon: PhosphorIconsBold.flag,
            iconColor: AppColors.orange,
            controller: goalCtrl,
          ),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final TextEditingController controller;
  const _FieldCard({
    required this.label, required this.hint,
    required this.icon, required this.iconColor,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          color: AppColors.textSecondary, fontSize: 12,
          fontWeight: FontWeight.w700, letterSpacing: 0.3,
        )),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.outlineStrong),
          ),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Step 2: Lịch tập ──────────────────────────────────────────────────────────

class _StepSchedule extends StatelessWidget {
  final List<String> allChips;
  final Set<String> selectedChips;
  final void Function(String) onToggle;
  final int daysPerWeek;

  const _StepSchedule({
    required this.allChips, required this.selectedChips,
    required this.onToggle, required this.daysPerWeek,
  });

  static const _dayNames = {
    'T2': 'Thứ 2', 'T3': 'Thứ 3', 'T4': 'Thứ 4',
    'T5': 'Thứ 5', 'T6': 'Thứ 6', 'T7': 'Thứ 7', 'CN': 'Chủ nhật',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(PhosphorIconsBold.calendarBlank,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bước 2 — Lịch tập', style: TextStyle(
                      color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    const Text('Chọn ngày tập trong tuần', style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 16,
                      fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Count badge
          Row(
            children: [
              const Text('Số buổi đã chọn', style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.cyanGradient,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  '$daysPerWeek buổi/tuần',
                  style: const TextStyle(
                    color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Day buttons — 2 columns grid
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: allChips.map((chip) {
              final selected = selectedChips.contains(chip);
              return GestureDetector(
                onTap: () => onToggle(chip),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    gradient: selected ? AppTheme.cyanGradient : null,
                    color: selected ? null : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.outlineStrong,
                      width: selected ? 1.5 : 1,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.22),
                            blurRadius: 10,
                          )]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (selected)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(PhosphorIconsBold.checkCircle,
                              color: AppColors.textDark, size: 16),
                        ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            chip,
                            style: TextStyle(
                              color: selected ? AppColors.textDark : AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          Text(
                            _dayNames[chip] ?? chip,
                            style: TextStyle(
                              color: selected
                                  ? AppColors.textDark.withValues(alpha: 0.7)
                                  : AppColors.textTertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Chạm để chọn/bỏ chọn ngày tập',
              style: const TextStyle(
                color: AppColors.textTertiary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Bài tập ───────────────────────────────────────────────────────────

class _StepExercises extends StatelessWidget {
  final List<WorkoutDayData> dayDataList;
  final int selectedDayIndex;
  final void Function(int) onSelectDay;
  final Future<void> Function(int) onAddExercise;
  final void Function(int, int) onRemoveExercise;

  const _StepExercises({
    required this.dayDataList, required this.selectedDayIndex,
    required this.onSelectDay, required this.onAddExercise,
    required this.onRemoveExercise,
  });

  @override
  Widget build(BuildContext context) {
    if (dayDataList.isEmpty) {
      return const Center(child: Text('Chưa chọn ngày tập',
          style: TextStyle(color: AppColors.textSecondary)));
    }

    final day = dayDataList[selectedDayIndex];

    return Column(
      children: [
        // Step label + day tabs
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Bước 3 — ', style: TextStyle(
                    color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800)),
                  const Text('Thêm bài tập', style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  // Completion status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _allDone
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.surface2,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      _allDone ? '✓ Hoàn thành' : '$_doneDays/${dayDataList.length} buổi',
                      style: TextStyle(
                        color: _allDone ? AppColors.success : AppColors.textTertiary,
                        fontSize: 11, fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Day tabs
              SizedBox(
                height: 66,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: dayDataList.length,
                  separatorBuilder: (context2, idx) => const SizedBox(width: 8),
                  itemBuilder: (context2, i) {
                    final d = dayDataList[i];
                    final sel = i == selectedDayIndex;
                    final hasMissing = d.exercises.isEmpty;
                    return GestureDetector(
                      onTap: () => onSelectDay(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 68,
                        decoration: BoxDecoration(
                          gradient: sel ? AppTheme.heroGradient : null,
                          color: sel ? null : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(
                            color: sel
                                ? AppColors.primary.withValues(alpha: 0.5)
                                : hasMissing
                                    ? AppColors.danger.withValues(alpha: 0.3)
                                    : AppColors.outline,
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(d.chipLabel, style: TextStyle(
                              color: sel ? AppColors.primary : AppColors.textSecondary,
                              fontSize: 15, fontWeight: FontWeight.w900, height: 1,
                            )),
                            const SizedBox(height: 2),
                            if (d.exercises.isEmpty)
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.danger, shape: BoxShape.circle),
                              )
                            else
                              Text('${d.exercises.length} bài', style: TextStyle(
                                color: sel ? AppColors.success : AppColors.success,
                                fontSize: 9, fontWeight: FontWeight.w700,
                              )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Day card
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(
              key: ValueKey(selectedDayIndex),
              child: _DayExerciseCard(
                day: day,
                dayIndex: selectedDayIndex,
                onAdd: onAddExercise,
                onRemove: onRemoveExercise,
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool get _allDone => dayDataList.every((d) => d.exercises.isNotEmpty);
  int get _doneDays => dayDataList.where((d) => d.exercises.isNotEmpty).length;
}

class _DayExerciseCard extends StatelessWidget {
  final WorkoutDayData day;
  final int dayIndex;
  final Future<void> Function(int) onAdd;
  final void Function(int, int) onRemove;
  const _DayExerciseCard({
    required this.day, required this.dayIndex,
    required this.onAdd, required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          children: [
            // Card header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusLg)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Center(child: Text(day.chipLabel, style: const TextStyle(
                      color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w900,
                    ))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(day.dayName, style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14,
                          fontWeight: FontWeight.w800, height: 1,
                        )),
                        const SizedBox(height: 2),
                        Text(
                          day.exercises.isEmpty
                              ? 'Chưa có bài tập'
                              : '${day.exercises.length} bài tập đã thêm',
                          style: TextStyle(
                            color: day.exercises.isEmpty
                                ? AppColors.danger
                                : AppColors.success,
                            fontSize: 11, fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onAdd(dayIndex),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.cyanGradient,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Row(
                        children: [
                          Icon(PhosphorIconsBold.plus, color: AppColors.textDark, size: 15),
                          SizedBox(width: 4),
                          Text('Thêm', style: TextStyle(
                            color: AppColors.textDark, fontSize: 12,
                            fontWeight: FontWeight.w900,
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Exercise list
            Expanded(
              child: day.exercises.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.danger.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(PhosphorIconsBold.barbell,
                                color: AppColors.danger, size: 22),
                          ),
                          const SizedBox(height: 10),
                          const Text('Chưa có bài tập', style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13,
                            fontWeight: FontWeight.w700,
                          )),
                          const SizedBox(height: 4),
                          const Text('Nhấn "Thêm" để bổ sung', style: TextStyle(
                            color: AppColors.textTertiary, fontSize: 11)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: day.exercises.length,
                      separatorBuilder: (context2, idx) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context2, i) {
                        final ex = day.exercises[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(child: Text('${i + 1}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13, fontWeight: FontWeight.w900,
                                  ),
                                )),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ex.exerciseName, maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary, fontSize: 13,
                                        fontWeight: FontWeight.w700, height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _Badge('${ex.sets} sets', AppColors.primary),
                                        const SizedBox(width: 6),
                                        _Badge('${ex.reps} reps', AppColors.orange),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => onRemove(dayIndex, i),
                                icon: const Icon(PhosphorIconsBold.minusCircle,
                                    size: 20, color: AppColors.danger),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 34, minHeight: 34),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 4: Xác nhận ──────────────────────────────────────────────────────────

class _StepConfirm extends StatelessWidget {
  final String name;
  final String goal;
  final List<WorkoutDayData> dayDataList;
  const _StepConfirm({required this.name, required this.goal,
      required this.dayDataList});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: AppTheme.cyanGradient,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16, spreadRadius: 2,
                    )],
                  ),
                  child: const Icon(PhosphorIconsBold.check,
                      color: AppColors.textDark, size: 28),
                ),
                const SizedBox(height: 14),
                const Text('Sẵn sàng lưu!', style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 20,
                  fontWeight: FontWeight.w900, letterSpacing: -0.5,
                )),
                const SizedBox(height: 4),
                const Text('Xem lại chi tiết lịch tập bên dưới',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Info summary
          _SummaryRow(icon: PhosphorIconsBold.pencilSimple, color: AppColors.primary,
              label: 'Tên lịch tập', value: name.isEmpty ? '—' : name),
          const SizedBox(height: 10),
          _SummaryRow(icon: PhosphorIconsBold.flag, color: AppColors.orange,
              label: 'Mục tiêu', value: goal.isEmpty ? '—' : goal),
          const SizedBox(height: 10),
          _SummaryRow(icon: PhosphorIconsBold.calendarBlank, color: AppColors.blue,
              label: 'Tổng buổi tập',
              value: '${dayDataList.length} buổi/tuần'),
          const SizedBox(height: 20),
          const Text('CHI TIẾT CÁC BUỔI TẬP', style: TextStyle(
            color: AppColors.textTertiary, fontSize: 11,
            fontWeight: FontWeight.w800, letterSpacing: 1.2,
          )),
          const SizedBox(height: 12),
          ...dayDataList.map((day) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(child: Text(day.chipLabel, style: const TextStyle(
                      color: AppColors.primary, fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(day.dayName, style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13,
                          fontWeight: FontWeight.w800,
                        )),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6, runSpacing: 4,
                          children: day.exercises.map((ex) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: Text(
                              '${ex.exerciseName} · ${ex.sets}×${ex.reps}',
                              style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _SummaryRow({required this.icon, required this.color,
      required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(
                color: AppColors.textTertiary, fontSize: 10,
                fontWeight: FontWeight.w700, letterSpacing: 0.3,
              )),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 14,
                fontWeight: FontWeight.w800,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(label, style: TextStyle(
        color: color, fontSize: 10, fontWeight: FontWeight.w800,
      )),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class WorkoutDayData {
  final int dayNumber;
  final String chipLabel;
  final String weekday;
  String dayName;
  final List<WorkoutExercise> exercises;

  WorkoutDayData({
    required this.dayNumber,
    required this.chipLabel,
    required this.weekday,
    required this.dayName,
    List<WorkoutExercise>? exercises,
  }) : exercises = exercises ?? [];
}
