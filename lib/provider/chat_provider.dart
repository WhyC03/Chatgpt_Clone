import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:chatgpt_clone/models/chat_history_model.dart';
import 'package:chatgpt_clone/models/chat_message_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatProvider with ChangeNotifier {
  List<ChatMessage> _messages = [];
  List<ChatHistoryItem> _chatHistory = [];
  String? _currentChatId;
  String userId = 'user123'; // Default user ID
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  List<ChatHistoryItem> get chatHistory => _chatHistory;
  String? get currentChatId => _currentChatId;
  bool get isLoading => _isLoading;

  bool _isTyping = false;
  bool get isTyping => _isTyping;

  // Replace with your backend base URL
  final String _baseUrl = 'http://<your-own-ip-address>:5000/api/chat';
  
  // Cloudinary upload URL
  final String _cloudinaryUploadUrl = 'http://<your-own-ip-address>:5000/api/chat/upload';


  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await fetchChatHistory();
      
      // Don't automatically load any chat - start with fresh screen
      // Chats will only be loaded when user taps on them in the drawer
    } catch (e) {
      log('Error initializing chat provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send a message (optionally with an image URL)
  Future<void> sendMessage(String text, {String? imageUrl}) async {
    try {
      log('Sending request to backend:');
      log('URL: $_baseUrl/send');
      log('Message: $text');
      log('Has image URL: ${imageUrl != null}');
      
      // Always use JSON for sending messages
      final requestBody = {
        'message': text,
        'userId': userId,
        'chatId': _currentChatId,
        if (imageUrl != null) 'image': imageUrl,
      };
      
      final response = await http.post(
        Uri.parse('$_baseUrl/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success']) {
                     // Add user message
           _messages.add(
             ChatMessage(
               role: 'user',
               content: text,
               image: imageUrl,
               timestamp: DateTime.now(),
             ),
           );

          // Add assistant message
          _messages.add(
            ChatMessage(
              role: 'assistant',
              content: data['aiMessage'],
              timestamp: DateTime.now(),
            ),
          );

                     // Set chat ID if it's a new chat
           if (_currentChatId == null) {
             _currentChatId = data['chatId'];
             final newChat = ChatHistoryItem(
               chatId: data['chatId'],
               title: text.length > 30 ? '${text.substring(0, 30)}...' : text,
               timestamp: DateTime.now(),
             );
             
             // Add new chat to the beginning of the list (most recent first)
             _chatHistory.insert(0, newChat);
           }

          notifyListeners();
        }
      } else {
        log('Backend responded with status: ${response.statusCode}');
        log('Response body: ${response.body}');
        
        if (response.statusCode == 413) {
          throw Exception('Image too large. Please try with a smaller image or compress it.');
        } else if (response.statusCode == 400) {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['error'] ?? 'Invalid request';
          throw Exception('Bad request: $errorMessage');
        } else {
          throw Exception('Failed to send message: ${response.statusCode}');
        }
      }
    } catch (e) {
      log('Error sending message: $e');
      rethrow;
    }
  }

  // Load full chat history (used in drawer)
  Future<void> fetchChatHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/history/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _chatHistory = (data['chats'] as List<dynamic>).map((chat) {
            final chatData = chat as Map<String, dynamic>;
            final timestamp = chatData['createdAt'] != null 
                ? DateTime.parse(chatData['createdAt']) 
                : DateTime.now();
            
            return ChatHistoryItem(
              chatId: chatData['chatId'] ?? '',
              title: (chatData['lastMessage'] ?? '').toString().length > 30 
                  ? '${(chatData['lastMessage'] ?? '').toString().substring(0, 30)}...' 
                  : (chatData['lastMessage'] ?? '').toString(),
              timestamp: timestamp,
            );
          }).toList();
          
          // The backend already sorts by createdAt in descending order, so we don't need to sort again
          // But we'll keep this as a safety measure
          _chatHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          notifyListeners();
        }
      }
    } catch (e) {
      log('Error fetching chat history: $e');
    }
  }

  // Load messages for a specific chat
  Future<void> loadMessages(String chatId) async {
    try {
      _currentChatId = chatId;
      final response = await http.get(
        Uri.parse('$_baseUrl/$chatId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _messages = (data['chat']['messages'] as List<dynamic>).map((msg) {
            return ChatMessage.fromJson(msg as Map<String, dynamic>);
          }).toList();
          notifyListeners();
        }
      }
    } catch (e) {
      log('Error loading messages: $e');
    }
  }

  void clearChat() {
    _messages.clear();
    _currentChatId = null;
    notifyListeners();
  }

  void startNewChat() {
    _messages = [];
    _currentChatId = null;
    notifyListeners();
  }

  void setCurrentChatId(String chatId) {
    _currentChatId = chatId;
    notifyListeners();
  }

  void setTyping(bool value) {
    _isTyping = value;
    notifyListeners();
  }
  
  // Upload image to Cloudinary and return the URL
  Future<String> uploadImageToCloudinary(File imageFile) async {
    try {
      log('Uploading image to Cloudinary...');
      
      var request = http.MultipartRequest('POST', Uri.parse(_cloudinaryUploadUrl));
      
      // Add image file
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ));
      
      final response = await http.Response.fromStream(await request.send());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          log('Image uploaded successfully: ${data['imageUrl']}');
          return data['imageUrl'];
        } else {
          throw Exception('Upload failed: ${data['error']}');
        }
      } else {
        log('Upload failed with status: ${response.statusCode}');
        log('Response body: ${response.body}');
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      log('Error uploading image: $e');
      rethrow;
    }
  }
}
