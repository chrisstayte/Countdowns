import 'dart:convert';
import 'dart:io';

import 'package:countdowns/storage/photos.dart';

/// Who took a stock photo, kept next to the photo file
/// (`photos/123.jpg.credit.json`), so the countdown's photo carries its
/// credit wherever it is used. Camera-roll photos have none.
class PhotoCredit {
  const PhotoCredit({
    required this.photographer,
    required this.photographerUrl,
    required this.pageUrl,
    required this.source,
    this.id = '',
    this.license = '',
  });

  final String photographer;
  final String photographerUrl;
  final String pageUrl;

  /// Where it came from, e.g. "Soon & Since catalogue".
  final String source;

  /// The catalogue photo id, so it can be identified after it leaves the
  /// catalogue.
  final String id;

  /// `CC0-1.0`, `PDM-1.0`, `owned`, `commissioned`, or empty.
  final String license;

  Map<String, String> toJson() => {
    'photographer': photographer,
    'photographerUrl': photographerUrl,
    'pageUrl': pageUrl,
    'source': source,
    'id': id,
    'license': license,
  };

  static PhotoCredit fromJson(Map<String, Object?> j) => PhotoCredit(
    photographer: j['photographer'] as String? ?? '',
    photographerUrl: j['photographerUrl'] as String? ?? '',
    pageUrl: j['pageUrl'] as String? ?? '',
    source: j['source'] as String? ?? '',
    id: j['id'] as String? ?? '',
    license: j['license'] as String? ?? '',
  );

  static File _file(String photoPath) =>
      File('${PhotoStore.instance.fileFor(photoPath).path}.credit.json');

  static Future<void> write(String photoPath, PhotoCredit credit) async {
    if (!PhotoStore.ready) return;
    await _file(photoPath).writeAsString(jsonEncode(credit.toJson()));
  }

  static PhotoCredit? read(String? photoPath) {
    if (photoPath == null || !PhotoStore.ready) return null;
    try {
      final f = _file(photoPath);
      if (!f.existsSync()) return null;
      return fromJson(
        (jsonDecode(f.readAsStringSync()) as Map).cast<String, Object?>(),
      );
    } catch (_) {
      return null;
    }
  }
}
