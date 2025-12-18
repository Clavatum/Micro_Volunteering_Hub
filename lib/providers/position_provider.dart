import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:micro_volunteering_hub/providers/user_provider.dart';
import 'package:micro_volunteering_hub/utils/position_service.dart';

final positionServiceProvider = Provider((ref) => PositionService());

final positionNotifierProvider = StateNotifierProvider<PositionNotifier, Position?>((ref) => PositionNotifier(ref));
class PositionNotifier extends StateNotifier<Position?>{
  PositionNotifier(this.ref) : super(null);

  final Ref ref;

  Future<void> updatePosition() async{
    final service = ref.read(positionServiceProvider);
    final pos = await service.getCurrentPosition();

    if(pos == null) return;

    state = pos;

    ref.read(userProvider.notifier).setUserPosition(lat: pos.latitude, lon: pos.longitude);
  }
}