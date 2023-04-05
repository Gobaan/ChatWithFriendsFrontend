import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chat_with_friends/config.dart';
import 'package:chat_with_friends/chat_screen.dart';
import 'package:chat_with_friends/conversation.dart';

class LanguageScreen extends StatefulWidget {
  @override
  _LanguageScreenState createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Language')),
      body: ListView(
        children: [
          ListTile(
              title: const Text('English'),
              onTap: () => _selectLanguage('English')),
          ListTile(
              title: const Text('French'),
              onTap: () => _selectLanguage('French')),
          ListTile(
              title: const Text('Russian'),
              onTap: () => _selectLanguage('Russian')),
          ListTile(
              title: const Text('Spanish'),
              onTap: () => _selectLanguage('Spanish')),
        ],
      ),
    );
  }

  String _getUserId() {
    return '1';
  }

  String _getUserLanguage() {
    return 'en';
  }

  void _selectLanguage(String language) async {
    var sessionId = '1';
    try {
      sessionId = await _getSessionId();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Failed to get sessionId')),
      );
    }
    final conversation = Conversation(
        userId: _getUserId(),
        title: 'Placeholder',
        sessionId: sessionId,
        checksum: 'Placeholder',
        messages: [],
        userLanguage: _getUserLanguage(),
        defaultLanguage: AppConfig.languageCode[language] ?? 'en');
    // Perform any action after selecting the language
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversation: conversation),
      ),
    );
  }

  Future<String> _getSessionId() async {
    final response = await http.get(Uri.parse(AppConfig.negotiateUrl));

    if (response.statusCode == 200) {
      return json.decode(response.body)['sessionId'];
    } else {
      throw Exception('Failed to get sessionId');
    }
  }
}
