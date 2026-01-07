import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:micro_volunteering_hub/models/event.dart';

//This URL is a local ip for testing purposes.
String localServerURL = "http://192.168.137.16:8000";

String publicServerURL = "https://micro-volunteering-hub-backend.onrender.com";
String usedServerURL = publicServerURL;
class FetchEventsResult{
  final List<Event> events;
  final String? cursor;

  FetchEventsResult(this.events, this.cursor);
}

Future<bool> pingBackendAPI() async {
  try {
    final response = await http
        .get(Uri.parse("$usedServerURL/health"))
        .timeout(const Duration(seconds: 3));
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}

Future<Map<String, dynamic>> createEventAPI(
  Map<String, dynamic>? eventData,
) async {
  try {
    final response = await http
        .post(
          Uri.parse("$usedServerURL/event/create"),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode(eventData),
        )
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      return {
        "ok": false,
        "msg": "Request to API has failed with status code ${response.statusCode}.",
      };
    }
  } on TimeoutException {
    return {"ok": false, "msg": "Request to API server has timed out."};
  }
}

Future<Map<String, dynamic>> createAndStoreUserAPI(
  Map<String, dynamic>? userData,
) async {
  try {
    final response = await http
        .post(
          Uri.parse("$usedServerURL/user/create"),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode(userData),
        )
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      return {
        "ok": false,
        "msg": "Request to API has failed with status code ${response.statusCode}.",
      };
    }
  } on TimeoutException {
    return {"ok": false, "msg": "Request to API server has timed out."};
  }
}

Future<FetchEventsResult> fetchEventsAPI(String? cursor) async {
  try {
    final response = await http
        .get(
          Uri.parse(
            (cursor == null) ? "$usedServerURL/events" : "$usedServerURL/events?after=$cursor",
          ),
        )
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return FetchEventsResult(
        (body["events"] as List? ?? []).map((e) => Event.fromJson(e)).toList(),
        body["cursor"],
      );
    } else {
      print(
        "fetchEventsAPI: Request to API has failed with status code ${response.statusCode}.",
      );
      return FetchEventsResult([], cursor);
    }
  } on TimeoutException {
    print("fetchEventsAPI: Request to API server has timed out.");
    return FetchEventsResult([], cursor);
  }
}

Future<Map<String, dynamic>> joinEventAPI(String eventId, String userId) async {
  try {
    final response = await http.post(
      Uri.parse("$usedServerURL/event/$eventId/join"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({"user_id": userId}),
    ).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      return {
        "ok": false,
        "msg": "Request to API has failed with status code ${response.statusCode}.",
      };
    }
  } on TimeoutException {
    return {"ok": false, "msg": "Request to API server has timed out."};
  }
}

Future<Map<String, dynamic>> leaveEventAPI(String eventId, String userId) async {
  try {
    final response = await http.post(
      Uri.parse("$usedServerURL/event/$eventId/leave"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({"user_id": userId}),
    ).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      return {
        "ok": false,
        "msg": "Request to API has failed with status code ${response.statusCode}.",
      };
    }
  } on TimeoutException {
    return {"ok": false, "msg": "Request to API server has timed out."};
  }
}

Future<Map<String, dynamic>> fetchUserAPI(String userID) async {
  try {
    final response = await http
        .get(
          Uri.parse(
            "$usedServerURL/user?id=$userID",
          ),
        )
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      return {"ok": false, "msg": "Request to API has failed with status code ${response.statusCode}."};
    }
  } on TimeoutException {
    print("fetchUserAPI: Request to API server has timed out.");
    return {"ok": false, "msg": "Request to API server has timed out."};
  }
}

Future<Map<String, dynamic>> fetchMessagesAPI(String eventID) async{
  try {
    final response = await http
        .get(
          Uri.parse(
            "$usedServerURL/event/$eventID/chats",
          ),
        )
        .timeout(const Duration(seconds: 5));
    print(response.statusCode);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      return {"ok": false, "msg": "Request to API has failed with status code ${response.statusCode}."};
    }
  } on TimeoutException {
    print("fetchUserAPI: Request to API server has timed out.");
    return {"ok": false, "msg": "Request to API server has timed out."};
  }
}