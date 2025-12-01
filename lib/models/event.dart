import 'package:latlong2/latlong.dart';

class Event {
  final String title;
  final DateTime time;
  final String hostName;
  final int capacity;
  final String imageUrl;
  final List<Tag> tags;
  final LatLng coords;

  const Event({
    required this.title,
    required this.time,
    required this.hostName,
    required this.capacity,
    required this.imageUrl,
    required this.tags,
    required this.coords,
  });
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
}
