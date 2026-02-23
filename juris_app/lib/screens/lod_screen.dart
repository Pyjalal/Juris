import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class LodScreen extends StatefulWidget {
  final String auditId;

  const LodScreen({super.key, required this.auditId});

  @override
  State<LodScreen> createState() => _LodScreenState();
}

class _LodScreenState extends State<LodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tenantNameController = TextEditingController();
  final _tenantIcController = TextEditingController();
  final _tenantAddressController = TextEditingController();
  final _landlordNameController = TextEditingController();
  final _propertyAddressController = TextEditingController();

  bool _loading = false;
  String? _letterContent;
  String? _error;

  @override
  void dispose() {
    _tenantNameController.dispose();
    _tenantIcController.dispose();
    _tenantAddressController.dispose();
    _landlordNameController.dispose();
    _propertyAddressController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ApiService().generateLOD(
        auditId: widget.auditId,
        tenantName: _tenantNameController.text.trim(),
        tenantIc: _tenantIcController.text.trim(),
        tenantAddress: _tenantAddressController.text.trim(),
        landlordName: _landlordNameController.text.trim(),
        propertyAddress: _propertyAddressController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _letterContent = result['letter_content'] as String?;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _copyToClipboard() {
    if (_letterContent == null) return;
    Clipboard.setData(ClipboardData(text: _letterContent!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Letter copied to clipboard')),
    );
  }

  void _share() {
    if (_letterContent == null) return;
    Share.share(_letterContent!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Letter of Demand'),
        actions: [
          if (_letterContent != null) ...[
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _copyToClipboard,
              tooltip: 'Copy',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _share,
              tooltip: 'Share',
            ),
          ],
        ],
      ),
      body: _letterContent != null ? _buildPreview() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Details',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'We will generate a formal Letter of Demand based on the audit findings.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tenant Details',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tenantNameController,
              decoration: const InputDecoration(labelText: 'Full Name *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tenantIcController,
              decoration:
                  const InputDecoration(labelText: 'IC Number (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tenantAddressController,
              decoration:
                  const InputDecoration(labelText: 'Current Address (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Text(
              'Landlord Details',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _landlordNameController,
              decoration: const InputDecoration(labelText: 'Landlord Name *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _propertyAddressController,
              decoration:
                  const InputDecoration(labelText: 'Property Address *'),
              maxLines: 2,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Address is required' : null,
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
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _generate,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Generate Letter of Demand'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.compliantBg,
          child: Text(
            'Letter generated successfully. Review, copy, or share it.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.compliant,
            ),
          ),
        ),
        Expanded(
          child: Markdown(
            data: _letterContent ?? '',
            padding: const EdgeInsets.all(20),
            styleSheet: MarkdownStyleSheet(
              h1: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              h2: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              p: GoogleFonts.inter(fontSize: 14, height: 1.6),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _letterContent = null),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _share,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
