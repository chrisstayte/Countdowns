import 'package:countdowns/models/background_catalog.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/models/event_icons.dart';
import 'package:countdowns/models/icon_catalog.dart';
import 'package:countdowns/models/palette.dart';
import 'package:countdowns/providers/recents_provider.dart';
import 'package:countdowns/screens/editor/all_backgrounds_sheet.dart';
import 'package:countdowns/screens/editor/editor_details.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/utilities/feedback.dart';
import 'package:countdowns/widgets/event_icon.dart';
import 'package:countdowns/widgets/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Look: background (photo, gradient or colour), icon and font.
class EditorLook extends ConsumerWidget {
  const EditorLook({
    super.key,
    required this.draft,
    required this.edit,
    required this.onAddPhoto,
    this.originalColor,
    this.backgroundColumns = 6,
    this.iconColumns = 8,
  });

  final Countdown draft;
  final DraftEdit edit;
  final VoidCallback onAddPhoto;

  /// The saved colour when editing, so an off-palette colour can be offered
  /// as "Current" until the person picks another.
  final int? originalColor;
  final int backgroundColumns;
  final int iconColumns;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel(
          'Background',
          trailing: Text('Photo, gradient or colour', style: _hint),
        ),
        const SizedBox(height: 10),
        _BackgroundGrid(
          draft: draft,
          edit: edit,
          columns: backgroundColumns,
          originalColor: originalColor,
          recentPhotos: recents.photos,
          recentBackgrounds: recents.backgrounds,
          onAddPhoto: onAddPhoto,
        ),
        const SizedBox(height: 10),
        SeeAllButton(
          label: 'All backgrounds',
          onTap: () => _allBackgrounds(context, ref),
        ),
        if (draft.gradientId != null && !draft.hasPhoto) ...[
          const SizedBox(height: 14),
          _DirectionRow(draft: draft, edit: edit),
        ],
        if (draft.hasPhoto) ...[
          const SizedBox(height: 14),
          _DarkenRow(draft: draft, edit: edit),
        ],
        const SizedBox(height: 20),
        const SectionLabel('Icon'),
        const SizedBox(height: 10),
        _IconGrid(
          slugs: iconRow(recents.icons),
          selected: draft.iconSlug,
          columns: iconColumns,
          onPick: (slug) => _pickIcon(ref, slug),
          showNone: true,
        ),
        const SizedBox(height: 10),
        SeeAllButton(
          label: 'All ${eventIconCatalog.length} icons',
          onTap: () => _allIcons(context, ref),
        ),
        const SizedBox(height: 20),
        const SectionLabel('Font'),
        const SizedBox(height: 10),
        _FontGrid(
          families: _fontRow(recents.fonts),
          draft: draft,
          onPick: (f) => _pickFont(ref, f),
        ),
        const SizedBox(height: 10),
        SeeAllButton(
          label: 'All ${eventFonts.length} fonts',
          onTap: () => _allFonts(context, ref),
        ),
      ],
    );
  }

  List<String> _fontRow(List<String> recent) {
    final row = fontRow(recent);
    // Keep the current font visible.
    if (!row.contains(draft.fontFamily)) {
      return [draft.fontFamily, ...row.take(3)];
    }
    return row;
  }

  void _pickIcon(WidgetRef ref, String? slug) {
    feedback(ref, Sound.select);
    edit((d) => d.copyWith(iconSlug: slug));
  }

  void _pickFont(WidgetRef ref, String family) {
    feedback(ref, Sound.select);
    edit((d) => d.copyWith(fontFamily: family));
  }

  Future<void> _allBackgrounds(BuildContext context, WidgetRef ref) async {
    feedback(ref);
    final picked = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => AllBackgroundsSheet(draft: draft),
    );
    if (picked == addPhotoResult) {
      onAddPhoto();
    } else if (picked is BackgroundChoice) {
      edit(picked.applyTo);
    }
  }

  Future<void> _allIcons(BuildContext context, WidgetRef ref) async {
    feedback(ref);
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => AllIconsSheet(selected: draft.iconSlug),
    );
    if (picked != null) _pickIcon(ref, picked);
  }

  Future<void> _allFonts(BuildContext context, WidgetRef ref) async {
    feedback(ref);
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => AllFontsSheet(draft: draft),
    );
    if (picked != null) _pickFont(ref, picked);
  }
}

const _hint = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: AppColors.secondaryText,
);

/// The Look tab's short row: Add photo, photos, the current background,
/// recently used ones and featured picks (see lookRowKeys). Everything else
/// is in the All backgrounds sheet.
class _BackgroundGrid extends ConsumerWidget {
  const _BackgroundGrid({
    required this.draft,
    required this.edit,
    required this.columns,
    required this.originalColor,
    required this.recentPhotos,
    required this.recentBackgrounds,
    required this.onAddPhoto,
  });

  final Countdown draft;
  final DraftEdit edit;
  final int columns;
  final int? originalColor;
  final List<String> recentPhotos;
  final List<String> recentBackgrounds;
  final VoidCallback onAddPhoto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = backgroundKeyOf(draft);
    final custom = originalColor != null && !isPaletteColor(originalColor!)
        ? colourKey(Color(originalColor!))
        : null;
    final keys = lookRowKeys(
      draft: draft,
      recentPhotos: availablePhotos(recent: recentPhotos),
      recentBackgrounds: recentBackgrounds,
      originalColor: originalColor,
    );
    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.1,
      children: [
        AddPhotoTile(onTap: onAddPhoto),
        for (final k in keys)
          BackgroundTile(
            backgroundKey: k,
            selected: k == current,
            legacyBase: draft.color,
            badge: k == custom ? 'Current' : null,
            onTap: () {
              if (k == current) return;
              feedback(ref, Sound.select);
              edit((d) => applyBackground(d, k));
            },
          ),
      ],
    );
  }
}

class _DirectionRow extends ConsumerWidget {
  const _DirectionRow({required this.draft, required this.edit});
  final Countdown draft;
  final DraftEdit edit;

  @override
  Widget build(BuildContext context, WidgetRef ref) => DirectionPicker(
    colors: draft.gradient!,
    selected: draft.direction,
    onPick: (dir) {
      feedback(ref, Sound.select);
      edit((d) => d.copyWith(gradientDirection: dir));
    },
  );
}

class _DarkenRow extends ConsumerWidget {
  const _DarkenRow({required this.draft, required this.edit});
  final Countdown draft;
  final DraftEdit edit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = photoDarkenLevels.entries
        .reduce(
          (a, b) =>
              (a.value - draft.photoDarken).abs() <=
                  (b.value - draft.photoDarken).abs()
              ? a
              : b,
        )
        .key;
    return Row(
      children: [
        const SizedBox(
          width: 72,
          child: Text('DARKEN', style: AppText.eyebrow),
        ),
        Expanded(
          child: ChipSegmented<String>(
            values: photoDarkenLevels.keys.toList(),
            selected: current,
            label: (k) => k,
            height: 36,
            spacing: 6,
            equalWidths: true,
            onChanged: (k) {
              feedback(ref, Sound.select, false);
              edit((d) => d.copyWith(photoDarken: photoDarkenLevels[k]));
            },
          ),
        ),
      ],
    );
  }
}

class _IconGrid extends StatelessWidget {
  const _IconGrid({
    required this.slugs,
    required this.selected,
    required this.onPick,
    required this.columns,
    this.showNone = false,
  });

  final List<String> slugs;
  final String? selected;
  final ValueChanged<String?> onPick;
  final int columns;
  final bool showNone;

  @override
  Widget build(BuildContext context) {
    // Keep the chosen icon visible even if it isn't in the row.
    final row = selected != null && !slugs.contains(selected)
        ? [selected!, ...slugs.take(slugs.length - 1)]
        : slugs;
    Widget tile(String? slug) {
      final on = slug == selected;
      return Semantics(
        button: true,
        selected: on,
        label: slug == null ? 'No icon' : iconInfo(slug)?.label,
        child: GestureDetector(
          onTap: () => onPick(slug),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: on ? AppColors.highlighter : AppColors.wash,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: slug == null
                ? Icon(Icons.block_rounded, size: 20, color: AppColors.muted)
                : EventIcon(slug, size: 22, color: AppColors.ink),
          ),
        ),
      );
    }

    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 1.05,
      children: [if (showNone) tile(null), for (final s in row) tile(s)],
    );
  }
}

class _FontGrid extends StatelessWidget {
  const _FontGrid({
    required this.families,
    required this.draft,
    required this.onPick,
  });
  final List<String> families;
  final Countdown draft;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) => GridView.count(
    padding: EdgeInsets.zero,
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    mainAxisExtent: 54,
    children: [
      for (final family in families)
        _FontTile(
          font: eventFontFor(family),
          sample: draft.title.isEmpty ? 'Countdown' : draft.title,
          selected: draft.fontFamily == family,
          onTap: () => onPick(family),
        ),
    ],
  );
}

class _FontTile extends StatelessWidget {
  const _FontTile({
    required this.font,
    required this.sample,
    required this.selected,
    required this.onTap,
  });
  final EventFont font;
  final String sample;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '${font.label} font',
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.wash,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.ink : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              sample,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: font.fontFamily,
                fontSize: 18,
                height: 1.1,
                color: AppColors.ink,
              ),
            ),
            Text(
              font.label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// "All icons": every icon, searchable by label.
class AllIconsSheet extends StatefulWidget {
  const AllIconsSheet({super.key, this.selected});
  final String? selected;

  @override
  State<AllIconsSheet> createState() => _AllIconsSheetState();
}

class _AllIconsSheetState extends State<AllIconsSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final icons = eventIconCatalog
        .where(
          (i) =>
              q.isEmpty ||
              i.label.toLowerCase().contains(q) ||
              i.slug.contains(q),
        )
        .toList();
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('All icons', style: AppText.sheetTitle),
                const Spacer(),
                PillButton(label: 'Done', onTap: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Search icons',
                filled: true,
                fillColor: AppColors.wash,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: icons.isEmpty
                  ? const Center(
                      child: Text('No icons match', style: AppText.secondary),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.only(bottom: 30),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 84,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            mainAxisExtent: 108,
                          ),
                      itemCount: icons.length,
                      itemBuilder: (_, i) {
                        final info = icons[i];
                        final on = info.slug == widget.selected;
                        return Semantics(
                          button: true,
                          selected: on,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context, info.slug),
                            child: Column(
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: on
                                          ? AppColors.highlighter
                                          : AppColors.wash,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    alignment: Alignment.center,
                                    child: EventIcon(
                                      info.slug,
                                      size: 26,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  info.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "All fonts": every font previewing the real title, filterable.
class AllFontsSheet extends StatefulWidget {
  const AllFontsSheet({super.key, required this.draft});
  final Countdown draft;

  @override
  State<AllFontsSheet> createState() => _AllFontsSheetState();
}

class _AllFontsSheetState extends State<AllFontsSheet> {
  String _group = 'All';
  late String _selected = widget.draft.fontFamily;

  @override
  Widget build(BuildContext context) {
    final sample = widget.draft.title.isEmpty
        ? 'Countdown'
        : widget.draft.title;
    final rows = eventFonts
        .where((f) => _group == 'All' || f.group == _group)
        .toList();
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
            PillSegmented<String>(
              values: const ['All', 'Clean', 'Classic', 'Fun'],
              selected: _group,
              label: (g) => g,
              onChanged: (g) => setState(() => _group = g),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 30),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final f = rows[i];
                  final on = f.family == _selected;
                  return Semantics(
                    button: true,
                    selected: on,
                    label: '${f.label} font',
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = f.family),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 60,
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
                              child: Text(
                                sample,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: f.fontFamily,
                                  fontSize: 22,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(f.label, style: _hint),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
