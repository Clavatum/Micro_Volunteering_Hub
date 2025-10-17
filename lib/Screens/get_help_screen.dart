import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class GetHelpScreen extends StatefulWidget {
  const GetHelpScreen({Key? key}) : super(key: key);

  @override
  State<GetHelpScreen> createState() => _GetHelpScreenState();
}

class _GetHelpScreenState extends State<GetHelpScreen> {
  String cloudName = 'dm2k6xcne';
  String APIkey = 'ipjhnrc2wVlb-zWv3aKmRKwV-og';
  String unsignedPresetName = 'microvolunteeringapp';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _startDateTime;
  int _durationHours = 1;
  int _peopleNeeded = 1;
  String? _category;
  final _imagePicker = ImagePicker();
  File? _image;
  String? url;
  String? _currentAddress;
  Position? _currentPosition;

  final List<String> _categories = [
    'Food distribution',
    'Cleaning',
    'Teaching',
    'Medical',
    'Logistics',
    'Other',
  ];

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    await Geolocator.getCurrentPosition()
        .then((Position position) {
          setState(() => _currentPosition = position);
        })
        .catchError((e) {
          debugPrint(e);
        });
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location services are disabled. Please enable the services',
          ),
        ),
      );
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permissions are permanently denied, we cannot request permissions.',
          ),
        ),
      );
      return false;
    }
    return true;
  }

  Future<String> _getHumanReadableAddressFromLatLng() async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
    Placemark place = placemarks[0];
    return '${place.street}, ${place.subLocality},  ${place.subAdministrativeArea}, ${place.postalCode}';
  }

  @override
  void initState() {
    _getCurrentPosition();
    super.initState();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> uploadToCloudinary() async {
    if (_image == null) return;
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    var request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = unsignedPresetName
      ..files.add(await http.MultipartFile.fromPath('file', _image!.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final jsonResp = json.decode(respStr);
      this.url = jsonResp['secure_url'];
    } else {
      print('Upload failed with status: ${response.statusCode}');
      return;
    }
  }

  Future<void> uploadFirestore() async {
    if (_currentPosition == null || url == null) return;

    Map<String, String> data = {
      'user_lat': _currentPosition!.latitude.toString(),
      'user_lng': _currentPosition!.longitude.toString(),
      // 'user_mail': FirebaseAuth.instance.currentUser!.email!,
      'user_image_url': url!,
    };
    await FirebaseFirestore.instance.collection('user_info').add(data);
  }

  Future<void> handleImage() async {
    await uploadToCloudinary();
    await uploadFirestore();
  }

  Future<void> _pickImageFromGallery() async {
    var image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _image = File(image.path);
    });
    await handleImage();
  }

  Future<void> _pickImageFromCamera() async {
    var image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    setState(() {
      _image = File(image.path);
    });
    await handleImage();
  }

  void pickImage() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SizedBox(
        height: 150,
        child: Column(
          children: [
            SizedBox(width: double.infinity),
            ElevatedButton(
              onPressed: () {
                _pickImageFromCamera();
                Navigator.pop(context);
              },
              child: Text('Select from camera'),
            ),
            ElevatedButton(
              onPressed: () {
                _pickImageFromGallery();
                Navigator.pop(context);
              },
              child: Text('Select from gallery'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartDateTime(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDateTime ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate == null) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDateTime ?? now),
    );
    if (pickedTime == null) return;
    setState(() {
      _startDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  String _formatStart() {
    if (_startDateTime == null) return 'Pick start';
    final dt = _startDateTime!.toLocal();
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF5E35B1);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 2,
        title: Text(
          'Get Help',
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFf6d365), Color(0xFFfda085)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: InkWell(
                      child: _image != null
                          ? Image.file(_image!, fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                'Pictures placeholder',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                      onTap: () => pickImage(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Event description',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: .95),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      hintText: 'Describe the event...',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter a description'
                        : null,
                    style: GoogleFonts.poppins(color: Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Location',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 72,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Center(
                      child: Text(
                        'Location placeholder',
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Category',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .95),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _category,
                        hint: Text(
                          'Select category',
                          style: GoogleFonts.poppins(color: primary),
                        ),
                        isExpanded: true,
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  style: GoogleFonts.poppins(
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _category = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Start (date & time)',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: .95,
                            ),
                            foregroundColor: primary,
                          ),
                          onPressed: () => _pickStartDateTime(context),
                          child: Text(
                            _formatStart(),
                            style: GoogleFonts.poppins(
                              color: primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Duration (hours)',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(
                          () => _durationHours = (_durationHours - 1).clamp(
                            1,
                            999,
                          ),
                        ),
                        icon: Icon(Icons.remove_circle_outline, color: primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_durationHours hrs',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => setState(
                          () => _durationHours = (_durationHours + 1).clamp(
                            1,
                            999,
                          ),
                        ),
                        icon: Icon(Icons.add_circle_outline, color: primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'People needed',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(
                          () =>
                              _peopleNeeded = (_peopleNeeded - 1).clamp(1, 999),
                        ),
                        icon: Icon(Icons.remove_circle_outline, color: primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_peopleNeeded',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => setState(
                          () =>
                              _peopleNeeded = (_peopleNeeded + 1).clamp(1, 999),
                        ),
                        icon: Icon(Icons.add_circle_outline, color: primary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        textStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () async {
                        if (!(_formKey.currentState?.validate() ?? false))
                          return;
                        if (_startDateTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please pick a start date/time'),
                            ),
                          );
                          return;
                        }

                        final event = {
                          'description': _descriptionController.text.trim(),
                          'start': _startDateTime!.toIso8601String(),
                          'duration_hours': _durationHours,
                          'people_needed': _peopleNeeded,
                          'created_at': DateTime.now().toIso8601String(),
                        };

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Event saved (local only)'),
                          ),
                        );
                        Navigator.pop(context, event);
                      },
                      child: Text('Submit'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
