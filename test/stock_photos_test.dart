import 'dart:convert';
import 'dart:io';

import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/screens/editor/photos_tab.dart';
import 'package:countdowns/stock/cloudflare_photo_source.dart';
import 'package:countdowns/stock/manifest_store.dart';
import 'package:countdowns/stock/stock_categories.dart';
import 'package:countdowns/stock/stock_manifest.dart';
import 'package:countdowns/stock/stock_photo_source.dart';
import 'package:countdowns/stock/stock_provider.dart';
import 'package:countdowns/stock/stock_recents.dart';
import 'package:countdowns/storage/photo_credits.dart';
import 'package:countdowns/storage/photos.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, Object?> manifestJson({
  int schema = 1,
  bool enabled = true,
  List<Map<String, Object?>>? photos,
}) => {
  'schema': schema,
  'version': 3,
  'generatedAt': '2026-11-22T14:00:00Z',
  'baseUrl': 'https://media.countdowns.stayte.app',
  'enabled': enabled,
  'categories': {
    'christmas': {'cover': 'p_2'},
  },
  'somethingNew': {'ignored': true},
  'photos':
      photos ??
      [
        {
          'id': 'p_1',
          'categories': ['christmas', 'winter'],
          'w': 2560,
          'h': 3840,
          'color': '#7A4E3B',
          'blurhash': 'L@Mr0Vo0WCt6}?jsjZoeSgj[oeWC',
          'focal': {'x': 0.5, 'y': 0.35},
          'files': {
            'thumb': 'p/p_1/3f9a1c2e.thumb.webp',
            'full': 'p/p_1/8b10d7aa.full.jpg',
          },
          'credit': {
            'name': 'Ana',
            'url': 'https://example.com/ana',
            'page': 'https://example.com/page',
          },
          'license': 'CC0-1.0',
          'tags': ['tree', 'lights'],
          'added': '2026-11-22',
          'hidden': false,
          'futureField': 7,
        },
        // Only the required fields.
        {
          'id': 'p_2',
          'categories': ['christmas'],
          'w': 3000,
          'h': 2000,
          'files': {'thumb': 'p/p_2/a.thumb.webp', 'full': 'p/p_2/b.full.jpg'},
        },
        {
          'id': 'p_3',
          'categories': ['birthday'],
          'w': 2000,
          'h': 2000,
          'tags': ['cake', 'candles'],
          'files': {'thumb': 'p/p_3/a.thumb.webp', 'full': 'p/p_3/b.full.jpg'},
        },
        {
          'id': 'p_hidden',
          'categories': ['christmas'],
          'w': 10,
          'h': 10,
          'files': {'thumb': 'x', 'full': 'y'},
          'hidden': true,
        },
        // Malformed: skipped, not fatal.
        {
          'id': 'p_bad',
          'categories': ['christmas'],
        },
        'not even a map',
      ],
};

StockManifest manifest([Map<String, Object?>? j]) =>
    StockManifest.parse(j ?? manifestJson());

StockPhoto photo(
  String id, {
  String? blurHash,
  Color? colour,
  int w = 3000,
  int h = 2000,
}) => StockPhoto(
  id: id,
  thumbnailUrl: 'test://$id',
  fullUrl: 'test://full/$id',
  width: w,
  height: h,
  blurHash: blurHash,
  averageColor: colour,
  photographer: 'Ana $id',
);

void main() {
  group('manifest', () {
    test('parses fields and builds URLs from baseUrl', () {
      final m = manifest();
      expect(m.version, 3);
      expect(m.enabled, isTrue);
      expect(m.covers, {'christmas': 'p_2'});
      expect(m.photos.map((p) => p.id), ['p_1', 'p_2', 'p_3']);
      final p1 = m.photos.first;
      expect(
        p1.thumbnailUrl,
        'https://media.countdowns.stayte.app/p/p_1/3f9a1c2e.thumb.webp',
      );
      expect(
        p1.fullUrl,
        'https://media.countdowns.stayte.app/p/p_1/8b10d7aa.full.jpg',
      );
      expect((p1.width, p1.height), (2560, 3840));
      expect(p1.averageColor, const Color(0xFF7A4E3B));
      expect(p1.blurHash, isNotNull);
      expect(p1.focal, const Offset(0.5, 0.35));
      expect(p1.photographer, 'Ana');
      expect(p1.pageUrl, 'https://example.com/page');
      expect(p1.license, 'CC0-1.0');
      expect(p1.tags, ['tree', 'lights']);
    });

    test('missing optional fields are fine', () {
      final p2 = manifest().photos[1];
      expect(p2.averageColor, isNull);
      expect(p2.blurHash, isNull);
      expect(p2.focal, isNull);
      expect(p2.photographer, '');
      expect(p2.license, '');
      expect(p2.tags, isEmpty);
    });

    test('an unknown schema is refused (the cached copy stays)', () {
      expect(
        () => manifest(manifestJson(schema: 2)),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => StockManifest.parse({'photos': []}),
        throwsA(isA<FormatException>()),
      );
    });

    test('the live empty catalogue reads as switched off', () {
      // catalog/v1/manifest.json as first published.
      final m = StockManifest.parse({
        'schema': 1,
        'version': 1,
        'generatedAt': '2026-11-22T15:21:20.087Z',
        'baseUrl': 'https://media.countdowns.stayte.app/',
        'enabled': false,
        'categories': <String, Object?>{},
        'photos': <Object?>[],
      });
      expect(m.enabled, isFalse);
      expect(m.photos, isEmpty);
    });
  });

  group('Cloudflare source', () {
    CloudflarePhotoSource source(StockManifest m) => CloudflarePhotoSource(
      manifest: () async => m,
      downloads: Directory.systemTemp,
    );

    test('categories: only ones with photos, in the app’s order', () async {
      final cats = await source(manifest()).categories();
      expect(cats.map((c) => c.id), ['christmas', 'winter', 'birthday']);
    });

    test('the cover leads its category; hidden photos never show', () async {
      final xmas = stockCategories.firstWhere((c) => c.id == 'christmas');
      final page = await source(manifest()).photos(xmas, 1);
      expect(page.photos.map((p) => p.id), ['p_2', 'p_1']);
    });

    test('pages of 30', () async {
      final many = [
        for (var i = 0; i < 70; i++)
          {
            'id': 'p_$i',
            'categories': ['beach'],
            'w': 3,
            'h': 2,
            'files': {'thumb': 't', 'full': 'f'},
          },
      ];
      final s = source(manifest(manifestJson(photos: many)));
      final beach = stockCategories.firstWhere((c) => c.id == 'beach');
      final p1 = await s.photos(beach, 1), p3 = await s.photos(beach, 3);
      expect(p1.photos, hasLength(30));
      expect(p1.hasMore, isTrue);
      expect(p3.photos, hasLength(10));
      expect(p3.hasMore, isFalse);
    });

    test('enabled: false switches stock off', () async {
      final s = source(manifest(manifestJson(enabled: false)));
      expect(await s.categories(), isEmpty);
      expect((await s.search('tree', 1)).photos, isEmpty);
    });

    test('search matches tags and category words, all words', () {
      final ps = manifest().photos;
      List<String> ids(String q) => [
        for (final p in searchPhotos(ps, q, stockCategories)) p.id,
      ];
      expect(ids('tree'), ['p_1']);
      expect(ids('xmas'), ['p_1', 'p_2']); // a Christmas keyword
      expect(ids('cake'), ['p_3']);
      expect(ids('cake snow'), isEmpty);
      expect(ids(' '), isEmpty);
    });

    test('a manifest failure surfaces as unavailable', () async {
      final s = CloudflarePhotoSource(
        manifest: () async => throw const SocketException('offline'),
        downloads: Directory.systemTemp,
      );
      expect(s.categories(), throwsA(isA<StockUnavailable>()));
    });
  });

  group('manifest store', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('manifest'));
    tearDown(() => dir.deleteSync(recursive: true));

    final url = Uri.parse('https://media.example/catalog/v1/manifest.json');

    test('404 with nothing cached throws (the tab hides stock)', () async {
      final store = ManifestStore(
        url: url,
        directory: dir,
        client: MockClient((_) async => http.Response('', 404)),
      );
      expect(store.load(), throwsA(isA<HttpException>()));
    });

    test('caches, revalidates with ETag, and works offline', () async {
      var now = DateTime(2026, 11, 22, 9);
      final seen = <Map<String, String>>[];
      var online = true;
      ManifestStore store() => ManifestStore(
        url: url,
        directory: dir,
        clock: () => now,
        client: MockClient((r) async {
          seen.add(r.headers);
          if (!online) throw const SocketException('offline');
          if (r.headers['If-None-Match'] == '"v3"') {
            return http.Response('', 304);
          }
          return http.Response(
            jsonEncode(manifestJson()),
            200,
            headers: {'etag': '"v3"'},
          );
        }),
      );
      expect((await store().load()).version, 3);
      expect(seen, hasLength(1));
      // Within 6 hours: no request at all.
      now = now.add(const Duration(hours: 5));
      await store().load();
      expect(seen, hasLength(1));
      // Later: revalidates; a 304 keeps the cached copy.
      now = now.add(const Duration(hours: 2));
      expect((await store().load()).photos, hasLength(3));
      expect(seen.last['If-None-Match'], '"v3"');
      // Offline later still: the cached copy.
      now = now.add(const Duration(hours: 7));
      online = false;
      expect((await store().load()).version, 3);
    });

    test('a bad publish (unknown schema) keeps the cached copy', () async {
      var body = jsonEncode(manifestJson());
      var now = DateTime(2026, 11, 22);
      ManifestStore store() => ManifestStore(
        url: url,
        directory: dir,
        clock: () => now,
        client: MockClient((_) async => http.Response(body, 200)),
      );
      await store().load();
      body = jsonEncode(manifestJson(schema: 9));
      now = now.add(const Duration(days: 1));
      expect((await store().load()).schema, 1);
    });
  });

  group('placeholders', () {
    test('blurhash, then colour, then Wash', () {
      expect(
        placeholderFor(
          photo(
            'a',
            blurHash: 'L@Mr0Vo0WCt6}?jsjZoeSgj[oeWC',
            colour: Colors.red,
          ),
        ),
        PlaceholderKind.blurHash,
      );
      // A malformed hash falls through to the colour.
      expect(
        placeholderFor(photo('b', blurHash: 'L@Mr0', colour: Colors.red)),
        PlaceholderKind.colour,
      );
      expect(placeholderFor(photo('c')), PlaceholderKind.wash);
    });

    test('tiles keep the photo’s aspect ratio', () {
      expect(stockTileWidth(photo('w', w: 3, h: 2)), closeTo(198, 0.01));
      expect(stockTileWidth(photo('t', w: 2, h: 3)), closeTo(88, 0.01));
      // Extremes are clamped so one photo can't take the whole row.
      expect(stockTileWidth(photo('pano', w: 10, h: 1)), 260);
    });
  });

  group('recently used', () {
    test('newest first, no duplicates, at most 15', () {
      var list = <StockPhoto>[];
      for (var i = 0; i < 20; i++) {
        list = pushRecent(list, photo('p$i'));
      }
      expect(list, hasLength(stockRecentsLimit));
      expect(list.first.id, 'p19');
      expect(list.last.id, 'p5');
      list = pushRecent(list, photo('p10'));
      expect(list.first.id, 'p10');
      expect(list.where((p) => p.id == 'p10'), hasLength(1));
      expect(list, hasLength(15));
    });

    test('survive a round trip through JSON', () {
      final p = manifest().photos.first;
      final back = StockPhoto.fromJson(
        (jsonDecode(jsonEncode(p.toJson())) as Map).cast<String, Object?>(),
      )!;
      expect(back.id, p.id);
      expect(back.fullUrl, p.fullUrl);
      expect(back.focal, p.focal);
      expect(back.blurHash, p.blurHash);
      expect(back.localPath, isNull);
      final saved = StockPhoto.fromJson(
        (jsonDecode(
          jsonEncode(p.withLocalPath('photos/1.jpg').toJson()),
        ) as Map).cast<String, Object?>(),
      )!;
      expect(saved.localPath, 'photos/1.jpg');
      expect(saved.focal, p.focal);
      expect(StockPhoto.fromJson({'id': 1}), isNull);
    });
  });

  group('category order', () {
    List<String> top(DateTime now, {DateTime? event, String title = ''}) =>
        orderCategories(
          stockCategories,
          now,
          eventDate: event,
          title: title,
        ).take(4).map((c) => c.id).toList();

    test('late November: Thanksgiving, Christmas, Winter, New Year', () {
      expect(top(DateTime(2026, 11, 22)), [
        'thanksgiving',
        'christmas',
        'winter',
        'new-year',
      ]);
    });

    test('other seasons lead in their windows', () {
      expect(top(DateTime(2027, 2, 1)).first, 'valentines');
      expect(top(DateTime(2026, 10, 10)).first, 'halloween');
      expect(top(DateTime(2027, 7, 4)).first, 'summer');
      expect(top(DateTime(2027, 3, 20)).first, 'easter');
      expect(
        top(DateTime(2027, 1, 3)).take(2),
        unorderedEquals(['winter', 'new-year']),
      );
    });

    test('title and event date boost categories', () {
      expect(top(DateTime(2027, 7, 4), title: 'Japan trip').take(2), [
        'vacation',
        'city',
      ]);
      expect(
        top(DateTime(2027, 7, 4), event: DateTime(2027, 12, 25)).first,
        'christmas',
      );
      expect(
        top(DateTime(2027, 7, 4), title: 'Toured'),
        isNot(contains('concert')),
      );
    });
  });

  group('download then treat as local', () {
    test('imports with its credit, id and licence', () async {
      final root = Directory.systemTemp.createTempSync('store');
      addTearDown(() => root.deleteSync(recursive: true));
      PhotoStore.setUp(root);
      final download = File('${root.path}/dl.jpg')..writeAsBytesSync([9, 9]);
      final p = manifest().photos.first;
      final path = await importStockPhoto(download, p);
      expect(PhotoStore.instance.fileFor(path).readAsBytesSync(), [9, 9]);
      expect(download.existsSync(), isFalse);
      final credit = PhotoCredit.read(path)!;
      expect(credit.photographer, 'Ana');
      expect(credit.id, 'p_1');
      expect(credit.license, 'CC0-1.0');
    });

    test('the focal point becomes the starting crop', () {
      final crops = const ImportedPhoto(
        'x',
        focal: Offset(0.75, 0.25),
      ).startCrops;
      final pt = crops.pointFor(CropShape.card);
      expect(pt.x, closeTo(0.5, 1e-9));
      expect(pt.y, closeTo(-0.5, 1e-9));
      expect(const ImportedPhoto('x').startCrops.points, isEmpty);
    });
  });

  group('Photos tab', () {
    late Directory root;
    ImportedPhoto? imported;

    setUp(() {
      root = Directory.systemTemp.createTempSync('tab');
      PhotoStore.setUp(root);
      imported = null;
    });
    tearDown(() => root.deleteSync(recursive: true));

    Future<ProviderContainer> pump(
      WidgetTester tester,
      StockPhotoSource? source, {
      Map<String, Object> prefsValues = const {},
    }) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'localSettings': jsonEncode({'hapticFeedback': false, 'sound': false}),
        ...prefsValues,
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          stockPhotoSourceProvider.overrideWithValue(source),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: PhotosTab(
                draft: Countdown(
                  id: 1,
                  title: 'Mia’s birthday',
                  dateTime: DateTime(2027, 2, 3),
                ),
                photos: const [],
                selected: 'colour:FF7877E6',
                onPick: (_) {},
                onAdd: () {},
                onImported: (p) => imported = p,
                now: DateTime(2026, 11, 22),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    CloudflarePhotoSource source() => CloudflarePhotoSource(
      manifest: () async => manifest(),
      downloads: root,
      client: MockClient((_) async => http.Response.bytes([1, 2, 3], 200)),
    );

    testWidgets('rows by category: title, event date, then today’s season', (
      tester,
    ) async {
      await pump(tester, source());
      final headings = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .where((d) => d == 'BIRTHDAY' || d == 'CHRISTMAS' || d == 'WINTER')
          .toList();
      // Birthday from the title, Winter from the date (Feb 3), then today's
      // season (late November: Christmas).
      expect(headings, ['BIRTHDAY', 'WINTER', 'CHRISTMAS']);
      expect(find.byKey(const ValueKey('stock-recents')), findsNothing);
      expect(find.byKey(const ValueKey('stock-search')), findsOneWidget);
    });

    /// Nothing but Your photos: no message, search, heading or spinner.
    void expectNoStock() {
      expect(find.text('YOUR PHOTOS'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const ValueKey('stock-search')), findsNothing);
      expect(find.byKey(const ValueKey('stock-recents')), findsNothing);
      expect(find.textContaining('unavailable'), findsNothing);
    }

    testWidgets('unreachable and nothing cached: as if it never existed', (
      tester,
    ) async {
      await pump(
        tester,
        CloudflarePhotoSource(
          manifest: () async => throw const SocketException('offline'),
          downloads: root,
        ),
        // Picked before but its copy is gone: needs the network, so hidden.
        prefsValues: {
          'recentStockPhotos': jsonEncode([
            manifest().photos.first.withLocalPath('photos/gone.jpg').toJson(),
          ]),
        },
      );
      expectNoStock();
      expect(tester.widgetList<Text>(find.byType(Text)).map((t) => t.data), [
        'YOUR PHOTOS',
      ]);
    });

    testWidgets('switched off: no stock at all', (tester) async {
      await pump(
        tester,
        CloudflarePhotoSource(
          manifest: () async => manifest(manifestJson(enabled: false)),
          downloads: root,
        ),
      );
      expectNoStock();
    });

    testWidgets('offline, downloaded recents stay and work', (tester) async {
      final stored = File('${root.path}/photos/kept.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync([1, 2, 3]);
      expect(stored.existsSync(), isTrue);
      final container = await pump(
        tester,
        CloudflarePhotoSource(
          manifest: () async => throw const SocketException('offline'),
          downloads: root,
          client: MockClient((_) async => throw const SocketException('x')),
        ),
        prefsValues: {
          'recentStockPhotos': jsonEncode([
            manifest().photos.first.withLocalPath('photos/kept.jpg').toJson(),
            manifest().photos.last.toJson(),
          ]),
        },
      );
      expect(find.text('RECENTLY USED'), findsOneWidget);
      expect(find.byKey(const ValueKey('stock-search')), findsNothing);
      // Only the one on the device.
      expect(find.bySemanticsLabel(RegExp('^Photo')), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Photo by Ana'));
      await tester.pumpAndSettle();
      expect(imported?.path, 'photos/kept.jpg');
      expect(imported?.focal, const Offset(0.5, 0.35));
      expect(container.read(stockRecentsProvider).first.id, 'p_1');
    });

    testWidgets('search filters on the device', (tester) async {
      await pump(tester, source());
      await tester.enterText(
        find.byKey(const ValueKey('stock-search')),
        'candles',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('RESULTS FOR “CANDLES”'), findsOneWidget);
      expect(find.text('BIRTHDAY'), findsNothing);
    });

    testWidgets('picking downloads, imports, remembers and hands over', (
      tester,
    ) async {
      final container = await pump(tester, source());
      await tester.tap(find.bySemanticsLabel('Photo by Ana').first);
      for (var i = 0; i < 40 && imported == null; i++) {
        await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(imported, isNotNull);
      expect(imported!.focal, const Offset(0.5, 0.35));
      expect(PhotoCredit.read(imported!.path)!.id, 'p_1');
      expect(container.read(stockRecentsProvider).first.id, 'p_1');
      expect(
        container.read(stockRecentsProvider).first.localPath,
        imported!.path,
      );
      // The prefs carry it to the next launch.
      final saved = container
          .read(preferencesProvider)
          .getString('recentStockPhotos');
      expect(saved, contains('p_1'));
    });

    testWidgets('recently used shows when there are any', (tester) async {
      await pump(
        tester,
        source(),
        prefsValues: {
          'recentStockPhotos': jsonEncode([manifest().photos.last.toJson()]),
        },
      );
      expect(find.text('RECENTLY USED'), findsOneWidget);
      expect(find.byKey(const ValueKey('stock-recents')), findsOneWidget);
    });
  });
}
