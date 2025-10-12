import 'package:flutter/material.dart';
import 'screens/main_menu_screen.dart';
import 'screens/app_loading_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform
      ), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done){
          return MaterialApp(home: const MainMenuScreen(), debugShowCheckedModeBanner: false);
        }
        else{
          return MaterialApp(
            home: Scaffold(),
          );
        }
      },
    );
  }
}