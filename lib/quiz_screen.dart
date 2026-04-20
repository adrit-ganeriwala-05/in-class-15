// lib/quiz_screen.dart

import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'api_service.dart';
import 'question.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // ─── State Variables ───────────────────────────────────────
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _answered = false;         // locks buttons after a tap
  String? _selectedAnswer;        // which button the user tapped
  bool _isLoading = true;
  String? _errorMessage;

  // HTML entity decoder — cleans "&amp;" → "&", "&#039;" → "'"
  final HtmlUnescape _unescape = HtmlUnescape();

  // ─── Lifecycle ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  // ─── Data Fetching ─────────────────────────────────────────
  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final questions = await ApiService.fetchQuestions();
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ─── Quiz Logic ────────────────────────────────────────────
  void _handleAnswer(String selected) {
    if (_answered) return; // guard — ignore taps after first answer

    setState(() {
      _answered = true;
      _selectedAnswer = selected;
      if (selected == _questions[_currentQuestionIndex].correctAnswer) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answered = false;
        _selectedAnswer = null;
      });
    } else {
      // Move to final score screen
      setState(() {
        _currentQuestionIndex = _questions.length; // sentinel value
      });
    }
  }

  void _restartQuiz() {
    setState(() {
      _questions = [];
      _currentQuestionIndex = 0;
      _score = 0;
      _answered = false;
      _selectedAnswer = null;
      _isLoading = true;
      _errorMessage = null;
    });
    _loadQuestions();
  }

  // ─── Color Helpers ─────────────────────────────────────────
  Color _buttonColor(String answer) {
    if (!_answered) return Colors.white;
    final correct = _questions[_currentQuestionIndex].correctAnswer;
    if (answer == correct) return const Color(0xFF4CAF50);       // green
    if (answer == _selectedAnswer) return const Color(0xFFE53935); // red
    return Colors.white;
  }

  Color _buttonTextColor(String answer) {
    if (!_answered) return const Color(0xFF1a1a2e);
    final correct = _questions[_currentQuestionIndex].correctAnswer;
    if (answer == correct || answer == _selectedAnswer) return Colors.white;
    return const Color(0xFF1a1a2e);
  }

  // ─── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0c29),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoadingState();
    if (_errorMessage != null) return _buildErrorState();
    if (_questions.isEmpty) return _buildErrorState();

    // Show final score screen once we've passed the last question
    if (_currentQuestionIndex >= _questions.length) return _buildScoreScreen();

    return _buildQuizContent();
  }

  // ─── Loading State ─────────────────────────────────────────
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF9c6fff),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Loading questions...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Error State ───────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Color(0xFF9c6fff), size: 64),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unable to load questions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            _primaryButton(
              label: 'Try Again',
              icon: Icons.refresh_rounded,
              onTap: _restartQuiz,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Quiz Content ──────────────────────────────────────────
  Widget _buildQuizContent() {
    final question = _questions[_currentQuestionIndex];
    final questionText = _unescape.convert(question.questionText);
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Column(
      children: [
        // ── Top Bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Question counter
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  letterSpacing: 0.4,
                ),
              ),
              // Score badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF9c6fff).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF9c6fff).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFF9c6fff), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$_score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Progress Bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF9c6fff)),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // ── Question Card ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Question text card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1744),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    questionText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Answer Buttons ──
                ...question.answers.map((answer) {
                  final decoded = _unescape.convert(answer);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: _buttonColor(answer),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _answered
                              ? Colors.transparent
                              : const Color(0xFF9c6fff).withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _answered ? null : () => _handleAnswer(answer),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 18),
                            child: Text(
                              decoded,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _buttonTextColor(answer),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // ── Next Button ──
                if (_answered) ...[
                  const SizedBox(height: 8),
                  _primaryButton(
                    label: _currentQuestionIndex < _questions.length - 1
                        ? 'Next Question'
                        : 'See Results',
                    icon: _currentQuestionIndex < _questions.length - 1
                        ? Icons.arrow_forward_rounded
                        : Icons.emoji_events_rounded,
                    onTap: _nextQuestion,
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Final Score Screen ────────────────────────────────────
  Widget _buildScoreScreen() {
    final percentage = (_score / _questions.length * 100).round();

    String emoji;
    String headline;
    if (percentage == 100) {
      emoji = '🏆';
      headline = 'Perfect Score!';
    } else if (percentage >= 70) {
      emoji = '🎉';
      headline = 'Great Work!';
    } else if (percentage >= 40) {
      emoji = '💪';
      headline = 'Keep Practising!';
    } else {
      emoji = '📚';
      headline = 'Better luck next time!';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 20),
            Text(
              headline,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You scored $_score out of ${_questions.length}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),

            // Score ring
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF9c6fff), Color(0xFF6c3fff)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9c6fff).withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48),
            _primaryButton(
              label: 'Play Again',
              icon: Icons.replay_rounded,
              onTap: _restartQuiz,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Shared Button Widget ──────────────────────────────────
  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9c6fff),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}