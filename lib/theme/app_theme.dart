import 'dart:async';

import 'package:countdowns/fonts/font_library.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

/// The "Highlighter" palette, taken from the default app icon.
///
/// Event colours, gradients, photos and the automatic ink/white text on
/// events are separate (see palette.dart) and don't change with this.
abstract final class AppColors {
  /// App background.
  static const paper = Color(0xFFFBF9F3);

  /// Text, links, outlines, icons and primary dark buttons.
  static const ink = Color(0xFF2E2A3A);

  /// Secondary text. 5.3:1 on paper, 4.7:1 on wash.
  static const pencil = Color(0xFF6B6677);

  /// The selected state: segmented pills, selected chips, Save.
  static const highlighter = Color(0xFFFFE36E);

  /// Borders and dividers.
  static const rule = Color(0xFFE6E1D3);

  /// Segmented tracks, grouped rows and tiles.
  static const wash = Color(0xFFF1EDE2);

  static const surface = Colors.white;
  static const danger = Color(0xFFB3261E);

  /// Dark ground for the crop screen and wall mode.
  static const night = Color(0xFF24212D);

  /// Light text on [night].
  static const nightText = Color(0xFFE6E1D3);
  static const nightSubtle = Color(0xFFB8B3A6);

  /// The scrim over photos (unchanged: photos look the same).
  static const scrim = Color(0xFF120F22);

  /// Ink at 12%, for soft fills on event colours.
  static const softInk = Color(0x1F1C1633);

  // Older names, kept so every screen picks up the new palette.
  static const ground = paper;
  static const primary = ink;
  static const secondaryText = pencil;
  static const muted = pencil;
  static const border = rule;
  static const divider = rule;
  static const track = wash;
  static const highlight = highlighter;
}

/// Font families. Event fonts use [resolveEventFont].
abstract final class AppFonts {
  static const ui = 'Inter';
  static const numerals = 'BricolageGrotesque';

  /// Bricolage cut at a large optical size, for the giant numbers.
  static const display = 'BricolageDisplay';
}

/// A font bundled with the app. Every other event font is a Google font,
/// stored by its family name and downloaded when used (see FontLibrary).
class EventFont {
  const EventFont(this.family, this.label);

  /// The value stored on the event.
  final String family;
  final String label;

  String get fontFamily => resolveEventFont(family);
}

/// The event fonts that ship with the app: Default (Bricolage) and the
/// originals that aren't on Google Fonts.
const bundledEventFonts = [
  EventFont('Default', 'Default'),
  EventFont('GoodTimes', 'Good Times'),
  EventFont('DiarioDeAndy', 'Diario De Andy'),
  EventFont('Sunnyspells', 'Sunnyspells'),
  EventFont('CarnivaleeFreakshow', 'Carnivalee Freakshow'),
  EventFont('Starjedi', 'Not Starwars'),
  EventFont('NewWaltDisney', 'Not Disney'),
];

/// Fonts the app used to bundle that now come from Google Fonts. Countdowns
/// keep the old value; it reads as the Google family.
const legacyEventFonts = {
  'LibreBaskerville': 'Libre Baskerville',
  'ComicNeue': 'Comic Neue',
  'LuxuriousRoman': 'Luxurious Roman',
  // 'Roboto' is the same name on Google Fonts.
};

/// The font a stored value means today.
String canonicalEventFont(String family) =>
    family.isEmpty ? 'Default' : legacyEventFonts[family] ?? family;

EventFont? bundledEventFont(String family) {
  final key = canonicalEventFont(family);
  for (final f in bundledEventFonts) {
    if (f.family == key) return f;
  }
  return null;
}

bool isGoogleEventFont(String family) => bundledEventFont(family) == null;

/// What the picker calls a font.
String eventFontLabel(String family) =>
    bundledEventFont(family)?.label ?? canonicalEventFont(family);

/// The Flutter family for an event font. "Default" is Bricolage Grotesque
/// in the redesign. A Google font starts loading here (from the device, or
/// downloaded once); pair this with [eventFontFallback] so the title shows
/// in Default until it's ready, offline included.
String resolveEventFont(String family) {
  final key = canonicalEventFont(family);
  if (key == 'Default') return AppFonts.numerals;
  if (bundledEventFont(key) != null) return key;
  unawaited(FontLibrary.instance.use(key));
  return FontLibrary.flutterFamily(key);
}

/// Fallback for event titles while a Google font loads or if it can't.
const eventFontFallback = [AppFonts.numerals];

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
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.ink,
        onPrimary: Colors.white,
        secondary: AppColors.highlighter,
        onSecondary: AppColors.ink,
        outline: AppColors.rule,
        onSurface: AppColors.ink,
        onSurfaceVariant: AppColors.pencil,
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
