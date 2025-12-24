import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:geolocator/geolocator.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:micro_volunteering_hub/models/event.dart';
import 'package:micro_volunteering_hub/models/join_request.dart';
import 'package:micro_volunteering_hub/providers/events_provider.dart';
import 'package:micro_volunteering_hub/providers/join_request_provider.dart';
import 'package:micro_volunteering_hub/providers/user_provider.dart';
import 'package:micro_volunteering_hub/widgets/event_dialog.dart';

class HelpOthersScreen extends ConsumerStatefulWidget {
  const HelpOthersScreen({super.key});

  @override
  ConsumerState<HelpOthersScreen> createState() => _HelpOthersScreenState();
}

class _HelpOthersScreenState extends ConsumerState<HelpOthersScreen> {
  late MapController _mapController;
  List<String> selectedTags = [];
  Map<String, dynamic>? _userData;
  Position? _currentPosition;

  void _centerMapToUser() {
    if (_currentPosition == null) return;
    _mapController.move(
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      13.0,
    );
  }

  void _showEventDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) => EventDialog(
        event: event,
        onJoin: () async {
          await _requestJoin(
            eventId: event.eventId,
            userId: _userData!['id'] ?? '',
            hostId: event.userId,
          );
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _zoomIn() {
    try {
      final center = _mapController.camera.center;
      final zoom = _mapController.camera.zoom;
      _mapController.move(center, zoom + 1);
    } catch (e) {
      debugPrint('zoomIn failed: $e');
      try {
        _mapController.move(LatLng(41.0082, 28.9784), 15.0);
      } catch (_) {}
    }
  }

  void _zoomOut() {
    try {
      final center = _mapController.camera.center;
      final zoom = _mapController.camera.zoom;
      _mapController.move(center, zoom - 1);
    } catch (e) {
      debugPrint('zoomOut failed: $e');
      try {
        _mapController.move(LatLng(41.0082, 28.9784), 13.0);
      } catch (_) {}
    }
  }

  Future<void> _requestJoin({
    required String eventId,
    required String userId,
    required String hostId,
  }) async {
    final firestore = FirebaseFirestore.instance;
    /* userId represents id of requesting persons id whereas hostId repr. host
 */
    final requestId = "${eventId}_$userId";
    var data = {
      'requester_name': _userData!['user_name'],
      'event_id': eventId,
      'requester_id': userId,
      'host_id': hostId,
      'status': 'pending',
      'requested_at': FieldValue.serverTimestamp(),
    };

    await firestore.collection('join_requests').doc(requestId).set(data);
    ref
        .read(joinRequestProvider.notifier)
        .addJoinRequest(
          JoinRequest.fromJson(data),
        );
  }

  late ProviderSubscription _userSub;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _userSub = ref.listenManual(
      userProvider,
      (previous, next) {
        final pos = next?["user_position"] as Position?;

        if (pos != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(
              LatLng(pos.latitude, pos.longitude),
              14.0,
            );
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _userSub.close();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);
    final watchedUser = ref.watch(userProvider);

    _userData = watchedUser;
    try {
      _currentPosition = _userData == null
          ? null
          : _userData!["user_position"] as Position?;
    } catch (_) {
      _currentPosition = null;
    }

    final filteredEvents = selectedTags.isEmpty
        ? events
        : events
              .where((e) => e.tags.any((t) => selectedTags.contains(t.name)))
              .toList();
    const Color primary = Color(0xFF00A86B);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 2,
        title: Text(
          'Help Others',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                onMapReady: _centerMapToUser,
                initialCenter: _currentPosition != null
                    ? LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      )
                    : const LatLng(41.0082, 28.9784),
                initialZoom: 14.0,
                minZoom: 5.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c'],
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    if (_currentPosition != null)
                      Marker(
                        point: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withAlpha(100),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ...filteredEvents.map(
                      (event) => Marker(
                        point: event.coords,
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () {
                            _showEventDialog(event);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withAlpha(100),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_currentPosition == null)
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'No location, centered to Istanbul',
                      style: GoogleFonts.poppins(color: Colors.black87),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 120,
              right: 16,
              child: Column(
                children: [
                  Material(
                    color: Colors.white,
                    elevation: 2,
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: [
                        IconButton(
                          onPressed: _zoomIn,
                          icon: const Icon(Icons.add, color: primary),
                          iconSize: 24,
                        ),
                        IconButton(
                          onPressed: _zoomOut,
                          icon: const Icon(Icons.remove, color: primary),
                          iconSize: 24,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    backgroundColor: primary,
                    mini: true,
                    onPressed: _centerMapToUser,
                    tooltip: 'Center to my location',
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 5,
              left: 0,
              right: 0,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: Tag.values.map((tag) {
                      final isSelected = selectedTags.contains(tag.name);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(
                            tag.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: primary,
                          backgroundColor: Colors.grey[200],
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedTags.add(tag.name);
                              } else {
                                selectedTags.remove(tag.name);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
