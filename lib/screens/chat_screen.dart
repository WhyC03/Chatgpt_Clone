// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'dart:io';
// import 'package:chatgpt_clone/models/chat_message_model.dart';
import 'package:chatgpt_clone/provider/chat_provider.dart';
import 'package:chatgpt_clone/utils/app_colors.dart';
import 'package:chatgpt_clone/widgets/chat_drawer.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //Mock Data
  // final List<ChatMessage> _messages = [
  //   ChatMessage(
  //     role: 'user',
  //     content: 'Tell me something about Harry Potter.',
  //     image: null,
  //     timestamp: DateTime.now().subtract(Duration(minutes: 5)),
  //   ),
  //   ChatMessage(
  //     role: 'assistant',
  //     content:
  //         'Harry Potter is a famous fictional wizard created by J.K. Rowling.',
  //     image: null,
  //     timestamp: DateTime.now().subtract(Duration(minutes: 4)),
  //   ),
  //   ChatMessage(
  //     role: 'user',
  //     content: 'Who is Voldemort?',
  //     image: null,
  //     timestamp: DateTime.now().subtract(Duration(minutes: 3)),
  //   ),
  //   ChatMessage(
  //     role: 'assistant',
  //     content:
  //         'Voldemort is the main antagonist in the Harry Potter series. The "OpenAI" name, the OpenAI logo, the "ChatGPT" and "GPT" brands, and other OpenAI trademarks, are property of OpenAI. These guidelines are intended to help our partners, resellers, customers, developers, consultants, publishers, and any other third parties understand how to use and display our trademarks and copyrighted work in their own assets and materials.',
  //     image: null,
  //     timestamp: DateTime.now().subtract(Duration(minutes: 2)),
  //   ),
  //   ChatMessage(
  //     role: 'user',
  //     content: 'Here is a picture of Hogwarts.',
  //     image:
  //         'https://imgs.search.brave.com/eut7FrXlDo2vX5pEuTh8WmmpWp4hdAlCzfzCbSNjvMA/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly91cGxv/YWQud2lraW1lZGlh/Lm9yZy93aWtpcGVk/aWEvY29tbW9ucy90/aHVtYi9iL2I2L0lt/YWdlX2NyZWF0ZWRf/d2l0aF9hX21vYmls/ZV9waG9uZS5wbmcv/OTYwcHgtSW1hZ2Vf/Y3JlYXRlZF93aXRo/X2FfbW9iaWxlX3Bo/b25lLnBuZw',
  //     timestamp: DateTime.now().subtract(Duration(minutes: 1)),
  //   ),
  //   ChatMessage(
  //     role: 'assistant',
  //     content: 'That looks amazing! Hogwarts is truly iconic.',
  //     image: null,
  //     timestamp: DateTime.now(),
  //   ),
  // ];

  TextEditingController controller = TextEditingController();
  ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  File? _uploadedImage;

  // Auto-scroll to the bottom of the chat
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Dismiss keyboard
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _uploadedImage = File(picked.path);
      });
    }
  }

  // Compress image to reduce payload size using flutter_image_compress
  Future<File> _compressImage(File imageFile) async {
    try {
      log('Starting image compression with flutter_image_compress...');

      // Get original file size
      final originalSize = await imageFile.length();
      final originalSizeMB = originalSize / (1024 * 1024);
      log('Original file size: ${originalSizeMB.toStringAsFixed(2)} MB');

      // Compress image with quality: 20 and max width/height: 1024
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        quality: 20,
        minWidth: 1024,
        minHeight: 1024,
      );

      if (compressedBytes == null) {
        log('Compression failed, returning original image');
        return imageFile;
      }

      // Create a temporary file for the compressed image
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final compressedFile = File('${tempDir.path}/compressed_$timestamp.jpg');
      await compressedFile.writeAsBytes(compressedBytes);

      // Verify the file was created and has content
      if (!await compressedFile.exists()) {
        log('Compressed file was not created');
        return imageFile;
      }

      final compressedSize = await compressedFile.length();
      if (compressedSize == 0) {
        log('Compressed file is empty');
        return imageFile;
      }

      final compressedSizeMB = compressedSize / (1024 * 1024);
      log('Compressed file size: ${compressedSizeMB.toStringAsFixed(2)} MB');
      log('Compressed file path: ${compressedFile.path}');

      return compressedFile;
    } catch (e) {
      log('Error compressing image with flutter_image_compress: $e');
      log('Falling back to original image...');

      // Fallback to original image if compression fails
      return imageFile;
    }
  }

  Future<void> _handleSend() async {
    final text = controller.text.trim();
    if (text.isEmpty && _uploadedImage == null) return;

    setState(() => _isSending = true);

    // Dismiss keyboard immediately when send is tapped
    _dismissKeyboard();

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      // Upload image to Cloudinary if available
      String? imageUrl;
      if (_uploadedImage != null) {
        log('Processing image for upload...');

        // Check file size before compression
        final fileSize = await _uploadedImage!.length();
        final fileSizeMB = fileSize / (1024 * 1024);
        log('Original file size: ${fileSizeMB.toStringAsFixed(2)} MB');

        if (fileSizeMB > 10) {
          throw Exception(
            'Image file is too large (${fileSizeMB.toStringAsFixed(2)} MB). Please select a smaller image.',
          );
        }

        // Compress the image first
        final compressedImageFile = await _compressImage(_uploadedImage!);

        // Check compressed size
        final compressedSize = await compressedImageFile.length();
        final compressedSizeMB = compressedSize / (1024 * 1024);
        log('Compressed size: ${compressedSizeMB.toStringAsFixed(2)} MB');

        if (compressedSizeMB > 5) {
          throw Exception(
            'Compressed image is still too large. Please try with a smaller image.',
          );
        }

        // Upload compressed image to Cloudinary
        log('Uploading compressed image to Cloudinary...');
        imageUrl = await chatProvider.uploadImageToCloudinary(
          compressedImageFile,
        );
        log('Image uploaded successfully: $imageUrl');
      }

      // If sending only an image without text, provide a default message
      final messageText = text.isNotEmpty ? text : 'Analyze this image';

      await chatProvider.sendMessage(messageText, imageUrl: imageUrl);

      controller.clear(); // Clear the text input
      _uploadedImage = null; // Clear the selected image

      // Auto-scroll to the bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      log('Error sending message: $e');
      String errorMessage = 'Failed to send message';

      if (e.toString().contains('413') || e.toString().contains('too large')) {
        errorMessage = 'Image too large. Please try with a smaller image.';
      } else if (e.toString().contains('400')) {
        errorMessage =
            'Invalid request. Please check your input and try again.';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('Image file is too large')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      } else if (e.toString().contains('Compressed image is still too large')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  void initState() {
    super.initState();

    // Add listener to auto-scroll when new messages are added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.addListener(() {
        // Auto-scroll to bottom when messages change
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      });

      // Fetch available models on app start
      chatProvider.fetchAvailableModels();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _scrollController.dispose(); // Dispose scroll controller
    // Refresh chat history when leaving the chat screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.fetchChatHistory();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor,
      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            return IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: Icon(Icons.menu_outlined, color: Colors.white),
            );
          },
        ),
        centerTitle: true,
        title: Text(
          'ChatGPT',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return PopupMenuButton<String>(
                color: Colors.black,
                icon: Icon(Icons.settings, color: Colors.white),
                tooltip: 'Select Model',
                onSelected: (value) {
                  if (value == 'select_model') {
                    chatProvider.showModelSelectionDialog(context);
                  }
                },
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: 'select_model',
                        child: Row(
                          children: [
                            // Icon(Icons.settings, size: 20),
                            // SizedBox(width: 8),
                            Text('Change Model'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        enabled: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Model:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              chatProvider.currentModel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
              );
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      drawer: ChatDrawer(),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Loading your conversations...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                final messages = chatProvider.messages;

                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListView.builder(
                    controller: _scrollController, // Add scroll controller
                    itemCount: messages.length,
                    itemBuilder: (BuildContext context, int index) {
                      final message = messages[index];
                      final isUser = message.role == 'user';

                      return Container(
                        decoration: BoxDecoration(
                          color:
                              isUser
                                  ? Colors.transparent
                                  : const Color(0xFF444654),
                          borderRadius: BorderRadius.circular(15),
                        ),

                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        child: Row(
                          crossAxisAlignment:
                              isUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                          mainAxisAlignment:
                              isUser
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                          children: [
                            // Avatar (for assistant)
                            if (!isUser)
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: 12,
                                  top: 10,
                                ),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.white,
                                  child: Image.asset(
                                    'assets/openai_icon.png', // Replace with your icon
                                    width: 24,
                                  ),
                                ),
                              ),
                            // Chat Bubble
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    isUser
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                children: [
                                  if (message.image != null &&
                                      message.image!.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        message.image!,
                                        height: 180,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) => const SizedBox(),
                                      ),
                                    ),
                                  if (message.content.isNotEmpty) ...[
                                    if (message.image != null &&
                                        message.image!.isNotEmpty)
                                      const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            isUser
                                                ? Colors.transparent
                                                : AppColors.messageBgColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        message.content,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isUser)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.grey.shade700,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          Container(
            height: 140,
            padding: EdgeInsets.all(16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                promptContainer(
                  'Why hire Yash Chandra, developer of this app?',
                ),
                promptContainer('Tell me Something About Harry Potter'),
                promptContainer('Tell me Something How to get OpenAI API'),
                promptContainer('What is Solar Eclipse?'),
                promptContainer(
                  'Which is better Gemini AI, Claude AI, Perplexity AI or ChatGPT?',
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.only(left: 16, right: 16, top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_uploadedImage != null)
                  Column(
                    children: [
                      SizedBox(height: 10),
                      Stack(
                        children: [
                          Image.file(
                            _uploadedImage!,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 15,
                                ),
                                onPressed:
                                    () => setState(() => _uploadedImage = null),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.image, color: Colors.white),
                      onPressed: _pickImage,
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        cursorColor: Colors.white,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Ask Anything',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          filled: false,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    GestureDetector(
                      onTap: _isSending ? null : _handleSend,
                      child:
                          _isSending
                              ? CircularProgressIndicator(color: Colors.white)
                              : Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  "ChatGPT July 2025 Version.",
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.grey.shade400,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Free research Preview',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget promptContainer(String text) {
    return GestureDetector(
      onTap: () {
        if (controller.text.isEmpty) {
          setState(() {
            controller.text = text;
          });
          // Dismiss keyboard when prompt is selected
          _dismissKeyboard();
        }
      },
      child: Container(
        margin: EdgeInsets.only(right: 8),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 0.5),
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        width: 200,
        child: Center(
          child: Text(
            maxLines: 3,
            text,
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
            textAlign: TextAlign.center,
            overflow: TextOverflow.fade,
          ),
        ),
      ),
    );
  }
}
