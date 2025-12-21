import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rowan_mind_lab/controller/home_controller.dart'; // import 추가

class MirrorController extends GetxController {
  final TextEditingController textController = TextEditingController();
  final GlobalKey captureKey = GlobalKey();

  // 🍎 [핵심 수정] 내 변수가 아니라 HomeController의 변수를 빌려옴
  // 이제 화면이 꺼져도 이 값은 HomeController에 안전하게 살아있음
  HomeController get homeController => Get.find<HomeController>();

  var isLoading = false.obs;
  var answerText = "".obs;

  final int costPerQuestion = 2;
  final bool isAdEnabled = false;

  Future<void> captureAndShare() async {
    try {
      RenderRepaintBoundary? boundary = captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        print("캡처 영역을 찾을 수 없습니다.");
        return;
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return;
      Uint8List pngBytes = byteData.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final File imgFile = File('${directory.path}/genie_mirror_result.png');
      await imgFile.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(imgFile.path)],
        text: "[지니의 램프] 내 욕망을 꿰뚫어 본 지니의 답변...🔮\n#지니의램프 #팩폭 #소원",
      );

    } catch (e) {
      print("캡처 에러 발생: $e");
      Get.snackbar("오류", "이미지 공유 중 문제가 발생했습니다.", backgroundColor: Colors.white);
    }
  }

  void askMirror() async {
    String question = textController.text.trim();
    if (question.isEmpty) return;

    // 🍎 [수정] homeController.appleCount 사용
    if (homeController.appleCount.value < costPerQuestion) {
      Get.dialog(
        AlertDialog(
          title: const Text("🍎 사과가 부족해요"),
          content: Obx(() => Text("신비한 거울에게 질문하려면\n황금 사과 $costPerQuestion개가 필요합니다.\n(현재: ${homeController.appleCount.value}개)")),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("취소"),
            ),
            if (isAdEnabled)
              ElevatedButton(
                onPressed: () {
                  Get.back();
                },
                child: const Text("광고 보고 충전"),
              ),
          ],
        ),
      );
      return;
    }

    // 🍎 [수정] 차감도 homeController에서
    homeController.appleCount.value -= costPerQuestion;

    isLoading.value = true;
    answerText.value = "";
    FocusManager.instance.primaryFocus?.unfocus();

    try {
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