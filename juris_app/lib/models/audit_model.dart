import 'package:cloud_firestore/cloud_firestore.dart';

class FlaggedClause {
  final String clauseId;
  final String originalText;
  final String statuteViolated;
  final String violationType;
  final String explanation;
  final String suggestedRevision;
  final double confidence;

  FlaggedClause({
    required this.clauseId,
    required this.originalText,
    required this.statuteViolated,
    required this.violationType,
    required this.explanation,
    required this.suggestedRevision,
    required this.confidence,
  });

  factory FlaggedClause.fromMap(Map<String, dynamic> map) {
    return FlaggedClause(
      clauseId: map['clause_id'] ?? '',
      originalText: map['original_text'] ?? '',
      statuteViolated: map['statute_violated'] ?? 'N/A',
      violationType: map['violation_type'] ?? 'caution',
      explanation: map['explanation'] ?? '',
      suggestedRevision: map['suggested_revision'] ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AuditModel {
  final String id;
  final String docId;
  final String uid;
  final int riskScore;
  final List<FlaggedClause> flaggedClauses;
  final int compliantClausesCount;
  final int totalClausesCount;
  final String actionableNextStep;
  final String analysisNotes;
  final int ragChunksUsed;
  final DateTime? createdAt;

  AuditModel({
    required this.id,
    required this.docId,
    required this.uid,
    required this.riskScore,
    required this.flaggedClauses,
    required this.compliantClausesCount,
    required this.totalClausesCount,
    required this.actionableNextStep,
    required this.analysisNotes,
    required this.ragChunksUsed,
    this.createdAt,
  });

  int get flaggedCount => flaggedClauses.length;

  int get illegalCount =>
      flaggedClauses.where((c) => c.violationType == 'illegal').length;

  int get unfairCount =>
      flaggedClauses.where((c) => c.violationType == 'unfair').length;

  int get cautionCount =>
      flaggedClauses.where((c) => c.violationType == 'caution').length;

  String get riskLabel {
    if (riskScore >= 70) return 'High Risk';
    if (riskScore >= 40) return 'Medium Risk';
    if (riskScore >= 20) return 'Low Risk';
    return 'Minimal Risk';
  }

  factory AuditModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AuditModel(
      id: doc.id,
      docId: data['doc_id'] ?? '',
      uid: data['uid'] ?? '',
      riskScore: (data['risk_score'] as num?)?.toInt() ?? 0,
      flaggedClauses: (data['flagged_clauses'] as List?)
              ?.map((e) => FlaggedClause.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      compliantClausesCount:
          (data['compliant_clauses_count'] as num?)?.toInt() ?? 0,
      totalClausesCount: (data['total_clauses_count'] as num?)?.toInt() ?? 0,
      actionableNextStep: data['actionable_next_step'] ?? '',
      analysisNotes: data['analysis_notes'] ?? '',
      ragChunksUsed: (data['rag_chunks_used'] as num?)?.toInt() ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }
}
