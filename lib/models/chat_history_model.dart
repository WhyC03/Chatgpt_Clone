class ChatHistoryItem {
  final String chatId;
  final String title; // could be the first user message or a summary
  final DateTime timestamp; // timestamp for sorting

  ChatHistoryItem({
    required this.chatId, 
    required this.title, 
    required this.timestamp,
  });

  factory ChatHistoryItem.fromJson(Map<String, dynamic> json) {
    return ChatHistoryItem(
      chatId: json['chatId'], 
      title: json['title'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId, 
      'title': title,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
