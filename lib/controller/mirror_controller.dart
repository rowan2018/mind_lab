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
import 'package:rowan_mind_lab/controller/home_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:rowan_mind_lab/service/mirror_ui_event.dart';

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
  final uiEvent = Rxn<MirrorUiEvent>();

  void _emit(MirrorUiEvent e) => uiEvent.value = e;

  Future<void> captureAndShare() async {
    try {
      RenderRepaintBoundary? boundary = captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        _emit(const MirrorUiEvent(MirrorEventType.captureAreaNotFound));
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
      _emit(const MirrorUiEvent(MirrorEventType.shareFailed));
    }
    String _hashText(String s) {
      final bytes = utf8.encode(s);
      return sha1.convert(bytes).toString();
    }

    String _todayKey() {
      final now = DateTime.now();
      return "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    }

    Future<void> _rewardAppleForShareIfEligible() async {
      final text = answerText.value.trim();
      if (text.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();

      // ✅ 설정값 (원하는대로 조정)
      const int rewardApple = 1;   // 공유 보상: +2 (너가 말한 “2개”)
      const int dailyLimit = 3;    // 하루 최대 1번만 (무한 방지 강력)
      // const int dailyLimit = 3; // 좀 느슨하게 하고 싶으면 3

      final dayKey = _todayKey();
      final dailyCountKey = "mirror_share_reward_count_$dayKey";
      final dailyCount = prefs.getInt(dailyCountKey) ?? 0;

      // 오늘 한도 초과면 지급 안 함
      if (dailyCount >= dailyLimit) return;

      // 같은 답변으로 중복 지급 방지
      final answerHash = _hashText(text);
      final rewardedAnswerKey = "mirror_share_rewarded_$answerHash";
      if (prefs.getBool(rewardedAnswerKey) == true) return;

      // ✅ 지급
      homeController.appleCount.value += rewardApple;
      await prefs.setBool(rewardedAnswerKey, true);
      await prefs.setInt(dailyCountKey, dailyCount + 1);

      _emit(MirrorUiEvent(
        MirrorEventType.shareRewarded,
        rewardApple: rewardApple,
        todayCount: dailyCount + 1,
        dailyLimit: dailyLimit,
      ));
    }
    await _rewardAppleForShareIfEligible();
  }

  void askMirror() async {
    String question = textController.text.trim();
    if (question.isEmpty) return;

    // 🍎 [수정] homeController.appleCount 사용
    if (homeController.appleCount.value < costPerQuestion) {
      _emit(MirrorUiEvent(
        MirrorEventType.notEnoughApples,
        costPerQuestion: costPerQuestion,
        currentApple: homeController.appleCount.value,
      ));
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
        _emit(const MirrorUiEvent(MirrorEventType.serverError));
      }

    } catch (e) {
      _emit(const MirrorUiEvent(MirrorEventType.networkError));
    } finally {
      isLoading.value = false;
      textController.clear();
    }
  }
}