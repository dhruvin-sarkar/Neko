import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// A themed text field with a coral focus glow, a check icon when valid, and an
/// optional password visibility toggle. Borders and radii come from the app
/// [InputDecorationTheme]; this widget adds the focus glow and validation
/// affordances on top.
class NekoTextField extends StatefulWidget {
  const NekoTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.maxLength,
    this.inputFormatters,
    this.suffixText,
    this.showValidCheck = true,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? suffixText;
  final bool showValidCheck;

  @override
  State<NekoTextField> createState() => _NekoTextFieldState();
}

class _NekoTextFieldState extends State<NekoTextField> {
  late final FocusNode _focusNode;
  bool _obscured = true;
  bool _focused = false;
  String? _errorText;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChange);
    widget.controller?.addListener(_revalidate);
  }

  void _onFocusChange() => setState(() => _focused = _focusNode.hasFocus);

  void _revalidate() {
    final String text = widget.controller?.text ?? '';
    final String? error = widget.validator?.call(text);
    setState(() {
      _errorText = error;
      _isValid = error == null && text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    widget.controller?.removeListener(_revalidate);
    super.dispose();
  }

  Widget? _buildSuffix() {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.textSecondary,
        ),
        onPressed: () => setState(() => _obscured = !_obscured),
        tooltip: _obscured ? 'Show password' : 'Hide password',
      );
    }
    if (widget.suffixText != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Text(
          widget.suffixText!,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    if (widget.showValidCheck && _isValid) {
      return const Padding(
        padding: EdgeInsets.only(right: 16),
        child: Icon(Icons.check_circle, color: AppColors.success, size: 22),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            obscureText: widget.obscureText && _obscured,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            style: AppTextStyles.bodyLarge,
            cursorColor: AppColors.primary,
            onChanged: (value) {
              _revalidate();
              widget.onChanged?.call(value);
            },
            onFieldSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              counterText: '',
              floatingLabelStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
              suffixIcon: _buildSuffix(),
            ),
          ),
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 6),
            child: Text(
              _errorText!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
      ],
    );
  }
}
