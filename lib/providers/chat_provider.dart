import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class ChatStateNotifier extends StateNotifier<Map<String, List<Map<String, dynamic>>>> {
  ChatStateNotifier(): super({});

  List<Map<String, dynamic>> getMessages(String eventId) => state[eventId] ?? [];

  void setMessages(String eventId, List<Map<String, dynamic>> messages) {
    state = {...state, eventId: messages};
  }

  void addMessage(String eventId, Map<String, dynamic> message) {
    final current = state[eventId] ?? [];
    state = {...state, eventId: [...current, message]};
  }
}

final chatProvider = StateNotifierProvider<ChatStateNotifier, Map<String, List<Map<String, dynamic>>>>(
  (ref) => ChatStateNotifier(),
);