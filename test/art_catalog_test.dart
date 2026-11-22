import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:countdowns/data/database.dart';
import 'package:countdowns/models/art_catalog.dart';
import 'package:countdowns/models/background_catalog.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/models/palette.dart';
import 'package:countdowns/widgets/art_painter.dart';
import 'package:countdowns/widgets_bridge/widget_snapshot.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('ids are unique, names are unique within a kind', () {
    final ids = artLibrary.map((a) => a.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final kind in ArtKind.values) {
      final names = [
        for (final c in artCollectionsFor(kind))
          for (final a in c.items) a.name,
      ];
      expect(names.toSet().length, names.length, reason: '$kind names');
    }
  });

  test('every kind is filled out in named families', () {
    for (final kind in ArtKind.values) {
      final collections = artCollectionsFor(kind);
      expect(collections.length, greaterThanOrEqualTo(5), reason: '$kind');
      final count = collections.fold(0, (n, c) => n + c.items.length);
      expect(count, greaterThanOrEqualTo(30), reason: '$kind');
      for (final c in collections) {
        expect(c.items, isNotEmpty);
        expect(c.items.every((a) => a.kind == kind), isTrue, reason: c.id);
      }
    }
  });

  test('text reads at WCAG AA on the ground and every colour drawn', () {
    final failures = <String>[];
    for (final art in artLibrary) {
      for (final p in art.paints) {
        final ratio = contrast(art.textColor, p);
        if (ratio < 4.5) {
          failures.add(
            '${art.id}: ${p.toARGB32().toRadixString(16)} '
            '${ratio.toStringAsFixed(2)}',
          );
        }
      }
    }
    expect(failures, isEmpty);
  });

  test('every piece paints at card, widget, swatch and screen sizes', () {
    for (final art in artLibrary) {
      for (final (size, scale) in [
        (const Size(170, 165), 1.0),
        (const Size(360, 168), 1.0),
        (const Size(390, 844), 1.0),
        (const Size(1194, 834), 1.0),
        (const Size(50, 50), 0.6),
      ]) {
        final rec = ui.PictureRecorder();
        paintArt(ui.Canvas(rec), size, art, scale: scale);
        rec.endRecording().dispose();
      }
    }
  });

  group('keys', () {
    final base = Countdown(
      id: 1,
      title: 'Trip',
      dateTime: DateTime(2027, 3, 14),
      gradientId: 'sunset',
      gradientDirection: GradientDirection.radial,
    );

    test('every art piece round trips through apply and key', () {
      for (final art in artLibrary) {
        final d = applyBackground(base, artKey(art));
        expect(d.artId, art.id);
        expect(d.art, same(art));
        expect(d.gradientId, isNull);
        expect(d.color, art.ground);
        expect(d.textColor, art.textColor);
        expect(backgroundKeyOf(d), artKey(art));
        expect(parseBackgroundKey(artKey(art))!.kind.art, art.kind);
      }
    });

    test('a colour or gradient clears the art', () {
      final d = applyBackground(base, 'pattern:polka-navy');
      expect(applyBackground(d, 'colour:FFFE7228').artId, isNull);
      expect(applyBackground(d, 'gradient:lagoon').artId, isNull);
    });

    test('a photo shows over art and keeps it underneath', () {
      final d = applyBackground(base, 'illustration:birthday');
      final withPhoto = applyBackground(d, 'photo:photos/a.jpg');
      expect(withPhoto.art, isNull);
      expect(withPhoto.textColor, Colors.white);
      expect(backgroundKeyOf(withPhoto), 'photo:photos/a.jpg');
      expect(withPhoto.copyWith(photoPath: null).art?.id, 'birthday');
    });

    test('unknown ids and mismatched kinds change nothing', () {
      expect(applyBackground(base, 'pattern:nope'), base);
      expect(applyBackground(base, 'texture:polka-navy'), base);
      // A saved id that no longer resolves falls back to the colour.
      final orphan = base.copyWith(gradientId: null, artId: 'gone');
      expect(orphan.art, isNull);
      expect(backgroundKeyOf(orphan), colourKey(orphan.color));
    });

    test('stale art recents are skipped on the Look row', () {
      final keys = lookRowKeys(
        draft: base,
        recentBackgrounds: ['pattern:gone', 'texture:linen-oat'],
      );
      expect(keys, contains('texture:linen-oat'));
      expect(keys, isNot(contains('pattern:gone')));
    });
  });

  test('widgets get art as images, without the photo scrim', () {
    final now = DateTime(2026, 11, 22);
    final e = applyBackground(
      Countdown(id: 7, title: 'Party', dateTime: DateTime(2027, 1, 1)),
      'illustration:party',
    );
    final m = (buildWidgetSnapshot([e], now)['events']! as List).single as Map;
    final art = artById('party')!;
    expect(m['photo'], artFileName(art, 'photo'));
    expect(m['photoWide'], artFileName(art, 'photoWide'));
    expect(m['photoFull'], artFileName(art, 'photoFull'));
    expect(m['scrim'], isFalse);
    expect(m['colors'], hasLength(1));
    expect(
      m['text'],
      '#${(art.textColor.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
    );
    for (final key in ['photo', 'photoWide', 'photoFull']) {
      expect(artShapes, contains(key));
    }

    final plain = Countdown(
      id: 8,
      title: 'Plain',
      dateTime: DateTime(2027, 1, 1),
    );
    final p =
        (buildWidgetSnapshot([plain], now)['events']! as List).single as Map;
    expect(p['photo'], isNull);
    expect(p['scrim'], isTrue);
  });

  group('database', () {
    test('saves and reads the art id', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final id = await db.saveCountdown(
        applyBackground(
          Countdown(title: 'Snow', dateTime: DateTime(2027, 1, 1)),
          'illustration:first-snow',
        ),
      );
      final back = (await db.allCountdowns()).single;
      expect(back.id, id);
      expect(back.artId, 'first-snow');
    });

    test('a schema 1 database upgrades with nothing changed', () async {
      final dir = await Directory.systemTemp.createTemp('art-migration');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/countdowns.sqlite');

      // Make a schema 2 file, then turn it back into schema 1.
      final v2 = AppDatabase(NativeDatabase(file));
      await v2.saveCountdown(
        Countdown(
          title: 'Old',
          dateTime: DateTime(2027, 5, 1),
          colorArgb: 0xFF66B6FE,
          gradientId: 'lagoon',
          reminders: const [0, 1440],
        ),
      );
      await v2.customStatement('ALTER TABLE events DROP COLUMN art_id');
      await v2.customStatement('PRAGMA user_version = 1');
      await v2.close();

      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);
      final old = (await db.allCountdowns()).single;
      expect(old.title, 'Old');
      expect(old.gradientId, 'lagoon');
      expect(old.colorArgb, 0xFF66B6FE);
      expect(old.reminders, [0, 1440]);
      expect(old.artId, isNull);
      // And the new column works.
      await db.saveCountdown(old.copyWith(artId: 'linen-oat'));
      expect((await db.allCountdowns()).single.artId, 'linen-oat');
    });
  });
}
