// models/message.dart
class Message {
  final String id;
  final String sender; // 'user' or 'bot'
  final String text;
  final String? imageUrl; // Optional image
  final DateTime timestamp;

  Message({
    required this.id,
    required this.sender,
    required this.text,
    this.imageUrl,
    required this.timestamp,
  });
}
