// Writes assets/fonts/google_fonts.json, the catalogue behind "All fonts".
//
//   dart run tool/generate_font_catalog.dart
//
// Two public sources, no API key:
// - the google_fonts package (a dev dependency, pinned in pubspec.yaml) for
//   every family's font files. Each file is addressed by its SHA-256 at
//   https://fonts.gstatic.com/s/a/<sha256>.ttf, so the app can check what it
//   downloads.
// - https://fonts.google.com/metadata/fonts for each family's category and
//   popularity.
//
// Each family keeps one file: the upright weight closest to bold, which is
// how countdown titles are drawn in the app and in the widgets. Families
// that can't write Latin text are left out, since titles are mostly Latin
// and the preview shows the title.
//
// Re-run after bumping google_fonts to pick up new families.
import 'dart:convert';
import 'dart:io';

/// Category codes used in the JSON, matching FontCategory in the app.
const categoryCodes = {
  'Sans Serif': 's',
  'Serif': 'r',
  'Display': 'd',
  'Handwriting': 'h',
  'Monospace': 'm',
};

/// Emoji and icon families: nothing to write a title with.
const skip = {
  'Noto Color Emoji',
  'Noto Emoji',
  'Material Icons',
  'Material Symbols',
};

Future<void> main() async {
  final source = await _googleFontsSource();
  final files = _parseFiles(source.readAsStringSync());
  stdout.writeln('google_fonts: ${files.length} families');

  final meta = await _metadata();
  final out = <List<Object>>[];
  for (final m in meta) {
    final family = m['family'] as String;
    final subsets = (m['subsets'] as List).cast<String>();
    final category = categoryCodes[m['category']];
    final variants = files[family];
    if (variants == null ||
        category == null ||
        skip.contains(family) ||
        family.startsWith('Material ') ||
        !subsets.contains('latin')) {
      continue;
    }
    final upright = variants.where((v) => !v.italic).toList();
    if (upright.isEmpty) continue;
    // Closest to 700; on a tie, the heavier one.
    upright.sort((a, b) {
      final d = (a.weight - 700).abs().compareTo((b.weight - 700).abs());
      return d != 0 ? d : b.weight.compareTo(a.weight);
    });
    final v = upright.first;
    out.add([
      family,
      category,
      v.weight,
      v.hash,
      v.length,
      m['popularity'] as int,
    ]);
  }
  out.sort((a, b) => (a[5] as int).compareTo(b[5] as int));

  final json = StringBuffer('{"version":1,"fonts":[\n');
  for (final (i, row) in out.indexed) {
    // Popularity is only used for the order.
    json.write(jsonEncode(row.sublist(0, 5)));
    json.write(i == out.length - 1 ? '\n' : ',\n');
  }
  json.write(']}\n');
  File('assets/fonts/google_fonts.json')
    ..createSync(recursive: true)
    ..writeAsStringSync(json.toString());
  stdout.writeln('wrote ${out.length} families');
}

class _Variant {
  _Variant(this.weight, this.italic, this.hash, this.length);
  final int weight;
  final bool italic;
  final String hash;
  final int length;
}

/// Finds google_fonts' generated catalogue through the package config.
Future<File> _googleFontsSource() async {
  final config = jsonDecode(
    File('.dart_tool/package_config.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final package = (config['packages'] as List)
      .cast<Map<String, dynamic>>()
      .firstWhere(
        (p) => p['name'] == 'google_fonts',
        orElse: () => throw StateError(
          'google_fonts is missing: run flutter pub get first',
        ),
      );
  var rootUri = package['rootUri'] as String;
  if (!rootUri.endsWith('/')) rootUri = '$rootUri/';
  var root = Uri.parse(rootUri);
  if (!root.isAbsolute) {
    root = File('.dart_tool/package_config.json').absolute.uri.resolveUri(root);
  }
  return File.fromUri(root.resolve('lib/src/google_fonts_lite.dart'));
}

/// Reads `'Family': { GoogleFontsVariant(...): GoogleFontsFile(hash, len) }`.
Map<String, List<_Variant>> _parseFiles(String source) {
  final families = <String, List<_Variant>>{};
  final family = RegExp(r"^    '([^']+)': \{$", multiLine: true);
  final variant = RegExp(
    r'fontWeight: FontWeight\.w(\d+),\s*fontStyle: FontStyle\.(normal|italic),'
    r"\s*\): const GoogleFontsFile\(\s*'([0-9a-f]{64})',\s*(\d+),",
  );
  final starts = family.allMatches(source).toList();
  for (final (i, m) in starts.indexed) {
    final end = i + 1 < starts.length ? starts[i + 1].start : source.length;
    final body = source.substring(m.end, end);
    families[m.group(1)!] = [
      for (final v in variant.allMatches(body))
        _Variant(
          int.parse(v.group(1)!),
          v.group(2) == 'italic',
          v.group(3)!,
          int.parse(v.group(4)!),
        ),
    ];
  }
  return families;
}

Future<List<Map<String, dynamic>>> _metadata() async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse('https://fonts.google.com/metadata/fonts'),
    );
    final response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException('metadata: HTTP ${response.statusCode}');
    }
    var body = await response.transform(utf8.decoder).join();
    // The endpoint has, at times, prefixed its JSON with )]}'.
    body = body.substring(body.indexOf('{'));
    final json = jsonDecode(body) as Map<String, dynamic>;
    return (json['familyMetadataList'] as List).cast<Map<String, dynamic>>();
  } finally {
    client.close();
  }
}
