import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Keeps stock result pages on the device for [maxAge], so browsing the
/// same category or search again costs no requests.
class StockCache {
  StockCache(
    this.directory, {
    this.maxAge = const Duration(hours: 24),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Directory directory;
  final Duration maxAge;
  final DateTime Function() _clock;

  File _file(String key) => File(
    p.join(
      directory.path,
      '${base64Url.encode(utf8.encode(key)).replaceAll('=', '')}.json',
    ),
  );

  /// The cached value for [key] if it is younger than [maxAge].
  Future<Map<String, Object?>?> read(String key) async {
    try {
      final f = _file(key);
      if (!await f.exists()) return null;
      final j = jsonDecode(await f.readAsString()) as Map<String, Object?>;
      final at = DateTime.parse(j['at']! as String);
      if (_clock().difference(at) > maxAge) return null;
      return (j['value']! as Map).cast<String, Object?>();
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, Map<String, Object?> value) async {
    try {
      await directory.create(recursive: true);
      await _file(key).writeAsString(
        jsonEncode({'at': _clock().toIso8601String(), 'value': value}),
      );
    } catch (_) {
      // A cache miss next time is fine.
    }
  }
}
