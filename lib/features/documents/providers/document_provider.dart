import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/firebase_providers.dart';
import '../data/document_repository.dart';
import '../models/cat_document.dart';

part 'document_provider.g.dart';

/// Streams a cat's documents (newest first). Emits empty while signed out.
@riverpod
Stream<List<CatDocument>> documents(Ref ref, String catId) {
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) {
    return Stream<List<CatDocument>>.value(const <CatDocument>[]);
  }
  return ref.watch(documentRepositoryProvider(catId)).watchAll();
}

/// Drives document upload/delete actions and exposes progress as [AsyncValue].
@riverpod
class DocumentActionController extends _$DocumentActionController {
  @override
  FutureOr<void> build() {}

  Future<void> upload({
    required String catId,
    required String path,
    required String name,
    required String type,
  }) async {
    if (state.isLoading) return;
    state = const AsyncValue<void>.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(documentRepositoryProvider(catId))
          .upload(path: path, name: name, type: type),
    );
  }

  Future<void> delete({
    required String catId,
    required CatDocument document,
  }) async {
    if (state.isLoading) return;
    state = const AsyncValue<void>.loading();
    state = await AsyncValue.guard(
      () => ref.read(documentRepositoryProvider(catId)).delete(document),
    );
  }
}
