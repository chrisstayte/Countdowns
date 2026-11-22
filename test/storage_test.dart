import 'dart:convert';
import 'dart:io';

import 'package:countdowns/enums/sorting_method.dart';
import 'package:countdowns/models/event.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/storage/legacy_import.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The first Hive version stored just six fields, including nullable colors and font.
class _OldEventWriter extends TypeAdapter<Event> {
  @override
  final int typeId = 0;

  @override
  Event read(BinaryReader reader) =>
      throw UnsupportedError('Write-only fixture');

  @override
  void write(BinaryWriter writer, Event value) {
    final fields = [
      value.title,
      value.eventDateTime,
      Icons.cake.codePoint,
      null,
      null,
      null,
    ];
    writer.writeByte(fields.length);
    for (final (index, field) in fields.indexed) {
      writer.writeByte(index);
      writer.write(field);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Reads a historical Hive file, imports JSON once, and reopens edited data',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'countdowns-storage',
      );
      addTearDown(() async {
        await Hive.close();
        await directory.delete(recursive: true);
      });
      Hive.init(directory.path);
      Hive.registerAdapter(_OldEventWriter());
      var box = await Hive.openBox<Event>(eventsBoxName);
      await box.put(
        17,
        Event(title: 'Birthday', eventDateTime: DateTime(2032, 2, 1)),
      );
      await box.close();
      Hive.registerAdapter(EventAdapter(), override: true);
      box = await Hive.openBox<Event>(eventsBoxName);
      expect(box.get(17)!.icon, Icons.cake);
      expect(box.get(17)!.allDayEvent, true);
      expect(box.get(17)!.fontFamily, 'Default');
      expect(box.get(17)!.backgroundGradient, false);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await File('${directory.path}/settings.json').writeAsString(
        jsonEncode({
          'themeMode': 2,
          'squareView': false,
          'sortingMethod': 'SortingMethod.dateDescending',
        }),
      );
      await File('${directory.path}/countdownevents.json').writeAsString(
        jsonEncode([
          {
            'title': 'Anniversary',
            'eventDate': '2031-01-01',
            'backgroundColor': 0xff123456,
            'icon': Icons.favorite.codePoint,
            'fontFamily': 'ComicNeue',
          },
        ]),
      );
      await importLegacyData(directory, box, prefs);
      // Simulate an interruption between the event write and completion marker.
      await prefs.remove('legacyEventsImported');
      await importLegacyData(directory, box, prefs);
      expect(box.keys, [17, 18]);
      expect(box.get(18)!.icon, Icons.favorite);
      expect(box.get(18)!.backgroundColor, const Color(0xff123456));
      expect(box.get(18)!.fontFamily, 'ComicNeue');

      ProviderContainer openContainer() => ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          eventBoxProvider.overrideWithValue(box),
        ],
      );
      var container = openContainer();
      expect(container.read(localSettingsProvider).themeMode, ThemeMode.dark);
      expect(container.read(localSettingsProvider).squareView, false);
      expect(container.read(sortedEventsProvider).first.title, 'Birthday');
      final controller = container.read(localSettingsProvider.notifier);
      await controller.setSortingMethod(SortingMethod.alphaAscending);
      expect(container.read(sortedEventsProvider).first.title, 'Anniversary');
      await controller.setThemeMode(1);
      final edited = box.get(17)!.copy()..backgroundGradient = true;
      await container.read(eventsProvider.notifier).save(edited, key: 17);
      container.dispose();
      await box.close();
      box = await Hive.openBox<Event>(eventsBoxName);
      await importLegacyData(directory, box, prefs);
      container = openContainer();
      addTearDown(container.dispose);
      expect(container.read(localSettingsProvider).themeMode, ThemeMode.light);
      expect(container.read(sortedEventsProvider).first.key, 18);
      expect(container.read(eventByIdProvider('17'))!.backgroundGradient, true);
      expect(container.read(eventByIdProvider('invalid')), isNull);
      expect(box.keys, [17, 18]);
    },
  );
}
