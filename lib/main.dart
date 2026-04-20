// lib/main.dart

import 'package:flutter/material.dart';
import 'quiz_screen.dart';

void main() {
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trivia Quiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF9c6fff),
          background: const Color(0xFF0f0c29),
        ),
        useMaterial3: true,
      ),
      home: const QuizScreen(),
    );
  }
}