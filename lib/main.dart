import 'package:flutter/material.dart';
import 'package:chat_with_friends/conversation.dart';
import 'package:chat_with_friends/home_screen.dart';
import 'package:chat_with_friends/chat_screen.dart';

void main() async {
  runApp(MessengerApp());
}

class MessengerApp extends StatefulWidget {
  @override
  _MessengerAppState createState() => _MessengerAppState();
}

class _MessengerAppState extends State<MessengerApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
  }

  String _getUserId(String? sessionId) {
    return '1';
  }

  String _getChecksum(String? sessionId) {
    return '1';
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    if (uri.path == '/') {
      // Get Websocket
      final sessionId = uri.queryParameters['sessionId'];
      final language = uri.queryParameters['language'];
      final userId = _getUserId(sessionId);
      final checksum = _getChecksum(sessionId);
      if (sessionId != null) {
        return MaterialPageRoute(
          builder: (context) => ChatScreen(
              conversation: Conversation(
                  sessionId: sessionId,
                  userId: '2',
                  checksum: checksum,
                  messages: messages,
                  title: 'Placeholder',
                  userLanguage: language ?? 'en',
                  defaultLanguage: language ?? 'en')),
        );
      } else {
        return MaterialPageRoute(builder: (context) => HomeScreen());
      }
    }

    // Add more routes as needed.

    // Return a default route if no other routes match.
    return MaterialPageRoute(builder: (context) => HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      onGenerateRoute: _generateRoute,
    );
  }
}
