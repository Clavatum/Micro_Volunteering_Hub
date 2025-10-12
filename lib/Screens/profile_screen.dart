import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:micro_volunteering_hub/Screens/google_sign_in_screen.dart';

class ProfileScreen extends StatelessWidget {
  Future<void> _logOut(context) async{
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pop();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const GoogleSignInScreen()),
      (route) => false //This removes all previous routes
    );
  }

  const ProfileScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    Color primary = Color(0xFF5E35B1);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Profile Screen',
              style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            ElevatedButton.icon(
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
              label: const Text('Log Out'),
              onPressed: () async {
                await _logOut(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
