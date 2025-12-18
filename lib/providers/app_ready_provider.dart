//Handles if loading the app is done and can continue to main menu screen
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_volunteering_hub/providers/auth_controller.dart';
import 'package:micro_volunteering_hub/providers/user_provider.dart';

final appReadyProvider = Provider<bool>((ref){
  final auth = ref.watch(authControllerProvider);
  final userData = ref.watch(userProvider);

  if(auth != AuthStatus.authenticated) return false;
  if(userData.isEmpty) return false;

  return true;
});