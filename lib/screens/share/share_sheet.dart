import 'dart:io';
import 'dart:ui' as ui;

import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/providers/timer_provider.dart';
import 'package:countdowns/screens/share/ics.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/utilities/count_format.dart';
import 'package:countdowns/utilities/feedback.dart';
import 'package:countdowns/widgets/countdown_surface.dart';
import 'package:countdowns/widgets/event_icon.dart';
import 'package:countdowns/widgets/ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum ShareFormat { story, square, calendar }

void showShareSheet(BuildContext context, Countdown event, CountUnit unit) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    barrierColor: AppColors.scrim.withValues(alpha: 0.45),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (_) => ShareSheet(event: event, unit: unit),
  );
}

/// Story image, Square image or Calendar file, all made on the device and
/// sent through the system share sheet.
class ShareSheet extends ConsumerStatefulWidget {
  const ShareSheet({super.key, required this.event, required this.unit});
  final Countdown event;
  final CountUnit unit;

  @override
  ConsumerState<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<ShareSheet> {
  ShareFormat _format = ShareFormat.story;
  late CountUnit _unit = widget.unit;
  final _imageKey = GlobalKey();
  final _shareButtonKey = GlobalKey();
  bool _busy = false;

  String _summary(DateTime now) {
    final e = widget.event;
    final c = countIn(e, _unit, now);
    final date = DateFormat('EEEE, MMMM d').format(e.nextOccurrence(now));
    return '${c.big} ${c.unit} until ${e.title} ($date)';
  }

  Rect? _origin() {
    final box =
        _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<File> _makeFile(DateTime now) async {
    final dir = await getTemporaryDirectory();
    final e = widget.event;
    if (_format == ShareFormat.calendar) {
      final c = countIn(e, _unit, now);
      final file = File('${dir.path}/${fileNameFor(e.title, 'ics')}');
      await file.writeAsString(
        buildIcs(
          e,
          now: now,
          note: '${c.big} ${c.unit} to go. Made with Since & Soon.',
        ),
      );
      return file;
    }
    final boundary =
        _imageKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final target = _format == ShareFormat.story ? 1080.0 : 1080.0;
    final image = await boundary.toImage(
      pixelRatio: target / boundary.size.width,
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${dir.path}/${fileNameFor(e.title, 'png')}');
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    return file;
  }

  Future<void> _share() async {
    if (_busy) return;
    feedback(ref);
    setState(() => _busy = true);
    final now = DateTime.now();
    try {
      final file = await _makeFile(now);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: _format == ShareFormat.calendar ? null : _summary(now),
          sharePositionOrigin: _origin(),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Couldn’t share: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    feedback(ref);
    await Clipboard.setData(ClipboardData(text: _summary(DateTime.now())));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Copied')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(minuteClockProvider);
    final e = widget.event;
    final count = countIn(e, _unit, now);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Share ${e.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sheetTitle,
                ),
              ),
              RoundButton(
                icon: Icons.close_rounded,
                label: 'Close',
                size: 40,
                background: AppColors.ground,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PillSegmented<ShareFormat>(
            values: ShareFormat.values,
            selected: _format,
            height: 38,
            label: (f) => switch (f) {
              ShareFormat.story => 'Story',
              ShareFormat.square => 'Square',
              ShareFormat.calendar => 'Calendar',
            },
            onChanged: (f) {
              feedback(ref, Sound.select, false);
              setState(() => _format = f);
            },
          ),
          const SizedBox(height: 14),
          Container(
            height: 356,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.center,
            child: switch (_format) {
              ShareFormat.story => _Rounded(
                child: RepaintBoundary(
                  key: _imageKey,
                  child: _StoryImage(event: e, count: count, now: now),
                ),
              ),
              ShareFormat.square => _Rounded(
                child: RepaintBoundary(
                  key: _imageKey,
                  child: _SquareImage(event: e, count: count, now: now),
                ),
              ),
              ShareFormat.calendar => _CalendarPreview(
                event: e,
                count: count,
                now: now,
              ),
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'Count in',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: ChipSegmented<CountUnit>(
                    values: CountUnit.values,
                    selected: _unit,
                    label: (u) => u.label,
                    height: 32,
                    fontSize: 13,
                    spacing: 6,
                    segmentPadding: 10,
                    onChanged: (u) {
                      feedback(ref, Sound.select, false);
                      setState(() => _unit = u);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: KeyedSubtree(
                  key: _shareButtonKey,
                  child: PillButton(
                    label: _busy
                        ? 'Making it…'
                        : switch (_format) {
                            ShareFormat.calendar => 'Share calendar file',
                            _ => 'Share image',
                          },
                    icon: Icons.ios_share_rounded,
                    height: 52,
                    onTap: _busy ? null : _share,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              PillButton(
                label: 'Copy text',
                height: 52,
                background: AppColors.ground,
                foreground: AppColors.ink,
                onTap: _copy,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

TextStyle _title(Countdown e, double size, Color ink, List<Shadow>? s) =>
    TextStyle(
      fontFamily: resolveEventFont(e.fontFamily),
      fontFamilyFallback: eventFontFallback,
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: ink,
      shadows: s,
      height: 1.1,
    );

class _StoryImage extends StatelessWidget {
  const _StoryImage({
    required this.event,
    required this.count,
    required this.now,
  });
  final Countdown event;
  final CountText count;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final ink = event.textColor;
    final s = event.hasPhoto ? photoTextShadow : null;
    return SizedBox(
      width: 186,
      height: 330,
      child: CountdownSurface(
        event: event,
        shape: CropShape.full,
        scrim: ScrimStyle.fullBleed,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.iconSlug != null)
              EventIcon(event.iconSlug, size: 26, color: ink),
            const SizedBox(height: 10),
            Text(event.title, style: _title(event, 22, ink, s)),
            Text(
              DateFormat('EEEE, MMMM d').format(event.nextOccurrence(now)),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ink,
                shadows: s,
              ),
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                count.big,
                style: AppText.numeral(
                  96,
                  color: ink,
                ).copyWith(height: 0.82, shadows: s),
              ),
            ),
            Text(
              '${count.unit} to go',
              style: TextStyle(
                fontFamily: AppFonts.numerals,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ink,
                shadows: s,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'MADE WITH SINCE & SOON',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: ink,
                shadows: s,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareImage extends StatelessWidget {
  const _SquareImage({
    required this.event,
    required this.count,
    required this.now,
  });
  final Countdown event;
  final CountText count;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final ink = event.textColor;
    final s = event.hasPhoto ? photoTextShadow : null;
    return SizedBox.square(
      dimension: 290,
      child: CountdownSurface(
        event: event,
        padding: const EdgeInsets.all(20),
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
                      Text(event.title, style: _title(event, 26, ink, s)),
                      Text(
                        DateFormat('EEEE, MMMM d')
                            .format(event.nextOccurrence(now)),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ink,
                          shadows: s,
                        ),
                      ),
                    ],
                  ),
                ),
                if (event.iconSlug != null)
                  EventIcon(event.iconSlug, size: 28, color: ink),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          count.big,
                          style: AppText.numeral(
                            104,
                            color: ink,
                          ).copyWith(height: 0.82, shadows: s),
                        ),
                      ),
                      Text(
                        '${count.unit} to go',
                        style: TextStyle(
                          fontFamily: AppFonts.numerals,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: ink,
                          shadows: s,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'SINCE & SOON',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.54,
                    color: ink,
                    shadows: s,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarPreview extends StatelessWidget {
  const _CalendarPreview({
    required this.event,
    required this.count,
    required this.now,
  });
  final Countdown event;
  final CountText count;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final when = event.nextOccurrence(now);
    final ink = event.textColor;
    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Text(k, style: const TextStyle(color: AppColors.secondaryText)),
          const Spacer(),
          Flexible(
            child: Text(
              v,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return SizedBox(
      width: 270,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x262E2A3A),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                CountdownSurface(
                  event: event,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('MMM').format(when).toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: event.hasPhoto
                                    ? AppColors.ink
                                    : event.color,
                              ),
                            ),
                            Text(
                              '${when.day}',
                              style: AppText.numeral(
                                26,
                                color: AppColors.ink,
                              ).copyWith(height: 1),
                            ),
                          ],
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
                              style: _title(event, 20, ink, null),
                            ),
                            Text(
                              '${DateFormat('EEEE').format(when)} · ${event.allDay ? 'All day' : timeOfDay(event.dateTime)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(fontSize: 13, color: AppColors.ink),
                    child: Column(
                      children: [
                        row('File', fileNameFor(event.title, 'ics')),
                        row('Note', '${count.big} ${count.unit} to go'),
                        row('Alert', '1 day before'),
                        if (event.repeat == RepeatRule.yearly)
                          row('Repeats', 'Every year'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'A calendar file made on your phone. No account or server needed.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}

/// Rounds the preview on screen; the exported image keeps square corners.
class _Rounded extends StatelessWidget {
  const _Rounded({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x332E2A3A),
          blurRadius: 28,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: ClipRRect(borderRadius: BorderRadius.circular(18), child: child),
  );
}
