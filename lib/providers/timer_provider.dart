import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ticks every second, for screens that show seconds.
final clockProvider = NotifierProvider.autoDispose<CountdownClock, DateTime>(
  CountdownClock.new,
);

class CountdownClock extends Notifier<DateTime> {
  @override
  DateTime build() {
    final timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => state = DateTime.now(),
    );
    ref.onDispose(timer.cancel);
    return DateTime.now();
  }
}

/// Ticks on the minute, for lists and cards.
final minuteClockProvider =
    NotifierProvider.autoDispose<MinuteClock, DateTime>(MinuteClock.new);

class MinuteClock extends Notifier<DateTime> {
  @override
  DateTime build() {
    Timer? timer;
    void schedule() {
      final now = DateTime.now();
      timer = Timer(
        Duration(seconds: 60 - now.second, milliseconds: -now.millisecond),
        () {
          state = DateTime.now();
          schedule();
        },
      );
    }

    schedule();
    ref.onDispose(() => timer?.cancel());
    return DateTime.now();
  }
}
