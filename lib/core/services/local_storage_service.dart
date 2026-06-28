import 'dart:io';
import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/logger.dart';

/// On-device media storage for cat profile pictures and documents.
///
/// Replaces Firebase Storage (which the project intentionally doesn't use):
/// files live under `<appDocuments>/neko/cats/<catId>/...` and a Hive box keeps
/// the lightweight index (profile-picture path + document metadata). Bytes stay
/// on disk; Hive only holds paths and metadata, so it stays small and fast.
class LocalStorageService {
  LocalStorageService._();

  static const String _boxName = 'neko_media';
  static Box<dynamic>? _box;
  static late String _root;

  static Box<dynamic> get _media {
    final Box<dynamic>? box = _box;
    if (box == null) {
      throw StateError('LocalStorageService.init() must be called first.');
    }
    return box;
  }

  /// Opens Hive and prepares the `<appDocuments>/neko/` directory. Call once
  /// from `main()` before `runApp`.
  static Future<void> init() async {
    if (_box != null) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
    final Directory docs = await getApplicationDocumentsDirectory();
    _root = '${docs.path}/neko';
    await Directory(_root).create(recursive: true);
  }

  static String _catDir(String catId) => '$_root/cats/$catId';

  // ── Profile picture ──

  /// Saves [imageBytes] as the cat's profile picture and returns the file path.
  static Future<String?> saveProfilePicture(
    String catId,
    Uint8List imageBytes,
  ) async {
    try {
      final Directory dir = Directory(_catDir(catId));
      await dir.create(recursive: true);
      final String path = '${dir.path}/profile.jpg';
      await File(path).writeAsBytes(imageBytes, flush: true);
      await _media.put('pfp_$catId', path);
      return path;
    } on Object catch (e, st) {
      AppLogger.error('Failed to save profile picture', e, st);
      return null;
    }
  }

  /// Returns the stored profile-picture path, or null if none exists on disk.
  static Future<String?> getProfilePicturePath(String catId) async {
    final Object? path = _media.get('pfp_$catId');
    if (path is! String) return null;
    return await File(path).exists() ? path : null;
  }

  // ── Documents ──

  /// Saves a document and records its metadata. Returns the saved file path.
  static Future<String?> saveDocument({
    required String catId,
    required String docType,
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final Directory dir = Directory('${_catDir(catId)}/docs/$docType');
      await dir.create(recursive: true);
      final String path = '${dir.path}/$filename';
      await File(path).writeAsBytes(bytes, flush: true);

      final List<Map<String, dynamic>> docs = await getDocuments(catId);
      docs.removeWhere((Map<String, dynamic> d) => d['path'] == path);
      docs.add(<String, dynamic>{
        'path': path,
        'docType': docType,
        'filename': filename,
        'savedAt': DateTime.now().toIso8601String(),
        'sizeBytes': bytes.length,
      });
      await _media.put('docs_$catId', docs);
      return path;
    } on Object catch (e, st) {
      AppLogger.error('Failed to save document', e, st);
      return null;
    }
  }

  /// Returns saved document metadata:
  /// `{path, docType, filename, savedAt, sizeBytes}`.
  static Future<List<Map<String, dynamic>>> getDocuments(String catId) async {
    final Object? raw = _media.get('docs_$catId');
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (Map<dynamic, dynamic> m) =>
              m.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList();
  }

  /// Removes one document (file + index entry).
  static Future<void> deleteDocument(String catId, String path) async {
    try {
      final File file = File(path);
      if (await file.exists()) await file.delete();
      final List<Map<String, dynamic>> docs = await getDocuments(catId);
      docs.removeWhere((Map<String, dynamic> d) => d['path'] == path);
      await _media.put('docs_$catId', docs);
    } on Object catch (e, st) {
      AppLogger.warning('Failed to delete document', e, st);
    }
  }

  /// Removes every file and index entry for a cat.
  static Future<void> clearCatData(String catId) async {
    try {
      final Directory dir = Directory(_catDir(catId));
      if (await dir.exists()) await dir.delete(recursive: true);
      await _media.delete('pfp_$catId');
      await _media.delete('docs_$catId');
    } on Object catch (e, st) {
      AppLogger.warning('Failed to clear cat data', e, st);
    }
  }
}
