import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/timestamp_converter.dart';

part 'cat_document.freezed.dart';
part 'cat_document.g.dart';

/// A stored document for a cat (vaccination card, passport, etc.), mirroring
/// `users/{uid}/cats/{catId}/documents/{docId}` in Firestore.
@freezed
class CatDocument with _$CatDocument {
  const factory CatDocument({
    required String id,
    required String name,
    required String type,
    required String storageUrl,
    @TimestampConverter() DateTime? uploadedAt,
  }) = _CatDocument;

  factory CatDocument.fromJson(Map<String, dynamic> json) =>
      _$CatDocumentFromJson(json);

  factory CatDocument.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return CatDocument.fromJson(<String, dynamic>{...data, 'id': doc.id});
  }
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
