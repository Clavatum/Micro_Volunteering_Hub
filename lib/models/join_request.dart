class JoinRequest {
  final String eventId, hostId, requesterId, status, requesterName;

  const JoinRequest({
    required this.requesterId,
    required this.requesterName,
    required this.hostId,
    required this.status,
    required this.eventId,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      requesterName: json["requester_name"],
      eventId: json["event_id"],
      hostId: json['host_id'] ?? '',
      status: json['status'] ?? '',
      requesterId: json['requester_id'] ?? '',
    );
  }
}
