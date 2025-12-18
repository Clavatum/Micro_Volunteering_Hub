import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_volunteering_hub/Screens/app_loading_screen.dart';
import 'package:micro_volunteering_hub/Screens/google_sign_in_screen.dart';
import 'package:micro_volunteering_hub/Screens/main_menu_screen.dart';
import 'package:micro_volunteering_hub/providers/app_ready_provider.dart';
import 'package:micro_volunteering_hub/providers/auth_controller.dart';

class AppShell extends ConsumerWidget{
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final appReady = ref.watch(appReadyProvider);
    if(auth == AuthStatus.unauthenticated){
      return const GoogleSignInScreen();
    }

    if (auth == AuthStatus.unknown || !appReady){
      return const AppLoadingScreen();
    }

    return const MainMenuScreen();
  }
}