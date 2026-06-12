import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NearoTheme {
  const NearoTheme._();

  static const charcoal = Color(0xFF0B0D12);
  static const night = Color(0xFF070910);
  static const surface = Color(0xFF151922);
  static const elevated = Color(0xFF1E2430);
  static const glass = Color(0xCC151922);
  static const glassBorder = Color(0x22FFFFFF);
  static const gold = Color(0xFFD6A84F);
  static const amber = Color(0xFFFFC46B);
  static const neon = Color(0xFF8A5CFF);
  static const wine = Color(0xFF7B244A);
  static const text = Color(0xFFF7F1E7);
  static const mutedText = Color(0xFF9AA3B2);
  static const danger = Color(0xFFFF5A6A);
  static const success = Color(0xFF40D39C);

  static const pageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF12131C), night, charcoal],
  );

  static List<BoxShadow> glowShadow(Color color, {double opacity = 0.24}) => [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: 28,
      spreadRadius: -6,
      offset: const Offset(0, 14),
    ),
  ];

  static BoxDecoration glassDecoration({
    double radius = 28,
    Color borderColor = glassBorder,
    Color glowColor = neon,
    double glowOpacity = 0.12,
  }) {
    return BoxDecoration(
      color: glass,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: glowShadow(glowColor, opacity: glowOpacity),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: text, displayColor: text);

    return base.copyWith(
      scaffoldBackgroundColor: charcoal,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: neon,
        surface: surface,
        error: danger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: charcoal,
        foregroundColor: text,
        centerTitle: false,
        titleTextStyle: GoogleFonts.montserrat(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: glass,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: glassBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated.withValues(alpha: 0.84),
        hintStyle: const TextStyle(color: mutedText),
        prefixIconColor: mutedText,
        suffixIconColor: mutedText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: gold, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: charcoal,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: neon,
          foregroundColor: text,
          minimumSize: const Size(44, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: neon.withValues(alpha: 0.28),
        labelStyle: const TextStyle(color: text),
        secondaryLabelStyle: const TextStyle(color: text),
        iconTheme: const IconThemeData(color: mutedText, size: 18),
        side: const BorderSide(color: glassBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? text : mutedText,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? neon.withValues(alpha: 0.64)
              : elevated,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: neon,
        unselectedItemColor: mutedText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
