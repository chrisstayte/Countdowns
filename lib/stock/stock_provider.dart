import 'dart:convert';
import 'dart:io';

import 'package:countdowns/stock/cloudflare_photo_source.dart';
import 'package:countdowns/stock/manifest_store.dart';
import 'package:countdowns/stock/stock_manifest.dart';
import 'package:countdowns/stock/stock_photo_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Where the app keeps disposable files (manifest cache, downloads); set
/// at startup.
Directory? stockCacheRoot;

/// Debug builds only: `--dart-define=STOCK_FIXTURE=true` loads the bundled
/// sample catalogue (assets/dev/stock/) instead of the network, so the
/// layout can be seen before the real catalogue is live.
const _useFixture = bool.fromEnvironment('STOCK_FIXTURE');
bool get stockFixtureOn => kDebugMode && _useFixture;

const fixtureManifestAsset = 'assets/dev/stock/manifest.json';

Future<Uint8List> readStockAsset(String url) async {
  final path = url.replaceFirst(RegExp(r'^asset:/*'), '');
  return (await rootBundle.load(path)).buffer.asUint8List();
}

/// The stock photo source, or null when there's nowhere to keep files.
final stockPhotoSourceProvider = Provider<StockPhotoSource?>((ref) {
  final root = stockCacheRoot;
  if (root == null) return null;
  final downloads = Directory(p.join(root.path, 'stock-downloads'));
  if (stockFixtureOn) {
    return CloudflarePhotoSource(
      manifest: () async => StockManifest.parse(
        (jsonDecode(await rootBundle.loadString(fixtureManifestAsset)) as Map)
            .cast<String, Object?>(),
      ),
      downloads: downloads,
      readAsset: readStockAsset,
    );
  }
  final store = ManifestStore(
    url: CloudflarePhotoSource.manifestUrl,
    directory: Directory(p.join(root.path, 'stock-manifest')),
  );
  return CloudflarePhotoSource(manifest: store.load, downloads: downloads);
});
