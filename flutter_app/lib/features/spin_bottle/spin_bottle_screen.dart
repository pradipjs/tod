import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/haptics/haptics_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/sound/sound_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/game_provider.dart';
import '../../data/models/player.dart';

/// Spin the bottle screen with an attractive pie chart wheel.
class SpinBottleScreen extends ConsumerStatefulWidget {
  const SpinBottleScreen({super.key});

  @override
  ConsumerState<SpinBottleScreen> createState() => _SpinBottleScreenState();
}

class _SpinBottleScreenState extends ConsumerState<SpinBottleScreen>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  
  double _currentAngle = 0.0;
  double _angularVelocity = 0.0;
  bool _isSpinning = false;
  int? _selectedPlayerIndex;
  Offset? _lastPanPosition;
  double _lastPanAngle = 0.0;

  // Wheel segment colors - vibrant and engaging
  static const List<Color> _wheelColors = [
    Color(0xFFFF4081), // Pink
    Color(0xFF7C4DFF), // Purple
    Color(0xFF00E5FF), // Cyan
    Color(0xFF00E676), // Green
    Color(0xFFFFD600), // Yellow
    Color(0xFFFF6D00), // Orange
    Color(0xFF00B0FF), // Blue
    Color(0xFFE040FB), // Magenta
    Color(0xFFFF1744), // Red
    Color(0xFF64FFDA), // Teal
    Color(0xFFFFAB00), // Amber
    Color(0xFFAA00FF), // Deep Purple
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60fps
    )..addListener(_updateSpin);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _updateSpin() {
    if (!_isSpinning) return;

    setState(() {
      // Apply friction
      _angularVelocity *= AppConstants.spinFriction;
      _currentAngle += _angularVelocity;

      // Normalize angle to 0-2π
      _currentAngle = _currentAngle % (2 * pi);

      // Check if stopped
      if (_angularVelocity.abs() < AppConstants.minAngularVelocity) {
        _isSpinning = false;
        _spinController.stop();
        _onSpinComplete();
      }
    });
  }

  void _onSpinComplete() {
    final gameState = ref.read(gameProvider);
    final players = gameState.session?.players ?? [];
    if (players.isEmpty) return;

    // Calculate which player the bottle points to (bottle points up, so we check top)
    // The bottle tip points in the direction of _currentAngle
    // We need to find which sector this angle falls into
    final sectorAngle = (2 * pi) / players.length;
    
    // Bottle points at _currentAngle from the top (-π/2)
    // Adjust so sector 0 starts at top
    final adjustedAngle = (_currentAngle + pi / 2) % (2 * pi);
    final selectedIndex = (adjustedAngle / sectorAngle).floor() % players.length;

    setState(() {
      _selectedPlayerIndex = selectedIndex;
    });

    // Play sound and haptic
    ref.read(soundServiceProvider).play(SoundEffect.spinStop);
    ref.read(hapticsServiceProvider).spinStop();

    // Update game state
    ref.read(gameProvider.notifier).selectPlayer(selectedIndex);

    // Navigate to question screen after delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        context.push(AppRoutes.question);
      }
    });
  }

  void _spin() {
    if (_isSpinning) return;

    final random = Random();
    // Random velocity between min and max
    _angularVelocity = 0.3 + random.nextDouble() * 0.4;

    setState(() {
      _isSpinning = true;
      _selectedPlayerIndex = null;
    });

    ref.read(soundServiceProvider).play(SoundEffect.spinStart);
    ref.read(hapticsServiceProvider).trigger(HapticType.medium);
    _spinController.repeat();
  }

  void _onPanStart(DragStartDetails details, Offset center) {
    if (_isSpinning) return;
    _lastPanPosition = details.localPosition;
    _lastPanAngle = _getAngleFromCenter(details.localPosition, center);
  }

  void _onPanUpdate(DragUpdateDetails details, Offset center) {
    if (_isSpinning || _lastPanPosition == null) return;

    final currentAngle = _getAngleFromCenter(details.localPosition, center);
    var deltaAngle = currentAngle - _lastPanAngle;

    // Handle wrap-around
    if (deltaAngle > pi) deltaAngle -= 2 * pi;
    if (deltaAngle < -pi) deltaAngle += 2 * pi;

    setState(() {
      _currentAngle += deltaAngle;
      _angularVelocity = deltaAngle * 2; // Amplify for better feel
    });

    _lastPanAngle = currentAngle;
    _lastPanPosition = details.localPosition;
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isSpinning) return;

    // Only spin if there's enough velocity
    if (_angularVelocity.abs() > 0.02) {
      _angularVelocity = _angularVelocity.clamp(-0.6, 0.6);
      
      setState(() {
        _isSpinning = true;
        _selectedPlayerIndex = null;
      });

      ref.read(soundServiceProvider).play(SoundEffect.spinStart);
      ref.read(hapticsServiceProvider).trigger(HapticType.medium);
      _spinController.repeat();
    }

    _lastPanPosition = null;
  }

  double _getAngleFromCenter(Offset position, Offset center) {
    return atan2(position.dy - center.dy, position.dx - center.dx);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gameState = ref.watch(gameProvider);
    final players = gameState.session?.players ?? [];
    final size = MediaQuery.of(context).size;
    
    // Calculate wheel size to fit screen nicely
    final minDimension = min(size.width, size.height);
    final wheelSize = minDimension * 0.75;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.tr('spinBottle'),
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () => context.push(AppRoutes.scoreboard),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Wheel container
                SizedBox(
                  width: wheelSize,
                  height: wheelSize,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final center = Offset(
                        constraints.maxWidth / 2,
                        constraints.maxHeight / 2,
                      );
                      
                      return GestureDetector(
                        onTap: _spin,
                        onPanStart: (details) => _onPanStart(details, center),
                        onPanUpdate: (details) => _onPanUpdate(details, center),
                        onPanEnd: _onPanEnd,
                        child: AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              size: Size(wheelSize, wheelSize),
                              painter: _WheelPainter(
                                players: players,
                                selectedIndex: _selectedPlayerIndex,
                                wheelColors: _wheelColors,
                                bottleAngle: _currentAngle,
                                glowIntensity: _glowAnimation.value,
                                isSpinning: _isSpinning,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Selected player or tap instruction
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _selectedPlayerIndex != null && players.isNotEmpty
                      ? _buildSelectedPlayer(theme, players[_selectedPlayerIndex!])
                      : _buildTapInstruction(theme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTapInstruction(ThemeData theme) {
    return Column(
      key: const ValueKey('instruction'),
      children: [
        Text(
          context.tr('tapToSpin'),
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.tr('swipeToSpin'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white38,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedPlayer(ThemeData theme, Player player) {
    final playerColor = Color(player.avatarColor);
    
    return TweenAnimationBuilder<double>(
      key: ValueKey(player.id),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Column(
            children: [
              // Player avatar with glow
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: playerColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: playerColor.withValues(alpha: 0.6),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    player.avatar,
                    style: const TextStyle(fontSize: 44),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Player name
              Text(
                player.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              // Choose option text
              Text(
                context.tr('chooseOption'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: playerColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for the attractive pie chart wheel with bottle.
class _WheelPainter extends CustomPainter {
  final List<Player> players;
  final int? selectedIndex;
  final List<Color> wheelColors;
  final double bottleAngle;
  final double glowIntensity;
  final bool isSpinning;

  _WheelPainter({
    required this.players,
    this.selectedIndex,
    required this.wheelColors,
    required this.bottleAngle,
    required this.glowIntensity,
    required this.isSpinning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw wheel even if no players (with placeholder segments)
    final displayPlayers = players.isEmpty
        ? List.generate(
            4,
            (i) => Player(
              id: '$i',
              name: 'Player ${i + 1}',
              colorIndex: i,
            ),
          )
        : players;

    final sectorAngle = (2 * pi) / displayPlayers.length;

    // Draw outer glow ring
    _drawOuterGlow(canvas, center, radius);

    // Draw decorative ring
    _drawDecorativeRing(canvas, center, radius);

    // Draw wheel segments
    for (var i = 0; i < displayPlayers.length; i++) {
      // Start from top (-π/2)
      final startAngle = i * sectorAngle - pi / 2;
      final isSelected = i == selectedIndex;
      final color = wheelColors[i % wheelColors.length];

      _drawSegment(
        canvas, 
        center, 
        radius * 0.92, // Slightly smaller for border
        startAngle, 
        sectorAngle, 
        color,
        isSelected,
      );

      // Draw player name in segment
      _drawPlayerName(
        canvas,
        center,
        radius * 0.65,
        startAngle,
        sectorAngle,
        displayPlayers[i].name,
        color,
        isSelected,
      );
    }

    // Draw inner decorative circle
    _drawInnerCircle(canvas, center, radius * 0.25);

    // Draw bottle/arrow pointer
    _drawBottlePointer(canvas, center, radius * 0.4, bottleAngle);

    // Draw center button
    _drawCenterButton(canvas, center, radius * 0.15);

    // Draw indicator at top
    _drawTopIndicator(canvas, center, radius);
  }

  void _drawOuterGlow(Canvas canvas, Offset center, double radius) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: glowIntensity * 0.5),
          AppColors.secondary.withValues(alpha: glowIntensity * 0.3),
          Colors.transparent,
        ],
        stops: const [0.7, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.1));

    canvas.drawCircle(center, radius * 1.1, glowPaint);
  }

  void _drawDecorativeRing(Canvas canvas, Offset center, double radius) {
    // Outer border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, borderPaint);

    // Inner decorative dots
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5);

    const numDots = 36;
    for (var i = 0; i < numDots; i++) {
      final angle = (i / numDots) * 2 * pi - pi / 2;
      final dotCenter = Offset(
        center.dx + (radius - 8) * cos(angle),
        center.dy + (radius - 8) * sin(angle),
      );
      canvas.drawCircle(dotCenter, 2, dotPaint);
    }
  }

  void _drawSegment(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
    Color color,
    bool isSelected,
  ) {
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw segment
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, startAngle, sweepAngle, false)
      ..close();

    // Main fill with solid color for better look
    final fillPaint = Paint()
      ..color = isSelected 
          ? color 
          : color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    // Add inner shadow/depth
    final innerRadius = radius * 0.3;
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
    final innerPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, startAngle, sweepAngle, false)
      ..arcTo(innerRect, startAngle + sweepAngle, -sweepAngle, false)
      ..close();

    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(rect);

    canvas.drawPath(innerPath, shadowPaint);

    // Segment border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: isSelected ? 0.8 : 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3 : 1.5;

    canvas.drawPath(path, borderPaint);

    // Selected glow effect
    if (isSelected) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10);

      canvas.drawPath(path, glowPaint);
    }
  }

  void _drawPlayerName(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
    String name,
    Color color,
    bool isSelected,
  ) {
    // Position text at middle of segment
    final textAngle = startAngle + sweepAngle / 2;
    final textCenter = Offset(
      center.dx + radius * cos(textAngle),
      center.dy + radius * sin(textAngle),
    );

    // Truncate long names
    String displayName = name;
    const maxLength = 10;
    if (name.length > maxLength) {
      displayName = '${name.substring(0, maxLength - 1)}…';
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: displayName,
        style: TextStyle(
          color: Colors.white,
          fontSize: isSelected ? 14 : 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: radius * 0.6);

    // Rotate text to be readable along radius
    canvas.save();
    canvas.translate(textCenter.dx, textCenter.dy);
    
    // Rotate text to align with segment
    var textRotation = textAngle + pi / 2;
    // Flip text if it would be upside down
    if (textAngle > 0 && textAngle < pi) {
      textRotation += pi;
    }
    canvas.rotate(textRotation);
    
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore();
  }

  void _drawInnerCircle(Canvas canvas, Offset center, double radius) {
    // Dark inner circle
    final innerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.darkCard,
          AppColors.darkSurface,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, innerPaint);

    // Border
    final borderPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, borderPaint);
  }

  void _drawBottlePointer(
    Canvas canvas,
    Offset center,
    double length,
    double angle,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    // Bottle shape pointing right (will be rotated)
    final path = Path();
    
    // Bottle body (left side - thicker)
    path.moveTo(-length * 0.3, 0);
    path.lineTo(-length * 0.15, -12);
    path.lineTo(-length * 0.15, 12);
    path.close();

    // Bottle neck and tip (right side - pointer)
    path.moveTo(-length * 0.15, -8);
    path.lineTo(length * 0.6, -4);
    path.lineTo(length, 0); // Tip
    path.lineTo(length * 0.6, 4);
    path.lineTo(-length * 0.15, 8);
    path.close();

    // Gradient fill
    final gradient = LinearGradient(
      colors: [
        AppColors.primary,
        AppColors.secondary,
        AppColors.primary,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: length * 2,
      height: 30,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // Shine effect
    final shinePath = Path();
    shinePath.moveTo(-length * 0.1, -6);
    shinePath.lineTo(length * 0.5, -2);
    shinePath.lineTo(-length * 0.1, -2);
    shinePath.close();

    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    canvas.drawPath(shinePath, shinePaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, borderPaint);

    // Glow effect on tip
    final tipGlow = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(Offset(length, 0), 6, tipGlow);

    canvas.restore();
  }

  void _drawCenterButton(Canvas canvas, Offset center, double radius) {
    // Outer glow
    final glowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawCircle(center, radius + 5, glowPaint);

    // Main button gradient
    final gradient = RadialGradient(
      colors: [
        AppColors.secondary,
        AppColors.primary,
      ],
    );

    final buttonPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius, buttonPaint);

    // Inner highlight
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.4),
          Colors.transparent,
        ],
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, highlightPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, borderPaint);

    // "SPIN" text
    if (!isSpinning) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'SPIN',
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            shadows: const [
              Shadow(
                color: Colors.black26,
                blurRadius: 4,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
    }
  }

  void _drawTopIndicator(Canvas canvas, Offset center, double radius) {
    // Triangle indicator at top pointing down
    final indicatorPath = Path();
    const indicatorSize = 20.0;
    
    indicatorPath.moveTo(center.dx, center.dy - radius + 15);
    indicatorPath.lineTo(center.dx - indicatorSize / 2, center.dy - radius - 5);
    indicatorPath.lineTo(center.dx + indicatorSize / 2, center.dy - radius - 5);
    indicatorPath.close();

    // Glow
    final glowPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(indicatorPath, glowPaint);

    // Fill
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.accent, AppColors.neonGreen],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy - radius),
          width: indicatorSize,
          height: 25,
        ),
      );

    canvas.drawPath(indicatorPath, fillPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(indicatorPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.bottleAngle != bottleAngle ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.glowIntensity != glowIntensity ||
        oldDelegate.isSpinning != isSpinning ||
        oldDelegate.players != players;
  }
}
