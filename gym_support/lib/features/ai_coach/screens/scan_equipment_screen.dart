import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/services/backend_api.dart';

class ScanEquipmentScreen extends StatefulWidget {
  final String? email;
  final String initialMode;

  const ScanEquipmentScreen({
    super.key,
    this.email,
    this.initialMode = 'equipment_info',
  });

  @override
  State<ScanEquipmentScreen> createState() => _ScanEquipmentScreenState();
}

class _ScanEquipmentScreenState extends State<ScanEquipmentScreen> {
  bool _loading = false;
  List<dynamic>? _detections;
  Map<String, dynamic>? _enriched;
  String? _error;
  XFile? _picked;
  late String _currentMode;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
  }

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
      if (file == null) {
        setState(() => _loading = false);
        return;
      }
      _picked = file;
      final bytes = await file.readAsBytes();
      final res = await BackendApi.uploadScanImage(
        bytes: bytes,
        filename: file.name,
        email: widget.email,
        mode: _currentMode,
      );
      setState(() {
        _detections = res['detections'] as List<dynamic>? ?? [];
        _enriched = res['enriched'] as Map<String, dynamic>?;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildModeSelector(),
            const SizedBox(height: 20),
            if (_picked != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    File(_picked!.path),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    onPressed: _loading ? null : () => _pickAndUpload(ImageSource.camera),
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    onPressed: _loading ? null : () => _pickAndUpload(ImageSource.gallery),
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: Colors.white.withOpacity(0.1),
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ),
            if (_enriched != null || (_detections != null && _detections!.isNotEmpty))
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_enriched != null) _buildResultContent(),
                      if (_detections != null && _detections!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ..._detections!.map((d) => _buildDetectionTile(d)).toList(),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_currentMode) {
      case 'form_check': return 'Form Check';
      case 'body_check': return 'Body Composition';
      default: return 'Equipment Scan';
    }
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _ModeTab(
            label: 'Equipment',
            isActive: _currentMode == 'equipment_info',
            onTap: () => setState(() => _currentMode = 'equipment_info'),
          ),
          _ModeTab(
            label: 'Form',
            isActive: _currentMode == 'form_check',
            onTap: () => setState(() => _currentMode = 'form_check'),
          ),
          _ModeTab(
            label: 'Body',
            isActive: _currentMode == 'body_check',
            onTap: () => setState(() => _currentMode = 'body_check'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultContent() {
    final title = _currentMode == 'form_check' 
        ? 'Phân tích tư thế' 
        : (_currentMode == 'body_check' ? 'Phân tích vóc dáng' : 'AI Hướng dẫn sử dụng');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white10),
          
          if (_currentMode == 'equipment_info') ...[
            _buildInfoRow('Nhóm cơ', _enriched?['targetMuscle'] ?? '--'),
            _buildInfoRow('Độ khó', _enriched?['difficulty'] ?? '--'),
          ],
          
          const Text(
            'Kết luận AI:',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ..._buildInstructionLines(_enriched?['instructions']),
          
          if ((_enriched?['commonMistakes'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Lưu ý quan trọng:',
              style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              _enriched?['commonMistakes'],
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13, height: 1.4),
            ),
          ],
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop({
                  'text': _buildChatSummaryMessage(),
                  'imagePath': _picked?.path,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                foregroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Gửi vào Chat AI', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionTile(dynamic d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.fitness_center, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d['name']?.toString() ?? 'Unknown',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confidence: ${d['confidence'] ?? ''}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  List<Widget> _buildInstructionLines(dynamic instructions) {
    if (instructions is List) {
      return instructions
          .whereType<dynamic>()
          .map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${step.toString()}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
              ))
          .toList();
    }
    if (instructions != null && instructions.toString().isNotEmpty) {
      return [Text(instructions.toString(), style: TextStyle(color: Colors.white.withValues(alpha: 0.8)))];
    }
    return [Text('Chưa có hướng dẫn cụ thể.', style: TextStyle(color: Colors.white.withValues(alpha: 0.6)))];
  }

  String _buildChatSummaryMessage() {
    final buffer = StringBuffer();
    String prefix = 'Scan Equipment';
    if (_currentMode == 'form_check') prefix = 'Form Check';
    if (_currentMode == 'body_check') prefix = 'Body Analysis';

    buffer.writeln('[$prefix Result]');
    if (_currentMode == 'equipment_info') {
      final equipmentName = _detections?.isNotEmpty == true ? _detections!.first['name']?.toString() : 'Thiết bị không xác định';
      buffer.writeln('Thiết bị: $equipmentName');
    }
    final instructions = _enriched?['instructions'];
    if (instructions is List && instructions.isNotEmpty) {
      for (final step in instructions) {
        buffer.writeln('- ${step.toString()}');
      }
    } else if (instructions != null && instructions.toString().isNotEmpty) {
      buffer.writeln('- ${instructions.toString()}');
    }
    final mistakes = _enriched?['commonMistakes']?.toString() ?? '';
    if (mistakes.isNotEmpty) {
      buffer.writeln('Lưu ý: $mistakes');
    }
    return buffer.toString().trim();
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _ModeTab({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: isActive ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: isActive ? AppColors.textDark : Colors.white60, fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    this.textColor = AppColors.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
    );
  }
}
