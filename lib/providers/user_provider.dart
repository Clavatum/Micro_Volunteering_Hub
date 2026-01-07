import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:micro_volunteering_hub/models/event.dart';

class UserProvider extends StateNotifier<Map<String, dynamic>> {
  UserProvider() : super({});

  void setUserPosition({required Position? position}){
    state = {...state, "user_position": position};
  }

  void setUser(Map<String, dynamic> userData) {
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

  void setUserAttendedEvents(List<String> s) {
    state = {...state, 'user_attended_events': s};
  }

  void attendEvent(String s) {
    List<String> eventIds = state['user_attended_events'] ?? List<String>.empty(growable: true);
    eventIds.add(s);
    state = {...state, 'user_attended_events': eventIds};
  }

  void clear(){
    state = {};
  }
}

var userProvider = StateNotifierProvider<UserProvider, Map<String, dynamic>>(
  (ref) => UserProvider(),
);
