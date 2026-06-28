import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/utils/logger.dart';
import '../models/cat_document.dart';

part 'document_repository.g.dart';

/// Repository for one cat's documents, stored on-device via
/// [LocalStorageService] (no Firebase Storage — a deliberate cost decision).
@riverpod
DocumentRepository documentRepository(Ref ref, String catId) =>
    DocumentRepository(catId);

class DocumentRepository {
  DocumentRepository(this._catId);

  final String _catId;

  /// All stored documents for this cat, newest first.
  Future<List<CatDocument>> getAll() async {
    final List<Map<String, dynamic>> raw =
        await LocalStorageService.getDocuments(_catId);
    final List<CatDocument> docs = raw.map(CatDocument.fromLocal).toList();
    docs.sort((a, b) {
      final DateTime? ad = a.savedAt;
      final DateTime? bd = b.savedAt;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1; // undated/corrupt entries sort last
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return docs;
  }

  /// Saves the file at [path] on-device under [type] with display [name].
  Future<void> upload({
    required String path,
    required String name,
    required String type,
  }) async {
    try {
      final bytes = await File(path).readAsBytes();
      final String ext = _extensionOf(path);
      final String display = name.trim().isEmpty
          ? DocumentTypes.label(type)
          : name.trim();
      final String? saved = await LocalStorageService.saveDocument(
        catId: _catId,
        docType: type,
        bytes: bytes,
        filename: '$display.$ext',
      );
      if (saved == null) {
        throw const AppException(
          "We couldn't save that document. Please try again.",
        );
      }
    } on AppException {
      rethrow;
    } on Object catch (e, st) {
      AppLogger.error('Document save failed', e, st);
      throw const AppException(
        "We couldn't save that document. Please try again.",
      );
    }
  }

  /// Removes a document (index entry + file).
  Future<void> delete(CatDocument document) async {
    try {
      await LocalStorageService.deleteDocument(_catId, document.path);
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
}
