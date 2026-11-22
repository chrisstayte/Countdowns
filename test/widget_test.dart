import 'dart:convert';
import 'dart:typed_data';

import 'package:countdowns/main.dart';
import 'package:countdowns/models/event.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/providers/notification_provider.dart';
import 'package:countdowns/providers/timer_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoNotifications extends EventNotifications {
  @override
  bool get supported => false;
}

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

  testWidgets(
    'Create, customize, edit, cancel and delete through the routed screens',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Hive.registerAdapter(EventAdapter());
      final box = await Hive.openBox<Event>('events', bytes: Uint8List(0));
      addTearDown(box.close);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventBoxProvider.overrideWithValue(box),
            preferencesProvider.overrideWithValue(prefs),
            notificationsProvider.overrideWithValue(_NoNotifications()),
          ],
          child: const MyApp(),
        ),
      );

      Future<void> tap(Finder target) async {
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      PackageInfo.setMockInitialValues(
        appName: 'Countdowns',
        packageName: 'countdowns',
        version: '2.0.0',
        buildNumber: '5',
        buildSignature: '',
      );
      await tap(find.byIcon(Icons.settings));
      await tap(find.text('System'));
      await tap(find.text('Dark').last);
      expect(find.text('Settings'), findsOneWidget);
      expect(
        jsonDecode(prefs.getString('localSettings')!)['themeMode'],
        ThemeMode.dark.index,
      );
      await tap(find.byIcon(Icons.arrow_back));
      await tap(find.byIcon(Icons.add_rounded));
      await tap(find.text('Save'));
      expect(box.isEmpty, isTrue);
      await tester.enterText(find.byType(TextField), 'Birthday');
      await tap(find.byIcon(Icons.calendar_month_rounded));
      expect(find.text('Date'), findsOneWidget);
      await tap(find.byType(Switch));
      await tap(find.byIcon(Icons.check));
      await tap(find.byIcon(Icons.palette_rounded));
      await tap(find.byType(Switch).hitTestable());
      await tap(find.byIcon(Icons.add_reaction_rounded));
      await tap(find.byIcon(Icons.cake));
      await tap(find.byIcon(Icons.font_download_rounded));
      await tap(find.text('Comic Neue'));
      await tap(find.text('Save'));
      final key = box.keys.single;
      expect(box.get(key)!.allDayEvent, isFalse);
      expect(box.get(key)!.backgroundGradient, isTrue);
      expect(box.get(key)!.icon, Icons.cake);
      expect(box.get(key)!.fontFamily, 'ComicNeue');

      await tap(find.byIcon(Icons.table_rows));
      expect(
        jsonDecode(prefs.getString('localSettings')!)['squareView'],
        false,
      );
      await tap(find.text('Birthday'));
      expect(find.text('Seconds'), findsOneWidget);
      await tap(find.byIcon(Icons.more_vert));
      await tap(find.text('Edit'));
      await tester.enterText(find.byType(TextField), 'Discard me');
      await tap(find.byIcon(Icons.arrow_back));
      expect(box.get(key)!.title, 'Birthday');

      await tap(find.byIcon(Icons.more_vert));
      await tap(find.text('Edit'));
      await tester.enterText(find.byType(TextField), 'Updated birthday');
      await tap(find.text('Save'));
      expect(box.keys.single, key);
      expect(box.get(key)!.title, 'Updated birthday');
      expect(find.text('Updated birthday'), findsOneWidget);
      await tap(find.byIcon(Icons.more_vert));
      await tap(find.text('Delete'));
      await tap(find.text('No'));
      expect(box.length, 1);
      await tap(find.byIcon(Icons.more_vert));
      await tap(find.text('Delete'));
      await tap(find.text('Yes'));
      expect(find.text('Events'), findsOneWidget);
      expect(box.isEmpty, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}
