import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/logger.dart';
import '../models/cat_document.dart';

part 'document_repository.g.dart';

/// Repository for one cat's documents, scoped to the current user.
@riverpod
DocumentRepository documentRepository(Ref ref, String catId) =>
    DocumentRepository(
      firestore: ref.watch(firestoreProvider),
      storage: ref.watch(firebaseStorageProvider),
      userId: ref.watch(currentUserProvider).uid,
      catId: catId,
    );

class DocumentRepository {
  DocumentRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required String userId,
    required String catId,
  }) : _docsRef = firestore
           .collection('users')
           .doc(userId)
           .collection('cats')
           .doc(catId)
           .collection('documents'),
       _storageBase = storage.ref('users/$userId/cats/$catId/documents');

  final CollectionReference<Map<String, dynamic>> _docsRef;
  final Reference _storageBase;

  Stream<List<CatDocument>> watchAll() => _docsRef
      .orderBy('uploadedAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(CatDocument.fromFirestore).toList());

  /// Uploads the file at [path] to Storage and records its metadata.
  Future<void> upload({
    required String path,
    required String name,
    required String type,
  }) async {
    try {
      final File file = File(path);
      final String extension = _extensionOf(path);
      final String objectName =
          '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final Reference ref = _storageBase.child(objectName);

      await ref.putFile(
        file,
        SettableMetadata(contentType: _contentTypeFor(extension)),
      );
      final String url = await ref.getDownloadURL();

      final DocumentReference<Map<String, dynamic>> docRef = _docsRef.doc();
      await docRef.set(<String, dynamic>{
        'id': docRef.id,
        'name': name.trim().isEmpty ? DocumentTypes.label(type) : name.trim(),
        'type': type,
        'storageUrl': url,
        'uploadedAt': FieldValue.serverTimestamp(),
      });
    } on Object catch (e, st) {
      AppLogger.error('Document upload failed', e, st);
      throw const AppException(
        "We couldn't upload that document. Please try again.",
      );
    }
  }

  /// Removes a document's Firestore record and its Storage object.
  Future<void> delete(CatDocument document) async {
    try {
      await _docsRef.doc(document.id).delete();
      try {
        await FirebaseStorage.instance.refFromURL(document.storageUrl).delete();
      } on Object catch (e, st) {
        // The metadata is gone; a leftover Storage object is non-fatal.
        AppLogger.warning('Document storage cleanup failed', e, st);
      }
    } on Object catch (e, st) {
      AppLogger.error('Document delete failed', e, st);
      throw const AppException(
        "We couldn't remove that document. Please try again.",
      );
    }
  }

  String _extensionOf(String path) {
    final int dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return 'dat';
    return path.substring(dot + 1).toLowerCase();
  }

  String _contentTypeFor(String extension) {
    return switch (extension) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
  }
}
