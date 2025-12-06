class DailyQuote {
  final String content;
  final String author;

  DailyQuote({required this.content, required this.author});

  factory DailyQuote.fromJson(Map<String, dynamic> json) {
    return DailyQuote(
      content: json['content'] ?? '',
      author: json['author'] ?? 'Unknown',
    );
  }
}

class TestItem {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final List<Question> questions;
  final List<TestResult> results;

  TestItem({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.questions,
    required this.results,
  });

  factory TestItem.fromJson(Map<String, dynamic> json) {
    return TestItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      thumbnailUrl: json['thumbnailUrl'],
      questions: (json['questions'] as List).map((e) => Question.fromJson(e)).toList(),
      results: (json['results'] as List).map((e) => TestResult.fromJson(e)).toList(),
    );
  }
}

class Question {
  final String text;
  final List<Option> options;

  Question({required this.text, required this.options});

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      text: json['text'],
      options: (json['options'] as List).map((e) => Option.fromJson(e)).toList(),
    );
  }
}

class Option {
  final String text;
  final int score;

  Option({required this.text, required this.score});

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(text: json['text'], score: json['score']);
  }
}

class TestResult {
  final int minScore;
  final int maxScore;
  final String resultTitle;
  final String resultDesc;
  final String? imgUrl; // 여기 추가됨 (이미지가 없을 수도 있으니 nullable로 처리)

  TestResult({
    required this.minScore,
    required this.maxScore,
    required this.resultTitle,
    required this.resultDesc,
    this.imgUrl, // 생성자에도 추가
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      minScore: json['minScore'],
      maxScore: json['maxScore'],
      resultTitle: json['resultTitle'],
      resultDesc: json['resultDesc'],
      imgUrl: json['imgUrl'], // JSON 파싱에도 추가
    );
  }
}