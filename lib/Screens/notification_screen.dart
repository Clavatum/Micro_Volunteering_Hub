import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:micro_volunteering_hub/backend/client/requests.dart';
import 'package:micro_volunteering_hub/models/join_request.dart';
import 'package:micro_volunteering_hub/providers/events_provider.dart';
import 'package:micro_volunteering_hub/providers/join_request_provider.dart';
import 'package:micro_volunteering_hub/utils/snackbar_service.dart';


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
    var apiResponse = await eventRequestsAPI(r.eventId, r.requesterId, "approve");
    if(apiResponse["ok"]){
      showGlobalSnackBar("Approved join request successfully.");
      _removeLocally(r);
    }
    else{
      showGlobalSnackBar(apiResponse["msg"]);
    }
  }

  Future<void> _rejectRequest(JoinRequest req) async {
    var apiResponse = await eventRequestsAPI(req.eventId, req.requesterId, "reject");
    if(apiResponse["ok"]){
      showGlobalSnackBar("Rejected join request successfully.");
      _removeLocally(req);
    }
    else{
      showGlobalSnackBar(apiResponse["msg"]);
    }
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
