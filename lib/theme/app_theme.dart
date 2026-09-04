import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Calming, minimal purple-and-yellow palette + shared component theming,
/// used by [MaterialApp.theme]/[MaterialApp.darkTheme] in `main.dart` so
/// every screen (built entirely on default Material widgets — no
/// screen-local colors) picks it up automatically.
///
/// Type pairs an expressive display serif ([_displayFont], for headlines and
/// moments of personality — greetings, empty states) with a clean grotesque
/// ([_bodyFont], for everything read at length) rather than a single
/// Material default, and [heroGradient]/[auroraGradient] give screens a
/// shared vocabulary for the soft gradient accents used across cards, nav,
/// and decorative blobs.
abstract final class AppTheme {
  static TextStyle _displayFont({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
    double? height,
  }) => GoogleFonts.fraunces(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
    fontStyle: FontStyle.normal,
  );

  /// The primary hero gradient: purple through pink into gold. Used for
  /// filled hero surfaces (selected nav pill, mood-tile selection, primary
  /// decorative blobs).
  static LinearGradient heroGradient(ColorScheme scheme) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [scheme.primary, scheme.tertiary, scheme.secondary],
  );

  /// A washed-out version of [heroGradient] for large, low-contrast
  /// background surfaces (decorative blobs, hero card fills) where
  /// on-color text still needs to read as [ColorScheme.onSurface].
  static LinearGradient auroraGradient(ColorScheme scheme) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      scheme.primaryContainer,
      scheme.tertiaryContainer,
      scheme.secondaryContainer,
    ],
  );

  static const _lightScheme = ColorScheme.light(
    primary: Color(0xFF7B6EBD),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFE9E3F7),
    onPrimaryContainer: Color(0xFF362C5C),
    secondary: Color(0xFFE0AC1F),
    onSecondary: Color(0xFF453200),
    secondaryContainer: Color(0xFFFBEAC0),
    onSecondaryContainer: Color(0xFF4A3800),
    tertiary: Color(0xFFD98CA0),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFF7DCE3),
    onTertiaryContainer: Color(0xFF5C2A38),
    error: Color(0xFFBA4949),
    onError: Colors.white,
    surface: Color(0xFFFFFDF8),
    onSurface: Color(0xFF352F3D),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFFBF7EF),
    surfaceContainer: Color(0xFFF6F1E7),
    surfaceContainerHigh: Color(0xFFF0EADC),
    surfaceContainerHighest: Color(0xFFEAE3D2),
    onSurfaceVariant: Color(0xFF6E6779),
    outline: Color(0xFFD3CBE0),
    outlineVariant: Color(0xFFE7E1EF),
    inverseSurface: Color(0xFF352F3D),
    onInverseSurface: Color(0xFFF6F1E7),
    inversePrimary: Color(0xFFC9BEEA),
  );

  static const _darkScheme = ColorScheme.dark(
    primary: Color(0xFFC9BEEA),
    onPrimary: Color(0xFF362C5C),
    primaryContainer: Color(0xFF4F4380),
    onPrimaryContainer: Color(0xFFE9E3F7),
    secondary: Color(0xFFE8C766),
    onSecondary: Color(0xFF3D2E00),
    secondaryContainer: Color(0xFF5A4400),
    onSecondaryContainer: Color(0xFFFBEAC0),
    tertiary: Color(0xFFE8AFC0),
    onTertiary: Color(0xFF4A1F2C),
    tertiaryContainer: Color(0xFF63394A),
    onTertiaryContainer: Color(0xFFF7DCE3),
    error: Color(0xFFE3A0A0),
    onError: Color(0xFF4A1414),
    surface: Color(0xFF201B2B),
    onSurface: Color(0xFFEAE3F0),
    surfaceContainerLowest: Color(0xFF17131F),
    surfaceContainerLow: Color(0xFF1D1826),
    surfaceContainer: Color(0xFF241F30),
    surfaceContainerHigh: Color(0xFF2E2839),
    surfaceContainerHighest: Color(0xFF393143),
    onSurfaceVariant: Color(0xFFC9C1D6),
    outline: Color(0xFF4E4560),
    outlineVariant: Color(0xFF362F44),
    inverseSurface: Color(0xFFEAE3F0),
    onInverseSurface: Color(0xFF201B2B),
    inversePrimary: Color(0xFF7B6EBD),
  );

  static ThemeData get light => _build(_lightScheme);
  static ThemeData get dark => _build(_darkScheme);

  static ThemeData _build(ColorScheme scheme) {
    final baseTextTheme = GoogleFonts.manropeTextTheme(
      ThemeData(brightness: scheme.brightness).textTheme,
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    final textTheme = baseTextTheme.copyWith(
      displayLarge: _displayFont(
        fontSize: 52,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
        letterSpacing: -1,
      ),
      displayMedium: _displayFont(
        fontSize: 40,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
        letterSpacing: -0.5,
      ),
      displaySmall: _displayFont(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      headlineLarge: _displayFont(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      headlineMedium: _displayFont(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      headlineSmall: _displayFont(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,

      appBarTheme: AppBarThemeData(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: _displayFont(
          fontSize: 21,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primaryContainer,
        disabledColor: scheme.surfaceContainerHigh,
        labelStyle: TextStyle(color: scheme.onSurface),
        secondaryLabelStyle: TextStyle(color: scheme.onPrimaryContainer),
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
        elevation: 0,
        shape: const StadiumBorder(),
      ),

      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.primaryContainer,
        thumbColor: scheme.secondary,
        overlayColor: scheme.secondary.withValues(alpha: 0.15),
        valueIndicatorColor: scheme.primary,
        valueIndicatorTextStyle: TextStyle(color: scheme.onPrimary),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        circularTrackColor: scheme.primaryContainer,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      dividerTheme: DividerThemeData(color: scheme.outlineVariant),

      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        textColor: scheme.onSurface,
      ),
    );
  }
}
