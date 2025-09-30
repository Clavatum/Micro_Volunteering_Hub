import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpOthersScreen extends StatelessWidget {
  const HelpOthersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help Others',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Text(
          'Help Others Screen',
          style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
