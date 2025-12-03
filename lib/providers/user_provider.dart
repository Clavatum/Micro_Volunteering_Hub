import 'package:flutter_riverpod/legacy.dart';
import 'package:micro_volunteering_hub/models/event.dart';

class UserProvider extends StateNotifier<Map<String, dynamic>> {
  UserProvider() : super({});

  void setUser(Map<String, dynamic> userData) {
    state = {...userData};
  }

  void setUserEvents(List<Event> usersEvents) {
    state = {...state, 'users_events': usersEvents};
  }
}

var userProvider = StateNotifierProvider<UserProvider, Map<String, dynamic>>(
  (ref) => UserProvider(),
);
