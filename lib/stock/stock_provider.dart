import 'dart:io';

import 'package:countdowns/stock/cloudflare_photo_source.dart';
import 'package:countdowns/stock/manifest_store.dart';
import 'package:countdowns/stock/stock_photo_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Where the app keeps disposable files (manifest cache, downloads); set
/// at startup.
Directory? stockCacheRoot;

/// The stock photo source, or null when there's nowhere to keep files.
/// Every build, debug included, reads the live catalogue.
final stockPhotoSourceProvider = Provider<StockPhotoSource?>((ref) {
  final root = stockCacheRoot;
  if (root == null) return null;
  final store = ManifestStore(
    url: CloudflarePhotoSource.manifestUrl,
    directory: Directory(p.join(root.path, 'stock-manifest')),
  );
  return CloudflarePhotoSource(
    manifest: store.load,
    downloads: Directory(p.join(root.path, 'stock-downloads')),
  );
});
