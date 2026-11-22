import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Each open editor owns an independent draft, even for the same saved event.
class DraftSession {
  DraftSession(this.eventId);
  final String? eventId;
}

final eventDraftProvider = NotifierProvider.autoDispose
    .family<EventDraft, Countdown, DraftSession>(EventDraft.new);

class EventDraft extends Notifier<Countdown> {
  EventDraft(this.session);
  final DraftSession session;

  @override
  Countdown build() {
    final existing = ref.read(eventByIdProvider(session.eventId));
    if (existing != null) return existing;
    final settings = ref.read(localSettingsProvider);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return Countdown(
      title: '',
      dateTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9),
      unit: settings.defaultUnit,
      reminders: settings.notify ? settings.defaultReminders : const [],
    );
  }

  void change(Countdown Function(Countdown) edit) => state = edit(state);
}
