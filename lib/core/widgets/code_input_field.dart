import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../theme/app_typography.dart';
import '../theme/theme_extension.dart';

class CodeInputField extends StatefulWidget {
  const CodeInputField({
    super.key,
    this.length = AppConstants.codeLength,
    this.onCompleted,
    this.onChanged,
    this.hasError = false,
    this.errorMessage,
    this.autofocus = true,
  });

  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final bool hasError;
  final String? errorMessage;
  final bool autofocus;

  @override
  State<CodeInputField> createState() => CodeInputFieldState();
}

class CodeInputFieldState extends State<CodeInputField> with SingleTickerProviderStateMixin {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    if (widget.autofocus && _focusNodes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNodes.first.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant CodeInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      triggerShake();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  void triggerShake() {
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0.0);
  }

  String get code => _controllers.map((c) => c.text).join();

  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    if (_focusNodes.isNotEmpty) {
      _focusNodes.first.requestFocus();
    }
    widget.onChanged?.call('');
    setState(() {});
  }

  void setCode(String rawCode) {
    final clean = _sanitizeInput(rawCode);
    final chars = clean.split('');
    for (int i = 0; i < widget.length; i++) {
      if (i < chars.length) {
        _controllers[i].text = chars[i];
      } else {
        _controllers[i].clear();
      }
    }
    final fullCode = code;
    widget.onChanged?.call(fullCode);
    if (fullCode.length == widget.length) {
      HapticFeedback.mediumImpact();
      widget.onCompleted?.call(fullCode);
      _focusNodes.last.unfocus();
    } else {
      final nextIndex = fullCode.length.clamp(0, widget.length - 1);
      _focusNodes[nextIndex].requestFocus();
    }
    setState(() {});
  }

  String _sanitizeInput(String input) {
    final upper = input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final buffer = StringBuffer();
    for (final char in upper.split('')) {
      if (AppConstants.codeAlphabet.contains(char)) {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  void _onBoxChanged(int index, String value) {
    if (value.length > 1) {
      // Possible paste into a single box
      setCode(value);
      return;
    }

    if (value.isEmpty) {
      widget.onChanged?.call(code);
      setState(() {});
      return;
    }

    final sanitized = _sanitizeInput(value);
    if (sanitized.isEmpty) {
      _controllers[index].clear();
      return;
    }

    _controllers[index].text = sanitized;
    _controllers[index].selection = TextSelection.collapsed(offset: sanitized.length);

    final currentCode = code;
    widget.onChanged?.call(currentCode);

    if (index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (currentCode.length == widget.length) {
      HapticFeedback.mediumImpact();
      _focusNodes[index].unfocus();
      widget.onCompleted?.call(currentCode);
    }
    setState(() {});
  }

  Widget _buildBox(int index, GhostConvColors colors) {
    final controller = _controllers[index];
    final focusNode = _focusNodes[index];
    final isFocused = focusNode.hasFocus;
    final hasValue = controller.text.isNotEmpty;

    Color borderColor;
    if (widget.hasError) {
      borderColor = AppColors.danger;
    } else if (isFocused) {
      borderColor = AppColors.primary;
    } else if (hasValue) {
      borderColor = AppColors.secondary;
    } else {
      borderColor = colors.border;
    }

    return Container(
      width: 36,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(AppConstants.radiusInput),
        border: Border.all(
          color: borderColor,
          width: isFocused || widget.hasError ? 2.0 : 1.0,
        ),
        boxShadow: isFocused && colors.isDark
            ? [
                BoxShadow(
                  color: AppColors.primary.withAlpha(50),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty &&
              index > 0) {
            _focusNodes[index - 1].requestFocus();
            _controllers[index - 1].clear();
            widget.onChanged?.call(code);
            setState(() {});
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          style: AppTypography.codeMedium.copyWith(
            color: widget.hasError ? AppColors.danger : colors.text,
            fontWeight: FontWeight.bold,
          ),
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          textInputAction: index == widget.length - 1 ? TextInputAction.done : TextInputAction.next,
          maxLength: 1,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          onChanged: (val) => _onBoxChanged(index, val),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ghostColors;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // First group of 4 boxes
              for (int i = 0; i < 4; i++) ...[
                _buildBox(i, colors),
                if (i < 3) const SizedBox(width: AppConstants.space8),
              ],
              // Hyphen separator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.space8),
                child: Container(
                  width: 10,
                  height: 2,
                  decoration: BoxDecoration(
                    color: colors.muted,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              // Second group of 4 boxes
              for (int i = 4; i < widget.length; i++) ...[
                _buildBox(i, colors),
                if (i < widget.length - 1) const SizedBox(width: AppConstants.space8),
              ],
            ],
          ),
          if (widget.errorMessage != null && widget.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: AppConstants.space8),
            Text(
              widget.errorMessage!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
