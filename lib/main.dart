import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_volunteering_hub/utils/snackbar_service.dart';
import 'package:micro_volunteering_hub/widgets/app_shell.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Firebase.initializeApp();
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickHelp',
      scaffoldMessengerKey: snackbarKey,
      debugShowCheckedModeBanner: false,
      home: const AppShell(),
    );
  }
}
