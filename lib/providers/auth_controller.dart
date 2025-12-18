import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:micro_volunteering_hub/providers/user_provider.dart';
import 'package:micro_volunteering_hub/utils/database.dart';

enum AuthStatus{unknown, authenticated, unauthenticated}

final authControllerProvider = StateNotifierProvider<AuthController, AuthStatus>(
  (ref) => AuthController(ref));

class AuthController extends StateNotifier<AuthStatus>{
  final Ref ref;
  late final StreamSubscription<User?> _sub;
  
  AuthController(this.ref) : super(AuthStatus.unknown){
    _sub = FirebaseAuth.instance.authStateChanges().listen((user){
      if(user == null){
        state = AuthStatus.unauthenticated;
      }
      else{
        state = AuthStatus.authenticated;
      }
    });
  }

  Future<void> logout() async{
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.signOut();
    ref.read(userProvider.notifier).clear();
    await UserLocalDb.setCurrentUser("");
    state = AuthStatus.unauthenticated;
  }
  @override
  void dispose(){
    _sub.cancel();
    super.dispose();
  }
}