import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:micro_volunteering_hub/helper_functions.dart';

class Event {
  final String title;
  final String desc;
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
  final List<String> attendantIds;

  Event({
    required this.eventId,
    required this.userId,
    required this.title,
    required this.desc,
    required this.time,
    required this.hostName,
    required this.capacity,
    required this.imageUrl,
    required this.tags,
    required this.coords,
    this.distanceToUser = -1,
    this.attendantIds = const [],
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

  factory Event.fromJson(Map<String, dynamic> json) {
    final DateTime parsedDate = DateTime.parse(json["starting_date"]).toLocal();
    return Event(
      attendantIds: List<String>.from(json['attendant_ids'] ?? []),
      eventId: json["id"],
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      desc: json['description'] ?? '',
      time: parsedDate,
      hostName: json['host_name'] ?? 'unknown',
      capacity: json['people_needed'],
      imageUrl: json['user_image_url'],
      tags: _fromJsonToEvents(json['categories'] as List<dynamic>),
      coords: LatLng((json['selected_lat'] as num).toDouble(), (json['selected_lon'] as num).toDouble()),
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

Color getColorBasedOnCategory(Event e) {
  switch (e.tags.first) {
    case Tag.animals:
      return Colors.green;
    case Tag.cleaning:
      return Colors.lightBlue;
    case Tag.community:
      return Colors.orange;
    case Tag.donation:
      return Colors.green;
    case Tag.emergency:
      return Colors.red;
    case Tag.environment:
      return Colors.green;
    case Tag.other:
      return Colors.grey;
    case Tag.skills:
      return const Color(0xFF00A86B);
    case Tag.support:
      return Colors.blue;
  }
}

List<Tag> _fromJsonToEvents(List<dynamic> events) {
  return events.map((e) => _fromString(e)).toList();
}
