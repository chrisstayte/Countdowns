import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/providers/home_provider.dart';
import 'package:countdowns/providers/timer_provider.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/utilities/count_format.dart';
import 'package:countdowns/widgets/countdown_surface.dart';
import 'package:countdowns/widgets/event_icon.dart';
import 'package:countdowns/widgets/ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// An always-on board for an iPad on a stand: the clock, Up next and the
/// next four countdowns, with Since events filling any room left.
class WallScreen extends ConsumerWidget {
  const WallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider);
    final lists = ref.watch(homeListsProvider);
    final all = [...lists.upcoming, ...lists.since];
    final hero = all.firstOrNull;
    final tiles = all.skip(1).take(4).toList();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.night,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 20, 32, 28),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('h:mm').format(now),
                      style: const TextStyle(
                        fontFamily: AppFonts.numerals,
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      DateFormat('EEEE, MMMM d').format(now),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.nightSubtle,
                      ),
                    ),
                    const Spacer(),
                    PillButton(
                      label: 'Exit wall mode',
                      icon: Icons.close_rounded,
                      height: 44,
                      background: Colors.white.withValues(alpha: 0.1),
                      onTap: () => context.pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: hero == null
                      ? const Center(
                          child: Text(
                            'Add a countdown to fill the wall.',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _Hero(event: hero, now: now),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  for (final row in [0, 2]) ...[
                                    if (row > 0) const SizedBox(height: 16),
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          for (final i in [row, row + 1]) ...[
                                            if (i > row)
                                              const SizedBox(width: 16),
                                            Expanded(
                                              child: i < tiles.length
                                                  ? _Tile(
                                                      event: tiles[i],
                                                      now: now,
                                                    )
                                                  : const SizedBox(),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.event, required this.now});
  final Countdown event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final ink = event.textColor;
    final s = event.hasPhoto ? photoTextShadow : null;
    final (:from, :to) = countSpan(event, now);
    final span = to.difference(from);
    final ms = span.isNegative ? Duration.zero : span;
    final count = cardCount(event, now);
    String pad(int n) => n.toString().padLeft(2, '0');
    TextStyle on(TextStyle t) => t.copyWith(color: ink, shadows: s);
    return CountdownSurface(
      event: event,
      shape: CropShape.card,
      borderRadius: BorderRadius.circular(36),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.isSince ? 'SINCE' : 'UP NEXT',
            style: on(
              const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            event.title,
            style: on(
              TextStyle(
                fontFamily: resolveEventFont(event.fontFamily),
                fontFamilyFallback: eventFontFallback,
                fontSize: 44,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
          Text(
            longDate(event, now),
            style: on(
              const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.bottomLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  count.big,
                  style: on(AppText.numeral(200).copyWith(height: 0.82)),
                ),
                const SizedBox(width: 12),
                Text(
                  count.unit,
                  style: on(
                    const TextStyle(
                      fontFamily: AppFonts.numerals,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '${pad(ms.inHours % 24)}:${pad(ms.inMinutes % 60)}:${pad(ms.inSeconds % 60)}',
            style: on(
              const TextStyle(
                fontFamily: AppFonts.numerals,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.event, required this.now});
  final Countdown event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final ink = event.textColor;
    final s = event.hasPhoto ? photoTextShadow : null;
    final count = cardCount(event, now);
    TextStyle on(TextStyle t) => t.copyWith(color: ink, shadows: s);
    return CountdownSurface(
      event: event,
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: on(
                    TextStyle(
                      fontFamily: resolveEventFont(event.fontFamily),
                      fontFamilyFallback: eventFontFallback,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
              if (event.iconSlug != null)
                EventIcon(event.iconSlug, size: 24, color: ink),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.bottomLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(count.big, style: on(AppText.numeral(72))),
                const SizedBox(width: 6),
                Text(
                  count.unit,
                  style: on(
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Text(
            cardDate(event, now),
            style: on(
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
