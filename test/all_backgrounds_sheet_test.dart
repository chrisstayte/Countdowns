import 'dart:convert';
import 'dart:ui' show Tristate;

import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/models/palette.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/screens/editor/all_backgrounds_sheet.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opens the sheet from a button and records what it returns.
class _Host {
  Object? result = 'not closed';

  String? get key => (result as BackgroundChoice?)?.key;

  Future<void> pump(WidgetTester tester, Countdown draft) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'localSettings': jsonEncode({'hapticFeedback': false, 'sound': false}),
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    result = await showModalBottomSheet<Object>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => AllBackgroundsSheet(draft: draft),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }
}

SemanticsNode node(WidgetTester tester, String label) =>
    tester.getSemantics(find.bySemanticsLabel(label).first);

bool isSelected(WidgetTester tester, String label) =>
    node(tester, label).flagsCollection.isSelected == Tristate.isTrue;

void main() {
  final draft = Countdown(
    id: 1,
    title: 'Japan trip',
    dateTime: DateTime(2099, 3, 14),
    colorArgb: 0xFF7877E6, // Lavender
  );

  testWidgets('opens on Colours with the current colour ringed', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final host = _Host();
    await host.pump(tester, draft);
    expect(find.text('All backgrounds'), findsOneWidget);
    expect(find.text('WARM'), findsOneWidget);
    expect(isSelected(tester, 'Lavender'), isTrue);
    expect(isSelected(tester, 'Teal'), isFalse);
    // The name shows under the chosen swatch only.
    expect(find.text('Lavender'), findsOneWidget);
    expect(find.text('Teal'), findsNothing);
    handle.dispose();
  });

  testWidgets('a pick updates the preview and moves the ring; Done returns '
      'it', (tester) async {
    final handle = tester.ensureSemantics();
    final host = _Host();
    await host.pump(tester, draft);
    await tester.tap(find.bySemanticsLabel('Teal'));
    await tester.pumpAndSettle();
    expect(isSelected(tester, 'Teal'), isTrue);
    expect(isSelected(tester, 'Lavender'), isFalse);
    expect(find.bySemanticsLabel('Preview: Teal'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(host.key, 'colour:FF2BB3A3');
    handle.dispose();
  });

  testWidgets('gradients are grouped; picking one returns its id', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final host = _Host();
    await host.pump(tester, draft);
    await tester.tap(find.text('Gradients'));
    await tester.pumpAndSettle();
    expect(find.text('SUNSET'), findsOneWidget);
    // Night is deep in the list: scroll until Nebula is built, then bring
    // it fully into view.
    while (find.bySemanticsLabel('Nebula gradient').evaluate().isEmpty) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.bySemanticsLabel('Nebula gradient'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Nebula gradient'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Preview: Nebula'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(host.key, 'gradient:nebula');
    handle.dispose();
  });

  testWidgets('a gradient countdown opens on Gradients with it ringed', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final host = _Host();
    await host.pump(
      tester,
      draft.copyWith(gradientId: 'sunset', colorArgb: 0xFFFE7228),
    );
    expect(find.text('SUNSET'), findsOneWidget);
    expect(isSelected(tester, 'Sunset gradient'), isTrue);
    handle.dispose();
  });

  testWidgets('swiping the sheet away changes nothing', (tester) async {
    final host = _Host();
    await host.pump(tester, draft);
    await tester.tap(find.bySemanticsLabel('Teal'));
    await tester.pumpAndSettle();
    // Tap the barrier above the sheet.
    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();
    expect(host.result, isNull);
  });

  testWidgets('Photos offers Add photo, which asks the editor to pick', (
    tester,
  ) async {
    final host = _Host();
    await host.pump(tester, draft);
    // The test font is wide, so the tab row scrolls here.
    await tester.ensureVisible(find.text('Photos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photos'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Add a photo'));
    await tester.pumpAndSettle();
    expect(host.result, addPhotoResult);
  });

  group('direction', () {
    Gradient? swatchGradient(WidgetTester tester, String label) {
      final tile = find.ancestor(
        of: find.byType(Container),
        matching: find.bySemanticsLabel(label),
      );
      for (final c in tester.widgetList<Container>(
        find.descendant(
          of: find.bySemanticsLabel(label).first,
          matching: find.byType(Container),
        ),
      )) {
        final d = c.decoration;
        if (d is BoxDecoration && d.gradient != null) return d.gradient;
      }
      expect(tile, findsWidgets);
      return null;
    }

    /// The chip row is wider than the phone; slide it to the end first.
    Future<void> showAllChips(WidgetTester tester) async {
      await tester.drag(
        find.byKey(const ValueKey('pinned-direction-row')),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('only the Gradients tab has the Direction row', (tester) async {
      final host = _Host();
      await host.pump(tester, draft);
      expect(find.byKey(const ValueKey('pinned-direction-row')), findsNothing);
      await tester.tap(find.text('Gradients'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('pinned-direction-row')),
        findsOneWidget,
      );
      await tester.tap(find.text('Photos'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pinned-direction-row')), findsNothing);
    });

    testWidgets('the row stays put while families scroll under it', (
      tester,
    ) async {
      final host = _Host();
      await host.pump(
        tester,
        draft.copyWith(gradientId: 'sunset', colorArgb: 0xFFFE7228),
      );
      final row = find.byKey(const ValueKey('pinned-direction-row'));
      final before = tester.getTopLeft(row);
      final header = tester.getTopLeft(find.text('SUNSET'));
      double divider() => tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('direction-divider')),
          )
          .opacity;
      expect(divider(), 0);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(row), before);
      expect(
        find.text('SUNSET'),
        findsNothing,
        reason: 'scrolled under, not moved with: was at $header',
      );
      expect(divider(), 1);
    });

    testWidgets('a direction redraws every gradient swatch and the preview; '
        'Done returns it', (tester) async {
      final handle = tester.ensureSemantics();
      final host = _Host();
      await host.pump(
        tester,
        draft.copyWith(
          gradientId: 'sunset',
          colorArgb: 0xFFFE7228,
          gradientDirection: GradientDirection.diagonalDown,
        ),
      );
      expect(
        (swatchGradient(tester, 'Lagoon gradient') as LinearGradient).begin,
        Alignment.topLeft,
      );
      await showAllChips(tester);
      await tester.tap(find.bySemanticsLabel('From the centre'));
      await tester.pumpAndSettle();
      expect(swatchGradient(tester, 'Lagoon gradient'), isA<RadialGradient>());
      expect(swatchGradient(tester, 'Sunset gradient'), isA<RadialGradient>());
      // Picking another gradient keeps the direction.
      await tester.tap(find.bySemanticsLabel('Lagoon gradient'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      final choice = host.result! as BackgroundChoice;
      expect(choice.key, 'gradient:lagoon');
      expect(choice.direction, GradientDirection.radial);
      final applied = choice.applyTo(draft);
      expect(applied.gradientId, 'lagoon');
      expect(applied.direction, GradientDirection.radial);
      handle.dispose();
    });

    testWidgets('swiping away discards a direction change', (tester) async {
      final handle = tester.ensureSemantics();
      final host = _Host();
      await host.pump(
        tester,
        draft.copyWith(gradientId: 'sunset', colorArgb: 0xFFFE7228),
      );
      await showAllChips(tester);
      await tester.tap(find.bySemanticsLabel('Round'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();
      expect(host.result, isNull);
      handle.dispose();
    });
  });
}
