import 'dart:convert';
import 'dart:io';

import 'package:countdowns/fonts/font_catalog.dart';
import 'package:countdowns/fonts/font_library.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/widgets_bridge/widget_snapshot.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('catalogue', () {
    late FontCatalog catalog;
    setUpAll(() async {
      catalog = FontCatalog.parse(File(FontCatalog.asset).readAsStringSync());
    });

    test('has the families the old bundled fonts move to', () {
      for (final legacy in ['Roboto', ...legacyEventFonts.keys]) {
        final family = canonicalEventFont(legacy);
        expect(catalog[family], isNotNull, reason: family);
      }
      expect(catalog['Libre Baskerville']!.category, FontCategory.serif);
      expect(catalog['Libre Baskerville']!.weight, 700);
      // Only one weight exists, so that's the one.
      expect(catalog['Luxurious Roman']!.weight, 400);
    });

    test('is large, popular first, with checkable addresses', () {
      expect(catalog.fonts.length, greaterThan(1500));
      expect(catalog.fonts.first.family, 'Roboto');
      final names = catalog.fonts.map((f) => f.family).toSet();
      expect(names.length, catalog.fonts.length);
      for (final f in catalog.fonts) {
        expect(f.hash, matches(RegExp(r'^[0-9a-f]{64}$')));
      }
      // Bundled keys never collide with a Google family.
      for (final b in bundledEventFonts) {
        expect(catalog[b.family], isNull, reason: b.family);
      }
    });

    test('search puts names that start with the query first', () {
      final hits = catalog.matching('mono');
      expect(hits.first.family.toLowerCase(), startsWith('mono'));
      expect(hits.any((f) => f.family == 'Roboto Mono'), isTrue);
      final serif = catalog.matching('', category: FontCategory.serif);
      expect(serif.every((f) => f.category == FontCategory.serif), isTrue);
    });
  });

  test('event font keys: legacy names read as their Google family', () {
    expect(canonicalEventFont('LibreBaskerville'), 'Libre Baskerville');
    expect(canonicalEventFont('ComicNeue'), 'Comic Neue');
    expect(canonicalEventFont(''), 'Default');
    expect(isGoogleEventFont('Default'), isFalse);
    expect(isGoogleEventFont('NewWaltDisney'), isFalse);
    expect(isGoogleEventFont('Roboto'), isTrue);
    expect(eventFontLabel('Starjedi'), 'Not Starwars');
    expect(eventFontLabel('LuxuriousRoman'), 'Luxurious Roman');
    expect(resolveEventFont('Default'), AppFonts.numerals);
    expect(resolveEventFont('GoodTimes'), 'GoodTimes');
    expect(resolveEventFont('ComicNeue'), 'gf:Comic Neue');
  });

  group('library', () {
    // A real font file stands in for Google's.
    final bytes = File('fonts/Inter-700.ttf').readAsBytesSync();
    final font = GoogleFont(
      family: 'Test Sans',
      category: FontCategory.sans,
      weight: 700,
      hash: sha256.convert(bytes).toString(),
      length: bytes.length,
    );
    final catalog = FontCatalog([font]);

    late Directory root;
    late List<Uri> requests;
    final library = FontLibrary.instance;

    void setUpWith(Future<http.Response> Function(http.Request) handler) {
      library.setUp(
        installed: Directory('${root.path}/widget/fonts'),
        cache: Directory('${root.path}/cache'),
        client: MockClient((r) {
          requests.add(r.url);
          return handler(r);
        }),
        catalog: () async => catalog,
      );
    }

    setUp(() {
      root = Directory.systemTemp.createTempSync('fonts');
      requests = [];
      library.reset();
    });

    tearDown(() {
      library.reset();
      root.deleteSync(recursive: true);
    });

    test('does nothing before setup (tests, other platforms)', () async {
      expect(await library.use('Test Sans'), isFalse);
      expect(await library.preview('Test Sans'), isFalse);
    });

    test('a countdown font downloads once, checked, into the widget '
        'folder, and loads', () async {
      setUpWith((_) async => http.Response.bytes(bytes, 200));
      var installed = 0;
      library.onInstalled = () => installed++;
      expect(await library.use('Test Sans'), isTrue);
      expect(await library.use('Test Sans'), isTrue);
      expect(requests, [font.url]);
      expect(installed, 1);
      expect(library.isLoaded('Test Sans'), isTrue);
      final file = File('${root.path}/widget/fonts/Test_Sans.ttf');
      expect(file.readAsBytesSync(), bytes);
      expect(await library.installedFile('Test Sans'), isNotNull);
    });

    test('a preview stays in the cache until a countdown uses it', () async {
      setUpWith((_) async => http.Response.bytes(bytes, 200));
      expect(await library.preview('Test Sans'), isTrue);
      expect(File('${root.path}/cache/Test_Sans.ttf').existsSync(), isTrue);
      expect(await library.installedFile('Test Sans'), isNull);
      // Using it moves it across without downloading again.
      expect(await library.use('Test Sans'), isTrue);
      expect(requests, hasLength(1));
      expect(await library.installedFile('Test Sans'), isNotNull);
    });

    test('a file that fails its checksum is never kept', () async {
      setUpWith(
        (_) async => http.Response.bytes([...bytes.take(100), 0, 0], 200),
      );
      expect(await library.use('Test Sans'), isFalse);
      expect(library.failed('Test Sans'), isTrue);
      expect(Directory('${root.path}/widget/fonts').existsSync(), isFalse);
      expect(Directory('${root.path}/cache').existsSync(), isFalse);
    });

    test('offline fails quietly and waits before trying again', () async {
      setUpWith((_) async => throw const SocketException('offline'));
      expect(await library.use('Test Sans'), isFalse);
      expect(library.offline, isTrue);
      expect(await library.use('Test Sans'), isFalse);
      expect(requests, hasLength(1));
    });

    test('pruning moves fonts no countdown uses back to the cache', () async {
      setUpWith((_) async => http.Response.bytes(bytes, 200));
      await library.use('Test Sans');
      await library.prune({'Other'});
      expect(await library.installedFile('Test Sans'), isNull);
      expect(File('${root.path}/cache/Test_Sans.ttf').existsSync(), isTrue);
      await library.use('Test Sans');
      expect(requests, hasLength(1));
    });

    test('the widget writer installs a countdown\'s Google font and points '
        'the snapshot at it', () async {
      setUpWith((_) async => http.Response.bytes(bytes, 200));
      const channel = MethodChannel('countdowns/widgets');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'containerPath' ? root.path : null,
      );
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() {
        messenger.setMockMethodCallHandler(channel, null);
        debugDefaultTargetPlatformOverride = null;
      });
      // Installed earlier for a countdown that's since been deleted.
      File('${root.path}/widget/fonts/Gone.ttf')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);

      await WidgetSnapshotWriter(clock: () => DateTime(2026, 11, 22)).write([
        Countdown(
          id: 1,
          title: 'Party',
          dateTime: DateTime(2026, 12, 31),
          fontFamily: 'Test Sans',
        ),
        Countdown(id: 2, title: 'Trip', dateTime: DateTime(2027, 1, 5)),
      ]);
      final json = jsonDecode(
        File('${root.path}/widget/snapshot.json').readAsStringSync(),
      ) as Map;
      final events = (json['events'] as List).cast<Map>();
      expect(events[0]['font'], 'Test Sans');
      expect(events[0]['fontFile'], 'fonts/Test_Sans.ttf');
      expect(events[1]['fontFile'], isNull);
      expect(
        File('${root.path}/widget/fonts/Test_Sans.ttf').existsSync(),
        isTrue,
      );
      expect(File('${root.path}/widget/fonts/Gone.ttf').existsSync(), isFalse);
    });

    test('offline, the snapshot leaves the file out so widgets use '
        'Default', () async {
      setUpWith((_) async => throw const SocketException('offline'));
      const channel = MethodChannel('countdowns/widgets');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'containerPath' ? root.path : null,
      );
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() {
        messenger.setMockMethodCallHandler(channel, null);
        debugDefaultTargetPlatformOverride = null;
      });
      await WidgetSnapshotWriter(clock: () => DateTime(2026, 11, 22)).write([
        Countdown(
          id: 1,
          title: 'Party',
          dateTime: DateTime(2026, 12, 31),
          fontFamily: 'Test Sans',
        ),
      ]);
      final json = jsonDecode(
        File('${root.path}/widget/snapshot.json').readAsStringSync(),
      ) as Map;
      expect((json['events'] as List).single['fontFile'], isNull);
    });
  });
}
