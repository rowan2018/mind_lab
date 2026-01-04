import 'package:get/get.dart'; // 폰 언어 확인용 (필수!)

// 1. 오늘의 명언 모델 (다국어 지원 완료)
class DailyQuote {
  // DB에서 오는 데이터들 (한국어, 영어, 일본어)
  final String contentKo;
  final String contentEn;
  final String contentJp;

  final String authorKo;
  final String authorEn;
  final String authorJp;

  DailyQuote({
    required this.contentKo,
    required this.contentEn,
    required this.contentJp,
    required this.authorKo,
    required this.authorEn,
    required this.authorJp,
  });

  factory DailyQuote.fromJson(Map<String, dynamic> json) {
    return DailyQuote(
      contentKo: json['content_ko'] ?? json['content'] ?? '', // 옛날 버전 호환
      contentEn: json['content_en'] ?? json['content'] ?? '',
      contentJp: json['content_jp'] ?? json['content'] ?? '',

      authorKo: json['author_ko'] ?? json['author'] ?? '',
      authorEn: json['author_en'] ?? json['author'] ?? '',
      authorJp: json['author_jp'] ?? json['author'] ?? '',
    );
  }

  // ✨ 마법의 Getter (화면은 이걸 부르면 됨)
  String get content {
    String lang = Get.deviceLocale?.languageCode ?? 'en';
    if (lang == 'ko') return contentKo;
    if (lang == 'ja') return contentJp;
    return contentEn;
  }


  String get author {
    String lang = Get.deviceLocale?.languageCode ?? 'en';
    if (lang == 'ko') return authorKo;
    if (lang == 'ja') return authorJp;
    return authorEn;
  }
}

// 2. 선택지 모델 (다국어 업그레이드 완료)
class Option {
  // 실제 데이터는 3개 다 가지고 있음
  final String textKo;
  final String textEn;
  final String textJp;
  final int score;

  Option({
    required this.textKo,
    required this.textEn,
    required this.textJp,
    required this.score,
  });

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      textKo: json['text_ko'] ?? json['text'] ?? '', // 옛날 버전 호환
      textEn: json['text_en'] ?? json['text'] ?? '',
      textJp: json['text_jp'] ?? json['text'] ?? '',
      score: json['score'] ?? 0,
    );
  }

  // ✨ 마법의 Getter: 화면에서 .text를 부르면 알아서 언어 바꿔줌
  String get text {
    String lang = Get.deviceLocale?.languageCode ?? 'en';
    if (lang == 'ko') return textKo;
    if (lang == 'ja') return textJp;
    return textEn; // 기본은 영어
  }
}

// 3. 질문 모델 (다국어 업그레이드 완료)
class Question {
  final int qId;
  final String textKo;
  final String textEn;
  final String textJp;
  final List<Option> options;

  Question({
    required this.qId,
    required this.textKo,
    required this.textEn,
    required this.textJp,
    required this.options,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    var list = json['options'] as List? ?? [];
    List<Option> optionList = list.map((i) => Option.fromJson(i)).toList();

    return Question(
      qId: json['q_id'] ?? 0,
      textKo: json['text_ko'] ?? json['text'] ?? '',
      textEn: json['text_en'] ?? json['text'] ?? '',
      textJp: json['text_jp'] ?? json['text'] ?? '',
      options: optionList,
    );
  }

  // ✨ 마법의 Getter
  String get text {
    String lang = Get.deviceLocale?.languageCode ?? 'en';
    if (lang == 'ko') return textKo;
    if (lang == 'ja') return textJp;
    return textEn;
  }
}

// 4. 결과 모델 (다국어 업그레이드 완료)
class TestResult {
  final int minScore;
  final int maxScore;

  final String resultTitleKo;
  final String resultTitleEn;
  final String resultTitleJp;

  final String resultDescKo;
  final String resultDescEn;
  final String resultDescJp;

  final String imgUrl;

  TestResult({
    required this.minScore,
    required this.maxScore,
    required this.resultTitleKo,
    required this.resultTitleEn,
    required this.resultTitleJp,
    required this.resultDescKo,
    required this.resultDescEn,
    required this.resultDescJp,
    required this.imgUrl,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      minScore: json['minScore'] ?? 0,
      maxScore: json['maxScore'] ?? 0,

      resultTitleKo: json['resultTitle_ko'] ?? json['resultTitle'] ?? '',
      resultTitleEn: json['resultTitle_en'] ?? json['resultTitle'] ?? '',
      resultTitleJp: json['resultTitle_jp'] ?? json['resultTitle'] ?? '',

      resultDescKo: json['resultDesc_ko'] ?? json['resultDesc'] ?? '',
      resultDescEn: json['resultDesc_en'] ?? json['resultDesc'] ?? '',
      resultDescJp: json['resultDesc_jp'] ?? json['resultDesc'] ?? '',

      imgUrl: json['imgUrl'] ?? '',
    );
  }

  // ✨ 마법의 Getter
  String get resultTitle {
    String lang = Get.deviceLocale?.languageCode ?? 'en';
    if (lang == 'ko') return resultTitleKo;
    if (lang == 'ja') return resultTitleJp;
    return resultTitleEn;
  }

  String get resultDesc {
    String lang = Get.deviceLocale?.languageCode ?? 'en';
    if (lang == 'ko') return resultDescKo;
    if (lang == 'ja') return resultDescJp;
    return resultDescEn;
  }
}

// 5. 전체 테스트 아이템 모델 (다국어 업그레이드 완료)
class TestItem {
  final String id;
  final bool isPrimary;
  final String titleKo;
  final String titleEn;
  final String titleJp;

  final String descriptionKo;
  final String descriptionEn;
  final String descriptionJp;

  final String thumbnailUrl;
  final String? status;
  final List<Question> questions;
  final List<TestResult> results;

  TestItem({
    required this.id,
    this.isPrimary = false,
    required this.titleKo,
    required this.titleEn,
    required this.titleJp,
    required this.descriptionKo,
    required this.descriptionEn,
    required this.descriptionJp,
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
      isPrimary: json['isPrimary'] ?? false,
      titleKo: json['title_ko'] ?? json['title'] ?? '',
      titleEn: json['title_en'] ?? json['title'] ?? '',
      titleJp: json['title_jp'] ?? json['title'] ?? '',

      descriptionKo: json['description_ko'] ?? json['description'] ?? '',
      descriptionEn: json['description_en'] ?? json['description'] ?? '',
      descriptionJp: json['description_jp'] ?? json['description'] ?? '',

      thumbnailUrl: json['thumbnailUrl'] ?? '',
      status: json['status'],
      questions: questionList,
      results: resultList,
    );
  }

  // ✨ 마법의 Getter
  String get title {
    String lang = Get.deviceLocale?.languageCode ?? 'en';
    if (lang == 'ko') return titleKo;
    if (lang == 'ja') return titleJp;
    return titleEn;
  }

  String get description {
    String lang = Get.deviceLocale?.languageCode ?? 'en';
    if (lang == 'ko') return descriptionKo;
    if (lang == 'ja') return descriptionJp;
    return descriptionEn;
  }
}