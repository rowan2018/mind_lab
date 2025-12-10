// lib/data/models.dart

// 1. 오늘의 명언 모델
class DailyQuote {
  final String content;
  final String author;

  DailyQuote({required this.content, required this.author});

  factory DailyQuote.fromJson(Map<String, dynamic> json) {
    return DailyQuote(
      content: json['content'] ?? '',
      author: json['author'] ?? '',
    );
  }
}

// 2. 선택지 모델 (에러 해결: class Option)
class Option {
  final String text;
  final int score;

  Option({required this.text, required this.score});

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      text: json['text'] ?? '',
      score: json['score'] ?? 0,
    );
  }
}

// 3. 질문 모델 (에러 해결: class Question)
class Question {
  final int qId;
  final String text;
  final List<Option> options;

  Question({required this.qId, required this.text, required this.options});

  factory Question.fromJson(Map<String, dynamic> json) {
    var list = json['options'] as List? ?? [];
    List<Option> optionList = list.map((i) => Option.fromJson(i)).toList();

    return Question(
      qId: json['q_id'] ?? 0,
      text: json['text'] ?? '',
      options: optionList,
    );
  }
}

// 4. 결과 모델
class TestResult {
  final int minScore;
  final int maxScore;
  final String resultTitle;
  final String resultDesc;
  final String imgUrl;

  TestResult({
    required this.minScore,
    required this.maxScore,
    required this.resultTitle,
    required this.resultDesc,
    required this.imgUrl,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      minScore: json['minScore'] ?? 0,
      maxScore: json['maxScore'] ?? 0,
      resultTitle: json['resultTitle'] ?? '',
      resultDesc: json['resultDesc'] ?? '',
      imgUrl: json['imgUrl'] ?? '',
    );
  }
}

// 5. 전체 테스트 아이템 모델 (에러 해결: status, questions 추가됨!)
class TestItem {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String? status; // ✨ 에러 해결!
  final List<Question> questions; // ✨ 에러 해결!
  final List<TestResult> results; // ✨ 에러 해결!

  TestItem({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    this.status,
    required this.questions,
    required this.results,
  });

  factory TestItem.fromJson(Map<String, dynamic> json) {
    var qList = json['questions'] as List? ?? [];
    List<Question> questionList = qList.map((i) => Question.fromJson(i)).toList();

    var rList = json['results'] as List? ?? [];
    List<TestResult> resultList = rList.map((i) => TestResult.fromJson(i)).toList();

    return TestItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      status: json['status'],
      questions: questionList,
      results: resultList,
    );
  }
}