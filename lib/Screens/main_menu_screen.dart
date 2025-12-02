import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:micro_volunteering_hub/models/event.dart';
import 'package:micro_volunteering_hub/providers/user_events_provider.dart';
import 'package:micro_volunteering_hub/providers/user_provider.dart';
import 'profile_screen.dart';
import 'event_details_screen.dart';
import 'get_help_screen.dart';
import 'help_others_screen.dart';

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen> {
  int _navIndex = 0;
  final Color primary = const Color(0xFF00A86B);
  final Color background = const Color(0xFFF2F2F3);

  List<Event>? _events;
  Map<String, dynamic>? _userData;
  List<Event>? _closeEvents;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _handleClose();
  }

  Future<void> _handleClose() async {
    _userData = ref.read(userProvider);

    try {
      await _getEventsFromFirebase();
      _userData = ref.read(userProvider);
      _setDistances();
      _setCloseEvents();
    } catch (e) {
      debugPrint('Error loading events: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getEventsFromFirebase() async {
    final snap = await FirebaseFirestore.instance.collection('event_info').get();
    _events = snap.docs.map((doc) => Event.fromJson(doc.data(), doc.id)).toList();
  }

  void _setDistances() {
    if (_events == null || _userData == null) return;
    for (Event e in _events!) {
      e.setIsClose(
        double.tryParse(_userData!['user_latitude'] ?? '-1000000000') ?? -1000000000,
        double.tryParse(_userData!['user_longitude'] ?? '-1000000000') ?? -1000000000,
      );
    }
  }

  void _setCloseEvents() {
    if (_events == null) return;
    _closeEvents = _events!.where((e) => e.isClose == true).toList();
  }

  void _showCreateModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'What do you want to do?',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GetHelpScreen()),
                  );
                },
                icon: const Icon(Icons.help),
                label: const Text('Get Help'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HelpOthersScreen()),
                  );
                },
                icon: const Icon(Icons.volunteer_activism),
                label: const Text('Help Others'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: background,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Hello, ${FirebaseAuth.instance.currentUser!.displayName}!',
                      overflow: TextOverflow.clip,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ready to help someone today?',
                      style: GoogleFonts.poppins(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: (_events?.isEmpty ?? true)
                          ? const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 24,
                            )
                          : EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: (_events?.isEmpty ?? true)
                          ? Text(
                              'No active events yet\n tap + to get started',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : Image.network(
                              _events!.last.imageUrl,
                              fit: BoxFit.cover,
                              height: 100,
                            ),
                    ),

                    const SizedBox(height: 18),
                    Text(
                      'Nearby Events - Join Instantly',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),

                    Column(
                      children: (_closeEvents?.isEmpty ?? true)
                          ? [
                              Center(
                                child: Text(
                                  'There is no close events to your location...',
                                  style: GoogleFonts.poppins(color: Colors.black54),
                                ),
                              ),
                            ]
                          : _closeEvents!.map((e) {
                              return Container(
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
                                        builder: (_) => EventDetailsScreen(event: e),
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
                                            e.imageUrl,
                                            width: (MediaQuery.of(context).size.width * 0.34).clamp(96.0, 160.0),
                                            height: 110,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 8,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  e.title,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 18,
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
                                                      e.hostName,
                                                      overflow: TextOverflow.clip,
                                                      style: GoogleFonts.poppins(fontSize: 14),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                    ),
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.03,
            minChildSize: 0.03,
            maxChildSize: 0.35,
            builder: (context, controller) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      width: 40,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: controller,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Call (placeholder)'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.call),
                                ),
                                IconButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Navigate (placeholder)'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.directions),
                                ),
                                IconButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Share (placeholder)'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.share),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateModal,
        shape: CircleBorder(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: Colors.white,
        notchMargin: 6,
        child: SizedBox(
          height: 60,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => setState(() => _navIndex = 0),
                  icon: Icon(
                    Icons.home,
                    color: _navIndex == 0 ? primary : Colors.black54,
                  ),
                ),
                const SizedBox(width: 155),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  icon: Icon(
                    Icons.person,
                    color: _navIndex == 1 ? primary : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
