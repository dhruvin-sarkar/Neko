import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/services/feedback_service.dart';
import '../../../shared/widgets/auth_divider.dart';
import '../../../shared/widgets/google_sign_in_button.dart';
import '../../../shared/widgets/neko_primary_button.dart';
import '../../../shared/widgets/neko_text_field.dart';
import '../providers/auth_provider.dart';

/// Email/password + Google sign-in. The default landing for signed-out users.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    unawaited(ref.read(feedbackServiceProvider).onTap());
    ref
        .read(authControllerProvider.notifier)
        .signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  void _resetPassword() {
    if (Validators.email(_emailController.text) != null) {
      _showSnack('Enter your email above first, then tap reset.');
      return;
    }
    ref
        .read(authControllerProvider.notifier)
        .resetPassword(_emailController.text);
    _showSnack('If that email has an account, a reset link is on its way.');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next is AsyncError) {
        final Object error = next.error;
        _showSnack(
          error is AppException ? error.message : 'Something went wrong.',
        );
      } else if (next is AsyncData && (previous?.isLoading ?? false)) {
        // Sign-in succeeded; the router will redirect.
        unawaited(ref.read(feedbackServiceProvider).onSuccess());
      }
    });

    final bool isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _LoginHeader(),
                const SizedBox(height: 32),
                GoogleSignInButton(
                  enabled: !isLoading,
                  onPressed: () {
                    unawaited(ref.read(feedbackServiceProvider).onTap());
                    ref
                        .read(authControllerProvider.notifier)
                        .signInWithGoogle();
                  },
                ),
                const AuthDivider(),
                NekoTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                NekoTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: Validators.signInPassword,
                  onSubmitted: (_) => _submit(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading ? null : _resetPassword,
                    child: Text(
                      'Forgot password?',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                NekoPrimaryButton(
                  label: 'Sign in',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 20),
                _RegisterPrompt(
                  onTap: isLoading ? null : () => context.go(Routes.register),
                ),
              ],
            ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.15, end: 0),
          ),
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back', style: AppTextStyles.displayLarge),
        const SizedBox(height: 8),
        Text(
          'Sign in to pick up where you and your cat left off.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _RegisterPrompt extends StatelessWidget {
  const _RegisterPrompt({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onTap,
        child: Text.rich(
          TextSpan(
            style: AppTextStyles.bodyMedium,
            children: [
              const TextSpan(text: 'New to Neko? '),
              TextSpan(
                text: 'Get started',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
