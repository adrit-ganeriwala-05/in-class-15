// lib/quiz_screen.dart

import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'api_service.dart';
import 'question.dart';

// ─── Design Tokens ────────────────────────────────────────────
class _AppColors {
  static const background   = Color(0xFFF2F2F7); // iOS system grouped bg
  static const card         = Colors.white;
  static const label        = Color(0xFF1C1C1E); // iOS primary label
  static const secondLabel  = Color(0xFF8E8E93); // iOS secondary label
  static const separator    = Color(0xFFE5E5EA); // iOS separator
  static const accent       = Color(0xFF007AFF); // iOS system blue
  static const success      = Color(0xFF34C759); // iOS system green
  static const danger       = Color(0xFFFF3B30); // iOS system red
  static const accentLight  = Color(0xFFEAF2FF); // accent tint for bg
  static const successLight = Color(0xFFEAFAEE);
  static const dangerLight  = Color(0xFFFFEBEA);
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {

  // ─── State ────────────────────────────────────────────────
  List<Question> _questions   = [];
  int  _currentIndex          = 0;
  int  _score                 = 0;
  bool _answered              = false;
  String? _selectedAnswer;
  bool _isLoading             = true;
  String? _errorMessage;

  late AnimationController _fadeController;
  late Animation<double>   _fadeAnimation;

  final HtmlUnescape _unescape = HtmlUnescape();

  // ─── Lifecycle ────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _loadQuestions();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ─── Data ─────────────────────────────────────────────────
  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading     = true;
      _errorMessage  = null;
    });
    try {
      final questions = await ApiService.fetchQuestions();
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
      _fadeController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading    = false;
      });
    }
  }

  // ─── Logic ────────────────────────────────────────────────
  void _handleAnswer(String selected) {
    if (_answered) return;
    setState(() {
      _answered        = true;
      _selectedAnswer  = selected;
      if (selected == _questions[_currentIndex].correctAnswer) _score++;
    });
  }

  void _nextQuestion() {
    _fadeController.reverse().then((_) {
      setState(() {
        if (_currentIndex < _questions.length - 1) {
          _currentIndex++;
          _answered       = false;
          _selectedAnswer = null;
        } else {
          _currentIndex = _questions.length; // triggers score screen
        }
      });
      _fadeController.forward();
    });
  }

  void _restartQuiz() {
    _fadeController.reverse().then((_) {
      setState(() {
        _questions      = [];
        _currentIndex   = 0;
        _score          = 0;
        _answered       = false;
        _selectedAnswer = null;
        _isLoading      = true;
        _errorMessage   = null;
      });
      _loadQuestions();
    });
  }

  // ─── Answer Button Styling ────────────────────────────────
  Color _buttonBg(String answer) {
    if (!_answered) return _AppColors.card;
    final correct = _questions[_currentIndex].correctAnswer;
    if (answer == correct)       return _AppColors.successLight;
    if (answer == _selectedAnswer) return _AppColors.dangerLight;
    return _AppColors.card;
  }

  Color _buttonBorder(String answer) {
    if (!_answered) return _AppColors.separator;
    final correct = _questions[_currentIndex].correctAnswer;
    if (answer == correct)         return _AppColors.success;
    if (answer == _selectedAnswer) return _AppColors.danger;
    return _AppColors.separator;
  }

  Color _buttonTextColor(String answer) {
    if (!_answered) return _AppColors.label;
    final correct = _questions[_currentIndex].correctAnswer;
    if (answer == correct)         return _AppColors.success;
    if (answer == _selectedAnswer) return _AppColors.danger;
    return _AppColors.secondLabel;
  }

  IconData? _buttonIcon(String answer) {
    if (!_answered) return null;
    final correct = _questions[_currentIndex].correctAnswer;
    if (answer == correct)         return Icons.check_circle_rounded;
    if (answer == _selectedAnswer) return Icons.cancel_rounded;
    return null;
  }

  // ─── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading)          return _buildLoading();
    if (_errorMessage != null) return _buildError();
    if (_questions.isEmpty)  return _buildError();
    if (_currentIndex >= _questions.length) return _buildScoreScreen();
    return _buildQuiz();
  }

  // ─── Loading ──────────────────────────────────────────────
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: _AppColors.accent,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading questions',
            style: TextStyle(
              fontSize: 15,
              color: _AppColors.secondLabel,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Error ────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _AppColors.dangerLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: _AppColors.danger,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No connection',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _AppColors.label,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to load questions. Check your connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: _AppColors.secondLabel,
                height: 1.5,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 32),
            _appleButton(
              label: 'Try Again',
              onTap: _restartQuiz,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Main Quiz ────────────────────────────────────────────
  Widget _buildQuiz() {
    final question     = _questions[_currentIndex];
    final questionText = _unescape.convert(question.questionText);
    final progress     = (_currentIndex + 1) / _questions.length;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentIndex + 1} of ${_questions.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _AppColors.secondLabel,
                    letterSpacing: -0.1,
                  ),
                ),
                // Score pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _AppColors.accentLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: _AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_score',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _AppColors.accent,
                          letterSpacing: -0.2,
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
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: _AppColors.separator,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  _AppColors.accent,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Question Card ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _AppColors.card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                questionText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _AppColors.label,
                  height: 1.5,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Answer Buttons ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                ...question.answers.map((answer) {
                  final decoded = _unescape.convert(answer);
                  final icon    = _buttonIcon(answer);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: _buttonBg(answer),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _buttonBorder(answer),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _answered
                              ? null
                              : () => _handleAnswer(answer),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    decoded,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: _buttonTextColor(answer),
                                      letterSpacing: -0.2,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                if (icon != null) ...[
                                  const SizedBox(width: 10),
                                  Icon(
                                    icon,
                                    size: 20,
                                    color: _buttonTextColor(answer),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // ── Next Button ──
                if (_answered) ...[
                  const SizedBox(height: 4),
                  _appleButton(
                    label: _currentIndex < _questions.length - 1
                        ? 'Next Question'
                        : 'See Results',
                    onTap: _nextQuestion,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Score Screen ─────────────────────────────────────────
  Widget _buildScoreScreen() {
    final pct = (_score / _questions.length * 100).round();

    String emoji;
    String headline;
    String sub;

    if (pct == 100) {
      emoji    = '🏆';
      headline = 'Perfect Score';
      sub      = 'You got every single one right.';
    } else if (pct >= 70) {
      emoji    = '🎉';
      headline = 'Well Done';
      sub      = 'That\'s a solid performance.';
    } else if (pct >= 40) {
      emoji    = '💪';
      headline = 'Keep Going';
      sub      = 'You\'re getting there.';
    } else {
      emoji    = '📚';
      headline = 'Room to Grow';
      sub      = 'Try again and beat your score.';
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Text(emoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 20),

              Text(
                headline,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.label,
                  letterSpacing: -0.8,
                ),
              ),

              const SizedBox(height: 8),
              Text(
                sub,
                style: const TextStyle(
                  fontSize: 15,
                  color: _AppColors.secondLabel,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 40),

              // Score card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 28, horizontal: 24),
                decoration: BoxDecoration(
                  color: _AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _scoreStat('$_score', 'Correct'),
                    _scoreDivider(),
                    _scoreStat(
                      '${_questions.length - _score}', 'Wrong'),
                    _scoreDivider(),
                    _scoreStat('$pct%', 'Score'),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              _appleButton(
                label: 'Play Again',
                onTap: _restartQuiz,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: _AppColors.label,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: _AppColors.secondLabel,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _scoreDivider() {
    return Container(
      height: 36,
      width: 1,
      color: _AppColors.separator,
    );
  }

  // ─── Shared Apple-Style Button ────────────────────────────
  Widget _appleButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoStyleButton(
        label: label,
        onTap: onTap,
      ),
    );
  }
}

// ─── Reusable Apple-Style Button ──────────────────────────────
class CupertinoStyleButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const CupertinoStyleButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _AppColors.accent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 17),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }
}