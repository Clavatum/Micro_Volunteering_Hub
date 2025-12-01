import 'package:flutter_riverpod/legacy.dart';

class UserProvider extends StateNotifier<Map<String, String>> {
  UserProvider() : super({});

  void setUser(Map<String, String> userData) {
    state = userData;
  }
}

var userProvider = StateNotifierProvider<UserProvider, Map<String, String>>(
  (ref) => UserProvider(),
);
