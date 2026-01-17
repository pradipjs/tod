import 'package:flutter/material.dart';

/// Application color constants.
/// 
/// Contains vibrant game-themed colors used throughout the app.
class AppColors {
  AppColors._();

  // Game mode colors - vibrant neon style
  static const Color kidsMode = Color(0xFF00E676);
  static const Color teenMode = Color(0xFFFFD600);
  static const Color adultMode = Color(0xFFFF1744);

  // Question type colors - bold and eye-catching
  static const Color truth = Color(0xFF00B0FF);
  static const Color dare = Color(0xFFFF4081);

  // Status colors
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFAB00);
  static const Color error = Color(0xFFFF1744);
  static const Color info = Color(0xFF00B0FF);

  // Primary colors - vibrant purple/pink gaming theme
  static const Color primary = Color(0xFF7C4DFF);
  static const Color secondary = Color(0xFFE040FB);
  static const Color accent = Color(0xFF00E5FF);

  // Dark theme background colors
  static const Color darkBg = Color(0xFF0D0D1A);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);

  // Special colors
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonPink = Color(0xFFFF10F0);
  static const Color neonBlue = Color(0xFF00FFFF);
  static const Color neonPurple = Color(0xFF7C4DFF);

  // Gradient colors - vibrant gaming gradients
  static const List<Color> primaryGradient = [
    Color(0xFF7C4DFF),
    Color(0xFFE040FB),
  ];

  static const List<Color> truthGradient = [
    Color(0xFF00B0FF),
    Color(0xFF00E5FF),
  ];

  static const List<Color> dareGradient = [
    Color(0xFFFF4081),
    Color(0xFFFF1744),
  ];

  static const List<Color> goldGradient = [
    Color(0xFFFFD700),
    Color(0xFFFFA000),
  ];

  static const List<Color> backgroundGradient = [
    Color(0xFF0D0D1A),
    Color(0xFF1A1A2E),
    Color(0xFF16213E),
  ];

  static const List<Color> neonPurpleGradient = [
    Color(0xFF7C4DFF),
    Color(0xFFB388FF),
  ];

  static const List<Color> neonPinkGradient = [
    Color(0xFFFF4081),
    Color(0xFFFF80AB),
  ];

  static const List<Color> neonBlueGradient = [
    Color(0xFF00B0FF),
    Color(0xFF80D8FF),
  ];

  static const List<Color> fireGradient = [
    Color(0xFFFF6D00),
    Color(0xFFFF1744),
    Color(0xFFFFD600),
  ];

  // Category colors - unique vibrant color per category
  static const List<Color> categoryColors = [
    Color(0xFFFF4081), // Pink
    Color(0xFF7C4DFF), // Purple
    Color(0xFF00E5FF), // Cyan
    Color(0xFF00E676), // Green
    Color(0xFFFFD600), // Yellow
    Color(0xFFFF6D00), // Orange
    Color(0xFF00B0FF), // Blue
    Color(0xFFE040FB), // Magenta
  ];

  // Avatar colors - vibrant player colors
  static const List<Color> avatarColors = [
    Color(0xFFFF4081),
    Color(0xFFFF6D00),
    Color(0xFFFFD600),
    Color(0xFF00E676),
    Color(0xFF00E5FF),
    Color(0xFF00B0FF),
    Color(0xFF7C4DFF),
    Color(0xFFE040FB),
  ];
}
