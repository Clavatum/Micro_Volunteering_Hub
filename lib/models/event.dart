import 'package:latlong2/latlong.dart';
import 'package:micro_volunteering_hub/helper_functions.dart';

class Event {
  final String title;
  final String userId;
  final String eventId;

  final DateTime time;
  final String hostName;
  final int capacity;
  final String imageUrl;
  final List<Tag> tags;
  final LatLng coords;
  bool isClose;
  int distanceToUser;

  Event({
    required this.eventId,
    required this.userId,
    required this.title,
    required this.time,
    required this.hostName,
    required this.capacity,
    required this.imageUrl,
    required this.tags,
    required this.coords,
    this.distanceToUser = -1,
  }) : isClose = false;

  void setIsClose(double lat, double lon) {
    int dist = HelperFunctions.getDistanceFromTwoPoints(
      lat1: lat,
      lon1: lon,
      lat2: coords.latitude,
      lon2: coords.longitude,
    );

    distanceToUser = dist;

    isClose = (dist < 100000000);
  }

  factory Event.fromJson(Map<String, dynamic> json, String docId) {
    return Event(
      eventId: json['event_id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['description'] ?? '',
      time: HelperFunctions.formatter.parse(json['starting_date'] ?? ''),
      hostName: json['host_name'] ?? 'unknown',
      capacity:
          int.tryParse(
            json['people_needed'],
          ) ??
          -1,
      imageUrl: json['user_image_url'],
      tags: _fromJsonToEvents(
        json['categories'] ?? '',
      ),
      coords: LatLng(
        double.tryParse(json['selected_lat']) ?? -1,
        double.tryParse(json['selected_lon']) ?? -1,
      ),
    );
  }
}

enum Tag {
  cleaning,
  donation,
  support,
  community,
  emergency,
  skills,
  environment,
  animals,
  other,
}

Tag _fromString(String s) {
  if (s == 'cleaning') return Tag.cleaning;
  if (s == 'donation') return Tag.donation;
  if (s == 'support') return Tag.support;
  if (s == 'community') return Tag.community;
  if (s == 'emergency') return Tag.emergency;
  if (s == 'skills') return Tag.skills;
  if (s == 'environment') return Tag.environment;
  if (s == 'animals') return Tag.animals;
  return Tag.other;
}

List<Tag> _fromJsonToEvents(List<dynamic> events) {
  return events.map((e) => _fromString(e)).toList();
}
