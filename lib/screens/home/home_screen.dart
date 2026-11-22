import 'package:countdowns/constants.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/providers/home_provider.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/providers/timer_provider.dart';
import 'package:countdowns/screens/tablet/tablet_home.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/utilities/feedback.dart';
import 'package:countdowns/widgets/countdown_cards.dart';
import 'package:countdowns/widgets/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Width from which Home becomes the iPad split view.
const tabletBreakpoint = 900.0;

/// The split view also needs a tablet-sized screen, so a phone turned
/// sideways (wide but short) keeps the phone layout.
const tabletShortestSide = 600.0;

bool useTabletLayout(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.width >= tabletBreakpoint &&
      size.shortestSide >= tabletShortestSide;
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (useTabletLayout(context)) {
      return const TabletHome();
    }
    return Scaffold(
      body: Stack(
        children: [
          HomeList(
            onOpen: (e) {
              feedback(ref);
              context.pushNamed(
                AppRoutes.event,
                pathParameters: {'id': '${e.id}'},
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 30 + MediaQuery.paddingOf(context).bottom * 0.4,
            child: Center(
              child: PillButton(
                label: 'New event',
                icon: Icons.add_rounded,
                height: 52,
                shadow: true,
                onTap: () {
                  feedback(ref);
                  context.pushNamed(AppRoutes.eventNew);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The scrolling Home content: header, Up next, filters, cards, Since and
/// Done.
class HomeList extends ConsumerWidget {
  const HomeList({
    super.key,
    required this.onOpen,
    this.selectedId,
    this.showHeader = true,
    this.columns = 2,
  });

  final ValueChanged<Countdown> onOpen;
  final int? selectedId;
  final bool showHeader;
  final int columns;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(homeListsProvider);
    final now = ref.watch(minuteClockProvider);
    final filter = ref.watch(homeFilterProvider);
    final keepDone = ref.watch(localSettingsProvider.select((s) => s.keepDone));
    final upcoming = lists.upcoming;
    final since = lists.since;
    final done = lists.done;
    final hero = filter == HomeFilter.upcoming ? upcoming.firstOrNull : null;
    final cards = switch (filter) {
      HomeFilter.upcoming => upcoming.skip(1).toList(),
      HomeFilter.since => since,
      HomeFilter.all => upcoming,
      HomeFilter.done => const <Countdown>[],
    };
    // All lists Since under its own heading, after the countdowns.
    final sinceSection = filter == HomeFilter.all ? since : const <Countdown>[];
    final showDone = switch (filter) {
      HomeFilter.upcoming => keepDone && done.isNotEmpty,
      HomeFilter.since => false,
      HomeFilter.done || HomeFilter.all => done.isNotEmpty,
    };
    final empty = upcoming.isEmpty && since.isEmpty && done.isEmpty;

    Widget grid(List<Countdown> events) => SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 165,
        ),
        itemCount: events.length,
        itemBuilder: (_, i) => CountdownCard(
          event: events[i],
          now: now,
          selected: events[i].id == selectedId,
          onTap: () => onOpen(events[i]),
        ),
      ),
    );

    return CustomScrollView(
      slivers: [
        SliverSafeArea(
          bottom: false,
          sliver: SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverList.list(
              children: [
                if (showHeader) ...[
                  const _HomeHeader(),
                  const SizedBox(height: 18),
                ],
                if (empty)
                  const _EmptyHome()
                else ...[
                  if (hero != null) ...[
                    UpNextCard(
                      event: hero,
                      now: now,
                      onTap: () => onOpen(hero),
                    ),
                    const SizedBox(height: 18),
                  ],
                  _Filters(
                    upcoming: upcoming.length,
                    since: since.length,
                    done: done.length,
                  ),
                  const SizedBox(height: 18),
                ],
              ],
            ),
          ),
        ),
        if (cards.isNotEmpty) grid(cards),
        if (sinceSection.isNotEmpty) ...[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, cards.isEmpty ? 0 : 22, 20, 10),
            sliver: const SliverToBoxAdapter(child: SectionLabel('Since')),
          ),
          grid(sinceSection),
        ],
        if (!empty &&
            cards.isEmpty &&
            sinceSection.isEmpty &&
            hero == null &&
            !showDone)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'Nothing here yet.',
                textAlign: TextAlign.center,
                style: AppText.secondary,
              ),
            ),
          ),
        if (showDone)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            sliver: SliverList.list(
              children: [
                const SectionLabel('Done'),
                const SizedBox(height: 10),
                for (final e in done) ...[
                  DoneRow(event: e, now: now, onTap: () => onOpen(e)),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(minuteClockProvider);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMMM d').format(now),
                style: AppText.secondary.copyWith(letterSpacing: 0.26),
              ),
              const SizedBox(height: 2),
              const MarkedTitle('Soon & Since', style: AppText.largeTitle),
            ],
          ),
        ),
        RoundButton(
          icon: Icons.search_rounded,
          label: 'Search',
          onTap: () {
            feedback(ref);
            context.pushNamed(AppRoutes.search);
          },
        ),
        const SizedBox(width: 8),
        RoundButton(
          icon: Icons.tune_rounded,
          label: 'Settings',
          onTap: () {
            feedback(ref);
            context.pushNamed(AppRoutes.settings);
          },
        ),
      ],
    );
  }
}

class _Filters extends ConsumerWidget {
  const _Filters({
    required this.upcoming,
    required this.since,
    required this.done,
  });
  final int upcoming, since, done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(homeFilterProvider);
    return ChipSegmented<HomeFilter>(
      values: HomeFilter.values,
      selected: filter,
      height: 36,
      label: (f) => switch (f) {
        HomeFilter.upcoming => '${f.label} · $upcoming',
        HomeFilter.since => '${f.label} · $since',
        HomeFilter.done => '${f.label} · $done',
        HomeFilter.all => f.label,
      },
      onChanged: (f) {
        feedback(ref, Sound.select, false);
        ref.read(homeFilterProvider.notifier).set(f);
      },
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 196),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: AppColors.border, width: 1.5),
    ),
    alignment: Alignment.bottomLeft,
    child: const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nothing to count yet',
          style: TextStyle(
            fontFamily: AppFonts.numerals,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Count down to a birthday or a trip, or up from a fresh start, '
          'and it’ll show up here.',
          style: TextStyle(fontSize: 15, color: AppColors.secondaryText),
        ),
      ],
    ),
  );
}
