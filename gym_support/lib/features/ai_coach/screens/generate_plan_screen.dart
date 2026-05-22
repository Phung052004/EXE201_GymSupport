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
                child: SingleChildScrollView(
                  child: Text(_prettyJson(_result!)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _prettyJson(Map<String, dynamic> json) {
    try {
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (_) {
      return json.toString();
    }
  }
}
