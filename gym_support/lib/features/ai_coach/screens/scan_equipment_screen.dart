import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/services/backend_api.dart';

class ScanEquipmentScreen extends StatefulWidget {
  final String? email;
  const ScanEquipmentScreen({super.key, this.email});

  @override
  State<ScanEquipmentScreen> createState() => _ScanEquipmentScreenState();
}

class _ScanEquipmentScreenState extends State<ScanEquipmentScreen> {
  bool _loading = false;
  List<dynamic>? _detections;
  Map<String, dynamic>? _enriched;
  String? _error;
  XFile? _picked;

  Future<void> _pickAndUpload(ImageSource src) async {
    setState(() {
      _loading = true;
      _error = null;
      _detections = null;
      _enriched = null;
    });

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: src,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (file == null) return;
      _picked = file;
      final bytes = await file.readAsBytes();
      final res = await BackendApi.uploadScanImage(
        bytes: bytes,
        filename: file.name,
        email: widget.email,
      );
      setState(() {
        _detections = res['detections'] as List<dynamic>? ?? [];
        _enriched = res['enriched'] as Map<String, dynamic>?;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan Equipment'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_picked != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(_picked!.path),
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading
                        ? null
                        : () => _pickAndUpload(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading
                        ? null
                        : () => _pickAndUpload(ImageSource.gallery),
                    icon: const Icon(Icons.photo),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            if (_error != null)
              Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.redAccent),
              ),
            if (_enriched != null)
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Hướng dẫn sử dụng',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nhóm cơ: ${_enriched?['targetMuscle'] ?? '--'}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Độ khó: ${_enriched?['difficulty'] ?? '--'}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Cách sử dụng:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ..._buildInstructionLines(_enriched?['instructions']),
                    if ((_enriched?['commonMistakes'] ?? '')
                        .toString()
                        .isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'Lỗi thường gặp: ${_enriched?['commonMistakes']}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(_buildChatSummaryMessage());
                        },
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Gửi vào chat AI'),
                      ),
                    ),
                  ],
                ),
              ),
            if (_detections != null)
              Expanded(
                child: ListView.builder(
                  itemCount: _detections!.length,
                  itemBuilder: (ctx, i) {
                    final d = _detections![i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.fitness_center,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d['name']?.toString() ?? 'Unknown',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Confidence: ${d['confidence'] ?? ''}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
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

  List<Widget> _buildInstructionLines(dynamic instructions) {
    if (instructions is List) {
      return instructions
          .whereType<dynamic>()
          .map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• ${step.toString()}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
            ),
          )
          .toList();
    }

    if (instructions != null && instructions.toString().isNotEmpty) {
      return [
        Text(
          instructions.toString(),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
      ];
    }

    return [
      Text(
        'Chưa có hướng dẫn cụ thể.',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
      ),
    ];
  }

  String _buildChatSummaryMessage() {
    final buffer = StringBuffer();
    final equipmentName = _detections?.isNotEmpty == true
        ? _detections!.first['name']?.toString()
        : 'Thiết bị không xác định';

    buffer.writeln('Kết quả scan: $equipmentName');
    buffer.writeln('Nhóm cơ: ${_enriched?['targetMuscle'] ?? '--'}');
    buffer.writeln('Độ khó: ${_enriched?['difficulty'] ?? '--'}');
    buffer.writeln('Cách sử dụng:');

    final instructions = _enriched?['instructions'];
    if (instructions is List && instructions.isNotEmpty) {
      for (final step in instructions) {
        buffer.writeln('- ${step.toString()}');
      }
    } else if (instructions != null && instructions.toString().isNotEmpty) {
      buffer.writeln('- ${instructions.toString()}');
    } else {
      buffer.writeln('- Chưa có hướng dẫn cụ thể.');
    }

    final mistakes = _enriched?['commonMistakes']?.toString() ?? '';
    if (mistakes.isNotEmpty) {
      buffer.writeln('Lỗi thường gặp: $mistakes');
    }

    return buffer.toString().trim();
  }
}
