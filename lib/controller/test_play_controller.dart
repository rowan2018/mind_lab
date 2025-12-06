import 'package:get/get.dart';
import 'package:rowan_mind_lab/data/models.dart';
import 'package:rowan_mind_lab/screens/result_screen.dart'; // 결과 화면 (나중에 생성)
import 'package:rowan_mind_lab/routers/routers.dart';

class TestPlayController extends GetxController {
  // 이전 화면에서 넘겨준 TestItem 객체
  late TestItem testItem;

  // 반응형 변수들
  var currentQuestionIndex = 0.obs;
  var totalScore = 0.obs;

  // 게터: 현재 보여줄 질문
  Question get currentQuestion => testItem.questions[currentQuestionIndex.value];

  // 게터: 진행률 (0.0 ~ 1.0)
  double get progress => (currentQuestionIndex.value + 1) / testItem.questions.length;

  @override
  void onInit() {
    super.onInit();
    // 화면 이동 시 arguments로 데이터 받기
    if (Get.arguments != null) {
      testItem = Get.arguments as TestItem;
    } else {
      Get.back(); // 데이터 없으면 뒤로가기
      Get.snackbar("오류", "테스트 데이터를 불러오지 못했습니다.");
    }
  }

  // 답변 선택 시 호출
  void selectOption(int score) {
    totalScore.value += score;

    if (currentQuestionIndex.value < testItem.questions.length - 1) {
      // 다음 문제로 이동
      currentQuestionIndex.value++;
    } else {
      // 마지막 문제 -> 결과 계산 및 이동
      _finishTest();
    }
  }

  void _finishTest() {
    // 1. 점수에 맞는 결과 찾기
    TestResult finalResult = testItem.results.firstWhere(
          (result) => totalScore.value >= result.minScore && totalScore.value <= result.maxScore,
      orElse: () => testItem.results.first, // 예외 처리: 첫 번째 결과 반환
    );

    // ---------------------------------------------------------
    // 👇 여기를 수정하세요!
    // ---------------------------------------------------------

    // 기존 알람(snackbar) 코드는 이제 지우거나 주석 처리 하세요
    // Get.snackbar("테스트 완료", "결과: ${finalResult.resultTitle}");

    // ⭐ 진짜 결과 화면으로 이동하는 코드 (데이터 들고 이동!)
   // Get.offNamed('/result', arguments: finalResult);

    // (만약 routers.dart를 쓰신다면 아래처럼 쓰셔도 됩니다)
     Get.offNamed(Routes.RESULT, arguments: finalResult);
  }
}