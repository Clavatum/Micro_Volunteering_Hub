import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_menu_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

String clientID =
    "615113923331-7si1neuaitp2q6seah3085ks5n3vuo0h.apps.googleusercontent.com";

class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({Key? key}) : super(key: key);

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  Color primary = Color(0xFF5E35B1);
  late Animation<double> _animFade;
  late Animation<Offset> _animSlide;
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _animFade = Tween(begin: 0.0, end: 1.0).animate(_animController);
    _animSlide = Tween(begin: Offset(0.0, -0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.decelerate),
    );
    GoogleSignIn googleSignIn = GoogleSignIn.instance;
    unawaited(googleSignIn.initialize(clientId: clientID));

    _auth.authStateChanges().listen((user) {
      setState(() {
        _user = user;
      });
    });
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _snackBarMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        backgroundColor: primary,
      ),
    );
  }

  Future<void> _logInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance
          .authenticate();

      if (googleUser == null) {
        _snackBarMessage(context, "Error while logging in.");
        return;
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      if (userCredential.user != null) {
        _snackBarMessage(context, "Login successful.");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainMenuScreen()),
          (route) => false,
        );
      } else {
        _snackBarMessage(context, "Error while logging in.");
      }
    } on PlatformException catch (e) {
      if (e.code == "network_error") {
        _snackBarMessage(
          context,
          "Network error, please check your internet connection.",
        );
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _snackBarMessage(context, "Sign in cancelled by user");
      }
    } catch (e) {
      debugPrint(e.toString());
      _snackBarMessage(
        context,
        "Something went wrong while logging in with Google.",
      );
    }
  }

  Widget signInAnimation() {
    return SlideTransition(
      position: _animSlide,
      child: FadeTransition(
        opacity: _animFade,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in with Google to continue',
                style: GoogleFonts.poppins(color: Colors.black87),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 260,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const Icon(Icons.login, size: 20),
                  label: const Text('Sign in with Google'),
                  onPressed: () async {
                    await _logInWithGoogle(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 2,
        title: Text(
          'Sign in',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFf6d365), Color(0xFFfda085)],
          ),
        ),
        child: signInAnimation(),
      ),
    );
  }
}
