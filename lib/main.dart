// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'quiz_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trivia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF007AFF),
          background: Color(0xFFF2F2F7),
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const QuizScreen(),
    );
  }
}