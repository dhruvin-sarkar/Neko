import 'package:flutter_test/flutter_test.dart';
import 'package:neko/features/safety/models/safety_verdict.dart';

void main() {
  group('SafetyVerdict.parse', () {
    test('reads a well-formed label and strips it from the detail', () {
      final SafetyVerdict v = SafetyVerdict.parse(
        'CAUTION: That looks like a lily, which is toxic to cats.',
      );
      expect(v.level, SafetyLevel.caution);
      expect(v.detail, 'That looks like a lily, which is toxic to cats.');
    });

    test('accepts SAFE / DANGER labels', () {
      expect(
        SafetyVerdict.parse('SAFE: Plain cooked chicken is fine.').level,
        SafetyLevel.safe,
      );
      expect(
        SafetyVerdict.parse('DANGER: Chocolate is toxic to cats.').level,
        SafetyLevel.danger,
      );
    });

    test('accepts dash and em-dash separators', () {
      expect(
        SafetyVerdict.parse('DANGER - lilies are deadly.').level,
        SafetyLevel.danger,
      );
      expect(
        SafetyVerdict.parse('CAUTION — hard to tell, better ask a vet.').level,
        SafetyLevel.caution,
      );
    });

    test('is case-insensitive on the label', () {
      expect(
        SafetyVerdict.parse('safe: catnip is fine in moderation.').level,
        SafetyLevel.safe,
      );
    });

    // The reason the parser exists: a WARNING that merely begins with the
    // letters "safe" must never be shown as a green "Looks safe" verdict. An
    // off-format reply like this errs to CAUTION (a warning), never safe.
    test('does NOT read "Safety first…" as safe', () {
      final SafetyVerdict v = SafetyVerdict.parse(
        "Safety first — that's a lily, and lilies are highly toxic to cats. "
        'Contact your vet or animal poison control right away.',
      );
      expect(v.level, isNot(SafetyLevel.safe));
      expect(v.level, SafetyLevel.caution);
    });

    test('does NOT read "Safe to say…" as safe', () {
      final SafetyVerdict v = SafetyVerdict.parse(
        "Safe to say that's toxic — keep it away from your cat.",
      );
      expect(v.level, isNot(SafetyLevel.safe));
    });

    test('a label followed by whitespace only (no separator) is not a match', () {
      // "SAFE TO SAY" — SAFE followed by a space, not a separator.
      final SafetyVerdict v = SafetyVerdict.parse(
        'SAFE TO SAY this plant is a hazard, ask your vet.',
      );
      expect(v.level, isNot(SafetyLevel.safe));
    });

    // A non-empty reply that doesn't lead with a label errs to CAUTION — this
    // is the prompt-injection backstop: a manipulated reply engineered to skip
    // the DANGER label can never surface as safe, and never as a reassuring
    // neutral verdict. The model's full text is still shown.
    test('an unlabelled reply falls through to CAUTION with the full text', () {
      final SafetyVerdict v = SafetyVerdict.parse(
        'That looks like catnip, which cats love and is perfectly fine.',
      );
      expect(v.level, SafetyLevel.caution);
      expect(v.detail, contains('catnip'));
    });

    test('label on its own line keeps the rest as detail', () {
      final SafetyVerdict v = SafetyVerdict.parse(
        'DANGER:\nThat is a sago palm, which is extremely toxic to cats.',
      );
      expect(v.level, SafetyLevel.danger);
      expect(v.detail, 'That is a sago palm, which is extremely toxic to cats.');
    });

    test('empty reply returns a friendly unknown', () {
      final SafetyVerdict v = SafetyVerdict.parse('   ');
      expect(v.level, SafetyLevel.unknown);
      expect(v.detail, isNotEmpty);
    });
  });
}
