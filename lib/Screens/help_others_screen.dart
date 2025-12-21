import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:micro_volunteering_hub/models/event.dart';
import 'package:micro_volunteering_hub/providers/events_provider.dart';
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

  @override
  void initState() {
    _mapController = MapController();
    super.initState();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _centerMapToUser() {
    if (_userData == null || _userData!.isEmpty) {
      return;
    }
    Position? position = _userData!["user_position"];
    if (position == null) {
      return;
    }
    _mapController.move(LatLng(position.latitude, position.longitude), 13.0);
  }

  void _showEventDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) => EventDialog(
        event: event,
        onJoin: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Joined: ${event.title}',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF00A86B),
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        },
      ),
    );
  }

  void _zoomIn() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom + 1,
    );
  }

  void _zoomOut() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom - 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);
    _userData = ref.watch(userProvider);
    _currentPosition = _userData!["user_position"];

    final allTags = <String>{for (final e in events) ...e.tags.map((t) => t.name)}.toList();

    final filteredEvents = selectedTags.isEmpty
        ? events
        : events.where((e) => e.tags.any((t) => selectedTags.contains(t.name))).toList();
    const Color primary = Color(0xFF00A86B);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 2,
        title: Text(
          'Help Others',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,

      body: events.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No events available',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    onMapReady: _centerMapToUser,
                    initialCenter: _currentPosition != null
                        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                        : const LatLng(41.0082, 28.9784),
                    initialZoom: 13.0,
                    minZoom: 5.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c'],
                      maxZoom: 19,
                    ),
                    MarkerLayer(
                      markers: [
                        if (_currentPosition != null)
                          Marker(
                            point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            width: 50,
                            height: 50,
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Your location',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.blue,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withAlpha(220),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withAlpha(150),
                                      blurRadius: 12,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_pin_circle,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),

                        ...filteredEvents.map(
                          (event) => Marker(
                            point: event.coords,
                            width: 50,
                            height: 50,
                            child: GestureDetector(
                              onTap: () => _showEventDialog(event),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(220),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withAlpha(150),
                                      blurRadius: 12,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                Positioned(
                  top: 150,
                  right: 16,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(230),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(50),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            IconButton(
                              onPressed: _zoomIn,
                              icon: const Icon(
                                Icons.add,
                                color: Colors.black,
                              ),
                              iconSize: 20,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            Container(
                              height: 1,
                              width: 24,
                              color: Colors.grey[300],
                            ),
                            IconButton(
                              onPressed: _zoomOut,
                              icon: const Icon(
                                Icons.remove,
                                color: Colors.black,
                              ),
                              iconSize: 20,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  bottom: 24,
                  right: 16,
                  child: FloatingActionButton(
                    backgroundColor: const Color(0xFF00A86B),
                    mini: false,
                    onPressed: _centerMapToUser,
                    tooltip: 'Center on my location',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Tag Chip’leri
                Positioned(
                  top: 90,
                  left: 0,
                  right: 0,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: allTags.map((tag) {
                        final isSelected = selectedTags.contains(tag);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(
                              tag,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFF00A86B),
                            backgroundColor: Colors.grey[200],
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedTags.add(tag);
                                } else {
                                  selectedTags.remove(tag);
                                }
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
