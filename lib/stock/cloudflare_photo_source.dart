import 'dart:io';
import 'dart:typed_data';

import 'package:countdowns/stock/stock_categories.dart';
import 'package:countdowns/stock/stock_manifest.dart';
import 'package:countdowns/stock/stock_photo_source.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// Our own catalogue on Cloudflare R2 (design/photo-catalogue/PLAN.md):
/// a public manifest plus pre-optimised photos on
/// media.countdowns.stayte.app. No key, no server code. Everything is
/// filtered and searched on the device.
class CloudflarePhotoSource extends StockPhotoSource {
  CloudflarePhotoSource({
    required this.manifest,
    required this.downloads,
    http.Client? client,
    this.readAsset,
    this.categoryList = stockCategories,
  }) : _client = client ?? http.Client();

  static final manifestUrl = Uri.parse(
    'https://media.countdowns.stayte.app/catalog/v1/manifest.json',
  );

  /// Loads the manifest (the network store, or the debug sample).
  final Future<StockManifest> Function() manifest;
  final Directory downloads;
  final http.Client _client;

  /// Reads `asset:` URLs (the debug sample catalogue).
  final Future<Uint8List> Function(String url)? readAsset;
  final List<StockCategory> categoryList;

  static const pageSize = 30;

  Future<StockManifest> _load() async {
    try {
      return await manifest();
    } on StockUnavailable {
      rethrow;
    } catch (e) {
      throw StockUnavailable('$e');
    }
  }

  @override
  Future<List<StockCategory>> categories() async {
    final m = await _load();
    if (!m.enabled) return const [];
    final used = {for (final ph in m.photos) ...ph.categories};
    return [
      for (final c in categoryList)
        if (used.contains(c.id)) c,
    ];
  }

  StockPage _page(List<StockPhoto> all, int page) {
    final start = (page - 1) * pageSize;
    if (start >= all.length || page < 1) {
      return const StockPage([], hasMore: false);
    }
    final end = (start + pageSize).clamp(0, all.length);
    return StockPage(all.sublist(start, end), hasMore: end < all.length);
  }

  @override
  Future<StockPage> photos(StockCategory category, int page) async {
    final m = await _load();
    if (!m.enabled) return const StockPage([], hasMore: false);
    final inCat = m.photos
        .where((ph) => ph.categories.contains(category.id))
        .toList();
    // The category's cover, if set, leads.
    final cover = m.covers[category.id];
    if (cover != null) {
      final i = inCat.indexWhere((ph) => ph.id == cover);
      if (i > 0) inCat.insert(0, inCat.removeAt(i));
    }
    return _page(inCat, page);
  }

  @override
  Future<StockPage> search(String query, int page) async {
    final m = await _load();
    if (!m.enabled) return const StockPage([], hasMore: false);
    return _page(searchPhotos(m.photos, query, categoryList), page);
  }

  @override
  Future<File> download(
    StockPhoto photo, {
    void Function(double? progress)? onProgress,
  }) async {
    await downloads.create(recursive: true);
    final out = File(p.join(downloads.path, '${photo.id}.jpg'));
    if (photo.fullUrl.startsWith('asset:')) {
      final read = readAsset;
      if (read == null) throw const StockUnavailable('No asset reader');
      onProgress?.call(null);
      await out.writeAsBytes(await read(photo.fullUrl));
      onProgress?.call(1);
      return out;
    }
    final http.StreamedResponse res;
    try {
      res = await _client
          .send(http.Request('GET', Uri.parse(photo.fullUrl)))
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw StockUnavailable('$e');
    }
    if (res.statusCode == 429) throw const StockRateLimited();
    if (res.statusCode != 200) {
      throw StockUnavailable('HTTP ${res.statusCode}');
    }
    final sink = out.openWrite();
    final total = res.contentLength;
    var got = 0;
    try {
      await for (final chunk in res.stream) {
        sink.add(chunk);
        got += chunk.length;
        onProgress?.call(total == null || total == 0 ? null : got / total);
      }
      await sink.close();
    } catch (e) {
      await sink.close();
      if (await out.exists()) await out.delete();
      throw StockUnavailable('$e');
    }
    return out;
  }
}

/// On-device search: every word must match a photo's tags, its category
/// ids, or its categories' labels and title keywords. Best matches (more
/// tag hits) first.
List<StockPhoto> searchPhotos(
  List<StockPhoto> photos,
  String query,
  List<StockCategory> categories,
) {
  final words = query
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.length > 1)
      .toList();
  if (words.isEmpty) return const [];
  final byId = {for (final c in categories) c.id: c};
  final scored = <(StockPhoto, int)>[];
  for (final ph in photos) {
    final tags = ph.tags.map((t) => t.toLowerCase()).toList();
    final cats = [
      for (final id in ph.categories) ...[
        id.replaceAll('-', ' '),
        if (byId[id] case final c?) ...[c.label.toLowerCase(), ...c.keywords],
      ],
    ];
    var score = 0;
    var all = true;
    for (final w in words) {
      final inTags = tags.any((t) => t.contains(w));
      final inCats = cats.any((c) => c.contains(w));
      if (!inTags && !inCats) {
        all = false;
        break;
      }
      score += inTags ? 2 : 1;
    }
    if (all) scored.add((ph, score));
  }
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final (ph, _) in scored) ph];
}
