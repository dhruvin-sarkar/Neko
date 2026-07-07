/// How safe something is for a cat, parsed from the leading label of Neko's
/// safety-scan reply (`SAFE:` / `CAUTION:` / `DANGER:`).
enum SafetyLevel { safe, caution, danger, unknown }

/// A parsed safety-scan result: the [level] drives the chip colour and icon,
/// [detail] is the explanation shown (and spoken-ready) to the owner.
class SafetyVerdict {
  const SafetyVerdict({required this.level, required this.detail});

  final SafetyLevel level;
  final String detail;

  /// Splits a raw reply like "CAUTION: That looks like a lily…" into the level
  /// and the trailing explanation. Falls back to [SafetyLevel.unknown] with the
  /// whole text as detail if no recognised label leads the reply — so the owner
  /// always sees the model's words, and an unrecognised reply renders as a
  /// neutral "Safety check", never a false green "Looks safe".
  factory SafetyVerdict.parse(String reply) {
    final String trimmed = reply.trim();
    if (trimmed.isEmpty) {
      return const SafetyVerdict(
        level: SafetyLevel.unknown,
        detail: 'Neko couldn’t read that photo. Try again with a clearer shot.',
      );
    }

    // The label must be a WHOLE token at the very start of the first line,
    // followed by a real separator (":" / "-" / "—"). This is deliberately
    // strict: matching a bare "SAFE" prefix would read "Safety first, that's a
    // lily…" (a warning) or "Safe to say it's toxic…" as SAFE and show a green
    // verdict on a lethal item. A reply that doesn't lead with "LABEL:" falls
    // through to the cautious neutral verdict instead.
    final List<String> lines = trimmed.split('\n');
    final String firstLine = lines.first;
    final RegExpMatch? match = RegExp(
      r'^(SAFE|CAUTION|DANGER)\s*[:\-—]',
      caseSensitive: false,
    ).firstMatch(firstLine);

    if (match == null) {
      // A non-empty reply that doesn't lead with a label means the model
      // didn't follow the format — which is exactly what a prompt-injection
      // attempt to dodge a DANGER verdict looks like. Err toward CAUTION (a
      // warning), not a neutral verdict, so a manipulated or off-format reply
      // always lands on the cautious side. Only an explicit "SAFE:" above can
      // ever surface as safe.
      return SafetyVerdict(level: SafetyLevel.caution, detail: trimmed);
    }

    final SafetyLevel level = switch (match.group(1)!.toUpperCase()) {
      'SAFE' => SafetyLevel.safe,
      'CAUTION' => SafetyLevel.caution,
      'DANGER' => SafetyLevel.danger,
      _ => SafetyLevel.unknown,
    };

    // Drop the "LABEL:" from the first line, keep the rest of the reply.
    lines[0] = firstLine.substring(match.end).trim();
    final String detail = lines.join('\n').trim();
    return SafetyVerdict(
      level: level,
      detail: detail.isEmpty ? trimmed : detail,
    );
  }

  String get headline => switch (level) {
    SafetyLevel.safe => 'Looks safe',
    SafetyLevel.caution => 'Be careful',
    SafetyLevel.danger => 'Not safe',
    SafetyLevel.unknown => 'Safety check',
  };
}
