import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 💾 저장소 추가
import 'package:rowan_mind_lab/l10n/app_localizations.dart';
import 'package:rowan_mind_lab/data/models.dart';
import 'package:rowan_mind_lab/routers/routers.dart';
import 'package:rowan_mind_lab/controller/home_controller.dart';

class ResultController extends GetxController {
  final ScreenshotController screenshotController = ScreenshotController();

  late TestResult result;
  bool hasResultRewardGiven = false;

  @override
  void onInit() {
    super.onInit();

    // [중요] 다국어 객체 가져오기 (Context가 유효할 때)
    final loc = AppLocalizations.of(Get.context!)!;

    if (Get.arguments != null && Get.arguments is TestResult) {
      result = Get.arguments as TestResult;
    } else {
      result = TestResult(
        minScore: 0,
        maxScore: 0,
        resultTitleKo: loc.errorTitle,
        resultTitleEn: "Error",
        resultTitleJp: "エラー",
        resultDescKo: loc.errorLoadData,
        resultDescEn: "Failed to load result.",
        resultDescJp: "結果を読み込めませんでした。",
        imgUrl: "",
      );
    }

    // 결과 화면 진입 보상 (혹시 필요하면 사용)
    _giveResultReward();
  }

  void _giveResultReward() {
    if (hasResultRewardGiven) return;
    if (Get.isRegistered<HomeController>()) {
      // 단순 진입 보상은 일단 패스 (필요하면 addApple 추가)
      hasResultRewardGiven = true;
    }
  }

  // 🎁 [수정 1] 공유 보상 로직 (하루 3회 제한 + 사과 지급)
  Future<void> _giveShareReward() async {
    final loc = AppLocalizations.of(Get.context!)!;
    final prefs = await SharedPreferences.getInstance();

    // 오늘 날짜 키 생성 (예: 2023-12-28)
    final todayKey = DateTime.now().toString().substring(0, 10);
    final countKey = "share_reward_count_$todayKey";

    // 현재 횟수 가져오기
    int currentCount = prefs.getInt(countKey) ?? 0;

    // 🛑 하루 3회 넘었으면 중단
    if (currentCount >= 3) return;

    // 🍎 사과 지급
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().addApple(2); // 사과 2개 추가

      // 횟수 저장
      await prefs.setInt(countKey, currentCount + 1);

      // 보상 알림
      Get.snackbar(
          loc.shareRewardTitle,   // "공유 보상"
          loc.shareRewardMessage, // "사과를 획득했어요!"
          backgroundColor: Colors.white,
          snackPosition: SnackPosition.BOTTOM
      );
    }
  }

  void goHome() {
    Get.offAllNamed(Routes.HOME);
  }

  Future<void> shareResultImage() async {
    final loc = AppLocalizations.of(Get.context!)!;

    try {
      final Uint8List? imageBytes = await screenshotController.capture();
      if (imageBytes == null) return;

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/result_share.png').create();
      await imagePath.writeAsBytes(imageBytes);

      // 🔗 [수정 2] 다운로드 링크 추가
      String appLink = Platform.isAndroid
          ? "https://play.google.com/store/apps/details?id=com.rowan.mindlab"
          : "https://apps.apple.com/app/id6739346543";

      await Share.shareXFiles(
          [XFile(imagePath.path)],
          // 멘트 + 줄바꿈 + 링크 조합
          text: "${loc.shareViralText}\n\n$appLink"
      );

      // 공유 끝나면 보상 지급 체크
      await _giveShareReward();

    } catch (e) {
      print("Share Error: $e");
      Get.snackbar(
          loc.errorTitle,
          loc.shareErrorMessage,
          backgroundColor: Colors.white
      );
    }
  }
}