import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/utilities/milestones.dart';
import 'package:intl/intl.dart';

/// A number and its unit word, e.g. ("34", "days").
typedef CountText = ({String big, String unit});

final _thousands = NumberFormat.decimalPattern('en_US');

String _plural(int n, String one, String many) => n == 1 ? one : many;

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Calendar days from [from]'s date to [to]'s date (nights in between).
int calendarDaysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// What gets counted: from now to the next occurrence for Soon, from the
/// start to now for Since.
({DateTime from, DateTime to}) countSpan(Countdown event, DateTime now) =>
    event.isSince
    ? (from: event.target, to: now)
    : (from: now, to: event.nextOccurrence(now));

Duration _length(DateTime from, DateTime to) {
  final d = to.difference(from);
  return d.isNegative ? Duration.zero : d;
}

/// The big number for [unit], as on the detail screen.
CountText countIn(Countdown event, CountUnit unit, DateTime now) {
  final (:from, :to) = countSpan(event, now);
  final ms = _length(from, to);
  switch (unit) {
    case CountUnit.days:
      final d = ms.inDays;
      return (big: '$d', unit: _plural(d, 'day', 'days'));
    case CountUnit.weeks:
      final w = ms.inSeconds / (7 * 24 * 3600);
      return (big: w.toStringAsFixed(1), unit: 'weeks');
    case CountUnit.sleeps:
      final s = calendarDaysBetween(from, to).clamp(0, 1 << 30);
      return (big: '$s', unit: _plural(s, 'sleep', 'sleeps'));
    case CountUnit.hours:
      final h = ms.inHours;
      return (big: _thousands.format(h), unit: _plural(h, 'hour', 'hours'));
  }
}

/// The short count for cards and widgets. Drops to hours and minutes on the
/// last day, says "Today" on the day of an all-day event.
CountText cardCount(Countdown event, DateTime now) {
  if (event.isDone(now)) {
    final ago = calendarDaysBetween(event.target, now);
    return (big: '$ago', unit: _plural(ago, 'day ago', 'days ago'));
  }
  if (event.isToday(now)) return (big: 'Today', unit: '');
  final (:from, :to) = countSpan(event, now);
  final left = _length(from, to);
  if (event.unit != CountUnit.sleeps && left.inDays < 1) {
    if (left.inHours >= 1) {
      return (
        big: '${left.inHours}',
        unit: _plural(left.inHours, 'hour', 'hours'),
      );
    }
    final m = left.inMinutes.clamp(0, 59);
    return (big: '$m', unit: 'min');
  }
  return countIn(event, event.unit, now);
}

/// Whole calendar years from [now] to [target], and the date after them.
({int years, DateTime after}) _wholeYears(DateTime now, DateTime target) {
  var years = target.year - now.year;
  DateTime add(int y) =>
      DateTime(now.year + y, now.month, now.day, now.hour, now.minute);
  while (years > 0 && add(years).isAfter(target)) {
    years--;
  }
  return (years: years, after: add(years));
}

/// The quiet line under the giant number for spans of a year or more:
/// "2 years, 41 days", "2 years, 6 weeks", or "2 years" for hours.
String? yearsLine(Countdown event, CountUnit unit, DateTime now) {
  final (:from, to: target) = countSpan(event, now);
  if (target.difference(from).inDays < 365) return null;
  final (:years, :after) = _wholeYears(from, target);
  if (years < 1) return null;
  final y = '$years ${_plural(years, 'year', 'years')}';
  final restDays = unit == CountUnit.sleeps
      ? calendarDaysBetween(after, target)
      : target.difference(after).inDays;
  switch (unit) {
    case CountUnit.hours:
      return y;
    case CountUnit.weeks:
      final w = restDays ~/ 7;
      return w == 0 ? y : '$y, $w ${_plural(w, 'week', 'weeks')}';
    case CountUnit.days:
    case CountUnit.sleeps:
      return restDays == 0
          ? y
          : '$y, $restDays ${_plural(restDays, 'day', 'days')}';
  }
}

/// "in 2 years" for cards when an event is two or more years away.
String? cardYears(Countdown event, DateTime now) {
  if (event.isSince) return null;
  final target = event.nextOccurrence(now);
  final (:years, after: _) = _wholeYears(now, target);
  return years >= 2 ? 'in $years years' : null;
}

String _pad(int n) => n.toString().padLeft(2, '0');

String _compact(int n) => n >= 1000000
    ? '${(n / 1000000).toStringAsFixed(2)}M'
    : _thousands.format(n);

/// The three supporting tiles under the big number for each unit.
List<({String value, String label})> detailTiles(
  Countdown event,
  CountUnit unit,
  DateTime now,
) {
  final (:from, :to) = countSpan(event, now);
  final ms = _length(from, to);
  switch (unit) {
    case CountUnit.days:
      return [
        (value: _pad(ms.inHours % 24), label: 'hours'),
        (value: _pad(ms.inMinutes % 60), label: 'minutes'),
        (value: _pad(ms.inSeconds % 60), label: 'seconds'),
      ];
    case CountUnit.weeks:
      return [
        (value: '${ms.inDays ~/ 7}', label: 'weeks'),
        (value: '${ms.inDays % 7}', label: 'days'),
        (value: _pad(ms.inHours % 24), label: 'hours'),
      ];
    case CountUnit.sleeps:
      final nights = calendarDaysBetween(from, to).clamp(0, 1 << 30);
      var saturdays = 0, mondays = 0;
      final start = _day(from);
      for (var i = 0; i < nights; i++) {
        final d = DateTime(start.year, start.month, start.day + i);
        if (d.weekday == DateTime.saturday) saturdays++;
        if (d.weekday == DateTime.monday) mondays++;
      }
      return [
        (value: '$saturdays', label: _plural(saturdays, 'weekend', 'weekends')),
        (value: '$mondays', label: _plural(mondays, 'Monday', 'Mondays')),
        (value: '$nights', label: _plural(nights, 'bedtime', 'bedtimes')),
      ];
    case CountUnit.hours:
      return [
        (value: _compact(ms.inMinutes), label: 'minutes'),
        (value: _compact(ms.inSeconds), label: 'seconds'),
        (
          value: '${_pad(ms.inMinutes % 60)}:${_pad(ms.inSeconds % 60)}',
          label: 'this hour',
        ),
      ];
  }
}

/// Share of the wait already behind you, 0 to 100. For Since, the way to
/// the next milestone.
int waitProgress(Countdown event, DateTime now) {
  if (event.isSince) return milestoneProgress(event, now);
  final start = event.createdAt;
  if (start == null) return 0;
  final target = event.nextOccurrence(now);
  final total = target.difference(start).inSeconds;
  if (total <= 0) return 100;
  return (now.difference(start).inSeconds * 100 / total).round().clamp(0, 100);
}

final _cardDate = DateFormat('EEE, MMM d');
final _cardDateYear = DateFormat('EEE, MMM d, y');
final _time = DateFormat('h:mm a');

/// "Fri, Dec 25" (with the year when it isn't this year).
String shortDate(DateTime d, DateTime now) =>
    (d.year == now.year ? _cardDate : _cardDateYear).format(d);

/// The date line on cards: when it happens, or "Since Mar 3, 2025" (no
/// weekday, so the year fits) when it started.
String cardDate(Countdown event, DateTime now) {
  final d = event.nextOccurrence(now);
  if (!event.isSince) return shortDate(d, now);
  return 'Since ${(d.year == now.year ? _sinceDate : _sinceDateYear).format(d)}';
}

final _sinceDate = DateFormat('MMM d');
final _sinceDateYear = DateFormat('MMM d, y');

/// What follows the big number: "days to go" or "days since".
String countLabel(Countdown event, CountText count, DateTime now) {
  if (event.isToday(now)) {
    return event.isSince ? 'Started today' : 'It’s today!';
  }
  return '${count.unit} ${event.isSince ? 'since' : 'to go'}';
}

/// "Friday, December 25 · All day" or "Sunday, March 14, 2027 · 9:30 AM",
/// after "Since" for Since events.
String longDate(Countdown event, DateTime now) {
  final d = event.nextOccurrence(now);
  final date = DateFormat(
    d.year == now.year ? 'EEEE, MMMM d' : 'EEEE, MMMM d, y',
  ).format(d);
  final time = event.allDay
      ? (event.isSince ? '' : ' · All day')
      : ' · ${_time.format(event.dateTime)}';
  return '${event.isSince ? 'Since ' : ''}$date$time';
}

String timeOfDay(DateTime d) => _time.format(d);
