import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

import '../../core/utils/logger.dart';

/// The Neko mascot.
///
/// Tries to load `assets/animations/neko.riv`; until a real Rive file is
/// dropped in (the current asset is a placeholder), it renders [fallback].
/// When the real file arrives, wire its `StateMachineController` here.
class NekoMascot extends StatefulWidget {
  const NekoMascot({super.key, required this.size, required this.fallback});

  final double size;
  final Widget fallback;

  @override
  State<NekoMascot> createState() => _NekoMascotState();
}

class _NekoMascotState extends State<NekoMascot> {
  static const String _asset = 'assets/animations/neko.riv';
  late final Future<rive.RiveFile?> _file = _load();

  Future<rive.RiveFile?> _load() async {
    try {
      return await rive.RiveFile.asset(_asset);
    } on Object catch (e) {
      AppLogger.warning('Rive mascot unavailable; using fallback', e);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: FutureBuilder<rive.RiveFile?>(
        future: _file,
        builder: (context, snapshot) {
          final bool ready =
              snapshot.connectionState == ConnectionState.done &&
              snapshot.data != null;
          if (!ready) return widget.fallback;
          return rive.RiveAnimation.asset(_asset, fit: BoxFit.contain);
        },
      ),
    );
  }
}
