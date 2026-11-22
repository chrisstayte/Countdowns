import 'package:countdowns/models/background_catalog.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/models/palette.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/recents_provider.dart';
import 'package:countdowns/providers/timer_provider.dart';
import 'package:countdowns/storage/photos.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/utilities/count_format.dart';
import 'package:countdowns/utilities/feedback.dart';
import 'package:countdowns/widgets/countdown_surface.dart';
import 'package:countdowns/widgets/event_icon.dart';
import 'package:countdowns/widgets/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// What the sheet returns when "Add photo" is tapped: the editor closes the
/// sheet and runs its own photo picker and crop.
const addPhotoResult = 'add-photo';

/// Photos that exist on disk, current first, then recents, then photos on
/// other countdowns. No duplicates.
List<String> availablePhotos({
  String? current,
  List<String> recent = const [],
  List<String> others = const [],
}) {
  final seen = <String>{};
  return [
    for (final p in [?current, ...recent, ...others])
      if (seen.add(p) &&
          PhotoStore.ready &&
          PhotoStore.instance.fileFor(p).existsSync())
        p,
  ];
}

/// "All backgrounds": every colour, gradient and photo, in collections.
/// Picks apply to the preview at the top; Done returns the chosen key
/// (see background_catalog.dart), swiping away keeps what was there.
class AllBackgroundsSheet extends ConsumerStatefulWidget {
  const AllBackgroundsSheet({super.key, required this.draft});
  final Countdown draft;

  @override
  ConsumerState<AllBackgroundsSheet> createState() =>
      _AllBackgroundsSheetState();
}

class _AllBackgroundsSheetState extends ConsumerState<AllBackgroundsSheet> {
  late String _key = backgroundKeyOf(widget.draft);
  late BackgroundKind _tab =
      parseBackgroundKey(_key)?.kind ?? BackgroundKind.colour;

  /// Every countdown, for "photos on your other countdowns". Read once from
  /// the database: the events stream may have no listener under a sheet.
  List<Countdown> _all = const [];

  @override
  void initState() {
    super.initState();
    _loadOthers();
  }

  Future<void> _loadOthers() async {
    try {
      final all = await ref.read(databaseProvider).allCountdowns();
      if (mounted) setState(() => _all = all);
    } catch (_) {
      // No database (tests): show current and recent photos only.
    }
  }

  void _pick(String key) {
    if (key == _key) return;
    feedback(ref, Sound.select);
    setState(() => _key = key);
  }

  @override
  Widget build(BuildContext context) {
    final preview = applyBackground(widget.draft, _key);
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
                const Expanded(
                  child: Text(
                    'All backgrounds',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sheetTitle,
                  ),
                ),
                const SizedBox(width: 12),
                PillButton(
                  label: 'Done',
                  onTap: () => Navigator.pop(context, _key),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BackgroundPreviewStrip(event: preview),
            const SizedBox(height: 12),
            PillSegmented<BackgroundKind>(
              values: BackgroundKind.values,
              selected: _tab,
              label: (k) => switch (k) {
                BackgroundKind.colour => 'Colours',
                BackgroundKind.gradient => 'Gradients',
                BackgroundKind.photo => 'Photos',
              },
              onChanged: (k) => setState(() => _tab = k),
            ),
            Expanded(
              // Fade the grid out under the tabs as it scrolls.
              child: ClipRect(
                child: switch (_tab) {
                  BackgroundKind.colour => _Collections(
                    sections: [
                      for (final c in colourCollections)
                        (
                          title: c.name,
                          keys: [for (final p in c.colours) colourKey(p.color)],
                        ),
                    ],
                    selected: _key,
                    legacyBase: widget.draft.color,
                    onPick: _pick,
                  ),
                  BackgroundKind.gradient => _Collections(
                    sections: [
                      for (final c in gradientCollections)
                        (
                          title: c.name,
                          keys: [
                            for (final g in c.gradients) gradientKey(g.id),
                          ],
                        ),
                    ],
                    selected: _key,
                    legacyBase: widget.draft.color,
                    onPick: _pick,
                  ),
                  BackgroundKind.photo => _Photos(
                    photos: availablePhotos(
                      current: widget.draft.photoPath,
                      recent: ref.watch(recentsProvider).photos,
                      others: [for (final e in _all) ?e.photoPath],
                    ),
                    selected: _key,
                    onPick: _pick,
                    onAdd: () => Navigator.pop(context, addPhotoResult),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _Section = ({String title, List<String> keys});

class _Collections extends StatelessWidget {
  const _Collections({
    required this.sections,
    required this.selected,
    required this.legacyBase,
    required this.onPick,
  });

  final List<_Section> sections;
  final String selected;
  final Color legacyBase;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      for (final s in sections) ...[
        SliverPadding(
          padding: const EdgeInsets.only(top: 18, bottom: 10),
          sliver: SliverToBoxAdapter(
            child: Text(s.title.toUpperCase(), style: AppText.eyebrow),
          ),
        ),
        SliverGrid.builder(
          gridDelegate: _namedGrid,
          itemCount: s.keys.length,
          itemBuilder: (_, i) => _NamedTile(
            backgroundKey: s.keys[i],
            selected: s.keys[i] == selected,
            legacyBase: legacyBase,
            onTap: () => onPick(s.keys[i]),
          ),
        ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 30)),
    ],
  );
}

const _namedGrid = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 56,
  mainAxisSpacing: 2,
  crossAxisSpacing: 8,
  mainAxisExtent: 70,
);

/// A swatch with its name under it when it is the one chosen.
class _NamedTile extends StatelessWidget {
  const _NamedTile({
    required this.backgroundKey,
    required this.selected,
    required this.legacyBase,
    required this.onTap,
  });

  final String backgroundKey;
  final bool selected;
  final Color legacyBase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: BackgroundTile(
              backgroundKey: backgroundKey,
              selected: selected,
              legacyBase: legacyBase,
              onTap: onTap,
            ),
          ),
        ),
      ),
      SizedBox(
        height: 16,
        child: ExcludeSemantics(
          child: Text(
            selected ? backgroundName(backgroundKey) : '',
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            style: const TextStyle(
              fontSize: 11,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    ],
  );
}

class _Photos extends StatelessWidget {
  const _Photos({
    required this.photos,
    required this.selected,
    required this.onPick,
    required this.onAdd,
  });

  final List<String> photos;
  final String selected;
  final ValueChanged<String> onPick;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      const SliverPadding(
        padding: EdgeInsets.only(top: 18, bottom: 10),
        sliver: SliverToBoxAdapter(
          child: Text('YOUR PHOTOS', style: AppText.eyebrow),
        ),
      ),
      SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 104,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: photos.length + 1,
        itemBuilder: (_, i) => i == 0
            ? AddPhotoTile(onTap: onAdd)
            : BackgroundTile(
                backgroundKey: photoKey(photos[i - 1]),
                selected: photoKey(photos[i - 1]) == selected,
                legacyBase: AppColors.ink,
                onTap: () => onPick(photoKey(photos[i - 1])),
              ),
      ),
      if (photos.isEmpty)
        const SliverPadding(
          padding: EdgeInsets.only(top: 16),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Photos you add, and photos on your other countdowns, show '
              'up here.',
              style: AppText.secondary,
            ),
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 30)),
    ],
  );
}

/// A friendly name for a key: "Sunset", "Lavender", "Custom colour".
String backgroundName(String key) {
  final ref = parseBackgroundKey(key);
  if (ref == null) return '';
  return switch (ref.kind) {
    BackgroundKind.colour =>
      colourName(colourFromKey(ref.value)) ?? 'Custom colour',
    BackgroundKind.gradient =>
      ref.value == legacyGradientId
          ? 'Classic gradient'
          : gradientById(ref.value)?.name ?? 'Gradient',
    BackgroundKind.photo => 'Photo',
  };
}

/// What a screen reader says for a key: "Sunset gradient", "Lavender".
String backgroundLabel(String key) {
  final name = backgroundName(key);
  return key.startsWith('gradient:') ? '$name gradient' : name;
}

/// One background swatch for a key, used on the Look tab and in the sheet.
/// The chosen one gets an Ink ring and a check, so it never relies on
/// colour alone.
class BackgroundTile extends StatelessWidget {
  const BackgroundTile({
    super.key,
    required this.backgroundKey,
    required this.selected,
    required this.onTap,
    this.legacyBase = AppColors.ink,
    this.badge,
  });

  final String backgroundKey;
  final bool selected;
  final VoidCallback onTap;

  /// The countdown's colour, for drawing the old automatic gradient.
  final Color legacyBase;
  final String? badge;

  BoxDecoration? _fill() {
    final ref = parseBackgroundKey(backgroundKey);
    if (ref == null) return null;
    switch (ref.kind) {
      case BackgroundKind.colour:
        return BoxDecoration(color: colourFromKey(ref.value));
      case BackgroundKind.gradient:
        final colors = gradientColors(ref.value, legacyBase);
        if (colors == null) return null;
        return BoxDecoration(
          gradient: buildGradient(colors, GradientDirection.diagonalDown),
        );
      case BackgroundKind.photo:
        if (!PhotoStore.ready) return null;
        return BoxDecoration(
          image: DecorationImage(
            image: ResizeImage(
              FileImage(PhotoStore.instance.fileFor(ref.value)),
              width: 160,
            ),
            fit: BoxFit.cover,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = backgroundKey.startsWith('photo:');
    final radius = photo ? 14.0 : 21.0;
    return Semantics(
      button: true,
      selected: selected,
      label: badge == null
          ? backgroundLabel(backgroundKey)
          : '$badge ${backgroundLabel(backgroundKey).toLowerCase()}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: selected ? AppColors.ink : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: Container(
                  decoration:
                      (_fill() ?? const BoxDecoration(color: AppColors.wash))
                          .copyWith(
                            borderRadius: BorderRadius.circular(radius - 4),
                          ),
                ),
              ),
            ),
            if (selected)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            if (badge != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: -6,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The dashed "Add a photo" tile.
class AddPhotoTile extends StatelessWidget {
  const AddPhotoTile({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Add a photo',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedRRect(),
        child: const Center(
          child: Icon(
            Icons.add_photo_alternate_outlined,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ),
    ),
  );
}

class _DashedRRect extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    canvas.drawRRect(rrect, Paint()..color = AppColors.ground);
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(rrect.deflate(0.75));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A short card showing the countdown with the background being tried.
class BackgroundPreviewStrip extends ConsumerWidget {
  const BackgroundPreviewStrip({super.key, required this.event});
  final Countdown event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = cardCount(event, ref.watch(minuteClockProvider));
    final ink = event.textColor;
    final shadow = event.hasPhoto ? photoTextShadow : null;
    return Semantics(
      label: 'Preview: ${backgroundName(backgroundKeyOf(event))}',
      excludeSemantics: true,
      child: SizedBox(
        height: 72,
        child: CountdownSurface(
          event: event,
          shape: CropShape.wide,
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (event.iconSlug != null) ...[
                EventIcon(event.iconSlug!, size: 22, color: ink),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  event.title.isEmpty ? 'Countdown' : event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: resolveEventFont(event.fontFamily),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ink,
                    shadows: shadow,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                count.big,
                style: AppText.numeral(
                  32,
                  color: ink,
                ).copyWith(height: 1, shadows: shadow),
              ),
              if (count.unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  count.unit,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ink,
                    shadows: shadow,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
