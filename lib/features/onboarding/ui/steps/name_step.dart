import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/neko_text_field.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/step_headline.dart';

/// Step 1 — the cat's name.
class NameStep extends ConsumerStatefulWidget {
  const NameStep({super.key});

  @override
  ConsumerState<NameStep> createState() => _NameStepState();
}

class _NameStepState extends ConsumerState<NameStep> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(onboardingNotifierProvider).draft.name,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepHeadline("What's your cat called?"),
        const SizedBox(height: 28),
        NekoTextField(
          controller: _controller,
          hint: 'Mochi, Luna, Whiskers...',
          autofocus: true,
          textInputAction: TextInputAction.done,
          maxLength: 50,
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
          onChanged: ref.read(onboardingNotifierProvider.notifier).setName,
        ),
      ],
    );
  }
}
