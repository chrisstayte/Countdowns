import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/timer_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HomeFilter {
  upcoming('Soon'),
  since('Since'),
  done('Done'),
  all('All');

  const HomeFilter(this.label);
  final String label;
}

typedef HomeLists = ({
  List<Countdown> upcoming,
  List<Countdown> since,
  List<Countdown> done,
});

/// Upcoming soonest first; Since newest start first (smallest count first,
/// like Upcoming); done most recent first.
HomeLists splitEvents(List<Countdown> events, DateTime now) {
  final upcoming = events.where((e) => !e.isSince && !e.isDone(now)).toList()
    ..sort((a, b) => a.nextOccurrence(now).compareTo(b.nextOccurrence(now)));
  final since = events.where((e) => e.isSince).toList()
    ..sort((a, b) => b.target.compareTo(a.target));
  final done = events.where((e) => e.isDone(now)).toList()
    ..sort((a, b) => b.target.compareTo(a.target));
  return (upcoming: upcoming, since: since, done: done);
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
