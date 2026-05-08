import 'package:flutter/material.dart';

/// WhatsApp-style color palette and [ThemeData] for the app.
///
/// Provides both a light theme and a dark theme. The primary brand colour is
/// the iconic WhatsApp teal/green (#25D366 for the icon, #128C7E for the
/// darker action bar variant).
abstract final class AppTheme {
  // ---------------------------------------------------------------------------
  // Brand colours
  // ---------------------------------------------------------------------------

  /// Primary teal-green used for FABs, active icons, and send buttons.
  static const Color primaryGreen = Color(0xFF25D366);

  /// Darker teal used for the app bar and header backgrounds (light mode).
  static const Color darkTeal = Color(0xFF128C7E);

  /// Even darker teal for status bar / system UI overlay.
  static const Color deepTeal = Color(0xFF075E54);

  /// Accent blue used for links and read-receipt ticks.
  static const Color accentBlue = Color(0xFF34B7F1);

  // ---------------------------------------------------------------------------
  // Light theme surface colours
  // ---------------------------------------------------------------------------
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF0F0F0);
  static const Color lightChatBackground = Color(0xFFECE5DD);
  static const Color lightMessageBubbleSent = Color(0xFFDCF8C6);
  static const Color lightMessageBubbleReceived = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Dark theme surface colours
  // ---------------------------------------------------------------------------
  static const Color darkBackground = Color(0xFF111B21);
  static const Color darkSurface = Color(0xFF1F2C34);
  static const Color darkChatBackground = Color(0xFF0D1418);
  static const Color darkMessageBubbleSent = Color(0xFF005C4B);
  static const Color darkMessageBubbleReceived = Color(0xFF1F2C34);

  // ---------------------------------------------------------------------------
  // Text colours
  // ---------------------------------------------------------------------------
  static const Color lightTextPrimary = Color(0xFF111111);
  static const Color lightTextSecondary = Color(0xFF667781);
  static const Color darkTextPrimary = Color(0xFFE9EDEF);
  static const Color darkTextSecondary = Color(0xFF8696A0);

  // ---------------------------------------------------------------------------
  // Light ThemeData
  // ---------------------------------------------------------------------------

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: darkTeal,
      onPrimary: Colors.white,
      primaryContainer: deepTeal,
      onPrimaryContainer: Colors.white,
      secondary: primaryGreen,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFB2DFDB),
      onSecondaryContainer: Color(0xFF004D40),
      tertiary: accentBlue,
      onTertiary: Colors.white,
      error: Color(0xFFB00020),
      onError: Colors.white,
      surface: lightBackground,
      onSurface: lightTextPrimary,
      surfaceContainerHighest: lightSurface,
      onSurfaceVariant: lightTextSecondary,
      outline: Color(0xFFCCCCCC),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightBackground,
        selectedItemColor: darkTeal,
        unselectedItemColor: lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xB3FFFFFF),
        indicatorColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: darkTeal),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 0.5,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dark ThemeData
  // ---------------------------------------------------------------------------

  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primaryGreen,
      onPrimary: Colors.black,
      primaryContainer: darkTeal,
      onPrimaryContainer: Colors.white,
      secondary: primaryGreen,
      onSecondary: Colors.black,
      secondaryContainer: Color(0xFF004D40),
      onSecondaryContainer: Color(0xFFB2DFDB),
      tertiary: accentBlue,
      onTertiary: Colors.black,
      error: Color(0xFFCF6679),
      onError: Colors.black,
      surface: darkBackground,
      onSurface: darkTextPrimary,
      surfaceContainerHighest: darkSurface,
      onSurfaceVariant: darkTextSecondary,
      outline: Color(0xFF3B4A54),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: darkTextPrimary),
        actionsIconTheme: IconThemeData(color: darkTextPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryGreen,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryGreen,
        unselectedLabelColor: darkTextSecondary,
        indicatorColor: primaryGreen,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.black,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        hintStyle: const TextStyle(color: darkTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryGreen),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3B4A54),
        thickness: 0.5,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
