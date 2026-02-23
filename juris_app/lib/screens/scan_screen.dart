import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;
  String? _error;

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        _uploading = true;
        _error = null;
      });

      final file = File(picked.path);
      final docId = DateTime.now().millisecondsSinceEpoch.toString();
      final service = FirebaseService();

      final imageUrl = await service.uploadDocumentImage(
        docId: docId,
        imageFile: file,
      );

      await service.createDocument(docId: docId, imageUrl: imageUrl);

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/processing', arguments: {
        'docId': docId,
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Agreement')),
      body: _uploading ? _buildUploadingState() : _buildPickerUI(),
    );
  }

  Widget _buildUploadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text('Uploading document...'),
        ],
      ),
    );
  }

  Widget _buildPickerUI() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Icon(
            Icons.document_scanner_outlined,
            size: 96,
            color: AppColors.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 24),
          Text(
            'Upload Your Tenancy Agreement',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Take a photo or pick from your gallery.\n'
            'We will analyse it for potentially illegal or unfair clauses.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.illegalBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _error!,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.illegal),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _pickAndUpload(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _pickAndUpload(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Pick from Gallery'),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
