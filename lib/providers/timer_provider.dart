import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
