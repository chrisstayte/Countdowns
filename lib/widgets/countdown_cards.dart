import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/utilities/count_format.dart';
import 'package:countdowns/widgets/countdown_surface.dart';
import 'package:countdowns/widgets/event_icon.dart';
import 'package:material_ui/material_ui.dart';

TextStyle _onEvent(Countdown e, TextStyle s) => s.copyWith(
  color: e.textColor,
  shadows: e.hasPhoto ? photoTextShadow : null,
);

String _semantics(Countdown e, DateTime now) {
  final c = cardCount(e, now);
  return '${e.title}, ${c.big} ${c.unit}, ${cardDate(e, now)}';
}

/// The grid card on Home.
class CountdownCard extends StatelessWidget {
  const CountdownCard({
    super.key,
    required this.event,
    required this.now,
    this.onTap,
    this.height = 165,
    this.selected = false,
  });

  final Countdown event;
  final DateTime now;
  final VoidCallback? onTap;
  final double height;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final count = cardCount(event, now);
    final years = cardYears(event, now);
    final date = cardDate(event, now);
    final ink = event.textColor;
    return Semantics(
      button: onTap != null,
      label: _semantics(event, now),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: height,
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.ink : Colors.transparent,
              width: 3,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
          child: CountdownSurface(
            event: event,
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(16),
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
                        style: _onEvent(
                          event,
                          TextStyle(
                            fontFamily: resolveEventFont(event.fontFamily),
                            fontFamilyFallback: eventFontFallback,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ),
                    if (event.iconSlug != null) ...[
                      const SizedBox(width: 6),
                      EventIcon(event.iconSlug, size: 22, color: ink),
                    ],
                  ],
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        count.big,
                        style: _onEvent(event, AppText.numeral(44)),
                      ),
                      if (count.unit.isNotEmpty) ...[
                        const SizedBox(width: 5),
                        Text(
                          count.unit,
                          style: _onEvent(
                            event,
                            const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  years == null ? date : '$years · $date',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _onEvent(
                    event,
                    TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ink.withValues(alpha: 0.85),
                    ),
                  ).copyWith(color: ink.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The big "Up next" card at the top of Home.
class UpNextCard extends StatelessWidget {
  const UpNextCard({
    super.key,
    required this.event,
    required this.now,
    this.onTap,
    this.height = 196,
  });

  final Countdown event;
  final DateTime now;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final count = cardCount(event, now);
    final left = event.timeLeft(now);
    final ink = event.textColor;
    final rest = event.isToday(now)
        ? 'All day'
        : left.inDays >= 1
        ? '${left.inHours % 24} hr'
        : '${left.inMinutes % 60} min';
    final years = cardYears(event, now);
    return Semantics(
      button: onTap != null,
      label: 'Up next: ${_semantics(event, now)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: CountdownSurface(
            event: event,
            borderRadius: BorderRadius.circular(28),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UP NEXT',
                            style: _onEvent(
                              event,
                              const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.96,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _onEvent(
                              event,
                              TextStyle(
                                fontFamily: resolveEventFont(event.fontFamily),
                                fontFamilyFallback: eventFontFallback,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (event.iconSlug != null)
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ink == Colors.white
                              ? Colors.white.withValues(alpha: 0.2)
                              : AppColors.softInk,
                          shape: BoxShape.circle,
                        ),
                        child: EventIcon(event.iconSlug, size: 22, color: ink),
                      ),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.bottomLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              count.big,
                              style: _onEvent(
                                event,
                                AppText.numeral(84).copyWith(height: 0.85),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              count.unit,
                              style: _onEvent(
                                event,
                                const TextStyle(
                                  fontFamily: AppFonts.numerals,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          years ?? rest,
                          style: _onEvent(
                            event,
                            const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          shortDate(event.nextOccurrence(now), now),
                          style: _onEvent(
                            event,
                            const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

/// A finished countdown in the Done section.
class DoneRow extends StatelessWidget {
  const DoneRow({
    super.key,
    required this.event,
    required this.now,
    this.onTap,
  });

  final Countdown event;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ago = calendarDaysBetween(event.target, now);
    final agoText = ago == 0
        ? 'Today'
        : ago == 1
        ? 'Yesterday'
        : '$ago days ago';
    return Semantics(
      button: onTap != null,
      label: '${event.title}, done, $agoText',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CountdownSurface(
                  event: event,
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child: EventIcon(
                      event.iconSlug ?? 'done',
                      size: 20,
                      color: event.textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      DateFormatShort.format(event.target),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Text(agoText, style: AppText.secondary),
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class DateFormatShort {
  static String format(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
