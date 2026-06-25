import 'package:flutter/material.dart';

import '../services/onboarding_storage.dart';
import '../theme/neko_colors.dart';
import '../theme/neko_typography.dart';
import '../widgets/animated_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _catName;
  List<String> _personalities = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final name = await OnboardingStorage.getCatName();
    final personalities = await OnboardingStorage.getPersonalities();
    if (mounted) {
      setState(() {
        _catName = name;
        _personalities = personalities;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NekoColors.background,
      body: AnimatedBackground(
        primaryColor: NekoColors.primary,
        secondaryColor: NekoColors.secondary,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _catName != null ? 'Hello, $_catName! 🐱' : 'Welcome to Neko',
                    style: NekoTypography.title(size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your smart cat tracker hub',
                    style: NekoTypography.body(color: NekoColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  // Quick stats or tracker cards could go here
                  _buildTrackerSection(),
                  if (_personalities.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text('Personality Traits', style: NekoTypography.label()),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _personalities.map((p) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: NekoColors.surface,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(p, style: NekoTypography.caption(size: 13)),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackerSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: NekoColors.primary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Track & Monitor',
                style: NekoTypography.label(),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: NekoColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Live',
                  style: NekoTypography.caption(
                    size: 11,
                    color: NekoColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Monitor your cat\'s activity, location, and well-being in real-time.',
            style: NekoTypography.body(
              size: 13,
              color: NekoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
