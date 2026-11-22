import 'dart:io';

import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/widgets/cropped_photo.dart';
import 'package:countdowns/widgets/sliding_segmented.dart';
import 'package:countdowns/widgets/ui.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

const _dark = AppColors.night;
const _soft = AppColors.nightText;
const _sub = AppColors.nightSubtle;

/// Outline colour per shape, as on the canvas.
const _shapeColors = {
  CropShape.full: Colors.white,
  CropShape.card: AppColors.highlight,
  CropShape.wide: Color(0xFF66B6FE),
  CropShape.tablet: Color(0xFF5FD3B5),
};

/// Screens from this size up are tablets: they get the landscape crop.
const _tabletShortestSide = 600.0;

/// Wide enough for the iPad layout with thumbnails.
const _wideLayout = 700.0;

/// Crop a photo for every shape it shows up in on this device. One shape
/// is shown at a time; each keeps its own crop point and zoom, and moving
/// one never moves the others.
class CropScreen extends StatefulWidget {
  const CropScreen({super.key, required this.file, required this.initial});

  final File file;
  final PhotoCrops initial;

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  late final Map<CropShape, CropPoint> _points = {
    for (final s in CropShape.values) s: widget.initial.pointFor(s),
  };

  CropShape _selected = CropShape.full;
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

  /// Only shapes this device actually shows: the landscape detail crop is
  /// for tablets.
  List<CropShape> get _shapes =>
      MediaQuery.sizeOf(context).shortestSide >= _tabletShortestSide
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
    Navigator.pop(context, PhotoCrops(points: Map.of(_points)));
  }

  void _select(CropShape shape) => setState(() => _selected = shape);

  @override
  Widget build(BuildContext context) {
    final shapes = _shapes;
    // A window that shrinks (split view) may drop the tablet shape.
    final selected = shapes.contains(_selected) ? _selected : shapes.first;
    final names = _ShapeNames(Theme.of(context).platform);
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
    final canvas = _CropCanvas(
      file: widget.file,
      imageSize: _imageSize,
      shape: selected,
      point: _points[selected]!,
      label: names.long(selected),
      hint: 'Drag or pinch to set the ${names.inSentence(selected)} crop',
      onMove: (delta) => setState(
        () => _points[selected] = _points[selected]!.moved(delta.dx, delta.dy),
      ),
      onZoom: (zoom) =>
          setState(() => _points[selected] = _points[selected]!.zoomed(zoom)),
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _dark,
        body: SafeArea(
          child: Column(
            children: [
              header,
              Expanded(
                child: MediaQuery.sizeOf(context).width >= _wideLayout
                    ? _wideBody(canvas, shapes, selected, names)
                    : Column(
                        children: [
                          Expanded(child: canvas),
                          _phoneShapes(shapes, selected, names),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// iPad and other wide windows. Side by side when there is room across,
  /// otherwise (portrait, split view) the photo on top and the shapes in a
  /// row underneath.
  Widget _wideBody(
    Widget canvas,
    List<CropShape> shapes,
    CropShape selected,
    _ShapeNames names,
  ) => LayoutBuilder(
    builder: (context, box) {
      const intro = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Every place it shows up',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.numerals,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            'Each shape keeps its own crop. Pick one to adjust it.',
            style: TextStyle(fontSize: 14, color: _sub),
          ),
        ],
      );
      Widget thumbnail(CropShape s) => _Thumbnail(
        shape: s,
        title: names.short(s),
        where: names.where(s),
        file: widget.file,
        point: _points[s]!,
        selected: selected == s,
        onTap: () => _select(s),
      );

      final sideBySide = box.maxWidth >= box.maxHeight && box.maxWidth >= 1000;
      if (sideBySide) {
        final panel = (box.maxWidth * 0.42).clamp(380.0, 520.0);
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: canvas),
              const SizedBox(width: 32),
              SizedBox(
                width: panel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    intro,
                    const SizedBox(height: 18),
                    Expanded(
                      child: GridView.count(
                        padding: EdgeInsets.zero,
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.6,
                        children: [for (final s in shapes) thumbnail(s)],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      final rowHeight = (box.maxHeight * 0.18).clamp(132.0, 200.0);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
              child: canvas,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                intro,
                const SizedBox(height: 14),
                SizedBox(
                  height: rowHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, s) in shapes.indexed) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(child: thumbnail(s)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );

  Widget _phoneShapes(
    List<CropShape> shapes,
    CropShape selected,
    _ShapeNames names,
  ) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
    child: SlidingSegmented<CropShape>(
      values: shapes,
      selected: selected,
      onChanged: _select,
      height: 60,
      radius: 16,
      trackColor: null,
      spacing: 6,
      segmentColor: Colors.white.withValues(alpha: 0.06),
      pillColor: Colors.white.withValues(alpha: 0.14),
      pillBorder: (s) => _shapeColors[s]!,
      semanticLabel: names.short,
      builder: (context, s, t) => _ShapeLabel(
        label: names.short(s),
        color: _shapeColors[s]!,
        glyph: switch (s) {
          CropShape.full => const Size(10, 20),
          CropShape.card => const Size(16, 16),
          CropShape.wide => const Size(22, 11),
          CropShape.tablet => const Size(20, 14),
        },
      ),
    ),
  );
}

/// What each shape is called on this platform. The landscape detail crop
/// is "iPad" on iOS and "Tablet" elsewhere.
class _ShapeNames {
  const _ShapeNames(this.platform);
  final TargetPlatform platform;

  bool get _ios => platform == TargetPlatform.iOS;

  String short(CropShape s) => switch (s) {
    CropShape.full => 'Full screen',
    CropShape.card => 'Card',
    CropShape.wide => 'Wide',
    CropShape.tablet => _ios ? 'iPad' : 'Tablet',
  };

  String long(CropShape s) => switch (s) {
    CropShape.tablet => _ios ? 'iPad landscape' : 'Tablet landscape',
    _ => s.label,
  };

  /// [long] as it reads mid-sentence: "full screen", but still "iPad".
  String inSentence(CropShape s) {
    final name = long(s);
    return name.startsWith('iPad') ? name : name.toLowerCase();
  }

  String where(CropShape s) => switch (s) {
    CropShape.full => 'Detail · large widget',
    CropShape.card => 'Home card · small widget',
    CropShape.wide => 'Wide widget',
    CropShape.tablet => 'Landscape detail',
  };
}

/// The frame for a shape inside an image drawn at [image]: exactly the part
/// of the photo that shape will show.
Rect cropFrame(Rect image, double aspect, CropPoint point) =>
    cropRectIn(image.size, aspect, point).shift(image.topLeft);

/// The photo with the selected shape's frame on it. Dragging anywhere moves
/// that frame; pinching zooms it.
class _CropCanvas extends StatefulWidget {
  const _CropCanvas({
    required this.file,
    required this.imageSize,
    required this.shape,
    required this.point,
    required this.label,
    required this.hint,
    required this.onMove,
    required this.onZoom,
  });

  final File file;
  final Size? imageSize;
  final CropShape shape;
  final CropPoint point;
  final String label;
  final String hint;
  final ValueChanged<Offset> onMove;
  final ValueChanged<double> onZoom;

  @override
  State<_CropCanvas> createState() => _CropCanvasState();
}

class _CropCanvasState extends State<_CropCanvas> {
  double _startZoom = 1;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = widget.imageSize;
      if (size == null) {
        return const Center(child: CircularProgressIndicator(color: _soft));
      }
      // The hint sits just under the photo, never on it.
      const hintSpace = 36.0;
      final room = Size(
        box.maxWidth,
        (box.maxHeight - hintSpace).clamp(0.0, double.infinity),
      );
      final fitted = applyBoxFit(BoxFit.contain, size, room);
      final image = Alignment.center.inscribe(
        fitted.destination,
        Offset.zero & room,
      );
      final frame = cropFrame(image, widget.shape.aspect, widget.point);
      final color = _shapeColors[widget.shape]!;

      void update(ScaleUpdateDetails d) {
        if (d.pointerCount > 1) widget.onZoom(_startZoom * d.scale);
        final dx = image.width - frame.width;
        final dy = image.height - frame.height;
        // Moving the frame over the photo: drag right, crop moves right.
        widget.onMove(
          Offset(
            dx > 0 ? 2 * d.focalPointDelta.dx / dx : 0,
            dy > 0 ? 2 * d.focalPointDelta.dy / dy : 0,
          ),
        );
      }

      return GestureDetector(
        onScaleStart: (_) => _startZoom = widget.point.zoom,
        onScaleUpdate: update,
        child: ClipRect(
          child: Stack(
            children: [
              Positioned.fromRect(
                rect: image,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(widget.file, fit: BoxFit.fill),
                ),
              ),
              Positioned.fromRect(
                rect: frame,
                child: IgnorePointer(
                  child: CustomPaint(painter: _FramePainter(color: color)),
                ),
              ),
              Positioned(
                left: frame.left + 8,
                top: frame.top + 8,
                child: IgnorePointer(
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
                      widget.label,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: image.bottom + 10,
                child: Text(
                  widget.hint,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _soft,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// The frame outline, a rule-of-thirds grid inside it, and the rest of the
/// photo dimmed.
class _FramePainter extends CustomPainter {
  _FramePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));
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
    canvas.drawRRect(
      rrect.deflate(1.5),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) => old.color != color;
}

class _ShapeLabel extends StatelessWidget {
  const _ShapeLabel({
    required this.label,
    required this.color,
    required this.glyph,
  });

  final String label;
  final Color color;
  final Size glyph;

  @override
  Widget build(BuildContext context) => Column(
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
      const SizedBox(height: 4),
      Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

/// iPad: each shape's real crop as a live thumbnail.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.shape,
    required this.title,
    required this.where,
    required this.file,
    required this.point,
    required this.selected,
    required this.onTap,
  });

  final CropShape shape;
  final String title, where;
  final File file;
  final CropPoint point;
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
                    child: CroppedPhoto(
                      file: file,
                      point: point,
                      cacheWidth: 400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                where,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _sub, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
