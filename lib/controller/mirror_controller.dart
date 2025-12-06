import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // 광고 패키지
// import 'package:rowan_mind_lab/controller/ad_controller.dart'; // (나중에 광고 컨트롤러 연결)
import 'dart:convert'; // jsonEncode 쓰려면 필요
import 'package:http/http.dart' as http; // 통신 패키지

class MirrorController extends GetxController {
  final TextEditingController textController = TextEditingController();

  // 🍎 황금 사과 개수 (기본 0개에서 시작)
  var appleCount = 100.obs;
  var isLoading = false.obs;
  var answerText = "".obs;

  // 💰 질문 1회당 비용 (사장님 기획: 7개)
  final int costPerQuestion = 2;

  // 🕵️ [핵심] 심사 통과용 스위치 (이것만 false로 두면 버튼 숨겨짐)
  final bool isAdEnabled = false;

  @override
  void onInit() {
    super.onInit();
    // (나중에 여기에 저장된 사과 개수 불러오는 로직 추가)
  }

  // 질문하기
  void askMirror() async {
    String question = textController.text.trim();
    if (question.isEmpty) return;

    // 1. 사과 부족 체크
    if (appleCount.value < costPerQuestion) {
      Get.dialog(
        AlertDialog(
          title: const Text("🍎 사과가 부족해요"),
          content: Text("신비한 거울에게 질문하려면\n황금 사과 $costPerQuestion개가 필요합니다.\n(현재: ${appleCount.value}개)"),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("취소"),
            ),
            // 심사 중엔 이 버튼이 아예 안 보이거나, 눌러도 반응 없게
            if (isAdEnabled)
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  // TODO: 광고 보여주고 사과 충전하는 함수 연결
                  // AdController.to.showRewardAd();
                },
                child: const Text("광고 보고 충전 (+5개)"),
              ),
          ],
        ),
      );
      return;
    }

    // 2. 정상 진행 (사과 차감)
    appleCount.value -= costPerQuestion;
    isLoading.value = true;
    answerText.value = "";
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      // ⭐ [여기가 핵심] 진짜 서버로 요청 보내기
      // 사장님 윈도우 서버 주소 + 포트 3000
      final url = Uri.parse('http://www.rowanzone.co.kr:3000/ask-mirror');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "question": question,
          "lang": Get.locale?.languageCode ?? 'ko' // 현재 언어(ko/ja)도 같이 보냄
        }),
      );

      if (response.statusCode == 200) {
        // 성공! 서버가 준 답변을 화면에 표시
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        answerText.value = data['answer'];
      } else {
        answerText.value = "거울의 마력이 부족하여 연결되지 않았습니다. (서버 에러)";
        print("서버 에러: ${response.statusCode}");
      }

    } catch (e) {
      answerText.value = "거울이 흐려져 아무것도 보이지 않습니다... (인터넷 연결 확인)";
      print("통신 실패: $e");
    } finally {
      isLoading.value = false;
      textController.clear();
    }
  }
}