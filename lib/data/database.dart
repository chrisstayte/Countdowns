import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/models/palette.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

@DataClassName('EventRow')
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  DateTimeColumn get eventDateTime => dateTime()();
  BoolColumn get allDay => boolean().withDefault(const Constant(true))();
  TextColumn get iconSlug => text().nullable()();
  IntColumn get colorArgb => integer()();
  TextColumn get gradientId => text().nullable()();
  TextColumn get gradientDirection =>
      textEnum<GradientDirection>().nullable()();
  TextColumn get photoPath => text().nullable()();

  /// JSON: a crop point per shape plus a "same for all" flag.
  TextColumn get photoCrops => text().nullable()();
  RealColumn get photoDarken => real().withDefault(const Constant(0.35))();
  TextColumn get fontFamily => text().withDefault(const Constant('Default'))();
  TextColumn get unit => textEnum<CountUnit>()();
  TextColumn get repeat => textEnum<RepeatRule>()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// The Hive key this row was copied from, so the copy can run again safely.
  IntColumn get legacyHiveKey => integer().nullable().unique()();
}

@DataClassName('ReminderRow')
class Reminders extends Table {
  /// Also used as the notification id.
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventId =>
      integer().references(Events, #id, onDelete: KeyAction.cascade)();

  /// Minutes before the event. 0 means at the time.
  IntColumn get offsetMinutes => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {eventId, offsetMinutes},
  ];
}

/// Small key/value flags written in the same transaction as the data they
/// describe.
@DataClassName('MetaRow')
class Meta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Events, Reminders, Meta])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'countdowns'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<String?> readMeta(String key) async => (await (select(
    meta,
  )..where((m) => m.key.equals(key))).getSingleOrNull())?.value;

  Future<void> writeMeta(String key, String value) =>
      into(meta)
          .insertOnConflictUpdate(MetaCompanion.insert(key: key, value: value));

  Stream<List<Countdown>> watchCountdowns() {
    // Reminder changes always come with an event write in the same
    // transaction, so watching events is enough.
    return select(events).watch().asyncMap((rows) async {
      final reminderRows = await select(reminders).get();
      return _assemble(rows, reminderRows);
    });
  }

  Future<List<Countdown>> allCountdowns() async =>
      _assemble(await select(events).get(), await select(reminders).get());

  Future<List<ReminderRow>> allReminders() => select(reminders).get();

  List<Countdown> _assemble(List<EventRow> rows, List<ReminderRow> rems) {
    final byEvent = <int, List<int>>{};
    for (final r in rems) {
      (byEvent[r.eventId] ??= []).add(r.offsetMinutes);
    }
    return [
      for (final row in rows)
        countdownFromRow(row, (byEvent[row.id] ?? [])..sort()),
    ];
  }

  /// Inserts or updates [c] and replaces its reminders. Returns the id.
  Future<int> saveCountdown(Countdown c, {DateTime? now}) => transaction(
    () async {
      final stamp = now ?? DateTime.now();
      final companion = _companion(c, stamp);
      final int id;
      if (c.id == null) {
        id = await into(events).insert(companion);
      } else {
        id = c.id!;
        await (update(events)..where((e) => e.id.equals(id))).write(companion);
      }
      await _replaceReminders(id, c.reminders);
      return id;
    },
  );

  Future<void> _replaceReminders(int id, List<int> offsets) async {
    final existing = await (select(
      reminders,
    )..where((r) => r.eventId.equals(id))).get();
    final wanted = offsets.toSet();
    // Keep rows that stay, so their notification ids stay stable.
    for (final r in existing) {
      if (!wanted.remove(r.offsetMinutes)) {
        await (delete(reminders)..where((x) => x.id.equals(r.id))).go();
      }
    }
    for (final offset in wanted) {
      await into(
        reminders,
      ).insert(RemindersCompanion.insert(eventId: id, offsetMinutes: offset));
    }
  }

  EventsCompanion _companion(Countdown c, DateTime stamp) => EventsCompanion(
    title: Value(c.title),
    eventDateTime: Value(c.dateTime),
    allDay: Value(c.allDay),
    iconSlug: Value(c.iconSlug),
    colorArgb: Value(c.colorArgb),
    gradientId: Value(c.gradientId),
    gradientDirection: Value(c.gradientDirection),
    photoPath: Value(c.photoPath),
    photoCrops: Value(c.photoCrops?.toJson()),
    photoDarken: Value(c.photoDarken),
    fontFamily: Value(c.fontFamily),
    unit: Value(c.unit),
    repeat: Value(c.repeat),
    createdAt: c.id == null
        ? Value(c.createdAt ?? stamp)
        : const Value.absent(),
    updatedAt: Value(stamp),
    legacyHiveKey: c.id == null ? Value(c.legacyHiveKey) : const Value.absent(),
  );

  Future<void> deleteCountdown(int id) =>
      (delete(events)..where((e) => e.id.equals(id))).go();

  Future<void> deleteAllCountdowns() => transaction(() async {
    await delete(reminders).go();
    await delete(events).go();
  });

  Future<Set<int>> legacyKeys() async {
    final rows = await (selectOnly(
      events,
    )..addColumns([events.legacyHiveKey])).get();
    return {
      for (final r in rows)
        if (r.read(events.legacyHiveKey) case final int key) key,
    };
  }
}

Countdown countdownFromRow(EventRow row, List<int> reminders) => Countdown(
  id: row.id,
  title: row.title,
  dateTime: row.eventDateTime,
  allDay: row.allDay,
  iconSlug: row.iconSlug,
  colorArgb: row.colorArgb,
  gradientId: row.gradientId,
  gradientDirection: row.gradientDirection,
  photoPath: row.photoPath,
  photoCrops: PhotoCrops.fromJson(row.photoCrops),
  photoDarken: row.photoDarken,
  fontFamily: row.fontFamily,
  unit: row.unit,
  repeat: row.repeat,
  reminders: reminders,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
  legacyHiveKey: row.legacyHiveKey,
);
