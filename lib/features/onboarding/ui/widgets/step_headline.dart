import 'package:flutter/material.dart';

import '../../../../app/theme/app_text_styles.dart';

/// The bold headline shown at the top of each onboarding question.
class StepHeadline extends StatelessWidget {
  const StepHeadline(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.displayLarge);
  }
}
