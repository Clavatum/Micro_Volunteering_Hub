import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:micro_volunteering_hub/backend/client/requests.dart';
import 'package:micro_volunteering_hub/models/event.dart';
import 'package:micro_volunteering_hub/providers/close_events_provider.dart';
import 'package:micro_volunteering_hub/providers/events_provider.dart';
import 'package:micro_volunteering_hub/providers/position_provider.dart';
import 'package:micro_volunteering_hub/providers/user_provider.dart';
import 'package:micro_volunteering_hub/widgets/events_preview.dart';
import 'package:micro_volunteering_hub/widgets/last_event_preview.dart';
import 'package:micro_volunteering_hub/utils/position_service.dart';
import 'profile_screen.dart';
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

  Timer? _positionTimer;
  Timer? _pollingTimer;
  int? _lastFetchTs;
  bool _isFetching = false;

  @override
  void initState(){
    super.initState();
    _init();
  }

  Future<void> _init() async {
    //await _getEventsFromFirebase();
    _userData = ref.read(userProvider);
    _setCloseEvents();
    await fetchEvents();
    startPositionTimer();
    startEventPolling();
    if (mounted){
      setState(() => _isLoading = false);
    }
  }

  Future<void> fetchEvents() async{
    if(_isFetching) return;
    _isFetching = true;
    try{
      final fetchedEvents = await fetchEventsAPI(_lastFetchTs);
      if (fetchedEvents.events.isNotEmpty){
        _lastFetchTs = fetchedEvents.lastTs;
        ref.read(eventsProvider.notifier).addEvents(fetchedEvents.events);
        if(_userData != null){
          ref.read(userProvider.notifier).setUserEvents(
            fetchedEvents.events.where((e) => e.userId == _userData!['id']).toList(),
          );
        }
      }
    }catch(e){
      debugPrint("fetchEvents has failed: $e");
    }finally{
      _isFetching = false;
      _events = ref.watch(eventsProvider);
    }
  }
  Future<void> startEventPolling() async{
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try{
        await fetchEvents();
      }catch(e){
        print("Something went wrong while fetching events: $e");
      }
    });
  }
  
  void stopEventPolling(){
    _pollingTimer?.cancel();
  }

  Future<void> startPositionTimer() async{
    _positionTimer = Timer.periodic(const Duration(seconds: 5), (_) async{
      try{
        final position = ref.watch(positionNotifierProvider);
        if (position == null) return;
        ref.read(userProvider.notifier).setUserPosition(lat: position.latitude, lon: position.longitude);
        _userData = ref.watch(userProvider);
        //Update event distances
        _setDistances();
      }catch (e){
        print("Error while reading position: $e");
      }
    });
  }

  void stopPositionTimer(){
    _positionTimer?.cancel();
  }
  void _setDistances() {
    if (_events == null || _userData == null) return;
    for (Event e in _events!) {
      e.setIsClose(
        _userData!['user_latitude'] ?? -1000000000,
        _userData!['user_longitude'] ?? -1000000000,
      );
    }
  }

  void _setCloseEvents() {
    if (_events == null) return;
    _closeEvents = _events!.where((e) => e.isClose == true).toList();
    ref.read(closeEventsProvider.notifier).setEvents(_closeEvents!);
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
                    MaterialPageRoute(builder: (_) => GetHelpScreen()),
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

  bool isLoading = true;
  @override
  void dispose(){
    stopEventPolling();
    stopPositionTimer();
    super.dispose();
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
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? "Guest";
    return Scaffold(
      extendBody: true,
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $name!',
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

                if (_events != null && _events!.isNotEmpty)
                  LastEventPreview(event: _events!.last)
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'No events yet',
                      style: GoogleFonts.poppins(color: Colors.black54),
                    ),
                  ),

                const SizedBox(height: 8),
                Text(
                  'Nearby Events - Join Instantly',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                if (_closeEvents != null && _closeEvents!.isNotEmpty)
                  EventsPreview(events: _closeEvents!)
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'No nearby events',
                      style: GoogleFonts.poppins(color: Colors.black54),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateModal,
        shape: const CircleBorder(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white, size:32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: Colors.white,
        notchMargin: 6,
        child: SizedBox(
          height: 80,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: IconButton(
                    onPressed: () => setState(() => _navIndex = 0),
                    icon: Icon(
                      Icons.home,
                      size: 32,
                      color: _navIndex == 0 ? primary : Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(width: 75),
                Expanded(
                  child: IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                    icon: Icon(
                      Icons.person,
                      size: 32,
                      color: _navIndex == 1 ? primary : Colors.black54,
                    ),
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
