import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chat_with_friends/conversation.dart';
import 'package:chat_with_friends/message.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/html.dart';
import 'package:flutter/foundation.dart';
import "package:chat_with_friends/helpers.dart";
import 'package:qr_flutter/qr_flutter.dart';
import 'package:chat_with_friends/config.dart';
import 'dart:html' as html;

Future<String> fetchWebSocketUrl(Conversation conversation) async {
  var negotiateUrl =
      '${AppConfig.negotiateUrl}?sessionId=${conversation.sessionId}&userId=${conversation.userId}&language=${conversation.userLanguage}';
  // root = http://localhost:7071/api/
  final response = await http.get(Uri.parse(negotiateUrl));

  if (response.statusCode == 200) {
    // Parse the response body for the WebSocket URL
    final jsonResponse = jsonDecode(response.body);
    final sessionId = jsonResponse['sessionId'];
    final userId = jsonResponse['userId'];
    storeInfo('sessionId', sessionId);
    storeInfo(sessionId + ':userId', userId);
    return jsonResponse['url'];
  } else {
    throw Exception('Failed to fetch WebSocket URL');
  }
}

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  ChatScreen({required this.conversation});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  WebSocketChannel? _webSocketChannel;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _webSocketChannel?.sink.close();
    super.dispose();
  }

  Future<void> _initializeWebSocket() async {
    try {
      final webSocketUrl = await fetchWebSocketUrl(widget.conversation);

      if (kIsWeb) {
        _webSocketChannel = HtmlWebSocketChannel.connect(webSocketUrl);
      } else {
        _webSocketChannel = IOWebSocketChannel.connect(webSocketUrl);
      }

      _listenForIncomingMessages();
    } catch (e) {
      print('Error initializing WebSocket: $e');
    }
  }

  void _listenForIncomingMessages() {
    _webSocketChannel?.stream.listen((event) {
      final jsonObject = jsonDecode(event);
      final incomingMessage = Message.fromJson(jsonObject);
      // Add the incoming message to the list of messages and update the UI
      setState(() {
        widget.conversation.messages.add(incomingMessage);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final qrCodeUrl =
        '${html.window.location}?sessionId=${widget.conversation.sessionId}&language=${widget.conversation.defaultLanguage}';
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.conversation.title),
        ),
        body: Column(
          children: [
            SelectableText(
                'visit ${qrCodeUrl} or Scan this QR code to join the chat:'),
            const SizedBox(height: 20),
            QrImage(data: qrCodeUrl, size: 200),
            Expanded(
              child: ListView.builder(
                itemCount: widget.conversation.messages.length,
                itemBuilder: (context, index) {
                  final message = widget.conversation.messages[index];
                  final bool isMe = message.sender ==
                      'YourUsername'; // Replace 'YourUsername' with the current user's identifier
                  return _buildMessageRow(message, isMe);
                },
              ),
            ),
            _buildInputArea(),
          ],
        ));
  }

  Widget _buildMessageRow(Message message, bool isMe) {
    return Container(
      margin: EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              child: Text(message.sender[0]),
            ),
          SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isMe ? Colors.blue : Colors.grey[300],
                  ),
                  child: Text(
                    message.translated.isEmpty
                        ? message.original
                        : message.translated,
                    style: TextStyle(color: isMe ? Colors.white : Colors.black),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  DateFormat('hh:mm a').format(message.timestamp),
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      height: 70.0,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type a message',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              final text = _textController.text.trim();
              if (text.isNotEmpty) {
                _sendMessage(text);
                _textController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    final message = Message(
      sender: widget
          .conversation.userId, // Replace with the current user's identifier
      original: text,
      translated: '',
      timestamp: DateTime.now(),
    );

    var jsonMessage = message.toJson();
    jsonMessage['sessionId'] = widget.conversation.sessionId;
    jsonMessage['language'] = widget.conversation.userLanguage;
    // Send the message via WebSocket
    _webSocketChannel?.sink.add(json.encode(jsonMessage));

    // Add the sent message to the list of messages and update the UI
    setState(() {
      widget.conversation.messages.add(message);
    });
  }
}

final List<Message> messages = [
  Message(
      sender: 'John',
      original: 'Hey there!',
      translated: '',
      timestamp: DateTime.now().subtract(Duration(minutes: 15))),
  Message(
      sender: 'Me',
      original: 'Hi, John!',
      translated: '',
      timestamp: DateTime.now().subtract(Duration(minutes: 10))),
  Message(
      sender: 'John',
      original: 'How are you?',
      translated: '',
      timestamp: DateTime.now().subtract(Duration(minutes: 8))),
  Message(
      sender: 'Me',
      original: 'I\'m good, thanks! How about you?',
      translated: '',
      timestamp: DateTime.now().subtract(Duration(minutes: 5))),
];
