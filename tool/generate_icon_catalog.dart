// Writes lib/models/icon_catalog.dart from assets/event_icons/icons.json.
//
//   dart run tool/generate_icon_catalog.dart
//
// icons.json lists every event icon in catalogue order. The first 68 are the
// redrawn Material icons the old app offered and carry the Material name in
// `material`; keep them first and in order, because stored codepoints map
// through them. Icons added since have no `material`.
import 'dart:convert';
import 'dart:io';

/// The sections of "All icons", in order.
const categories = [
  'Celebrations',
  'Holidays',
  'Life events',
  'Travel',
  'Food & drink',
  'Sports',
  'Fun',
  'School',
  'Work & money',
  'Home',
  'Health',
  'Animals',
  'Nature',
  'Everyday',
];

String quote(String s) =>
    s.contains("'") ? '"${s.replaceAll('"', r'\"')}"' : "'$s'";

void main() {
  final icons = (jsonDecode(
    File('assets/event_icons/icons.json').readAsStringSync(),
  ) as List).cast<Map<String, dynamic>>();

  final seen = <String>{};
  for (final icon in icons) {
    final slug = icon['slug'] as String;
    if (!seen.add(slug)) throw StateError('Duplicate slug $slug');
    if (!categories.contains(icon['category'])) {
      throw StateError('$slug has unknown category ${icon['category']}');
    }
    if (!File('assets/event_icons/$slug.svg').existsSync()) {
      throw StateError('Missing assets/event_icons/$slug.svg');
    }
  }

  final out = StringBuffer()
    ..writeln(
      '// Generated from assets/event_icons/icons.json by '
      'tool/generate_icon_catalog.dart.',
    )
    ..writeln('// Do not edit by hand.')
    ..writeln("import 'package:material_ui/material_ui.dart';")
    ..writeln()
    ..writeln('class EventIconInfo {')
    ..writeln(
      '  const EventIconInfo(this.slug, this.label, this.category, '
      'this.keywords, [this.legacyCodePoint]);',
    )
    ..writeln('  final String slug;')
    ..writeln('  final String label;')
    ..writeln()
    ..writeln(
      '  /// The "All icons" section it sits in, one of [iconCategories].',
    )
    ..writeln('  final String category;')
    ..writeln()
    ..writeln(
      '  /// Comma-separated, lower-case words and phrases "All icons" search',
    )
    ..writeln('  /// matches.')
    ..writeln('  final String keywords;')
    ..writeln()
    ..writeln(
      '  /// The Material icon codepoint the old app stored for this icon, or',
    )
    ..writeln('  /// null for icons added since.')
    ..writeln('  final int? legacyCodePoint;')
    ..writeln()
    ..writeln("  String get asset => 'assets/event_icons/\$slug.svg';")
    ..writeln('}')
    ..writeln()
    ..writeln('/// The sections of "All icons", in order.')
    ..writeln('const List<String> iconCategories = [')
    ..writeAll(categories.map((c) => '  ${quote(c)},\n'))
    ..writeln('];')
    ..writeln()
    ..writeln('final List<EventIconInfo> eventIconCatalog = [');
  for (final icon in icons) {
    final material = icon['material'] as String?;
    final keywords = (icon['keywords'] as List).cast<String>();
    final args = [
      quote(icon['slug'] as String),
      quote(icon['label'] as String),
      quote(icon['category'] as String),
      quote(keywords.join(', ')),
      if (material != null) 'Icons.$material.codePoint',
    ].join(', ');
    out.writeln('  ${material == null ? 'const ' : ''}EventIconInfo($args),');
  }
  out.writeln('];');

  const path = 'lib/models/icon_catalog.dart';
  File(path).writeAsStringSync(out.toString());
  Process.runSync('dart', ['format', path]);
  stdout.writeln('Wrote ${icons.length} icons to $path');
}
