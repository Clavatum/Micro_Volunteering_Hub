import 'package:flutter_riverpod/legacy.dart';
import 'package:micro_volunteering_hub/models/event.dart';

class EventsProvider extends StateNotifier<List<Event>> {
  EventsProvider() : super([]);

  void setEvents(List<Event> events) {
    state = List.unmodifiable(events);
  }

  void addEvent(Event event) {
    if (state.any((e) => e.eventId == event.eventId)) return;
    state = [...state, event];
  }

  void removeEventById(String id) {
    state = state.where((e) => e.eventId != id).toList();
  }

  void addEvents(List<Event> newEvents) {
    final existingIds = state.map((e) => e.eventId).toSet();
    final filtered = newEvents.where((e) => !existingIds.contains(e.eventId)).toList();
    if (filtered.isEmpty) return;
    state = [...state, ...filtered];
  }

  void addAttendee(String eventId, String userId) {
    state = state.map((event) {
      if (event.eventId == eventId) {
        if (event.attendantIds.contains(userId)) return event;

        return event.copyWith(
          attendantIds: [...event.attendantIds, userId],
          participantCount: event.participantCount + 1,
        );
      }
      return event;
    }).toList();
  }
}

var eventsProvider = StateNotifierProvider<EventsProvider, List<Event>>((ref) => EventsProvider());
