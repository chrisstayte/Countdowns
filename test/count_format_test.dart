import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/utilities/count_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 21, 20);
  final christmas = Countdown(title: 'Christmas', dateTime: DateTime(2026, 12, 25));

  test('units', () {
    expect(countIn(christmas, CountUnit.days, now), (big: '33', unit: 'days'));
    expect(countIn(christmas, CountUnit.sleeps, now), (big: '34', unit: 'sleeps'));
    expect(countIn(christmas, CountUnit.weeks, now).big, '4.7');
    expect(countIn(christmas, CountUnit.hours, now), (big: '796', unit: 'hours'));
  });

  test('years line shows from 365 days and hides under a year', () {
    expect(yearsLine(christmas, CountUnit.days, now), isNull);
    final far = Countdown(title: 'Far', dateTime: DateTime(2029, 1, 1));
    expect(yearsLine(far, CountUnit.days, now), '2 years, 40 days');
    expect(yearsLine(far, CountUnit.weeks, now), '2 years, 5 weeks');
    expect(yearsLine(far, CountUnit.hours, now), '2 years');
    expect(cardYears(far, now), 'in 2 years');
    final oneYear = Countdown(title: 'Next', dateTime: DateTime(2027, 12, 1));
    expect(yearsLine(oneYear, CountUnit.days, now), '1 year, 9 days');
    expect(cardYears(oneYear, now), isNull);
  });

  test('yearly events roll over and are never done', () {
    final bday = Countdown(
      title: 'Birthday',
      dateTime: DateTime(1990, 2, 3),
      repeat: RepeatRule.yearly,
    );
    expect(bday.nextOccurrence(now), DateTime(2027, 2, 3));
    expect(bday.isDone(now), isFalse);
  });

  test('cards on the day and after', () {
    final today = Countdown(title: 'Today', dateTime: DateTime(2026, 11, 21));
    expect(cardCount(today, now).big, 'Today');
    final past = Countdown(title: 'Past', dateTime: DateTime(2026, 8, 2));
    expect(cardCount(past, now), (big: '111', unit: 'days ago'));
  });
}
