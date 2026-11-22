import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/screens/share/ics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 21, 12);

  test('all-day yearly event', () {
    final ics = buildIcs(
      Countdown(
        id: 4,
        title: 'Christmas, at home; with tea',
        dateTime: DateTime(2020, 12, 25),
        repeat: RepeatRule.yearly,
      ),
      now: now,
      note: '34 sleeps to go',
    );
    expect(ics, contains('DTSTART;VALUE=DATE:20261225\r\n'));
    expect(ics, contains('DTEND;VALUE=DATE:20261226\r\n'));
    expect(ics, contains('RRULE:FREQ=YEARLY\r\n'));
    expect(ics, contains(r'SUMMARY:Christmas\, at home\; with tea'));
    expect(ics, contains('TRIGGER:-P1D'));
    expect(ics, startsWith('BEGIN:VCALENDAR\r\n'));
    expect(ics, endsWith('END:VCALENDAR\r\n'));
  });

  test('timed one-off event is in UTC', () {
    final start = DateTime(2027, 3, 14, 9, 30);
    final ics = buildIcs(
      Countdown(title: 'Japan trip', dateTime: start, allDay: false),
      now: now,
    );
    final u = start.toUtc();
    expect(
      ics,
      contains(
        'DTSTART:${u.year}${'${u.month}'.padLeft(2, '0')}${'${u.day}'.padLeft(2, '0')}T${'${u.hour}'.padLeft(2, '0')}3000Z',
      ),
    );
    expect(ics, isNot(contains('RRULE')));
  });

  test('file names are safe', () {
    expect(fileNameFor('Mia/Leo: party?', 'ics'), 'MiaLeo party.ics');
    expect(fileNameFor('  ', 'png'), 'Countdown.png');
  });
}
