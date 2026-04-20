// lib/question.dart

class Question {
  final String questionText;
  final List<String> answers;
  final String correctAnswer;

  Question({
    required this.questionText,
    required this.answers,
    required this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final String correct = json['correct_answer'] as String;

    final List<String> allAnswers =
        List<String>.from(json['incorrect_answers'] as List)..add(correct);

    allAnswers.shuffle();

    return Question(
      questionText: json['question'] as String,
      answers: allAnswers,
      correctAnswer: correct,
    );
  }
}