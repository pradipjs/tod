import 'dart:math';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Animated game background with floating particles and gradient.
class GameBackground extends StatefulWidget {
  final Widget child;
  final bool showParticles;
  final List<Color>? gradientColors;

  const GameBackground({
    super.key,
    required this.child,
    this.showParticles = true,
    this.gradientColors,
  });

  @override
  State<GameBackground> createState() => _GameBackgroundState();
}

class _GameBackgroundState extends State<GameBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Generate particles
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 4 + 2,
        speed: _random.nextDouble() * 0.3 + 0.1,
        color: AppColors.categoryColors[_random.nextInt(AppColors.categoryColors.length)]
            .withValues(alpha: 0.3),
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = widget.gradientColors ?? AppColors.backgroundGradient;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: widget.showParticles
          ? AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _controller.value,
                  ),
                  child: child,
                );
              },
              child: widget.child,
            )
          : widget.child,
    );
  }
}

class _Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final y = (particle.y + progress * particle.speed) % 1.0;
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Neon glow container for game elements.
class NeonContainer extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double borderRadius;
  final double glowIntensity;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const NeonContainer({
    super.key,
    required this.child,
    this.glowColor = AppColors.primary,
    this.borderRadius = 20,
    this.glowIntensity = 0.5,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.darkCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: glowColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: glowIntensity * 0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: glowColor.withValues(alpha: glowIntensity * 0.1),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Gradient text for headings.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final List<Color> colors;

  const GradientText({
    super.key,
    required this.text,
    this.style,
    this.colors = AppColors.primaryGradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(text, style: style),
    );
  }
}

/// Animated gradient border.
class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final List<Color> colors;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.borderWidth = 2,
    this.colors = AppColors.primaryGradient,
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: SweepGradient(
              colors: [...widget.colors, widget.colors.first],
              transform: GradientRotation(_controller.value * 2 * pi),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.borderWidth),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(widget.borderRadius - widget.borderWidth),
              ),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
