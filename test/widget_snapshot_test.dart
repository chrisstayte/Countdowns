import 'dart:convert';
import 'dart:io';

import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/models/palette.dart';
import 'package:countdowns/widgets_bridge/widget_snapshot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 11, 21, 12);

  test('snapshot lists upcoming countdowns soonest first, with their look', () {
    final snapshot = buildWidgetSnapshot([
      Countdown(id: 1, title: 'Past', dateTime: DateTime(2026, 8, 2)),
      Countdown(
        id: 2,
        title: 'Japan trip',
        dateTime: DateTime(2027, 3, 14, 9, 30),
        allDay: false,
        iconSlug: 'plane',
        colorArgb: sky.toARGB32(),
        gradientId: 'lagoon',
        gradientDirection: GradientDirection.up,
        unit: CountUnit.sleeps,
      ),
      Countdown(
        id: 3,
        title: 'Birthday',
        dateTime: DateTime(1990, 2, 3),
        repeat: RepeatRule.yearly,
        fontFamily: 'ComicNeue',
      ),
    ], now);
    final events = snapshot['events']! as List;
    expect(events.map((e) => (e as Map)['id']), [3, 2]);
    final birthday = events.first as Map;
    expect(
      birthday['target'],
      DateTime(2027, 2, 3).millisecondsSinceEpoch ~/ 1000,
    );
    expect(birthday['yearly'], true);
    expect(birthday['font'], 'ComicNeue');
    expect(birthday['icon'], isNull);
    final trip = events.last as Map;
    expect(trip['colors'], ['#66B6FE', '#5FD3B5']);
    expect(trip['direction'], 'up');
    expect(trip['unit'], 'sleeps');
    expect(trip['text'], '#1C1633');
    expect(trip['icon'], 'icons/plane-1C1633.png');
    expect(trip['photo'], isNull);
  });

  test('the snapshot carries only active countdowns, which picks the large '
      'layout: none is the empty state, one is the hero, more is the list', () {
    List snapshotOf(List<Countdown> events) =>
        buildWidgetSnapshot(events, now)['events']! as List;
    final done = Countdown(
      id: 1,
      title: 'Done',
      dateTime: DateTime(2026, 1, 1),
    );
    final trip = Countdown(
      id: 2,
      title: 'Trip',
      dateTime: DateTime(2027, 3, 14),
      photoPath: 'p.jpg',
    );
    final party = Countdown(
      id: 3,
      title: 'Party',
      dateTime: DateTime(2026, 12, 31),
    );
    expect(snapshotOf([done]), isEmpty);
    final single = snapshotOf([done, trip]);
    expect(single, hasLength(1));
    // The hero uses the full-screen crop.
    expect((single.single as Map)['photoFull'], startsWith('photos/2-full-'));
    expect(snapshotOf([done, trip, party]), hasLength(2));
  });

  test('snapshot is capped', () {
    final many = [
      for (var i = 0; i < 30; i++)
        Countdown(id: i, title: '$i', dateTime: DateTime(2027, 1, 1 + i)),
    ];
    expect(
      (buildWidgetSnapshot(many, now)['events']! as List).length,
      widgetEventLimit,
    );
  });

  test('snapshot matches the fixture the Android widget is tested on', () {
    // android/app/src/test/resources/snapshot.json is parsed by the Kotlin
    // tests (CounterTest.kt); the Swift reader decodes the same keys.
    final fixture = jsonDecode(
      File('android/app/src/test/resources/snapshot.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final built = buildWidgetSnapshot([
      Countdown(
        id: 1,
        title: 'Trip',
        dateTime: DateTime(2027, 3, 14),
        iconSlug: 'plane',
      ),
    ], now);
    expect(built['version'], fixture['version']);
    expect(built.keys.toSet(), fixture.keys.toSet());
    final fixtureKeys = {
      for (final e in fixture['events']! as List) ...(e as Map).keys,
    };
    expect(
      (((built['events']! as List).single) as Map).keys.toSet(),
      fixtureKeys,
    );
  });

  group('one writer for both platforms', () {
    const channel = MethodChannel('countdowns/widgets');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    late Directory root;
    late List<String> calls;

    setUp(() {
      root = Directory.systemTemp.createTempSync('widgets');
      calls = [];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return call.method == 'containerPath' ? root.path : null;
      });
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = null;
      root.deleteSync(recursive: true);
    });

    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      test(
        'writes snapshot.json and asks ${platform.name} to redraw',
        () async {
          debugDefaultTargetPlatformOverride = platform;
          await WidgetSnapshotWriter(clock: () => now).write([
            Countdown(id: 4, title: 'Party', dateTime: DateTime(2026, 12, 31)),
            Countdown(id: 5, title: 'Old', dateTime: DateTime(2026, 1, 1)),
          ]);
          expect(calls, ['containerPath', 'reload']);
          final file = File('${root.path}/widget/snapshot.json');
          final json = jsonDecode(file.readAsStringSync()) as Map;
          expect(json['version'], 1);
          expect((json['events'] as List).map((e) => (e as Map)['title']), [
            'Party',
          ]);
          // Written whole, never left half-done.
          expect(File('${file.path}.tmp').existsSync(), isFalse);
          expect(Directory('${root.path}/widget/icons').existsSync(), isTrue);
          expect(Directory('${root.path}/widget/photos').existsSync(), isTrue);
        },
      );
    }

    test('stale icon and photo copies are pruned', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final stale = File('${root.path}/widget/photos/9-card-old.png')
        ..createSync(recursive: true);
      await WidgetSnapshotWriter(clock: () => now).write([
        Countdown(id: 4, title: 'Party', dateTime: DateTime(2026, 12, 31)),
      ]);
      expect(stale.existsSync(), isFalse);
    });

    test('does nothing on platforms without widgets', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(WidgetSnapshotWriter.supported, isFalse);
      await WidgetSnapshotWriter(clock: () => now).write([
        Countdown(id: 4, title: 'Party', dateTime: DateTime(2026, 12, 31)),
      ]);
      expect(calls, isEmpty);
    });
  });
}
