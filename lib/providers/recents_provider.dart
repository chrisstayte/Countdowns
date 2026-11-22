import 'package:countdowns/models/event_icons.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Recently used things, newest first, kept in SharedPreferences under their
/// own keys (not inside `localSettings`).
class Recents {
  const Recents({
    this.icons = const [],
    this.fonts = const [],
    this.photos = const [],
    this.searches = const [],
    this.backgrounds = const [],
  });
  final List<String> icons, fonts, photos, searches;

  /// Colour and gradient keys (see background_catalog.dart), newest first.
  final List<String> backgrounds;

  Recents copyWith({
    List<String>? icons,
    List<String>? fonts,
    List<String>? photos,
    List<String>? searches,
    List<String>? backgrounds,
  }) => Recents(
    icons: icons ?? this.icons,
    fonts: fonts ?? this.fonts,
    photos: photos ?? this.photos,
    searches: searches ?? this.searches,
    backgrounds: backgrounds ?? this.backgrounds,
  );
}

final recentsProvider = NotifierProvider<RecentsController, Recents>(
  RecentsController.new,
);

const _iconsKey = 'recentIcons';
const _fontsKey = 'recentFonts';
const _photosKey = 'recentPhotos';
const _searchesKey = 'recentSearches';
const _backgroundsKey = 'recentBackgrounds';

class RecentsController extends Notifier<Recents> {
  @override
  Recents build() {
    final prefs = ref.watch(preferencesProvider);
    return Recents(
      icons: prefs.getStringList(_iconsKey) ?? const [],
      // Older versions stored bundled names that are Google fonts now.
      fonts: (prefs.getStringList(_fontsKey) ?? const [])
          .map(canonicalEventFont)
          .toSet()
          .toList(),
      photos: prefs.getStringList(_photosKey) ?? const [],
      searches: prefs.getStringList(_searchesKey) ?? const [],
      backgrounds: prefs.getStringList(_backgroundsKey) ?? const [],
    );
  }

  List<String> _push(List<String> list, String value, int max) =>
      [value, ...list.where((v) => v != value)].take(max).toList();

  Future<void> useIcon(String slug) async {
    state = state.copyWith(icons: _push(state.icons, slug, 15));
    await ref.read(preferencesProvider).setStringList(_iconsKey, state.icons);
  }

  Future<void> useFont(String family) async {
    final key = canonicalEventFont(family);
    state = state.copyWith(fonts: _push(state.fonts, key, 4));
    await ref.read(preferencesProvider).setStringList(_fontsKey, state.fonts);
  }

  Future<void> usePhoto(String path) async {
    state = state.copyWith(photos: _push(state.photos, path, 6));
    await ref.read(preferencesProvider).setStringList(_photosKey, state.photos);
  }

  Future<void> useSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    state = state.copyWith(searches: _push(state.searches, q, 5));
    await ref
        .read(preferencesProvider)
        .setStringList(_searchesKey, state.searches);
  }

  Future<void> clearSearches() async {
    state = state.copyWith(searches: const []);
    await ref.read(preferencesProvider).remove(_searchesKey);
  }

  /// Remembers a colour or gradient key. Photos have their own list.
  Future<void> useBackground(String key) async {
    if (key.startsWith('photo:')) return;
    state = state.copyWith(backgrounds: _push(state.backgrounds, key, 8));
    await ref
        .read(preferencesProvider)
        .setStringList(_backgroundsKey, state.backgrounds);
  }
}

/// The editor's main icon row: the 15 most recent, topped up from the
/// default row.
List<String> iconRow(List<String> recent) => [
  ...recent,
  ...defaultIconRow.where((s) => !recent.contains(s)),
].where((s) => iconInfo(s) != null).take(15).toList();

/// The editor's 4 recent fonts, topped up with sensible defaults.
List<String> fontRow(List<String> recent) => [
  ...recent,
  ...[
    'Default',
    'Libre Baskerville',
    'Comic Neue',
    'Pacifico',
  ].where((f) => !recent.contains(f)),
].take(4).toList();
