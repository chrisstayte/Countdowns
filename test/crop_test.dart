import 'dart:io';
import 'dart:ui' as ui;

import 'package:countdowns/data/database.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/screens/editor/crop_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<File> _testImage(Directory dir) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 600, 400),
    Paint()..color = const Color(0xFF66B6FE),
  );
  final image = await recorder.endRecording().toImage(600, 400);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('${dir.path}/photo.png');
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  return file;
}

void main() {
  group('crop maths', () {
    const image = Size(600, 400);

    test('zoom 1 is BoxFit.cover at the alignment', () {
      // A square crop of a landscape photo is 400×400, slid by x.
      expect(
        cropRectIn(image, 1, const CropPoint(-1, 0)),
        const Rect.fromLTWH(0, 0, 400, 400),
      );
      expect(
        cropRectIn(image, 1, const CropPoint(1, 0)),
        const Rect.fromLTWH(200, 0, 400, 400),
      );
    });

    test('zoom shrinks the crop around the alignment', () {
      expect(
        cropRectIn(image, 1, const CropPoint(0, 0, 2)),
        const Rect.fromLTWH(200, 100, 200, 200),
      );
      expect(
        cropRectIn(image, 1, const CropPoint(1, 1, 2)),
        const Rect.fromLTWH(400, 200, 200, 200),
      );
    });

    test('zoom is clamped so the photo always covers the shape', () {
      expect(CropPoint.center.zoomed(0.2).zoom, minPhotoZoom);
      expect(CropPoint.center.zoomed(99).zoom, maxPhotoZoom);
      expect(const CropPoint(0.9, 0).moved(0.5, -3).x, 1);
      expect(const CropPoint(0.9, 0).moved(0.5, -3).y, -1);
    });
  });

  group('PhotoCrops', () {
    final crops = PhotoCrops(
      points: {
        CropShape.full: const CropPoint(-0.5, 0.2, 1.5),
        CropShape.card: const CropPoint(0.7, -0.1, 2.25),
        CropShape.wide: const CropPoint(0, 1),
      },
    );

    test('each shape keeps its own point and zoom', () {
      expect(crops.pointFor(CropShape.card), const CropPoint(0.7, -0.1, 2.25));
      expect(crops.pointFor(CropShape.wide), const CropPoint(0, 1));
      // A shape without its own crop falls back to the full-screen one.
      expect(crops.pointFor(CropShape.tablet), const CropPoint(-0.5, 0.2, 1.5));
    });

    test('older saves with the "same" flag keep what was stored', () {
      // The flag is ignored; stored shapes keep their own values and
      // shapes with nothing stored use the full-screen crop, as before.
      final old = PhotoCrops.fromJson(
        '{"same":true,"full":[0.3,-0.4,2.0],"card":[0.9,0.1,1.5]}',
      )!;
      expect(old.pointFor(CropShape.full), const CropPoint(0.3, -0.4, 2));
      expect(old.pointFor(CropShape.card), const CropPoint(0.9, 0.1, 1.5));
      expect(old.pointFor(CropShape.wide), const CropPoint(0.3, -0.4, 2));
      expect(old.toJson(), isNot(contains('same')));
    });

    test('JSON keeps zoom, and older [x, y] crops read as zoom 1', () {
      expect(PhotoCrops.fromJson(crops.toJson()), crops);
      final old = PhotoCrops.fromJson('{"full":[0.3,-0.4]}')!;
      expect(old.pointFor(CropShape.card), const CropPoint(0.3, -0.4));
      expect(PhotoCrops.fromJson('not json'), isNull);
    });

    test('crops survive saving and reopening', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final id = await db.saveCountdown(
        Countdown(
          title: 'Trip',
          dateTime: DateTime(2027, 3, 14),
          photoPath: 'photos/1.jpg',
          photoCrops: crops,
          photoDarken: 0.55,
        ),
      );
      var saved = (await db.allCountdowns()).single;
      expect(saved.photoCrops, crops);
      // Edit one shape and save again: the others are untouched.
      final edited = PhotoCrops(
        points: {...crops.points, CropShape.card: const CropPoint(0, 0, 3)},
      );
      await db.saveCountdown(saved.copyWith(id: id, photoCrops: edited));
      saved = (await db.allCountdowns()).single;
      expect(
        saved.photoCrops!.pointFor(CropShape.card),
        const CropPoint(0, 0, 3),
      );
      expect(saved.photoCrops!.pointFor(CropShape.wide), const CropPoint(0, 1));
      expect(saved.photoDarken, 0.55);
    });
  });

  group('crop screen', () {
    late Directory dir;
    late File photo;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('crop');
      photo = await _testImage(dir);
    });
    tearDown(() => dir.delete(recursive: true));

    Future<PhotoCrops?> open(
      WidgetTester tester,
      PhotoCrops initial,
      Future<void> Function() act,
    ) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      PhotoCrops? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await Navigator.push<PhotoCrops>(
                context,
                MaterialPageRoute(
                  builder: (_) => CropScreen(file: photo, initial: initial),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(CropScreen), findsOneWidget);
      // Let the photo decode so the canvas knows its size.
      for (
        var i = 0;
        i < 20 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await act();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      return result;
    }

    Offset canvasCenter(WidgetTester tester) =>
        tester.getCenter(find.byType(Image).first);

    testWidgets('there are no nudge arrows', (tester) async {
      await open(tester, const PhotoCrops(), () async {
        expect(find.bySemanticsLabel('Move up'), findsNothing);
        expect(find.byIcon(Icons.arrow_left_rounded), findsNothing);
      });
    });

    testWidgets('there is no Same spot for all switch', (tester) async {
      await open(tester, const PhotoCrops(), () async {
        expect(find.text('Same spot for all'), findsNothing);
        expect(find.bySemanticsLabel('Same spot for all'), findsNothing);
      });
    });

    testWidgets('dragging one shape moves only it', (tester) async {
      final result = await open(tester, const PhotoCrops(), () async {
        await tester.tap(find.text('Card').last);
        await tester.pump();
        await tester.dragFrom(canvasCenter(tester), const Offset(60, 0));
        await tester.pump();
      });
      expect(result!.pointFor(CropShape.card).x, greaterThan(0.2));
      expect(result.pointFor(CropShape.full), CropPoint.center);
      expect(result.pointFor(CropShape.wide), CropPoint.center);
    });

    testWidgets('pinching zooms only that shape', (tester) async {
      final result = await open(tester, const PhotoCrops(), () async {
        await tester.tap(find.text('Wide').last);
        await tester.pump();
        final c = canvasCenter(tester);
        final a = await tester.startGesture(c - const Offset(20, 0));
        final b = await tester.startGesture(c + const Offset(20, 0));
        await tester.pump();
        for (var i = 1; i <= 5; i++) {
          await a.moveTo(c - Offset(20.0 + i * 8, 0));
          await b.moveTo(c + Offset(20.0 + i * 8, 0));
          await tester.pump();
        }
        await a.up();
        await b.up();
        await tester.pump();
      });
      expect(result!.pointFor(CropShape.wide).zoom, greaterThan(1.5));
      expect(
        result.pointFor(CropShape.wide).zoom,
        lessThanOrEqualTo(maxPhotoZoom),
      );
      expect(result.pointFor(CropShape.full).zoom, 1);
      expect(result.pointFor(CropShape.card).zoom, 1);
    });

    testWidgets('in All shapes, dragging moves only the frame touched', (
      tester,
    ) async {
      final initial = PhotoCrops(
        points: {
          CropShape.full: const CropPoint(-1, 0),
          CropShape.card: const CropPoint(1, 0, 2),
          CropShape.wide: const CropPoint(0, 1),
          CropShape.tablet: const CropPoint(0, 0),
        },
      );
      final result = await open(tester, initial, () async {
        // In the 600×400 photo the zoomed card is x 400–600, y 100–300
        // and the wide frame starts at y 120, so (500, 110) is card only.
        final image = tester.getRect(find.byType(Image).first);
        final start =
            image.topLeft +
            Offset(image.width * 500 / 600, image.height * 110 / 400);
        await tester.dragFrom(start, const Offset(-60, 0));
        await tester.pump();
      });
      expect(result!.pointFor(CropShape.card).x, lessThan(1));
      expect(result.pointFor(CropShape.card).zoom, 2);
      expect(result.pointFor(CropShape.full), const CropPoint(-1, 0));
      expect(result.pointFor(CropShape.wide), const CropPoint(0, 1));
    });

    testWidgets('existing crops come back as they were saved', (tester) async {
      final initial = PhotoCrops(
        points: {
          CropShape.full: const CropPoint(-0.5, 0, 1.2),
          CropShape.card: const CropPoint(0.4, 0.1, 2),
          CropShape.wide: const CropPoint(0, -0.3, 1.5),
          CropShape.tablet: const CropPoint(0.1, 0.2),
        },
      );
      final result = await open(tester, initial, () async {});
      expect(result, initial);
    });
  });
}
