// lib/question.dart

class Question {
  final String questionText;
  final List<String> answers;      // all 4 options, shuffled
  final String correctAnswer;

  Question({
    required this.questionText,
    required this.answers,
    required this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    // Step 1: Pull the correct answer out first so we can
    // compare against it later in the UI
    final String correct = json['correct_answer'];

    // Step 2: Build a combined list of all 4 answer options
    final List<String> allAnswers =
        List<String>.from(json['incorrect_answers'])..add(correct);

    // Step 3: Shuffle so the correct answer isn't always last
    allAnswers.shuffle();

    return Question(
      questionText: json['question'],
      answers: allAnswers,
      correctAnswer: correct,
    );
  }
}