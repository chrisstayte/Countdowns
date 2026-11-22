import 'dart:io';

import 'package:countdowns/stock/pexels_photo_source.dart';
import 'package:countdowns/stock/stock_cache.dart';
import 'package:countdowns/stock/stock_photo_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Set at build time: `--dart-define=PEXELS_API_KEY=…` (see README).
const _pexelsKey = String.fromEnvironment('PEXELS_API_KEY');

/// Where the app keeps temporary files; set at startup.
Directory? stockCacheRoot;

/// The stock photo source, or null when none is configured (no API key):
/// the Photos tab then shows only the person's own photos.
final stockPhotoSourceProvider = Provider<StockPhotoSource?>((ref) {
  final root = stockCacheRoot;
  if (_pexelsKey.isEmpty || root == null) return null;
  return PexelsPhotoSource(
    apiKey: _pexelsKey,
    cache: StockCache(Directory(p.join(root.path, 'stock-pages'))),
    downloads: Directory(p.join(root.path, 'stock-downloads')),
  );
});
