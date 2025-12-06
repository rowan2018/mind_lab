import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

// 👇 절대 경로 import
import 'package:rowan_mind_lab/data/models.dart';
import 'package:rowan_mind_lab/controller/mirror_controller.dart'; // 사과 창고 연결

class ResultController extends GetxController {
  late TestResult result;

  // 📸 화면 캡쳐를 위한 컨트롤러 (ResultScreen에서 씀)
  final ScreenshotController screenshotController = ScreenshotController();

  // 🚫 중복 보상 방지용 (한 번 받으면 true로 바뀜)
  var hasReceivedReward = false;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      result = Get.arguments as TestResult;
    } else {
      Get.offAllNamed('/');
      // Get.snackbar("오류", "데이터 없음"); // (필요 시 주석 해제)
    }
  }

  // 홈으로 가기
  void goHome() {
    Get.offAllNamed('/');
  }

  // ⭐ 이미지 캡쳐 후 공유 (+ 보상 지급)
  Future<void> shareResultImage() async {
    try {
      // 1. 화면 캡쳐
      final Uint8List? imageBytes = await screenshotController.capture();

      if (imageBytes != null) {
        // 2. 파일로 저장
        final directory = await getTemporaryDirectory();
        final imagePath = File('${directory.path}/result_image.png');
        await imagePath.writeAsBytes(imageBytes);

        // 3. 공유창 띄우기
        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: '[마음쉼표] 심리테스트 결과 "${result.resultTitle}"\n나도 하러가기 👉 http://www.rowanzone.co.kr/mind',
        );

        // 4. 공유창 닫고 돌아왔을 때 보상 지급!
        _giveReward();
      }
    } catch (e) {
      print("공유 실패: $e");
      Get.snackbar("알림", "이미지 공유 중 오류가 발생했습니다.");
    }
  }

  // 🎁 보상 지급 로직 (사과 2개)
  void _giveReward() {
    // 이미 받았으면 중단
    if (hasReceivedReward) return;

    // 거울 컨트롤러가 메모리에 있는지 확인
    if (Get.isRegistered<MirrorController>()) {
      final mirrorController = Get.find<MirrorController>();

      // 🍎 사과 2개 추가!
      mirrorController.appleCount.value += 2;

      // 중복 방지 체크
      hasReceivedReward = true;

      // 축하 알림
      Get.snackbar(
        "보상 지급 완료! 🍎",
        "공유 보상으로 황금 사과 2개를 얻었습니다!\n(거울 상담소 1회 무료 이용 가능)",
        backgroundColor: Colors.white.withOpacity(0.9),
        icon: const Icon(Icons.auto_awesome, color: Colors.amber),
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
      );
    }
  }
}