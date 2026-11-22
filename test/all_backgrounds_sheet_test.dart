import 'dart:convert';
import 'dart:ui' show Tristate;

import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/screens/editor/all_backgrounds_sheet.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opens the sheet from a button and records what it returns.
class _Host {
  String? result = 'not closed';

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
                    result = await showModalBottomSheet<String>(
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
    expect(host.result, 'colour:FF2BB3A3');
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
    await tester.scrollUntilVisible(
      find.bySemanticsLabel('Nebula gradient'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.bySemanticsLabel('Nebula gradient'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Preview: Nebula'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(host.result, 'gradient:nebula');
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
    await tester.tap(find.text('Photos'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Add a photo'));
    await tester.pumpAndSettle();
    expect(host.result, addPhotoResult);
  });
}
