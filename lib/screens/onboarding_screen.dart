import 'package:flutter/material.dart';

import '../services/onboarding_storage.dart';
import '../theme/neko_colors.dart';
import '../theme/neko_typography.dart';
import '../widgets/neko_buttons.dart';
import '../widgets/neko_text_field.dart';
import '../widgets/particle_effects.dart';

enum OnboardingStep { nameCat, personality }

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onComplete,
    required this.onBack,
  });

  final void Function(String catName, List<String> personalities) onComplete;
  final VoidCallback onBack;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  OnboardingStep _step = OnboardingStep.nameCat;
  late AnimationController _stepController;
  late Animation<double> _stepFade;

  final _nameController = TextEditingController();
  final GlobalKey<ParticleEffectState> _confettiKey = GlobalKey();
  bool _showConfetti = false;

  final _personalities = [
    ('Adventurous', ''),
    ('A total napper', ''),
    ('Sassy queen', ''),
    ('Drama queen', ''),
  ];
  final Set<String> _selectedPersonalities = {};

  @override
  void initState() {
    super.initState();
    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _stepFade = CurvedAnimation(parent: _stepController, curve: Curves.easeOut);
    _stepController.forward();
  }

  Future<void> _goToPersonality() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() {
      _showConfetti = true;
    });
    _confettiKey.currentState?.burst();
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    await _stepController.reverse();
    setState(() {
      _step = OnboardingStep.personality;
      _showConfetti = false;
    });
    await _stepController.forward();
  }

  Future<void> _completeOnboarding() async {
    if (_selectedPersonalities.isEmpty) return;

    final name = _nameController.text.trim();
    final personalities = _selectedPersonalities.toList();
    await OnboardingStorage.saveCatName(name);
    await OnboardingStorage.savePersonalities(personalities);
    widget.onComplete(name, personalities);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NekoColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: NekoColors.textPrimary),
          onPressed: widget.onBack,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FadeTransition(
            opacity: _stepFade,
            child: _step == OnboardingStep.nameCat
                ? _buildNameStep()
                : _buildPersonalityStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          'First, tell us about your cat',
          style: NekoTypography.title(size: 24),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(
              height: 120,
              // NekoChan removed
            ),
            if (_showConfetti)
              Positioned.fill(
                child: ParticleEffect(
                  key: _confettiKey,
                  type: ParticleEffectType.confetti,
                ),
              ),
          ],
        ),
        const SizedBox(height: 32),
        NekoTextField(
          label: "Cat's name",
          controller: _nameController,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
        ),
        const Spacer(),
        NekoPillButton(
          label: 'Continue',
          enabled: _nameController.text.trim().isNotEmpty,
          onPressed: _goToPersonality,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPersonalityStep() {
    final catName = _nameController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          "What's $catName like?",
          style: NekoTypography.title(size: 24),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Select all that apply',
          style: NekoTypography.body(size: 14, color: NekoColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        // NekoChan removed from center
        const SizedBox(height: 32),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          physics: const NeverScrollableScrollPhysics(),
          children: _personalities.map((p) {
            final key = p.$1;
            return PersonalityChip(
              emoji: p.$2,
              label: key,
              selected: _selectedPersonalities.contains(key),
              onTap: () {
                setState(() {
                  if (_selectedPersonalities.contains(key)) {
                    _selectedPersonalities.remove(key);
                  } else {
                    _selectedPersonalities.add(key);
                  }
                });
              },
            );
          }).toList() as List<Widget>,
        ),
        const Spacer(),
        NekoPillButton(
          label: 'Continue',
          enabled: _selectedPersonalities.isNotEmpty,
          onPressed: _completeOnboarding,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
