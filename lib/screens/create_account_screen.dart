import 'package:flutter/material.dart';

import '../services/authentication_service.dart';
import '../services/onboarding_storage.dart';
import '../theme/neko_colors.dart';
import '../theme/neko_typography.dart';
import '../widgets/neko_buttons.dart';
import '../widgets/neko_text_field.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({
    super.key,
    required this.catName,
    required onAccountCreated,
    required this.onBack,
    required this.onSignIn,
  }) : _onAccountCreated = onAccountCreated;

  final String catName;
  final void Function() _onAccountCreated;
  final VoidCallback onBack;
  final VoidCallback onSignIn;

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!value.contains('@')) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'At least 8 characters';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = await AuthenticationService.signUpWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null) {
        await OnboardingStorage.setHasAccount(true);
        await OnboardingStorage.setLoggedIn(true);

        if (mounted) {
          setState(() => _isLoading = false);
          widget._onAccountCreated();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthenticationService.signInWithGoogle();

      if (user != null) {
        await OnboardingStorage.setHasAccount(true);
        await OnboardingStorage.setLoggedIn(true);
        if (mounted) {
          setState(() => _isLoading = false);
          widget._onAccountCreated();
        }
      } else {
        // User cancelled
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: NekoColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: NekoColors.textPrimary),
          onPressed: widget.onBack,
        ),
      ),
      body: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: NekoColors.surface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [NekoColors.cardShadow],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // NekoChan removed
                        Text(
                          "Save ${widget.catName}'s profile",
                          style: NekoTypography.title(size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "We'll keep everything safe.",
                          style: NekoTypography.body(
                            size: 14,
                            color: NekoColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  GoogleSignInButton(
                    compact: false,
                    onPressed: _isLoading ? () {} : _googleSignIn,
                  ),
                  const AuthDivider(),
                  NekoTextField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  NekoTextField(
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: true,
                    validator: _validatePassword,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  NekoTextField(
                    label: 'Confirm Password',
                    controller: _confirmController,
                    obscureText: true,
                    validator: _validateConfirm,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 32),
                  NekoPillButton(
                    label: "Create ${widget.catName}'s Profile",
                    onPressed: _createAccount,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      style: NekoTypography.caption(size: 11, color: NekoColors.textSecondary),
                      children: [
                        const TextSpan(text: 'By continuing, you agree to our '),
                        TextSpan(
                          text: 'Terms',
                          style: NekoTypography.caption(size: 11, color: NekoColors.primary)
                              .copyWith(decoration: TextDecoration.underline),
                        ),
                        const TextSpan(text: ' & '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: NekoTypography.caption(size: 11, color: NekoColors.primary)
                              .copyWith(decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: widget.onSignIn,
                      child: Text.rich(
                        TextSpan(
                          style: NekoTypography.body(size: 14, color: NekoColors.textSecondary),
                          children: [
                            const TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Sign in',
                              style: NekoTypography.label(size: 14, color: NekoColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
