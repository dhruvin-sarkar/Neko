import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../errors/app_exception.dart';

part 'firebase_providers.g.dart';

/// The Firebase Auth singleton.
@Riverpod(keepAlive: true)
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

/// The Cloud Firestore singleton.
@Riverpod(keepAlive: true)
FirebaseFirestore firestore(Ref ref) => FirebaseFirestore.instance;

/// Streams the current authentication state. Emits `null` when signed out.
///
/// This is the source of truth the router listens to for auth gating.
@Riverpod(keepAlive: true)
Stream<User?> authStateChanges(Ref ref) =>
    ref.watch(firebaseAuthProvider).authStateChanges();

/// The currently authenticated user.
///
/// Throws [AppException] if read while signed out — callers that depend on an
/// authenticated user (repositories, profile providers) can rely on this.
@Riverpod(keepAlive: true)
User currentUser(Ref ref) {
  final User? user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) {
    throw const AppException('You need to be signed in to do that.');
  }
  return user;
}
