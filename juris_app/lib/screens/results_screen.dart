import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/audit_model.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/clause_card.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/risk_gauge.dart';

class ResultsScreen extends StatelessWidget {
  final String docId;
  final String auditId;

  const ResultsScreen({
    super.key,
    required this.docId,
    required this.auditId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Results')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/lod', arguments: {
            'auditId': auditId,
          });
        },
        icon: const Icon(Icons.mail_outline),
        label: const Text('Generate Letter of Demand'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: StreamBuilder<AuditModel?>(
        stream: FirebaseService().auditStream(auditId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final audit = snapshot.data;
          if (audit == null) {
            return Center(
              child: Text(
                'Audit not found',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            );
          }

          return _buildResultsBody(audit);
        },
      ),
    );
  }

  Widget _buildResultsBody(AuditModel audit) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        const SizedBox(height: 24),
        Center(child: RiskGauge(riskScore: audit.riskScore)),
        const SizedBox(height: 16),
        _buildSummaryRow(audit),
        const SizedBox(height: 8),
        const DisclaimerBanner(),
        const SizedBox(height: 8),
        if (audit.actionableNextStep.isNotEmpty)
          _buildNextStepCard(audit.actionableNextStep),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            'Flagged Clauses (${audit.flaggedCount})',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (audit.flaggedClauses.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.check_circle,
                      size: 48, color: AppColors.compliant),
                  const SizedBox(height: 12),
                  Text(
                    'No flagged clauses found!',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.compliant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(
            audit.flaggedClauses.length,
            (i) => ClauseCard(clause: audit.flaggedClauses[i], index: i),
          ),
      ],
    );
  }

  Widget _buildSummaryRow(AuditModel audit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildChip(
            'Total: ${audit.totalClausesCount}',
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.08),
          ),
          _buildChip(
            'Compliant: ${audit.compliantClausesCount}',
            AppColors.compliant,
            AppColors.compliantBg,
          ),
          if (audit.illegalCount > 0)
            _buildChip(
              'Illegal: ${audit.illegalCount}',
              AppColors.illegal,
              AppColors.illegalBg,
            ),
          if (audit.unfairCount > 0)
            _buildChip(
              'Unfair: ${audit.unfairCount}',
              AppColors.unfair,
              AppColors.unfairBg,
            ),
          if (audit.cautionCount > 0)
            _buildChip(
              'Caution: ${audit.cautionCount}',
              AppColors.caution,
              AppColors.cautionBg,
            ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildNextStepCard(String nextStep) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primary.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_outline,
                color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended Next Step',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nextStep,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.5,
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
}
