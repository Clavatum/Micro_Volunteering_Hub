import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_menu_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleSignInScreen extends StatelessWidget {
  const GoogleSignInScreen({Key? key}) : super(key: key);

  void _snackBarMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance
          .authenticate(); //Pops up a Google Sign In Screen to choose account.
      if (googleUser == null) {
        //If signing in is not successful then return.
        _snackBarMessage(context, 'Sign in cancelled');
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      // GoogleSignInAuthentication currently provides an idToken. Use it to
      // create a Firebase credential. accessToken may not be available in
      // some versions of the plugin.
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(
            credential,
          ); //Login to firebase server using credential.
      if (userCredential.user != null) {
        //If logging in is successful then send user to home screen.
        _snackBarMessage(context, "Login successful.");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainMenuScreen()),
        );
      } else {
        _snackBarMessage(context, "Error while logging in.");
      }
    } on PlatformException catch (e) {
      if (e.code == "network_error") {
        //If device has slow or no internet.
        _snackBarMessage(
          context,
          "Network error, please check your internet connection.",
        );
      }
    } catch (e) {
      //For other errors, handle with catch block.
      debugPrint(e.toString());
      _snackBarMessage(
        context,
        "Something went wrong while logging in with Google.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF5E35B1);
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
}
