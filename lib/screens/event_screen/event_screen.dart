import 'package:countdowns/constants.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/notification_provider.dart';
import 'package:countdowns/providers/timer_provider.dart';
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

/// Opens the share sheet. Set by the share feature.
typedef ShareOpener =
    void Function(BuildContext context, Countdown event, CountUnit unit);
ShareOpener? openShareSheet;

class EventScreen extends ConsumerWidget {
  const EventScreen({super.key, required this.eventKey});

  final String? eventKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(eventByIdProvider(eventKey));
    if (event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This countdown was deleted.')),
      );
    }
    return Scaffold(
      backgroundColor: event.color,
      body: CountdownDetail(
        key: ValueKey(event.id),
        event: event,
        onClose: () {
          feedback(ref);
          context.pop();
        },
        onEdit: () {
          feedback(ref);
          context.pushNamed(
            AppRoutes.eventEdit,
            pathParameters: {'id': '${event.id}'},
          );
        },
      ),
    );
  }
}

/// The full countdown: giant number, unit switcher and tiles. Used full
/// screen on phones and in the detail pane on iPad.
class CountdownDetail extends ConsumerStatefulWidget {
  const CountdownDetail({
    super.key,
    required this.event,
    required this.onEdit,
    this.onClose,
    this.closeIcon = Icons.close_rounded,
    this.compact = false,
  });

  final Countdown event;
  final VoidCallback onEdit;
  final VoidCallback? onClose;
  final IconData closeIcon;

  /// Smaller type for narrow panes.
  final bool compact;

  @override
  ConsumerState<CountdownDetail> createState() => _CountdownDetailState();
}

class _CountdownDetailState extends ConsumerState<CountdownDetail> {
  late CountUnit _unit = widget.event.unit;

  @override
  void didUpdateWidget(covariant CountdownDetail old) {
    super.didUpdateWidget(old);
    if (old.event.id != widget.event.id) _unit = widget.event.unit;
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final now = ref.watch(clockProvider);
    final photo = event.hasPhoto;
    final ink = event.textColor;
    final soft = ink == Colors.white
        ? Colors.white.withValues(alpha: 0.2)
        : AppColors.softInk;
    final shadows = photo ? photoTextShadow : null;
    final done = event.isDone(now);
    final count = done
        ? (big: '${calendarDaysBetween(event.target, now)}', unit: 'days')
        : countIn(event, _unit, now);
    final label = done
        ? '${count.unit} since'
        : event.isToday(now)
        ? 'It’s today!'
        : '${count.unit} to go';
    final years = done ? null : yearsLine(event, _unit, now);
    final bigSize = widget.compact ? 120.0 : 168.0;

    TextStyle on(TextStyle s) => s.copyWith(color: ink, shadows: shadows);

    return CountdownSurface(
      event: event,
      shape: CropShape.full,
      scrim: ScrimStyle.fullBleed,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 28,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (widget.onClose != null)
                          RoundButton(
                            icon: widget.closeIcon,
                            label: 'Close',
                            background: soft,
                            foreground: ink,
                            onTap: widget.onClose!,
                          ),
                        const Spacer(),
                        if (openShareSheet != null) ...[
                          RoundButton(
                            icon: Icons.ios_share_rounded,
                            label: 'Share',
                            background: soft,
                            foreground: ink,
                            onTap: () {
                              feedback(ref);
                              openShareSheet!(context, event, _unit);
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        PillButton(
                          label: 'Edit',
                          height: 44,
                          background: photo
                              ? Colors.white.withValues(alpha: 0.2)
                              : AppColors.ink,
                          onTap: widget.onEdit,
                        ),
                      ],
                    ),
                    SizedBox(height: photo ? 22 : 36),
                    if (event.iconSlug != null && !photo) ...[
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: soft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: EventIcon(event.iconSlug, size: 28, color: ink),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Semantics(
                      header: true,
                      child: Text(
                        event.title,
                        style: on(
                          TextStyle(
                            fontFamily: resolveEventFont(event.fontFamily),
                            fontSize: widget.compact ? 32 : 40,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      longDate(event, now),
                      style: on(
                        const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (photo) const Spacer() else const SizedBox(height: 34),
                    Semantics(
                      liveRegion: false,
                      label: '${count.big} $label',
                      excludeSemantics: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              event.isToday(now) ? '0' : count.big,
                              style: on(
                                AppText.numeral(bigSize).copyWith(
                                  height: 0.82,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(
                              label,
                              style: on(
                                TextStyle(
                                  fontFamily: AppFonts.numerals,
                                  fontSize: widget.compact ? 24 : 30,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          if (years != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 6, top: 4),
                              child: Text(
                                years,
                                style: on(
                                  const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ).copyWith(color: ink.withValues(alpha: 0.75)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!done) ...[
                      const SizedBox(height: 22),
                      if (!photo) _switcher(ink, soft),
                      SizedBox(height: photo ? 0 : 16),
                      _tiles(event, now, photo),
                      if (photo) ...[
                        const SizedBox(height: 16),
                        _switcher(ink, soft),
                      ],
                    ],
                    if (!photo) const Spacer(),
                    if (!photo && !done) ...[
                      const SizedBox(height: 24),
                      _progress(event, now, ink),
                    ],
                    if (!photo) ...[
                      const SizedBox(height: 18),
                      _reminders(event, ink),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _switcher(Color ink, Color soft) {
    final photo = widget.event.hasPhoto;
    return PillSegmented<CountUnit>(
      values: CountUnit.values,
      selected: _unit,
      label: (u) => u.label,
      height: photo ? 38 : 36,
      trackColor: photo ? AppColors.scrim.withValues(alpha: 0.45) : soft,
      selectedColor: ink == Colors.white ? Colors.white : AppColors.ink,
      selectedText: ink == Colors.white ? AppColors.ink : Colors.white,
      text: ink,
      onChanged: (u) {
        feedback(ref, Sound.select);
        setState(() => _unit = u);
      },
    );
  }

  Widget _tiles(Countdown event, DateTime now, bool photo) {
    final tiles = detailTiles(event, _unit, now);
    return Row(
      children: [
        for (final (i, t) in tiles.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: photo ? 74 : null,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: photo
                    ? Colors.white.withValues(alpha: 0.16)
                    : AppColors.ink,
                borderRadius: BorderRadius.circular(18),
                border: photo
                    ? Border.all(color: Colors.white.withValues(alpha: 0.25))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: photo
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      t.value,
                      style: AppText.numeral(
                        photo ? 26 : 28,
                        color: Colors.white,
                      ).copyWith(
                        height: 1.1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Text(
                    t.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: photo ? Colors.white : const Color(0xFFCFCBE6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _progress(Countdown event, DateTime now, Color ink) {
    final pct = waitProgress(event, now);
    final added = event.createdAt;
    return Semantics(
      label: '$pct percent of the wait is behind you',
      excludeSemantics: true,
      child: Column(
        children: [
          Row(
            children: [
              if (added != null)
                Text(
                  'Added ${DateFormat('MMM d').format(added)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              const Spacer(),
              Text(
                '$pct% of the wait is behind you',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 10,
              backgroundColor: ink.withValues(alpha: 0.15),
              color: ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reminders(Countdown event, Color ink) {
    final offsets = [...event.reminders]..sort((a, b) => b.compareTo(a));
    final text = offsets.isEmpty
        ? 'No reminders'
        : 'Reminders: ${offsets.map((o) => reminderLabel(o).replaceAll('On the day', 'on the day')).join(', ')}';
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: widget.onEdit,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(Icons.notifications_none_rounded, size: 20, color: ink),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: ink),
            ],
          ),
        ),
      ),
    );
  }
}
