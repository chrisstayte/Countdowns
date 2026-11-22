import 'dart:convert';

import 'package:countdowns/data/database.dart';
import 'package:countdowns/main.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/providers/notification_provider.dart';
import 'package:countdowns/widgets_bridge/widget_links.dart';
import 'package:countdowns/widgets_bridge/widget_snapshot.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
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

  group('widget links', () {
    Future<bool> only(int id, int wanted) async => id == wanted;

    test('one link per countdown, in the snapshot', () {
      expect(widgetLinkFor(42).toString(), 'countdowns://event/42');
      expect(widgetLinkEventId(Uri.parse('countdowns://event/42')), 42);
      final snapshot = buildWidgetSnapshot([
        Countdown(id: 7, title: 'Trip', dateTime: DateTime(2027, 3, 14)),
      ], DateTime(2026, 11, 21));
      expect(
        ((snapshot['events']! as List).single as Map)['link'],
        'countdowns://event/7',
      );
    });

    test('an existing countdown opens its detail over Home', () async {
      expect(
        await widgetLinkRedirect(
          Uri.parse('countdowns://event/5'),
          (id) => only(id, 5),
        ),
        '/event/5',
      );
    });

    test('a deleted countdown or a bad link falls back to Home', () async {
      for (final link in [
        'countdowns://event/9',
        'countdowns://event/',
        'countdowns://event/abc',
        'countdowns://event/5/extra',
        'countdowns://settings',
        // A widget drawn by an older build can hand over Glance's own URI.
        'glance-action:/abc',
      ]) {
        expect(
          await widgetLinkRedirect(Uri.parse(link), (id) => only(id, 5)),
          '/',
          reason: link,
        );
      }
    });

    test('ordinary navigation is left alone', () async {
      for (final path in ['/', '/event/5', '/settings', '/new?title=x']) {
        expect(
          await widgetLinkRedirect(Uri.parse(path), (_) async => false),
          isNull,
          reason: path,
        );
      }
    });
  });

  group('opening the app from a widget', () {
    late AppDatabase db;

    Future<void> pumpApp(WidgetTester tester) async {
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
        'localSettings': jsonEncode({'themeMode': 2}),
      });
      final prefs = await SharedPreferences.getInstance();
      db = AppDatabase(NativeDatabase.memory());
      await tester.runAsync(
        () => db.saveCountdown(
          Countdown(title: 'Japan trip', dateTime: DateTime(2099, 3, 14)),
        ),
      );
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
    }

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 3; i++) {
        // Drift streams and the async redirect resolve on real async work.
        await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 400));
      }
    }

    /// What the engine sends when the OS opens a URL in a running app.
    Future<void> openLink(WidgetTester tester, String url) async {
      final message = const JSONMethodCodec().encodeMethodCall(
        MethodCall('pushRouteInformation', {'location': url, 'state': null}),
      );
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/navigation',
        message,
        (_) {},
      );
      await settle(tester);
    }

    /// Unmount first so Drift's streams close, then close the database.
    Future<void> finish(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      final closing = db.close();
      await tester.pump(const Duration(seconds: 1));
      await closing;
    }

    bool onDetail() => find.text('days to go').evaluate().isNotEmpty;

    testWidgets('a running app goes to the countdown, back returns Home', (
      tester,
    ) async {
      await pumpApp(tester);
      await settle(tester);
      expect(find.text('Countdowns'), findsWidgets);
      expect(onDetail(), isFalse);

      final id = (await tester.runAsync(db.allCountdowns))!.single.id!;
      await openLink(tester, 'countdowns://event/$id');
      expect(onDetail(), isTrue);
      expect(find.text('Japan trip'), findsWidgets);

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(onDetail(), isFalse);
      await finish(tester);
    });

    testWidgets('a deleted countdown falls back to Home', (tester) async {
      await pumpApp(tester);
      await settle(tester);
      await openLink(tester, 'countdowns://event/999');
      expect(onDetail(), isFalse);
      expect(find.text('Japan trip'), findsWidgets);
      expect(find.text('Page No Found'), findsNothing);
      await finish(tester);
    });

    testWidgets('a cold start opens straight on the countdown', (tester) async {
      // The engine passes the launch URL as the initial route.
      tester.platformDispatcher.defaultRouteNameTestValue =
          'countdowns://event/1';
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
      await pumpApp(tester);
      await settle(tester);
      expect(onDetail(), isTrue);
      expect(find.text('Japan trip'), findsWidgets);
      await finish(tester);
    });
  });
}
