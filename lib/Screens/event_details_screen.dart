import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:micro_volunteering_hub/helper_functions.dart';
import 'package:micro_volunteering_hub/models/event.dart';
import 'package:micro_volunteering_hub/providers/user_provider.dart';

class EventDetailsScreen extends ConsumerWidget {
  final Event event;
  const EventDetailsScreen({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var userData = ref.watch(userProvider);
    String _userLatS = userData['user_latitude']!;
    String _userLonS = userData['user_longitude']!;
    double _userLat = double.tryParse(_userLatS)!;
    double _userLon = double.tryParse(_userLonS)!;

    String _distance = HelperFunctions.getStringDistance(
      _userLat,
      _userLon,
      event,
    );

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
              if (event.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(event.imageUrl, width: double.infinity, height: 200, fit: BoxFit.cover),
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
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text('Join action (placeholder)'),
                    ),
                  );
                },
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
