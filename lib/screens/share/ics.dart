import 'package:countdowns/models/countdown.dart';

String _two(int n) => n.toString().padLeft(2, '0');

String _date(DateTime d) => '${d.year}${_two(d.month)}${_two(d.day)}';

String _utc(DateTime d) {
  final u = d.toUtc();
  return '${_date(u)}T${_two(u.hour)}${_two(u.minute)}${_two(u.second)}Z';
}

/// Escapes text per RFC 5545.
String _escape(String s) => s
    .replaceAll(r'\', r'\\')
    .replaceAll(';', r'\;')
    .replaceAll(',', r'\,')
    .replaceAll('\n', r'\n');

/// Folds lines longer than 75 characters.
String _fold(String line) {
  if (line.length <= 75) return line;
  final out = StringBuffer(line.substring(0, 75));
  for (var i = 75; i < line.length; i += 74) {
    out.write(
      '\r\n ${line.substring(i, i + 74 > line.length ? line.length : i + 74)}',
    );
  }
  return out.toString();
}

/// A calendar file for [event], made on the device. [note] goes in the
/// description. One alert the day before.
String buildIcs(Countdown event, {required DateTime now, String? note}) {
  final start = event.nextOccurrence(now);
  final lines = <String>[
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Since & Soon//Since & Soon app//EN',
    'CALSCALE:GREGORIAN',
    'BEGIN:VEVENT',
    'UID:countdown-${event.id ?? 0}-${_date(start)}@countdowns.app',
    'DTSTAMP:${_utc(now)}',
    if (event.allDay) ...[
      'DTSTART;VALUE=DATE:${_date(start)}',
      'DTEND;VALUE=DATE:${_date(DateTime(start.year, start.month, start.day + 1))}',
    ] else ...[
      'DTSTART:${_utc(start)}',
      'DTEND:${_utc(start.add(const Duration(hours: 1)))}',
    ],
    if (event.repeat == RepeatRule.yearly) 'RRULE:FREQ=YEARLY',
    'SUMMARY:${_escape(event.title)}',
    if (note != null) 'DESCRIPTION:${_escape(note)}',
    'BEGIN:VALARM',
    'ACTION:DISPLAY',
    'DESCRIPTION:${_escape(event.title)}',
    'TRIGGER:-P1D',
    'END:VALARM',
    'END:VEVENT',
    'END:VCALENDAR',
  ];
  return '${lines.map(_fold).join('\r\n')}\r\n';
}

/// A safe file name from a title.
String fileNameFor(String title, String extension) {
  final clean = title
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return '${clean.isEmpty ? 'Countdown' : clean}.$extension';
}
