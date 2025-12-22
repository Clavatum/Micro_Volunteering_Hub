import 'package:flutter_riverpod/legacy.dart';
import 'package:micro_volunteering_hub/models/join_request.dart';

class JoinRequestsProvider extends StateNotifier<List<JoinRequest>> {
  JoinRequestsProvider() : super([]);
  /*
      ONLY USERS JOIN REQUESTSSS!!!!
  
   */

  void addJoinRequest(JoinRequest request) {
    state = [...state, request];
  }

  void setJoinRequests(List<JoinRequest> requests) {
    state = requests;
  }

  void removeJoinRequest(JoinRequest request) {
    state = [
      for (final r in state)
        if (!(r.eventId == request.eventId && r.requesterId == request.requesterId)) r,
    ];
  }
}

var joinRequestProvider = StateNotifierProvider<JoinRequestsProvider, List<JoinRequest>>(
  (ref) => JoinRequestsProvider(),
);
