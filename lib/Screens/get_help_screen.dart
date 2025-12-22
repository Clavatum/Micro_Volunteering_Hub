import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:micro_volunteering_hub/backend/client/requests.dart';
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
import 'package:micro_volunteering_hub/utils/snackbar_service.dart';
import 'package:uuid/uuid.dart';

class GetHelpScreen extends ConsumerStatefulWidget {
  const GetHelpScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GetHelpScreen> createState() => _GetHelpScreenState();
}

class _GetHelpScreenState extends ConsumerState<GetHelpScreen> {
  String cloudName = 'dm2k6xcne';
  String APIkey = 'ipjhnrc2wVlb-zWv3aKmRKwV-og';
  String unsignedPresetName = 'microvolunteeringapp';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _startDateTime;
  int _durationMinutes = 0;
  int _peopleNeeded = 1;
  final _imagePicker = ImagePicker();
  File? _image;
  String? url;
  Map<String, dynamic>? _locationknowledge;
  final FocusNode _dummyFocusNode = FocusNode();

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
  final List<int> durations = [15, 30, 60, 120, 240, 480, 1440, 2880];
  String? _selectedDuration;
  List<Tag> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
     _dummyFocusNode.dispose();
    _titleController.dispose();
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

  Future<bool> uploadFirestore() async {
    if (_locationknowledge == null || _locationknowledge!['position'] == null)
      return false;

    List<String> selectedCategoryNames = _selectedCategories
        .map((e) => e.name)
        .toList();

    LatLng pos = _locationknowledge!['position'];
    var id = FirebaseAuth.instance.currentUser!.uid;
    var title = _titleController.text;
    var desc = _descriptionController.text;
    var userName = FirebaseAuth.instance.currentUser!.displayName ?? 'unknown';

    Event event = Event(
      eventId: Uuid().v4(),
      userId: id,
      title: title,
      desc: desc,

      coords: pos,
      time: _startDateTime ?? DateTime.now(),
      hostName: userName,
      capacity: _peopleNeeded,
      imageUrl: url ?? 'not selected',
      tags: _selectedCategories,
    );

    Map<String, dynamic> eventData = {
      'host_name': userName,
      'user_id': id,
      'selected_lat': pos.latitude,
      'selected_lon': pos.longitude,
      'user_image_url': url ?? "",
      'categories': selectedCategoryNames,
      'title': title,
      'description': desc,
      'people_needed': _peopleNeeded,
      'duration': _durationMinutes, //Stored in minutes
      'starting_date': _startDateTime != null
          ? _startDateTime!.toUtc().toString()
          : "null",
    };
    var apiResponse = await createEventAPI(eventData);
    if (apiResponse["ok"]) {
      ref.read(userProvider.notifier).addUserEvent(event);

      if (Navigator.canPop(context)) {
        final mainMenuContext = Navigator.of(context);
      }
      return true;
    } else {
      showGlobalSnackBar(apiResponse["msg"]);
      return false;
    }
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
              child: Text('Select From Camera'),
            ),
            ElevatedButton(
              onPressed: () {
                _pickImageFromGallery();
                Navigator.pop(context);
              },
              child: Text('Select From Gallery'),
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
    if (_startDateTime == null) return 'Select Start Date';
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
        color: bg,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: FocusScope(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Title',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
              
                    const SizedBox(height: 8),
              
                    TextFormField(
                      controller: _titleController,
                      maxLength: 32,
                      maxLines: 1,
                      autofocus: false,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: .95),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        hintText: 'The title of event is...',
                        hintStyle: GoogleFonts.poppins(color: primary, fontSize: 16),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter a title'
                          : null,
                      style: GoogleFonts.poppins(color: primary,fontSize: 16),
                    ),
              
                    const SizedBox(height: 8),
              
                    Text(
                      'Event Description',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLength: 1024,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      autofocus: false,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: .95),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        hintText: 'Describe the event...',
                        hintStyle: GoogleFonts.poppins(color: primary, fontSize: 16),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter a description'
                          : null,
                      style: GoogleFonts.poppins(color: primary, fontSize: 16),
                    ),
              
                    const SizedBox(height: 8),
              
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
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black87),
                      ),
                      child: InkWell(
                        onTap: () async {
                          FocusScope.of(context).unfocus();
                          Map<String, dynamic>? map =
                              await Navigator.of(
                                context,
                              ).push(
                                MaterialPageRoute(
                                  builder: (context) => MapScreen(),
                                ),
                              );
                          setState(() {
                            _locationknowledge = map;
                          });
                          FocusScope.of(context).requestFocus(_dummyFocusNode);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_pin, size: 28, color: primary),
                            Flexible(
                              child: Text(
                                _locationknowledge == null ||
                                        _locationknowledge!['position'] == null
                                    ? 'Tap to Select a Location'
                                    : '${_locationknowledge!['address']}',
                                style:
                                    GoogleFonts.poppins(
                                      color: primary,
                                    ).copyWith(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 16
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              
                    const SizedBox(height: 16),
                    
                    Text(
                      'Picture (Optional)',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black),
                      ),
                      child: InkWell(
                        child: _image != null
                            ? Image.file(_image!, fit: BoxFit.cover)
                            : Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.photo, size: 28, color: primary),
                                    Text(
                                      'Tap to Add a Picture',
                                      style: GoogleFonts.poppins(color: primary, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                        onTap: () {
                          pickImage(); 
                          FocusScope.of(context).requestFocus(_dummyFocusNode);
                        },
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
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                                      padding: MediaQuery.of(
                                        context,
                                      ).viewInsets,
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Select Categories',
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            ..._categories.map((c) {
                                              final checked = temp.contains(
                                                c,
                                              );
                                              return CheckboxListTile(
                                                value: checked,
                                                activeColor: primary,
                                                checkColor: Colors.white,
                                                title: Text(
                                                  c.name,
                                                  style: GoogleFonts.poppins(fontSize: 16),
                                                ),
                                                onChanged: (v) =>
                                                    setStateModal(() {
                                                      if (v == true)
                                                        temp.add(c);
                                                      else
                                                        temp.remove(c);
                                                    }),
                                              );
                                            }),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  style: TextButton.styleFrom(
                                                    side: BorderSide(),
                                                    foregroundColor: primary,
                                                  ),
                                                  onPressed: () =>
                                                      Navigator.of(ctx).pop(
                                                        _selectedCategories,
                                                      ),
                                                  child: Text(
                                                    'Cancel',
                                                    style: GoogleFonts.poppins(
                                                      color: primary,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: primary
                                                        .withValues(alpha: .95),
                                                    foregroundColor: Colors.white,
                                                  ),
                                                  onPressed: () => Navigator.of(
                                                    ctx,
                                                  ).pop(temp),
                                                  child: Text(
                                                    'Done',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                    ),
                                                  ),
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
                            FocusScope.of(context).requestFocus(_dummyFocusNode);
                          },
                          child: Text(
                            'Select Categories',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedCategories.isEmpty
                                ? 'No Categories Selected'
                                : '${_selectedCategories.length} Selected',
                            style: GoogleFonts.poppins(color: primary,fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_selectedCategories.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: _selectedCategories
                            .map((c) => Chip(
                              label: Text(c.name, style: GoogleFonts.poppins(color:primary)), 
                              backgroundColor: Colors.white38,
                              side: BorderSide(),
                              ))
                            .toList(),
                      ),
                    const SizedBox(height: 16),
              
                    Text(
                      'Start of Event (Date & Time)',
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
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: (){
                              _pickStartDateTime(context);
                              FocusScope.of(context).requestFocus(_dummyFocusNode);
                            },
                            child: Text(
                              _formatStart(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
              
                    Text(
                      'Duration',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: BoxBorder.all(),
                        color: Colors.white.withValues(alpha: .95),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonFormField<String>(
                        style: GoogleFonts.poppins(color: primary),
                        initialValue: _selectedDuration,
                        isExpanded: true,
                        decoration: const InputDecoration.collapsed(hintText: ''),
                        hint: Text(
                          'Select Duration',
                          style: GoogleFonts.poppins(color: primary, fontSize: 16),
                        ),
                        items: _durationOptions
                            .map(
                              (d) => DropdownMenuItem(
                                value: d,
                                child: Text(d, style: GoogleFonts.poppins(fontSize: 16)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedDuration = v;
                          if (v != null){
                            try{
                              _durationMinutes = durations[_durationOptions.indexOf(v)];
                            }
                            catch(e){
                              _durationMinutes = 0;
                            }
                          }
                        }),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Please Select Duration'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
              
                    Text(
                      'People Needed',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: BoxBorder.all(),
                        color: Colors.white.withValues(alpha: .95),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonFormField<int>(
                        style: GoogleFonts.poppins(color: primary, fontSize: 16),
                        initialValue: _peopleNeeded,
                        isExpanded: true,
                        decoration: const InputDecoration.collapsed(hintText: ''),
                        items: List.generate(50, (i) => i + 1)
                            .map(
                              (n) => DropdownMenuItem(
                                value: n,
                                child: Text(
                                  n.toString(),
                                  style: GoogleFonts.poppins(color: primary, fontSize: 16),
                                ),
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
                          textStyle: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (!(_formKey.currentState?.validate() ?? false))
                                  return;
              
                                if (_locationknowledge == null) {
                                  showGlobalSnackBar("Please pick a location");
                                  return;
                                }
              
                                if (_startDateTime == null) {
                                  showGlobalSnackBar(
                                    "Please pick a start date/time",
                                  );
                                  return;
                                }
              
                                if (_durationMinutes == 0) {
                                  showGlobalSnackBar("Please pick a duration");
                                  return;
                                }
              
                                setState(() {
                                  _isLoading = true;
                                });
              
                                bool isUploaded = await uploadFirestore();
                                setState(() {
                                  _isLoading = false;
                                });
                                if (isUploaded) {
                                  showGlobalSnackBar("Event saved");
                                  Navigator.pop(context);
                                }
                              },
                        child: _isLoading
                            ? CircularProgressIndicator()
                            : Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
