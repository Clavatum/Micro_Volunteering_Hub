import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:micro_volunteering_hub/helper_functions.dart';
import 'package:micro_volunteering_hub/models/event.dart';
import 'package:micro_volunteering_hub/providers/user_provider.dart';

class EventDialog extends ConsumerWidget {
  final Event event;
  final VoidCallback? onJoin;

  const EventDialog({
    super.key,
    required this.event,
    this.onJoin,
  });

  Future<String?> _fetchAddress() async {
    try {
      final coords = event.coords;
      final placemarks = await placemarkFromCoordinates(
        coords.latitude,
        coords.longitude,
      );

      final p = placemarks.first;
      return "${p.street}, ${p.locality}, ${p.administrativeArea}";
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchCreator() async {
    final query = await FirebaseFirestore.instance
        .collection('user_info')
        .where('id', isEqualTo: event.userId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first.data();
  }

  Future<_DialogData> _loadDialogData() async {
    final results = await Future.wait([
      _fetchAddress(),
      _fetchCreator(),
    ]);

    return _DialogData(
      address: results[0] as String?,
      creator: results[1] as Map<String, dynamic>?,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var _userData = ref.watch(userProvider);
    bool canJoin = _userData['id'] != event.userId;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            (event.imageUrl.isNotEmpty)
                ? Container(
                    height: 170,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(event.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: 170,
                    color: Colors.green,
                  ),

            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(35),
                    border: Border.all(
                      color: Colors.white.withAlpha(60),
                      width: 1.2,
                    ),
                  ),
                  child: FutureBuilder<_DialogData>(
                    future: _loadDialogData(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }

                      final data = snapshot.data!;
                      return _buildContent(context, data.address, data.creator, canJoin);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, String? address, Map<String, dynamic>? creator, bool canJoin) {
    final maxHeight = MediaQuery.of(context).size.height * 0.5;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withAlpha(40),
                      backgroundImage: creator != null ? NetworkImage(creator["photo_url"]) : null,
                      child: creator == null ? const Icon(Icons.person, color: Colors.white70) : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.hostName,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withAlpha(230),
                            ),
                          ),
                          Text(
                            "Event Organizer",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withAlpha(180),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Text(
                  event.title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withAlpha(230),
                  ),
                ),

                const SizedBox(height: 16),

                _infoRow(Icons.people_alt_outlined, "${event.capacity} people needed"),

                const SizedBox(height: 10),

                _infoRow(
                  Icons.schedule,
                  HelperFunctions.formatter.format(event.time),
                ),

                const SizedBox(height: 10),

                if (event.distanceToUser != -1)
                  _infoRow(
                    Icons.near_me,
                    "${event.distanceToUser} m away",
                  ),

                const SizedBox(height: 10),

                _infoRow(
                  Icons.location_on,
                  address ?? "Loading location...",
                ),

                const SizedBox(height: 18),

                if (event.tags.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Categories",
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: event.tags
                            .map(
                              (tag) => Chip(
                                label: Text(
                                  tag.name.toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: const Color(0xFF00A86B).withAlpha(150),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                Text(
                  event.desc,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withAlpha(220),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 26),

        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: canJoin ? onJoin ?? () => Navigator.of(context).pop() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A86B).withAlpha(220),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "Join Event",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Colors.white.withAlpha(120),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.white.withAlpha(230),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withAlpha(220), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withAlpha(220),
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogData {
  final String? address;
  final Map<String, dynamic>? creator;

  _DialogData({
    required this.address,
    required this.creator,
  });
}
