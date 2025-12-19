import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:micro_volunteering_hub/utils/position_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  Position? _currentPosition;
  final MapController _mapController = MapController();
  double _currentZoom = 13;
  String? _selectedAddress;
  LatLng? _currentCenter;
  LatLng? tappedPos;

  String userAgent = '';
  bool _isUserAgentReady = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  Future<void> initUserAgent() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      userAgent = info.packageName;
      _isUserAgentReady = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    initUserAgent();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _centerToMyLocation() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        _currentZoom,
      );
      setState(() {
        _currentCenter = LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      });
    }
  }

  void incrementZoom() {
    if (_currentZoom < 18) {
      setState(() {
        _currentZoom += 1;
      });
      final center = _currentCenter ?? LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      _mapController.move(center, _currentZoom);
    }
  }

  void decreaseZoom() {
    if (_currentZoom > 1) {
      setState(() {
        _currentZoom -= 1;
      });
      final center = _currentCenter ?? LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      _mapController.move(center, _currentZoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPosition == null || !_isUserAgentReady) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade50, Colors.blue.shade100],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Map loading...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _currentCenter ??
                  LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
              initialZoom: _currentZoom,
              minZoom: 1,
              maxZoom: 18,
              onTap: (tapPosition, point) async {
                _animationController.forward();
                var selectedAddress = await PositionService.getHumanReadableAddressFromLatLng(
                  point.latitude,
                  point.longitude,
                );
                setState(() {
                  tappedPos = point;
                  _selectedAddress = selectedAddress;
                });
              },
              onPositionChanged: (position, hasGesture) {
                setState(() {
                  _currentCenter = position.center;
                  _currentZoom = position.zoom;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                userAgentPackageName: userAgent,
                maxZoom: 19,
              ),
              if (tappedPos != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: tappedPos!,
                      width: 60,
                      height: 60,
                      child: TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.elasticOut,
                        builder: (context, double value, child) {
                          return Transform.scale(scale: value, child: child);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(50),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            size: 45,
                            color: Colors.red,
                            shadows: [
                              Shadow(
                                blurRadius: 8,
                                color: Colors.black26,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withAlpha(100), Colors.transparent],
                ),
              ),
            ),
          ),

          Positioned(
            top: 50,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                color: Colors.black87,
              ),
            ),
          ),

          Positioned(
            top: 50,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: incrementZoom,
                    icon: const Icon(Icons.add, size: 22),
                    color: Colors.black87,
                    splashRadius: 24,
                  ),
                  Container(height: 1, width: 32, color: Colors.grey.shade200),
                  IconButton(
                    onPressed: decreaseZoom,
                    icon: const Icon(Icons.remove, size: 22),
                    color: Colors.black87,
                    splashRadius: 24,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: tappedPos != null ? 200 : 100,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withAlpha(100),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _centerToMyLocation,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(14.0),
                    child: Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (tappedPos != null && _selectedAddress != null)
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_fadeAnimation),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(51),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.red.shade600,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Selected Location',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedAddress!,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      tappedPos = null;
                                      _selectedAddress = null;
                                      _animationController.reverse();
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop({
                                      'user_position': _currentPosition,
                                      'position': tappedPos,
                                      'address': _selectedAddress,
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'Submit the location',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.check_circle, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
