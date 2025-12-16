import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:micro_volunteering_hub/backend/client/requests.dart';
import 'package:micro_volunteering_hub/providers/user_provider.dart';
import 'package:micro_volunteering_hub/utils/database.dart';
import 'package:micro_volunteering_hub/utils/snackbar_service.dart';
import 'package:micro_volunteering_hub/utils/storage.dart';

class AppLoadingScreen extends ConsumerStatefulWidget {
  const AppLoadingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends ConsumerState<AppLoadingScreen> {
  String loadingText = "Initializing application";

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<bool> hasInternet() async{
    final result = await Connectivity().checkConnectivity();
    final internet = result.contains(ConnectivityResult.mobile) || result.contains(ConnectivityResult.wifi) || result.contains(ConnectivityResult.vpn);
    return internet;
  }

  Future<void> _initApp() async {
    try{
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null){
        return;
      }

      updateLoadingText("Checking internet connection");
      final online = await hasInternet();

    Map<String, dynamic>? userData;

    if(online){
      updateLoadingText("Fetching user data from Firebase");
      userData = {
        "id": user.uid,
        "user_name": user.displayName ?? "unknown",
        "user_mail": user.email,
        "photo_url": user.photoURL ?? "",
        "updated_at": DateTime.now().millisecondsSinceEpoch,
      };
      //Don't upload with photo_path
      final apiResponse = await createAndStoreUserAPI(userData);
      if (!apiResponse["ok"]){
        showGlobalSnackBar(apiResponse["msg"]);
      }
      
      userData["photo_path"] = await downloadAndSaveImage(userData["photo_url"], userData["id"]);
      await UserLocalDb.saveUserAndActivate(userData);
    }
    else{
      updateLoadingText("Fetching user data from database");
      userData = await UserLocalDb.getActiveUser();
    }

    if (userData == null){
      throw Exception("User data is missing");
    }
    Future.microtask((){
      ref.read(userProvider.notifier).setUser(userData!);
    });
    } catch (e){
      showGlobalSnackBar("App initialization failed");
    }

  }

  void updateLoadingText(String text){
    if(!mounted) return;
    Future.microtask((){
      if(!mounted) return;
      setState(() {
        loadingText = text;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return loadingScreen(loadingText);
  }
}

//Loading screen
Widget loadingScreen(String loadingText){
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
              "$loadingText",
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