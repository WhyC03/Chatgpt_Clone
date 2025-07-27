class ChatMessage {
  final String role; // "user" or "assistant"
  final String content;
  final String? image; // optional image URL
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    this.image,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'],
      content: json['content'] ?? '',
      image: json['image'],
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      if (image != null) 'image': image,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
