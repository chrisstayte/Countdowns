import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/models/palette.dart';
import 'package:countdowns/widgets_bridge/widget_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
