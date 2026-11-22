import 'dart:io';

import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/widgets/ui.dart';
import 'package:material_ui/material_ui.dart';

const _dark = AppColors.scrim;
const _soft = Color(0xFFB3B2F7);
const _sub = Color(0xFFB9B5D6);

/// Outline colour per shape, as on the canvas.
const _shapeColors = {
  CropShape.full: Colors.white,
  CropShape.card: AppColors.highlight,
  CropShape.wide: Color(0xFF66B6FE),
  CropShape.tablet: Color(0xFF5FD3B5),
};

const _where = {
  CropShape.full: 'Detail screen',
  CropShape.card: 'Home card · small widget',
  CropShape.wide: 'Wide widget',
  CropShape.tablet: 'iPad landscape',
};

/// Crop a photo for every shape it shows up in. Each shape keeps its own
/// crop point unless "Same spot for all" is on.
class CropScreen extends StatefulWidget {
  const CropScreen({super.key, required this.file, required this.initial});

  final File file;
  final PhotoCrops initial;

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  late bool _same = widget.initial.sameForAll;
  late final Map<CropShape, Alignment> _points = {
    for (final s in CropShape.values) s: widget.initial.alignmentFor(s),
  };

  /// Null means "All shapes".
  CropShape? _selected;
  Size? _imageSize;
  ImageStream? _stream;
  late final ImageStreamListener _listener = ImageStreamListener((info, _) {
    if (mounted) {
      setState(
        () => _imageSize = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ),
      );
    }
  });

  bool get _tablet => MediaQuery.sizeOf(context).width >= 700;

  List<CropShape> get _shapes => _tablet
      ? CropShape.values
      : CropShape.values.where((s) => s != CropShape.tablet).toList();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stream ??= FileImage(
      widget.file,
    ).resolve(createLocalImageConfiguration(context))..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  void _done() {
    final points = _same
        ? {CropShape.full: _points[CropShape.full]!}
        : Map<CropShape, Alignment>.of(_points);
    Navigator.pop(context, PhotoCrops(sameForAll: _same, points: points));
  }

  /// Shapes that move together right now.
  List<CropShape> get _moving =>
      _same || _selected == null ? CropShape.values : [_selected!];

  void _nudge(Offset fraction) => setState(() {
    for (final s in _moving) {
      final a = _points[s]!;
      _points[s] = Alignment(
        (a.x + fraction.dx).clamp(-1, 1),
        (a.y + fraction.dy).clamp(-1, 1),
      );
    }
  });

  void _toggleSame() => setState(() {
    _same = !_same;
    if (_same) {
      // Line everything up with the full-screen crop.
      final a = _points[_selected ?? CropShape.full]!;
      for (final s in CropShape.values) {
        _points[s] = a;
      }
    }
  });

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Row(
        children: [
          TextAction(
            'Cancel',
            color: _soft,
            onTap: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Crop photo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
          PillButton(
            label: 'Done',
            background: AppColors.highlight,
            foreground: AppColors.ink,
            onTap: _done,
          ),
        ],
      ),
    );
    final hint = _selected == null
        ? 'Every place this photo shows up'
        : 'Drag the photo to set the ${_selected!.label.toLowerCase()} crop';
    final canvas = _CropCanvas(
      file: widget.file,
      imageSize: _imageSize,
      shapes: _shapes,
      points: _points,
      selected: _selected,
      hint: hint,
      onDrag: (shape, delta) => setState(() {
        for (final s in _same || _selected == null ? _shapes : [shape]) {
          final a = _points[s]!;
          _points[s] = Alignment(
            (a.x + delta.dx).clamp(-1, 1),
            (a.y + delta.dy).clamp(-1, 1),
          );
        }
      }),
    );
    final link = _LinkToggle(
      on: _same,
      onTap: _toggleSame,
      sub: _same
          ? 'Moving one moves them all'
          : 'Each shape keeps its own crop',
    );
    final pad = _Nudge(onNudge: _nudge);

    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(
        child: _tablet
            ? Column(
                children: [
                  header,
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: canvas,
                            ),
                          ),
                          const SizedBox(width: 32),
                          SizedBox(
                            width: 520,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Every place it shows up',
                                  style: TextStyle(
                                    fontFamily: AppFonts.numerals,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  'Pick a shape to set its own crop, or see them all at once.',
                                  style: TextStyle(fontSize: 14, color: _sub),
                                ),
                                const SizedBox(height: 14),
                                _ShowAll(
                                  on: _selected == null,
                                  onTap: () => setState(() => _selected = null),
                                ),
                                const SizedBox(height: 14),
                                Expanded(
                                  child: GridView.count(
                                    padding: EdgeInsets.zero,
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 1.6,
                                    children: [
                                      for (final s in _shapes)
                                        _Thumbnail(
                                          shape: s,
                                          file: widget.file,
                                          alignment: _points[s]!,
                                          selected: _selected == s,
                                          onTap: () =>
                                              setState(() => _selected = s),
                                        ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(child: link),
                                    const SizedBox(width: 14),
                                    pad,
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  header,
                  Expanded(child: canvas),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _ShapeChip(
                              label: 'All shapes',
                              color: Colors.white,
                              glyph: const Size(14, 14),
                              on: _selected == null,
                              onTap: () => setState(() => _selected = null),
                            ),
                            for (final s in _shapes) ...[
                              const SizedBox(width: 6),
                              _ShapeChip(
                                label: switch (s) {
                                  CropShape.full => 'Full screen',
                                  CropShape.card => 'Card',
                                  CropShape.wide => 'Wide',
                                  CropShape.tablet => 'iPad',
                                },
                                color: _shapeColors[s]!,
                                glyph: switch (s) {
                                  CropShape.full => const Size(10, 20),
                                  CropShape.card => const Size(16, 16),
                                  CropShape.wide => const Size(22, 11),
                                  CropShape.tablet => const Size(20, 14),
                                },
                                on: _selected == s,
                                onTap: () => setState(() => _selected = s),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: link),
                            const SizedBox(width: 12),
                            pad,
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// The frame for [shape] inside an image drawn in [image], positioned by
/// [alignment], exactly as BoxFit.cover would show it.
Rect cropFrame(Rect image, double aspect, Alignment alignment) {
  final imageAspect = image.width / image.height;
  final w = aspect > imageAspect ? image.width : image.height * aspect;
  final h = aspect > imageAspect ? image.width / aspect : image.height;
  final dx = image.width - w, dy = image.height - h;
  return Rect.fromLTWH(
    image.left + dx * (alignment.x + 1) / 2,
    image.top + dy * (alignment.y + 1) / 2,
    w,
    h,
  );
}

class _CropCanvas extends StatelessWidget {
  const _CropCanvas({
    required this.file,
    required this.imageSize,
    required this.shapes,
    required this.points,
    required this.selected,
    required this.hint,
    required this.onDrag,
  });

  final File file;
  final Size? imageSize;
  final List<CropShape> shapes;
  final Map<CropShape, Alignment> points;
  final CropShape? selected;
  final String hint;
  final void Function(CropShape shape, Offset alignmentDelta) onDrag;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = imageSize;
      if (size == null) {
        return const Center(child: CircularProgressIndicator(color: _soft));
      }
      final fitted = applyBoxFit(BoxFit.contain, size, box.biggest);
      final image = Alignment.center.inscribe(
        fitted.destination,
        Offset.zero & box.biggest,
      );
      final order = [...shapes.where((s) => s != selected), ?selected];
      void drag(DragUpdateDetails d) {
        final shape = selected ?? CropShape.full;
        final frame = cropFrame(image, shape.aspect, points[shape]!);
        final dx = image.width - frame.width;
        final dy = image.height - frame.height;
        // Dragging the photo moves it under the frame, so the crop point
        // moves the other way.
        onDrag(
          shape,
          Offset(
            dx > 0 ? -2 * d.delta.dx / dx : 0,
            dy > 0 ? -2 * d.delta.dy / dy : 0,
          ),
        );
      }

      return GestureDetector(
        onPanUpdate: drag,
        child: Stack(
          children: [
            Positioned.fromRect(
              rect: image,
              child: Image.file(file, fit: BoxFit.fill),
            ),
            for (final s in order)
              _Frame(
                rect: cropFrame(image, s.aspect, points[s]!),
                shape: s,
                selected: selected == s,
                faded: selected != null && selected != s,
              ),
            Positioned(
              left: 0,
              right: 0,
              top: image.bottom - 40,
              child: Center(
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _dark.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    hint,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _Frame extends StatelessWidget {
  const _Frame({
    required this.rect,
    required this.shape,
    required this.selected,
    required this.faded,
  });

  final Rect rect;
  final CropShape shape;
  final bool selected, faded;

  @override
  Widget build(BuildContext context) {
    final color = _shapeColors[shape]!;
    return Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        child: Opacity(
          opacity: faded ? 0.35 : 1,
          child: CustomPaint(
            painter: _FramePainter(color: color, selected: selected),
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    shape.label,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter({required this.color, required this.selected});
  final Color color;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));
    if (selected) {
      // Dim everything outside the selected frame.
      final outside = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(rect.inflate(3000))
        ..addRRect(rrect);
      canvas.drawPath(outside, Paint()..color = _dark.withValues(alpha: 0.6));
      final grid = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 1;
      for (final f in [1 / 3, 2 / 3]) {
        canvas.drawLine(
          Offset(size.width * f, 0),
          Offset(size.width * f, size.height),
          grid,
        );
        canvas.drawLine(
          Offset(0, size.height * f),
          Offset(size.width, size.height * f),
          grid,
        );
      }
    }
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 3 : 2;
    if (selected) {
      canvas.drawRRect(rrect.deflate(1.5), stroke);
      return;
    }
    final path = Path()..addRRect(rrect.deflate(1));
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 10) {
        canvas.drawPath(m.extractPath(d, d + 6), stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) =>
      old.color != color || old.selected != selected;
}

class _ShapeChip extends StatelessWidget {
  const _ShapeChip({
    required this.label,
    required this.color,
    required this.glyph,
    required this.on,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Size glyph;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      button: true,
      selected: on,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: on ? 0.14 : 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: on ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: glyph.width,
                height: glyph.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: color, width: 2),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LinkToggle extends StatelessWidget {
  const _LinkToggle({required this.on, required this.onTap, required this.sub});
  final bool on;
  final VoidCallback onTap;
  final String sub;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: on,
    label: 'Same spot for all',
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 26,
              padding: const EdgeInsets.all(3),
              alignment: on ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                color: on
                    ? AppColors.save
                    : Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Same spot for all',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _sub, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Nudge extends StatelessWidget {
  const _Nudge({required this.onNudge});
  final ValueChanged<Offset> onNudge;

  static const _step = 0.1;

  @override
  Widget build(BuildContext context) {
    Widget key(IconData icon, String label, Offset delta) => Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () => onNudge(delta),
        child: Container(
          width: 30,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
    return Column(
      children: [
        key(Icons.arrow_drop_up_rounded, 'Move up', const Offset(0, -_step)),
        const SizedBox(height: 3),
        Row(
          children: [
            key(Icons.arrow_left_rounded, 'Move left', const Offset(-_step, 0)),
            const SizedBox(width: 3),
            key(
              Icons.arrow_drop_down_rounded,
              'Move down',
              const Offset(0, _step),
            ),
            const SizedBox(width: 3),
            key(
              Icons.arrow_right_rounded,
              'Move right',
              const Offset(_step, 0),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShowAll extends StatelessWidget {
  const _ShowAll({required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: on ? Colors.white : Colors.transparent,
          width: 2,
        ),
      ),
      child: const Text(
        'Show all outlines',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

/// iPad: each shape's real crop as a live thumbnail.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.shape,
    required this.file,
    required this.alignment,
    required this.selected,
    required this.onTap,
  });

  final CropShape shape;
  final File file;
  final Alignment alignment;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _shapeColors[shape]!;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: selected ? 0.14 : 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: shape.aspect,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.file(
                      file,
                      fit: BoxFit.cover,
                      alignment: alignment,
                      cacheWidth: 400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                shape.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _where[shape]!,
                style: const TextStyle(color: _sub, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
