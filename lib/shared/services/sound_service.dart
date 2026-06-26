import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sound_service.g.dart';

/// UI sound effects.
///
/// There are no real sound clips bundled yet, so every method is a no-op and
/// the app relies on haptics for tactile feedback. Attempting to load the
/// missing/placeholder assets only spammed errors and caused startup jank.
/// When real CC0 clips land in `assets/sounds/`, restore the `AudioPool`
/// implementation (it's in git history) and wire the paths back into [init].
class SoundService {
  Future<void> init() async {}
  Future<void> tap() async {}
  Future<void> select() async {}
  Future<void> whoosh() async {}
  Future<void> success() async {}
  Future<void> error() async {}
  Future<void> dispose() async {}
}

/// App-wide [SoundService]. Initialized in `main()` before `runApp`.
@Riverpod(keepAlive: true)
SoundService soundService(Ref ref) {
  final SoundService service = SoundService();
  ref.onDispose(service.dispose);
  return service;
}
