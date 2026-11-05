import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../theme/app_typography.dart';
import '../theme/theme_extension.dart';

enum GhostButtonVariant {
  primary,
  secondary,
  outline,
  destructive,
  ghost,
}

class GhostButton extends StatefulWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = GhostButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48.0,
    this.haptic = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final GhostButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final bool haptic;

  @override
  State<GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<GhostButton> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  void _handleTapDown(TapDownDetails details) {
    if (!_isEnabled) return;
    setState(() => _isPressed = true);
    if (widget.haptic) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isEnabled) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (!_isEnabled) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ghostColors;

    Color backgroundColor;
    Color foregroundColor;
    Border? border;
    Gradient? gradient;
    List<BoxShadow>? shadows;

    switch (widget.variant) {
      case GhostButtonVariant.primary:
        gradient = _isEnabled ? AppColors.sentBubbleGradient : null;
        backgroundColor = _isEnabled ? AppColors.primary : colors.muted;
        foregroundColor = Colors.white;
        shadows = _isEnabled && colors.isDark ? AppColors.darkGlowShadow : null;
        break;
      case GhostButtonVariant.secondary:
        backgroundColor = colors.elevated;
        foregroundColor = colors.text;
        break;
      case GhostButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = colors.text;
        border = Border.all(color: colors.border);
        break;
      case GhostButtonVariant.destructive:
        backgroundColor = AppColors.danger;
        foregroundColor = Colors.white;
        break;
      case GhostButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = colors.text;
        break;
    }

    final child = AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: AppConstants.durationFast,
      curve: AppConstants.defaultCurve,
      child: AnimatedOpacity(
        duration: AppConstants.durationFast,
        opacity: _isEnabled ? 1.0 : 0.5,
        child: Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: gradient == null ? backgroundColor : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppConstants.radiusButton),
            border: border,
            boxShadow: shadows,
          ),
          child: Row(
            mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading) ...[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                  ),
                ),
                const SizedBox(width: AppConstants.space8),
              ] else if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: AppConstants.space8),
              ],
              Text(
                widget.label,
                style: AppTypography.bodyMedium.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _isEnabled ? widget.onPressed : null,
      behavior: HitTestBehavior.opaque,
      child: widget.isFullWidth ? SizedBox(width: double.infinity, child: child) : child,
    );
  }
}

