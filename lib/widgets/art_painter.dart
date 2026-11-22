import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:countdowns/models/art_catalog.dart';
import 'package:material_ui/material_ui.dart';

/// Paints an [Art] background to fill its box: the app's surfaces, the
/// swatches and the widget images all draw through [paintArt], so they
/// match. Motifs keep their size in logical pixels; [scale] shrinks them
/// for small swatches.
class ArtPainter extends CustomPainter {
  const ArtPainter(this.art, {this.scale = 1});

  final Art art;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) =>
      paintArt(canvas, size, art, scale: scale);

  @override
  bool shouldRepaint(ArtPainter old) =>
      old.art.id != art.id || old.scale != scale;
}

/// [art] filling [size], with the same layout every time.
void paintArt(Canvas canvas, Size size, Art art, {double scale = 1}) {
  if (size.isEmpty) return;
  canvas.save();
  canvas.clipRect(Offset.zero & size);
  canvas.drawRect(Offset.zero & size, _fill(art.ground));
  final rng = math.Random(_seed(art.id));
  switch (art) {
    case PatternArt a:
      _PatternPainter(canvas, size, a, scale, rng).paint();
    case TextureArt a:
      _TexturePainter(canvas, size, a, scale, rng).paint();
    case IllustrationArt a:
      _IllustrationPainter(canvas, size, a, scale, rng).paint();
  }
  canvas.restore();
}

/// FNV-1a, so the layout never depends on String.hashCode.
int _seed(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h;
}

Paint _fill(Color c) => Paint()
  ..color = c
  ..isAntiAlias = true;

Paint _stroke(Color c, double w, {StrokeCap cap = StrokeCap.round}) => Paint()
  ..color = c
  ..isAntiAlias = true
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = cap
  ..strokeJoin = StrokeJoin.round;

Paint _soft(Color c) => _fill(c.withValues(alpha: artSoftFill));

/// Soft fill inside, then the outline: the "Highlighter" icon style.
void _outline(Canvas cv, Path p, Color c, double w) {
  cv.drawPath(p, _soft(c));
  cv.drawPath(p, _stroke(c, w));
}

double _range(math.Random r, double a, double b) =>
    a + r.nextDouble() * (b - a);

/// A smooth closed curve through [pts] (Catmull-Rom as cubics).
Path _smoothClosed(List<Offset> pts) {
  final n = pts.length;
  final path = Path()..moveTo(pts[0].dx, pts[0].dy);
  for (var i = 0; i < n; i++) {
    final p0 = pts[(i - 1 + n) % n], p1 = pts[i];
    final p2 = pts[(i + 1) % n], p3 = pts[(i + 2) % n];
    path.cubicTo(
      p1.dx + (p2.dx - p0.dx) / 6,
      p1.dy + (p2.dy - p0.dy) / 6,
      p2.dx - (p3.dx - p1.dx) / 6,
      p2.dy - (p3.dy - p1.dy) / 6,
      p2.dx,
      p2.dy,
    );
  }
  return path..close();
}

/// A smooth open curve through [pts].
Path _smoothOpen(List<Offset> pts, [Path? into]) {
  final path = into ?? Path();
  path.moveTo(pts[0].dx, pts[0].dy);
  for (var i = 0; i < pts.length - 1; i++) {
    final p0 = pts[math.max(0, i - 1)], p1 = pts[i];
    final p2 = pts[i + 1], p3 = pts[math.min(pts.length - 1, i + 2)];
    path.cubicTo(
      p1.dx + (p2.dx - p0.dx) / 6,
      p1.dy + (p2.dy - p0.dy) / 6,
      p2.dx - (p3.dx - p1.dx) / 6,
      p2.dy - (p3.dy - p1.dy) / 6,
      p2.dx,
      p2.dy,
    );
  }
  return path;
}

/// A slightly wobbly circle, as if drawn by hand.
Path _blob(
  Offset c,
  double r,
  math.Random rng, {
  double wobble = 0.07,
  int n = 8,
}) {
  final start = rng.nextDouble() * math.pi;
  return _smoothClosed([
    for (var i = 0; i < n; i++)
      c +
          Offset.fromDirection(
            start + i * 2 * math.pi / n,
            r * (1 + _range(rng, -wobble, wobble)),
          ),
  ]);
}

/// Many dots or short lines in one draw call.
void _raw(Canvas cv, ui.PointMode mode, List<double> xy, Color c, double w) {
  if (xy.isEmpty) return;
  cv.drawRawPoints(mode, Float32List.fromList(xy), _stroke(c, w));
}

Path _polygon(List<Offset> pts) => Path()..addPolygon(pts, true);

// MARK: Patterns

class _PatternPainter {
  _PatternPainter(this.cv, this.size, this.art, this.u, this.rng);

  final Canvas cv;
  final Size size;
  final PatternArt art;
  final double u;
  final math.Random rng;

  double get w => size.width;
  double get h => size.height;
  Color ink(int i) => art.inks[i % art.inks.length];

  /// Cell centres on a grid with every other row shifted half a cell.
  Iterable<(Offset, int)> _offsetGrid(double sx, double sy) sync* {
    var i = 0;
    for (var row = 0; row * sy - sy < h + sy; row++) {
      final shift = row.isOdd ? sx / 2 : 0.0;
      for (var x = -sx + shift; x < w + sx; x += sx) {
        yield (Offset(x, row * sy - sy / 2), i++);
      }
    }
  }

  void paint() {
    switch (art.motif) {
      case Motif.polka:
        for (final (c, _) in _offsetGrid(34 * u, 30 * u)) {
          cv.drawPath(_blob(c, 7 * u, rng, wobble: 0.05), _fill(ink(0)));
        }
      case Motif.pinDots:
        final pts = <double>[];
        for (final (c, _) in _offsetGrid(16 * u, 14 * u)) {
          pts.addAll([c.dx, c.dy]);
        }
        _raw(cv, ui.PointMode.points, pts, ink(0), 4.4 * u);
      case Motif.confetti:
        final n = (w * h / (26 * 26 * u * u)).ceil();
        for (var i = 0; i < n; i++) {
          final c = Offset(rng.nextDouble() * w, rng.nextDouble() * h);
          final color = ink(rng.nextInt(art.inks.length));
          if (rng.nextBool()) {
            cv.drawCircle(c, _range(rng, 2.5, 4.5) * u, _fill(color));
          } else {
            cv.save();
            cv.translate(c.dx, c.dy);
            cv.rotate(rng.nextDouble() * math.pi);
            cv.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromCenter(
                  center: Offset.zero,
                  width: 4 * u,
                  height: 11 * u,
                ),
                Radius.circular(2 * u),
              ),
              _fill(color),
            );
            cv.restore();
          }
        }
      case Motif.spots:
        final s = 46 * u;
        for (var y = -s / 2; y < h + s; y += s) {
          for (var x = -s / 2; x < w + s; x += s) {
            final c = Offset(
              x + _range(rng, -10, 10) * u,
              y + _range(rng, -10, 10) * u,
            );
            _outline(
              cv,
              _blob(c, _range(rng, 7, 12) * u, rng, wobble: 0.18),
              ink(0),
              2 * u,
            );
          }
        }
      case Motif.stripes:
        for (var x = 7 * u; x < w + 14 * u; x += 28 * u) {
          _wobblyLine(
            Offset(x, -10 * u),
            Offset(x, h + 10 * u),
            ink(0),
            14 * u,
            1.2 * u,
          );
        }
      case Motif.candy:
        final p = _stroke(ink(0), 12 * u, cap: StrokeCap.butt);
        for (var d = -h; d < w + h; d += 30 * u) {
          cv.drawLine(
            Offset(d, h + 10 * u),
            Offset(d + h + 20 * u, -10 * u),
            p,
          );
        }
      case Motif.pinstripe:
        final pts = <double>[];
        for (var x = 7 * u; x < w; x += 14 * u) {
          pts.addAll([x, 0, x, h]);
        }
        _raw(cv, ui.PointMode.lines, pts, ink(0), 1.5 * u);
      case Motif.breton:
        for (var y = 12 * u; y < h + 12 * u; y += 24 * u) {
          _wobblyLine(
            Offset(-10 * u, y),
            Offset(w + 10 * u, y),
            ink(0),
            6 * u,
            0.8 * u,
          );
        }
      case Motif.gingham:
        final band = _fill(ink(0).withValues(alpha: artSoftFill));
        for (var x = 0.0; x < w; x += 28 * u) {
          cv.drawRect(Rect.fromLTWH(x, 0, 14 * u, h), band);
        }
        for (var y = 0.0; y < h; y += 28 * u) {
          cv.drawRect(Rect.fromLTWH(0, y, w, 14 * u), band);
        }
      case Motif.plaid:
        final band = _fill(ink(0).withValues(alpha: artSoftFill));
        for (var x = 0.0; x < w; x += 56 * u) {
          cv.drawRect(Rect.fromLTWH(x, 0, 22 * u, h), band);
        }
        for (var y = 0.0; y < h; y += 56 * u) {
          cv.drawRect(Rect.fromLTWH(0, y, w, 22 * u), band);
        }
        final lines = <double>[];
        for (var x = 38 * u; x < w; x += 56 * u) {
          lines.addAll([x, 0, x, h]);
        }
        for (var y = 38 * u; y < h; y += 56 * u) {
          lines.addAll([0, y, w, y]);
        }
        _raw(cv, ui.PointMode.lines, lines, ink(1), 2 * u);
      case Motif.checkerboard:
        final s = 26 * u;
        for (var row = 0; row * s < h; row++) {
          for (var col = row.isOdd ? 1 : 0; col * s < w; col += 2) {
            cv.drawRect(Rect.fromLTWH(col * s, row * s, s, s), _fill(ink(0)));
          }
        }
      case Motif.windowpane:
        final lines = <double>[];
        for (var x = 20 * u; x < w; x += 40 * u) {
          lines.addAll([x, 0, x, h]);
        }
        for (var y = 20 * u; y < h; y += 40 * u) {
          lines.addAll([0, y, w, y]);
        }
        _raw(cv, ui.PointMode.lines, lines, ink(0), 2.2 * u);
      case Motif.waves:
        for (var y = 10 * u; y < h + 20 * u; y += 22 * u) {
          _waveLine(y, 5 * u, 40 * u, ink(0), 3 * u);
        }
      case Motif.scallops:
        final r = 14 * u;
        final p = _stroke(ink(0), 2.5 * u);
        for (var row = 0; row * r < h + 2 * r; row++) {
          for (var x = row.isOdd ? r : 0.0; x < w + 2 * r; x += 2 * r) {
            cv.drawArc(
              Rect.fromCircle(center: Offset(x, row * r), radius: r),
              0,
              math.pi,
              false,
              p,
            );
          }
        }
      case Motif.zigzag:
        final p = _stroke(ink(0), 4 * u);
        for (var y = 8 * u; y < h + 20 * u; y += 26 * u) {
          final path = Path()..moveTo(-14 * u, y);
          var up = true;
          for (var x = 0.0; x < w + 28 * u; x += 14 * u) {
            path.lineTo(x, y + (up ? -8 : 0) * u);
            up = !up;
          }
          cv.drawPath(path, p);
        }
      case Motif.squiggle:
        final s = 40 * u;
        for (var y = -s / 2; y < h + s; y += s) {
          for (var x = -s / 2; x < w + s; x += s) {
            final c = Offset(
              x + _range(rng, -8, 8) * u,
              y + _range(rng, -8, 8) * u,
            );
            cv.save();
            cv.translate(c.dx, c.dy);
            cv.rotate(rng.nextDouble() * math.pi);
            final pts = [
              for (var i = 0; i <= 4; i++)
                Offset((i - 2) * 5 * u, (i.isEven ? -3.5 : 3.5) * u),
            ];
            cv.drawPath(_smoothOpen(pts), _stroke(ink(rng.nextInt(9)), 3 * u));
            cv.restore();
          }
        }
      case Motif.hearts:
        for (final (c, _) in _offsetGrid(44 * u, 38 * u)) {
          _shape(Sprite.heart, c, 9 * u, 0.25);
        }
      case Motif.stars:
        for (final (c, _) in _offsetGrid(44 * u, 38 * u)) {
          _shape(Sprite.star, c, 9 * u, 0.4);
        }
      case Motif.triangles:
        for (final (c, _) in _offsetGrid(40 * u, 34 * u)) {
          cv.save();
          cv.translate(c.dx, c.dy);
          cv.rotate(rng.nextDouble() * math.pi * 2);
          final r = 9 * u;
          _outline(
            cv,
            _polygon([
              for (var i = 0; i < 3; i++)
                Offset.fromDirection(-math.pi / 2 + i * 2 * math.pi / 3, r),
            ]),
            ink(0),
            2.2 * u,
          );
          cv.restore();
        }
      case Motif.crosses:
        final lines = <double>[];
        for (final (c, _) in _offsetGrid(30 * u, 26 * u)) {
          final a = 5.5 * u;
          lines.addAll([
            c.dx - a,
            c.dy,
            c.dx + a,
            c.dy,
            c.dx,
            c.dy - a,
            c.dx,
            c.dy + a,
          ]);
        }
        _raw(cv, ui.PointMode.lines, lines, ink(0), 3.5 * u);
      case Motif.diamonds:
        final sx = 30 * u, sy = 44 * u;
        for (final (c, i) in _offsetGrid(sx, sy / 2)) {
          final path = _polygon([
            c + Offset(0, -sy / 4 + u),
            c + Offset(sx / 2 - u, 0),
            c + Offset(0, sy / 4 - u),
            c + Offset(-sx / 2 + u, 0),
          ]);
          if (i.isEven) cv.drawPath(path, _soft(ink(0)));
          cv.drawPath(path, _stroke(ink(0), 1.6 * u));
        }
      case Motif.rainbows:
        for (final (c, _) in _offsetGrid(64 * u, 44 * u)) {
          for (var i = 0; i < 3; i++) {
            cv.drawArc(
              Rect.fromCircle(
                center: c + Offset(0, 6 * u),
                radius: (14 - i * 4.5) * u,
              ),
              math.pi,
              math.pi,
              false,
              _stroke(ink(i), 3.5 * u),
            );
          }
        }
      case Motif.grid:
        final thin = <double>[], thick = <double>[];
        var i = 0;
        for (var x = 0.0; x < w; x += 18 * u, i++) {
          (i % 5 == 0 ? thick : thin).addAll([x, 0, x, h]);
        }
        i = 0;
        for (var y = 0.0; y < h; y += 18 * u, i++) {
          (i % 5 == 0 ? thick : thin).addAll([0, y, w, y]);
        }
        _raw(cv, ui.PointMode.lines, thin, ink(0), 1 * u);
        _raw(cv, ui.PointMode.lines, thick, ink(0), 1.8 * u);
      case Motif.dotGrid:
        final pts = <double>[];
        for (var y = 9 * u; y < h; y += 18 * u) {
          for (var x = 9 * u; x < w; x += 18 * u) {
            pts.addAll([x, y]);
          }
        }
        _raw(cv, ui.PointMode.points, pts, ink(0), 3.2 * u);
      case Motif.lined:
        final lines = <double>[];
        for (var y = 30 * u; y < h; y += 26 * u) {
          lines.addAll([0, y, w, y]);
        }
        _raw(cv, ui.PointMode.lines, lines, ink(0), 1.2 * u);
        cv.drawLine(
          Offset(44 * u, 0),
          Offset(44 * u, h),
          _stroke(ink(1), 1.6 * u),
        );
    }
  }

  void _shape(Sprite s, Offset c, double r, double tilt) {
    cv.save();
    cv.translate(c.dx, c.dy);
    cv.rotate(_range(rng, -tilt, tilt));
    _spritePath(s, r, cv, ink(0), 2.2 * u, rng);
    cv.restore();
  }

  void _wobblyLine(Offset a, Offset b, Color c, double width, double wobble) {
    final n = math.max(2, ((b - a).distance / (30 * u)).ceil());
    final normal = Offset(-(b - a).dy, (b - a).dx) / (b - a).distance;
    final path = _smoothOpen([
      for (var i = 0; i <= n; i++)
        Offset.lerp(a, b, i / n)! + normal * _range(rng, -wobble, wobble),
    ]);
    cv.drawPath(path, _stroke(c, width));
  }

  void _waveLine(double y, double amp, double length, Color c, double width) {
    final path = Path()..moveTo(-length, y);
    for (var x = -length; x < w + length; x += length) {
      path
        ..quadraticBezierTo(x + length / 4, y - amp * 2, x + length / 2, y)
        ..quadraticBezierTo(x + length * 3 / 4, y + amp * 2, x + length, y);
    }
    cv.drawPath(path, _stroke(c, width));
  }
}

// MARK: Textures

class _TexturePainter {
  _TexturePainter(this.cv, this.size, this.art, this.u, this.rng);

  final Canvas cv;
  final Size size;
  final TextureArt art;
  final double u;
  final math.Random rng;

  double get w => size.width;
  double get h => size.height;
  Color tone(int i) => art.tones[i % art.tones.length];

  /// How many things at one per [each] square logical pixels.
  int count(double each) => (w * h / (each * u * u)).ceil();

  /// Random dots, one draw per tone.
  void specks(double each, double width, List<int> tones) {
    final byTone = {for (final t in tones) t: <double>[]};
    for (var i = 0, n = count(each); i < n; i++) {
      byTone[tones[i % tones.length]]!.addAll([
        rng.nextDouble() * w,
        rng.nextDouble() * h,
      ]);
    }
    for (final e in byTone.entries) {
      _raw(cv, ui.PointMode.points, e.value, tone(e.key), width * u);
    }
  }

  /// Short random strokes, one draw per tone.
  void fibres(
    double each,
    double minLen,
    double maxLen,
    double width,
    List<int> tones,
  ) {
    final byTone = {for (final t in tones) t: <double>[]};
    for (var i = 0, n = count(each); i < n; i++) {
      final a = Offset(rng.nextDouble() * w, rng.nextDouble() * h);
      final b =
          a +
          Offset.fromDirection(
            rng.nextDouble() * math.pi * 2,
            _range(rng, minLen, maxLen) * u,
          );
      byTone[tones[i % tones.length]]!.addAll([a.dx, a.dy, b.dx, b.dy]);
    }
    for (final e in byTone.entries) {
      _raw(cv, ui.PointMode.lines, e.value, tone(e.key), width * u);
    }
  }

  void paint() {
    switch (art.weave) {
      case Weave.paper:
        specks(70, 1.4, [0, 2]);
        specks(160, 2, [1]);
        fibres(900, 4, 12, 0.6, [0]);
      case Weave.kraft:
        specks(30, 1.2, [0, 2]);
        specks(80, 1.6, [1]);
        fibres(160, 4, 14, 0.7, [0, 2, 1]);
      case Weave.linen:
        for (final (vertical, step) in [(false, 2.6), (true, 3.4)]) {
          final lines = {0: <double>[], 1: <double>[]};
          final span = vertical ? w : h, along = vertical ? h : w;
          var k = 0;
          for (var p = 0.0; p < span; p += step * u, k++) {
            var s = -rng.nextDouble() * 20 * u;
            while (s < along) {
              final len = _range(rng, 12, 60) * u;
              final t = lines[(k + (s ~/ 7)) % 2]!;
              t.addAll(vertical ? [p, s, p, s + len] : [s, p, s + len, p]);
              s += len + _range(rng, 2, 10) * u;
            }
          }
          for (final e in lines.entries) {
            _raw(cv, ui.PointMode.lines, e.value, tone(e.key), 0.9 * u);
          }
        }
      case Weave.canvas:
        final cell = 3.2 * u;
        final a = <double>[], b = <double>[];
        for (var y = cell / 2; y < h; y += cell) {
          for (var x = cell / 2; x < w; x += cell) {
            final odd = ((x / cell).floor() + (y / cell).floor()).isOdd;
            if (rng.nextDouble() < 0.82) (odd ? a : b).addAll([x, y]);
          }
        }
        cv.drawRawPoints(
          ui.PointMode.points,
          Float32List.fromList(a),
          _stroke(tone(0), cell * 0.7, cap: StrokeCap.square),
        );
        cv.drawRawPoints(
          ui.PointMode.points,
          Float32List.fromList(b),
          _stroke(tone(1), cell * 0.5, cap: StrokeCap.square),
        );
      case Weave.denim:
        final lines = <double>[];
        for (var d = -h; d < w; d += 3.2 * u) {
          lines.addAll([d, h, d + h * 0.6, 0]);
        }
        _raw(cv, ui.PointMode.lines, lines, tone(0), 1.3 * u);
        fibres(120, 3, 9, 0.8, [1]);
        specks(90, 1.2, [2]);
      case Weave.corduroy:
        final period = 8 * u;
        for (var x = 0.0; x < w; x += period) {
          cv.drawRect(Rect.fromLTWH(x, 0, 3 * u, h), _fill(tone(0)));
          cv.drawRect(
            Rect.fromLTWH(x + 4.6 * u, 0, 1.3 * u, h),
            _fill(tone(1)),
          );
        }
      case Weave.felt:
        fibres(22, 2, 5, 0.8, [0, 1]);
      case Weave.grain:
        specks(10, 1.1, [0, 1]);
      case Weave.sand:
        specks(7, 1.1, [0, 1, 2]);
        specks(400, 2.2, [2]);
      case Weave.cork:
        for (var i = 0, n = count(26); i < n; i++) {
          cv.drawPath(
            _blob(
              Offset(rng.nextDouble() * w, rng.nextDouble() * h),
              _range(rng, 0.8, 2.8) * u,
              rng,
              wobble: 0.3,
              n: 5,
            ),
            _fill(tone(i)),
          );
        }
      case Weave.terrazzo:
        specks(60, 1.5, [0, 1, 2, 3]);
        for (var i = 0, n = count(520); i < n; i++) {
          final c = Offset(rng.nextDouble() * w, rng.nextDouble() * h);
          final r = _range(rng, 2.5, 8) * u;
          final k = 4 + rng.nextInt(3);
          final start = rng.nextDouble() * math.pi;
          cv.drawPath(
            _polygon([
              for (var j = 0; j < k; j++)
                c +
                    Offset.fromDirection(
                      start + j * 2 * math.pi / k + _range(rng, -0.3, 0.3),
                      r * _range(rng, 0.6, 1),
                    ),
            ]),
            _fill(tone(i)),
          );
        }
      case Weave.marble:
        final veins = math.max(3, (w * h / (26000 * u * u)).ceil());
        for (var v = 0; v < veins; v++) {
          var p = Offset(rng.nextDouble() * w, -10 * u);
          var angle = math.pi / 2 + _range(rng, -0.9, 0.2);
          final pts = <Offset>[p];
          while (p.dy < h + 20 * u && pts.length < 200) {
            angle += _range(rng, -0.35, 0.35);
            angle = angle.clamp(0.3, math.pi - 0.3);
            p += Offset.fromDirection(angle, 14 * u);
            pts.add(p);
          }
          cv.drawPath(_smoothOpen(pts), _stroke(tone(1), 5 * u));
          cv.drawPath(_smoothOpen(pts), _stroke(tone(0), 1.1 * u));
          // A thin branch.
          final from = rng.nextInt(pts.length);
          final branch = [pts[from]];
          var a = angle + _range(rng, -1, 1);
          for (var j = 0; j < 8; j++) {
            a += _range(rng, -0.4, 0.4);
            branch.add(branch.last + Offset.fromDirection(a, 10 * u));
          }
          cv.drawPath(_smoothOpen(branch), _stroke(tone(0), 0.7 * u));
        }
      case Weave.wood:
        final phase = rng.nextDouble() * 10;
        final knots = [
          for (
            var i = 0, n = math.max(1, (w * h / (60000 * u * u)).round());
            i < n;
            i++
          )
            Offset(rng.nextDouble() * w, rng.nextDouble() * h),
        ];
        var k = 0;
        for (
          var y0 = -10 * u;
          y0 < h + 10 * u;
          y0 += _range(rng, 3, 7) * u, k++
        ) {
          final pts = <Offset>[];
          for (var x = -10 * u; x < w + 20 * u; x += 12 * u) {
            var y = y0 + 3 * u * math.sin(x / (70 * u) + phase + y0 / (90 * u));
            for (final kn in knots) {
              final d = (Offset(x, y) - kn).distance;
              if (d < 40 * u) y += (y > kn.dy ? 1 : -1) * (40 * u - d) * 0.35;
            }
            pts.add(Offset(x, y));
          }
          cv.drawPath(
            _smoothOpen(pts),
            _stroke(tone(k % 3 == 0 ? 1 : 0), (k % 4 == 0 ? 1.6 : 0.9) * u),
          );
        }
        for (final kn in knots) {
          for (var r = 3.0; r < 14; r += 3.5) {
            cv.drawOval(
              Rect.fromCenter(center: kn, width: r * 2.4 * u, height: r * u),
              _stroke(tone(0), 1 * u),
            );
          }
        }
      case Weave.watercolour:
        final blur = MaskFilter.blur(BlurStyle.normal, 14 * u);
        for (var i = 0, n = math.max(6, count(7000)); i < n; i++) {
          cv.drawPath(
            _blob(
              Offset(rng.nextDouble() * w, rng.nextDouble() * h),
              _range(rng, 28, 80) * u,
              rng,
              wobble: 0.25,
            ),
            _fill(tone(i).withValues(alpha: 0.7))..maskFilter = blur,
          );
        }
        specks(500, 2.5, [0]);
      case Weave.stucco:
        for (var i = 0, n = count(140); i < n; i++) {
          cv.drawPath(
            _blob(
              Offset(rng.nextDouble() * w, rng.nextDouble() * h),
              _range(rng, 2, 7) * u,
              rng,
              wobble: 0.3,
              n: 6,
            ),
            _fill(tone(i)),
          );
        }
        specks(40, 1, [0, 1]);
    }
  }
}

// MARK: Illustrations

const _upright = {
  Sprite.balloon,
  Sprite.lantern,
  Sprite.hotAirBalloon,
  Sprite.sailboat,
  Sprite.cloud,
  Sprite.diya,
  Sprite.gradCap,
  Sprite.gift,
  Sprite.pumpkin,
  Sprite.bird,
  Sprite.plane,
  Sprite.bat,
  Sprite.fish,
  Sprite.rings,
  Sprite.bubble,
};

const _big = {
  Sprite.balloon,
  Sprite.lantern,
  Sprite.hotAirBalloon,
  Sprite.cloud,
  Sprite.plane,
  Sprite.sailboat,
};

class _IllustrationPainter {
  _IllustrationPainter(this.cv, this.size, this.art, this.u, this.rng);

  final Canvas cv;
  final Size size;
  final IllustrationArt art;
  final double u;
  final math.Random rng;

  double get w => size.width;
  double get h => size.height;
  double get sw => 2.2 * u;

  Color land(int i) => art.landColors[math.min(i, art.landColors.length - 1)];

  late final double landH = art.land == Land.none
      ? 0
      : _swatch
      ? h * 0.3
      : (h * 0.22).clamp(math.min(26 * u, h * 0.3), 220 * u);
  late final double horizon = h - landH;

  late final double heroR = _swatch
      ? math.min(w, h) * 0.17
      : (math.min(w, h) * 0.17).clamp(12 * u, 70 * u);
  late final Offset heroC = _swatch
      ? Offset(w * 0.7, h * 0.34)
      : Offset(w * 0.76, math.min(h * 0.38, horizon - heroR * 1.4));

  /// Swatches are too small for the scattered layout, so they get a
  /// fixed little scene: a few sprites, the hero and the land.
  bool get _swatch => math.min(w, h) < 90;

  void paint() {
    _hero();
    if (_swatch) {
      _swatchSprites();
    } else {
      _sprites();
    }
    _land();
  }

  void _swatchSprites() {
    final kinds = art.sprites.where((s) => s != Sprite.sailboat).toList();
    if (kinds.isEmpty || art.spriteColors.isEmpty) return;
    final spots = art.hero == SkyFeature.none || art.hero == SkyFeature.rainbow
        ? const [(0.3, 0.32), (0.72, 0.36), (0.48, 0.66)]
        : const [(0.26, 0.3), (0.32, 0.66)];
    for (var i = 0; i < spots.length; i++) {
      final (fx, fy) = spots[i];
      final kind = kinds[i % kinds.length];
      final c = Offset(w * fx, math.min(h * fy, horizon - h * 0.08));
      cv.save();
      cv.translate(c.dx, c.dy);
      if (!_upright.contains(kind)) cv.rotate(i.isEven ? -0.25 : 0.25);
      final r = math.min(w, h) * (_big.contains(kind) ? 0.16 : 0.13);
      _spritePath(
        kind,
        r,
        cv,
        art.spriteColors[i % art.spriteColors.length],
        1.6 * u,
        rng,
      );
      cv.restore();
    }
  }

  void _hero() {
    if (art.heroColors.isEmpty) return;
    final c = art.heroColors.first;
    switch (art.hero) {
      case SkyFeature.none:
        break;
      case SkyFeature.sun:
        _outline(cv, _blob(heroC, heroR, rng, wobble: 0.03), c, sw * 1.2);
        final rays = <double>[];
        for (var i = 0; i < 12; i++) {
          final a = i * math.pi / 6 + 0.1;
          final p1 = heroC + Offset.fromDirection(a, heroR * 1.28);
          final p2 =
              heroC +
              Offset.fromDirection(
                a,
                heroR * 1.28 + math.max(5 * u, heroR * 0.3),
              );
          rays.addAll([p1.dx, p1.dy, p2.dx, p2.dy]);
        }
        _raw(cv, ui.PointMode.lines, rays, c, sw * 1.2);
      case SkyFeature.moon:
        final moon = Path.combine(
          PathOperation.difference,
          Path()..addOval(Rect.fromCircle(center: heroC, radius: heroR)),
          Path()..addOval(
            Rect.fromCircle(
              center: heroC + Offset(heroR * 0.5, -heroR * 0.3),
              radius: heroR * 0.85,
            ),
          ),
        );
        _outline(cv, moon, c, sw * 1.2);
      case SkyFeature.rainbow:
        final bandW = math.max(6 * u, landH * 0.18);
        final r = math.min(w * 0.42, horizon * 0.7);
        final centre = Offset(w * 0.68, horizon + landH * 0.4);
        for (var i = 0; i < art.heroColors.length; i++) {
          cv.drawArc(
            Rect.fromCircle(center: centre, radius: r - i * bandW),
            math.pi,
            math.pi,
            false,
            _stroke(art.heroColors[i], bandW * 0.85, cap: StrokeCap.butt),
          );
        }
    }
  }

  void _sprites() {
    final kinds = art.sprites.where((s) => s != Sprite.sailboat).toList();
    if (kinds.isEmpty || art.spriteColors.isEmpty) return;
    final base = 13 * u;
    final cell = base * 4.6 / math.sqrt(art.density);
    final colors = art.spriteColors;
    var n = 0;
    for (var y = cell * 0.2; y < horizon + base * 0.5; y += cell * 0.86) {
      final row = (y / cell).round();
      for (
        var x = row.isOdd ? cell * 0.5 : 0.0;
        x < w + cell * 0.5;
        x += cell
      ) {
        if (rng.nextDouble() > 0.78) continue;
        final kind = kinds[rng.nextInt(kinds.length)];
        final big = _big.contains(kind);
        if (big &&
            rng.nextDouble() <
                (kind == Sprite.cloud || kind == Sprite.plane ? 0.45 : 0.15)) {
          continue;
        }
        var r = base * _range(rng, 0.75, 1.2) * (big ? 1.5 : 1);
        final c = Offset(
          x + _range(rng, -0.3, 0.3) * cell,
          y + _range(rng, -0.25, 0.25) * cell,
        );
        if (art.hero != SkyFeature.none &&
            art.hero != SkyFeature.rainbow &&
            (c - heroC).distance < heroR * 1.7 + r) {
          continue;
        }
        // Keep things in the sky, apart from what falls.
        if (c.dy > horizon - r * (big ? 1.6 : 0.4)) {
          if (big) continue;
          r *= 0.8;
        }
        cv.save();
        cv.translate(c.dx, c.dy);
        if (!_upright.contains(kind)) cv.rotate(_range(rng, -0.45, 0.45));
        if ({Sprite.bird, Sprite.fish, Sprite.plane}.contains(kind) &&
            rng.nextBool()) {
          cv.scale(-1, 1);
        }
        _spritePath(kind, r, cv, colors[n++ % colors.length], sw, rng);
        cv.restore();
      }
    }
  }

  /// A wavy top edge from y = [top] with [amp] and [length].
  Path _band(double top, double amp, double length, {double phase = 0}) {
    final pts = <Offset>[
      for (var x = -length; x <= w + length; x += length / 4)
        Offset(x, top + amp * math.sin(x / length * 2 * math.pi + phase)),
    ];
    return _smoothOpen(pts)
      ..lineTo(w + length, h + 1)
      ..lineTo(-length, h + 1)
      ..close();
  }

  Path _hills(double top, double amp, double span) =>
      _band(top, amp, span, phase: rng.nextDouble() * 6);

  void _land() {
    final lh = landH, top = horizon;
    switch (art.land) {
      case Land.none:
        break;
      case Land.hills:
        cv.drawPath(
          _hills(top + lh * 0.22, lh * 0.18, w * 0.9),
          _fill(land(0)),
        );
        cv.drawPath(
          _hills(top + lh * 0.55, lh * 0.14, w * 0.7),
          _fill(land(1)),
        );
      case Land.waves:
        cv.drawPath(
          _band(top + lh * 0.12, math.max(2.5 * u, lh * 0.05), 42 * u),
          _fill(land(0)),
        );
        _boats(top + lh * 0.3);
        cv.drawPath(
          _band(
            top + lh * 0.5,
            math.max(2.5 * u, lh * 0.05),
            54 * u,
            phase: 1.3,
          ),
          _fill(land(1)),
        );
      case Land.dunes:
        cv.drawPath(_hills(top + lh * 0.2, lh * 0.2, w * 1.1), _fill(land(0)));
        final front = _hills(top + lh * 0.55, lh * 0.12, w * 0.8);
        cv.drawPath(front, _fill(land(1)));
        if (art.landColors.length > 2) {
          for (final f in [0.16, 0.86]) {
            _cactus(Offset(w * f, top + lh * 0.62), lh * 0.7);
          }
        }
      case Land.snow:
        cv.drawPath(_hills(top + lh * 0.2, lh * 0.12, w * 0.5), _fill(land(0)));
        cv.drawPath(_hills(top + lh * 0.55, lh * 0.1, w * 0.4), _fill(land(1)));
      case Land.mountains:
        var x = -30 * u;
        while (x < w + 30 * u) {
          final half = _range(rng, 40, 75) * u;
          final peak = Offset(x + half, top - lh * _range(rng, 0.3, 0.75));
          final base = top + lh * 0.6;
          cv.drawPath(
            _polygon([Offset(x, base), peak, Offset(x + half * 2, base)]),
            _fill(land(0)),
          );
          if (art.landColors.length > 2) {
            final t = 0.3;
            final l = Offset.lerp(peak, Offset(x, base), t)!;
            final r = Offset.lerp(peak, Offset(x + half * 2, base), t)!;
            cv.drawPath(
              _polygon([
                peak,
                r,
                Offset.lerp(l, r, 0.7)! + Offset(0, -3 * u),
                Offset.lerp(l, r, 0.5)! + Offset(0, 4 * u),
                Offset.lerp(l, r, 0.3)! + Offset(0, -2 * u),
                l,
              ]),
              _fill(land(2)),
            );
          }
          x += half * _range(rng, 1.1, 1.6);
        }
        cv.drawPath(
          _hills(top + lh * 0.55, lh * 0.12, w * 0.8),
          _fill(land(1)),
        );
      case Land.skyline:
        for (final (layer, lo, hi, minW, maxW) in [
          (0, 0.7, 1.6, 18.0, 40.0),
          (1, 0.35, 1.0, 22.0, 46.0),
        ]) {
          var x = -5 * u;
          while (x < w) {
            final bw = _range(rng, minW, maxW) * u;
            final bh = lh * _range(rng, lo, hi);
            final rect = Rect.fromLTWH(x, h - bh, bw - 2 * u, bh + 1);
            cv.drawRect(rect, _fill(land(layer)));
            if (layer == 1 && art.landColors.length > 2) {
              final lit = _fill(land(2));
              for (var wy = rect.top + 5 * u; wy < h - 6 * u; wy += 8 * u) {
                for (
                  var wx = rect.left + 4 * u;
                  wx < rect.right - 6 * u;
                  wx += 7 * u
                ) {
                  if (rng.nextDouble() < 0.35) {
                    cv.drawRect(Rect.fromLTWH(wx, wy, 3 * u, 4 * u), lit);
                  }
                }
              }
            }
            x += bw;
          }
        }
      case Land.forest:
      case Land.camp:
        cv.drawPath(_hills(top + lh * 0.4, lh * 0.08, w), _fill(land(0)));
        _trees(top + lh * 0.48, lh * 0.75, land(0), 0.9);
        final front = _hills(top + lh * 0.7, lh * 0.06, w * 0.8);
        _trees(top + lh * 0.78, lh * 0.55, land(1), 1.6);
        cv.drawPath(front, _fill(land(1)));
        if (art.land == Land.camp && art.landColors.length > 2) {
          _tent(Offset(w * 0.3, top + lh * 0.82), lh * 0.45);
        }
      case Land.meadow:
        cv.drawPath(_hills(top + lh * 0.2, lh * 0.1, w * 0.9), _fill(land(0)));
        cv.drawPath(_hills(top + lh * 0.5, lh * 0.08, w * 0.7), _fill(land(1)));
        if (art.landColors.length > 2) {
          final tufts = <double>[];
          for (var i = 0, n = (w / (16 * u)).ceil(); i < n; i++) {
            final p = Offset(
              rng.nextDouble() * w,
              _range(rng, top + lh * 0.6, h - 4 * u),
            );
            for (final a in [-0.5, 0.0, 0.5]) {
              final q = p + Offset.fromDirection(-math.pi / 2 + a, 5 * u);
              tufts.addAll([p.dx, p.dy, q.dx, q.dy]);
            }
          }
          _raw(cv, ui.PointMode.lines, tufts, land(2), 1.6 * u);
        }
      case Land.beach:
        cv.drawPath(
          _band(top + lh * 0.1, math.max(2.5 * u, lh * 0.04), 40 * u),
          _fill(land(0)),
        );
        cv.drawPath(_hills(top + lh * 0.55, lh * 0.1, w * 1.2), _fill(land(1)));
        if (art.landColors.length > 2) {
          _palm(Offset(w * 0.12, top + lh * 0.7), lh * 1.1);
        }
    }
  }

  void _boats(double y) {
    if (!art.sprites.contains(Sprite.sailboat) || art.spriteColors.isEmpty) {
      return;
    }
    final r = math.max(9 * u, landH * 0.28).clamp(9 * u, 26 * u);
    for (final f in w > 250 * u ? [0.22, 0.68] : [0.3]) {
      cv.save();
      cv.translate(w * f, y - r * 0.5);
      _spritePath(Sprite.sailboat, r, cv, art.spriteColors.first, sw, rng);
      cv.restore();
    }
  }

  void _trees(double base, double height, Color c, double spacing) {
    var x = _range(rng, -10, 0) * u;
    while (x < w + 10 * u) {
      final th = height * _range(rng, 0.7, 1.1);
      final tw = th * 0.42;
      final path = Path();
      for (var t = 0; t < 3; t++) {
        final y0 = base - th * (0.15 + t * 0.28);
        final y1 = base - th * (0.55 + t * 0.28);
        final half = tw * (1 - t * 0.25);
        path.addPolygon([
          Offset(x - half, y0),
          Offset(x, math.min(y1, base - th)),
          Offset(x + half, y0),
        ], true);
      }
      path.addRect(
        Rect.fromLTWH(x - th * 0.05, base - th * 0.2, th * 0.1, th * 0.25),
      );
      cv.drawPath(path, _fill(c));
      x += tw * spacing * _range(rng, 0.9, 1.4);
    }
  }

  void _cactus(Offset foot, double height) {
    final c = land(2);
    final wd = height * 0.22;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(foot.dx - wd / 2, foot.dy - height, wd, height),
          Radius.circular(wd / 2),
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            foot.dx - wd * 2.1,
            foot.dy - height * 0.75,
            wd * 0.8,
            height * 0.38,
          ),
          Radius.circular(wd * 0.4),
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            foot.dx + wd * 1.3,
            foot.dy - height * 0.85,
            wd * 0.8,
            height * 0.34,
          ),
          Radius.circular(wd * 0.4),
        ),
      );
    final arms = Path()
      ..moveTo(foot.dx - wd * 1.7, foot.dy - height * 0.42)
      ..quadraticBezierTo(
        foot.dx - wd * 1.7,
        foot.dy - height * 0.3,
        foot.dx - wd * 0.5,
        foot.dy - height * 0.3,
      )
      ..moveTo(foot.dx + wd * 1.7, foot.dy - height * 0.55)
      ..quadraticBezierTo(
        foot.dx + wd * 1.7,
        foot.dy - height * 0.45,
        foot.dx + wd * 0.5,
        foot.dy - height * 0.45,
      );
    _outline(cv, path, c, sw);
    cv.drawPath(arms, _stroke(c, wd * 0.8));
  }

  void _tent(Offset foot, double height) {
    final c = land(2);
    final half = height * 0.85;
    final path = _polygon([
      foot + Offset(-half, 0),
      foot + Offset(0, -height),
      foot + Offset(half, 0),
    ]);
    _outline(cv, path, c, sw);
    cv.drawPath(
      Path()
        ..moveTo(foot.dx, foot.dy - height)
        ..lineTo(foot.dx - half * 0.25, foot.dy)
        ..moveTo(foot.dx, foot.dy - height)
        ..lineTo(foot.dx + half * 0.25, foot.dy),
      _stroke(c, sw),
    );
  }

  void _palm(Offset foot, double height) {
    final c = land(2);
    final top = foot + Offset(height * 0.25, -height);
    cv.drawPath(
      Path()
        ..moveTo(foot.dx, foot.dy)
        ..quadraticBezierTo(
          foot.dx + height * 0.02,
          foot.dy - height * 0.6,
          top.dx,
          top.dy,
        ),
      _stroke(c, math.max(3 * u, height * 0.06)),
    );
    for (var i = 0; i < 6; i++) {
      final a = -math.pi + i * math.pi / 5 + _range(rng, -0.15, 0.15);
      final len = height * _range(rng, 0.38, 0.5);
      final tip = top + Offset.fromDirection(a, len) + Offset(0, len * 0.35);
      final mid =
          top + Offset.fromDirection(a, len * 0.5) + Offset(0, -len * 0.08);
      final normal = Offset.fromDirection(a + math.pi / 2, len * 0.14);
      _outline(
        cv,
        Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(
            mid.dx + normal.dx,
            mid.dy + normal.dy,
            tip.dx,
            tip.dy,
          )
          ..quadraticBezierTo(
            mid.dx - normal.dx,
            mid.dy - normal.dy,
            top.dx,
            top.dy,
          ),
        c,
        sw,
      );
    }
  }
}

/// Draws [s] centred on the canvas origin, about [r] in radius.
void _spritePath(
  Sprite s,
  double r,
  Canvas cv,
  Color c,
  double sw,
  math.Random rng,
) {
  Offset p(double x, double y) => Offset(x * r, y * r);
  Path poly(List<List<double>> pts) =>
      _polygon([for (final q in pts) p(q[0], q[1])]);
  final line = _stroke(c, sw);
  switch (s) {
    case Sprite.star:
      _outline(
        cv,
        _polygon([
          for (var i = 0; i < 10; i++)
            Offset.fromDirection(
              -math.pi / 2 + i * math.pi / 5,
              r * (i.isEven ? 1 : 0.48),
            ),
        ]),
        c,
        sw,
      );
    case Sprite.sparkle:
      final path = Path()..moveTo(0, -r);
      for (var i = 1; i <= 4; i++) {
        final a = -math.pi / 2 + i * math.pi / 2;
        final mid = Offset.fromDirection(a - math.pi / 4, r * 0.18);
        final tip = Offset.fromDirection(a, r);
        path.quadraticBezierTo(mid.dx, mid.dy, tip.dx, tip.dy);
      }
      _outline(cv, path..close(), c, sw);
    case Sprite.snowflake:
      final lines = <double>[];
      for (var i = 0; i < 6; i++) {
        final a = i * math.pi / 3;
        final tip = Offset.fromDirection(a, r);
        final b = Offset.fromDirection(a, r * 0.55);
        lines.addAll([0, 0, tip.dx, tip.dy]);
        for (final side in [-0.6, 0.6]) {
          final q = b + Offset.fromDirection(a + side, r * 0.32);
          lines.addAll([b.dx, b.dy, q.dx, q.dy]);
        }
      }
      _raw(cv, ui.PointMode.lines, lines, c, sw);
    case Sprite.heart:
      _outline(cv, _heart(r), c, sw);
    case Sprite.balloon:
      _outline(
        cv,
        Path()..addOval(Rect.fromLTWH(-0.7 * r, -1.25 * r, 1.4 * r, 1.7 * r)),
        c,
        sw,
      );
      _outline(
        cv,
        poly([
          [-0.13, 0.6],
          [0.13, 0.6],
          [0, 0.45],
        ]),
        c,
        sw * 0.8,
      );
      cv.drawPath(
        Path()
          ..moveTo(0, 0.6 * r)
          ..cubicTo(0.25 * r, 1.0 * r, -0.2 * r, 1.4 * r, 0.1 * r, 1.9 * r),
        _stroke(c, sw * 0.6),
      );
      cv.drawArc(
        Rect.fromLTWH(-0.45 * r, -1.0 * r, 0.6 * r, 0.8 * r),
        math.pi * 1.05,
        math.pi * 0.4,
        false,
        _stroke(c, sw * 0.8),
      );
    case Sprite.confetti:
      if (rng.nextBool()) {
        cv.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: 0.45 * r,
              height: 1.2 * r,
            ),
            Radius.circular(0.18 * r),
          ),
          _fill(c),
        );
      } else {
        cv.drawPath(
          _smoothOpen([
            p(-0.8, 0.2),
            p(-0.4, -0.25),
            p(0, 0.2),
            p(0.4, -0.25),
            p(0.8, 0.2),
          ]),
          _stroke(c, sw * 1.2),
        );
      }
    case Sprite.leaf:
      _outline(
        cv,
        Path()
          ..moveTo(0, -r)
          ..quadraticBezierTo(0.9 * r, -0.2 * r, 0, r)
          ..quadraticBezierTo(-0.9 * r, -0.2 * r, 0, -r)
          ..close(),
        c,
        sw,
      );
      cv.drawLine(p(0, -0.65), p(0, 1.25), line);
      cv.drawLine(p(0, -0.05), p(0.3, -0.35), _stroke(c, sw * 0.7));
      cv.drawLine(p(0, 0.35), p(-0.3, 0.05), _stroke(c, sw * 0.7));
    case Sprite.flower:
      for (var i = 0; i < 5; i++) {
        cv.save();
        cv.rotate(i * 2 * math.pi / 5);
        _outline(
          cv,
          Path()..addOval(
            Rect.fromCenter(
              center: p(0, -0.52),
              width: 0.58 * r,
              height: 0.78 * r,
            ),
          ),
          c,
          sw * 0.8,
        );
        cv.restore();
      }
      cv.drawCircle(Offset.zero, 0.26 * r, _fill(c));
    case Sprite.blossom:
      for (var i = 0; i < 5; i++) {
        cv.save();
        cv.rotate(i * 2 * math.pi / 5);
        _outline(
          cv,
          Path()
            ..moveTo(0, -0.12 * r)
            ..cubicTo(
              -0.5 * r,
              -0.35 * r,
              -0.42 * r,
              -1.0 * r,
              -0.13 * r,
              -0.98 * r,
            )
            ..lineTo(0, -0.84 * r)
            ..lineTo(0.13 * r, -0.98 * r)
            ..cubicTo(0.42 * r, -1.0 * r, 0.5 * r, -0.35 * r, 0, -0.12 * r)
            ..close(),
          c,
          sw * 0.8,
        );
        cv.restore();
      }
      for (var i = 0; i < 5; i++) {
        cv.drawCircle(
          Offset.fromDirection(i * 2 * math.pi / 5 + 0.6, 0.2 * r),
          0.07 * r + sw * 0.3,
          _fill(c),
        );
      }
    case Sprite.cloud:
      var cloud = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(-1.1 * r, -0.05 * r, 2.2 * r, 0.6 * r),
            Radius.circular(0.3 * r),
          ),
        );
      for (final (x, y, rr) in [
        (-0.5, 0.05, 0.42),
        (0.05, -0.2, 0.55),
        (0.6, 0.1, 0.36),
      ]) {
        cloud = Path.combine(
          PathOperation.union,
          cloud,
          Path()..addOval(Rect.fromCircle(center: p(x, y), radius: rr * r)),
        );
      }
      _outline(cv, cloud, c, sw);
    case Sprite.bird:
      cv.drawPath(
        Path()
          ..moveTo(-r, 0)
          ..quadraticBezierTo(-0.5 * r, -0.55 * r, 0, 0.05 * r)
          ..quadraticBezierTo(0.5 * r, -0.55 * r, r, 0),
        _stroke(c, sw * 1.1),
      );
    case Sprite.raindrop:
      _outline(
        cv,
        Path()
          ..moveTo(0, -0.9 * r)
          ..cubicTo(0.55 * r, -0.1 * r, 0.55 * r, 0.7 * r, 0, 0.7 * r)
          ..cubicTo(-0.55 * r, 0.7 * r, -0.55 * r, -0.1 * r, 0, -0.9 * r)
          ..close(),
        c,
        sw,
      );
    case Sprite.bubble:
      final rr = r * _range(rng, 0.45, 0.85);
      cv.drawCircle(Offset.zero, rr, _soft(c));
      cv.drawCircle(Offset.zero, rr, line);
      cv.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: rr * 0.62),
        math.pi * 1.1,
        math.pi * 0.35,
        false,
        _stroke(c, sw * 0.8),
      );
    case Sprite.lantern:
      cv.drawLine(p(0, -0.78), p(0, -1.6), _stroke(c, sw * 0.6));
      _outline(
        cv,
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(-0.75 * r, -0.62 * r, 1.5 * r, 1.24 * r),
            Radius.circular(0.55 * r),
          ),
        ),
        c,
        sw,
      );
      cv.drawPath(
        Path()
          ..moveTo(-0.3 * r, -0.6 * r)
          ..quadraticBezierTo(-0.5 * r, 0, -0.3 * r, 0.6 * r)
          ..moveTo(0.3 * r, -0.6 * r)
          ..quadraticBezierTo(0.5 * r, 0, 0.3 * r, 0.6 * r),
        _stroke(c, sw * 0.7),
      );
      cv.drawRect(
        Rect.fromLTWH(-0.35 * r, -0.8 * r, 0.7 * r, 0.2 * r),
        _fill(c),
      );
      cv.drawRect(
        Rect.fromLTWH(-0.35 * r, 0.6 * r, 0.7 * r, 0.2 * r),
        _fill(c),
      );
      cv.drawLine(p(0, 0.8), p(0, 1.3), _stroke(c, sw * 0.9));
    case Sprite.firework:
      final lines = <double>[];
      final dots = <double>[];
      for (var i = 0; i < 12; i++) {
        final a = i * math.pi / 6;
        final q1 = Offset.fromDirection(a, r * 0.35),
            q2 = Offset.fromDirection(a, r * 0.95);
        final d = Offset.fromDirection(a + math.pi / 12, r * 1.12);
        lines.addAll([q1.dx, q1.dy, q2.dx, q2.dy]);
        dots.addAll([d.dx, d.dy]);
      }
      _raw(cv, ui.PointMode.lines, lines, c, sw);
      _raw(cv, ui.PointMode.points, dots, c, sw * 1.6);
    case Sprite.pumpkin:
      for (final (x, wd) in [(-0.38, 0.95), (0.38, 0.95), (0.0, 1.0)]) {
        _outline(
          cv,
          Path()..addOval(
            Rect.fromCenter(center: p(x, 0.12), width: wd * r, height: 1.3 * r),
          ),
          c,
          sw,
        );
      }
      cv.drawPath(
        Path()
          ..moveTo(0, -0.5 * r)
          ..quadraticBezierTo(0.05 * r, -0.85 * r, 0.25 * r, -0.95 * r),
        _stroke(c, sw * 1.5),
      );
    case Sprite.bat:
      final wing = Path()
        ..moveTo(-0.15 * r, -0.15 * r)
        ..cubicTo(-0.5 * r, -0.65 * r, -0.95 * r, -0.5 * r, -1.15 * r, -0.2 * r)
        ..quadraticBezierTo(-0.9 * r, -0.12 * r, -0.78 * r, 0.12 * r)
        ..quadraticBezierTo(-0.6 * r, -0.02 * r, -0.45 * r, 0.18 * r)
        ..quadraticBezierTo(-0.32 * r, 0.02 * r, -0.15 * r, 0.15 * r)
        ..close();
      _outline(cv, wing, c, sw * 0.8);
      cv.save();
      cv.scale(-1, 1);
      _outline(cv, wing, c, sw * 0.8);
      cv.restore();
      _outline(
        cv,
        Path()
          ..addOval(
            Rect.fromCenter(
              center: p(0, 0.05),
              width: 0.38 * r,
              height: 0.6 * r,
            ),
          )
          ..addPolygon([
            p(-0.16, -0.12),
            p(-0.12, -0.38),
            p(-0.02, -0.18),
          ], true)
          ..addPolygon([p(0.16, -0.12), p(0.12, -0.38), p(0.02, -0.18)], true),
        c,
        sw * 0.8,
      );
    case Sprite.egg:
      final egg = Path()
        ..moveTo(0, -r)
        ..cubicTo(0.55 * r, -r, 0.78 * r, 0.1 * r, 0.72 * r, 0.35 * r)
        ..cubicTo(0.62 * r, 0.85 * r, -0.62 * r, 0.85 * r, -0.72 * r, 0.35 * r)
        ..cubicTo(-0.78 * r, 0.1 * r, -0.55 * r, -r, 0, -r)
        ..close();
      _outline(cv, egg, c, sw);
      cv.save();
      cv.clipPath(egg);
      final zig = Path()..moveTo(-r, 0);
      for (var i = 0; i <= 8; i++) {
        zig.lineTo(-r + i * 0.25 * r, i.isEven ? 0.05 * r : -0.15 * r);
      }
      cv.drawPath(zig, line);
      cv.restore();
    case Sprite.gift:
      _outline(
        cv,
        Path()..addRect(Rect.fromLTWH(-0.75 * r, -0.45 * r, 1.5 * r, 1.25 * r)),
        c,
        sw,
      );
      _outline(
        cv,
        Path()..addRect(Rect.fromLTWH(-0.88 * r, -0.72 * r, 1.76 * r, 0.3 * r)),
        c,
        sw,
      );
      cv.drawLine(p(0, -0.72), p(0, 0.8), line);
      for (final sx in [-1.0, 1.0]) {
        cv.drawPath(
          Path()
            ..moveTo(0, -0.72 * r)
            ..cubicTo(
              sx * -0.1 * r,
              -1.25 * r,
              sx * 0.75 * r,
              -1.2 * r,
              0,
              -0.72 * r,
            ),
          line,
        );
      }
    case Sprite.clover:
      for (var i = 0; i < 3; i++) {
        cv.save();
        cv.rotate(i * 2 * math.pi / 3);
        cv.translate(0, -0.45 * r);
        cv.rotate(math.pi);
        _outline(cv, _heart(r * 0.5), c, sw * 0.8);
        cv.restore();
      }
      cv.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(0.05 * r, 0.7 * r, 0.35 * r, 1.15 * r),
        line,
      );
    case Sprite.butterfly:
      for (final sx in [-1.0, 1.0]) {
        cv.save();
        cv.scale(sx, 1);
        cv.save();
        cv.translate(0.45 * r, -0.3 * r);
        cv.rotate(0.45);
        _outline(
          cv,
          Path()..addOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: 0.75 * r,
              height: 0.95 * r,
            ),
          ),
          c,
          sw * 0.8,
        );
        cv.restore();
        _outline(
          cv,
          Path()..addOval(
            Rect.fromCenter(
              center: p(0.33, 0.38),
              width: 0.52 * r,
              height: 0.6 * r,
            ),
          ),
          c,
          sw * 0.8,
        );
        cv.drawPath(
          Path()
            ..moveTo(0, -0.55 * r)
            ..quadraticBezierTo(0.05 * r, -0.95 * r, 0.32 * r, -1.05 * r),
          _stroke(c, sw * 0.7),
        );
        cv.restore();
      }
      cv.drawLine(p(0, -0.6), p(0, 0.65), _stroke(c, sw * 1.4));
    case Sprite.gradCap:
      _outline(
        cv,
        poly([
          [-0.55, -0.2],
          [-0.55, 0.4],
          [0.55, 0.4],
          [0.55, -0.2],
        ])..addArc(
          Rect.fromLTWH(-0.55 * r, 0.15 * r, 1.1 * r, 0.5 * r),
          0,
          math.pi,
        ),
        c,
        sw,
      );
      _outline(
        cv,
        poly([
          [0, -0.9],
          [1.05, -0.42],
          [0, 0.05],
          [-1.05, -0.42],
        ]),
        c,
        sw,
      );
      cv.drawPath(
        Path()
          ..moveTo(0, -0.42 * r)
          ..lineTo(0.75 * r, -0.2 * r)
          ..lineTo(0.75 * r, 0.45 * r),
        _stroke(c, sw * 0.8),
      );
      cv.drawCircle(p(0.75, 0.5), 0.1 * r, _fill(c));
    case Sprite.plane:
      _outline(
        cv,
        poly([
          [-0.05, 0],
          [0.28, 0],
          [-0.22, 0.78],
          [-0.45, 0.78],
        ]),
        c,
        sw * 0.8,
      );
      _outline(
        cv,
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(-1.05 * r, -0.17 * r, 2.1 * r, 0.34 * r),
            Radius.circular(0.17 * r),
          ),
        ),
        c,
        sw * 0.8,
      );
      _outline(
        cv,
        poly([
          [-0.05, -0.05],
          [0.22, -0.05],
          [-0.25, -0.62],
          [-0.42, -0.62],
        ]),
        c,
        sw * 0.8,
      );
      _outline(
        cv,
        poly([
          [-0.72, -0.1],
          [-0.92, -0.58],
          [-1.05, -0.58],
          [-1.0, -0.05],
        ]),
        c,
        sw * 0.8,
      );
    case Sprite.hotAirBalloon:
      final env = Path()
        ..moveTo(0, -1.2 * r)
        ..cubicTo(0.95 * r, -1.2 * r, 1.05 * r, 0, 0.3 * r, 0.55 * r)
        ..lineTo(-0.3 * r, 0.55 * r)
        ..cubicTo(-1.05 * r, 0, -0.95 * r, -1.2 * r, 0, -1.2 * r)
        ..close();
      _outline(cv, env, c, sw);
      cv.drawPath(
        Path()
          ..moveTo(0, -1.2 * r)
          ..cubicTo(0.45 * r, -1.0 * r, 0.45 * r, 0.2 * r, 0.12 * r, 0.55 * r)
          ..moveTo(0, -1.2 * r)
          ..cubicTo(
            -0.45 * r,
            -1.0 * r,
            -0.45 * r,
            0.2 * r,
            -0.12 * r,
            0.55 * r,
          ),
        _stroke(c, sw * 0.8),
      );
      cv.drawLine(p(-0.3, 0.55), p(-0.2, 0.88), _stroke(c, sw * 0.6));
      cv.drawLine(p(0.3, 0.55), p(0.2, 0.88), _stroke(c, sw * 0.6));
      _outline(
        cv,
        Path()..addRect(Rect.fromLTWH(-0.24 * r, 0.88 * r, 0.48 * r, 0.32 * r)),
        c,
        sw * 0.8,
      );
    case Sprite.sailboat:
      _outline(
        cv,
        poly([
          [-0.95, 0.35],
          [0.95, 0.35],
          [0.65, 0.75],
          [-0.65, 0.75],
        ]),
        c,
        sw,
      );
      cv.drawLine(p(0, 0.35), p(0, -1.1), line);
      _outline(
        cv,
        poly([
          [0.1, -1.0],
          [0.1, 0.22],
          [0.85, 0.22],
        ]),
        c,
        sw,
      );
      _outline(
        cv,
        poly([
          [-0.1, -0.75],
          [-0.1, 0.22],
          [-0.62, 0.22],
        ]),
        c,
        sw,
      );
    case Sprite.diya:
      _outline(
        cv,
        Path()
          ..moveTo(-0.95 * r, 0.15 * r)
          ..quadraticBezierTo(0, 1.15 * r, 0.95 * r, 0.15 * r)
          ..close(),
        c,
        sw,
      );
      _outline(
        cv,
        Path()
          ..moveTo(0, -0.95 * r)
          ..cubicTo(0.38 * r, -0.45 * r, 0.3 * r, 0.05 * r, 0, 0.05 * r)
          ..cubicTo(-0.3 * r, 0.05 * r, -0.38 * r, -0.45 * r, 0, -0.95 * r)
          ..close(),
        c,
        sw,
      );
    case Sprite.rings:
      cv.drawCircle(p(-0.3, 0.2), 0.55 * r, line);
      cv.drawCircle(p(0.3, 0.2), 0.55 * r, line);
      _outline(
        cv,
        poly([
          [0.3, -0.62],
          [0.48, -0.44],
          [0.3, -0.26],
          [0.12, -0.44],
        ]),
        c,
        sw * 0.8,
      );
    case Sprite.fish:
      _outline(
        cv,
        Path()
          ..moveTo(0.95 * r, 0)
          ..quadraticBezierTo(0.2 * r, -0.62 * r, -0.5 * r, 0)
          ..quadraticBezierTo(0.2 * r, 0.62 * r, 0.95 * r, 0)
          ..close(),
        c,
        sw,
      );
      _outline(
        cv,
        poly([
          [-0.45, 0],
          [-0.95, -0.42],
          [-0.82, 0],
          [-0.95, 0.42],
        ]),
        c,
        sw,
      );
      cv.drawCircle(p(0.5, -0.08), 0.08 * r + sw * 0.2, _fill(c));
  }
}

Path _heart(double r) => Path()
  ..moveTo(0, 0.85 * r)
  ..cubicTo(-0.2 * r, 0.65 * r, -1.05 * r, 0.15 * r, -0.95 * r, -0.35 * r)
  ..cubicTo(-0.85 * r, -0.95 * r, -0.15 * r, -0.95 * r, 0, -0.45 * r)
  ..cubicTo(0.15 * r, -0.95 * r, 0.85 * r, -0.95 * r, 0.95 * r, -0.35 * r)
  ..cubicTo(1.05 * r, 0.15 * r, 0.2 * r, 0.65 * r, 0, 0.85 * r)
  ..close();
