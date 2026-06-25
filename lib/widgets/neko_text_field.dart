import 'package:flutter/material.dart';

import '../theme/neko_colors.dart';
import '../theme/neko_typography.dart';

class NekoTextField extends StatefulWidget {
  const NekoTextField({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.textInputAction,
  });

  final String label;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  @override
  State<NekoTextField> createState() => _NekoTextFieldState();
}

class _NekoTextFieldState extends State<NekoTextField> {
  late FocusNode _focusNode;
  bool _obscured = true;
  bool _focused = false;
  String? _errorText;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChange);
    widget.controller?.addListener(_validate);
  }

  void _onFocusChange() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  void _validate() {
    if (widget.validator != null) {
      final error = widget.validator!(widget.controller?.text);
      setState(() {
        _errorText = error;
        _isValid = error == null && (widget.controller?.text.isNotEmpty ?? false);
      });
    } else {
      setState(() {
        _isValid = widget.controller?.text.isNotEmpty ?? false;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    widget.controller?.removeListener(_validate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showPasswordToggle = widget.obscureText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            boxShadow: _focused ? [NekoColors.focusGlow] : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText && _obscured,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: (value) {
              _validate();
              widget.onChanged?.call(value);
            },
            style: NekoTypography.body(size: 16),
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: NekoTypography.caption(
                color: _focused ? NekoColors.primary : NekoColors.textSecondary,
              ),
              floatingLabelStyle: NekoTypography.caption(color: NekoColors.primary),
              suffixIcon: showPasswordToggle
                  ? IconButton(
                      icon: Icon(
                        _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: NekoColors.primary,
                      ),
                      onPressed: () => setState(() => _obscured = !_obscured),
                    )
                  : _isValid
                      ? Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Icon(Icons.check_circle, color: NekoColors.success, size: 22),
                        )
                      : null,
              errorText: null,
            ),
          ),
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 8),
            child: Text(
              _errorText!,
              style: NekoTypography.caption(size: 12, color: NekoColors.accent),
            ),
          ),
      ],
    );
  }
}

class PersonalityChip extends StatefulWidget {
  const PersonalityChip({
    super.key,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<PersonalityChip> createState() => _PersonalityChipState();
}

class _PersonalityChipState extends State<PersonalityChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _popController;
  late Animation<double> _popScale;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _popScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.05), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _popController, curve: Curves.elasticOut));
  }

  @override
  void didUpdateWidget(PersonalityChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.selected && widget.selected) {
      _popController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _popScale,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.selected ? _popScale.value : 1.0,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: widget.selected ? NekoColors.primary : NekoColors.surface,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: widget.selected
                    ? NekoColors.primary
                    : NekoColors.secondary.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    style: NekoTypography.label(
                      size: 13,
                      color: widget.selected ? Colors.white : NekoColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
