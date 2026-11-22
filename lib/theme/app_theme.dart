import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Colours from the redesign canvas.
abstract final class AppColors {
  static const ground = Color(0xFFF5F4FF);
  static const ink = Color(0xFF1C1633);
  static const primary = Color(0xFF4A0D67);
  static const save = Color(0xFF1B998B);
  static const secondaryText = Color(0xFF5E5878);
  static const border = Color(0xFFD6D3F0);
  static const muted = Color(0xFF8A8796);
  static const track = Color(0xFFE4E1F5);
  static const divider = Color(0xFFECEAFB);
  static const surface = Colors.white;
  static const danger = Color(0xFFB3261E);
  static const highlight = Color(0xFFF7BC33);
  static const scrim = Color(0xFF120F22);
  static const softInk = Color(0x1F1C1633); // ink at 12%
}

/// Font families. Event fonts use [eventFontFamily].
abstract final class AppFonts {
  static const ui = 'Inter';
  static const numerals = 'BricolageGrotesque';

  /// Bricolage cut at a large optical size, for the giant numbers.
  static const display = 'BricolageDisplay';
}

class EventFont {
  const EventFont(this.family, this.label, this.group);

  /// The value stored on the event.
  final String family;
  final String label;
  final String group;

  String get fontFamily => resolveEventFont(family);
}

/// The 11 event fonts, grouped as on the canvas.
const eventFonts = [
  EventFont('Default', 'Default', 'Clean'),
  EventFont('Roboto', 'Roboto', 'Clean'),
  EventFont('GoodTimes', 'Good Times', 'Clean'),
  EventFont('LibreBaskerville', 'Baskerville', 'Classic'),
  EventFont('LuxuriousRoman', 'Luxurious Roman', 'Classic'),
  EventFont('ComicNeue', 'Comic Neue', 'Fun'),
  EventFont('DiarioDeAndy', 'Diario De Andy', 'Fun'),
  EventFont('Sunnyspells', 'Sunnyspells', 'Fun'),
  EventFont('CarnivaleeFreakshow', 'Carnivalee Freakshow', 'Fun'),
  EventFont('Starjedi', 'Not Starwars', 'Fun'),
  EventFont('NewWaltDisney', 'Not Disney', 'Fun'),
];

EventFont eventFontFor(String family) => eventFonts.firstWhere(
  (f) => f.family == family,
  orElse: () => eventFonts.first,
);

/// "Default" is Bricolage Grotesque in the redesign.
String resolveEventFont(String family) =>
    family == 'Default' ? AppFonts.numerals : family;

/// Text styles used across screens.
abstract final class AppText {
  static const eyebrow = TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.96,
    color: AppColors.secondaryText,
  );

  static const largeTitle = TextStyle(
    fontFamily: AppFonts.numerals,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.68,
    color: AppColors.ink,
    height: 1.1,
  );

  static const sheetTitle = TextStyle(
    fontFamily: AppFonts.numerals,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
  );

  static const body = TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: 15,
    color: AppColors.ink,
  );

  static const secondary = TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.secondaryText,
  );

  static TextStyle numeral(double size, {Color? color}) => TextStyle(
    fontFamily: size >= 60 ? AppFonts.display : AppFonts.numerals,
    fontSize: size,
    fontWeight: FontWeight.w800,
    height: 0.9,
    letterSpacing: size * -0.035,
    color: color,
  );
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    onSurface: AppColors.ink,
    surface: AppColors.ground,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: AppFonts.ui,
    scaffoldBackgroundColor: AppColors.ground,
    splashFactory: NoSplash.splashFactory,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionHandleColor: AppColors.primary,
    ),
    appBarTheme: const AppBarThemeData(
      backgroundColor: AppColors.ground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.ink,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    cupertinoOverrideTheme: const NoDefaultCupertinoThemeData(
      primaryColor: AppColors.primary,
    ),
  );
}
