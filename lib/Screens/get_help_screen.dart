import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GetHelpScreen extends StatelessWidget {
  const GetHelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Get Help',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Text(
          'Get Help Screen',
          style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
