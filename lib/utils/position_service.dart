import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

enum LocationPermissionResult{
  ok,
  serviceDisabled,
  denied,
  deniedForever,
}

class PositionService {
  Future<LocationPermissionResult> checkPermission() async{
    if(!await Geolocator.isLocationServiceEnabled()){
      return LocationPermissionResult.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if(permission == LocationPermission.deniedForever){
      return LocationPermissionResult.deniedForever;
    }

    return LocationPermissionResult.ok;
  }
  
  Future<Position?> getCurrentPosition() async {
    try {
      Position userPos = await Geolocator.getCurrentPosition();
      return userPos;
    } catch (e) {
      debugPrint('$e');
    }
  }

  static Future<String> getHumanReadableAddressFromLatLng(
    double lat,
    double long,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
      Placemark place = placemarks[0];
      return '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
    } catch (e) {
      return 'no address';
    }
  }

}