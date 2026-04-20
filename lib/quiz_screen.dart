// lib/quiz_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html_unescape/html_unescape.dart';
import 'api_service.dart';
import 'question.dart';

// ─────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────

class _C {
  static const bg           = Color(0xFFF2F2F7);
  static const card         = Color(0xFFFFFFFF);
  static const label        = Color(0xFF1C1C1E);
  static const label2       = Color(0xFF8E8E93);
  static const label3       = Color(0xFFC7C7CC);
  static const sep          = Color(0xFFE5E5EA);
  static const accent       = Color(0xFF007AFF);
  static const accentBg     = Color(0xFFEAF2FF);
  static const success      = Color(0xFF34C759);
  static const successBg    = Color(0xFFEAFAEE);
  static const danger       = Color(0xFFFF3B30);
  static const dangerBg     = Color(0xFFFFEBEA);
  static const badgeBg      = Color(0xFFF2F2F7);
  static const badgeLabel   = Color(0xFF8E8E93);
}

// ─────────────────────────────────────────────────────────────
// Start Screen
// ─────────────────────────────────────────────────────────────

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),

              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _C.accentBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: _C.accent,
                  size: 32,
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Trivia',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: _C.label,
                  letterSpacing: -1.2,
                  height: 1.1,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                '10 questions.\nGeneral knowledge.\nHow well do you know the world?',
                style: TextStyle(
                  fontSize: 17,
                  color: _C.label2,
                  height: 1.6,
                  letterSpacing: -0.2,
                ),
              ),

              const Spacer(flex: 2),

              Row(
                children: [
                  _statPill(Icons.help_outline_rounded, '10 Questions'),
                  const SizedBox(width: 10),
                  _statPill(Icons.bar_chart_rounded, 'Easy'),
                  const SizedBox(width: 10),
                  _statPill(Icons.category_rounded, 'General'),
                ],
              ),

              const SizedBox(height: 32),

              _PrimaryButton(
                label: 'Start Quiz',
                onTap: () => Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const QuizScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) =>
                            FadeTransition(opacity: animation, child: child),
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.sep),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _C.label2),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _C.label2,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Quiz Screen
// ─────────────────────────────────────────────────────────────

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {

  // ── State ──────────────────────────────────────────────────
  List<Question> _questions  = [];
  int    _currentIndex       = 0;
  int    _score              = 0;
  bool   _answered           = false;
  String? _selectedAnswer;
  bool   _isLoading          = true;
  String? _errorMessage;

  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _fadeCtrl,
    curve: Curves.easeIn,
  );

  final HtmlUnescape _unescape = HtmlUnescape();
  static const List<String> _labels = ['A', 'B', 'C', 'D'];

  // ── Lifecycle ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────
  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });
    try {
      final questions = await ApiService.fetchQuestions();
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading    = false;
      });
    }
  }

  // ── Logic ──────────────────────────────────────────────────
  void _handleAnswer(String selected) {
    if (_answered) return;
    HapticFeedback.lightImpact();
    setState(() {
      _answered       = true;
      _selectedAnswer = selected;
      if (selected == _questions[_currentIndex].correctAnswer) _score++;
    });
  }

  void _nextQuestion() {
    _fadeCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        if (_currentIndex < _questions.length - 1) {
          _currentIndex++;
          _answered       = false;
          _selectedAnswer = null;
        } else {
          _currentIndex = _questions.length;
        }
      });
      _fadeCtrl.forward();
    });
  }

  void _restartQuiz() {
    _fadeCtrl.reverse().then((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const StartScreen(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    });
  }

  // ── Answer Styling ─────────────────────────────────────────
  Color _btnBg(String answer) {
    if (!_answered) return _C.card;
    final c = _questions[_currentIndex].correctAnswer;
    if (answer == c)               return _C.successBg;
    if (answer == _selectedAnswer) return _C.dangerBg;
    return _C.card;
  }

  Color _btnBorder(String answer) {
    if (!_answered) return _C.sep;
    final c = _questions[_currentIndex].correctAnswer;
    if (answer == c)               return _C.success;
    if (answer == _selectedAnswer) return _C.danger;
    return _C.sep;
  }

  Color _btnLabelColor(String answer) {
    if (!_answered) return _C.label;
    final c = _questions[_currentIndex].correctAnswer;
    if (answer == c)               return _C.success;
    if (answer == _selectedAnswer) return _C.danger;
    return _C.label3;
  }

  Color _badgeBg(String answer) {
    if (!_answered) return _C.badgeBg;
    final c = _questions[_currentIndex].correctAnswer;
    if (answer == c)               return _C.success;
    if (answer == _selectedAnswer) return _C.danger;
    return _C.badgeBg;
  }

  Color _badgeLabelColor(String answer) {
    if (!_answered) return _C.badgeLabel;
    final c = _questions[_currentIndex].correctAnswer;
    if (answer == c || answer == _selectedAnswer) return Colors.white;
    return _C.badgeLabel;
  }

  Widget _badgeContent(int index, String answer) {
    if (!_answered) {
      return Text(
        _labels[index],
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _badgeLabelColor(answer),
          letterSpacing: 0.2,
        ),
      );
    }
    final c = _questions[_currentIndex].correctAnswer;
    if (answer == c) {
      return Icon(Icons.check_rounded, size: 14, color: _badgeLabelColor(answer));
    }
    if (answer == _selectedAnswer) {
      return Icon(Icons.close_rounded, size: 14, color: _badgeLabelColor(answer));
    }
    return Text(
      _labels[index],
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _badgeLabelColor(answer),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading)                         return _buildLoading();
    if (_errorMessage != null)              return _buildError();
    if (_questions.isEmpty)                 return _buildError();
    if (_currentIndex >= _questions.length) return _buildScoreScreen();
    return _buildQuiz();
  }

  // ── Loading ────────────────────────────────────────────────
  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              color: _C.accent,
              strokeWidth: 2,
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Loading questions…',
            style: TextStyle(
              fontSize: 15,
              color: _C.label2,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: _C.dangerBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: _C.danger,
                size: 30,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Connection failed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _C.label,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ??
                  'Unable to load questions.\nCheck your connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: _C.label2,
                height: 1.55,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 32),
            _PrimaryButton(
              label: 'Try Again',
              onTap: _loadQuestions,
            ),
          ],
        ),
      ),
    );
  }

  // ── Quiz ───────────────────────────────────────────────────
  Widget _buildQuiz() {
    final q            = _questions[_currentIndex];
    final questionText = _unescape.convert(q.questionText);
    final progress     = (_currentIndex + 1) / _questions.length;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Title + Score ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Trivia',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: _C.label,
                    letterSpacing: -0.8,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    key: ValueKey(_score),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _C.accentBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: _C.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_score',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _C.accent,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Progress Row ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _C.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _C.sep),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${_questions.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _C.label2,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: _C.sep,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        _C.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ── Question Card ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _C.accentBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'General Knowledge',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _C.accent,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    questionText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _C.label,
                      height: 1.5,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Answer Buttons ─────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                ...q.answers.asMap().entries.map((entry) {
                  final i       = entry.key;
                  final answer  = entry.value;
                  final decoded = _unescape.convert(answer);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: _btnBg(answer),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _btnBorder(answer),
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x07000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
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
                                horizontal: 14, vertical: 15),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: _badgeBg(answer),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: _badgeContent(i, answer),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    decoded,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: _btnLabelColor(answer),
                                      letterSpacing: -0.2,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                if (_answered) ...[
                  const SizedBox(height: 4),
                  _PrimaryButton(
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

  // ── Score Screen ───────────────────────────────────────────
  Widget _buildScoreScreen() {
    final total = _questions.length;
    final wrong = total - _score;
    final pct   = (_score / total * 100).round();

    String emoji;
    String headline;
    String sub;

    if (pct == 100) {
      emoji    = '🏆';
      headline = 'Perfect Score';
      sub      = 'You got every question right.';
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
      opacity: _fadeAnim,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 64, height: 1)),
              const SizedBox(height: 20),
              Text(
                headline,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: _C.label,
                  letterSpacing: -0.9,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                sub,
                style: const TextStyle(
                  fontSize: 15,
                  color: _C.label2,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 36),
              Row(
                children: [
                  _StatCard(
                    value: '$_score',
                    label: 'Correct',
                    bg: _C.successBg,
                    valueColor: _C.success,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    value: '$wrong',
                    label: 'Wrong',
                    bg: _C.dangerBg,
                    valueColor: _C.danger,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    value: '$pct%',
                    label: 'Score',
                    bg: _C.accentBg,
                    valueColor: _C.accent,
                  ),
                ],
              ),
              const SizedBox(height: 36),
              _PrimaryButton(
                label: 'Play Again',
                onTap: _restartQuiz,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: _C.accent,
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
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color bg;
  final Color valueColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.bg,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: valueColor,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: _C.label2,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}