import 'package:flutter/material.dart';

/// The web console's palette (src/styles/variables.ts): deep navy surfaces with bright status colours.
class OhsColors {
  // surfaces, darkest to lightest
  static const bg0 = Color(0xFF07111F);
  static const bg1 = Color(0xFF0B1728);
  static const bg2 = Color(0xFF101F33);
  static const bg3 = Color(0xFF162942);
  static const bg4 = Color(0xFF203A59);

  static const text1 = Color(0xFFF2F7FB);
  static const text2 = Color(0xFFAABCCD);
  static const text3 = Color(0xFF6F849A);

  static const border = Color(0x1F9DBEDC);
  static const borderHi = Color(0x4F74B2EB);

  static const blue = Color(0xFF4DA3FF);
  static const blueBright = Color(0xFF85C4FF);
  static const green = Color(0xFF2DD4A8);
  static const amber = Color(0xFFF8BD56);
  static const red = Color(0xFFFB7185);
  static const purple = Color(0xFFAD8CFF);
  static const cyan = Color(0xFF35C6DC);

  // 12% tints of the status colours, for notice cards
  static const amberTint = Color(0x1FF8BD56);
  static const redTint = Color(0x1FFB7185);
  static const greenTint = Color(0x1F2DD4A8);
  static const blueTint = Color(0x1F4DA3FF);

  // status meanings used across the app
  static const brand = blue;
  static const critical = red;
  static const high = Color(0xFFFB923C);
  static const medium = amber;
  static const low = green;
  static const info = blue;
  static const neutral = text3;

  static const primaryGradient = LinearGradient(colors: [Color(0xFF328EDF), Color(0xFF236BA9)]);
}

/// Tinted panel used for notes and warnings (the web's .alert-* boxes).
BoxDecoration tintBox(Color c, {double radius = 12}) => BoxDecoration(
      color: c.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: c.withValues(alpha: 0.28)),
    );

const _sans = 'Manrope';
const mono = 'IBMPlexMono';

ThemeData buildTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: OhsColors.blue,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF173A5E),
    onPrimaryContainer: OhsColors.blueBright,
    secondary: OhsColors.cyan,
    onSecondary: OhsColors.bg0,
    secondaryContainer: OhsColors.bg4,
    onSecondaryContainer: OhsColors.text1,
    tertiary: OhsColors.purple,
    onTertiary: OhsColors.bg0,
    error: OhsColors.red,
    onError: Colors.white,
    errorContainer: Color(0xFF4A1C27),
    onErrorContainer: Color(0xFFFFC2CC),
    surface: OhsColors.bg1,
    onSurface: OhsColors.text1,
    onSurfaceVariant: OhsColors.text2,
    surfaceContainerLowest: OhsColors.bg0,
    surfaceContainerLow: OhsColors.bg1,
    surfaceContainer: OhsColors.bg2,
    surfaceContainerHigh: OhsColors.bg3,
    surfaceContainerHighest: OhsColors.bg4,
    outline: OhsColors.text3,
    outlineVariant: OhsColors.border,
    shadow: Colors.black,
    inverseSurface: OhsColors.text1,
    onInverseSurface: OhsColors.bg1,
    inversePrimary: Color(0xFF236BA9),
  );

  final base = ThemeData(useMaterial3: true, brightness: Brightness.dark, colorScheme: scheme, fontFamily: _sans);
  final text = base.textTheme.apply(bodyColor: OhsColors.text1, displayColor: OhsColors.text1);
  const r9 = BorderRadius.all(Radius.circular(9));
  const r12 = BorderRadius.all(Radius.circular(12));
  OutlineInputBorder field(Color c, [double w = 1]) => OutlineInputBorder(borderRadius: r9, borderSide: BorderSide(color: c, width: w));

  return base.copyWith(
    scaffoldBackgroundColor: OhsColors.bg0,
    canvasColor: OhsColors.bg1,
    dividerColor: OhsColors.border,
    textTheme: text.copyWith(
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      labelMedium: text.labelMedium?.copyWith(fontFamily: mono, color: OhsColors.text3, letterSpacing: 0.6),
      labelSmall: text.labelSmall?.copyWith(fontFamily: mono, color: OhsColors.text3, letterSpacing: 0.6),
      bodySmall: text.bodySmall?.copyWith(color: OhsColors.text2),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: OhsColors.bg1,
      surfaceTintColor: Colors.transparent,
      foregroundColor: OhsColors.text1,
      titleTextStyle: text.titleLarge?.copyWith(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3),
      shape: const Border(bottom: BorderSide(color: OhsColors.border)),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: OhsColors.bg2,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18)), side: BorderSide(color: OhsColors.border)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: const Color(0xA807121F),
      labelStyle: const TextStyle(color: OhsColors.text2),
      floatingLabelStyle: const TextStyle(color: OhsColors.blueBright),
      hintStyle: const TextStyle(color: OhsColors.text3),
      prefixIconColor: OhsColors.text3,
      suffixIconColor: OhsColors.text3,
      border: field(OhsColors.border),
      enabledBorder: field(OhsColors.border),
      focusedBorder: field(OhsColors.blue, 1.4),
      errorBorder: field(OhsColors.red),
      focusedErrorBorder: field(OhsColors.red, 1.4),
      disabledBorder: field(OhsColors.border.withValues(alpha: 0.06)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF2B7DC4),
        foregroundColor: Colors.white,
        disabledBackgroundColor: OhsColors.bg3,
        disabledForegroundColor: OhsColors.text3,
        shape: const RoundedRectangleBorder(borderRadius: r9),
        textStyle: const TextStyle(fontFamily: _sans, fontWeight: FontWeight.w700, letterSpacing: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: OhsColors.text1,
        side: const BorderSide(color: OhsColors.borderHi),
        shape: const RoundedRectangleBorder(borderRadius: r9),
        textStyle: const TextStyle(fontFamily: _sans, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: OhsColors.blueBright,
        textStyle: const TextStyle(fontFamily: _sans, fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF2B7DC4),
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: OhsColors.bg1,
      surfaceTintColor: Colors.transparent,
      indicatorColor: OhsColors.blue.withValues(alpha: 0.16),
      indicatorShape: const RoundedRectangleBorder(borderRadius: r12, side: BorderSide(color: OhsColors.borderHi)),
      height: 66,
      iconTheme: WidgetStateProperty.resolveWith((s) =>
          IconThemeData(color: s.contains(WidgetState.selected) ? OhsColors.blueBright : OhsColors.text3, size: 22)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontFamily: _sans,
            fontSize: 11.5,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
            color: s.contains(WidgetState.selected) ? OhsColors.text1 : OhsColors.text3,
          )),
    ),
    navigationDrawerTheme: const NavigationDrawerThemeData(backgroundColor: OhsColors.bg1),
    drawerTheme: const DrawerThemeData(backgroundColor: OhsColors.bg1),
    chipTheme: ChipThemeData(
      backgroundColor: OhsColors.bg2,
      selectedColor: OhsColors.blue.withValues(alpha: 0.18),
      side: const BorderSide(color: OhsColors.border),
      labelStyle: const TextStyle(fontFamily: _sans, fontSize: 12.5, fontWeight: FontWeight.w600, color: OhsColors.text2),
      secondaryLabelStyle: const TextStyle(color: OhsColors.blueBright),
      checkmarkColor: OhsColors.blueBright,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(999))),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      iconColor: OhsColors.text2,
      textColor: OhsColors.text1,
      titleTextStyle: TextStyle(fontFamily: _sans, color: OhsColors.text1, fontSize: 15, fontWeight: FontWeight.w700),
      subtitleTextStyle: TextStyle(fontFamily: _sans, color: OhsColors.text2, fontSize: 13),
    ),
    dividerTheme: const DividerThemeData(color: OhsColors.border, space: 1, thickness: 1),
    dialogTheme: const DialogThemeData(
      backgroundColor: OhsColors.bg2,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18)), side: BorderSide(color: OhsColors.borderHi)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: OhsColors.bg2,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: OhsColors.bg3,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: r12, side: BorderSide(color: OhsColors.border)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: OhsColors.bg4,
      contentTextStyle: TextStyle(fontFamily: _sans, color: OhsColors.text1),
      actionTextColor: OhsColors.blueBright,
      shape: RoundedRectangleBorder(borderRadius: r12),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: OhsColors.text1,
      unselectedLabelColor: OhsColors.text3,
      indicatorColor: OhsColors.blue,
      dividerColor: OhsColors.border,
      labelStyle: TextStyle(fontFamily: _sans, fontWeight: FontWeight.w800),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: OhsColors.blue, linearTrackColor: OhsColors.bg3),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : OhsColors.text3),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? OhsColors.blue : OhsColors.bg3),
    ),
  );
}

/// Edges for notice cards tinted with [OhsColors.amberTint] / [OhsColors.redTint].
const amberNotice = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(18)), side: BorderSide(color: Color(0x59F8BD56)));
const redNotice = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(18)), side: BorderSide(color: Color(0x59FB7185)));

/// Edge for a card tinted with any status colour.
RoundedRectangleBorder noticeShape(Color c) => RoundedRectangleBorder(
    borderRadius: const BorderRadius.all(Radius.circular(18)), side: BorderSide(color: c.withValues(alpha: 0.35)));
