import 'package:get/get.dart';
import 'package:rowan_mind_lab/data/models.dart';
import 'package:rowan_mind_lab/routers/routers.dart';

class TestPlayController extends GetxController {
  // 이전 화면에서 넘겨준 TestItem 객체 (원본 데이터)
  late TestItem testItem;

  // ⭐️ [NEW] 이번 테스트에서 실제로 사용할 질문 리스트 (섞이고 7개로 줄어든 것)
  List<Question> activeQuestions = [];

  // 반응형 변수들
  var currentQuestionIndex = 0.obs;
  var totalScore = 0.obs;

  // 게터: 현재 보여줄 질문 (원본 대신 activeQuestions 사용)
  Question get currentQuestion => activeQuestions[currentQuestionIndex.value];

  // 게터: 진행률 (0.0 ~ 1.0)
  double get progress => (currentQuestionIndex.value + 1) / activeQuestions.length;

  @override
  void onInit() {
    super.onInit();
    // 화면 이동 시 arguments로 데이터 받기
    if (Get.arguments != null) {
      testItem = Get.arguments as TestItem;

      // -------------------------------------------------------
      // 🎲 [핵심 로직] 질문 섞고 7개만 뽑기
      // -------------------------------------------------------
      // 1. 원본 질문 리스트 복사
      List<Question> allQuestions = List.from(testItem.questions);

      // 2. 무작위로 섞기
      allQuestions.shuffle();

      // 3. 앞에서부터 7개만 자르기 (질문이 7개보다 적으면 전체 다 사용)
      if (allQuestions.length > 7) {
        activeQuestions = allQuestions.sublist(0, 7);
      } else {
        activeQuestions = allQuestions;
      }
      // -------------------------------------------------------

    } else {
      Get.back(); // 데이터 없으면 뒤로가기
      Get.snackbar("오류", "테스트 데이터를 불러오지 못했습니다.");
    }
  }

  // 답변 선택 시 호출
  void selectOption(int score) {
    totalScore.value += score;

    // activeQuestions.length를 기준으로 판단
    if (currentQuestionIndex.value < activeQuestions.length - 1) {
      // 다음 문제로 이동
      currentQuestionIndex.value++;
    } else {
      // 마지막 문제 -> 결과 계산 및 이동
      _finishTest();
    }
  }

  void _finishTest() {
    // 1. 점수에 맞는 결과 찾기
    // (참고: 문항 수가 줄었으므로 점수 기준도 tests.json에서 조정되어 있어야 정확합니다)
    TestResult finalResult = testItem.results.firstWhere(
          (result) => totalScore.value >= result.minScore && totalScore.value <= result.maxScore,
      orElse: () => testItem.results.first, // 예외 처리: 첫 번째 결과 반환
    );

    // 결과 화면으로 이동
    Get.offNamed(Routes.RESULT, arguments: finalResult);
  }
}