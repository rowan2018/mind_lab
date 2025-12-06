import 'dart:math';
import 'package:flutter/material.dart'; // WidgetsBindingObserver 때문에 필요
import 'package:get/get.dart';
import '../data/models.dart';
import '../service/api_service.dart';

// with WidgetsBindingObserver 추가! (감시자 역할)
class HomeController extends GetxController with WidgetsBindingObserver {
  var isLoading = true.obs;
  var todayQuote = DailyQuote(content: "로딩 중...", author: "").obs;
  var testList = <TestItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    // 1. 감시자 등록 (앱 상태 변화 감지 시작)
    WidgetsBinding.instance.addObserver(this);
    loadData();
  }

  @override
  void onClose() {
    // 2. 감시자 해제 (메모리 누수 방지)
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  // ⭐ 3. 시스템 설정(언어 등)이 바뀌면 이 함수가 자동으로 실행됨!
  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);
    // 언어가 바뀌었으니 데이터를 다시 가져오라고 명령!
    // (약간의 딜레이를 줘서 Get.deviceLocale이 갱신될 시간을 줌)
    Future.delayed(const Duration(milliseconds: 500), () {
      print("언어 변경 감지! 데이터 새로고침 중...");
      loadData();
    });
  }

  void loadData() async {
    isLoading.value = true;

    // 명언 로드
    var quotes = await ApiService.fetchQuotes();
    if (quotes.isNotEmpty) {
      todayQuote.value = quotes[Random().nextInt(quotes.length)];
    } else {
      todayQuote.value = DailyQuote(
          content: "Failed to load data.",
          author: "Error"
      );
    }

    // 테스트 리스트 로드
    var tests = await ApiService.fetchTests();
    testList.assignAll(tests);

    isLoading.value = false;
  }
}