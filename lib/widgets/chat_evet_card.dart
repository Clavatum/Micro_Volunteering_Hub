import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:micro_volunteering_hub/Screens/chat_room_screen.dart';
import 'package:micro_volunteering_hub/models/event.dart';
import 'package:micro_volunteering_hub/providers/user_provider.dart';

class ChatEventCard extends ConsumerWidget {
  final Event event;

  const ChatEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const Color primary = Color(0xFF00A86B);
    final userData = ref.read(userProvider);

    bool canChat = (event.userId == userData["id"] || 
      (userData["user_attended_events"] != null && userData["user_attended_events"].contains(event.eventId)));

    return GestureDetector(
      onTap: () {
        if (canChat){
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(event: event, userData: userData),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: canChat ? primary.withAlpha(18) : Colors.grey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withAlpha(80)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.event, color: Colors.white),
            ),
            const SizedBox(width: 12),
      
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title.isEmpty ? 'Event' : event.title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hosted by ${event.hostName}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsetsGeometry.all(12),
              child: Icon(Icons.chevron_right, color: primary)
            ),
          ],
        ),
      ),
    );
  }
}
