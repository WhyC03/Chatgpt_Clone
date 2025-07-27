
import 'package:chatgpt_clone/provider/chat_provider.dart';
import 'package:chatgpt_clone/screens/onboarding_screen.dart';
import 'package:chatgpt_clone/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatGPT Clone',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: OnboardingScreen(),
    );
  }
}
