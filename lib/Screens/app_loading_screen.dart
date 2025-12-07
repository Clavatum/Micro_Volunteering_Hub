import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:micro_volunteering_hub/Screens/main_menu_screen.dart';
import 'package:micro_volunteering_hub/providers/user_provider.dart';
import 'google_sign_in_screen.dart';

class AppLoadingScreen extends ConsumerStatefulWidget {
  const AppLoadingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends ConsumerState<AppLoadingScreen> {
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await Firebase.initializeApp();
    Position userp = await _determinePosition();

    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GoogleSignInScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainMenuScreen()),
      );
    }

    var _user = FirebaseAuth.instance.currentUser!;

    var id = _user.uid;
    var userName = _user.displayName ?? 'unknown';
    var photoUrl = _user.photoURL;

    Map<String, String> userData = {
      'photo_url': photoUrl?? '',
      'id': id,
      'user_name': userName,
      'user_mail': FirebaseAuth.instance.currentUser!.email!,
      'user_latitude': userp.latitude.toString(),
      'user_longitude': userp.longitude.toString(),
    };

    ref.read(userProvider.notifier).setUser(userData);

    await FirebaseFirestore.instance.collection('user_info').doc(id).set(userData, SetOptions(merge: true));
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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Loading",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5E35B1),
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF5E35B1)),
              ),
              SizedBox(height: 40),
              Text(
                "Initializing firebase",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5E35B1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
