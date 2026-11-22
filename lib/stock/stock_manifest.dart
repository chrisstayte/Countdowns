import 'package:countdowns/stock/stock_photo_source.dart';
import 'package:material_ui/material_ui.dart';

/// The catalogue manifest (`catalog/v1/manifest.json`), as described in
/// design/photo-catalogue/PLAN.md. Parsing is tolerant: unknown fields are
/// ignored, optional fields may be missing, and a malformed photo is
/// skipped rather than failing the whole manifest.
class StockManifest {
  const StockManifest({
    required this.schema,
    required this.version,
    required this.baseUrl,
    required this.enabled,
    required this.photos,
    this.covers = const {},
  });

  /// The only schema this app understands.
  static const supportedSchema = 1;

  final int schema;
  final int version;
  final String baseUrl;

  /// Kill switch: when false the app offers the camera roll only.
  final bool enabled;

  /// Visible photos only (`hidden` ones are dropped while parsing).
  final List<StockPhoto> photos;

  /// Optional cover photo id per category id.
  final Map<String, String> covers;

  /// Throws [FormatException] for a manifest the app can't use (wrong
  /// shape or an unknown schema), so the caller keeps its cached copy.
  static StockManifest parse(Map<String, Object?> j) {
    final schema = j['schema'];
    if (schema is! int) throw const FormatException('No schema');
    if (schema != supportedSchema) {
      throw FormatException('Unknown schema $schema');
    }
    var base = j['baseUrl'];
    if (base is! String || base.isEmpty) {
      throw const FormatException('No baseUrl');
    }
    if (!base.endsWith('/')) base = '$base/';
    final covers = <String, String>{};
    if (j['categories'] case final Map cats) {
      for (final MapEntry(:key, :value) in cats.entries) {
        if (key is String && value is Map && value['cover'] is String) {
          covers[key] = value['cover'] as String;
        }
      }
    }
    return StockManifest(
      schema: schema,
      version: (j['version'] as num?)?.toInt() ?? 0,
      baseUrl: base,
      enabled: j['enabled'] != false,
      covers: covers,
      photos: [
        for (final raw in (j['photos'] as List? ?? const []))
          if (raw is Map) ?_photo(raw.cast<String, Object?>(), base),
      ],
    );
  }

  static StockPhoto? _photo(Map<String, Object?> j, String base) {
    if (j['hidden'] == true) return null;
    final id = j['id'];
    final files = j['files'];
    if (id is! String || files is! Map) return null;
    final thumb = files['thumb'], full = files['full'];
    if (thumb is! String || full is! String) return null;
    final w = j['w'], h = j['h'];
    if (w is! num || h is! num || w <= 0 || h <= 0) return null;
    List<String> strings(Object? v) => v is List
        ? [
            for (final x in v)
              if (x is String) x,
          ]
        : const [];
    final credit = j['credit'] is Map
        ? (j['credit']! as Map).cast<String, Object?>()
        : const <String, Object?>{};
    final focal = j['focal'];
    return StockPhoto(
      id: id,
      thumbnailUrl: _join(base, thumb),
      fullUrl: _join(base, full),
      width: w.toInt(),
      height: h.toInt(),
      averageColor: _colour(j['color']),
      blurHash: j['blurhash'] is String && (j['blurhash'] as String).isNotEmpty
          ? j['blurhash'] as String
          : null,
      categories: strings(j['categories']),
      tags: strings(j['tags']),
      photographer: credit['name'] as String? ?? '',
      photographerUrl: credit['url'] as String? ?? '',
      pageUrl: credit['page'] as String? ?? '',
      license: j['license'] as String? ?? '',
      focal: focal is Map && focal['x'] is num && focal['y'] is num
          ? Offset(
              (focal['x'] as num).toDouble().clamp(0, 1),
              (focal['y'] as num).toDouble().clamp(0, 1),
            )
          : null,
    );
  }

  static String _join(String base, String path) =>
      path.startsWith('http') || path.startsWith('asset:')
      ? path
      : '$base${path.startsWith('/') ? path.substring(1) : path}';

  static Color? _colour(Object? v) {
    if (v is! String) return null;
    final hex = v.replaceFirst('#', '');
    if (hex.length != 6) return null;
    final n = int.tryParse(hex, radix: 16);
    return n == null ? null : Color(0xFF000000 | n);
  }
}
