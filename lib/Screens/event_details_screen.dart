import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EventDetailsScreen extends StatelessWidget {
  final String title;
  final String distance;
  final String time;
  final String host;
  final String capacity;
  final String image;
  final List<String> tags;

  const EventDetailsScreen({
    Key? key,
    required this.title,
    this.distance = '',
    this.time = '',
    this.host = '',
    this.capacity = '',
    this.image = '',
    this.tags = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title, style: GoogleFonts.poppins())),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (image.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(image, width: double.infinity, height: 200, fit: BoxFit.cover),
                ),
              const SizedBox(height: 12),
              Text(title, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(Icons.location_on, size: 18),
                  const SizedBox(width: 6),
                  Text(distance, style: GoogleFonts.poppins()),
                  const SizedBox(width: 12),
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 6),
                  Text(time, style: GoogleFonts.poppins()),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 18),
                  const SizedBox(width: 6),
                  Text(host, style: GoogleFonts.poppins()),
                  const SizedBox(width: 12),
                  const Icon(Icons.group, size: 18),
                  const SizedBox(width: 6),
                  Text(capacity, style: GoogleFonts.poppins()),
                ],
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                children: tags.map((t) => Chip(label: Text(t, style: GoogleFonts.poppins(fontSize: 12)))).toList(),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Join action (placeholder)')));
                },
                child: Text('Join', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
