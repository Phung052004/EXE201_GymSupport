import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gym_support/core/services/backend_api.dart';

class GeneratePlanScreen extends StatefulWidget {
  final String email;
  final String name;
  final String gender;
  final String age;
  final String weight;
  final String height;
  final String goal;

  const GeneratePlanScreen({
    super.key,
    required this.email,
    required this.name,
    required this.gender,
    required this.age,
    required this.weight,
    required this.height,
    required this.goal,
  });

  @override
  State<GeneratePlanScreen> createState() => _GeneratePlanScreenState();
}

class _GeneratePlanScreenState extends State<GeneratePlanScreen> {
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;
  int _daysPerWeek = 4;
  bool _applying = false;

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final res = await BackendApi.generatePlan(
        name: widget.name,
        gender: widget.gender,
        age: widget.age,
        weight: widget.weight,
        height: widget.height,
        goal: widget.goal,
        daysPerWeek: _daysPerWeek,
        email: widget.email,
      );

      setState(() => _result = res['data'] ?? res);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _applyPlan() async {
    setState(() {
      _applying = true;
      _error = null;
    });

    try {
      final reply = await BackendApi.sendAiCoachMessage(
        message:
            'Đồng ý. Hãy tạo và lưu lịch tập vừa đề xuất vào hệ thống cho tôi.',
      );
      setState(() {
        _result = {'aiResponse': reply};
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Workout Plan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('Days/week:'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _daysPerWeek,
                  items: [3, 4, 5, 6, 7]
                      .map((d) => DropdownMenuItem(value: d, child: Text('$d')))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _daysPerWeek = v);
                  },
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _loading ? null : _generate,
                  child: Text(_loading ? 'Generating...' : 'Generate Plan'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            if (_result != null)
              Expanded(
                child: ListView(
                  children: [
                    ..._buildPlanWidgets(_result!),
                    if ((_result?['aiResponse'] ?? '').toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ElevatedButton(
                          onPressed: _applying ? null : _applyPlan,
                          child: Text(
                            _applying ? 'Đang lưu...' : 'Lưu lịch này',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlanWidgets(Map<String, dynamic> result) {
    final widgets = <Widget>[];

    final aiResponse = result['aiResponse']?.toString();
    if (aiResponse != null && aiResponse.isNotEmpty) {
      widgets.add(_sectionTitle('AI Coach'));
      widgets.add(
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Text(
            aiResponse,
            style: const TextStyle(fontSize: 13, height: 1.45),
          ),
        ),
      );
      return widgets;
    }

    final nutrition = result['nutrition'];
    if (nutrition is Map<String, dynamic>) {
      widgets.add(_sectionTitle('Nutrition'));
      widgets.add(_keyValueTable(_nutritionRows(nutrition)));
      widgets.add(const SizedBox(height: 16));
    }

    final workoutPlan = result['workoutPlan'];
    if (workoutPlan is List && workoutPlan.isNotEmpty) {
      widgets.add(_sectionTitle('Workout Plan'));
      for (var i = 0; i < workoutPlan.length; i += 1) {
        final day = workoutPlan[i];
        if (day is Map<String, dynamic>) {
          widgets.add(_dayCard(day, i + 1));
        }
      }
    }

    if (widgets.isEmpty) {
      widgets.add(
        Text(_prettyJson(result), style: const TextStyle(fontSize: 12)),
      );
    }

    return widgets;
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }

  List<MapEntry<String, String>> _nutritionRows(
    Map<String, dynamic> nutrition,
  ) {
    final rows = <MapEntry<String, String>>[];
    void addRow(String key, dynamic value) {
      if (value == null) return;
      rows.add(MapEntry(key, value.toString()));
    }

    addRow('Calories', nutrition['calories'] ?? nutrition['targetCalories']);
    addRow('Protein', nutrition['protein']);
    addRow('Carbs', nutrition['carbs']);
    addRow('Fat', nutrition['fat']);
    addRow('Notes', nutrition['notes']);

    if (rows.isEmpty) {
      nutrition.forEach((key, value) {
        rows.add(MapEntry(key, value.toString()));
      });
    }

    return rows;
  }

  Widget _dayCard(Map<String, dynamic> day, int index) {
    final dayTitle =
        day['day']?.toString() ?? day['title']?.toString() ?? 'Day $index';
    final focus = day['focus']?.toString() ?? day['muscleGroup']?.toString();
    final exercises = day['exercises'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayTitle,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          if (focus != null) ...[
            const SizedBox(height: 4),
            Text(
              focus,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (exercises is List && exercises.isNotEmpty)
            _exerciseTable(exercises)
          else
            Text(
              'No exercises found',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
            ),
        ],
      ),
    );
  }

  Widget _keyValueTable(List<MapEntry<String, String>> rows) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.key,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        row.value,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _exerciseTable(List exercises) {
    final rows = <Widget>[];

    rows.add(
      Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Exercise',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Sets/Reps',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );

    for (final item in exercises) {
      if (item is! Map<String, dynamic>) continue;
      final name = item['name']?.toString() ?? '-';
      final sets =
          item['setsAndReps']?.toString() ?? item['sets']?.toString() ?? '-';

      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(name, style: const TextStyle(fontSize: 13)),
              ),
              Expanded(
                child: Text(
                  sets,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  String _prettyJson(Map<String, dynamic> json) {
    try {
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (_) {
      return json.toString();
    }
  }
}
