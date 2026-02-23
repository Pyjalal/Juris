import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  final String id;
  final String uid;
  final String? imageUrl;
  final String? ocrText;
  final double? ocrConfidence;
  final String? ocrLanguage;
  final List<Map<String, dynamic>>? ocrClauses;
  final String? ocrWarning;
  final String status;
  final String? auditId;
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DocumentModel({
    required this.id,
    required this.uid,
    this.imageUrl,
    this.ocrText,
    this.ocrConfidence,
    this.ocrLanguage,
    this.ocrClauses,
    this.ocrWarning,
    this.status = 'pending',
    this.auditId,
    this.errorMessage,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  factory DocumentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return DocumentModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      imageUrl: data['image_url'],
      ocrText: data['ocr_text'],
      ocrConfidence: (data['ocr_confidence'] as num?)?.toDouble(),
      ocrLanguage: data['ocr_language'],
      ocrClauses: (data['ocr_clauses'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList(),
      ocrWarning: data['ocr_warning'],
      status: data['status'] ?? 'pending',
      auditId: data['audit_id'],
      errorMessage: data['error_message'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      if (imageUrl != null) 'image_url': imageUrl,
      'status': status,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}
