// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$documentsHash() => r'3c476c41926525664a3f558036ffaf9dcb6a3d00';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// A cat's documents (newest first). Empty while signed out. Re-reads on demand;
/// the action controller invalidates it after an upload or delete.
///
/// Copied from [documents].
@ProviderFor(documents)
const documentsProvider = DocumentsFamily();

/// A cat's documents (newest first). Empty while signed out. Re-reads on demand;
/// the action controller invalidates it after an upload or delete.
///
/// Copied from [documents].
class DocumentsFamily extends Family<AsyncValue<List<CatDocument>>> {
  /// A cat's documents (newest first). Empty while signed out. Re-reads on demand;
  /// the action controller invalidates it after an upload or delete.
  ///
  /// Copied from [documents].
  const DocumentsFamily();

  /// A cat's documents (newest first). Empty while signed out. Re-reads on demand;
  /// the action controller invalidates it after an upload or delete.
  ///
  /// Copied from [documents].
  DocumentsProvider call(String catId) {
    return DocumentsProvider(catId);
  }

  @override
  DocumentsProvider getProviderOverride(covariant DocumentsProvider provider) {
    return call(provider.catId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'documentsProvider';
}

/// A cat's documents (newest first). Empty while signed out. Re-reads on demand;
/// the action controller invalidates it after an upload or delete.
///
/// Copied from [documents].
class DocumentsProvider extends AutoDisposeFutureProvider<List<CatDocument>> {
  /// A cat's documents (newest first). Empty while signed out. Re-reads on demand;
  /// the action controller invalidates it after an upload or delete.
  ///
  /// Copied from [documents].
  DocumentsProvider(String catId)
    : this._internal(
        (ref) => documents(ref as DocumentsRef, catId),
        from: documentsProvider,
        name: r'documentsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$documentsHash,
        dependencies: DocumentsFamily._dependencies,
        allTransitiveDependencies: DocumentsFamily._allTransitiveDependencies,
        catId: catId,
      );

  DocumentsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.catId,
  }) : super.internal();

  final String catId;

  @override
  Override overrideWith(
    FutureOr<List<CatDocument>> Function(DocumentsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DocumentsProvider._internal(
        (ref) => create(ref as DocumentsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        catId: catId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<CatDocument>> createElement() {
    return _DocumentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DocumentsProvider && other.catId == catId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, catId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DocumentsRef on AutoDisposeFutureProviderRef<List<CatDocument>> {
  /// The parameter `catId` of this provider.
  String get catId;
}

class _DocumentsProviderElement
    extends AutoDisposeFutureProviderElement<List<CatDocument>>
    with DocumentsRef {
  _DocumentsProviderElement(super.provider);

  @override
  String get catId => (origin as DocumentsProvider).catId;
}

String _$documentActionControllerHash() =>
    r'9eaa2eda728ae629fc86a3e3e7c48165afaf878e';

/// Drives document upload/delete actions and exposes progress as [AsyncValue].
///
/// Copied from [DocumentActionController].
@ProviderFor(DocumentActionController)
final documentActionControllerProvider =
    AutoDisposeAsyncNotifierProvider<DocumentActionController, void>.internal(
      DocumentActionController.new,
      name: r'documentActionControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$documentActionControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DocumentActionController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
