import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/firebase_providers.dart';
import '../data/document_repository.dart';
import '../models/cat_document.dart';

part 'document_provider.g.dart';

/// A cat's documents (newest first). Empty while signed out. Re-reads on demand;
/// the action controller invalidates it after an upload or delete.
@riverpod
Future<List<CatDocument>> documents(Ref ref, String catId) async {
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) return const <CatDocument>[];
  return ref.watch(documentRepositoryProvider(catId)).getAll();
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
    // Hold the (auto-dispose) notifier alive across the await so navigating
    // away mid-upload can't dispose it and crash the post-await state write.
    final KeepAliveLink link = ref.keepAlive();
    try {
      state = const AsyncValue<void>.loading();
      state = await AsyncValue.guard(
        () => ref
            .read(documentRepositoryProvider(catId))
            .upload(path: path, name: name, type: type),
      );
      if (!state.hasError) ref.invalidate(documentsProvider(catId));
    } finally {
      link.close();
    }
  }

  Future<void> delete({
    required String catId,
    required CatDocument document,
  }) async {
    if (state.isLoading) return;
    final KeepAliveLink link = ref.keepAlive();
    try {
      state = const AsyncValue<void>.loading();
      state = await AsyncValue.guard(
        () => ref.read(documentRepositoryProvider(catId)).delete(document),
      );
      if (!state.hasError) ref.invalidate(documentsProvider(catId));
    } finally {
      link.close();
    }
  }
}
