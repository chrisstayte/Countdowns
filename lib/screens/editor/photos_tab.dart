import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:countdowns/models/background_catalog.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/screens/editor/all_backgrounds_sheet.dart';
import 'package:countdowns/stock/stock_categories.dart';
import 'package:countdowns/stock/stock_photo_source.dart';
import 'package:countdowns/stock/stock_provider.dart';
import 'package:countdowns/storage/photo_credits.dart';
import 'package:countdowns/storage/photos.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/utilities/feedback.dart';
import 'package:countdowns/widgets/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// What the sheet returns after a stock photo is downloaded and imported:
/// the editor then crops it exactly like a photo from the camera roll.
class ImportedPhoto {
  const ImportedPhoto(this.path);
  final String path;
}

/// Imports a downloaded stock photo into the app's photo store with its
/// credit, and removes the temporary download. Returns the stored path.
Future<String> importStockPhoto(
  File download,
  StockPhoto photo,
  String source,
) async {
  final path = await PhotoStore.instance.import(download.path);
  await PhotoCredit.write(
    path,
    PhotoCredit(
      photographer: photo.photographer,
      photographerUrl: photo.photographerUrl,
      pageUrl: photo.pageUrl,
      source: source,
    ),
  );
  try {
    await download.delete();
  } catch (_) {}
  return path;
}

/// The All backgrounds sheet's Photos tab: your own photos, then (when a
/// stock source is configured) search, category chips and a grid of free
/// photos that loads more as you scroll.
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
  final ValueChanged<String> onImported;

  /// Today, for seasonal ordering (tests pass a fixed date).
  final DateTime? now;

  @override
  ConsumerState<PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends ConsumerState<PhotosTab> {
  List<StockCategory> _categories = const [];
  StockCategory? _category;
  String _query = '';
  Timer? _debounce;

  final List<StockPhoto> _results = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  /// Bumped whenever the query or category changes, so late answers for an
  /// older request are dropped.
  int _generation = 0;

  String? _downloadingId;
  double? _progress;
  StockPhoto? _failed;

  StockPhotoSource? get _source => ref.read(stockPhotoSourceProvider);

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final source = _source;
    if (source == null) return;
    final all = await source.categories();
    if (!mounted) return;
    final ordered = orderCategories(
      all,
      widget.now ?? DateTime.now(),
      eventDate: widget.draft.dateTime,
      title: widget.draft.title,
    );
    setState(() {
      _categories = ordered;
      _category = ordered.firstOrNull;
    });
    _restart();
  }

  void _restart() {
    _generation++;
    setState(() {
      _results.clear();
      _page = 0;
      _hasMore = true;
      _error = null;
      _loading = false;
    });
    _loadMore();
  }

  Future<void> _loadMore() async {
    final source = _source;
    if (source == null || _loading || !_hasMore) return;
    final gen = _generation;
    final page = _page + 1;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final q = _query.trim();
      final result = q.isNotEmpty
          ? await source.search(q, page)
          : _category == null
          ? const StockPage([], hasMore: false)
          : await source.photos(_category!, page);
      if (!mounted || gen != _generation) return;
      setState(() {
        _results.addAll(result.photos);
        _page = page;
        _hasMore = result.hasMore && result.photos.isNotEmpty;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted || value.trim() == _query.trim()) return;
      _query = value;
      _restart();
    });
  }

  void _pickCategory(StockCategory c) {
    feedback(ref, Sound.select, false);
    setState(() => _category = c);
    if (_query.trim().isEmpty) _restart();
  }

  Future<void> _download(StockPhoto photo) async {
    final source = _source;
    if (source == null || _downloadingId != null) return;
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
      final path = await importStockPhoto(file, photo, _sourceName(source));
      if (!mounted) return;
      widget.onImported(path);
    } catch (e) {
      debugPrint('Stock download failed: $e');
      if (!mounted) return;
      setState(() {
        _downloadingId = null;
        _failed = photo;
        _error = e is StockRateLimited ? e : null;
      });
    }
  }

  static String _sourceName(StockPhotoSource s) =>
      s.attribution.replaceFirst(RegExp(r'^Photos provided by\s*'), '');

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(stockPhotoSourceProvider);
    final credit = PhotoCredit.read(widget.draft.photoPath);
    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.only(top: 18, bottom: 10),
          sliver: SliverToBoxAdapter(
            child: Text('YOUR PHOTOS', style: AppText.eyebrow),
          ),
        ),
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
                'Current photo by ${credit.photographer}'
                '${credit.source.isEmpty ? '' : ' on ${credit.source}'}',
                style: AppText.secondary.copyWith(fontSize: 12),
              ),
            ),
          ),
        if (source != null) ..._stock(context, source),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  List<Widget> _stock(BuildContext context, StockPhotoSource source) => [
    SliverPadding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            const Expanded(child: Text('FREE PHOTOS', style: AppText.eyebrow)),
            Semantics(
              link: true,
              child: GestureDetector(
                onTap: () => launchUrl(
                  source.attributionUrl,
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  source.attribution,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    SliverToBoxAdapter(
      child: TextField(
        key: const ValueKey('stock-search'),
        onChanged: _onSearch,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: 'Search free photos',
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
    if (_categories.isNotEmpty)
      SliverPadding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        sliver: SliverToBoxAdapter(
          child: BleedScroller(
            height: 36,
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final c = _categories[i];
              return ChoiceChipButton(
                label: c.label,
                selected: _query.trim().isEmpty && c.id == _category?.id,
                onTap: () => _pickCategory(c),
              );
            },
          ),
        ),
      ),
    if (_failed != null)
      SliverToBoxAdapter(
        child: _Notice(
          text: _error is StockRateLimited
              ? 'Lots of people are browsing photos right now. Try again '
                    'shortly.'
              : 'Couldn’t download that photo.',
          action: 'Retry',
          onAction: () => _download(_failed!),
        ),
      )
    else if (_error != null && _results.isEmpty)
      SliverToBoxAdapter(
        child: _Notice(
          text: _error is StockRateLimited
              ? 'Lots of people are browsing photos right now. Try again '
                    'shortly.'
              : 'Couldn’t load photos. Check your connection.',
          action: 'Try again',
          onAction: _restart,
        ),
      ),
    SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 130,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: _results.length,
      itemBuilder: (_, i) {
        // Load the next page a little before the end.
        if (i >= _results.length - 6) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _error == null) _loadMore();
          });
        }
        final photo = _results[i];
        return _StockTile(
          photo: photo,
          downloading: photo.id == _downloadingId,
          progress: photo.id == _downloadingId ? _progress : null,
          onTap: () => _download(photo),
        );
      },
    ),
    if (_loading)
      const SliverPadding(
        padding: EdgeInsets.all(20),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      )
    else if (_results.isEmpty && _error == null && _page > 0)
      const SliverPadding(
        padding: EdgeInsets.all(20),
        sliver: SliverToBoxAdapter(
          child: Text('No photos match.', style: AppText.secondary),
        ),
      ),
  ];
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

class _StockTile extends StatelessWidget {
  const _StockTile({
    required this.photo,
    required this.downloading,
    required this.progress,
    required this.onTap,
  });

  final StockPhoto photo;
  final bool downloading;
  final double? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Photo by ${photo.photographer}',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: photo.averageColor),
            if (photo.thumbnailUrl.startsWith('http'))
              CachedNetworkImage(
                imageUrl: photo.thumbnailUrl,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder: (_, _) => ColoredBox(color: photo.averageColor),
                errorWidget: (_, _, _) => ColoredBox(color: photo.averageColor),
              ),
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
    margin: const EdgeInsets.only(bottom: 12),
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
