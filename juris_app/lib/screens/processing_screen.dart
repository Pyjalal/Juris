import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/document_model.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class ProcessingScreen extends StatefulWidget {
  final String docId;

  const ProcessingScreen({super.key, required this.docId});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  int _stepFromStatus(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'processing':
        return 1;
      case 'completed':
        return 3;
      case 'failed':
        return -1;
      default:
        return 0;
    }
  }

  void _handleCompleted(DocumentModel doc) {
    if (_navigated) return;
    _navigated = true;
    Future.microtask(() {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/results', arguments: {
        'docId': doc.id,
        'auditId': doc.auditId,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysing')),
      body: StreamBuilder<DocumentModel?>(
        stream: FirebaseService().documentStream(widget.docId),
        builder: (context, snapshot) {
          final doc = snapshot.data;
          final status = doc?.status ?? 'pending';
          final step = _stepFromStatus(status);

          if (doc != null && doc.isCompleted && doc.auditId != null) {
            _handleCompleted(doc);
          }

          if (step == -1) {
            return _buildErrorState(doc?.errorMessage ?? 'Processing failed');
          }

          final activeStep = status == 'processing' ? 2 : step;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                _buildAnimatedIcon(activeStep),
                const SizedBox(height: 40),
                _buildStepIndicator(activeStep),
                const Spacer(),
                Text(
                  'Please wait while we analyse your agreement.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedIcon(int activeStep) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
        child: Icon(
          _iconForStep(activeStep),
          size: 56,
          color: AppColors.primary,
        ),
      ),
    );
  }

  IconData _iconForStep(int step) {
    switch (step) {
      case 0:
        return Icons.cloud_upload;
      case 1:
        return Icons.text_snippet;
      case 2:
        return Icons.analytics;
      case 3:
        return Icons.check_circle;
      default:
        return Icons.hourglass_empty;
    }
  }

  Widget _buildStepIndicator(int activeStep) {
    const labels = ['Uploading', 'OCR', 'Analysis', 'Complete'];

    return Column(
      children: [
        Row(
          children: List.generate(labels.length, (index) {
            final isActive = index <= activeStep;
            final isCurrent = index == activeStep;
            return Expanded(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppColors.primary : AppColors.divider,
                      border: isCurrent
                          ? Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              width: 3,
                            )
                          : null,
                    ),
                    child: Center(
                      child: isActive && index < activeStep
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : Text(
                              '${index + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[index],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: activeStep < 3 ? null : 1.0,
            backgroundColor: AppColors.divider,
            color: AppColors.primary,
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.illegal),
            const SizedBox(height: 16),
            Text(
              'Processing Failed',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.illegal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
