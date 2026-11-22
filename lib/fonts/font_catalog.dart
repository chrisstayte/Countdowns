import 'dart:convert';

import 'package:flutter/services.dart';

/// Google Fonts' categories, in the order the "All fonts" chips show them.
enum FontCategory {
  sans('s', 'Sans serif'),
  serif('r', 'Serif'),
  display('d', 'Display'),
  handwriting('h', 'Handwriting'),
  mono('m', 'Monospace');

  const FontCategory(this.code, this.label);
  final String code;
  final String label;

  static FontCategory fromCode(String code) =>
      values.firstWhere((c) => c.code == code, orElse: () => display);
}

/// One Google Fonts family, as tool/generate_font_catalog.dart wrote it:
/// the single file a countdown title needs (upright, closest to bold).
class GoogleFont {
  const GoogleFont({
    required this.family,
    required this.category,
    required this.weight,
    required this.hash,
    required this.length,
  });

  final String family;
  final FontCategory category;
  final int weight;

  /// SHA-256 of the file, which is also its address on fonts.gstatic.com.
  final String hash;

  /// Size of the file in bytes.
  final int length;

  Uri get url => Uri.parse('https://fonts.gstatic.com/s/a/$hash.ttf');

  /// Big files (mostly Chinese, Japanese and Korean families) only preview
  /// when tapped, so scrolling the list never pulls megabytes.
  bool get large => length > 1500000;
}

/// Every family in assets/fonts/google_fonts.json, most popular first.
class FontCatalog {
  FontCatalog(this.fonts) : _byFamily = {for (final f in fonts) f.family: f};

  static const asset = 'assets/fonts/google_fonts.json';

  final List<GoogleFont> fonts;
  final Map<String, GoogleFont> _byFamily;

  GoogleFont? operator [](String family) => _byFamily[family];

  static FontCatalog parse(String json) {
    final rows = (jsonDecode(json) as Map<String, dynamic>)['fonts'] as List;
    return FontCatalog([
      for (final r in rows.cast<List<dynamic>>())
        GoogleFont(
          family: r[0] as String,
          category: FontCategory.fromCode(r[1] as String),
          weight: r[2] as int,
          hash: r[3] as String,
          length: r[4] as int,
        ),
    ]);
  }

  static Future<FontCatalog>? _loading;

  /// Loads once, from the bundle.
  static Future<FontCatalog> load([AssetBundle? bundle]) => _loading ??=
      (bundle ?? rootBundle).loadString(asset, cache: false).then(parse);

  /// Families whose name contains [query], keeping the popularity order;
  /// names that start with it come first.
  List<GoogleFont> matching(String query, {FontCategory? category}) {
    final q = query.trim().toLowerCase();
    final pool = category == null
        ? fonts
        : fonts.where((f) => f.category == category);
    if (q.isEmpty) return pool.toList();
    final starts = <GoogleFont>[];
    final contains = <GoogleFont>[];
    for (final f in pool) {
      final name = f.family.toLowerCase();
      if (name.startsWith(q)) {
        starts.add(f);
      } else if (name.contains(q)) {
        contains.add(f);
      }
    }
    return [...starts, ...contains];
  }
}
