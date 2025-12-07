import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:micro_volunteering_hub/helper_functions.dart';
import 'package:micro_volunteering_hub/providers/events_provider.dart';
import 'package:micro_volunteering_hub/providers/user_provider.dart';
import 'package:micro_volunteering_hub/screens/map_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:micro_volunteering_hub/models/event.dart';
import 'package:uuid/uuid.dart';

class GetHelpScreen extends ConsumerStatefulWidget {
  const GetHelpScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GetHelpScreen> createState() => _GetHelpScreenState();
}

class _GetHelpScreenState extends ConsumerState<GetHelpScreen> {
  String cloudName = 'KEY';
  String APIkey = 'KEY';
  String unsignedPresetName = 'KEY';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _startDateTime;
  final int _durationHours = 1;
  int _peopleNeeded = 1;
  final _imagePicker = ImagePicker();
  File? _image;
  String? url;
  Map<String, dynamic>? _locationknowladge;

  final List<String> _durationOptions = [
    '15 minutes',
    '30 minutes',
    '1 hour',
    '2 hours',
    '4 hours',
    '8 hours',
    '1 day',
    '2 days',
  ];
  String? _selectedDuration;
  List<Tag> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> uploadToCloudinary() async {
    if (_image == null) return;
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

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
    if (_locationknowladge == null || _locationknowladge!['position'] == null || url == null) return;

    List<String> selectedCategoryNames = _selectedCategories.map((e) => e.name).toList();

    LatLng pos = _locationknowladge!['position'];
    var id = FirebaseAuth.instance.currentUser!.uid;
    var title = _descriptionController.text;
    var userName = FirebaseAuth.instance.currentUser!.displayName ?? 'unknown';

    Event event = Event(
      eventId: Uuid().v4(),
      userId: id,
      title: title,

      coords: pos,
      time: _startDateTime ?? DateTime.now(),
      hostName: userName,
      capacity: _peopleNeeded,
      imageUrl: url ?? 'not selected',
      tags: _selectedCategories,
    );

    Map<String, dynamic> eventData = {
      'createdAt': DateTime.now(),
      'expireAt': DateTime.now().add(
        Duration(hours: _durationHours),
      ),
      'event_id': event.eventId,
      'host_name': userName,
      'user_id': id,
      'selected_lat': pos.latitude.toString(),
      'selected_lon': pos.longitude.toString(),
      'user_image_url': url!,
      'categories': selectedCategoryNames,
      'description': title,
      'people_needed': _peopleNeeded.toString(),
      'duration': _durationHours.toString(),
      'starting_date': _startDateTime != null ? HelperFunctions.formatter.format(_startDateTime!) : 'null',
    };
    ref.read(userProvider.notifier).addUserEvent(event);
    ref.read(eventsProvider.notifier).addEvent(event);

    await FirebaseFirestore.instance.collection('event_info').add(eventData);
  }

  Future<void> handleImage() async {
    await uploadToCloudinary();
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
      _startDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
    });
  }

  String _formatStart() {
    if (_startDateTime == null) return 'Pick start';
    final dt = _startDateTime!.toLocal();
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final List<Tag> _categories = Tag.values;

    const Color primary = Color(0xFF00A86B);
    const Color bg = Color(0xFFF2F2F3);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 2,
        title: Text(
          'Get Help',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: bg,
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
                              child: Text('Pictures placeholder', style: GoogleFonts.poppins(color: Colors.white70)),
                            ),
                      onTap: () => pickImage(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Event description',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: .95),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                      hintText: 'Describe the event...',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a description' : null,
                    style: GoogleFonts.poppins(color: Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Location',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
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
                    child: InkWell(
                      onTap: () async {
                        Map<String, dynamic> map = await Navigator.of(
                          context,
                        ).push(MaterialPageRoute(builder: (context) => MapScreen()));
                        setState(() {
                          _locationknowladge = map;
                        });
                      },
                      child: Center(
                        child: Text(
                          _locationknowladge == null || _locationknowladge!['position'] == null
                              ? 'Tap to select a location'
                              : '${_locationknowladge!['address']}',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                          ).copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Category',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          // show multi-select sheet
                          final selected = await showModalBottomSheet<List<Tag>>(
                            context: context,
                            isScrollControlled: true,
                            builder: (ctx) {
                              final temp = _selectedCategories;
                              return StatefulBuilder(
                                builder: (context, setStateModal) {
                                  return Padding(
                                    padding: MediaQuery.of(context).viewInsets,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Select categories',
                                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 12),
                                          ..._categories.map((c) {
                                            final checked = temp.contains(c);
                                            return CheckboxListTile(
                                              value: checked,
                                              title: Text(c.name, style: GoogleFonts.poppins()),
                                              onChanged: (v) => setStateModal(() {
                                                if (v == true)
                                                  temp.add(c);
                                                else
                                                  temp.remove(c);
                                              }),
                                            );
                                          }),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                onPressed: () => Navigator.of(ctx).pop(_selectedCategories),
                                                child: Text('Cancel', style: GoogleFonts.poppins()),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                onPressed: () => Navigator.of(ctx).pop(temp),
                                                child: Text('Done', style: GoogleFonts.poppins()),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                          if (selected != null) {
                            setState(() => _selectedCategories = selected);
                          }
                        },
                        child: Text('Select Categories', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedCategories.isEmpty
                              ? 'No categories selected'
                              : '${_selectedCategories.length} selected',
                          style: GoogleFonts.poppins(color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_selectedCategories.isNotEmpty)
                    Wrap(spacing: 8, children: _selectedCategories.map((c) => Chip(label: Text(c.name))).toList()),
                  const SizedBox(height: 16),

                  Text(
                    'Start (date & time)',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: .95),
                            foregroundColor: primary,
                          ),
                          onPressed: () => _pickStartDateTime(context),
                          child: Text(
                            _formatStart(),
                            style: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Duration',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .95),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedDuration,
                      isExpanded: true,
                      decoration: const InputDecoration.collapsed(hintText: ''),
                      hint: Text('Select duration', style: GoogleFonts.poppins(color: primary)),
                      items: _durationOptions
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text(d, style: GoogleFonts.poppins()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedDuration = v),
                      validator: (v) => (v == null || v.isEmpty) ? 'Please select duration' : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'People needed',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .95),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonFormField<int>(
                      initialValue: _peopleNeeded,
                      isExpanded: true,
                      decoration: const InputDecoration.collapsed(hintText: ''),
                      items: List.generate(30, (i) => i + 1)
                          .map(
                            (n) => DropdownMenuItem(
                              value: n,
                              child: Text(n.toString(), style: GoogleFonts.poppins()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _peopleNeeded = v ?? 1),
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (!(_formKey.currentState?.validate() ?? false)) return;
                              if (_startDateTime == null) {
                                ScaffoldMessenger.of(
                                  context,
                                ).clearSnackBars();
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(const SnackBar(content: Text('Please pick a start date/time')));
                                return;
                              }

                              if (_durationHours == 0) {
                                ScaffoldMessenger.of(
                                  context,
                                ).clearSnackBars();
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please pick duration'),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                _isLoading = true;
                              });

                              await uploadFirestore();
                              setState(() {
                                _isLoading = false;
                              });

                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(const SnackBar(content: Text('Event saved')));
                              Navigator.pop(context);
                            },
                      child: _isLoading ? CircularProgressIndicator() : Text('Submit'),
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
