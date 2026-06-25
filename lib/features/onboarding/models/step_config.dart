/// Describes the shared chrome (progress bar + continue button) for a single
/// onboarding step. Derived from the current state by the notifier.
class StepConfig {
  const StepConfig({
    required this.continueLabel,
    required this.canContinue,
    required this.showProgress,
    required this.progressFraction,
    required this.isFinal,
    required this.showChrome,
  });

  /// Label for the continue/primary button (e.g. "Continue" or "Let's go").
  final String continueLabel;

  /// Whether the continue button is enabled for this step.
  final bool canContinue;

  /// Whether the top progress bar is visible (hidden on the welcome step).
  final bool showProgress;

  /// Progress fill from 0.0 to 1.0.
  final double progressFraction;

  /// Whether this is the final step (triggers save instead of advancing).
  final bool isFinal;

  /// Whether the shared scaffold chrome (back arrow, progress, continue
  /// button) is shown. The welcome step manages its own buttons.
  final bool showChrome;
}
