class Message {
  final String sender;
  final String translated;
  final String original;
  final DateTime timestamp;

  Message(
      {required this.sender,
      required this.original,
      required this.translated,
      required this.timestamp});

  // Deserialize the JSON object to create a Message object
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      sender: json['userId'],
      original: json['original'],
      translated: json['translated'],
      timestamp: DateTime.now(), //DateTime.parse(json['timestamp']),
    );
  }

  // Serialize the Message object to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'userId': sender,
      'text': original,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
