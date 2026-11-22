import 'dart:convert';

import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/widgets/sliding_segmented.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const options = ['Days', 'Weeks', 'Sleeps', 'Hours'];

/// Hosts a 400-wide control (four 97-wide options with 4 gaps, inside a
/// 4-point track padding) and records changes and haptic ticks.
class Harness {
  final changes = <String>[];
  var ticks = 0;
  late String selected;

  Future<void> pump(
    WidgetTester tester, {
    String initial = 'Days',
    bool haptics = true,
  }) async {
    selected = initial;
    SharedPreferences.setMockInitialValues({
      'localSettings': jsonEncode({'hapticFeedback': haptics}),
    });
    final prefs = await SharedPreferences.getInstance();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') ticks++;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 408,
                child: StatefulBuilder(
                  builder: (context, setState) => SlidingSegmented<String>(
                    values: options,
                    selected: selected,
                    label: (v) => v,
                    onChanged: (v) {
                      changes.add(v);
                      setState(() => selected = v);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Rect pill(WidgetTester tester) =>
    tester.getRect(find.byKey(const ValueKey('sliding-segmented-pill')));

Rect option(WidgetTester tester, String label) => tester.getRect(
  find.ancestor(of: find.text(label), matching: find.byType(Positioned)).first,
);

void main() {
  testWidgets('tapping an option selects it and the pill springs there', (
    tester,
  ) async {
    final h = Harness();
    await h.pump(tester);
    final start = pill(tester);
    expect(start.left, closeTo(option(tester, 'Days').left, 0.5));

    await tester.tap(find.text('Sleeps'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // Mid-animation the pill is between the two, not jumped.
    final mid = pill(tester);
    expect(mid.left, greaterThan(start.left));
    expect(mid.left, lessThan(option(tester, 'Sleeps').left));

    await tester.pumpAndSettle();
    expect(h.changes, ['Sleeps']);
    expect(pill(tester).left, closeTo(option(tester, 'Sleeps').left, 0.5));
    expect(pill(tester).width, closeTo(option(tester, 'Sleeps').width, 0.5));
    expect(h.ticks, 1);
  });

  testWidgets('tapping the selected option changes nothing', (tester) async {
    final h = Harness();
    await h.pump(tester, initial: 'Weeks');
    await tester.tap(find.text('Weeks'));
    await tester.pumpAndSettle();
    expect(h.changes, isEmpty);
    expect(h.ticks, 0);
  });

  testWidgets('dragging the pill follows the finger and snaps to nearest', (
    tester,
  ) async {
    final h = Harness();
    await h.pump(tester);
    final days = option(tester, 'Days');
    final step = option(tester, 'Weeks').left - days.left;

    final gesture = await tester.startGesture(days.center);
    // Move in small steps, as a finger does.
    for (var i = 0; i < 16; i++) {
      await gesture.moveBy(Offset(step * 0.1, 0));
      await tester.pump();
    }
    await tester.pump();
    // Following the finger: about 1.6 options along, between Weeks and
    // Sleeps, nothing selected yet.
    expect(pill(tester).left, closeTo(days.left + step * 1.6, 2));
    expect(h.changes, isEmpty);

    await gesture.up();
    await tester.pumpAndSettle();
    // Snapped to the nearest option, Sleeps, and selected it.
    expect(h.changes, ['Sleeps']);
    expect(pill(tester).left, closeTo(option(tester, 'Sleeps').left, 0.5));
    // One tick for each option the pill passed onto: Weeks, then Sleeps.
    expect(h.ticks, 2);
  });

  testWidgets('a drag that ends near where it started snaps back', (
    tester,
  ) async {
    final h = Harness();
    await h.pump(tester, initial: 'Hours');
    final hours = option(tester, 'Hours');
    final gesture = await tester.startGesture(hours.center);
    await gesture.moveBy(const Offset(-20, 0));
    await gesture.moveBy(const Offset(-10, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(h.changes, isEmpty);
    expect(pill(tester).left, closeTo(hours.left, 0.5));
  });

  testWidgets('dragging off the pill does not move it', (tester) async {
    final h = Harness();
    await h.pump(tester);
    final gesture = await tester.startGesture(option(tester, 'Hours').center);
    await gesture.moveBy(const Offset(-120, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(h.changes, isEmpty);
    expect(pill(tester).left, closeTo(option(tester, 'Days').left, 0.5));
  });

  testWidgets('no haptics when they are turned off', (tester) async {
    final h = Harness();
    await h.pump(tester, haptics: false);
    await tester.tap(find.text('Hours'));
    await tester.pumpAndSettle();
    expect(h.changes, ['Hours']);
    expect(h.ticks, 0);
  });

  testWidgets('labels cross-fade with the pill', (tester) async {
    final h = Harness();
    await h.pump(tester);
    int colorOf(String label) =>
        tester.widget<Text>(find.text(label)).style!.color!.toARGB32();
    final white = Colors.white.toARGB32();
    expect(colorOf('Days'), white);
    await tester.tap(find.text('Weeks'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    final mid = colorOf('Weeks');
    expect(mid, isNot(white));
    await tester.pumpAndSettle();
    expect(colorOf('Weeks'), white);
    expect(colorOf('Days'), isNot(white));
  });

  testWidgets('each option is a button with its selected state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final h = Harness();
    await h.pump(tester, initial: 'Sleeps');
    expect(
      tester.getSemantics(find.bySemanticsLabel('Sleeps')),
      matchesSemantics(
        label: 'Sleeps',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Days')),
      matchesSemantics(
        label: 'Days',
        isButton: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });
}
