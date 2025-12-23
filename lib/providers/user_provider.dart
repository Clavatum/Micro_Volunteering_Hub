import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:micro_volunteering_hub/models/event.dart';

class UserProvider extends StateNotifier<Map<String, dynamic>> {
  UserProvider() : super({});

  void setUserPosition({required Position? position}){
    state = {...state, "user_position": position};
  }

  void setUser(Map<String, dynamic> userData) {
    print(userData);
    state = {...userData};
  }

  void updateUserProfile(String url) {
    state = {
      ...state,
      'photo_url_custom': url,
    };
  }

  void updateUserAvatarState(bool isCustom){
    state = {
      ...state,
      "photo_iscustom": isCustom,
    };
  }
  void setUserEvents(List<Event> usersEvents) {
    state = {...state, 'users_events': usersEvents};
  }

  void addUserEvent(Event e) {
    List<Event> usersEvents = (state["users_events"] != null) ? state['users_events'] : [];
    usersEvents.add(e);

    state = {
      ...state,
      'users_events': usersEvents,
    };
  }

  void removeUserEvent(Event e) {
    List<Event> usersEvents = state['users_events'];
    usersEvents.remove(e);

    state = {
      ...state,
      'users_events': usersEvents,
    };
  }

  void setUserAttendedEvents(List<Event> e) {
    state = {...state, 'user_attended_events': e};
  }

  void attendEvent(Event e) {
    List<Event> events = state['user_attended_events'];
    events.add(e);
    state = {...state, 'user_attended_events': events};
  }

  void clear(){
    state = {};
  }
}

var userProvider = StateNotifierProvider<UserProvider, Map<String, dynamic>>(
  (ref) => UserProvider(),
);
