import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:micro_volunteering_hub/models/join_request.dart';
import 'package:micro_volunteering_hub/providers/events_provider.dart';
import 'package:micro_volunteering_hub/providers/join_request_provider.dart';

import 'chat_screen.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  void _removeLocally(JoinRequest req) {
    ref.read(joinRequestProvider.notifier).removeJoinRequest(req);
  }

  Future<void> _acceptRequest(JoinRequest r) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.runTransaction((tx) async {
      final joinRef = firestore.collection('join_requests').doc('${r.eventId}_${r.requesterId}');
      final eventRef = firestore.collection('event_info').doc(r.eventId);

      final eventSnap = await tx.get(eventRef);

      final List ids = List.from(eventSnap['attendant_ids'] ?? []);
      final int capacity = eventSnap['people_needed'];

      if (ids.length >= capacity) {
        throw Exception('Event full');
      }

      tx.update(joinRef, {'status': 'approved'});
      tx.update(eventRef, {
        'attendant_ids': FieldValue.arrayUnion([r.requesterId]),
      });
    });

    _removeLocally(r);
  }

  Future<void> _rejectRequest(JoinRequest req) async {
    final docId = '${req.eventId}_${req.requesterId}';

    await FirebaseFirestore.instance.collection('join_requests').doc(docId).update({
      'status': 'rejected',
    });
    _removeLocally(req);
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF00A86B);
    var events = ref.watch(eventsProvider);
    var _requestsB = ref.watch(joinRequestProvider);
    var _requests = _requestsB.where((e) => e.hostId == FirebaseAuth.instance.currentUser!.uid).toList();

    String getEventName(JoinRequest req) {
      final e = events.where((e) => e.eventId == req.eventId);
      return e.isNotEmpty
          ? e.first.title.isEmpty
                ? "unknown"
                : e.first.title
          : 'your event';
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 2,
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _requests.isEmpty
          ? Center(
              child: Text('No notifications yet!'),
            )
          : ListView.builder(
              itemCount: _requests.length,
              itemBuilder: (ctx, index) {
                var request = _requests[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primary.withAlpha(25),
                    child: Icon(Icons.person, color: primary),
                  ),

                  title: Text(
                    "${request.requesterName} wants to join your ${getEventName(request)} event",
                  ),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () async {
                            await _acceptRequest(request);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            await _rejectRequest(request);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
