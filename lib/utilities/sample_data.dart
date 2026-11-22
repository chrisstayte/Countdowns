import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/models/palette.dart';

/// Countdowns like the ones on the redesign canvas, for debug builds and
/// screenshots. Dates are relative to [now] so they always look current.
List<Countdown> sampleCountdowns(DateTime now) {
  DateTime inDays(int d, [int hour = 0, int minute = 0]) =>
      DateTime(now.year, now.month, now.day + d, hour, minute);
  return [
    Countdown(
      title: 'Thanksgiving',
      dateTime: inDays(5),
      iconSlug: 'dining',
      colorArgb: tangerine.toARGB32(),
      reminders: const [0, 1440],
    ),
    Countdown(
      title: 'Christmas',
      dateTime: inDays(34),
      iconSlug: 'gift',
      colorArgb: tomato.toARGB32(),
      fontFamily: 'Libre Baskerville',
      repeat: RepeatRule.yearly,
      reminders: const [0, 10080],
      createdAt: inDays(-51),
    ),
    Countdown(
      title: 'New Year’s Eve',
      dateTime: inDays(40, 20),
      allDay: false,
      iconSlug: 'party',
      colorArgb: sun.toARGB32(),
      gradientId: 'peachy',
      gradientDirection: GradientDirection.down,
    ),
    Countdown(
      title: 'Mia’s birthday',
      dateTime: inDays(74),
      iconSlug: 'cake',
      colorArgb: bubblegum.toARGB32(),
      fontFamily: 'Comic Neue',
      unit: CountUnit.sleeps,
      repeat: RepeatRule.yearly,
    ),
    Countdown(
      title: 'Japan trip',
      dateTime: inDays(113, 9, 30),
      allDay: false,
      iconSlug: 'plane',
      colorArgb: sky.toARGB32(),
      gradientId: 'lagoon',
    ),
    Countdown(
      title: 'Graduation',
      dateTime: inDays(800),
      iconSlug: 'graduation',
      colorArgb: cobalt.toARGB32(),
      unit: CountUnit.weeks,
    ),
    Countdown(
      title: 'Moved in',
      dateTime: inDays(-111),
      iconSlug: 'apartment',
      colorArgb: lime.toARGB32(),
    ),
  ];
}
