// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$documentRepositoryHash() =>
    r'd74194ecd92963ccd0eb029186ac554aef4098fc';

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

/// Repository for one cat's documents, stored on-device via
/// [LocalStorageService] (no Firebase Storage — a deliberate cost decision).
///
/// Copied from [documentRepository].
@ProviderFor(documentRepository)
const documentRepositoryProvider = DocumentRepositoryFamily();

/// Repository for one cat's documents, stored on-device via
/// [LocalStorageService] (no Firebase Storage — a deliberate cost decision).
///
/// Copied from [documentRepository].
class DocumentRepositoryFamily extends Family<DocumentRepository> {
  /// Repository for one cat's documents, stored on-device via
  /// [LocalStorageService] (no Firebase Storage — a deliberate cost decision).
  ///
  /// Copied from [documentRepository].
  const DocumentRepositoryFamily();

  /// Repository for one cat's documents, stored on-device via
  /// [LocalStorageService] (no Firebase Storage — a deliberate cost decision).
  ///
  /// Copied from [documentRepository].
  DocumentRepositoryProvider call(String catId) {
    return DocumentRepositoryProvider(catId);
  }

  @override
  DocumentRepositoryProvider getProviderOverride(
    covariant DocumentRepositoryProvider provider,
  ) {
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
  String? get name => r'documentRepositoryProvider';
}

/// Repository for one cat's documents, stored on-device via
/// [LocalStorageService] (no Firebase Storage — a deliberate cost decision).
///
/// Copied from [documentRepository].
class DocumentRepositoryProvider
    extends AutoDisposeProvider<DocumentRepository> {
  /// Repository for one cat's documents, stored on-device via
  /// [LocalStorageService] (no Firebase Storage — a deliberate cost decision).
  ///
  /// Copied from [documentRepository].
  DocumentRepositoryProvider(String catId)
    : this._internal(
        (ref) => documentRepository(ref as DocumentRepositoryRef, catId),
        from: documentRepositoryProvider,
        name: r'documentRepositoryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$documentRepositoryHash,
        dependencies: DocumentRepositoryFamily._dependencies,
        allTransitiveDependencies:
            DocumentRepositoryFamily._allTransitiveDependencies,
        catId: catId,
      );

  DocumentRepositoryProvider._internal(
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
    DocumentRepository Function(DocumentRepositoryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DocumentRepositoryProvider._internal(
        (ref) => create(ref as DocumentRepositoryRef),
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
  AutoDisposeProviderElement<DocumentRepository> createElement() {
    return _DocumentRepositoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DocumentRepositoryProvider && other.catId == catId;
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
mixin DocumentRepositoryRef on AutoDisposeProviderRef<DocumentRepository> {
  /// The parameter `catId` of this provider.
  String get catId;
}

class _DocumentRepositoryProviderElement
    extends AutoDisposeProviderElement<DocumentRepository>
    with DocumentRepositoryRef {
  _DocumentRepositoryProviderElement(super.provider);

  @override
  String get catId => (origin as DocumentRepositoryProvider).catId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
