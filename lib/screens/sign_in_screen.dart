import 'package:flutter/material.dart';

import '../services/authentication_service.dart';
import '../services/onboarding_storage.dart';
import '../theme/neko_colors.dart';
import '../theme/neko_typography.dart';
import '../widgets/neko_buttons.dart';
import '../widgets/neko_text_field.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.onSignedIn,
    required this.onGetStarted,
    this.onBack,
  });

  final VoidCallback onSignedIn;
  final VoidCallback onGetStarted;
  final VoidCallback? onBack;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _catName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCatName();
  }

  Future<void> _loadCatName() async {
    final name = await OnboardingStorage.getCatName();
    if (mounted) setState(() => _catName = name);
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!value.contains('@')) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = await AuthenticationService.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null) {
        await OnboardingStorage.setLoggedIn(true);
        if (mounted) {
          setState(() => _isLoading = false);
          widget.onSignedIn();
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
        await OnboardingStorage.setLoggedIn(true);
        if (mounted) {
          setState(() => _isLoading = false);
          widget.onSignedIn();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final subtitle = _catName != null ? '$_catName missed you' : 'We missed you';

    return Scaffold(
      backgroundColor: NekoColors.background,
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: NekoColors.textPrimary),
                onPressed: widget.onBack,
              )
            : null,
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
                  const SizedBox(height: 16),
                  // NekoChan removed
                  const SizedBox(height: 24),
                  Text(
                    'Welcome back',
                    style: NekoTypography.title(size: 28),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: NekoTypography.body(size: 16, color: NekoColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  GoogleSignInButton(
                    compact: true,
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
                    textInputAction: TextInputAction.done,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Forgot password?',
                        style: NekoTypography.caption(size: 12, color: NekoColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  NekoPillButton(
                    label: 'Sign In',
                    onPressed: _signIn,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: widget.onGetStarted,
                      child: Text.rich(
                        TextSpan(
                          style: NekoTypography.body(size: 14, color: NekoColors.textSecondary),
                          children: [
                            const TextSpan(text: 'New to Neko? '),
                            TextSpan(
                              text: 'Get started',
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
