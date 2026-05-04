class Question {
  String question;
  List<String>? options;
  int? correctIndex;
  bool isEssay;

  Question({
    required this.question,
    this.options,
    this.correctIndex,
    this.isEssay = false,
  });
}

List<Question> questions = [];
List<Map<String, dynamic>> studentResults = [];
