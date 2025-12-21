import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:micro_volunteering_hub/helper_functions.dart';
import 'package:micro_volunteering_hub/models/event.dart';
import 'package:micro_volunteering_hub/providers/auth_controller.dart';
import 'package:micro_volunteering_hub/providers/user_provider.dart';
import 'package:micro_volunteering_hub/screens/event_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const Color primary = Color(0xFF00A86B);
  static const background = Color(0xFFF2F2F3);
  String cloudName = 'dm2k6xcne';
  String APIkey = 'ipjhnrc2wVlb-zWv3aKmRKwV-og';
  String unsignedPresetName = 'microvolunteeringapp';
  final _imagePicker = ImagePicker();
  File? _image;
  String? url;

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

  Future<void> handleImage() async {
    await uploadToCloudinary();

    await FirebaseFirestore.instance
        .collection('user_info')
        .doc(
          FirebaseAuth.instance.currentUser!.uid,
        )
        .set(
          {
            'photo_url': url,
          },
          SetOptions(merge: true),
        );

    if (url != null) {
      ref.read(userProvider.notifier).updateUserProfile(url!);
    }
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
              child: Text('Take a photo'),
            ),
            ElevatedButton(
              onPressed: () {
                _pickImageFromGallery();
                Navigator.pop(context);
              },
              child: Text('Choose from gallery'),
            ),
          ],
        ),
      ),
    );
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

  int _selectedTab = 0;

  Widget userAvatar(String? localPath) {
    if (localPath == null || localPath.isEmpty) {
      return const CircleAvatar(
        radius: 52,
        backgroundColor: primary,
        child: ClipOval(child: Icon(Icons.person, size: 64, color: Colors.white)),
      );
    } else {
      return CircleAvatar(
        radius: 52,
        backgroundColor: primary,
        backgroundImage: FileImage(File(localPath)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var userData = ref.watch(userProvider);

    print(userData);

    List<Event> userEvents = userData['users_events'] ?? [];
    final String displayName = userData['user_name'] ?? 'Anonymous';
    final String role = 'Community Helper';
    String? photoUrl = userData['photo_url'];
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            onPressed: () async {
              await ref
                  .read(
                    authControllerProvider.notifier,
                  )
                  .logout();
              Navigator.of(context).pop();
            },
            tooltip: 'Log out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: userAvatar(userData["photo_url"]),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // stats
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${userEvents.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Events Created',
                          style: GoogleFonts.poppins(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          //placeholder
                          '0',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Events Attended',
                          style: GoogleFonts.poppins(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == 0 ? primary : Colors.white,
                      foregroundColor: _selectedTab == 0 ? Colors.white : primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => setState(() => _selectedTab = 0),
                    child: Text('My Events', style: GoogleFonts.poppins()),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: userEvents.length,
              itemBuilder: (ctx, i) {
                final e = userEvents[i];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      e.title,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      HelperFunctions.formatter.format(e.time),
                      style: GoogleFonts.poppins(),
                    ),
                    trailing: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        e.imageUrl,
                        width: 80,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 60,
                            color: Colors.green,
                            child: Icon(Icons.event, size: 48, color: Colors.black),
                          );
                        },
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EventDetailsScreen(
                            event: e,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
