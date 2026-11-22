import 'dart:convert';
import 'dart:io';

import 'package:countdowns/stock/stock_manifest.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// Fetches the catalogue manifest and keeps the last good copy on disk.
///
/// - Fetches at most every [refreshEvery], sending `If-None-Match` so an
///   unchanged manifest costs a 304.
/// - A network error, a bad response, invalid JSON or an unknown schema
///   all fall back to the cached copy.
/// - With nothing cached and no network, [load] throws, and the Photos tab
///   hides the stock sections.
class ManifestStore {
  ManifestStore({
    required this.url,
    required this.directory,
    http.Client? client,
    this.refreshEvery = const Duration(hours: 6),
    DateTime Function()? clock,
  }) : _client = client ?? http.Client(),
       _clock = clock ?? DateTime.now;

  final Uri url;
  final Directory directory;
  final Duration refreshEvery;
  final http.Client _client;
  final DateTime Function() _clock;

  StockManifest? _memory;

  File get _file => File(p.join(directory.path, 'manifest.json'));
  File get _meta => File(p.join(directory.path, 'manifest.meta.json'));

  Future<StockManifest> load() async {
    final meta = await _readMeta();
    final cached = _memory ?? await _readCached();
    final fetchedAt = meta['fetchedAt'] is String
        ? DateTime.tryParse(meta['fetchedAt'] as String)
        : null;
    final fresh =
        fetchedAt != null && _clock().difference(fetchedAt) < refreshEvery;
    if (cached != null && fresh) return _memory = cached;

    try {
      final res = await _client
          .get(
            url,
            headers: {
              if (cached != null && meta['etag'] is String)
                'If-None-Match': meta['etag'] as String,
            },
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 304 && cached != null) {
        await _writeMeta({...meta, 'fetchedAt': _clock().toIso8601String()});
        return _memory = cached;
      }
      if (res.statusCode != 200) {
        throw HttpException('HTTP ${res.statusCode}', uri: url);
      }
      final manifest = StockManifest.parse(
        (jsonDecode(res.body) as Map).cast<String, Object?>(),
      );
      await directory.create(recursive: true);
      await _file.writeAsString(res.body);
      await _writeMeta({
        'fetchedAt': _clock().toIso8601String(),
        if (res.headers['etag'] != null) 'etag': res.headers['etag'],
      });
      return _memory = manifest;
    } catch (e) {
      if (cached != null) return _memory = cached;
      rethrow;
    }
  }

  Future<StockManifest?> _readCached() async {
    try {
      if (!await _file.exists()) return null;
      return StockManifest.parse(
        (jsonDecode(await _file.readAsString()) as Map).cast<String, Object?>(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, Object?>> _readMeta() async {
    try {
      if (!await _meta.exists()) return const {};
      return (jsonDecode(await _meta.readAsString()) as Map)
          .cast<String, Object?>();
    } catch (_) {
      return const {};
    }
  }

  Future<void> _writeMeta(Map<String, Object?> m) async {
    try {
      await directory.create(recursive: true);
      await _meta.writeAsString(jsonEncode(m));
    } catch (_) {}
  }
}
