import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/models/event_icons.dart';

const _months = [
  'january',
  'february',
  'march',
  'april',
  'may',
  'june',
  'july',
  'august',
  'september',
  'october',
  'november',
  'december',
];

class SearchHit {
  const SearchHit(this.event, {this.start = -1, this.length = 0});
  final Countdown event;

  /// Where the query matched in the title, or -1.
  final int start;
  final int length;
}

/// The month a query names ("dec", "December"), if any.
int? monthFor(String q) {
  if (q.length < 3) return null;
  final i = _months.indexWhere((m) => m.startsWith(q));
  return i < 0 ? null : i + 1;
}

/// Matches titles, icon labels, month names, years, "this week" and "done".
/// Upcoming first (soonest first), then done.
List<SearchHit> searchCountdowns(
  List<Countdown> events,
  String query,
  DateTime now,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final year = RegExp(r'^\d{4}$').hasMatch(q) ? int.parse(q) : null;
  final month = monthFor(q);
  final weekEnd = DateTime(now.year, now.month, now.day + 7);
  final hits = <SearchHit>[];
  for (final e in events) {
    final when = e.nextOccurrence(now);
    final title = e.title.toLowerCase();
    final at = title.indexOf(q);
    final matches =
        at >= 0 ||
        (iconInfo(e.iconSlug)?.label.toLowerCase().contains(q) ?? false) ||
        (q == 'done' && e.isDone(now)) ||
        (q == 'since' && e.isSince) ||
        (q == 'this week' &&
            !e.isSince &&
            !e.isDone(now) &&
            when.isBefore(weekEnd)) ||
        (year != null && when.year == year) ||
        (month != null && when.month == month);
    if (matches) hits.add(SearchHit(e, start: at, length: q.length));
  }
  hits.sort((a, b) {
    // Countdowns first, then Since, then done.
    int rank(Countdown e) => e.isDone(now) ? 2 : (e.isSince ? 1 : 0);
    final ra = rank(a.event), rb = rank(b.event);
    if (ra != rb) return ra.compareTo(rb);
    return a.event.nextOccurrence(now).compareTo(b.event.nextOccurrence(now));
  });
  return hits;
}

/// Fixed-date holidays to suggest in "Try adding".
const holidays = [
  ('Valentine’s Day', 2, 14),
  ('St Patrick’s Day', 3, 17),
  ('Halloween', 10, 31),
  ('Christmas', 12, 25),
  ('New Year’s Eve', 12, 31),
];

List<(String, DateTime)> holidaySuggestions(
  List<Countdown> events,
  DateTime now,
) {
  final titles = events.map((e) => e.title.toLowerCase()).toSet();
  final today = DateTime(now.year, now.month, now.day);
  final list = [
    for (final (name, m, d) in holidays)
      if (!titles.any((t) => t.contains(name.toLowerCase().split('’').first)))
        (
          name,
          DateTime(now.year, m, d).isBefore(today)
              ? DateTime(now.year + 1, m, d)
              : DateTime(now.year, m, d),
        ),
  ]..sort((a, b) => a.$2.compareTo(b.$2));
  return list.take(2).toList();
}
