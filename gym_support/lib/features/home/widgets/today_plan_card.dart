import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class TodayPlanCard extends StatefulWidget {
  final VoidCallback onBuildRoutine;
  final VoidCallback onOpenWorkout;
  final Map<String, dynamic>? workout;
  final bool isLoading;

  const TodayPlanCard({
    super.key,
    required this.onBuildRoutine,
    required this.onOpenWorkout,
    this.workout,
    this.isLoading = false,
  });

  @override
  State<TodayPlanCard> createState() => _TodayPlanCardState();
}

class _TodayPlanCardState extends State<TodayPlanCard> {
  final PageController _pageController = PageController(viewportFraction: .88);
  Timer? _timer;
  int _page = 0;

  List<Map<String, dynamic>> get _exercises {
    final plans = widget.workout?['workoutPlan'];
    if (plans is! List || plans.isEmpty || plans.first is! Map) return const [];
    final day = Map<String, dynamic>.from(plans.first as Map);
    final raw = day['exercises'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic>? get _selectedDay {
    final plans = widget.workout?['workoutPlan'];
    if (plans is! List || plans.isEmpty || plans.first is! Map) return null;
    return Map<String, dynamic>.from(plans.first as Map);
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant TodayPlanCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workout != widget.workout) {
      _page = 0;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      final count = _exercises.length;
      if (!mounted || count < 2 || !_pageController.hasClients) return;
      final next = (_page + 1) % count;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return _loading();
    if (widget.workout == null || _selectedDay == null) return _empty();

    final day = _selectedDay!;
    final exercises = _exercises;
    if (exercises.isEmpty) return _empty();

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (day['day'] ?? 'Today').toString().toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        day['focus']?.toString() ?? 'Workout',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${exercises.length} bài',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _pageController,
              itemCount: exercises.length,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _ExerciseSlide(
                    exercise: exercises[index],
                    index: index,
                    total: exercises.length,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 13),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(exercises.length, (index) {
              final selected = index == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: selected ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.onOpenWorkout,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textDark,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'MỞ BUỔI TẬP HÔM NAY',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loading() {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _empty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          const Text(
            'Bạn chưa có lịch tập hôm nay.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: widget.onBuildRoutine,
            child: const Text('Tạo lịch tập'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseSlide extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final int index;
  final int total;

  const _ExerciseSlide({
    required this.exercise,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = exercise['imageUrl']?.toString() ?? '';
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF30363B),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(),
            )
          else
            _fallback(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xED111417)],
                stops: [.25, 1],
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .58),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${index + 1}/$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise['name']?.toString() ?? 'Exercise',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${exercise['sets'] ?? 3} sets × ${exercise['reps'] ?? '10'}  •  ${exercise['muscle'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFF30363B),
      padding: const EdgeInsets.all(22),
      alignment: Alignment.center,
      child: Text(
        exercise['name']?.toString() ?? 'Exercise',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white30,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
