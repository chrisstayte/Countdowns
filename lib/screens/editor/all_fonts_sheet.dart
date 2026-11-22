import 'dart:async';

import 'package:countdowns/fonts/font_catalog.dart';
import 'package:countdowns/fonts/font_library.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/widgets/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// The bundled Google Fonts catalogue, loaded once.
final fontCatalogProvider = FutureProvider<FontCatalog>(
  (_) => FontCatalog.load(),
);

/// "1,811 fonts": everything the picker offers.
String fontCount(FontCatalog catalog) =>
    '${NumberFormat.decimalPattern().format(catalog.fonts.length + bundledEventFonts.length)} fonts';

/// "All 1,811 fonts", or "All fonts" until the catalogue has loaded.
String allFontsLabel(FontCatalog? catalog) =>
    catalog == null ? 'All fonts' : 'All ${fontCount(catalog)}';

/// [text] in an event font, for pickers. A Google font previews from the
/// device or downloads into the cache after the row has been on screen for
/// [delay] (so a fast scroll doesn't start downloads it skips past). Until
/// then the text shows faded, in Default.
class FontSample extends StatefulWidget {
  const FontSample({
    super.key,
    required this.family,
    required this.text,
    required this.style,
    this.delay = Duration.zero,
    this.load = true,
  });

  /// The stored value: a bundled key or a Google family.
  final String family;
  final String text;
  final TextStyle style;
  final Duration delay;

  /// False holds back the download (big files wait for a tap).
  final bool load;

  @override
  State<FontSample> createState() => _FontSampleState();
}

class _FontSampleState extends State<FontSample> {
  Timer? _timer;

  String get _key => canonicalEventFont(widget.family);
  bool get _google => isGoogleEventFont(_key);

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(FontSample old) {
    super.didUpdateWidget(old);
    if (old.family != widget.family || old.load != widget.load) {
      _cancel(old.family);
      _schedule();
    }
  }

  void _schedule() {
    if (!_google || !widget.load) return;
    final library = FontLibrary.instance;
    if (library.isLoaded(_key)) return;
    if (widget.delay == Duration.zero) {
      unawaited(library.preview(_key));
    } else {
      _timer = Timer(widget.delay, () => library.preview(_key));
    }
  }

  void _cancel(String family) {
    _timer?.cancel();
    _timer = null;
    final key = canonicalEventFont(family);
    if (!FontLibrary.instance.isLoaded(key)) {
      FontLibrary.instance.cancelPreview(key);
    }
  }

  @override
  void dispose() {
    _cancel(widget.family);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Text(
      widget.text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: widget.style.copyWith(
        fontFamily: _google
            ? FontLibrary.flutterFamily(_key)
            : resolveEventFont(_key),
        fontFamilyFallback: eventFontFallback,
      ),
    );
    if (!_google) return text;
    return ValueListenableBuilder<int>(
      valueListenable: FontLibrary.instance.revision,
      builder: (_, _, _) => AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: FontLibrary.instance.isLoaded(_key) ? 1 : 0.35,
        child: text,
      ),
    );
  }
}

/// "All fonts": the built-in fonts and every Google font, previewing the
/// real title, with search and category chips. Returns the picked family.
class AllFontsSheet extends ConsumerStatefulWidget {
  const AllFontsSheet({super.key, required this.draft});
  final Countdown draft;

  @override
  ConsumerState<AllFontsSheet> createState() => _AllFontsSheetState();
}

/// A chip: null is All, [_builtIn] the bundled fonts, or a category.
const _builtIn = 'Built in';

class _AllFontsSheetState extends ConsumerState<AllFontsSheet> {
  final _scroll = ScrollController();
  late String _selected = canonicalEventFont(widget.draft.fontFamily);
  String _query = '';
  Object? _chip;

  static const _rowHeight = 64.0;
  static const _rowGap = 8.0;

  @override
  void dispose() {
    _scroll.dispose();
    unawaited(FontLibrary.instance.trimCache());
    super.dispose();
  }

  void _toTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _pick(String family) {
    setState(() => _selected = family);
    // Big families wait for a tap before downloading their preview.
    if (isGoogleEventFont(family)) {
      unawaited(FontLibrary.instance.preview(family));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sample = widget.draft.title.isEmpty
        ? 'Countdown'
        : widget.draft.title;
    final catalog = ref.watch(fontCatalogProvider).value;
    final q = _query.trim().toLowerCase();

    final builtIn = _chip == null || _chip == _builtIn
        ? bundledEventFonts
              .where((f) => f.label.toLowerCase().contains(q))
              .toList()
        : const <EventFont>[];
    final google = catalog == null || _chip == _builtIn
        ? const <GoogleFont>[]
        : catalog.matching(_query, category: _chip as FontCategory?);
    final chips = <Object?>[null, _builtIn, ...FontCategory.values];

    Widget row(String family, String label, {GoogleFont? font}) {
      final on = family == _selected;
      final large = font?.large ?? false;
      final waiting = large && !FontLibrary.instance.isLoaded(family) && !on;
      return Padding(
        padding: const EdgeInsets.only(bottom: _rowGap),
        child: Semantics(
          button: true,
          selected: on,
          label: '$label font',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => _pick(family),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.wash,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: on ? AppColors.ink : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FontSample(
                          family: family,
                          text: sample,
                          load: !large || on,
                          delay: const Duration(milliseconds: 180),
                          style: const TextStyle(
                            fontSize: 22,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          waiting
                              ? '$label · ${_megabytes(font!.length)}, tap to preview'
                              : label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _hint,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: on ? AppColors.ink : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: on
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    SliverFixedExtentList rows<T>(List<T> items, Widget Function(T) build) =>
        SliverFixedExtentList(
          itemExtent: _rowHeight + _rowGap,
          delegate: SliverChildBuilderDelegate(
            (_, i) => build(items[i]),
            childCount: items.length,
          ),
        );

    Widget header(String text) => SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 10),
        child: SectionLabel(text),
      ),
    );

    final empty = builtIn.isEmpty && google.isEmpty && catalog != null;
    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('All fonts', style: AppText.sheetTitle),
                const Spacer(),
                PillButton(
                  label: 'Done',
                  onTap: () => Navigator.pop(context, _selected),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (v) {
                setState(() => _query = v);
                _toTop();
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: catalog == null
                    ? 'Search fonts'
                    : 'Search ${fontCount(catalog)}',
                filled: true,
                fillColor: AppColors.wash,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 12),
            BleedScroller(
              height: 38,
              itemCount: chips.length,
              itemBuilder: (_, i) {
                final chip = chips[i];
                return ChoiceChipButton(
                  label: switch (chip) {
                    null => 'All',
                    FontCategory c => c.label,
                    _ => _builtIn,
                  },
                  selected: chip == _chip,
                  onTap: () {
                    setState(() => _chip = chip);
                    _toTop();
                  },
                );
              },
            ),
            ValueListenableBuilder<int>(
              valueListenable: FontLibrary.instance.revision,
              builder: (_, _, _) => FontLibrary.instance.offline
                  ? const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        "You're offline. Fonts you pick show in Default "
                        'until they can download.',
                        style: AppText.secondary,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: empty
                  ? const Center(
                      child: Text('No fonts match', style: AppText.secondary),
                    )
                  : CustomScrollView(
                      controller: _scroll,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        if (builtIn.isNotEmpty) ...[
                          if (_chip == null) header(_builtIn),
                          rows(builtIn, (f) => row(f.family, f.label)),
                        ],
                        if (google.isNotEmpty) ...[
                          if (_chip == null) header('Google Fonts'),
                          rows(google, (f) => row(f.family, f.family, font: f)),
                        ],
                        if (catalog == null)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: CircularProgressIndicator.adaptive(),
                              ),
                            ),
                          ),
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(4, 8, 4, 36),
                            child: Text(
                              'Google Fonts are free and open source (OFL, '
                              'Apache or UFL licences). Each one downloads '
                              'once, the first time you use it.',
                              style: _hint,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

String _megabytes(int bytes) => '${(bytes / 1e6).toStringAsFixed(1)} MB';

const _hint = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: AppColors.secondaryText,
);
