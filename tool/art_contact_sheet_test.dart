// Renders every pattern, texture and illustration as a card with sample
// text, one PNG per kind, for review:
//
//   flutter test tool/art_contact_sheet_test.dart
//
// Writes build/art_contact_sheet/<kind>.png (and wide.png: a few wide
// widget and full-screen shapes).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:countdowns/models/art_catalog.dart';
import 'package:countdowns/widgets/art_painter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _font(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(File(f).readAsBytes().then((b) => ByteData.view(b.buffer)));
  }
  await loader.load();
}

ui.Paragraph _text(
  String s,
  double size,
  ui.Color color, {
  String family = 'Inter',
  ui.FontWeight weight = ui.FontWeight.w700,
  double width = 1000,
}) {
  final b =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(fontFamily: family, fontSize: size, maxLines: 1),
        )
        ..pushStyle(ui.TextStyle(color: color, fontWeight: weight))
        ..addText(s);
  return b.build()..layout(ui.ParagraphConstraints(width: width));
}

void _card(ui.Canvas c, ui.Rect r, Art art, {String? caption}) {
  final rr = ui.RRect.fromRectAndRadius(r, const ui.Radius.circular(22));
  c.save();
  c.clipRRect(rr);
  c.translate(r.left, r.top);
  paintArt(c, r.size, art);
  final ink = art.textColor;
  c.drawParagraph(_text('Summer trip', 17, ink), const ui.Offset(14, 12));
  c.drawParagraph(
    _text('42', 44, ink, family: 'Bricolage'),
    ui.Offset(14, r.height - 74),
  );
  c.drawParagraph(_text('days', 15, ink), ui.Offset(70, r.height - 46));
  c.drawParagraph(
    _text('Fri, Jul 3', 12, ink.withValues(alpha: 0.85)),
    ui.Offset(14, r.height - 24),
  );
  c.restore();
  if (caption != null) {
    c.drawParagraph(
      _text(
        caption,
        13,
        const ui.Color(0xFF2E2A3A),
        weight: ui.FontWeight.w600,
      ),
      ui.Offset(r.left + 2, r.bottom + 6),
    );
  }
}

Future<void> _save(ui.Picture p, int w, int h, String name) async {
  final img = await p.toImage(w, h);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  final f = File('build/art_contact_sheet/$name.png');
  await f.create(recursive: true);
  await f.writeAsBytes(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('art contact sheet', (tester) async {
    await tester.runAsync(() async {
      await _font('Inter', ['fonts/Inter-600.ttf', 'fonts/Inter-700.ttf']);
      await _font('Bricolage', ['fonts/BricolageGrotesque-700.ttf']);
      const cell = 170.0, gap = 18.0, cols = 8, captionH = 26.0, headH = 40.0;
      for (final kind in ArtKind.values) {
        final collections = artCollectionsFor(kind);
        var rows = 0;
        for (final c in collections) {
          rows += (c.items.length / cols).ceil();
        }
        final width = (cols * (cell + gap) + gap).toInt();
        final height =
            (collections.length * headH +
                    rows * (cell + captionH + gap) +
                    gap * 2)
                .toInt();
        final rec = ui.PictureRecorder();
        final canvas = ui.Canvas(rec);
        canvas.drawRect(
          ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
          ui.Paint()..color = const ui.Color(0xFFFBF9F3),
        );
        var y = gap;
        for (final c in collections) {
          canvas.drawParagraph(
            _text(c.name.toUpperCase(), 16, const ui.Color(0xFF6B6677)),
            ui.Offset(gap, y + 10),
          );
          y += headH;
          for (var i = 0; i < c.items.length; i++) {
            final col = i % cols;
            if (i > 0 && col == 0) y += cell + captionH + gap;
            _card(
              canvas,
              ui.Rect.fromLTWH(gap + col * (cell + gap), y, cell, cell),
              c.items[i],
              caption: c.items[i].name,
            );
          }
          y += cell + captionH + gap;
        }
        await _save(rec.endRecording(), width, height, kind.name);
      }

      // Swatches as the sheet shows them (50pt tiles), at 3x.
      {
        const tile = 50.0, pad = 8.0, per = 12;
        final rows = (artLibrary.length / per).ceil();
        final rec = ui.PictureRecorder();
        final canvas = ui.Canvas(rec)..scale(3);
        canvas.drawRect(
          ui.Rect.fromLTWH(
            0,
            0,
            per * (tile + pad) + pad,
            rows * (tile + pad) + pad,
          ),
          ui.Paint()..color = const ui.Color(0xFFFFFFFF),
        );
        for (var i = 0; i < artLibrary.length; i++) {
          final r = ui.Rect.fromLTWH(
            pad + (i % per) * (tile + pad),
            pad + (i ~/ per) * (tile + pad),
            tile,
            tile,
          );
          canvas.save();
          canvas.clipRRect(
            ui.RRect.fromRectAndRadius(r, const ui.Radius.circular(17)),
          );
          canvas.translate(r.left, r.top);
          paintArt(canvas, r.size, artLibrary[i], scale: 0.55);
          canvas.restore();
        }
        await _save(
          rec.endRecording(),
          ((per * (tile + pad) + pad) * 3).toInt(),
          ((rows * (tile + pad) + pad) * 3).toInt(),
          'swatches',
        );
      }

      // Other shapes: wide widget and full screen, for a few pieces.
      final picks = [
        'birthday',
        'mountains',
        'city-lights',
        'beach-day',
        'christmas',
        'gingham-sky',
        'terrazzo',
        'wash-rose',
      ];
      final rec = ui.PictureRecorder();
      final canvas = ui.Canvas(rec);
      const fw = 195.0, fh = 422.0, ww = 360.0, wh = 168.0;
      final width =
          (picks.length / 2).ceil() * (fw + gap) + gap + 2 * (ww + gap);
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, width, fh * 2 + gap * 3),
        ui.Paint()..color = const ui.Color(0xFFFBF9F3),
      );
      for (var i = 0; i < picks.length; i++) {
        final art = artById(picks[i])!;
        final full = ui.Rect.fromLTWH(
          gap + (i ~/ 2) * (fw + gap),
          gap + (i % 2) * (fh + gap),
          fw,
          fh,
        );
        _card(canvas, full, art);
        final wide = ui.Rect.fromLTWH(
          gap + (picks.length / 2).ceil() * (fw + gap) + (i % 2) * (ww + gap),
          gap + (i ~/ 2) * (wh + gap),
          ww,
          wh,
        );
        _card(canvas, wide, art);
      }
      await _save(
        rec.endRecording(),
        width.toInt(),
        (fh * 2 + gap * 3).toInt(),
        'shapes',
      );
    });
  });
}
