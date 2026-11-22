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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (MediaQuery.sizeOf(context).width >= tabletBreakpoint) {
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
                label: 'New countdown',
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

/// The scrolling Home content: header, Up next, filters, cards and Done.
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
    final done = lists.done;
    final hero = filter == HomeFilter.upcoming ? upcoming.firstOrNull : null;
    final cards = switch (filter) {
      HomeFilter.upcoming => upcoming.skip(1).toList(),
      HomeFilter.all => upcoming,
      HomeFilter.done => const <Countdown>[],
    };
    final showDone = switch (filter) {
      HomeFilter.upcoming => keepDone && done.isNotEmpty,
      HomeFilter.done || HomeFilter.all => done.isNotEmpty,
    };
    final empty = upcoming.isEmpty && done.isEmpty;

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
                  _Filters(upcoming: upcoming.length, done: done.length),
                  const SizedBox(height: 18),
                ],
              ],
            ),
          ),
        ),
        if (cards.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 165,
              ),
              itemCount: cards.length,
              itemBuilder: (_, i) => CountdownCard(
                event: cards[i],
                now: now,
                selected: cards[i].id == selectedId,
                onTap: () => onOpen(cards[i]),
              ),
            ),
          ),
        if (!empty && cards.isEmpty && hero == null && !showDone)
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
              Semantics(
                header: true,
                child: const Text('Countdowns', style: AppText.largeTitle),
              ),
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
  const _Filters({required this.upcoming, required this.done});
  final int upcoming, done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(homeFilterProvider);
    void pick(HomeFilter f) {
      feedback(ref, Sound.select);
      ref.read(homeFilterProvider.notifier).set(f);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChipButton(
          height: 36,
          label: 'Upcoming · $upcoming',
          selected: filter == HomeFilter.upcoming,
          onTap: () => pick(HomeFilter.upcoming),
        ),
        ChoiceChipButton(
          height: 36,
          label: 'Done · $done',
          selected: filter == HomeFilter.done,
          onTap: () => pick(HomeFilter.done),
        ),
        ChoiceChipButton(
          height: 36,
          label: 'All',
          selected: filter == HomeFilter.all,
          onTap: () => pick(HomeFilter.all),
        ),
      ],
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) => Container(
    height: 196,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: AppColors.border, width: 1.5),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Nothing to count down to yet',
          style: TextStyle(
            fontFamily: AppFonts.numerals,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Add a birthday, a trip or a big day, and it’ll show up here.',
          style: TextStyle(fontSize: 15, color: AppColors.secondaryText),
        ),
      ],
    ),
  );
}
