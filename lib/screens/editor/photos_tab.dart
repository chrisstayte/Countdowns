import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:countdowns/models/background_catalog.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/screens/editor/all_backgrounds_sheet.dart';
import 'package:countdowns/stock/stock_categories.dart';
import 'package:countdowns/stock/stock_photo_source.dart';
import 'package:countdowns/stock/stock_provider.dart';
import 'package:countdowns/stock/stock_recents.dart';
import 'package:countdowns/storage/photo_credits.dart';
import 'package:countdowns/storage/photos.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/utilities/feedback.dart';
import 'package:countdowns/widgets/ui.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// What the sheet returns after a stock photo is downloaded and imported:
/// the editor then crops it exactly like a photo from the camera roll,
/// starting at the photo's focal point when it has one.
class ImportedPhoto {
  const ImportedPhoto(this.path, {this.focal});
  final String path;
  final Offset? focal;

  /// Every crop shape starting on the focal point (centred without one).
  PhotoCrops get startCrops {
    final f = focal;
    if (f == null) return const PhotoCrops();
    final point = CropPoint(
      (f.dx * 2 - 1).clamp(-1.0, 1.0),
      (f.dy * 2 - 1).clamp(-1.0, 1.0),
    );
    return PhotoCrops(points: {for (final s in CropShape.values) s: point});
  }
}

/// The name stored with a downloaded photo's credit.
const stockSourceName = 'Countdowns catalogue';

/// Imports a downloaded stock photo into the app's photo store with its
/// credit, and removes the temporary download. Returns the stored path.
Future<String> importStockPhoto(File download, StockPhoto photo) async {
  final path = await PhotoStore.instance.import(download.path);
  await PhotoCredit.write(
    path,
    PhotoCredit(
      photographer: photo.photographer,
      photographerUrl: photo.photographerUrl,
      pageUrl: photo.pageUrl,
      source: stockSourceName,
      id: photo.id,
      license: photo.license,
    ),
  );
  try {
    await download.delete();
  } catch (_) {}
  return path;
}

/// A recently used stock photo whose downloaded copy is still on the
/// device, so it can be used again offline.
bool isDownloaded(StockPhoto p) {
  final local = p.localPath;
  return local != null &&
      PhotoStore.ready &&
      PhotoStore.instance.fileFor(local).existsSync();
}

/// Which placeholder a tile shows while its thumbnail loads.
enum PlaceholderKind { blurHash, colour, wash }

PlaceholderKind placeholderFor(StockPhoto p) {
  if (p.blurHash != null && isValidBlurHash(p.blurHash!)) {
    return PlaceholderKind.blurHash;
  }
  if (p.averageColor != null) return PlaceholderKind.colour;
  return PlaceholderKind.wash;
}

const _base83 =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
    r'#$%*+,-.:;=?@[]^_{|}~';

/// A well-formed blurhash: base 83, and as long as its size flag says.
bool isValidBlurHash(String h) {
  if (h.length < 6) return false;
  for (final c in h.split('')) {
    if (!_base83.contains(c)) return false;
  }
  final flag = _base83.indexOf(h[0]);
  final nx = flag % 9 + 1, ny = flag ~/ 9 + 1;
  return h.length == 4 + 2 * nx * ny;
}

/// The All backgrounds sheet's Photos tab, top to bottom: your own photos;
/// then from the stock catalogue a search field, Recently used, and one
/// swipeable row per category (seasonal and title-matched first). When
/// the catalogue is loading, switched off or can't be reached, the stock
/// part isn't there at all: no message, no search, no headings. Only stock
/// photos already downloaded stay, under Recently used, because they work
/// without the network.
class PhotosTab extends ConsumerStatefulWidget {
  const PhotosTab({
    super.key,
    required this.draft,
    required this.photos,
    required this.selected,
    required this.onPick,
    required this.onAdd,
    required this.onImported,
    this.now,
  });

  final Countdown draft;
  final List<String> photos;
  final String selected;
  final ValueChanged<String> onPick;
  final VoidCallback onAdd;
  final ValueChanged<ImportedPhoto> onImported;

  /// Today, for seasonal ordering (tests pass a fixed date).
  final DateTime? now;

  @override
  ConsumerState<PhotosTab> createState() => _PhotosTabState();
}

enum _Status { loading, ready, hidden }

class _PhotosTabState extends ConsumerState<PhotosTab> {
  _Status _status = _Status.loading;
  List<StockCategory> _categories = const [];
  final Map<String, List<StockPhoto>> _rows = {};

  String _query = '';
  Timer? _debounce;
  List<StockPhoto> _results = const [];

  /// "See all" for one category: a grid that loads more as you scroll.
  StockCategory? _seeAll;
  final List<StockPhoto> _grid = [];
  int _gridPage = 0;
  bool _gridMore = true;
  bool _gridLoading = false;

  String? _downloadingId;
  double? _progress;
  StockPhoto? _failed;
  bool _failedRateLimited = false;

  StockPhotoSource? get _source => ref.read(stockPhotoSourceProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final source = _source;
    if (source == null) {
      setState(() => _status = _Status.hidden);
      return;
    }
    try {
      final cats = await source.categories();
      if (cats.isEmpty) {
        if (mounted) setState(() => _status = _Status.hidden);
        return;
      }
      final ordered = orderCategories(
        cats,
        widget.now ?? DateTime.now(),
        eventDate: widget.draft.dateTime,
        title: widget.draft.title,
      );
      final rows = <String, List<StockPhoto>>{};
      for (final c in ordered) {
        rows[c.id] = (await source.photos(c, 1)).photos;
      }
      if (!mounted) return;
      setState(() {
        _categories = [
          for (final c in ordered)
            if (rows[c.id]!.isNotEmpty) c,
        ];
        _rows
          ..clear()
          ..addAll(rows);
        _status = _Status.ready;
      });
    } catch (e) {
      debugPrint('Stock catalogue unavailable: $e');
      if (mounted) setState(() => _status = _Status.hidden);
    }
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted) return;
      final q = value.trim();
      _query = q;
      if (q.isEmpty) {
        setState(() => _results = const []);
        return;
      }
      try {
        final page = await _source!.search(q, 1);
        if (mounted && _query == q) setState(() => _results = page.photos);
      } catch (_) {
        if (mounted) setState(() => _results = const []);
      }
    });
  }

  Future<void> _openSeeAll(StockCategory c) async {
    feedback(ref, Sound.select, false);
    setState(() {
      _seeAll = c;
      _grid.clear();
      _gridPage = 0;
      _gridMore = true;
    });
    await _moreGrid();
  }

  Future<void> _moreGrid() async {
    final c = _seeAll;
    if (c == null || _gridLoading || !_gridMore) return;
    _gridLoading = true;
    try {
      final page = await _source!.photos(c, _gridPage + 1);
      if (!mounted || _seeAll != c) return;
      setState(() {
        _grid.addAll(page.photos);
        _gridPage++;
        _gridMore = page.hasMore;
      });
    } catch (_) {
      if (mounted) setState(() => _gridMore = false);
    } finally {
      _gridLoading = false;
    }
  }

  Future<void> _download(StockPhoto photo) async {
    if (_downloadingId != null) return;
    // Picked before and still on the device: use that copy, no network.
    final local = photo.localPath;
    if (local != null && isDownloaded(photo)) {
      feedback(ref, Sound.select);
      await ref.read(stockRecentsProvider.notifier).use(photo);
      if (mounted) widget.onImported(ImportedPhoto(local, focal: photo.focal));
      return;
    }
    final source = _source;
    if (source == null) return;
    feedback(ref, Sound.select);
    setState(() {
      _downloadingId = photo.id;
      _progress = null;
      _failed = null;
    });
    try {
      final file = await source.download(
        photo,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      final path = await importStockPhoto(file, photo);
      await ref
          .read(stockRecentsProvider.notifier)
          .use(photo.withLocalPath(path));
      if (!mounted) return;
      widget.onImported(ImportedPhoto(path, focal: photo.focal));
    } catch (e) {
      debugPrint('Stock download failed: $e');
      if (!mounted) return;
      setState(() {
        _downloadingId = null;
        _failed = photo;
        _failedRateLimited = e is StockRateLimited;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final credit = PhotoCredit.read(widget.draft.photoPath);
    return CustomScrollView(
      slivers: [
        const _Heading('YOUR PHOTOS'),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.photos.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => SizedBox(
                width: 84,
                child: i == 0
                    ? AddPhotoTile(onTap: widget.onAdd)
                    : _OwnPhoto(
                        path: widget.photos[i - 1],
                        selected:
                            photoKey(widget.photos[i - 1]) == widget.selected,
                        onTap: () =>
                            widget.onPick(photoKey(widget.photos[i - 1])),
                      ),
              ),
            ),
          ),
        ),
        if (credit != null && credit.photographer.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.only(top: 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Current photo by ${credit.photographer}',
                style: AppText.secondary.copyWith(fontSize: 12),
              ),
            ),
          ),
        ..._stock(context),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  List<Widget> _recentRow(List<StockPhoto> recents) => [
    if (recents.isNotEmpty) ...[
      const _Heading('RECENTLY USED'),
      SliverToBoxAdapter(
        child: _Row(
          key: const ValueKey('stock-recents'),
          photos: recents,
          tile: _tile,
        ),
      ),
    ],
  ];

  List<Widget> _stock(BuildContext context) {
    final recents = ref.watch(stockRecentsProvider);
    // Loading, switched off or unreachable: as if there were no catalogue,
    // apart from photos already on the device.
    if (_status != _Status.ready) {
      return _recentRow(recents.where(isDownloaded).toList());
    }
    final seeAll = _seeAll;
    return [
      SliverPadding(
        padding: const EdgeInsets.only(top: 22, bottom: 4),
        sliver: SliverToBoxAdapter(
          child: TextField(
            key: const ValueKey('stock-search'),
            onChanged: _onSearch,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Search photos',
              filled: true,
              fillColor: AppColors.wash,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
      if (_failed != null)
        SliverPadding(
          padding: const EdgeInsets.only(top: 12),
          sliver: SliverToBoxAdapter(
            child: _Notice(
              text: _failedRateLimited
                  ? 'Too many downloads at once. Try again shortly.'
                  : 'Couldn’t download that photo.',
              action: 'Retry',
              onAction: () => _download(_failed!),
            ),
          ),
        ),
      if (_query.isNotEmpty) ...[
        _Heading('RESULTS FOR “${_query.toUpperCase()}”'),
        if (_results.isEmpty)
          const SliverToBoxAdapter(
            child: Text('No photos match.', style: AppText.secondary),
          )
        else
          _gridOf(_results),
      ] else if (seeAll != null) ...[
        SliverPadding(
          padding: const EdgeInsets.only(top: 18, bottom: 10),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Back to all categories',
                  child: GestureDetector(
                    onTap: () => setState(() => _seeAll = null),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(seeAll.label.toUpperCase(), style: AppText.eyebrow),
              ],
            ),
          ),
        ),
        _gridOf(_grid, onNearEnd: _moreGrid),
      ] else ...[
        ..._recentRow(recents),
        for (final c in _categories) ...[
          _Heading(
            c.label.toUpperCase(),
            trailing: (_rows[c.id]?.length ?? 0) >= 6
                ? Semantics(
                    button: true,
                    label: 'See all ${c.label}',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => _openSeeAll(c),
                      child: const Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          SliverToBoxAdapter(
            child: _Row(
              key: ValueKey('stock-row-${c.id}'),
              photos: _rows[c.id]!,
              tile: _tile,
            ),
          ),
        ],
      ],
    ];
  }

  Widget _tile(StockPhoto photo) => StockTile(
    photo: photo,
    downloading: photo.id == _downloadingId,
    progress: photo.id == _downloadingId ? _progress : null,
    onTap: () => _download(photo),
  );

  Widget _gridOf(List<StockPhoto> photos, {VoidCallback? onNearEnd}) =>
      SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 130,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        itemCount: photos.length,
        itemBuilder: (_, i) {
          if (onNearEnd != null && i >= photos.length - 6) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) onNearEnd();
            });
          }
          return _tile(photos[i]);
        },
      );
}

/// Row height for category and recent rows; widths follow each photo's
/// aspect ratio so nothing jumps when the image arrives.
const stockRowHeight = 132.0;

double stockTileWidth(StockPhoto p) =>
    (stockRowHeight * p.aspect).clamp(stockRowHeight * 0.55, 260.0);

class _Row extends StatelessWidget {
  const _Row({super.key, required this.photos, required this.tile});
  final List<StockPhoto> photos;
  final Widget Function(StockPhoto) tile;

  @override
  Widget build(BuildContext context) => BleedScroller(
    height: stockRowHeight,
    itemCount: photos.length,
    itemBuilder: (_, i) =>
        SizedBox(width: stockTileWidth(photos[i]), child: tile(photos[i])),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    sliver: SliverToBoxAdapter(
      child: Row(
        children: [
          Expanded(child: Text(text, style: AppText.eyebrow)),
          ?trailing,
        ],
      ),
    ),
  );
}

class _OwnPhoto extends StatelessWidget {
  const _OwnPhoto({
    required this.path,
    required this.selected,
    required this.onTap,
  });
  final String path;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: 'Photo',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.ink : Colors.transparent,
            width: 3,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: PhotoStore.ready
              ? Image(
                  image: ResizeImage(
                    FileImage(PhotoStore.instance.fileFor(path)),
                    width: 200,
                  ),
                  fit: BoxFit.cover,
                )
              : const ColoredBox(color: AppColors.wash),
        ),
      ),
    ),
  );
}

/// A stock photo tile: placeholder (blurhash, else average colour, else
/// Wash), then the thumbnail. Shows download progress and the credit.
class StockTile extends StatelessWidget {
  const StockTile({
    super.key,
    required this.photo,
    required this.onTap,
    this.downloading = false,
    this.progress,
  });

  final StockPhoto photo;
  final bool downloading;
  final double? progress;
  final VoidCallback onTap;

  Widget _placeholder() => switch (placeholderFor(photo)) {
    PlaceholderKind.blurHash => BlurHash(
      hash: photo.blurHash!,
      imageFit: BoxFit.cover,
      color: photo.averageColor ?? AppColors.wash,
    ),
    PlaceholderKind.colour => ColoredBox(color: photo.averageColor!),
    PlaceholderKind.wash => const ColoredBox(color: AppColors.wash),
  };

  Widget _image() {
    if (isDownloaded(photo)) {
      return Image(
        image: ResizeImage(
          FileImage(PhotoStore.instance.fileFor(photo.localPath!)),
          width: 400,
        ),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }
    final url = photo.thumbnailUrl;
    if (!url.startsWith('http')) return const SizedBox.shrink();
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, _) => const SizedBox.shrink(),
      errorWidget: (_, _, _) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: photo.photographer.isEmpty
        ? 'Photo'
        : 'Photo by ${photo.photographer}',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _placeholder(),
              _image(),
              if (downloading) ...[
                const ColoredBox(color: Color(0x88120F22)),
                Center(
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
                if (photo.photographer.isNotEmpty)
                  Positioned(
                    left: 6,
                    right: 6,
                    bottom: 6,
                    child: Text(
                      'Photo by ${photo.photographer}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.text,
    required this.action,
    required this.onAction,
  });
  final String text, action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
    decoration: BoxDecoration(
      color: AppColors.wash,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Expanded(child: Text(text, style: AppText.secondary)),
        const SizedBox(width: 8),
        PillButton(label: action, height: 36, onTap: onAction),
      ],
    ),
  );
}
