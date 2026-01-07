import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:micro_volunteering_hub/backend/client/requests.dart';
import 'package:micro_volunteering_hub/providers/network_provider.dart';
import 'package:micro_volunteering_hub/providers/position_provider.dart';
import 'package:micro_volunteering_hub/providers/user_provider.dart';
import 'package:micro_volunteering_hub/utils/database.dart';
import 'package:micro_volunteering_hub/utils/position_service.dart';
import 'package:micro_volunteering_hub/utils/snackbar_service.dart';
import 'package:micro_volunteering_hub/utils/storage.dart';

class AppLoadingScreen extends ConsumerStatefulWidget {
  const AppLoadingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends ConsumerState<AppLoadingScreen> {
  String loadingText = "Initializing Application";

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> initLocation() async {
    // Read providers synchronously so we don't call `ref` after an await
    final service = ref.read(positionServiceProvider);
    final positionNotifier = ref.read(positionNotifierProvider.notifier);

    final result = await service.checkPermission();

    // If the widget was disposed while awaiting, bail out
    if (!mounted) return;

    switch (result) {
      case LocationPermissionResult.serviceDisabled:
        showGlobalSnackBar("Location Service is Disabled");
        return;
      case LocationPermissionResult.denied:
        showGlobalSnackBar("Location Permission is Denied");
        return;
      case LocationPermissionResult.deniedForever:
        showGlobalSnackBar("Location Permission is Denied Forever");
        return;
      case LocationPermissionResult.ok:
        await positionNotifier.updatePosition();
    }
  }


  Future<void> _initApp() async {
    Future.microtask(initLocation);

    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return;
      }

      updateLoadingText("Checking Internet Connection");
      final online = await ref.read(backendHealthProvider.notifier).check();
      Map<String, dynamic>? userData;
      if (online) {
        updateLoadingText("Loading Kindness...");
        //Try to fetch user first
        final apiResponse = await fetchUserAPI(user.uid);
        if (apiResponse["user"] != null){
          userData = apiResponse["user"];
          userData!["user_attended_events"] = List<String>.from(apiResponse["user_attended_events"]);
        }
        //If no user data exists then create the user data
        if (userData == null){
          userData = {
            "id": user.uid,
            "user_name": user.displayName ?? "unknown",
            "user_mail": user.email,
            "photo_url": user.photoURL ?? "",
            "photo_url_custom": "",
            "photo_path": "",
            "photo_path_custom": "",
            "photo_iscustom": false,
            "user_attended_events": List<String>.empty(),
            "updated_at": DateTime.now().millisecondsSinceEpoch,
          };
          final apiResponse = await createAndStoreUserAPI(userData);
          if (!apiResponse["ok"]) {
            showGlobalSnackBar(apiResponse["msg"]);
          }
        }

        userData["photo_path"] = await downloadAndSaveImage(
          userData["photo_url"],
          "user_${userData["id"]}.png",
        );
        userData["photo_iscustom"] = await UserLocalDb.getCurrentAvatarState();
        await UserLocalDb.saveUserAndActivate(userData);
      } else {
        updateLoadingText("Fetching User Data From Database");
        userData = await UserLocalDb.getActiveUser();
      }

      if (userData == null) {
        throw Exception("User Data is Missing");
      }
      if (!mounted) return;
      ref.read(userProvider.notifier).setUser(userData);
    } catch (e) {
      print(e);
      showGlobalSnackBar("App initialization is failed. Exit application and try again later.");
    }
  }

  void updateLoadingText(String text) {
    if (!mounted) return;
    Future.microtask(() {
      if (!mounted) return;
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
Widget loadingScreen(String loadingText) {
  return Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 255, 255, 255),
            Color.fromARGB(255, 130, 228, 130),
          ],
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
                color: Color(0xFF00A86B),
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF00A86B)),
            ),
            SizedBox(height: 40),
            Text(
              "$loadingText",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF00A86B),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
