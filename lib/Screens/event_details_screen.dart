import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:micro_volunteering_hub/backend/client/requests.dart';
import 'package:micro_volunteering_hub/helper_functions.dart';
import 'package:micro_volunteering_hub/models/event.dart';
import 'package:micro_volunteering_hub/providers/events_provider.dart';
import 'package:micro_volunteering_hub/providers/user_provider.dart';
import 'package:micro_volunteering_hub/utils/snackbar_service.dart';

class EventDetailsScreen extends ConsumerWidget {
  final Event event;
  const EventDetailsScreen({
    super.key,
    required this.event,
  });

  Future<Map<String, bool>> _requestJoin(Map<String, dynamic> user, WidgetRef ref) async {
    var apiResponse = await joinEventAPI(event.eventId, user["id"], user["user_name"]);
    if(!apiResponse["ok"]){
      showGlobalSnackBar(apiResponse["msg"]);
      return {"success": false};
    }
    else{
      if(apiResponse["instant_join"]){
        showGlobalSnackBar("Joined to event successfully.");
        ref.read(eventsProvider.notifier).addAttendee(event.eventId, user["id"]);
      }
      else{
        showGlobalSnackBar("Sent join request to event organizer successfully.");
      }
      return {"success": true, "instant_join": apiResponse["instant_join"]};
    }
  }
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String _distance = '${event.distanceToUser}m';
    Map<String, dynamic> _userData = ref.watch(userProvider);
    List<String> attendedEvents = _userData["user_attended_events"] ?? List<String>.empty(growable: true);
    bool canJoin = (_userData['id'] != event.userId) && (!attendedEvents.any((e) => e == event.eventId));
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
                      var result = await _requestJoin(user, ref);
                      if (result["success"]!){
                        if(result["instant_join"]!){
                          ref.read(userProvider.notifier).attendEvent(event.eventId);
                        }
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
