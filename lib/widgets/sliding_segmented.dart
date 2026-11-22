import 'dart:math' as math;

import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Builds one option. [selectedness] runs from 0 (the pill is away) to 1
/// (the pill is fully under it), for cross-fading colours.
typedef SegmentBuilder<T> = Widget Function(
  BuildContext context,
  T value,
  double selectedness,
);

/// The app's one segmented control, behaving like iOS's sliding control:
/// the pill springs to a tapped option, can be dragged sideways and snaps
/// to the nearest option on release, ticks a light haptic on every change
/// (when haptics are on), and cross-fades labels as it passes.
///
/// Options are equal width by default. With [equalWidths] off each option
/// is as wide as its label (plus [segmentPadding]) and the control sizes
/// itself, for chip-style rows.
class SlidingSegmented<T> extends ConsumerStatefulWidget {
  const SlidingSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
    this.label,
    this.builder,
    this.semanticLabel,
    this.height = 36,
    this.fontSize = 14,
    this.trackColor = AppColors.wash,
    this.trackPadding = 4,
    this.spacing = 4,
    this.pillColor = AppColors.highlighter,
    this.pillBorder,
    this.selectedText = AppColors.ink,
    this.text = AppColors.ink,
    this.outline,
    this.segmentColor,
    this.radius,
    this.raised = false,
    this.equalWidths = true,
    this.segmentPadding = 16,
    this.fontWeight = FontWeight.w700,
  }) : assert(label != null || builder != null);

  final List<T> values;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Text for each option; used by the default builder and semantics.
  final String Function(T)? label;
  final SegmentBuilder<T>? builder;
  final String Function(T)? semanticLabel;

  final double height;
  final double fontSize;
  final FontWeight fontWeight;

  /// Null for no track (chip rows).
  final Color? trackColor;
  final double trackPadding;
  final double spacing;
  final Color pillColor;

  /// A border on the pill, per option (crop shapes use the shape colour).
  final Color Function(T)? pillBorder;
  final Color selectedText, text;

  /// An outline drawn around every option (chip rows).
  final Color? outline;

  /// A fill behind every option (the crop shape picker).
  final Color? segmentColor;
  final double? radius;

  /// A white pill with a soft shadow (editor tabs).
  final bool raised;
  final bool equalWidths;
  final double segmentPadding;

  @override
  ConsumerState<SlidingSegmented<T>> createState() =>
      _SlidingSegmentedState<T>();
}

class _SlidingSegmentedState<T> extends ConsumerState<SlidingSegmented<T>>
    with SingleTickerProviderStateMixin {
  /// The pill's position as a fractional option index.
  late final AnimationController _pos = AnimationController.unbounded(
    vsync: this,
    value: _indexOf(widget.selected).toDouble(),
  );

  bool _dragging = false;
  double _dragStart = 0;
  int _lastTick = 0;

  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 500,
    damping: 38,
  );

  int _indexOf(T value) => math.max(0, widget.values.indexOf(value));

  @override
  void didUpdateWidget(covariant SlidingSegmented<T> old) {
    super.didUpdateWidget(old);
    final target = _indexOf(widget.selected).toDouble();
    if (!_dragging && _pos.value != target && !_pos.isAnimating) {
      _animateTo(target);
    } else if (!_dragging && _pos.isAnimating) {
      // Retarget a running animation if the selection changed elsewhere.
      if (old.selected != widget.selected) _animateTo(target);
    }
  }

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  void _animateTo(double target, [double velocity = 0]) =>
      _pos.animateWith(SpringSimulation(_spring, _pos.value, target, velocity));

  void _tick() {
    try {
      if (!ref.read(localSettingsProvider).hapticFeedback) return;
    } catch (_) {
      // No settings available (e.g. a bare test harness): stay quiet.
      return;
    }
    HapticFeedback.selectionClick();
  }

  void _select(int index, {double velocity = 0}) {
    _animateTo(index.toDouble(), velocity);
    if (widget.values[index] != widget.selected) {
      _tick();
      widget.onChanged(widget.values[index]);
    }
  }

  // MARK: layout

  double _labelWidth(BuildContext context, T value) {
    final painter = TextPainter(
      text: TextSpan(
        text: widget.label!(value),
        style: TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: widget.fontSize,
          fontWeight: widget.fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w + widget.segmentPadding * 2 + 4;
  }

  /// The rect of each option inside the track's padding.
  List<Rect> _rects(BuildContext context, double maxWidth) {
    final n = widget.values.length;
    final h = widget.height;
    if (widget.equalWidths) {
      final w = (maxWidth - widget.spacing * (n - 1)) / n;
      return [
        for (var i = 0; i < n; i++)
          Rect.fromLTWH(i * (w + widget.spacing), 0, w, h),
      ];
    }
    var x = 0.0;
    return [
      for (final v in widget.values)
        () {
          final w = _labelWidth(context, v);
          final r = Rect.fromLTWH(x, 0, w, h);
          x += w + widget.spacing;
          return r;
        }(),
    ];
  }

  Rect _pillRect(List<Rect> rects, double pos) {
    final p = pos.clamp(0.0, rects.length - 1.0);
    final i = p.floor(), j = math.min(i + 1, rects.length - 1);
    return Rect.lerp(rects[i], rects[j], p - i)!;
  }

  int _hit(List<Rect> rects, double dx) {
    var best = 0;
    var bestDist = double.infinity;
    for (final (i, r) in rects.indexed) {
      if (dx >= r.left && dx <= r.right) return i;
      final d = math.min((dx - r.left).abs(), (dx - r.right).abs());
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final pad = widget.trackColor == null ? 0.0 : widget.trackPadding;
    final radius = widget.radius ?? widget.height / 2;
    // A fixed height outside the LayoutBuilder, so parents that ask for
    // intrinsic heights (the detail screen) get an answer without running
    // the layout callback.
    return SizedBox(
      height: widget.height + pad * 2,
      child: LayoutBuilder(
        builder: (context, box) {
          final inner = widget.equalWidths
              ? box.maxWidth - pad * 2
              : double.infinity;
          final rects = _rects(context, inner);
          final contentWidth = rects.last.right;

          void dragStart(DragStartDetails d) {
            final pill = _pillRect(rects, _pos.value);
            // Like iOS: drag only when the touch starts on the pill.
            if (!pill.inflate(4).contains(d.localPosition - Offset(pad, pad))) {
              return;
            }
            _dragging = true;
            _pos.stop();
            _dragStart = _pos.value;
            _lastTick = _pos.value.round();
          }

          void dragUpdate(DragUpdateDetails d) {
            if (!_dragging) return;
            final i = _pos.value.clamp(0, rects.length - 1).floor();
            final w = rects[i].width + widget.spacing;
            _pos.value = (_pos.value + d.delta.dx / w).clamp(
              0.0,
              rects.length - 1.0,
            );
            final nearest = _pos.value.round();
            if (nearest != _lastTick) {
              _lastTick = nearest;
              _tick();
            }
          }

          void dragEnd(DragEndDetails d) {
            if (!_dragging) return;
            _dragging = false;
            final i = _pos.value.clamp(0, rects.length - 1).floor();
            final w = rects[i].width + widget.spacing;
            final velocity = d.velocity.pixelsPerSecond.dx / w;
            final target = (_pos.value + velocity * 0.05).round().clamp(
              0,
              rects.length - 1,
            );
            _animateTo(target.toDouble(), velocity);
            if (widget.values[target] != widget.selected) {
              // The tick already played while passing over it.
              if (_lastTick != target) _tick();
              widget.onChanged(widget.values[target]);
            }
            _dragStart = 0;
          }

          final control = GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Count movement from touch-down, so the pill tracks the
            // finger exactly instead of lagging by the drag slop.
            dragStartBehavior: DragStartBehavior.down,
            onHorizontalDragStart: dragStart,
            onHorizontalDragUpdate: dragUpdate,
            onHorizontalDragEnd: dragEnd,
            onHorizontalDragCancel: () {
              if (_dragging) {
                _dragging = false;
                _animateTo(_dragStart.roundToDouble());
              }
            },
            onTapUp: (d) => _select(_hit(rects, d.localPosition.dx - pad)),
            child: Container(
              width: contentWidth + pad * 2,
              height: widget.height + pad * 2,
              padding: EdgeInsets.all(pad),
              decoration: widget.trackColor == null
                  ? null
                  : BoxDecoration(
                      color: widget.trackColor,
                      borderRadius: BorderRadius.circular(radius + pad),
                    ),
              child: AnimatedBuilder(
                animation: _pos,
                builder: (context, _) {
                  final pill = _pillRect(rects, _pos.value);
                  final nearest = widget
                      .values[_pos.value.round().clamp(0, rects.length - 1)];
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (widget.outline != null || widget.segmentColor != null)
                        for (final r in rects)
                          Positioned.fromRect(
                            rect: r,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: widget.segmentColor,
                                borderRadius: BorderRadius.circular(radius),
                                border: widget.outline == null
                                    ? null
                                    : Border.all(
                                        color: widget.outline!,
                                        width: 1.5,
                                      ),
                              ),
                            ),
                          ),
                      Positioned.fromRect(
                        key: const ValueKey('sliding-segmented-pill'),
                        rect: pill,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: widget.pillColor,
                            borderRadius: BorderRadius.circular(radius),
                            border: widget.pillBorder == null
                                ? null
                                : Border.all(
                                    color: widget.pillBorder!(nearest),
                                    width: 2,
                                  ),
                            boxShadow: widget.raised
                                ? const [
                                    BoxShadow(
                                      color: Color(0x1F2E2A3A),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                      for (final (i, v) in widget.values.indexed)
                        Positioned.fromRect(
                          rect: rects[i],
                          child: Semantics(
                            button: true,
                            selected: v == widget.selected,
                            label: (widget.semanticLabel ?? widget.label)?.call(
                              v,
                            ),
                            onTap: () => _select(i),
                            excludeSemantics: widget.builder == null,
                            child: Center(
                              child: _segment(
                                context,
                                v,
                                (1 - (_pos.value - i).abs()).clamp(0.0, 1.0),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          );
          return widget.equalWidths
              ? control
              : Align(alignment: Alignment.centerLeft, child: control);
        },
      ),
    );
  }

  Widget _segment(BuildContext context, T value, double t) {
    if (widget.builder != null) return widget.builder!(context, value, t);
    return Text(
      widget.label!(value),
      maxLines: 1,
      overflow: TextOverflow.fade,
      softWrap: false,
      style: TextStyle(
        fontSize: widget.fontSize,
        fontWeight: widget.fontWeight,
        color: Color.lerp(widget.text, widget.selectedText, t),
      ),
    );
  }
}
