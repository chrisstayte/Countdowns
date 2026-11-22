import 'package:countdowns/enums/sorting_method.dart';
import 'package:countdowns/models/event.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/providers/notification_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const eventsBoxName = 'events';

final eventBoxProvider = Provider<Box<Event>>(
  (ref) => Hive.box<Event>(eventsBoxName),
);

final eventsProvider = NotifierProvider<EventsController, List<Event>>(
  EventsController.new,
);

final eventByIdProvider = Provider.autoDispose.family<Event?, String?>((
  ref,
  id,
) {
  final key = int.tryParse(id ?? '');
  return ref
      .watch(eventsProvider)
      .where((event) => event.key == key)
      .firstOrNull;
});

final sortedEventsProvider = Provider<List<Event>>((ref) {
  final events = [...ref.watch(eventsProvider)];
  final sort = ref.watch(localSettingsProvider.select((s) => s.sortingMethod));
  int byTitle(Event a, Event b) =>
      a.title.toLowerCase().compareTo(b.title.toLowerCase());
  int byDate(Event a, Event b) => a.eventDateTime.compareTo(b.eventDateTime);
  events.sort(switch (sort) {
    SortingMethod.alphaAscending => byTitle,
    SortingMethod.alphaDescending => (a, b) => byTitle(b, a),
    SortingMethod.dateAscending => byDate,
    SortingMethod.dateDescending => (a, b) => byDate(b, a),
  });
  return events;
});

class EventsController extends Notifier<List<Event>> {
  @override
  List<Event> build() {
    final box = ref.watch(eventBoxProvider);
    final changes = box.listenable();
    void refresh() => state = List.unmodifiable(box.values);
    changes.addListener(refresh);
    ref.onDispose(() => changes.removeListener(refresh));
    return List.unmodifiable(box.values);
  }

  Future<int> save(Event event, {int? key}) async {
    final box = ref.read(eventBoxProvider);
    final int id;
    if (key == null) {
      id = await box.add(event);
    } else {
      await box.put(key, event);
      id = key;
    }
    if (ref.read(localSettingsProvider).notify) {
      final notifications = ref.read(notificationsProvider);
      await _updateNotifications(() async {
        if (key != null) await notifications.cancel(id);
        await notifications.schedule(id, event);
      });
    }
    return id;
  }

  Future<void> deleteEvent(int key) async {
    await ref.read(eventBoxProvider).delete(key);
    await _updateNotifications(
      () => ref.read(notificationsProvider).cancel(key),
    );
  }

  Future<void> deleteAllEvents() async {
    await ref.read(eventBoxProvider).clear();
    await _updateNotifications(ref.read(notificationsProvider).cancelAll);
  }

  // A platform scheduling failure must not make a committed Hive write retry as a new event.
  Future<void> _updateNotifications(Future<void> Function() action) async {
    try {
      await action();
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
