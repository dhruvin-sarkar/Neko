import 'package:flutter_test/flutter_test.dart';
import 'package:neko/features/voice/providers/wake_word_controller.dart';

/// Verifies the wake-word matcher's recall (fires on real "Hey Neko" and its
/// common recogniser mishears) and precision (ignores unrelated speech and bare
/// look-alike words), without needing a live recogniser.
void main() {
  group('WakeWordController.matchesWake — should wake', () {
    const List<String> wakes = <String>[
      'hey neko',
      'Hey Neko',
      'HEY NEKO',
      'hey neco',
      'hey necko',
      'hey nekko',
      'hi neko',
      'ok neko', // weak lead + exact mishear
      'okay neko',
      'a neko', // dropped-greeting variant
      'neko', // said on its own
      'necko',
      'heyneko', // fused into one token
      'hey neck', // real greeting + a two-edit look-alike
      'hey nico', // real greeting + the name it mishears as
      'hey niko',
      'um, hey neko — you there?', // embedded in a longer partial
    ];
    for (final String s in wakes) {
      test('"$s"', () => expect(WakeWordController.matchesWake(s), isTrue));
    }
  });

  group('WakeWordController.matchesWake — should NOT wake', () {
    const List<String> ignores = <String>[
      '',
      'neck', // bare look-alike, no greeting
      'a neck', // weak lead can't clear a look-alike
      'let me check my neck',
      'necklace', // whole-word match, not a substring
      'nico', // the bare name must not wake it
      'niko',
      'hello there',
      'the weather is nice today',
      'echo test one two three',
      'i need to go now',
    ];
    for (final String s in ignores) {
      test('"$s"', () => expect(WakeWordController.matchesWake(s), isFalse));
    }
  });
}
