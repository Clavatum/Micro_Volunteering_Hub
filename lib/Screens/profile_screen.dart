import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'google_sign_in_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _localImage;
  bool _isUploading = false;

  int _selectedTab = 0;

  final List<Map<String, String>> _myEvents = [
    {
      'date': 'Sun, Oct 26, 09:00',
      'title': 'Community Garden Cleanup',
      'image': 'https://picsum.photos/seed/garden/120/80',
    },
    {
      'date': 'Mon, Nov 3, 13:00',
      'title': 'Local Park Restoration',
      'image': 'https://picsum.photos/seed/park/120/80',
    },
  ];

  final List<Map<String, String>> _pastEvents = [
    {
      'date': 'Sat, Sep 12, 10:00',
      'title': 'Beach Cleanup',
      'image': 'https://picsum.photos/seed/beach/120/80',
    },
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No image selected.')));
        return;
      }

      final File file = File(picked.path);
      setState(() {
        _localImage = file;
      });

      await _uploadAndSetProfileImage(file);
    } catch (e) {
      debugPrint('Image pick error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<void> _uploadAndSetProfileImage(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not signed in.')));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload disabled in this build.')),
      );

      setState(() {
        _localImage = null;
      });
    } catch (e) {
      debugPrint('Upload error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const GoogleSignInScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF00A86B);
    const Color background = Color(0xFFF2F2F3);

    final User? user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName ?? 'Anonymous';
    final String role = 'Community Helper';
    final String? photoUrl = user?.photoURL;

    final events = _selectedTab == 0 ? _myEvents : _pastEvents;

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
              await _logOut();
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
                    onTap: _showImageSourceSheet,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: primary,
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: Colors.white,
                            backgroundImage: _localImage != null
                                ? FileImage(_localImage!) as ImageProvider
                                : (photoUrl != null
                                      ? NetworkImage(photoUrl)
                                      : null),
                            child: _localImage == null && photoUrl == null
                                ? Text(
                                    displayName.isNotEmpty
                                        ? displayName[0].toUpperCase()
                                        : 'A',
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: primary,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        if (_isUploading)
                          const SizedBox(
                            width: 96,
                            height: 96,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
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
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit profile (TBD)')),
                      );
                    },
                    icon: Icon(Icons.edit, color: primary),
                    label: Text(
                      'Edit',
                      style: GoogleFonts.poppins(color: primary),
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
                          '12',
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
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '49',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Hours Volunteered',
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
                      backgroundColor: _selectedTab == 0
                          ? primary
                          : Colors.white,
                      foregroundColor: _selectedTab == 0
                          ? Colors.white
                          : primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => setState(() => _selectedTab = 0),
                    child: Text('My Events', style: GoogleFonts.poppins()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == 1
                          ? primary
                          : Colors.white,
                      foregroundColor: _selectedTab == 1
                          ? Colors.white
                          : primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => setState(() => _selectedTab = 1),
                    child: Text('Past Events', style: GoogleFonts.poppins()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: events.length,
              itemBuilder: (ctx, i) {
                final e = events[i];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      e['title'] ?? '',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      e['date'] ?? '',
                      style: GoogleFonts.poppins(),
                    ),
                    trailing: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        e['image'] ?? '',
                        width: 80,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Open event: ${e['title']}')),
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
