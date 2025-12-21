import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_volunteering_hub/firebase_options.dart';
import 'package:micro_volunteering_hub/utils/snackbar_service.dart';
import 'package:micro_volunteering_hub/widgets/app_shell.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _primaryColor = Color(0xFF00A86B);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _primaryColor),
        primaryColor: _primaryColor,
        textTheme: GoogleFonts.poppinsTextTheme(),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStatePropertyAll(_primaryColor),
          checkColor: MaterialStatePropertyAll(Colors.white),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _primaryColor),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          textStyle: GoogleFonts.poppins(color: _primaryColor),
        ),
      ),
      home: const AppShell(),
    );
  }
}
