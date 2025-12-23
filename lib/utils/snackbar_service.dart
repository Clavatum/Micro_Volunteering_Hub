import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final GlobalKey<ScaffoldMessengerState> snackbarKey =
    GlobalKey<ScaffoldMessengerState>();

void showGlobalSnackBar(String message) {
  WidgetsBinding.instance.addPostFrameCallback((_){
    snackbarKey.currentState?.clearSnackBars();
    snackbarKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Color(0xFF00A86B),
      ),
    );
  });
}
