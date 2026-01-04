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

  // 🍎 HomeController 연결
  HomeController get homeController => Get.find<HomeController>();

  var isLoading = false.obs;
  var answerText = "".obs;

  final int costPerQuestion = 2;
  final uiEvent = Rxn<MirrorUiEvent>();

  void _emit(MirrorUiEvent e) => uiEvent.value = e;

  // 🔥 [수정 1] 들어올 때마다 상태 초기화 (서지연님 피드백 반영)
  @override
  void onInit() {
    super.onInit();
    resetState();
  }

  void resetState() {
    answerText.value = "";
    textController.clear();
    isLoading.value = false;
  }

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

      // 공유 실행
      await Share.shareXFiles(
        [XFile(imgFile.path)],
        text: "[지니의 램프] 내 욕망을 꿰뚫어 본 지니의 답변...🔮\n#지니의램프 #팩폭 #소원",
      );

      // 공유 성공 시 보상 지급 로직 실행
      await _rewardAppleForShareIfEligible();

    } catch (e) {
      _emit(const MirrorUiEvent(MirrorEventType.shareFailed));
    }
  }

  // 내부 헬퍼 함수들 (보기 좋게 밖으로 뺌)
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
    const int rewardApple = 1;
    const int dailyLimit = 3;

    final dayKey = _todayKey();
    final dailyCountKey = "mirror_share_reward_count_$dayKey";
    final dailyCount = prefs.getInt(dailyCountKey) ?? 0;

    if (dailyCount >= dailyLimit) return;

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

  void askMirror() async {
    String question = textController.text.trim();
    if (question.isEmpty) return;

    // 사과 부족 체크
    if (homeController.appleCount.value < costPerQuestion) {
      _emit(MirrorUiEvent(
        MirrorEventType.notEnoughApples,
        costPerQuestion: costPerQuestion,
        currentApple: homeController.appleCount.value,
      ));
      return;
    }

    // 🍎 사과 선차감
    homeController.appleCount.value -= costPerQuestion;

    isLoading.value = true;
    answerText.value = "";
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      // ⚠️ 실제 사용중인 서버 주소인지 확인 필수
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
        // 🔥 [수정 2] 서버 에러 시 사과 환불
        homeController.appleCount.value += costPerQuestion;
        _emit(const MirrorUiEvent(MirrorEventType.serverError));
      }

    } catch (e) {
      // 🔥 [수정 2] 네트워크 에러 시 사과 환불
      homeController.appleCount.value += costPerQuestion;
      _emit(const MirrorUiEvent(MirrorEventType.networkError));
    } finally {
      isLoading.value = false;
      textController.clear();
    }
  }
}