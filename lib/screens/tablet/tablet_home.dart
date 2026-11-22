import 'package:countdowns/constants.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/providers/home_provider.dart';
import 'package:countdowns/providers/timer_provider.dart';
import 'package:countdowns/screens/event_screen/event_screen.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/utilities/count_format.dart';
import 'package:countdowns/utilities/feedback.dart';
import 'package:countdowns/widgets/countdown_surface.dart';
import 'package:countdowns/widgets/event_icon.dart';
import 'package:countdowns/widgets/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const _sidebar = AppColors.wash;

/// iPad: sidebar filters, a card list and a live detail pane side by side,
/// so tapping a card never leaves the list.
class TabletHome extends ConsumerStatefulWidget {
  const TabletHome({super.key});

  @override
  ConsumerState<TabletHome> createState() => _TabletHomeState();
}

class _TabletHomeState extends ConsumerState<TabletHome> {
  int? _selectedId;

  @override
  Widget build(BuildContext context) {
    final lists = ref.watch(homeListsProvider);
    final now = ref.watch(minuteClockProvider);
    final filter = ref.watch(homeFilterProvider);
    final list = switch (filter) {
      HomeFilter.upcoming => lists.upcoming,
      HomeFilter.done => lists.done,
      HomeFilter.all => [...lists.upcoming, ...lists.done],
    };
    final selected =
        list.where((e) => e.id == _selectedId).firstOrNull ?? list.firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.ground,
      body: Row(
        children: [
          _Sidebar(upcoming: lists.upcoming.length, done: lists.done.length),
          SizedBox(
            width: 372,
            child: SafeArea(
              right: false,
              left: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(switch (filter) {
                            HomeFilter.upcoming => 'Upcoming',
                            HomeFilter.done => 'Done',
                            HomeFilter.all => 'All',
                          }, style: AppText.largeTitle.copyWith(fontSize: 28)),
                        ),
                        RoundButton(
                          icon: Icons.add_rounded,
                          label: 'New countdown',
                          background: AppColors.primary,
                          foreground: Colors.white,
                          onTap: () {
                            feedback(ref);
                            context.pushNamed(AppRoutes.eventNew);
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: list.isEmpty
                        ? const Center(
                            child: Text(
                              'Nothing here yet.',
                              style: AppText.secondary,
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: list.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => _ListRow(
                              event: list[i],
                              now: now,
                              selected: list[i].id == selected?.id,
                              onTap: () {
                                feedback(ref, Sound.select);
                                setState(() => _selectedId = list[i].id);
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                0,
                MediaQuery.paddingOf(context).top + 8,
                16,
                16,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: selected == null
                    ? Container(
                        color: Colors.white,
                        alignment: Alignment.center,
                        child: const Text(
                          'Pick a countdown to see it here.',
                          style: AppText.secondary,
                        ),
                      )
                    : MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        removeBottom: true,
                        child: CountdownDetail(
                          key: ValueKey(selected.id),
                          event: selected,
                          onEdit: () {
                            feedback(ref);
                            context.pushNamed(
                              AppRoutes.eventEdit,
                              pathParameters: {'id': '${selected.id}'},
                            );
                          },
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.upcoming, required this.done});
  final int upcoming, done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(homeFilterProvider);
    Widget item(
      IconData icon,
      String label, {
      int? count,
      bool selected = false,
      required VoidCallback onTap,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: () {
            feedback(ref, Sound.select);
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.ink : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.white : AppColors.ink,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.ink,
                    ),
                  ),
                ),
                if (count != null)
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.secondaryText,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    void setFilter(HomeFilter f) =>
        ref.read(homeFilterProvider.notifier).set(f);

    return Container(
      width: 232,
      color: _sidebar,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(10, 0, 10, 18),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: MarkedTitle(
                    'Since & Soon',
                    style: TextStyle(
                      fontFamily: AppFonts.numerals,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              item(
                Icons.schedule_rounded,
                'Upcoming',
                count: upcoming,
                selected: filter == HomeFilter.upcoming,
                onTap: () => setFilter(HomeFilter.upcoming),
              ),
              item(
                Icons.check_rounded,
                'Done',
                count: done,
                selected: filter == HomeFilter.done,
                onTap: () => setFilter(HomeFilter.done),
              ),
              item(
                Icons.view_agenda_outlined,
                'All',
                count: upcoming + done,
                selected: filter == HomeFilter.all,
                onTap: () => setFilter(HomeFilter.all),
              ),
              item(
                Icons.search_rounded,
                'Search',
                onTap: () => context.pushNamed(AppRoutes.search),
              ),
              item(
                Icons.grid_view_rounded,
                'Wall mode',
                onTap: () => context.pushNamed(AppRoutes.wall),
              ),
              const Spacer(),
              item(
                Icons.tune_rounded,
                'Settings',
                onTap: () => context.pushNamed(AppRoutes.settings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.event,
    required this.now,
    required this.selected,
    required this.onTap,
  });

  final Countdown event;
  final DateTime now;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = event.textColor;
    final s = event.hasPhoto ? photoTextShadow : null;
    final count = cardCount(event, now);
    return Semantics(
      button: true,
      selected: selected,
      label: '${event.title}, ${count.big} ${count.unit}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 104,
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? AppColors.ink : Colors.transparent,
              width: 3,
            ),
          ),
          child: CountdownSurface(
            event: event,
            borderRadius: BorderRadius.circular(22),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ink == Colors.white
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.softInk,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: EventIcon(
                    event.iconSlug ?? 'calendar',
                    size: 22,
                    color: ink,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: resolveEventFont(event.fontFamily),
                          fontFamilyFallback: eventFontFallback,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: ink,
                          shadows: s,
                        ),
                      ),
                      Text(
                        shortDate(event.nextOccurrence(now), now),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ink,
                          shadows: s,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      count.big,
                      style: AppText.numeral(
                        38,
                        color: ink,
                      ).copyWith(height: 1, shadows: s),
                    ),
                    Text(
                      count.unit,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ink,
                        shadows: s,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
