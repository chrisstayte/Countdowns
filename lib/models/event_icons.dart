import 'package:countdowns/models/icon_catalog.dart';
import 'package:material_ui/material_ui.dart';

/// Material icons the old app offered, kept so the Hive adapter and v1 JSON
/// import can read stored codepoints.
const eventIcons = <IconData>[
  Icons.calendar_today,
  Icons.celebration,
  Icons.cake,
  Icons.local_dining,
  Icons.icecream,
  Icons.holiday_village,
  Icons.hiking,
  Icons.sports,
  Icons.sports_football,
  Icons.sports_baseball,
  Icons.sports_basketball,
  Icons.sports_esports,
  Icons.alarm,
  Icons.airplane_ticket,
  Icons.airplanemode_active,
  Icons.airline_seat_flat,
  Icons.photo,
  Icons.wifi,
  Icons.warning,
  Icons.baby_changing_station,
  Icons.apartment,
  Icons.card_giftcard,
  Icons.computer,
  Icons.book,
  Icons.bookmark,
  Icons.piano,
  Icons.donut_large,
  Icons.camera,
  Icons.animation,
  Icons.sports_cricket,
  Icons.agriculture,
  Icons.horizontal_distribute_sharp,
  Icons.music_note,
  Icons.music_video,
  Icons.snooze,
  Icons.school,
  Icons.work,
  Icons.business,
  Icons.group,
  Icons.add_to_drive,
  Icons.blender,
  Icons.block,
  Icons.cabin,
  Icons.cached,
  Icons.delete,
  Icons.delete_forever,
  Icons.tram_sharp,
  Icons.train,
  Icons.traffic,
  Icons.map,
  Icons.flutter_dash,
  Icons.golf_course,
  Icons.tty_sharp,
  Icons.attractions,
  Icons.assignment_sharp,
  Icons.camera_rear,
  Icons.cloud_sharp,
  Icons.coronavirus,
  Icons.motion_photos_auto,
  Icons.email,
  Icons.phone,
  Icons.wallet_giftcard,
  Icons.smart_button,
  Icons.brunch_dining_rounded,
  Icons.bakery_dining,
  Icons.library_add,
  Icons.favorite,
  Icons.park,
];

/// Reads a stored codepoint. Unknown codepoints become [Icons.event], as the
/// old app did.
IconData? eventIcon(int? codePoint) => codePoint == null
    ? null
    : eventIcons.where((icon) => icon.codePoint == codePoint).firstOrNull ??
          Icons.event;

final Map<String, EventIconInfo> _bySlug = {
  for (final info in eventIconCatalog) info.slug: info,
};

/// Old codepoint to slug. Material's card_giftcard and wallet_giftcard share
/// one codepoint, so the old app stored them identically and always showed
/// the first; that one (gift) wins here too.
final Map<int, String> _byCodePoint = () {
  final map = <int, String>{};
  for (final info in eventIconCatalog) {
    if (info.legacyCodePoint case final code?) {
      map.putIfAbsent(code, () => info.slug);
    }
  }
  return map;
}();

EventIconInfo? iconInfo(String? slug) => _bySlug[slug];

/// Maps an old Material codepoint to a redrawn icon. Unknown icons become
/// `calendar`; no icon stays no icon.
String? slugForCodePoint(int? codePoint) =>
    codePoint == null ? null : _byCodePoint[codePoint] ?? 'calendar';

/// Shown in the editor's main icon row until the person has used 15 icons.
/// "holiday" in the spec is the `village` icon, labelled Holiday.
const List<String> defaultIconRow = [
  'calendar',
  'cake',
  'party',
  'plane',
  'gift',
  'heart',
  'graduation',
  'dining',
  'note',
  'tree',
  'work',
  'friends',
  'baby',
  'village',
  'alarm',
];

/// "All icons" search: icons where every word of [query] appears in the
/// label, keywords, section or slug. Best matches come first: label starts
/// with the query, then a label word does, then a keyword is the query, then
/// a keyword starts with it, then the rest, each in catalogue order. An
/// empty query matches everything.
List<EventIconInfo> iconsMatching(String query, {String? category}) {
  final q = query.trim().toLowerCase();
  final words = q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final scored = <(int, int, EventIconInfo)>[];
  for (final (i, info) in eventIconCatalog.indexed) {
    if (category != null && info.category != category) continue;
    final label = info.label.toLowerCase();
    final haystack =
        '$label, ${info.keywords}, ${info.category.toLowerCase()}, '
        '${info.slug.replaceAll('-', ' ')}';
    if (!words.every(haystack.contains)) continue;
    final keywords = info.keywords.split(', ');
    final score = q.isEmpty || label.startsWith(q)
        ? 0
        : RegExp('\\b${RegExp.escape(q)}').hasMatch(label)
        ? 1
        : keywords.contains(q)
        ? 2
        : keywords.any((k) => k.startsWith(q))
        ? 3
        : 4;
    scored.add((score, i, info));
  }
  scored.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
  return [for (final (_, _, info) in scored) info];
}
