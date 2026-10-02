import 'package:flutter/material.dart';

/// The visual language used only by the complaint-management flow.
abstract final class ComplaintPalette {
  static const navy = Color(0xFF073B6F);
  static const darkNavy = Color(0xFF052B52);
  static const teal = Color(0xFF0B6EAA);
  static const cyan = Color(0xFF18A8C8);
  static const skyBlue = Color(0xFFCBD9E6);
  static const beige = Color(0xFFF5EFEB);
  static const white = Color(0xFFFFFFFF);
  static const ink = darkNavy;
  static const mutedInk = Color(0xFF607284);

  static const primaryGradient = LinearGradient(
    colors: [navy, teal, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const pageGradient = LinearGradient(
    colors: [Color(0xFFF5F8FC), skyBlue, beige],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const cardGradient = LinearGradient(
    colors: [white, Color(0xFFF3F8FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color statusColor(String status) {
    switch (status) {
      case 'Resolved':
        return Colors.green;
      case 'In Progress':
        return Colors.blue;
      case 'Pending':
        return Colors.orange;
      default:
        return mutedInk;
    }
  }

  static ThemeData theme(BuildContext context) {
    final base = Theme.of(context);
    final scheme = ColorScheme.fromSeed(
      seedColor: navy,
      brightness: Brightness.light,
    ).copyWith(
      primary: navy,
      secondary: teal,
      surface: white,
      surfaceContainerHighest: skyBlue,
      onPrimary: white,
      onSecondary: white,
      onSurface: ink,
      outline: teal.withValues(alpha: 0.45),
      outlineVariant: skyBlue,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF5F8FC),
      iconTheme: const IconThemeData(color: darkNavy),
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        foregroundColor: darkNavy,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkNavy),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Color(0xFFE1E8F0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIconColor: teal,
        labelStyle: const TextStyle(color: mutedInk),
        floatingLabelStyle: const TextStyle(color: navy),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E7EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E7EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: teal, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      dividerTheme: const DividerThemeData(color: skyBlue, thickness: 1),
      tabBarTheme: const TabBarThemeData(
        labelColor: teal,
        unselectedLabelColor: darkNavy,
        indicatorColor: teal,
      ),
    );
  }
}
