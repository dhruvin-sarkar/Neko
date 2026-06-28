import 'package:freezed_annotation/freezed_annotation.dart';

part 'cat_document.freezed.dart';

/// A stored document for a cat (vaccination card, passport, etc.), kept on the
/// device via `LocalStorageService`. [path] is the absolute file path and also
/// serves as the document's unique key.
@freezed
class CatDocument with _$CatDocument {
  const factory CatDocument({
    required String path,
    required String name,
    required String type,
    @Default(0) int sizeBytes,
    DateTime? savedAt,
  }) = _CatDocument;

  /// Builds from a `LocalStorageService` metadata map
  /// (`{path, docType, filename, savedAt, sizeBytes}`).
  factory CatDocument.fromLocal(Map<String, dynamic> m) => CatDocument(
    path: (m['path'] as String?) ?? '',
    name: (m['filename'] as String?) ?? 'Document',
    type: (m['docType'] as String?) ?? 'other',
    sizeBytes: ((m['sizeBytes'] as num?) ?? 0).toInt(),
    savedAt: DateTime.tryParse((m['savedAt'] as String?) ?? ''),
  );
}

/// The fixed set of document types the user can choose from.
abstract final class DocumentTypes {
  const DocumentTypes._();

  static const List<String> all = <String>[
    'passport',
    'vaccination',
    'microchip',
    'license',
    'other',
  ];

  static String label(String type) {
    return switch (type) {
      'passport' => 'Passport',
      'vaccination' => 'Vaccination',
      'microchip' => 'Microchip',
      'license' => 'License',
      _ => 'Other',
    };
  }
}
