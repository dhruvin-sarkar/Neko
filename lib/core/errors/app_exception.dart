/// The single exception type thrown across repository boundaries.
///
/// Repositories translate low-level failures (Firebase codes, network errors,
/// parsing issues) into an [AppException] carrying a user-friendly [message].
/// No Firebase or platform exception types should ever escape a repository.
class AppException implements Exception {
  const AppException(this.message, {this.cause});

  /// A message safe to display directly to the user.
  final String message;

  /// The originating error, kept for logging. Never surfaced to the UI.
  final Object? cause;

  @override
  String toString() => 'AppException: $message';
}
