import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Animated button with scale and tap effects.
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Duration duration;
  final double scaleDown;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.duration = const Duration(milliseconds: 100),
    this.scaleDown = 0.95,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

/// Primary game button with neon glow effect.
class GameButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool isOutlined;
  final double? width;
  final List<Color>? gradient;
  final double height;

  const GameButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.isOutlined = false,
    this.width,
    this.gradient,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primary;
    final fgColor = textColor ?? Colors.white;
    final buttonGradient = gradient ?? [bgColor, bgColor.withValues(alpha: 0.8)];

    return AnimatedButton(
      onPressed: onPressed,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: isOutlined ? null : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: buttonGradient,
          ),
          color: isOutlined ? Colors.transparent : null,
          borderRadius: BorderRadius.circular(16),
          border: isOutlined 
              ? Border.all(color: bgColor, width: 2) 
              : Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
          boxShadow: isOutlined || onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -5,
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isOutlined ? bgColor : fgColor,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              text.toUpperCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: isOutlined ? bgColor : fgColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Choice button for truth/dare selection with enhanced gaming style.
class ChoiceButton extends StatelessWidget {
  final String text;
  final String emoji;
  final List<Color> gradientColors;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;

  const ChoiceButton({
    super.key,
    required this.text,
    required this.emoji,
    required this.gradientColors,
    this.onPressed,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedButton(
      onPressed: onPressed,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.6),
              blurRadius: 25,
              offset: const Offset(0, 10),
              spreadRadius: -5,
            ),
            BoxShadow(
              color: gradientColors.last.withValues(alpha: 0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 56),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              text.toUpperCase(),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon button with neon glow.
class NeonIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final double size;

  const NeonIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color = AppColors.primary,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: size * 0.5,
        ),
      ),
    );
  }
}
