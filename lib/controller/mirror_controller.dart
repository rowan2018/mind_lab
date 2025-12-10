import 'dart:convert';
import 'dart:io'; // 파일 저장용
import 'dart:typed_data'; // 이미지 데이터 변환용
import 'dart:ui' as ui; // 이미지 캡처용

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // 캡처 경계 확인용
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart'; // 임시 폴더 경로용
import 'package:share_plus/share_plus.dart'; // 공유하기용

class MirrorController extends GetxController {
  final TextEditingController textController = TextEditingController();

  // 📸 화면 캡처를 위한 키
  final GlobalKey captureKey = GlobalKey();

  // 🍎 황금 사과 개수 (기본 100개)
  var appleCount = 100.obs;
  var isLoading = false.obs;
  var answerText = "".obs;

  // 💰 질문 1회당 비용
  final int costPerQuestion = 2;

  // 🕵️ 심사 통과용 스위치
  final bool isAdEnabled = false;

  @override
  void onInit() {
    super.onInit();
    // 나중에 로컬 저장소에서 사과 개수 불러오는 로직 추가 가능
  }

  // 📸 [기능] 화면 캡처 및 공유하기
  Future<void> captureAndShare() async {
    try {
      // 1. 캡처할 영역 가져오기
      RenderRepaintBoundary? boundary = captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        print("캡처 영역을 찾을 수 없습니다.");
        return;
      }

      // 2. 고화질 이미지로 변환 (pixelRatio 3.0 추천)
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return;
      Uint8List pngBytes = byteData.buffer.asUint8List();

      // 3. 휴대폰 임시 폴더에 파일로 저장
      final directory = await getTemporaryDirectory();
      final File imgFile = File('${directory.path}/genie_mirror_result.png');
      await imgFile.writeAsBytes(pngBytes);

      // 4. 공유 창 띄우기
      await Share.shareXFiles(
        [XFile(imgFile.path)],
        text: "[지니의 램프] 내 욕망을 꿰뚫어 본 지니의 답변...🔮\n#지니의램프 #팩폭 #소원",
      );

    } catch (e) {
      print("캡처 에러 발생: $e");
      Get.snackbar("오류", "이미지 공유 중 문제가 발생했습니다.", backgroundColor: Colors.white);
    }
  }

  // 🔮 [기능] 거울에게 질문하기
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
            if (isAdEnabled)
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  // 광고 보기 로직 연결
                },
                child: const Text("광고 보고 충전"),
              ),
          ],
        ),
      );
      return;
    }

    // 2. 정상 진행
    appleCount.value -= costPerQuestion;
    isLoading.value = true;
    answerText.value = "";
    FocusManager.instance.primaryFocus?.unfocus(); // 키보드 내리기

    try {
      // 서버 요청
      final url = Uri.parse('http://www.rowanzone.co.kr:3000/ask-mirror');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "question": question,
          "lang": Get.locale?.languageCode ?? 'ko'
        }),
      );


      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String rawAnswer = data['answer'];

        // ✨ [핵심] 정규식으로 (A), (B), 1. 등을 강제로 삭제
        // 1. 문장 맨 앞의 (A), A., 1. 같은 패턴 제거
        // 2. 따옴표(") 제거
        // 3. 앞뒤 공백 제거
        answerText.value = rawAnswer
            .replaceAll(RegExp(r'^[\(]?[A-Z0-9][\)\.]?\s*'), '')
            .replaceAll('"', '')
            .trim();
      } else {
        answerText.value = "거울의 마력이 부족하여 연결되지 않았습니다. (서버 에러)";
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