import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:micro_volunteering_hub/models/event.dart';

class UserEventsProvider extends StateNotifier<List<Event>> {
  UserEventsProvider() : super([]);

  void setEvents(List<Event> events) {
    state = events;
  }

  void addEvent(Event e) {
    state = [...state, e];
  }

  double getDistance(Position p, Event e) {
    return Geolocator.distanceBetween(
      p.latitude,
      p.longitude,
      e.coords.latitude,
      e.coords.longitude,
    );
  }
}

var userEventsProvider = StateNotifierProvider<UserEventsProvider, List<Event>>(
  (ref) => UserEventsProvider(),
);
