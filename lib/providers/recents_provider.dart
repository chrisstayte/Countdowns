import 'package:countdowns/models/event_icons.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Recently used things, newest first, kept in SharedPreferences under their
/// own keys (not inside `localSettings`).
class Recents {
  const Recents({
    this.icons = const [],
    this.fonts = const [],
    this.photos = const [],
    this.searches = const [],
  });
  final List<String> icons, fonts, photos, searches;
}

final recentsProvider = NotifierProvider<RecentsController, Recents>(
  RecentsController.new,
);

const _iconsKey = 'recentIcons';
const _fontsKey = 'recentFonts';
const _photosKey = 'recentPhotos';
const _searchesKey = 'recentSearches';

class RecentsController extends Notifier<Recents> {
  @override
  Recents build() {
    final prefs = ref.watch(preferencesProvider);
    return Recents(
      icons: prefs.getStringList(_iconsKey) ?? const [],
      fonts: prefs.getStringList(_fontsKey) ?? const [],
      photos: prefs.getStringList(_photosKey) ?? const [],
      searches: prefs.getStringList(_searchesKey) ?? const [],
    );
  }

  List<String> _push(List<String> list, String value, int max) =>
      [value, ...list.where((v) => v != value)].take(max).toList();

  Future<void> useIcon(String slug) async {
    state = Recents(
      icons: _push(state.icons, slug, 15),
      fonts: state.fonts,
      photos: state.photos,
      searches: state.searches,
    );
    await ref.read(preferencesProvider).setStringList(_iconsKey, state.icons);
  }

  Future<void> useFont(String family) async {
    state = Recents(
      icons: state.icons,
      fonts: _push(state.fonts, family, 4),
      photos: state.photos,
      searches: state.searches,
    );
    await ref.read(preferencesProvider).setStringList(_fontsKey, state.fonts);
  }

  Future<void> usePhoto(String path) async {
    state = Recents(
      icons: state.icons,
      fonts: state.fonts,
      photos: _push(state.photos, path, 6),
      searches: state.searches,
    );
    await ref.read(preferencesProvider).setStringList(_photosKey, state.photos);
  }

  Future<void> useSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    state = Recents(
      icons: state.icons,
      fonts: state.fonts,
      photos: state.photos,
      searches: _push(state.searches, q, 5),
    );
    await ref
        .read(preferencesProvider)
        .setStringList(_searchesKey, state.searches);
  }

  Future<void> clearSearches() async {
    state = Recents(
      icons: state.icons,
      fonts: state.fonts,
      photos: state.photos,
    );
    await ref.read(preferencesProvider).remove(_searchesKey);
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
    'LibreBaskerville',
    'ComicNeue',
    'NewWaltDisney',
  ].where((f) => !recent.contains(f)),
].take(4).toList();
