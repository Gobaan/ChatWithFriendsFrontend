import 'package:flutter/material.dart';
import 'package:chat_with_friends/message.dart';
import 'package:chat_with_friends/chat_screen.dart';

class Conversation {
  final String title;
  final String sessionId;
  final String userId;
  final String checksum;
  final List<Message> messages;
  final String userLanguage;
  final String defaultLanguage;

  Conversation(
      {required this.title,
      required this.sessionId,
      required this.userId,
      required this.checksum,
      required this.messages,
      required this.userLanguage,
      required this.defaultLanguage});
}

class ConversationsList extends StatelessWidget {
  final List<Conversation> conversations;

  ConversationsList({required this.conversations});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return ListTile(
          title: Text(conversation.title),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(conversation: conversation),
              ),
            );
          },
        );
      },
    );
  }
}
