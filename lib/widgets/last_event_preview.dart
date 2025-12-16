import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:micro_volunteering_hub/Screens/event_details_screen.dart';
import 'package:micro_volunteering_hub/models/event.dart';

class LastEventPreview extends StatelessWidget {
  final Event event;
  const LastEventPreview({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return EventDetailsScreen(event: event);
          },
        ),
      ),
      child: Container(
        height: 220,
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade200,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60), // hafif shadow
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                event.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.green,
                    child: Center(
                      child: Icon(Icons.event, size: 64, color: Colors.black,)
                    ),
                  );
                },
              )
            ),

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withAlpha(13), // was opacity 0.05
                      Colors.black.withAlpha(180), // was 0.7
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(230), // was opacity 0.9
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Last Event",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        event.hostName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withAlpha(230), // was 0.9
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "${event.time.day}.${event.time.month}.${event.time.year}",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withAlpha(230), // was 0.9
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
