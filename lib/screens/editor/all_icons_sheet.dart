import 'package:countdowns/models/event_icons.dart';
import 'package:countdowns/models/icon_catalog.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/widgets/event_icon.dart';
import 'package:countdowns/widgets/ui.dart';
import 'package:material_ui/material_ui.dart';

/// "All icons": every icon in sections, with section chips and a search that
/// matches labels and keywords ("wedding" finds the rings, bells, cake and
/// church). Tapping an icon returns its slug.
class AllIconsSheet extends StatefulWidget {
  const AllIconsSheet({super.key, this.selected});
  final String? selected;

  @override
  State<AllIconsSheet> createState() => _AllIconsSheetState();
}

class _AllIconsSheetState extends State<AllIconsSheet> {
  final _scroll = ScrollController();
  String _query = '';

  /// The chosen section chip; null is All.
  String? _category;

  static const _grid = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 84,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    mainAxisExtent: 108,
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _toTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final sectioned = _query.trim().isEmpty && _category == null;
    final icons = sectioned
        ? const <EventIconInfo>[]
        : iconsMatching(_query, category: _category);
    final chips = [null, ...iconCategories];
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
              onChanged: (v) {
                setState(() => _query = v);
                _toTop();
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Search ${eventIconCatalog.length} icons',
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
              itemBuilder: (_, i) => ChoiceChipButton(
                label: chips[i] ?? 'All',
                selected: chips[i] == _category,
                onTap: () {
                  setState(() => _category = chips[i]);
                  _toTop();
                },
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: !sectioned && icons.isEmpty
                  ? const Center(
                      child: Text('No icons match', style: AppText.secondary),
                    )
                  : CustomScrollView(
                      controller: _scroll,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        if (sectioned)
                          for (final (i, category)
                              in iconCategories.indexed) ...[
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: i == 0 ? 2 : 22,
                                  bottom: 10,
                                ),
                                child: SectionLabel(category),
                              ),
                            ),
                            _iconGrid(
                              eventIconCatalog
                                  .where((e) => e.category == category)
                                  .toList(),
                            ),
                          ]
                        else
                          _iconGrid(icons),
                        const SliverToBoxAdapter(child: SizedBox(height: 30)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconGrid(List<EventIconInfo> icons) => SliverGrid.builder(
    gridDelegate: _grid,
    itemCount: icons.length,
    itemBuilder: (_, i) => _IconCell(
      info: icons[i],
      selected: icons[i].slug == widget.selected,
      onTap: () => Navigator.pop(context, icons[i].slug),
    ),
  );
}

class _IconCell extends StatelessWidget {
  const _IconCell({
    required this.info,
    required this.selected,
    required this.onTap,
  });

  final EventIconInfo info;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: selected ? AppColors.highlighter : AppColors.wash,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: EventIcon(info.slug, size: 26, color: AppColors.ink),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            info.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}
