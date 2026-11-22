import 'package:countdowns/providers/timer_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Countdowns share a one-second tick and dispose the timer', (
    tester,
  ) async {
    final container = ProviderContainer();
    final ticks = <DateTime>[];
    final first = container.listen(clockProvider, (_, now) => ticks.add(now));
    final second = container.listen(clockProvider, (_, now) => ticks.add(now));
    await tester.pump(const Duration(seconds: 1));
    expect(ticks, hasLength(2));
    expect(ticks.first, ticks.last);
    first.close();
    second.close();
    await tester.pump(Duration.zero);
    expect(container.read(clockProvider.exists), isFalse);
    container.dispose();
  });

}
