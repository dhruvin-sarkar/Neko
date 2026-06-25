import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

/// Converts between Firestore [Timestamp] values and Dart [DateTime].
///
/// Tolerates ISO-8601 strings too, so models round-trip through both Firestore
/// and plain JSON without special-casing at the call site.
class TimestampConverter implements JsonConverter<DateTime?, Object?> {
  const TimestampConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json is Timestamp) return json.toDate();
    if (json is String) return DateTime.tryParse(json);
    return null;
  }

  @override
  Object? toJson(DateTime? date) =>
      date == null ? null : Timestamp.fromDate(date);
}
