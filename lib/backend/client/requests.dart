import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

//This URL is a local ip for testing purposes. Change this to public ip after deploying the API.
String localServerURL = "http://192.168.97.16:8000";

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