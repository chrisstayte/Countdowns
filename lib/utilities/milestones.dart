import 'package:countdowns/models/countdown.dart';
import 'package:intl/intl.dart';

/// A moment worth marking in a Since event: "100 days", "1 year".
typedef Milestone = ({DateTime at, String label});

/// Day counts worth marking, then every 1,000 days after these.
const _dayMarks = [1, 7, 30, 100, 200, 300, 500, 1000];

/// How far ahead milestones are worked out.
const _horizonYears = 120;

final _thousands = NumberFormat.decimalPattern('en_US');

/// Every milestone of a Since event in order: day counts (1 day, 1 week,
/// 30 days, 100 days … every 1,000 days), 6 months, and each anniversary.
/// Days move by calendar day, so the time of day stays put across daylight
/// saving. When two land on the same day the anniversary wins.
List<Milestone> sinceMilestones(Countdown event) {
  final s = event.target;
  DateTime at(int y, int m, int d) => DateTime(y, m, d, s.hour, s.minute);
  final byDay = <DateTime, Milestone>{};
  void add(DateTime when, String label, {bool wins = false}) {
    final day = DateTime(when.year, when.month, when.day);
    if (wins || !byDay.containsKey(day)) {
      byDay[day] = (at: when, label: label);
    }
  }

  final days = [
    ..._dayMarks,
    for (var n = 2000; n <= _horizonYears * 365; n += 1000) n,
  ];
  for (final n in days) {
    final label = switch (n) {
      1 => '1 day',
      7 => '1 week',
      _ => '${_thousands.format(n)} days',
    };
    add(at(s.year, s.month, s.day + n), label);
  }
  add(_addMonths(s, 6), '6 months');
  for (var y = 1; y <= _horizonYears; y++) {
    add(_addMonths(s, 12 * y), y == 1 ? '1 year' : '$y years', wins: true);
  }
  return byDay.values.toList()..sort((a, b) => a.at.compareTo(b.at));
}

/// The next milestone after [now], if any.
Milestone? nextMilestone(Countdown event, DateTime now) =>
    sinceMilestones(event).where((m) => m.at.isAfter(now)).firstOrNull;

/// The milestones after [now], soonest first.
Iterable<Milestone> upcomingMilestones(Countdown event, DateTime now) =>
    sinceMilestones(event).where((m) => m.at.isAfter(now));

/// How far from the last milestone (or the start) to the next, 0 to 100.
int milestoneProgress(Countdown event, DateTime now) {
  var from = event.target;
  for (final m in sinceMilestones(event)) {
    if (m.at.isAfter(now)) {
      final total = m.at.difference(from).inSeconds;
      if (total <= 0) return 100;
      final done = now.difference(from).inSeconds * 100 / total;
      return done.round().clamp(0, 100);
    }
    from = m.at;
  }
  return 100;
}

/// [d] plus [months], the day clamped to the end of a shorter month (so
/// Feb 29 lands on Feb 28 in other years).
DateTime _addMonths(DateTime d, int months) {
  final first = DateTime(d.year, d.month + months);
  final lastDay = DateTime(first.year, first.month + 1, 0).day;
  return DateTime(
    first.year,
    first.month,
    d.day > lastDay ? lastDay : d.day,
    d.hour,
    d.minute,
  );
}
