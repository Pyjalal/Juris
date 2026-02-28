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
  List<XFile> _selectedImages = [];

  Future<void> _pickImages(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> picked = await _picker.pickMultiImage(
          maxWidth: 2048,
          maxHeight: 2048,
          imageQuality: 85,
        );
        if (picked.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(picked);
            _error = null;
          });
        }
      } else {
        final XFile? picked = await _picker.pickImage(
          source: source,
          maxWidth: 2048,
          maxHeight: 2048,
          imageQuality: 85,
        );
        if (picked != null) {
          setState(() {
            _selectedImages.add(picked);
            _error = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to pick image(s): ${e.toString()}';
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _uploadAndProcess() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      final docId = DateTime.now().millisecondsSinceEpoch.toString();
      final service = FirebaseService();
      final List<String> imageUrls = [];

      for (int i = 0; i < _selectedImages.length; i++) {
        final file = File(_selectedImages[i].path);
        final imageUrl = await service.uploadDocumentImage(
          docId: docId,
          imageFile: file,
          index: i,
        );
        imageUrls.add(imageUrl);
      }

      await service.createDocument(docId: docId, imageUrls: imageUrls);

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
      body: _uploading ? _buildUploadingState() : _buildContent(),
      bottomNavigationBar: _selectedImages.isNotEmpty && !_uploading
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildContent() {
    if (_selectedImages.isEmpty) {
      return _buildPickerUI();
    } else {
      return _buildPreviewUI();
    }
  }

  Widget _buildPreviewUI() {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: _selectedImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                return _buildAddMoreButton();
              }
              return _buildImageCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageCard(int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            image: DecorationImage(
              image: FileImage(File(_selectedImages[index].path)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Page ${index + 1}',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddMoreButton() {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImages(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Pick from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImages(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate,
                size: 48, color: AppColors.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 8),
            Text(
              'Add Page',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.illegal),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _uploadAndProcess,
                icon: const Icon(Icons.upload_file),
                label: Text('Analyse ${_selectedImages.length} Pages'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
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
              onPressed: () => _pickImages(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _pickImages(ImageSource.gallery),
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
