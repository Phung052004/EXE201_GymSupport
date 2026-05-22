import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _error;
  XFile? _picked;

  Future<void> _pickAndUpload(ImageSource src) async {
    setState(() {
      _loading = true;
      _error = null;
      _detections = null;
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
      setState(() => _detections = res['detections'] as List<dynamic>? ?? []);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Equipment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_picked != null) Image.file(File(_picked!.path), height: 220),
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
            if (_loading) const CircularProgressIndicator(),
            if (_error != null)
              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            if (_detections != null)
              Expanded(
                child: ListView.builder(
                  itemCount: _detections!.length,
                  itemBuilder: (ctx, i) {
                    final d = _detections![i];
                    return ListTile(
                      title: Text(d['name']?.toString() ?? 'Unknown'),
                      subtitle: Text('Confidence: ${d['confidence'] ?? ''}'),
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
