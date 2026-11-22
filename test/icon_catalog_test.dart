import 'dart:convert';
import 'dart:io';

import 'package:countdowns/models/event_icons.dart';
import 'package:countdowns/models/icon_catalog.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> slugs(List<EventIconInfo> icons) => [
  for (final i in icons) i.slug,
];

void main() {
  test('268 icons with unique slugs, a section each and keywords', () {
    expect(eventIconCatalog, hasLength(268));
    expect(eventIconCatalog.map((i) => i.slug).toSet(), hasLength(268));
    for (final info in eventIconCatalog) {
      expect(iconCategories, contains(info.category), reason: info.slug);
      expect(info.keywords, isNotEmpty, reason: info.slug);
      expect(info.keywords, info.keywords.toLowerCase(), reason: info.slug);
      expect(iconInfo(info.slug), same(info));
    }
    // Every section has icons.
    for (final category in iconCategories) {
      expect(
        eventIconCatalog.where((i) => i.category == category),
        isNotEmpty,
        reason: category,
      );
    }
  });

  test('the generated catalogue matches icons.json', () {
    final json = (jsonDecode(
      File('assets/event_icons/icons.json').readAsStringSync(),
    ) as List).cast<Map<String, dynamic>>();
    expect(json.map((e) => e['slug']), slugs(eventIconCatalog));
    for (final (i, e) in json.indexed) {
      final info = eventIconCatalog[i];
      expect(info.label, e['label']);
      expect(info.category, e['category']);
      expect(info.keywords, (e['keywords'] as List).join(', '));
      expect(info.legacyCodePoint == null, e['material'] == null);
    }
  });

  test('every icon is a 24-unit currentColor SVG that parses', () async {
    for (final info in eventIconCatalog) {
      final svg = File(info.asset).readAsStringSync();
      expect(svg, contains('viewBox="0 0 24 24"'), reason: info.slug);
      expect(svg, contains('stroke="currentColor"'), reason: info.slug);
      expect(
        RegExp(r'#[0-9a-fA-F]{3,6}|rgb\(').hasMatch(svg),
        isFalse,
        reason: '${info.slug} hard-codes a colour',
      );
      await SvgStringLoader(svg).loadBytes(null);
    }
  });

  group('search', () {
    test('wedding finds the wedding icons, labels first', () {
      final found = slugs(iconsMatching('wedding'));
      expect(found.take(3), ['rings', 'wedding-bells', 'wedding-cake']);
      // Then icons with "wedding" as a keyword, before "wedding photos".
      expect(
        found.sublist(3, found.indexOf('camera')),
        containsAll(['bride-groom', 'church', 'invitation', 'bouquet']),
      );
    });

    test('matches keywords, every word and ignores case', () {
      expect(slugs(iconsMatching('Hanukkah')), contains('menorah'));
      expect(slugs(iconsMatching('chinese new year')), ['lantern']);
      expect(slugs(iconsMatching('  DENTIST ')), ['tooth']);
      expect(iconsMatching('zzzqqq'), isEmpty);
    });

    test('an empty query is everything; a section narrows it', () {
      expect(iconsMatching(''), hasLength(eventIconCatalog.length));
      final pets = iconsMatching('', category: 'Animals');
      expect(pets, isNotEmpty);
      expect(pets.every((i) => i.category == 'Animals'), isTrue);
      expect(
        slugs(iconsMatching('christmas', category: 'Food & drink')),
        isNot(contains('christmas-tree')),
      );
    });
  });
}
