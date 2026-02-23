import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/audit_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ClauseCard extends StatefulWidget {
  final FlaggedClause clause;
  final int index;

  const ClauseCard({
    super.key,
    required this.clause,
    required this.index,
  });

  @override
  State<ClauseCard> createState() => _ClauseCardState();
}

class _ClauseCardState extends State<ClauseCard> {
  bool _expanded = false;
  String? _simplifiedText;
  bool _simplifying = false;

  Color get _borderColor => AppColors.colorForViolationType(widget.clause.violationType);
  Color get _bgColor => AppColors.bgForViolationType(widget.clause.violationType);

  String get _typeLabel {
    switch (widget.clause.violationType) {
      case 'illegal':
        return 'ILLEGAL';
      case 'unfair':
        return 'UNFAIR';
      case 'caution':
        return 'CAUTION';
      default:
        return widget.clause.violationType.toUpperCase();
    }
  }

  Future<void> _simplify() async {
    setState(() => _simplifying = true);
    try {
      final result = await ApiService().simplifyClause(
        clauseText: widget.clause.originalText,
        violationType: widget.clause.violationType,
        statuteViolated: widget.clause.statuteViolated,
      );
      if (mounted) {
        setState(() {
          _simplifiedText = result['simplified_text'] as String?;
          _simplifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _simplifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to simplify: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: _borderColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 8),
                      Text(
                        widget.clause.originalText,
                        maxLines: _expanded ? null : 3,
                        overflow: _expanded ? null : TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                      if (_expanded) ...[
                        const SizedBox(height: 12),
                        _buildSection('Explanation', widget.clause.explanation),
                        if (widget.clause.statuteViolated != 'N/A')
                          _buildSection('Statute Violated', widget.clause.statuteViolated),
                        _buildSection('Suggested Revision', widget.clause.suggestedRevision),
                        const SizedBox(height: 8),
                        _buildSimplifySection(),
                      ],
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _typeLabel,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _borderColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          widget.clause.clauseId.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          '${(widget.clause.confidence * 100).toInt()}%',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimplifySection() {
    if (_simplifiedText != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simplified Explanation',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _simplifiedText!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _simplifying ? null : _simplify,
        icon: _simplifying
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.translate, size: 18),
        label: Text(_simplifying ? 'Simplifying...' : 'Simplify This Clause'),
      ),
    );
  }
}
