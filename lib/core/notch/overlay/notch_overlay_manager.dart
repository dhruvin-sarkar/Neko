import 'package:flutter/widgets.dart';

import '../widgets/notch_pill.dart';

/// Floats the notch pill above the whole app. Placed in the `MaterialApp.router`
/// builder, so it sits above the Navigator — and therefore above every route
/// and dialog — without needing an [OverlayEntry] (which can't resolve an
/// `Overlay` from the builder's context anyway).
///
/// The app fills the screen via [Positioned.fill]; the pill is aligned to the
/// top-centre and only occupies its own rect, so taps elsewhere fall through.
class NotchOverlayManager extends StatelessWidget {
  const NotchOverlayManager({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(child: child),
        // RepaintBoundary isolates the pill's perpetual animations (idle
        // breathe, call pulse, timer arc) from the full-screen app tree.
        const Align(
          alignment: Alignment.topCenter,
          child: RepaintBoundary(child: NotchPill()),
        ),
      ],
    );
  }
}
