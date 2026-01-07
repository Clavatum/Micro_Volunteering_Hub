import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:micro_volunteering_hub/backend/client/requests.dart';
import 'package:micro_volunteering_hub/models/event.dart';
import 'package:micro_volunteering_hub/providers/chat_provider.dart';
import 'package:micro_volunteering_hub/providers/network_provider.dart';
import 'package:micro_volunteering_hub/utils/database.dart';
import 'package:micro_volunteering_hub/utils/snackbar_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({super.key, required this.event, required this.userData});
  final Event event;
  final Map<String, dynamic> userData;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final userId = FirebaseAuth.instance.currentUser!.uid;
  late final WebSocketChannel channel;
  late final StreamSubscription sub;
  List<Map<String, dynamic>> messages = [];

  @override
  void initState(){
    super.initState();
    final messagesState = ref.read(chatProvider);
    if(!messagesState.containsKey(widget.event.eventId)){
      _loadMessagesOnce(widget.event.eventId);
    }

    String host = usedServerURL.substring(usedServerURL.indexOf("//")+2);
    channel = WebSocketChannel.connect(Uri.parse("ws://$host/websocket/chat/${widget.event.eventId}"));
    sub = channel.stream.listen((event){
      final msg = jsonDecode(event);
      if (!mounted) return;
      ref.read(chatProvider.notifier).addMessage(widget.event.eventId, msg);
      UserLocalDb.storeMessage(
        msg["id"],
        widget.event.eventId,
        msg["text"],
        msg["sender_id"],
        msg["sender_name"],
        DateTime.parse(msg["created_at_iso"]).millisecondsSinceEpoch,
      );
    });
  }
  @override
  void dispose() {
    _messageController.dispose();
    sub.cancel();
    channel.sink.close();
    super.dispose();
  }
  
  Future<void> _loadMessagesOnce(String eventId) async {
    final isOnline = ref.read(backendHealthProvider);
    if(isOnline){
      var data = await fetchMessagesAPI(eventId);
      final msgs = (data["messages"] as List)
          .map((m) => m as Map<String, dynamic>)
          .toList();
      ref.read(chatProvider.notifier).setMessages(eventId, msgs);
      for(Map<String, dynamic> msg in msgs){
        UserLocalDb.storeMessage(msg["id"], eventId, msg["text"], msg["sender_id"], msg["sender_name"], 
        DateTime.parse(msg["created_at_iso"]).millisecondsSinceEpoch);
      }
    }
    else{
      final msgs = await UserLocalDb.getMessages(eventId);
      
      ref.read(chatProvider.notifier).setMessages(eventId, msgs);
    }
  }

  bool get canChat {
    if (widget.event.userId == userId) return true;
    return widget.userData["user_attended_events"].contains(widget.event.eventId);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || !canChat) return;

    final user = FirebaseAuth.instance.currentUser!;
    channel.sink.add(jsonEncode({
      "text": text,
      "sender_id": user.uid,
      "sender_name": user.displayName ?? "User",
      "created_at": DateTime.now().toIso8601String()
    }));

    _messageController.clear();
  }

  Future<void> loadMessages() async{
    var apiResponse = await fetchMessagesAPI(widget.event.eventId);
    if (!apiResponse["ok"]){
      showGlobalSnackBar("Failed to load messages");
    }else{
      setState((){
        messages = (apiResponse["messages"] as List).map((m) => m as Map<String, dynamic>).toList();
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF00A86B);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        title: Text(
          widget.event.title,
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
      backgroundColor: Color.fromARGB(255, 241, 235, 227),
      body: Column(
        children: [
          Consumer(
            builder:(context, ref, child) {
              final messages = ref.watch(chatProvider)[widget.event.eventId] ?? [];
              print(messages);
              return Expanded(
                child: messages.isEmpty ? const Center(child: Text("No messages yet")) :
                ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[i];
                    final isMe = msg['sender_id'] == userId;
                    final senderName = msg['sender_name'] ?? 'User';
                    DateTime created = DateTime.parse(msg["created_at_iso"]).toLocal();
                    String time = DateFormat("HH:mm").format(created);
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? primary : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(
                                senderName,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            if (!isMe) const SizedBox(height: 4),
                            Text(
                              msg['text'],
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe ? Colors.white70 : Colors.black54
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          if (canChat)
            SafeArea(
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.multiline,
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: Ink(
                        decoration: const ShapeDecoration(color: Color.fromARGB(255, 0, 225, 100),shape: CircleBorder()),
                        child: IconButton(
                          icon: const Icon(Icons.send),
                          color: Colors.white,
                          onPressed: _sendMessage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'You are not allowed to send messages',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
