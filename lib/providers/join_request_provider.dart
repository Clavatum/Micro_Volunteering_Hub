import 'package:flutter_riverpod/legacy.dart';
import 'package:micro_volunteering_hub/models/join_request.dart';

class JoinRequestsProvider extends StateNotifier<List<JoinRequest>> {
  JoinRequestsProvider() : super([]);
  /*
      ONLY USERS JOIN REQUESTSSS!!!!
  
   */
  int requestCount(){
    return state.length;
  }
  void addJoinRequest(JoinRequest request) {
    final alreadyExists = state.any((r) =>
        r.requesterId == request.requesterId &&
        r.eventId == request.eventId);
    if (alreadyExists) return;

    state = [...state, request];
  }

  void setJoinRequests(List<JoinRequest> requests) {
    for(JoinRequest r in requests){
      addJoinRequest(r);
    }
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
