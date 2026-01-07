import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:micro_volunteering_hub/backend/client/requests.dart';
import 'package:micro_volunteering_hub/helper_functions.dart';
import 'package:micro_volunteering_hub/models/event.dart';
import 'package:micro_volunteering_hub/models/join_request.dart';
import 'package:micro_volunteering_hub/providers/events_provider.dart';
import 'package:micro_volunteering_hub/providers/join_request_provider.dart';
import 'package:micro_volunteering_hub/providers/user_provider.dart';
import 'package:micro_volunteering_hub/utils/snackbar_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventDetailsScreen extends ConsumerWidget {
  final Event event;
  const EventDetailsScreen({
    super.key,
    required this.event,
  });

  Future<bool> _requestJoin(Map<String, dynamic> user, WidgetRef ref) async {
    /* NOT IMPLEMENTED YET DO NOT REMOVE
    var data = {
      'requester_name': user["user_name"],
      'event_id': event.eventId,
      'requester_id': user["id"],
      'host_id': event.userId,
      'status': 'pending',
      'requested_at': FieldValue.serverTimestamp(),
    };*/
    var apiResponse = await joinEventAPI(event.eventId, user["id"]);
    if(!apiResponse["ok"]){
      showGlobalSnackBar(apiResponse["msg"]);
      return false;
    }
    else{
      showGlobalSnackBar("Joined to event successfully.");
      ref.read(eventsProvider.notifier).addAttendee(event.eventId, user["id"]);
      return true;
    }
    /*JOIN REQUESTS WITH PENDING STATE ARE NOT IMPLEMENTED YET, DO NOT REMOVE
    await firestore.collection('join_requests').doc(requestId).set(data);
    ref
        .read(joinRequestProvider.notifier)
        .addJoinRequest(
          JoinRequest.fromJson(data),
        );*/
  }
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String _distance = '${event.distanceToUser}m';
    Map<String, dynamic> _userData = ref.watch(userProvider);
    List<String> attendedEvents = _userData["user_attended_events"];
    bool canJoin = (_userData['id'] != event.userId) && (!attendedEvents!.any((e) => e == event.eventId));
    const Color primary = Color(0xFF00A86B);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          event.title,
          style: GoogleFonts.poppins(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  event.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.green,
                      child: Center(
                        child: Icon(
                          Icons.event,
                          size: 64,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18),
                      const SizedBox(width: 6),
                      Text(_distance.toString(), style: GoogleFonts.poppins()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        HelperFunctions.formatter.format(event.time),
                        style: GoogleFonts.poppins(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.hostName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.group, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        event.capacity.toString(),
                        style: GoogleFonts.poppins(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                children: event.tags
                    .map(
                      (t) => Chip(
                        label: Text(
                          t.name,
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Text(
                'Description',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(event.desc, style: GoogleFonts.poppins(fontSize: 16)),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer(
            builder: (context, ref, _){
              final user = ref.watch(userProvider);
              return ElevatedButton(
                onPressed: canJoin
                  ? () async{
                      var success = await _requestJoin(user, ref);
                      if (success){
                        ref.read(userProvider.notifier).attendEvent(event.eventId);
                        Navigator.pop(context);
                      }
                    }
                  : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                ),
                child: Text('Join', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)
              ),
            );
            }
          ),
        ),
      ),
    );
  }
}
