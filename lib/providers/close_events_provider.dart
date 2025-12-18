import 'package:flutter_riverpod/legacy.dart';
import 'package:micro_volunteering_hub/models/event.dart';

class CloseEventsProvider extends StateNotifier<List<Event>> {
  CloseEventsProvider() : super([]);

  void setEvents(List<Event> e) {
    state = e;
  }
}

var closeEventsProvider = StateNotifierProvider<CloseEventsProvider, List<Event>>((ref) => CloseEventsProvider());
