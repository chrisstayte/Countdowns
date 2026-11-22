import 'package:countdowns/models/event.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Each open editor owns an independent draft, even for the same saved event.
class DraftSession {
  DraftSession(this.eventId);
  final String? eventId;
}

final eventDraftProvider = NotifierProvider.autoDispose
    .family<EventDraft, Event, DraftSession>(EventDraft.new);

class EventDraft extends Notifier<Event> {
  EventDraft(this.session);
  final DraftSession session;

  @override
  Event build() =>
      ref.read(eventByIdProvider(session.eventId))?.copy() ??
      Event(
        title: '',
        eventDateTime: DateTime.now().add(const Duration(days: 1)),
      );

  void change(void Function(Event) edit) {
    final draft = state.copy();
    edit(draft);
    state = draft;
  }
}
