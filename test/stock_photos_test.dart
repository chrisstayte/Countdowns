import 'dart:convert';
import 'dart:io';

import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/screens/editor/photos_tab.dart';
import 'package:countdowns/stock/pexels_photo_source.dart';
import 'package:countdowns/stock/stock_cache.dart';
import 'package:countdowns/stock/stock_categories.dart';
import 'package:countdowns/stock/stock_photo_source.dart';
import 'package:countdowns/stock/stock_provider.dart';
import 'package:countdowns/storage/photo_credits.dart';
import 'package:countdowns/storage/photos.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

StockPhoto photo(int i) => StockPhoto(
  id: 'fake-$i',
  thumbnailUrl: 'test://$i',
  fullUrl: 'test://full/$i',
  width: 3000,
  height: 2000,
  averageColor: const Color(0xFF7877E6),
  photographer: 'Ana $i',
  photographerUrl: 'https://example.com/ana',
  pageUrl: 'https://example.com/photo/$i',
);

/// A source for widget tests: no network, records what was asked.
class FakeSource extends StockPhotoSource {
  FakeSource(this.dir);
  final Directory dir;
  final asked = <String>[];
  Object? failSearchWith;

  @override
  String get attribution => 'Photos provided by Fake';
  @override
  Uri get attributionUrl => Uri.parse('https://example.com');

  @override
  Future<StockPage> photos(StockCategory c, int page) async {
    asked.add('category:${c.id}:$page');
    return StockPage([
      for (var i = 0; i < 8; i++) photo(page * 100 + i),
    ], hasMore: page < 2);
  }

  @override
  Future<StockPage> search(String q, int page) async {
    asked.add('search:$q:$page');
    if (failSearchWith != null) throw failSearchWith!;
    return StockPage([photo(900)], hasMore: false);
  }

  @override
  Future<File> download(
    StockPhoto p, {
    void Function(double? progress)? onProgress,
  }) async {
    onProgress?.call(0.5);
    final f = File('${dir.path}/${p.id}.jpg')..writeAsBytesSync([1, 2, 3]);
    onProgress?.call(1);
    return f;
  }
}

void main() {
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
      expect(top(DateTime(2027, 2, 1)), contains('winter'));
      expect(top(DateTime(2026, 10, 10)).first, 'halloween');
      expect(top(DateTime(2027, 7, 4)).first, 'summer');
      expect(top(DateTime(2027, 3, 20)).first, 'easter');
      // New Year runs past the year end.
      expect(
        top(DateTime(2027, 1, 3)).take(2),
        unorderedEquals(['winter', 'new-year']),
      );
    });

    test('the title boosts matching categories', () {
      final ids = top(DateTime(2027, 7, 4), title: 'Japan trip');
      expect(ids.take(2), ['vacation', 'city']);
      expect(
        top(DateTime(2027, 7, 4), title: 'Mia’s birthday').first,
        'birthday',
      );
      // Whole words only: "Toured" is not "tour".
      expect(
        top(DateTime(2027, 7, 4), title: 'Toured'),
        isNot(contains('concert')),
      );
    });

    test('the event date boosts its season', () {
      final ids = top(DateTime(2027, 7, 4), event: DateTime(2027, 12, 25));
      expect(ids.first, 'christmas');
    });
  });

  group('cache', () {
    test('pages last 24 hours', () async {
      final dir = Directory.systemTemp.createTempSync('cache');
      addTearDown(() => dir.deleteSync(recursive: true));
      var now = DateTime(2026, 11, 22, 9);
      final cache = StockCache(dir, clock: () => now);
      await cache.write('k', {'a': 1});
      now = now.add(const Duration(hours: 23));
      expect(await cache.read('k'), {'a': 1});
      now = now.add(const Duration(hours: 2));
      expect(await cache.read('k'), isNull);
    });
  });

  group('Pexels source', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('pexels'));
    tearDown(() => dir.deleteSync(recursive: true));

    String body({bool more = true}) => jsonEncode({
      'page': 1,
      'photos': [
        {
          'id': 42,
          'width': 4000,
          'height': 3000,
          'url': 'https://www.pexels.com/photo/42/',
          'photographer': 'Kim',
          'photographer_url': 'https://www.pexels.com/@kim',
          'avg_color': '#7A6B5C',
          'src': {
            'original': 'https://images.pexels.com/photos/42/a.jpeg',
            'medium': 'https://images.pexels.com/photos/42/a.jpeg?h=350',
          },
        },
      ],
      if (more) 'next_page': 'https://api.pexels.com/v1/search?page=2',
    });

    PexelsPhotoSource source(MockClient client) => PexelsPhotoSource(
      apiKey: 'test-key',
      cache: StockCache(Directory('${dir.path}/pages')),
      downloads: Directory('${dir.path}/downloads'),
      client: client,
    );

    test('sends only the query, page and key; maps the result', () async {
      final requests = <http.Request>[];
      final s = source(
        MockClient((r) async {
          requests.add(r);
          return http.Response(body(), 200);
        }),
      );
      final page = await s.search('Snowy Cabin', 1);
      final r = requests.single;
      expect(r.url.host, 'api.pexels.com');
      expect(r.url.queryParameters, {
        'query': 'snowy cabin',
        'page': '1',
        'per_page': '30',
      });
      expect(r.headers['Authorization'], 'test-key');
      final p = page.photos.single;
      expect(p.id, 'pexels-42');
      expect(p.photographer, 'Kim');
      expect(p.averageColor, const Color(0xFF7A6B5C));
      expect(p.fullUrl, contains('w=2000'));
      expect(page.hasMore, isTrue);
    });

    test('a repeat request in 24 hours comes from the cache', () async {
      var calls = 0;
      final s = source(
        MockClient((_) async {
          calls++;
          return http.Response(body(more: false), 200);
        }),
      );
      await s.search('beach', 1);
      final again = await s.search('Beach ', 1);
      expect(calls, 1);
      expect(again.photos.single.id, 'pexels-42');
      expect(again.hasMore, isFalse);
    });

    test('429 is a rate limit, other errors are unavailable', () async {
      expect(
        source(MockClient((_) async => http.Response('', 429))).search('x', 1),
        throwsA(isA<StockRateLimited>()),
      );
      expect(
        source(MockClient((_) async => http.Response('', 500))).search('x', 1),
        throwsA(isA<StockUnavailable>()),
      );
    });

    test('download streams to a file with progress', () async {
      final progress = <double?>[];
      final s = source(
        MockClient.streaming((r, _) async {
          expect(r.url.toString(), contains('w=2000'));
          return http.StreamedResponse(
            Stream.fromIterable([
              [1, 2],
              [3, 4],
            ]),
            200,
            contentLength: 4,
          );
        }),
      );
      final page = await source(
        MockClient((_) async => http.Response(body(), 200)),
      ).search('a', 1);
      final f = await s.download(page.photos.single, onProgress: progress.add);
      expect(await f.readAsBytes(), [1, 2, 3, 4]);
      expect(progress, [0.5, 1.0]);
    });
  });

  group('download then treat as local', () {
    test('imports into the photo store with its credit', () async {
      final root = Directory.systemTemp.createTempSync('store');
      addTearDown(() => root.deleteSync(recursive: true));
      PhotoStore.setUp(root);
      final download = File('${root.path}/dl.jpg')..writeAsBytesSync([9, 9]);
      final path = await importStockPhoto(download, photo(1), 'Pexels');
      expect(path, startsWith('photos/'));
      expect(PhotoStore.instance.fileFor(path).readAsBytesSync(), [9, 9]);
      expect(download.existsSync(), isFalse);
      final credit = PhotoCredit.read(path)!;
      expect(credit.photographer, 'Ana 1');
      expect(credit.source, 'Pexels');
      expect(PhotoCredit.read('photos/none.jpg'), isNull);
    });
  });

  group('Photos tab', () {
    late Directory root;
    late FakeSource fake;
    String? imported;

    setUp(() {
      root = Directory.systemTemp.createTempSync('tab');
      PhotoStore.setUp(root);
      fake = FakeSource(root);
      imported = null;
    });
    tearDown(() => root.deleteSync(recursive: true));

    Future<void> pump(WidgetTester tester, {bool withSource = true}) async {
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
          overrides: [
            preferencesProvider.overrideWithValue(prefs),
            stockPhotoSourceProvider.overrideWithValue(
              withSource ? fake : null,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PhotosTab(
                draft: Countdown(
                  id: 1,
                  title: 'Japan trip',
                  dateTime: DateTime(2027, 3, 14),
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
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('no source: only your own photos', (tester) async {
      await pump(tester, withSource: false);
      expect(find.text('YOUR PHOTOS'), findsOneWidget);
      expect(find.text('FREE PHOTOS'), findsNothing);
      expect(find.byKey(const ValueKey('stock-search')), findsNothing);
    });

    testWidgets('categories are ordered and the first one loads', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('FREE PHOTOS'), findsOneWidget);
      expect(find.text('Photos provided by Fake'), findsOneWidget);
      // "Japan trip" → Vacation, City; its date (Mar 14) → Easter; then
      // late November's seasons.
      final labels = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .take(4)
          .toList();
      expect(labels, ['Vacation', 'City', 'Easter', 'Thanksgiving']);
      expect(fake.asked.first, 'category:vacation:1');
      expect(find.bySemanticsLabel('Photo by Ana 100'), findsOneWidget);
    });

    testWidgets('search waits for typing to pause', (tester) async {
      await pump(tester);
      await tester.enterText(
        find.byKey(const ValueKey('stock-search')),
        'snow',
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(fake.asked.where((a) => a.startsWith('search')), isEmpty);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(fake.asked.last, 'search:snow:1');
      expect(find.bySemanticsLabel('Photo by Ana 900'), findsOneWidget);
    });

    testWidgets('a rate limit shows a friendly message', (tester) async {
      fake.failSearchWith = const StockRateLimited();
      await pump(tester);
      await tester.enterText(find.byKey(const ValueKey('stock-search')), 'x');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(find.textContaining('Try again shortly'), findsOneWidget);
    });

    testWidgets('tapping a photo downloads, imports and hands it over', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.bySemanticsLabel('Photo by Ana 101'));
      // The import copies a real file: let real time pass, then pump so the
      // app sees each step finish.
      for (var i = 0; i < 40 && imported == null; i++) {
        await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(imported, isNotNull);
      expect(PhotoStore.instance.fileFor(imported!).existsSync(), isTrue);
      expect(PhotoCredit.read(imported)!.photographer, 'Ana 101');
    });
  });
}
