import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/timer_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HomeFilter { upcoming, done, all }

typedef HomeLists = ({List<Countdown> upcoming, List<Countdown> done});

/// Upcoming soonest first; done most recent first.
HomeLists splitEvents(List<Countdown> events, DateTime now) {
  final upcoming = events.where((e) => !e.isDone(now)).toList()
    ..sort((a, b) => a.nextOccurrence(now).compareTo(b.nextOccurrence(now)));
  final done = events.where((e) => e.isDone(now)).toList()
    ..sort((a, b) => b.target.compareTo(a.target));
  return (upcoming: upcoming, done: done);
}

final homeListsProvider = Provider.autoDispose<HomeLists>(
  (ref) =>
      splitEvents(ref.watch(eventsProvider), ref.watch(minuteClockProvider)),
);

final homeFilterProvider = NotifierProvider<HomeFilterController, HomeFilter>(
  HomeFilterController.new,
);

class HomeFilterController extends Notifier<HomeFilter> {
  @override
  HomeFilter build() => HomeFilter.upcoming;
  void set(HomeFilter value) => state = value;
}
