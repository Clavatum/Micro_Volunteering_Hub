class JoinRequest {
  final String eventId, hostId, attendentId, status;

  const JoinRequest({
    required this.attendentId,
    required this.hostId,
    required this.status,
    required this.eventId,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      eventId: json["event_id"],
      hostId: json['user_id'] ?? '',
      status: json['status'] ?? '',
      attendentId: json['attended_id'] ?? '',
    );
  }
}
