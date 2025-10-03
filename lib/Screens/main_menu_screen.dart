import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../materials/background_gradient.dart';
import '../materials/gradient_button.dart';
import 'get_help_screen.dart';
import 'help_others_screen.dart';
import 'profile_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundGradient(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const Spacer(flex: 1),

                Align(
                  alignment: const Alignment(0, 0.6),
                  child: Text(
                    'Micro Volunteering Hub',
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 190),

                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GradientButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const GetHelpScreen(),
                            ),
                          );
                        },
                        width: 150,
                        height: 250,
                        child: Text(
                          'Get Help',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GradientButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HelpOthersScreen(),
                            ),
                          );
                        },
                        width: 150,
                        height: 250,
                        child: Text(
                          'Help Others',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 10),
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
        },
        tooltip: 'Profile',
        child: const Icon(Icons.person_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
