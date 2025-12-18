import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:micro_volunteering_hub/helper_functions.dart';
import 'package:micro_volunteering_hub/models/event.dart';
import 'package:micro_volunteering_hub/providers/user_provider.dart';
import 'package:micro_volunteering_hub/utils/snackbar_service.dart';

class EventDetailsScreen extends ConsumerWidget {
  final Event event;
  const EventDetailsScreen({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String _distance = '${event.distanceToUser}m';
    Map<String, dynamic> _userData = ref.watch(userProvider);
    bool canJoin = _userData['id'] != event.userId;

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
                      child: Center(child: Icon(Icons.event, size: 64,),),
                    );
                  },
                )
              ),
              const SizedBox(height: 12),
              Text(event.title, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(Icons.location_on, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _distance.toString(),
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 6),
                  Text(HelperFunctions.formatter.format(event.time), style: GoogleFonts.poppins()),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 18),
                  const SizedBox(width: 6),
                  Text(event.hostName, style: GoogleFonts.poppins()),
                  const SizedBox(width: 12),
                  const Icon(Icons.group, size: 18),
                  const SizedBox(width: 6),
                  Text(event.capacity.toString(), style: GoogleFonts.poppins()),
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

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: canJoin
                    ? () {
                        showGlobalSnackBar("Join action (placeholder)");
                      }
                    : null,
                child: Text(
                  'Join',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
