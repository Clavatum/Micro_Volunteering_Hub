import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String?> downloadAndSaveImage(String imageUrl, String userId) async{
  try{
    final response = await http.get(Uri.parse(imageUrl));
    if(response.statusCode != 200) return null;

    final dir = await getApplicationDocumentsDirectory();
    final filePath = p.join(dir.path, "user_$userId.png");

    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    return filePath;
  } catch (e){
    return "";
  }
}