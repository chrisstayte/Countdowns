import 'dart:convert';

import 'package:countdowns/data/database.dart';
import 'package:countdowns/main.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/models/palette.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/providers/notification_provider.dart';
import 'package:countdowns/providers/timer_provider.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoNotifications extends EventNotifications {
  @override
  bool get supported => false;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

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

  testWidgets('Create, edit and delete a countdown through the new screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    PackageInfo.setMockInitialValues(
      appName: 'Countdowns',
      packageName: 'countdowns',
      version: '2.0.0',
      buildNumber: '5',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({
      'localSettings': jsonEncode({'themeMode': 2, 'squareView': false}),
    });
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());

    Future<List<Countdown>> rows() =>
        tester.runAsync(db.allCountdowns).then((v) => v!);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          preferencesProvider.overrideWithValue(prefs),
          notificationsProvider.overrideWithValue(_NoNotifications()),
        ],
        child: const MyApp(),
      ),
    );

    Future<void> settle() async {
      // Drift streams resolve on real async work.
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> tap(Finder target) async {
      await tester.tap(target);
      await settle();
    }

    await settle();
    expect(find.text('Nothing to count down to yet'), findsOneWidget);

    // Saving without a name asks for one.
    await tap(find.text('New countdown'));
    await tap(find.text('Save'));
    expect(find.text('Give your countdown a name'), findsOneWidget);
    expect(await rows(), isEmpty);

    await tester.enterText(find.byType(TextField), 'Birthday');
    await settle();
    await tap(find.text('Never'));
    await tap(find.text('Every year'));
    await tap(find.text('Sleeps'));
    await tap(find.text('Look'));
    await tap(find.bySemanticsLabel(RegExp('^Sunset gradient')));
    await tap(find.bySemanticsLabel(RegExp('^Up')));
    await tap(find.bySemanticsLabel(RegExp('^Birthday')).first);
    await tap(find.text('Save'));

    final saved = (await rows()).single;
    expect(saved.title, 'Birthday');
    expect(saved.repeat, RepeatRule.yearly);
    expect(saved.unit, CountUnit.sleeps);
    expect(saved.gradientId, 'sunset');
    expect(saved.gradientDirection, GradientDirection.up);
    expect(saved.iconSlug, 'cake');

    // The detail screen opens after saving a new countdown.
    expect(find.text('Edit'), findsOneWidget);
    expect(find.textContaining('to go'), findsOneWidget);
    await tap(find.text('Weeks'));
    expect(find.text('weeks to go'), findsOneWidget);

    // Cancel leaves it unchanged.
    await tap(find.text('Edit'));
    await tester.enterText(find.byType(TextField), 'Discard me');
    await tap(find.text('Cancel'));
    expect((await rows()).single.title, 'Birthday');

    await tap(find.text('Edit'));
    await tester.enterText(find.byType(TextField), 'Updated birthday');
    await tap(find.text('Save'));
    expect((await rows()).single.title, 'Updated birthday');
    expect((await rows()).single.id, saved.id);

    // Delete from the editor, after confirming.
    await tap(find.text('Edit'));
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -600),
    );
    await settle();
    await tap(find.text('Delete countdown'));
    await tap(find.text('Keep it'));
    expect(await rows(), hasLength(1));
    await tap(find.text('Delete countdown'));
    await tap(find.text('Delete'));
    expect(await rows(), isEmpty);
    expect(find.text('Countdowns'), findsWidgets);

    // Hidden settings are kept as they were.
    final stored = jsonDecode(prefs.getString('localSettings')!);
    expect(stored['themeMode'], 2);
    expect(stored['squareView'], false);

    await tester.pumpWidget(const SizedBox());
    final closing = db.close();
    await tester.pump(const Duration(seconds: 1));
    await closing;
  });
}
