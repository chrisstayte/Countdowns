import 'package:countdowns/constants.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/models/event_icons.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/recents_provider.dart';
import 'package:countdowns/providers/timer_provider.dart';
import 'package:countdowns/screens/search/search_logic.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/utilities/count_format.dart';
import 'package:countdowns/utilities/feedback.dart';
import 'package:countdowns/widgets/countdown_surface.dart';
import 'package:countdowns/widgets/event_icon.dart';
import 'package:countdowns/widgets/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.onOpen});

  /// Overrides opening a result (the iPad opens it in the detail pane).
  final ValueChanged<Countdown>? onOpen;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _set(String q) {
    feedback(ref, Sound.select);
    _controller.text = q;
    _controller.selection = TextSelection.collapsed(offset: q.length);
  }

  void _open(Countdown e) {
    feedback(ref);
    ref.read(recentsProvider.notifier).useSearch(_controller.text);
    if (widget.onOpen != null) return widget.onOpen!(e);
    context.pushNamed(AppRoutes.event, pathParameters: {'id': '${e.id}'});
  }

  void _create({String? title, DateTime? date}) {
    feedback(ref);
    context.pushNamed(
      AppRoutes.eventNew,
      queryParameters: {
        'title': ?title,
        if (date != null) 'date': date.toIso8601String(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _controller.text.trim();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(child: _field()),
                      const SizedBox(width: 10),
                      TextAction('Cancel', onTap: () => context.pop()),
                    ],
                  ),
                ),
                Expanded(child: q.isEmpty ? _start() : _results(q)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field() => Container(
    height: 46,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: AppColors.primary, width: 2),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.search_rounded,
          size: 20,
          color: AppColors.secondaryText,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (v) => ref.read(recentsProvider.notifier).useSearch(v),
            style: const TextStyle(fontSize: 16, color: AppColors.ink),
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: 'Search countdowns',
              hintStyle: TextStyle(fontSize: 16, color: AppColors.muted),
            ),
          ),
        ),
        if (_controller.text.isNotEmpty)
          Semantics(
            button: true,
            label: 'Clear search',
            child: GestureDetector(
              onTap: () => _set(''),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.border,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 14),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _start() {
    final events = ref.watch(eventsProvider);
    final now = ref.watch(minuteClockProvider);
    final recents = ref.watch(recentsProvider).searches;
    final nextMonth = DateTime(now.year, now.month + 1);
    final nextMonthName = DateFormat('MMMM').format(nextMonth);
    final nextYear = '${now.year + 1}';
    int count(String q) => searchCountdowns(events, q, now).length;
    final whens = [
      ('This week', 'this week'),
      (nextMonthName, nextMonthName),
      (nextYear, nextYear),
      ('Done', 'done'),
    ];
    // The icons used most, for quick shortcuts.
    final usage = <String, List<Countdown>>{};
    for (final e in events) {
      if (e.iconSlug != null) (usage[e.iconSlug!] ??= []).add(e);
    }
    final kinds = usage.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final suggestions = holidaySuggestions(events, now);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        if (recents.isNotEmpty) ...[
          SectionLabel(
            'Recent',
            trailing: GestureDetector(
              onTap: () => ref.read(recentsProvider.notifier).clearSearches(),
              child: const Text(
                'Clear',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GroupCard(
            radius: 18,
            children: [
              for (final (i, r) in recents.indexed) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.rule),
                InkWell(
                  onTap: () => _set(r),
                  child: SizedBox(
                    height: 48,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            size: 18,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              r,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const Icon(
                            Icons.north_east_rounded,
                            size: 16,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
        ],
        const SectionLabel('Coming up'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, query) in whens)
              ChoiceChipButton(
                label: label,
                selected: false,
                background: Colors.white,
                onTap: () => _set(query),
                trailing: Text(
                  '${count(query)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
          ],
        ),
        if (kinds.isNotEmpty) ...[
          const SizedBox(height: 24),
          const SectionLabel('By icon'),
          const SizedBox(height: 10),
          GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.7,
            children: [
              for (final k in kinds.take(5))
                Semantics(
                  button: true,
                  child: GestureDetector(
                    onTap: () => _set(iconInfo(k.key)!.label),
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: CountdownSurface(
                            event: k.value.first,
                            borderRadius: BorderRadius.circular(18),
                            child: Center(
                              child: EventIcon(
                                k.key,
                                color: k.value.first.textColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          iconInfo(k.key)!.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 24),
          const SectionLabel('Try adding'),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final (i, (name, date)) in suggestions.indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    button: true,
                    child: GestureDetector(
                      onTap: () => _create(title: name, date: date),
                      child: Container(
                        height: 64,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              shortDate(date, now),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _results(String q) {
    final events = ref.watch(eventsProvider);
    final now = ref.watch(minuteClockProvider);
    final hits = searchCountdowns(events, q, now);
    final done = hits.where((h) => h.event.isDone(now)).length;
    final up = hits.length - done;
    if (hits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
        child: Column(
          children: [
            Text(
              'Nothing called “$q”',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.numerals,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Want to count down to it?',
              style: TextStyle(fontSize: 14, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 12),
            PillButton(
              label: 'New event “$q”',
              background: AppColors.primary,
              height: 48,
              onTap: () => _create(title: q),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        Text(
          '$up upcoming${done > 0 ? ' · $done done' : ''}',
          style: AppText.secondary,
        ),
        const SizedBox(height: 10),
        for (final hit in hits) ...[
          _ResultRow(hit: hit, now: now, onTap: () => _open(hit.event)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.hit, required this.now, required this.onTap});
  final SearchHit hit;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = hit.event;
    final past = e.isDone(now);
    final count = past
        ? (big: '${calendarDaysBetween(e.target, now)}', unit: 'days ago')
        : countIn(e, CountUnit.days, now);
    final title = e.title;
    final style = TextStyle(
      fontFamily: resolveEventFont(e.fontFamily),
      fontFamilyFallback: eventFontFallback,
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    );
    final spans = hit.start < 0
        ? [TextSpan(text: title)]
        : [
            TextSpan(text: title.substring(0, hit.start)),
            TextSpan(
              text: title.substring(hit.start, hit.start + hit.length),
              style: const TextStyle(backgroundColor: AppColors.highlight),
            ),
            TextSpan(text: title.substring(hit.start + hit.length)),
          ];
    final tile = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: past ? AppColors.track : null,
        borderRadius: BorderRadius.circular(16),
      ),
      child: past
          ? _tileText(count, AppColors.ink)
          : CountdownSurface(
              event: e,
              borderRadius: BorderRadius.circular(16),
              child: _tileText(count, e.textColor),
            ),
    );
    return Semantics(
      button: true,
      label: '$title, ${count.big} ${count.unit}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: past ? 0.75 : 1,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                tile,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(children: spans),
                        style: style,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${past ? 'Done · ' : e.isSince ? 'Since ' : ''}${DateFormat('EEE, MMM d, y').format(e.nextOccurrence(now))}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tileText(CountText c, Color color) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(c.big, style: AppText.numeral(22, color: color).copyWith(height: 1)),
      Text(
        c.unit,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ],
  );
}
