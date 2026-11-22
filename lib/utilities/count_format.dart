import 'package:countdowns/models/countdown.dart';
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

/// The big number for [unit], as on the detail screen.
CountText countIn(Countdown event, CountUnit unit, DateTime now) {
  final target = event.nextOccurrence(now);
  final left = target.difference(now);
  final ms = left.isNegative ? Duration.zero : left;
  switch (unit) {
    case CountUnit.days:
      final d = ms.inDays;
      return (big: '$d', unit: _plural(d, 'day', 'days'));
    case CountUnit.weeks:
      final w = ms.inSeconds / (7 * 24 * 3600);
      return (big: w.toStringAsFixed(1), unit: 'weeks');
    case CountUnit.sleeps:
      final s = calendarDaysBetween(now, target).clamp(0, 1 << 30);
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
  final left = event.timeLeft(now);
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

/// Whole calendar years until [target], and the date after them.
({int years, DateTime after}) _wholeYears(DateTime now, DateTime target) {
  var years = target.year - now.year;
  DateTime add(int y) =>
      DateTime(now.year + y, now.month, now.day, now.hour, now.minute);
  while (years > 0 && add(years).isAfter(target)) {
    years--;
  }
  return (years: years, after: add(years));
}

/// The quiet line under the giant number for events a year or more away:
/// "2 years, 41 days", "2 years, 6 weeks", or "2 years" for hours.
String? yearsLine(Countdown event, CountUnit unit, DateTime now) {
  final target = event.nextOccurrence(now);
  if (target.difference(now).inDays < 365) return null;
  final (:years, :after) = _wholeYears(now, target);
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
  final target = event.nextOccurrence(now);
  final raw = target.difference(now);
  final ms = raw.isNegative ? Duration.zero : raw;
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
      final nights = calendarDaysBetween(now, target).clamp(0, 1 << 30);
      var saturdays = 0, mondays = 0;
      final start = _day(now);
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

/// Share of the wait already behind you, 0 to 100.
int waitProgress(Countdown event, DateTime now) {
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

/// "Friday, December 25 · All day" or "Sunday, March 14, 2027 · 9:30 AM".
String longDate(Countdown event, DateTime now) {
  final d = event.nextOccurrence(now);
  final date = DateFormat(
    d.year == now.year ? 'EEEE, MMMM d' : 'EEEE, MMMM d, y',
  ).format(d);
  return '$date · ${event.allDay ? 'All day' : _time.format(event.dateTime)}';
}

String timeOfDay(DateTime d) => _time.format(d);
