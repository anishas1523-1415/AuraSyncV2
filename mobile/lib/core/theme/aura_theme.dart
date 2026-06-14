import 'package:flutter/material.dart';
import 'dart:ui';

class AuraTheme {
  // Dark Cyberpunk / Neon aesthetics base colors
  static const Color backgroundDark = Color(0xFF0D0D12);
  static const Color backgroundCard = Color(0xFF1A1A24);
  
  // Neon Accents
  static const Color neonPurple = Color(0xFFB026FF);
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonPink = Color(0xFFFF0066);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      fontFamily: 'Inter', // Make sure to add this to pubspec.yaml
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -1.2),
        bodyLarge: TextStyle(color: Colors.white70, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.white54, fontSize: 14),
      ),
    );
  }

  // Dynamic Mood Gradient Generator
  static BoxDecoration getMoodGradient(String moodVibe) {
    List<Color> colors;
    switch (moodVibe) {
      case 'Energetic Sync':
        colors = [neonPink.withOpacity(0.4), neonPurple.withOpacity(0.1), backgroundDark];
        break;
      case 'Chill Discovery':
        colors = [neonCyan.withOpacity(0.3), neonPurple.withOpacity(0.1), backgroundDark];
        break;
      default:
        colors = [Colors.grey.withOpacity(0.2), backgroundDark];
    }

    return BoxDecoration(
      gradient: RadialGradient(
        center: const Alignment(0, -0.4),
        radius: 1.2,
        colors: colors,
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }
}
