import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:micro_volunteering_hub/backend/client/requests.dart';

final backendHealthProvider = StateNotifierProvider<BackendHealthNotifier, bool>(
  (ref) => BackendHealthNotifier(ref));

class BackendHealthNotifier extends StateNotifier<bool>{
  BackendHealthNotifier(this.ref) : super(false){
    _startPolling();
  }

  final Ref ref;
  Timer? _timer;

  Future<bool> check() async{
    final isOnline = await pingBackendAPI();
    state = isOnline;
    return isOnline;
  }

  void _startPolling(){
    check();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => check());
  }

  @override
  void dispose(){
    _timer?.cancel();
    super.dispose();
  }
}