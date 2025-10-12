import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'google_sign_in_screen.dart';

class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({Key? key}) : super(key: key);

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      // Try to initialize Firebase if available; if not, continue anyway
      await Firebase.initializeApp();
    } catch (_) {
      // ignore errors — app can continue without Firebase for now
    }

    // After initialization, move to Google sign-in screen
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GoogleSignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFf6d365), Color(0xFFfda085)],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF5E35B1)),
          ),
        ),
      ),
    );
  }
}
