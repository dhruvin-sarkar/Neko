import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/logger.dart';

part 'sound_service.g.dart';

/// Low-latency UI sound effects, pre-loaded into [AudioPool]s at startup.
///
/// Init is resilient: if a clip is missing or invalid the matching pool stays
/// null and playback is a silent no-op, so the app never crashes or blocks on
/// audio. Drop CC0 clips into `assets/sounds/` to enable sound; haptics work
/// either way.
class SoundService {
  AudioPool? _tapPool;
  AudioPool? _selectPool;
  AudioPool? _whooshPool;
  AudioPool? _successPool;
  AudioPool? _errorPool;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _tapPool = await _tryCreate('assets/sounds/tap.mp3', maxPlayers: 4);
    _selectPool = await _tryCreate('assets/sounds/select.mp3', maxPlayers: 2);
    _whooshPool = await _tryCreate('assets/sounds/whoosh.mp3', maxPlayers: 2);
    _successPool = await _tryCreate('assets/sounds/success.mp3', maxPlayers: 1);
    _errorPool = await _tryCreate('assets/sounds/error.mp3', maxPlayers: 1);
  }

  Future<AudioPool?> _tryCreate(String path, {required int maxPlayers}) async {
    try {
      return await AudioPool.createFromAsset(
        path: path,
        maxPlayers: maxPlayers,
      );
    } on Object catch (e) {
      AppLogger.warning('Sound asset unavailable: $path', e);
      return null;
    }
  }

  Future<void> tap() async => _start(_tapPool, 0.6);
  Future<void> select() async => _start(_selectPool, 0.7);
  Future<void> whoosh() async => _start(_whooshPool, 0.7);
  Future<void> success() async => _start(_successPool, 0.8);
  Future<void> error() async => _start(_errorPool, 0.7);

  Future<void> _start(AudioPool? pool, double volume) async {
    if (pool == null) return;
    try {
      await pool.start(volume: volume);
    } on Object catch (e) {
      AppLogger.warning('Sound playback failed', e);
    }
  }

  Future<void> dispose() async {
    await _tapPool?.dispose();
    await _selectPool?.dispose();
    await _whooshPool?.dispose();
    await _successPool?.dispose();
    await _errorPool?.dispose();
  }
}

/// App-wide [SoundService]. Initialized in `main()` before `runApp`.
@Riverpod(keepAlive: true)
SoundService soundService(Ref ref) {
  final SoundService service = SoundService();
  ref.onDispose(service.dispose);
  return service;
}
