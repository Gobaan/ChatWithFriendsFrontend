import "package:chat_with_friends/helpers.dart";
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:chat_with_friends/config.dart';
import 'package:chat_with_friends/conversation.dart';
import 'package:chat_with_friends/message.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:chat_with_friends/simple_recorder.dart';
import 'dart:js' as js;

void speak(String text, String language) {
  print(js.context.callMethod('getSupportedLanguages', []));
  js.context.callMethod('speak', [text, language]);
}

Future<String> fetchWebSocketUrl(Conversation conversation) async {
  var negotiateUrl =
      '${AppConfig.negotiateUrl}?sessionId=${conversation.sessionId}&userId=${conversation.userId}&language=${conversation.userLanguage}';
  final response = await http.get(Uri.parse(negotiateUrl));

  if (response.statusCode == 200) {
    // Parse the response body for the WebSocket URL
    final jsonResponse = jsonDecode(response.body);
    final sessionId = jsonResponse['sessionId'];
    storeInfo('sessionId', sessionId);
    storeInfo(sessionId + ':info', response.body);
    conversation.blobUrl = jsonResponse['blobUrl'];
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

  void playTextAsSpeech(String text) {
    speak(text, widget.conversation.getLanguage());
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
            SelectableText('${qrCodeUrl}'),
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
                    child: Row(children: [
                      message.blob.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.play_arrow),
                              onPressed: () {
                                playTextAsSpeech(message.translated.isEmpty
                                    ? message.original
                                    : message.translated);
                              },
                            )
                          : const SizedBox.shrink(),
                      (message.translated.isEmpty && message.original.isEmpty)
                          ? const SizedBox.shrink()
                          : Text(
                              message.translated.isEmpty
                                  ? message.original
                                  : message.translated,
                              style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black),
                            )
                    ])),
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
    return SimpleRecorder(
      onText: _sendMessage,
      onRecord: onRecord,
      conversation: widget.conversation,
    );
  }

  void onRecord(Uri uri) {
    final message = Message(
        sender: widget
            .conversation.userId, // Replace with the current user's identifier
        original: '',
        translated: '',
        timestamp: DateTime.now(),
        blob: uri.toString());

    var jsonMessage = message.toJson();
    jsonMessage['sessionId'] = widget.conversation.sessionId;
    jsonMessage['language'] = widget.conversation.userLanguage;
    jsonMessage['uri'] = uri.toString();
    // Send the message via WebSocket
    _webSocketChannel?.sink.add(json.encode(jsonMessage));

    // Add the sent message to the list of messages and update the UI
    setState(() {
      widget.conversation.messages.add(message);
    });
  }

  void _sendMessage(String text) {
    final message = Message(
        sender: widget
            .conversation.userId, // Replace with the current user's identifier
        original: text,
        translated: '',
        timestamp: DateTime.now(),
        blob: '');

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
