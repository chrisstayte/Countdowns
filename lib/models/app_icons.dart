/// App icons people can pick in Settings › App Icon (iOS only).
///
/// Each [AppIconOption.slug] matches:
/// - the Flutter thumbnail at `assets/images/icons/icon-<slug>.png`
/// - the iOS alternate icon set `ios/Runner/Assets.xcassets/icon-<slug>.appiconset`
///
/// The default icon lives in `AppIcon.appiconset`, so choosing it resets the
/// alternate icon to null instead of naming a set.
class AppIconOption {
  const AppIconOption(this.slug, this.label);

  final String slug;
  final String label;

  bool get isDefault => slug == defaultAppIcon;

  /// The name passed to `setAlternateIconName`, or null for the default icon.
  String? get alternateIconName => isDefault ? null : 'icon-$slug';

  String get assetPath => 'assets/images/icons/icon-$slug.png';
}

const String defaultAppIcon = 'highlighter';

const List<AppIconOption> appIcons = [
  AppIconOption('highlighter', 'Highlighter'),
  AppIconOption('peach-splash', 'Peach splash'),
  AppIconOption('mint-and-navy', 'Mint and navy'),
  AppIconOption('sky-splash', 'Sky splash'),
  AppIconOption('two-splashes', 'Two splashes'),
  AppIconOption('off-register-fill', 'Off-register'),
  AppIconOption('coral-pen', 'Coral pen'),
  AppIconOption('notebook', 'Notebook'),
  AppIconOption('graph-paper', 'Graph paper'),
  AppIconOption('chalkboard', 'Chalkboard'),
  AppIconOption('crayon', 'Crayon'),
  AppIconOption('scribbled-sand', 'Scribbled sand'),
  AppIconOption('sparkles', 'Sparkles'),
  AppIconOption('moon-doodle', 'Moon'),
  AppIconOption('heavy-marker', 'Heavy marker'),
  AppIconOption('one-line', 'One line'),
  AppIconOption('hatched', 'Hatched'),
  AppIconOption('blobby', 'Blobby'),
  AppIconOption('two-pens', 'Two pens'),
  AppIconOption('circled', 'Circled'),
  AppIconOption('sleepy-doodle', 'Sleepy'),
  AppIconOption('dashed-sketch', 'Dashed sketch'),
  AppIconOption('washi-tape', 'Washi tape'),
  AppIconOption('sticky-note', 'Sticky note'),
  AppIconOption('night-doodle', 'Night'),
];

/// Returns the option for a saved icon name, falling back to the default for
/// names from older versions (light, dark, original) that no longer exist.
AppIconOption appIconFor(String name) => appIcons.firstWhere(
  (icon) => icon.slug == name,
  orElse: () => appIcons.first,
);
