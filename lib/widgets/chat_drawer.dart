import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_history_model.dart';
import '../provider/chat_provider.dart';
import '../screens/chat_screen.dart';

class ChatDrawer extends StatefulWidget {
  const ChatDrawer({super.key});

  @override
  State<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends State<ChatDrawer> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Use a microtask to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized) {
        _hasInitialized = true;
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        // Always fetch chat history when drawer is opened to ensure it's up to date
        chatProvider.fetchChatHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            final List<ChatHistoryItem> chats = chatProvider.chatHistory;

            return Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: Colors.white70),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search',
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Static Menu Options
                _buildDrawerItem(
                  Icons.edit,
                  "New chat",
                  onTap: () {
                    Navigator.pop(context);
                    chatProvider.startNewChat();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    );
                  },
                ),
                _buildDrawerItem(Icons.image_outlined, "Library", onTap: () {}),
                _buildDrawerItem(Icons.grid_view_rounded, "GPTs", onTap: () {}),
                _buildDrawerItem(
                  Icons.chat_bubble_outline,
                  "Chats",
                  onTap: () {},
                ),

                const Divider(color: Colors.white12),

                // Dynamic Chat History List
                Expanded(
                  child:
                      chatProvider.isLoading
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 16),
                                Text(
                                  'Loading chat history...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : chats.isEmpty
                          ? RefreshIndicator(
                            color: Colors.white,
                            onRefresh: () => chatProvider.fetchChatHistory(),
                            child: ListView(
                              children: [
                                SizedBox(height: 200),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.history,
                                        size: 48,
                                        color: Colors.grey.shade600,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No chat history',
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Start a new conversation to see it here',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                          : RefreshIndicator(
                            color: Colors.white,
                            onRefresh: () => chatProvider.fetchChatHistory(),
                            child: ListView.builder(
                              itemCount: chats.length,
                              itemBuilder: (context, index) {
                                final chat = chats[index];
                                return ListTile(
                                  title: Text(
                                    chat.title,
                                    style: const TextStyle(color: Colors.white),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    'Tap to open conversation',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12,
                                    ),
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await chatProvider.loadMessages(
                                      chat.chatId,
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ChatScreen(),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                ),

                const Divider(color: Colors.white24),

                // Bottom user profile section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey,
                        radius: 18,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Yash Chandra",
                          style: TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down, color: Colors.white),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
