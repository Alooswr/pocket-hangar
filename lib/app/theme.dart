import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Design tokens: palette C (Radix Slate + Cyan), dark variant, from the team UI spec.
/// One accent colour, used only for the primary button, links, selected state and focus ring.
/// Contrast (WCAG 2.2): text 16.25:1, muted 8.45:1, control border 3.43:1, button text 6.28:1.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.hairline,
    required this.controlBorder,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.link,
    required this.danger,
    required this.like,
    required this.success,
    required this.warning,
  });

  final Color bg;
  final Color surface; // level 1: cards, sheets
  final Color surface2; // level 2: pressed / hover, inputs
  final Color surface3; // level 3: selected rows, chips
  final Color hairline;
  final Color controlBorder;
  final Color text;
  final Color textMuted;
  final Color accent;
  final Color onAccent;
  final Color link;
  final Color danger;
  final Color like;
  final Color success;
  final Color warning;

  static const dark = AppTokens(
    bg: Color(0xFF111113), // slate-1
    surface: Color(0xFF18191B), // slate-2
    surface2: Color(0xFF212225), // slate-3
    surface3: Color(0xFF272A2D), // slate-4
    hairline: Color(0xFF363A3F), // slate-6
    controlBorder: Color(0xFF696E77), // slate-9
    text: Color(0xFFEDEEF0), // slate-12
    textMuted: Color(0xFFB0B4BA), // slate-11
    accent: Color(0xFF00A2C7), // cyan-9
    onAccent: Color(0xFF111113),
    link: Color(0xFF4CCCE6), // cyan-11
    danger: Color(0xFFFF9592), // red-11
    like: Color(0xFFE54666), // ruby-9
    success: Color(0xFF3DD68C), // green-11
    warning: Color(0xFFFFCA16), // amber-11
  );

  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) => this;
}

/// Spacing scale (px): 4 8 12 16 24 32 48 64.
abstract final class Space {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

/// Radii: 6 tags/menu items, 8 buttons/inputs, 12 cards/popovers, 16 dialogs/sheets.
abstract final class Radii {
  static const sm = 6.0;
  static const md = 8.0;
  static const lg = 12.0;
  static const xl = 16.0;
}

/// Motion: 150 ms hover/press, 200-250 ms dialogs in, 150 ms out.
abstract final class Motion {
  static const fast = Duration(milliseconds: 150);
  static const enter = Duration(milliseconds: 220);
  static const enterCurve = Cubic(0.23, 1, 0.32, 1);
}

const hairlineWidth = 0.5;

/// Four sizes only (12 / 14 / 16 / 20), weights 400 and 600.
TextTheme _textTheme(AppTokens t) {
  TextStyle style(double size, double lineHeight, FontWeight weight, Color color) => TextStyle(
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
        color: color,
        letterSpacing: 0,
      );
  const regular = FontWeight.w400;
  const semibold = FontWeight.w600;
  return TextTheme(
    displayLarge: style(20, 28, semibold, t.text),
    displayMedium: style(20, 28, semibold, t.text),
    displaySmall: style(20, 28, semibold, t.text),
    headlineLarge: style(20, 28, semibold, t.text),
    headlineMedium: style(20, 28, semibold, t.text),
    headlineSmall: style(20, 28, semibold, t.text),
    titleLarge: style(20, 28, semibold, t.text),
    titleMedium: style(16, 24, semibold, t.text),
    titleSmall: style(14, 22, semibold, t.text),
    bodyLarge: style(16, 24, regular, t.text),
    bodyMedium: style(14, 22, regular, t.text),
    bodySmall: style(12, 18, regular, t.textMuted),
    labelLarge: style(14, 22, semibold, t.text),
    labelMedium: style(12, 18, semibold, t.text),
    labelSmall: style(12, 18, regular, t.textMuted),
  );
}

ThemeData buildDarkTheme() {
  const t = AppTokens.dark;
  final text = _textTheme(t);
  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: t.accent,
    onPrimary: t.onAccent,
    secondary: t.accent,
    onSecondary: t.onAccent,
    secondaryContainer: t.surface3,
    onSecondaryContainer: t.text,
    error: t.danger,
    onError: t.bg,
    surface: t.bg,
    onSurface: t.text,
    onSurfaceVariant: t.textMuted,
    surfaceContainerLowest: t.bg,
    surfaceContainerLow: t.surface,
    surfaceContainer: t.surface,
    surfaceContainerHigh: t.surface2,
    surfaceContainerHighest: t.surface3,
    outline: t.controlBorder,
    outlineVariant: t.hairline,
    shadow: Colors.transparent,
    scrim: Colors.black,
    surfaceTint: Colors.transparent,
  );
  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md));
  const buttonSize = Size(64, 40);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: t.bg,
    canvasColor: t.bg,
    textTheme: text,
    extensions: const [AppTokens.dark],
    splashFactory: NoSplash.splashFactory,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    dividerTheme: DividerThemeData(color: t.hairline, thickness: hairlineWidth, space: hairlineWidth),
    iconTheme: IconThemeData(color: t.textMuted, size: 20),
    appBarTheme: AppBarTheme(
      backgroundColor: t.bg,
      foregroundColor: t.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleMedium,
      shape: Border(bottom: BorderSide(color: t.hairline, width: hairlineWidth)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: t.bg,
      elevation: 0,
      height: 64,
      indicatorColor: t.surface3,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelMedium!.copyWith(
          color: states.contains(WidgetState.selected) ? t.text : t.textMuted,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 22,
          color: states.contains(WidgetState.selected) ? t.accent : t.textMuted,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: t.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg)),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: t.textMuted,
      textColor: t.text,
      titleTextStyle: text.bodyMedium,
      subtitleTextStyle: text.bodySmall,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.l),
      minVerticalPadding: Space.s,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: t.accent,
        foregroundColor: t.onAccent,
        minimumSize: buttonSize,
        padding: const EdgeInsets.symmetric(horizontal: Space.l),
        shape: buttonShape,
        textStyle: text.labelLarge,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: t.text,
        minimumSize: buttonSize,
        padding: const EdgeInsets.symmetric(horizontal: Space.l),
        shape: buttonShape,
        side: BorderSide(color: t.controlBorder, width: hairlineWidth),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: t.link,
        minimumSize: buttonSize,
        padding: const EdgeInsets.symmetric(horizontal: Space.m),
        shape: buttonShape,
        textStyle: text.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: t.textMuted, minimumSize: const Size(44, 44)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.m),
      hintStyle: text.bodyMedium!.copyWith(color: t.textMuted),
      labelStyle: text.bodyMedium!.copyWith(color: t.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: t.controlBorder, width: hairlineWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: t.controlBorder, width: hairlineWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: t.accent, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: t.surface2,
      selectedColor: t.surface3,
      labelStyle: text.labelMedium,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: Space.s),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: t.bg,
        foregroundColor: t.textMuted,
        selectedBackgroundColor: t.surface3,
        selectedForegroundColor: t.text,
        side: BorderSide(color: t.hairline, width: hairlineWidth),
        shape: buttonShape,
        textStyle: text.labelMedium,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.surface,
      modalBackgroundColor: t.surface,
      elevation: 0,
      modalElevation: 0,
      showDragHandle: true,
      dragHandleColor: t.controlBorder,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.surface2,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xl),
        side: BorderSide(color: t.hairline, width: hairlineWidth),
      ),
      titleTextStyle: text.titleMedium,
      contentTextStyle: text.bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.surface3,
      contentTextStyle: text.bodyMedium,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: t.hairline, width: hairlineWidth),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: t.accent,
      linearTrackColor: t.surface3,
      circularTrackColor: Colors.transparent,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.onAccent : t.textMuted),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.accent : t.surface3),
      trackOutlineColor: WidgetStateProperty.all(t.controlBorder),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: t.text,
      unselectedLabelColor: t.textMuted,
      labelStyle: text.labelLarge,
      unselectedLabelStyle: text.bodyMedium,
      indicatorColor: t.accent,
      dividerColor: t.hairline,
      indicatorSize: TabBarIndicatorSize.label,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

extension TokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
  TextTheme get text => Theme.of(this).textTheme;
}

/// Numbers in columns line up with tabular figures.
const tabular = [FontFeature.tabularFigures()];
