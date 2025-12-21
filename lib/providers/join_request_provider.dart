import 'package:flutter_riverpod/legacy.dart';
import 'package:micro_volunteering_hub/models/join_request.dart';

class JoinRequestsProvider extends StateNotifier<List<JoinRequest>> {
  JoinRequestsProvider() : super([]);

  void addJoinRequest(JoinRequest request) {
    state = [...state, request];
  }

  void setJoinRequests(List<JoinRequest> requests) {
    state = requests;
  }

  void removeJoinRequest(JoinRequest request) {
    var newState = state;
    newState.remove(request);
    state = newState;
  }
}

var joinRequestProvider = StateNotifierProvider<JoinRequestsProvider, List<JoinRequest>>(
  (ref) => JoinRequestsProvider(),
);
