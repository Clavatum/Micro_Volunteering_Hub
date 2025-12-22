import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:micro_volunteering_hub/providers/events_provider.dart';
import 'package:micro_volunteering_hub/widgets/chat_evet_card.dart';
import 'package:micro_volunteering_hub/widgets/events_preview.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatscreenState();
}

class _ChatscreenState extends ConsumerState<ChatScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF00A86B);
    var chats = ref.watch(eventsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 2,
        title: Text(
          'Chats',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        itemBuilder: (ctx, index) => ChatEventCard(event: chats[index]),
        itemCount: chats.length,
      ),
    );
  }
}
