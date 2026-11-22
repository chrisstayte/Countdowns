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
    bool inkPill = false,
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
                    // The detail screen's style: Ink pill, white label.
                    pillColor: inkPill
                        ? const Color(0xFF2E2A3A)
                        : const Color(0xFFFFE36E),
                    selectedText: inkPill
                        ? Colors.white
                        : const Color(0xFF2E2A3A),
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
  group('scrollable', scrollableTests);

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
    await h.pump(tester, inkPill: true);
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

/// The scrollable mode: label-sized options that fill the width when they
/// fit and scroll (with edge fades, keeping the selection in view) when
/// they don't.
class ScrollHarness {
  final changes = <String>[];
  late String selected;

  Future<void> pump(
    WidgetTester tester,
    List<String> values, {
    String? initial,
    double width = 360,
  }) async {
    selected = initial ?? values.first;
    SharedPreferences.setMockInitialValues({
      'localSettings': jsonEncode({'hapticFeedback': false}),
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: StatefulBuilder(
                  builder: (context, setState) => SlidingSegmented<String>(
                    values: values,
                    selected: selected,
                    label: (v) => v,
                    scrollable: true,
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
    await tester.pumpAndSettle();
  }
}

const seven = [
  'Colors',
  'Gradients',
  'Photos',
  'Patterns',
  'Textures',
  'Illustrations',
  'Emoji',
];

void scrollableTests() {
  testWidgets('three that fit fill the width, with no scrolling', (
    tester,
  ) async {
    // The test font is wide (every glyph is a square), so give it room.
    await ScrollHarness().pump(tester, [
      'Colors',
      'Gradients',
      'Photos',
    ], width: 600);
    expect(find.byType(SingleChildScrollView), findsNothing);
    final left = tester.getRect(find.text('Colors'));
    final right = tester.getRect(find.text('Photos'));
    // Options span the 360 track (inside its 4pt padding).
    final track = tester.getRect(find.byType(SlidingSegmented<String>));
    expect(track.width, 600);
    expect(left.left - track.left, lessThan(60));
    expect(track.right - right.right, lessThan(60));
  });

  testWidgets('seven scroll, sized to their labels, with an end fade', (
    tester,
  ) async {
    await ScrollHarness().pump(tester, seven);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sliding-segmented-fade')),
      findsOneWidget,
    );
    final short = tester.getRect(
      find.ancestor(of: find.text('Emoji'), matching: find.byType(Positioned)),
    );
    final long = tester.getRect(
      find.ancestor(
        of: find.text('Illustrations'),
        matching: find.byType(Positioned),
      ),
    );
    expect(long.width, greaterThan(short.width + 30));
  });

  testWidgets('picking a far option scrolls it to the middle', (tester) async {
    final h = ScrollHarness();
    await h.pump(tester, seven);
    final scroll = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(scroll.controller!.offset, 0);
    // Scroll by hand from the right-hand side (off the pill), then tap.
    final track0 = tester.getRect(find.byType(SlidingSegmented<String>));
    await tester.dragFrom(
      track0.centerRight - const Offset(20, 0),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Illustrations'));
    await tester.pumpAndSettle();
    expect(h.changes, ['Illustrations']);
    final centre = tester.getCenter(find.text('Illustrations')).dx;
    final track = tester.getCenter(find.byType(SlidingSegmented<String>)).dx;
    // Centred, or as near as the end of the row allows.
    final pos = scroll.controller!.position;
    expect(
      (centre - track).abs() < 2 || pos.pixels == pos.maxScrollExtent,
      isTrue,
    );
    expect(pill(tester).center.dx, closeTo(centre, 2));
  });

  testWidgets('a drag off the pill scrolls the row, not the pill', (
    tester,
  ) async {
    final h = ScrollHarness();
    await h.pump(tester, seven);
    final scroll = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    final pillBefore = pill(tester);
    final track = tester.getRect(find.byType(SlidingSegmented<String>));
    await tester.dragFrom(
      track.centerRight - const Offset(20, 0),
      const Offset(-150, 0),
    );
    await tester.pumpAndSettle();
    expect(scroll.controller!.offset, greaterThan(100));
    expect(h.changes, isEmpty);
    // The pill moved with the content, not along it.
    expect(
      pill(tester).left,
      closeTo(pillBefore.left - scroll.controller!.offset, 1),
    );
  });

  testWidgets('a drag that starts on the pill still slides it', (tester) async {
    final h = ScrollHarness();
    await h.pump(tester, seven);
    final start = tester.getCenter(find.text('Colors'));
    final g = await tester.startGesture(start);
    for (var i = 0; i < 12; i++) {
      await g.moveBy(const Offset(10, 0));
      await tester.pump();
    }
    await g.up();
    await tester.pumpAndSettle();
    expect(h.changes, ['Gradients']);
  });

  testWidgets('a selection made elsewhere is scrolled into view', (
    tester,
  ) async {
    final h = ScrollHarness();
    await h.pump(tester, seven, initial: 'Emoji');
    final scroll = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    final pos = scroll.controller!.position;
    expect(pos.pixels, pos.maxScrollExtent);
    expect(h.changes, isEmpty);
  });
}
