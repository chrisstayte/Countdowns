import 'dart:math' as math;

import 'package:countdowns/models/background_catalog.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/models/palette.dart';
import 'package:countdowns/widgets_bridge/widget_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

// CIE Lab and CIEDE2000, for "no near-duplicates".
List<double> lab(Color c) {
  double lin(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  final r = lin(c.r), g = lin(c.g), b = lin(c.b);
  final x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047;
  final y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  final z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883;
  double f(double t) =>
      t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
  return [116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))];
}

double deltaE2000(Color c1, Color c2) {
  double rad(double d) => d * math.pi / 180;
  double deg(double r) => r * 180 / math.pi;
  final [l1, a1, b1] = lab(c1);
  final [l2, a2, b2] = lab(c2);
  final cb = (math.sqrt(a1 * a1 + b1 * b1) + math.sqrt(a2 * a2 + b2 * b2)) / 2;
  final g =
      0.5 *
      (1 - math.sqrt(math.pow(cb, 7) / (math.pow(cb, 7) + math.pow(25, 7))));
  final a1p = (1 + g) * a1, a2p = (1 + g) * a2;
  final c1p = math.sqrt(a1p * a1p + b1 * b1),
      c2p = math.sqrt(a2p * a2p + b2 * b2);
  final h1p = (deg(math.atan2(b1, a1p)) + 360) % 360;
  final h2p = (deg(math.atan2(b2, a2p)) + 360) % 360;
  final dl = l2 - l1, dc = c2p - c1p;
  var dh = h2p - h1p;
  if (c1p * c2p == 0) {
    dh = 0;
  } else if (dh > 180) {
    dh -= 360;
  } else if (dh < -180) {
    dh += 360;
  }
  final dH = 2 * math.sqrt(c1p * c2p) * math.sin(rad(dh / 2));
  final lbp = (l1 + l2) / 2, cbp = (c1p + c2p) / 2;
  double hbp;
  if (c1p * c2p == 0) {
    hbp = h1p + h2p;
  } else if ((h1p - h2p).abs() <= 180) {
    hbp = (h1p + h2p) / 2;
  } else {
    hbp = h1p + h2p < 360 ? (h1p + h2p + 360) / 2 : (h1p + h2p - 360) / 2;
  }
  final t =
      1 -
      0.17 * math.cos(rad(hbp - 30)) +
      0.24 * math.cos(rad(2 * hbp)) +
      0.32 * math.cos(rad(3 * hbp + 6)) -
      0.20 * math.cos(rad(4 * hbp - 63));
  final dth = 30 * math.exp(-math.pow((hbp - 275) / 25, 2));
  final rc =
      2 * math.sqrt(math.pow(cbp, 7) / (math.pow(cbp, 7) + math.pow(25, 7)));
  final sl =
      1 + 0.015 * math.pow(lbp - 50, 2) / math.sqrt(20 + math.pow(lbp - 50, 2));
  final sc = 1 + 0.045 * cbp, sh = 1 + 0.015 * cbp * t;
  final rt = -math.sin(rad(2 * dth)) * rc;
  return math.sqrt(
    math.pow(dl / sl, 2) +
        math.pow(dc / sc, 2) +
        math.pow(dH / sh, 2) +
        rt * (dc / sc) * (dH / sh),
  );
}

/// The smallest CIEDE2000 gap allowed between two catalogue colours. 8
/// held for the first 43; at 100 the pastels and neutrals need 5.
const minDistance = 5.0;

void main() {
  group('catalogue', () {
    test('every original colour and gradient id still resolves exactly', () {
      final values = {for (final c in palette) c.color.toARGB32()};
      for (final MapEntry(:key, :value) in originalColours.entries) {
        expect(values, contains(value), reason: key);
        expect(colourName(Color(value)), key);
      }
      for (final MapEntry(:key, :value) in originalGradients.entries) {
        expect(
          gradientById(key)?.colors.map((c) => c.toARGB32()).toList(),
          value,
          reason: key,
        );
      }
    });

    test('ids, values and names are unique', () {
      final ids = gradientLibrary.map((g) => g.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids, isNot(contains(legacyGradientId)));
      final values = palette.map((c) => c.color.toARGB32()).toList();
      expect(values.toSet().length, values.length);
      // Names are unique across colours and gradients too, so the name
      // under a selected swatch is never ambiguous.
      final names = [
        ...palette.map((c) => c.name),
        ...gradientLibrary.map((g) => g.name),
      ];
      expect(names.toSet().length, names.length);
      final collections = [
        ...colourCollections.map((c) => c.id),
        ...gradientCollections.map((c) => c.id),
      ];
      expect(collections.toSet().length, collections.length);
    });

    test('about 100 colours and 100 gradients in named families', () {
      expect(colourCollections.map((c) => c.name), [
        'Warm',
        'Cool',
        'Pastel',
        'Bold',
        'Earthy',
        'Neutral',
        'Jewel',
        'Muted',
        'Seasonal',
      ]);
      expect(gradientCollections.map((c) => c.name), [
        'Sunset',
        'Ocean',
        'Candy',
        'Garden',
        'Night',
        'Aurora',
        'Citrus',
        'Berry',
        'Holiday',
        'Soft blends',
        'Earthy',
      ]);
      expect(palette.length, 100);
      expect(gradientLibrary.length, 100);
      expect(
        gradientLibrary.where((g) => g.colors.length == 3).length,
        greaterThanOrEqualTo(15),
      );
      for (final c in [...colourCollections.map((c) => c.colours.length)]) {
        expect(c, inInclusiveRange(4, 20));
      }
    });

    test('every colour reads at WCAG AA with its automatic text colour', () {
      for (final c in palette) {
        final text = autoTextColor(c.color);
        expect(
          contrast(text, c.color),
          greaterThanOrEqualTo(4.5),
          reason: c.name,
        );
      }
    });

    test('every gradient reads at AA across all of its stops', () {
      for (final g in gradientLibrary) {
        final text = autoTextColorFor(g.colors);
        for (final stop in g.colors) {
          expect(
            contrast(text, stop),
            greaterThanOrEqualTo(4.5),
            reason: '${g.name} at ${stop.toARGB32().toRadixString(16)}',
          );
        }
      }
    });

    test('no new colour is a near-duplicate of another (ΔE2000 ≥ 5)', () {
      final originals = originalColours.values.toSet();
      for (var i = 0; i < palette.length; i++) {
        for (var j = i + 1; j < palette.length; j++) {
          final a = palette[i], b = palette[j];
          // The 12 originals are kept as they were.
          if (originals.contains(a.color.toARGB32()) &&
              originals.contains(b.color.toARGB32())) {
            continue;
          }
          expect(
            deltaE2000(a.color, b.color),
            greaterThanOrEqualTo(minDistance),
            reason: '${a.name} vs ${b.name}',
          );
        }
      }
    });

    test('featured picks all resolve', () {
      for (final k in featuredBackgrounds) {
        final ref = parseBackgroundKey(k)!;
        if (ref.kind == BackgroundKind.gradient) {
          expect(gradientById(ref.value), isNotNull, reason: k);
        } else {
          expect(
            isPaletteColor(colourFromKey(ref.value).toARGB32()),
            isTrue,
            reason: k,
          );
        }
      }
    });

    test('the widget snapshot carries every colour and gradient', () {
      // Widgets draw from the stops in the snapshot, so any id renders.
      String hex(Color c) =>
          '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
      final now = DateTime(2026, 11, 22);
      var id = 1;
      final events = [
        for (final g in gradientLibrary)
          applyBackground(
            Countdown(id: id++, title: g.name, dateTime: DateTime(2027, 1, 1)),
            gradientKey(g.id),
          ),
        for (final c in palette)
          applyBackground(
            Countdown(id: id++, title: c.name, dateTime: DateTime(2027, 1, 1)),
            colourKey(c.color),
          ),
      ];
      final byTitle = <String, Map>{};
      for (var i = 0; i < events.length; i += widgetEventLimit) {
        final chunk = events.skip(i).take(widgetEventLimit).toList();
        for (final e in buildWidgetSnapshot(chunk, now)['events']! as List) {
          byTitle[(e as Map)['title'] as String] = e;
        }
      }
      for (final g in gradientLibrary) {
        expect(byTitle[g.name]!['colors'], g.colors.map(hex).toList());
        expect(byTitle[g.name]!['text'], hex(autoTextColorFor(g.colors)));
      }
      for (final c in palette) {
        expect(byTitle[c.name]!['colors'], [hex(c.color)]);
      }
    });
  });

  group('keys', () {
    final base = Countdown(
      id: 1,
      title: 'Trip',
      dateTime: DateTime(2027, 3, 14),
      colorArgb: 0xFF7877E6,
    );

    test('round trip through apply and key', () {
      for (final k in [
        for (final c in palette) colourKey(c.color),
        for (final g in gradientLibrary) gradientKey(g.id),
        photoKey('p/1.jpg'),
      ]) {
        expect(backgroundKeyOf(applyBackground(base, k)), k);
      }
    });

    test('a colour clears gradient and photo; a gradient keeps direction', () {
      final g = applyBackground(
        base.copyWith(gradientDirection: GradientDirection.up),
        gradientKey('nebula'),
      );
      expect(g.gradientId, 'nebula');
      expect(g.direction, GradientDirection.up);
      final withPhoto = applyBackground(g, photoKey('a.jpg'));
      expect(withPhoto.hasPhoto, isTrue);
      final c = applyBackground(withPhoto, colourKey(const Color(0xFFFFE89E)));
      expect(c.hasPhoto, isFalse);
      expect(c.gradientId, isNull);
      expect(c.colorArgb, 0xFFFFE89E);
    });

    test('the same photo keeps its crops, a new one starts afresh', () {
      const crops = PhotoCrops(
        points: {CropShape.card: CropPoint(0.3, -0.2, 2)},
      );
      final d = base.copyWith(photoPath: 'a.jpg', photoCrops: crops);
      expect(applyBackground(d, photoKey('a.jpg')).photoCrops, crops);
      expect(applyBackground(d, photoKey('b.jpg')).photoCrops, isNot(crops));
    });

    test('unknown keys and ids leave the countdown alone', () {
      for (final k in ['nonsense', 'gradient:nope', 'colour:zz', 'photo:']) {
        expect(applyBackground(base, k), same(base), reason: k);
      }
    });
  });

  group('Look tab row', () {
    final draft = Countdown(
      id: 1,
      title: 'Trip',
      dateTime: DateTime(2027, 3, 14),
      colorArgb: 0xFFA3A33A, // Olive: not in the featured picks
    );

    test('11 keys after Add photo: current, recents, then featured', () {
      final keys = lookRowKeys(
        draft: draft,
        recentBackgrounds: ['gradient:nebula', 'colour:FF2BB3A3'],
      );
      expect(keys, hasLength(11));
      expect(keys.first, 'colour:FFA3A33A');
      expect(keys.sublist(1, 3), ['gradient:nebula', 'colour:FF2BB3A3']);
      expect(keys.sublist(3), featuredBackgrounds.take(8).toList());
      expect(keys.toSet().length, keys.length);
    });

    test('photos lead, current first, then the background row', () {
      final keys = lookRowKeys(
        draft: draft.copyWith(photoPath: 'b.jpg'),
        recentPhotos: ['a.jpg', 'b.jpg', 'c.jpg', 'd.jpg'],
      );
      expect(keys.take(3), [
        photoKey('b.jpg'),
        photoKey('a.jpg'),
        photoKey('c.jpg'),
      ]);
      expect(keys, isNot(contains(photoKey('d.jpg'))));
    });

    test('a saved custom colour stays offered; stale recents are skipped', () {
      final keys = lookRowKeys(
        draft: draft.copyWith(colorArgb: 0xFF5FD3B5),
        originalColor: 0xFF7877E7, // off-catalogue
        recentBackgrounds: ['gradient:gone', 'photo:x.jpg', 'colour:FF5FD3B5'],
      );
      expect(keys.take(2), ['colour:FF5FD3B5', 'colour:FF7877E7']);
      expect(keys, isNot(contains('gradient:gone')));
      expect(keys, isNot(contains('photo:x.jpg')));
      expect(keys.where((k) => k == 'colour:FF5FD3B5'), hasLength(1));
    });
  });
}
