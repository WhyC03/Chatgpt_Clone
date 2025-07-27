import 'dart:developer';

import 'package:chatgpt_clone/provider/chat_provider.dart';
import 'package:chatgpt_clone/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:chatgpt_clone/utils/app_colors.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool isInitializing = false;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid calling initialize during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChatHistory();
    });
  }

  Future<void> _initializeChatHistory() async {
    setState(() => isInitializing = true);

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.initialize();
    } catch (e) {
      log('Error initializing chat history: $e');
    } finally {
      setState(() => isInitializing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greenBgColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              SizedBox(
                height: 200,
                width: 200,
                child: SvgPicture.asset(
                  'assets/openai.svg',
                  colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Welcome to ChatGPT',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pinkBgColor,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'The fastest and most powerful platform for building AI products',
                style: TextStyle(fontSize: 18, color: AppColors.pinkBgColor),
                textAlign: TextAlign.center,
              ),
              Spacer(),
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      Colors.transparent,
                    ),
                    elevation: WidgetStateProperty.all(0),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        side: BorderSide(color: AppColors.pinkBgColor),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => ChatScreen()),
                      (route) => false,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Try ChatGPT',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.pinkBgColor,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward, color: AppColors.pinkBgColor),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
