import 'package:countdowns/screens/editor/all_icons_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the sheet from a button and records what it returns.
class _Host {
  String? result = 'not closed';

  Future<void> pump(WidgetTester tester, {String? selected}) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await showModalBottomSheet<String>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AllIconsSheet(selected: selected),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('opens in sections, starting with Celebrations', (tester) async {
    await _Host().pump(tester);
    expect(find.text('CELEBRATIONS'), findsOneWidget);
    expect(find.text('Birthday'), findsOneWidget);
    expect(find.text('Search 268 icons'), findsOneWidget);
  });

  testWidgets('a section chip shows only that section', (tester) async {
    await _Host().pump(tester);
    await tester.tap(find.text('Celebrations'));
    await tester.pumpAndSettle();
    expect(find.text('CELEBRATIONS'), findsNothing);
    expect(find.text('Birthday'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Flowers'),
      200,
      scrollable: find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Christmas'), findsNothing);
  });

  testWidgets('searching wedding finds the wedding icons; tap returns it', (
    tester,
  ) async {
    final host = _Host();
    await host.pump(tester);
    await tester.enterText(find.byType(TextField), 'wedding');
    await tester.pumpAndSettle();
    expect(find.text('Wedding bells'), findsOneWidget);
    expect(find.text('Bride & groom'), findsOneWidget);
    expect(find.text('Birthday'), findsNothing);
    await tester.tap(find.text('Wedding bells'));
    await tester.pumpAndSettle();
    expect(host.result, 'wedding-bells');
  });

  testWidgets('no match says so', (tester) async {
    await _Host().pump(tester);
    await tester.enterText(find.byType(TextField), 'zzzqqq');
    await tester.pumpAndSettle();
    expect(find.text('No icons match'), findsOneWidget);
  });
}
