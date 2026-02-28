import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/audit_model.dart';
import '../models/document_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // === AUTH ===

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInAnonymously() async {
    final result = await _auth.signInAnonymously();
    return result.user;
  }

  // === STORAGE ===

  Future<String> uploadDocumentImage({
    required String docId,
    required File imageFile,
    required int index,
  }) async {
    final userId = uid;
    if (userId == null) throw Exception('Not authenticated');

    final ref = _storage.ref().child('documents/$userId/$docId/image_$index.jpg');
    await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.fullPath;
  }

  // === DOCUMENTS ===

  Future<void> createDocument({
    required String docId,
    required List<String> imageUrls,
  }) async {
    final userId = uid;
    if (userId == null) throw Exception('Not authenticated');

    await _firestore.collection('documents').doc(docId).set({
      'uid': userId,
      'image_urls': imageUrls,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentModel?> documentStream(String docId) {
    return _firestore
        .collection('documents')
        .doc(docId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      return DocumentModel.fromFirestore(snap);
    });
  }

  Stream<List<DocumentModel>> userDocumentsStream() {
    final userId = uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('documents')
        .where('uid', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DocumentModel.fromFirestore(d)).toList());
  }

  // === AUDITS ===

  Stream<AuditModel?> auditStream(String auditId) {
    return _firestore
        .collection('audits')
        .doc(auditId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      return AuditModel.fromFirestore(snap);
    });
  }

  Future<AuditModel?> getAudit(String auditId) async {
    final doc = await _firestore.collection('audits').doc(auditId).get();
    if (!doc.exists) return null;
    return AuditModel.fromFirestore(doc);
  }

  // === DELETE ===

  Future<void> deleteDocument(String docId) async {
    await _firestore.collection('documents').doc(docId).delete();
  }
}
