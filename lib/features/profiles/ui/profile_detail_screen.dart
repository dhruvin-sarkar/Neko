import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

/// Placeholder cat detail screen. The full profile UI is a later milestone.
class ProfileDetailScreen extends ConsumerWidget {
  const ProfileDetailScreen({super.key, required this.catId});

  final String catId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(leading: const BackButton()),
      body: Center(
        child: Text(
          'Cat profile',
          style: AppTextStyles.headlineLarge,
        ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.15, end: 0),
      ),
    );
  }
}
