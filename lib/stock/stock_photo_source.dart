import 'dart:io';

import 'package:countdowns/stock/stock_categories.dart';
import 'package:material_ui/material_ui.dart';

/// A free-to-use photo the person can pick as a background. Nothing here is
/// specific to where the photo comes from.
class StockPhoto {
  const StockPhoto({
    required this.id,
    required this.thumbnailUrl,
    required this.fullUrl,
    required this.width,
    required this.height,
    required this.averageColor,
    required this.photographer,
    required this.photographerUrl,
    required this.pageUrl,
  });

  final String id;
  final String thumbnailUrl;

  /// Around 2000px on the long edge: big enough for every crop shape.
  final String fullUrl;
  final int width, height;

  /// Shown while the thumbnail loads.
  final Color averageColor;
  final String photographer;
  final String photographerUrl;
  final String pageUrl;

  Map<String, Object?> toJson() => {
    'id': id,
    'thumbnailUrl': thumbnailUrl,
    'fullUrl': fullUrl,
    'width': width,
    'height': height,
    'averageColor': averageColor.toARGB32(),
    'photographer': photographer,
    'photographerUrl': photographerUrl,
    'pageUrl': pageUrl,
  };

  factory StockPhoto.fromJson(Map<String, Object?> j) => StockPhoto(
    id: j['id']! as String,
    thumbnailUrl: j['thumbnailUrl']! as String,
    fullUrl: j['fullUrl']! as String,
    width: j['width']! as int,
    height: j['height']! as int,
    averageColor: Color(j['averageColor']! as int),
    photographer: j['photographer']! as String,
    photographerUrl: j['photographerUrl']! as String,
    pageUrl: j['pageUrl']! as String,
  );
}

/// One page of results.
class StockPage {
  const StockPage(this.photos, {required this.hasMore});
  final List<StockPhoto> photos;
  final bool hasMore;

  Map<String, Object?> toJson() => {
    'photos': [for (final p in photos) p.toJson()],
    'hasMore': hasMore,
  };

  factory StockPage.fromJson(Map<String, Object?> j) => StockPage([
    for (final p in j['photos']! as List)
      StockPhoto.fromJson((p as Map).cast<String, Object?>()),
  ], hasMore: j['hasMore']! as bool);
}

/// Too many requests for now; try again shortly.
class StockRateLimited implements Exception {
  const StockRateLimited();
  @override
  String toString() => 'StockRateLimited';
}

/// The source couldn't be reached or answered with an error.
class StockUnavailable implements Exception {
  const StockUnavailable(this.reason);
  final String reason;
  @override
  String toString() => 'StockUnavailable: $reason';
}

/// Where stock photos come from. Swapping providers (for example from
/// Pexels to our own catalogue on Cloudflare) means writing one class that
/// implements this, and nothing else in the app changes.
abstract class StockPhotoSource {
  /// "Photos provided by …" text and link, shown in the Photos tab.
  String get attribution;
  Uri get attributionUrl;

  /// The browsable categories. Our own list by default (see
  /// stock_categories.dart); a source may narrow it.
  Future<List<StockCategory>> categories() async => stockCategories;

  Future<StockPage> photos(StockCategory category, int page);
  Future<StockPage> search(String query, int page);

  /// Downloads the full-size photo to a local file. [onProgress] gets 0–1
  /// (or null while the size is unknown).
  Future<File> download(
    StockPhoto photo, {
    void Function(double? progress)? onProgress,
  });
}
