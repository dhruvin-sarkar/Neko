import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Wraps the app and shows a little cat peeking just above the soft keyboard
/// whenever it's open (i.e. while typing). It slides in on appear and out on
/// dismiss, and is wrapped in an [IgnorePointer] so it never intercepts taps on
/// the field or buttons beneath it.
///
/// The Lottie controller only runs while the keyboard is visible, so it costs
/// nothing the rest of the time.
class KeyboardCat extends StatefulWidget {
  const KeyboardCat({super.key, required this.child});

  final Widget child;

  @override
  State<KeyboardCat> createState() => _KeyboardCatState();
}

class _KeyboardCatState extends State<KeyboardCat>
    with TickerProviderStateMixin {
  late final AnimationController _lottie = AnimationController(vsync: this);
  bool _visible = false;
  bool _reduceMotion = false;

  @override
  void dispose() {
    _lottie.dispose();
    super.dispose();
  }

  void _setVisible(bool value) {
    if (value == _visible) return;
    _visible = value;
    if (value && !_reduceMotion) {
      _lottie.repeat();
    } else {
      _lottie.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double inset = MediaQuery.of(context).viewInsets.bottom;
    final bool keyboardOpen = inset > 80;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    // Schedule the playback toggle outside build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _setVisible(keyboardOpen);
    });

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 0,
          right: 12,
          bottom: inset,
          child: IgnorePointer(
            child: AnimatedSlide(
              offset: keyboardOpen ? Offset.zero : const Offset(0, 0.6),
              duration: _reduceMotion
                  ? Duration.zero
                  : Duration(milliseconds: keyboardOpen ? 200 : 150),
              curve: keyboardOpen ? Curves.easeOut : Curves.easeIn,
              child: AnimatedOpacity(
                opacity: keyboardOpen ? 1 : 0,
                duration: _reduceMotion
                    ? Duration.zero
                    : Duration(milliseconds: keyboardOpen ? 200 : 150),
                // Peeks from the far right, above the keyboard, big enough to
                // read but kept off the centre so it never covers what you type.
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: RepaintBoundary(
                    child: Lottie.asset(
                      'assets/animations/cat_typing.json',
                      controller: _lottie,
                      width: 120,
                      onLoaded: (composition) {
                        _lottie.duration = composition.duration;
                        if (_visible && !_reduceMotion) _lottie.repeat();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
