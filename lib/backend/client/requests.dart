import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

//This URL is a local ip for testing purposes. Change this to public ip after deploying the API.
String localServerURL = "http://192.168.60.16:8000";

Future<Map<String, dynamic>> createEventAPI(Map<String, String>? eventData) async{
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
      return {"ok": false, "error": "unknown"};
    }
  }
  on TimeoutException{
    return {"ok": false, "error": "timeout"};
  }
}