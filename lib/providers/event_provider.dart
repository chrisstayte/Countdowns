import 'package:countdowns/data/database.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/providers/notification_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw StateError('The database must be opened before startup'),
);

/// Every countdown, live from Drift.
final eventsStreamProvider = StreamProvider<List<Countdown>>(
  (ref) => ref.watch(databaseProvider).watchCountdowns(),
);

/// The latest list, empty while the first read is in flight.
final eventsProvider = Provider<List<Countdown>>(
  (ref) => ref.watch(eventsStreamProvider).value ?? const [],
);

final eventByIdProvider = Provider.autoDispose.family<Countdown?, String?>((
  ref,
  id,
) {
  final key = int.tryParse(id ?? '');
  if (key == null) return null;
  return ref.watch(eventsProvider).where((e) => e.id == key).firstOrNull;
});

final eventsControllerProvider = Provider(EventsController.new);

class EventsController {
  EventsController(this.ref);
  final Ref ref;

  AppDatabase get _db => ref.read(databaseProvider);

  Future<int> save(Countdown event) async {
    final id = await _db.saveCountdown(event);
    await rescheduleNotifications();
    return id;
  }

  Future<void> deleteEvent(int id) async {
    await _db.deleteCountdown(id);
    await rescheduleNotifications();
  }

  Future<void> deleteAllEvents() async {
    await _db.deleteAllCountdowns();
    await rescheduleNotifications();
  }

  /// The notifications the database calls for right now.
  Future<List<NotificationRequest>> plannedNotifications() async {
    final events = await _db.allCountdowns();
    final slots = [
      for (final r in await _db.allReminders())
        (id: r.id, eventId: r.eventId, offsetMinutes: r.offsetMinutes),
    ];
    return planNotifications(events, slots, DateTime.now());
  }

  Future<void> _rescheduling = Future.value();

  /// Rebuilds every pending notification from the database. Runs one at a
  /// time, so a slow run can't put back reminders a later one removed.
  ///
  /// A platform scheduling failure must not make a committed write look like
  /// it failed, so errors are reported, not thrown.
  Future<void> rescheduleNotifications() =>
      _rescheduling = _rescheduling.then((_) => _reschedule());

  Future<void> _reschedule() async {
    final notifications = ref.read(notificationsProvider);
    try {
      if (!ref.read(localSettingsProvider).notify) {
        await notifications.cancelAll();
        return;
      }
      await notifications.replaceAll(await plannedNotifications());
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'countdown notifications',
        ),
      );
    }
  }
}
