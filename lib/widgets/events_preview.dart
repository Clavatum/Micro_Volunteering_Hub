import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:micro_volunteering_hub/Screens/chat_room_screen.dart';
import 'package:micro_volunteering_hub/models/event.dart';
import 'package:micro_volunteering_hub/screens/event_details_screen.dart';

class EventsPreview extends StatelessWidget {
  const EventsPreview({
    super.key,
    required this.events,
  });
  final List<Event> events;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height / 2 - 60,
      child: (events.isEmpty)
          ? Center(
              child: Text(
                'There is no desired events for your location...',
                style: GoogleFonts.poppins(color: Colors.black54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (context, index) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EventDetailsScreen(
                          event: events[index],
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 110,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: Image.network(
                            events[index].imageUrl,
                            width: (MediaQuery.of(context).size.width * 0.3).clamp(96.0, 160.0),
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 115,
                                color: Colors.green,
                                child: Center(
                                  child: Icon(Icons.event, size: 64, color: Colors.black),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                events[index].title.isEmpty ? "Unnamed Event" : events[index].title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    events[index].hostName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                  const SizedBox(width: 12,),
                                  const Icon(Icons.person_add, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${events[index].participantCount}/${events[index].capacity}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
