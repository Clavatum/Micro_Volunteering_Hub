import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:micro_volunteering_hub/models/event.dart';

class HelperFunctions {
  static DateFormat formatter = DateFormat('dd.MM.yyyy');

  static String getStringDistance(double lat, double lon, Event e) {
    return '${Geolocator.distanceBetween(
      lat,
      lon,
      e.coords.latitude,
      e.coords.longitude,
    ).floor()} meters';
  }

  static int getIntDistance(double lat, double lon, Event e) {
    return Geolocator.distanceBetween(
      lat,
      lon,
      e.coords.latitude,
      e.coords.longitude,
    ).floor();
  }

  static int getDistanceFromTwoPoints({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(
      lat1,
      lon1,
      lat2,
      lon2,
    ).floor();
  }
}
