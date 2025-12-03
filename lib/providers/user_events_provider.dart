import 'package:flutter_riverpod/legacy.dart';
import 'package:micro_volunteering_hub/models/event.dart';

class UserEventsProvider extends StateNotifier<List<Event>> {
  UserEventsProvider() : super([]);

  void setEvents(List<Event> events) {
    state = events;
  }

  void addEvent(Event e) {
    state = [...state, e];
  }
}

var userEventsProvider = StateNotifierProvider<UserEventsProvider, List<Event>>(
  (ref) => UserEventsProvider(),
);
