import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:micro_volunteering_hub/models/event.dart';

//This URL is a local ip for testing purposes. Change this to public ip after deploying the API.
String localServerURL = "http://192.168.97.16:8000";

class FetchEventsResult{
  final List<Event> events;
  final int? lastTs;

  FetchEventsResult(this.events, this.lastTs);
}

Future<Map<String, dynamic>> createEventAPI(Map<String, dynamic>? eventData) async{
  try{
    final response = await http.post(
      Uri.parse("$localServerURL/event/create"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(eventData)
    ).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200){
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    else{
      return {"ok": false, "msg": "Request to API has failed with status code ${response.statusCode}."};
    }
  }
  on TimeoutException{
    return {"ok": false, "msg": "Request to API server has timed out."};
  }
}

Future<Map<String, dynamic>> createAndStoreUserAPI(Map<String, dynamic>? userData) async{
  try{
    final response = await http.post(
      Uri.parse("$localServerURL/user/create"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(userData)
    ).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200){
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    else{
      return {"ok": false, "msg": "Request to API has failed with status code ${response.statusCode}."};
    }
  }
  on TimeoutException{
    return {"ok": false, "msg": "Request to API server has timed out."};
  }
}

Future<FetchEventsResult> fetchEventsAPI(int? since) async{
  try{
    final response = await http.get(
      Uri.parse((since == null) ? "$localServerURL/events" : "$localServerURL/events?since=$since"),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200){
      final body = jsonDecode(response.body);
      print(body["events"]);
      return FetchEventsResult((body["events"] as List? ?? []).map((e) => Event.fromJson(e)).toList(),
        body["last_ts"]);
    }
    else{
      print("fetchEventsAPI: Request to API has failed with status code ${response.statusCode}.");
      return FetchEventsResult([], since);
    }
  }
  on TimeoutException{
    print("fetchEventsAPI: Request to API server has timed out.");
    return FetchEventsResult([], since);
  }
}