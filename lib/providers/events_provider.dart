import 'package:flutter_riverpod/legacy.dart';
import 'package:micro_volunteering_hub/models/event.dart';

class EventsProvider extends StateNotifier<List<Event>> {
  EventsProvider() : super([]);

  void setEvents(List<Event> e) {
    state = e;
  }

  void addEvent(Event e) {
    state = [...state, e];
  }

  void removeEvent(Event e) {
    var newList = state;
    newList.remove(e);
    state = newList;
  }
}

var eventsProvider = StateNotifierProvider<EventsProvider, List<Event>>((ref) => EventsProvider());
