import 'dart:convert';
import 'dart:io';

import 'package:countdowns/stock/stock_cache.dart';
import 'package:countdowns/stock/stock_categories.dart';
import 'package:countdowns/stock/stock_photo_source.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

/// Stock photos from Pexels (https://www.pexels.com/api/). The only file
/// that knows about Pexels. Requests carry just the search words, the page
/// and the API key: no user data.
class PexelsPhotoSource extends StockPhotoSource {
  PexelsPhotoSource({
    required this.apiKey,
    required this.cache,
    required this.downloads,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final StockCache cache;

  /// Where downloaded photos land before the app imports them.
  final Directory downloads;
  final http.Client _client;

  static const _perPage = 30;

  @override
  String get attribution => 'Photos provided by Pexels';

  @override
  Uri get attributionUrl => Uri.parse('https://www.pexels.com');

  @override
  Future<StockPage> photos(StockCategory category, int page) =>
      search(category.query, page);

  @override
  Future<StockPage> search(String query, int page) async {
    final q = query.trim().toLowerCase();
    final key = 'pexels:$q:$page';
    final cached = await cache.read(key);
    if (cached != null) return StockPage.fromJson(cached);
    final uri = Uri.https('api.pexels.com', '/v1/search', {
      'query': q,
      'page': '$page',
      'per_page': '$_perPage',
    });
    final http.Response res;
    try {
      res = await _client
          .get(uri, headers: {'Authorization': apiKey})
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw StockUnavailable('$e');
    }
    if (res.statusCode == 429) throw const StockRateLimited();
    if (res.statusCode != 200) {
      throw StockUnavailable('HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, Object?>;
    final result = StockPage([
      for (final raw in (body['photos'] as List? ?? const []))
        _photo((raw as Map).cast<String, Object?>()),
    ], hasMore: body['next_page'] != null);
    await cache.write(key, result.toJson());
    return result;
  }

  static StockPhoto _photo(Map<String, Object?> j) {
    final src = (j['src']! as Map).cast<String, Object?>();
    final w = (j['width'] as num).toInt(), h = (j['height'] as num).toInt();
    final original = src['original']! as String;
    // Pexels resizes on request: about 2000px on the long edge.
    final full =
        '$original?auto=compress&cs=tinysrgb&${w >= h ? 'w' : 'h'}=2000';
    final avg = (j['avg_color'] as String?) ?? '#B3A08E';
    return StockPhoto(
      id: 'pexels-${j['id']}',
      thumbnailUrl: (src['medium'] ?? src['small'] ?? original) as String,
      fullUrl: full,
      width: w,
      height: h,
      averageColor: Color(
        0xFF000000 | int.parse(avg.replaceFirst('#', ''), radix: 16),
      ),
      photographer: (j['photographer'] as String?) ?? 'Unknown',
      photographerUrl: (j['photographer_url'] as String?) ?? '',
      pageUrl: (j['url'] as String?) ?? '',
    );
  }

  @override
  Future<File> download(
    StockPhoto photo, {
    void Function(double? progress)? onProgress,
  }) async {
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
    await downloads.create(recursive: true);
    final out = File(p.join(downloads.path, '${photo.id}.jpg'));
    final sink = out.openWrite();
    final total = res.contentLength;
    var got = 0;
    try {
      await for (final chunk in res.stream) {
        sink.add(chunk);
        got += chunk.length;
        onProgress?.call(total == null || total == 0 ? null : got / total);
      }
    } catch (e) {
      await sink.close();
      if (await out.exists()) await out.delete();
      throw StockUnavailable('$e');
    }
    await sink.close();
    return out;
  }
}
