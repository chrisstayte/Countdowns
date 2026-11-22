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
    this.averageColor,
    this.blurHash,
    this.categories = const [],
    this.tags = const [],
    this.photographer = '',
    this.photographerUrl = '',
    this.pageUrl = '',
    this.license = '',
    this.focal,
    this.localPath,
  });

  final String id;
  final String thumbnailUrl;

  /// The size downloaded when picked (about 2560px on the long edge).
  final String fullUrl;
  final int width, height;

  /// Placeholders while the thumbnail loads, best first: the blurhash, then
  /// this colour, then Wash.
  final Color? averageColor;
  final String? blurHash;

  /// App category ids (see stock_categories.dart).
  final List<String> categories;
  final List<String> tags;

  /// Credit, all optional (empty for our own photos).
  final String photographer;
  final String photographerUrl;
  final String pageUrl;

  /// `CC0-1.0`, `PDM-1.0`, `owned`, `commissioned`, or empty.
  final String license;

  /// Where the subject is, 0–1 across and down; the crop screen starts there.
  final Offset? focal;

  /// Recently used photos only: where the downloaded copy is in the app's
  /// photo store, so it can be used again without the network.
  final String? localPath;

  double get aspect => height == 0 ? 1 : width / height;

  StockPhoto withLocalPath(String? path) => StockPhoto(
    id: id,
    thumbnailUrl: thumbnailUrl,
    fullUrl: fullUrl,
    width: width,
    height: height,
    averageColor: averageColor,
    blurHash: blurHash,
    categories: categories,
    tags: tags,
    photographer: photographer,
    photographerUrl: photographerUrl,
    pageUrl: pageUrl,
    license: license,
    focal: focal,
    localPath: path,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'thumbnailUrl': thumbnailUrl,
    'fullUrl': fullUrl,
    'width': width,
    'height': height,
    'averageColor': averageColor?.toARGB32(),
    'blurHash': blurHash,
    'categories': categories,
    'tags': tags,
    'photographer': photographer,
    'photographerUrl': photographerUrl,
    'pageUrl': pageUrl,
    'license': license,
    if (focal != null) 'focal': [focal!.dx, focal!.dy],
    if (localPath != null) 'localPath': localPath,
  };

  /// Tolerant: missing optional fields are fine, unknown ones are ignored.
  static StockPhoto? fromJson(Map<String, Object?> j) {
    final id = j['id'], thumb = j['thumbnailUrl'], full = j['fullUrl'];
    if (id is! String || thumb is! String || full is! String) return null;
    List<String> strings(Object? v) => v is List
        ? [
            for (final x in v)
              if (x is String) x,
          ]
        : const [];
    final f = j['focal'];
    return StockPhoto(
      id: id,
      thumbnailUrl: thumb,
      fullUrl: full,
      width: (j['width'] as num?)?.toInt() ?? 1,
      height: (j['height'] as num?)?.toInt() ?? 1,
      averageColor: j['averageColor'] is int
          ? Color(j['averageColor']! as int)
          : null,
      blurHash: j['blurHash'] as String?,
      categories: strings(j['categories']),
      tags: strings(j['tags']),
      photographer: j['photographer'] as String? ?? '',
      photographerUrl: j['photographerUrl'] as String? ?? '',
      pageUrl: j['pageUrl'] as String? ?? '',
      license: j['license'] as String? ?? '',
      focal: f is List && f.length == 2 && f[0] is num && f[1] is num
          ? Offset((f[0] as num).toDouble(), (f[1] as num).toDouble())
          : null,
      localPath: j['localPath'] is String ? j['localPath'] as String : null,
    );
  }
}

/// One page of results.
class StockPage {
  const StockPage(this.photos, {required this.hasMore});
  final List<StockPhoto> photos;
  final bool hasMore;
}

/// Too many requests for now; try again shortly.
class StockRateLimited implements Exception {
  const StockRateLimited();
  @override
  String toString() => 'StockRateLimited';
}

/// The source couldn't be reached or answered with something unusable.
class StockUnavailable implements Exception {
  const StockUnavailable(this.reason);
  final String reason;
  @override
  String toString() => 'StockUnavailable: $reason';
}

/// Where stock photos come from. The app only knows this interface, so a
/// different source is one new class plus a one-line change in
/// stock_provider.dart.
abstract class StockPhotoSource {
  /// The app's categories that have photos, in the app's own order (the
  /// Photos tab reorders them by season and title). Empty when stock photos
  /// are switched off. Throws [StockUnavailable] when there is nothing to
  /// show (no network and nothing cached).
  Future<List<StockCategory>> categories();

  Future<StockPage> photos(StockCategory category, int page);
  Future<StockPage> search(String query, int page);

  /// Downloads the full-size photo to a local file. [onProgress] gets 0–1
  /// (or null while the size is unknown).
  Future<File> download(
    StockPhoto photo, {
    void Function(double? progress)? onProgress,
  });
}
