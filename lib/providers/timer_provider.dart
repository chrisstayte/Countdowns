import 'dart:async';

import 'package:flutter/material.dart';

// This provider is to ensure that all widgets that use the Timer.periodic
// Thus updating the UI at the same time

class TimerProvider extends ChangeNotifier {
  late Timer _timer;

  TimerProvider() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      notifyListeners();
    });
  }
}
