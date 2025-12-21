import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rowan_mind_lab/l10n/app_localizations.dart';// [필수] 다국어 임포트

import 'package:rowan_mind_lab/data/models.dart';
import 'package:rowan_mind_lab/routers/routers.dart';
import 'package:rowan_mind_lab/controller/home_controller.dart';

class ResultController extends GetxController {
  final ScreenshotController screenshotController = ScreenshotController();

  late TestResult result;

  bool hasResultRewardGiven = false;
  bool hasShareRewardGiven = false;

  @override
  void onInit() {
    super.onInit();

    // [중요] 다국어 객체 가져오기 (Context가 유효할 때)
    final loc = AppLocalizations.of(Get.context!)!;

    if (Get.arguments != null && Get.arguments is TestResult) {
      result = Get.arguments as TestResult;
    } else {
      // [수정] 한글 하드코딩 제거 -> loc 변수 사용
      result = TestResult(
        minScore: 0,
        maxScore: 0,
        resultTitleKo: loc.errorTitle, // "결과 오류" 대체
        resultTitleEn: "Error",        // 영어는 그대로 둠
        resultTitleJp: "エラー",         // 일본어는 그대로 둠
        resultDescKo: loc.errorLoadData, // "데이터 못 불러옴" 대체
        resultDescEn: "Failed to load result.",
        resultDescJp: "結果を読み込めませんでした。",
        imgUrl: "",
      );
    }

    // 결과 화면 진입 보상
    _giveResultReward();
  }

  // 🎁 1. 결과 확인 보상
  void _giveResultReward() {
    if (hasResultRewardGiven) return;

    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      homeController.addApple(2);
      hasResultRewardGiven = true;
    }
  }

  // 🎁 2. 공유 보상
  void _giveShareReward() {
    if (hasShareRewardGiven) return;

    // [중요] 다국어 객체 가져오기
    final loc = AppLocalizations.of(Get.context!)!;

    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      homeController.addApple(2);
      hasShareRewardGiven = true;

      // [수정] 스낵바 한글 제거
      Get.snackbar(
          loc.shareRewardTitle,   // "공유 보상"
          loc.shareRewardMessage, // "사과 2개 획득..."
          backgroundColor: Colors.white,
          snackPosition: SnackPosition.BOTTOM
      );
    }
  }

  void goHome() {
    Get.offAllNamed(Routes.HOME);
  }

  Future<void> shareResultImage() async {
    // [중요] 다국어 객체 가져오기
    final loc = AppLocalizations.of(Get.context!)!;

    try {
      final Uint8List? imageBytes = await screenshotController.capture();
      if (imageBytes == null) return;

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/result_share.png').create();
      await imagePath.writeAsBytes(imageBytes);

      // [수정] 공유 멘트 한글 제거
      await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: loc.shareViralText // "소름 돋아!..." 멘트
      );

      _giveShareReward();

    } catch (e) {
      print("Share Error: $e");
      // [수정] 에러 메시지 한글 제거
      Get.snackbar(
          loc.errorTitle,     // "오류"
          loc.shareErrorMessage, // "공유 실패..."
          backgroundColor: Colors.white
      );
    }
  }
}