import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// A themed text field with a coral focus glow, a check icon when valid, and an
/// optional password visibility toggle.
///
/// All view state (focus, validity, obscured) is driven by listenables rather
/// than `setState`, so rebuilds stay scoped to this field.
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
  final FocusNode _focusNode = FocusNode();
  final ValueNotifier<bool> _obscured = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _focusNode.dispose();
    _obscured.dispose();
    super.dispose();
  }

  Widget? _suffix({required bool obscured, required bool isValid}) {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.textSecondary,
        ),
        onPressed: () => _obscured.value = !_obscured.value,
        tooltip: obscured ? 'Show password' : 'Hide password',
      );
    }
    final String? suffixText = widget.suffixText;
    if (suffixText != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Text(
          suffixText,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    if (widget.showValidCheck && isValid) {
      return const Padding(
        padding: EdgeInsets.only(right: 16),
        child: Icon(Icons.check_circle, color: AppColors.success, size: 22),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final Listenable merged = Listenable.merge(<Listenable?>[
      _focusNode,
      widget.controller,
      _obscured,
    ]);

    return ListenableBuilder(
      listenable: merged,
      builder: (context, _) {
        final String text = widget.controller?.text ?? '';
        final String? error = widget.validator?.call(text);
        final bool isValid = error == null && text.isNotEmpty;
        final bool focused = _focusNode.hasFocus;
        final bool obscured = _obscured.value;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: focused
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
            obscureText: widget.obscureText && obscured,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            validator: widget.validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: AppTextStyles.bodyLarge,
            cursorColor: AppColors.primary,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              counterText: '',
              floatingLabelStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
              errorStyle: AppTextStyles.caption.copyWith(
                color: AppColors.primaryDark,
              ),
              suffixIcon: _suffix(obscured: obscured, isValid: isValid),
            ),
          ),
        );
      },
    );
  }
}
