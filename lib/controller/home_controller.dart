import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models.dart';
import '../service/api_service.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  var isLoading = true.obs;

  // 🍎 [핵심 수정] 사과 개수를 여기서 관리 (앱 켜져있는 동안 유지됨)
  var appleCount = 20.obs;
  void addApple(int count) {
    // 만약 변수명이 appleCount라면:
    appleCount.value += count;

    // 혹시 변수명이 userApple 이라면:
    // userApple.value += count;

    update(); // 화면 갱신 (GetX 사용 시 상황에 따라 필요)
  }

  var todayQuote = DailyQuote(
      contentKo: "로딩 중...",
      contentEn: "Loading...",
      contentJp: "読み込み中...",
      authorKo: "",
      authorEn: "",
      authorJp: ""
  ).obs;
  var testList = <TestItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    loadData();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);
    Future.delayed(const Duration(milliseconds: 500), () {
      print("언어 변경 감지! 데이터 새로고침 중...");
      loadData();
    });
  }

  void loadData() async {
    isLoading.value = true;
    try {
      var quotes = await ApiService.fetchQuotes();
      if (quotes.isNotEmpty) {
        todayQuote.value = quotes[Random().nextInt(quotes.length)];
      } else {
        todayQuote.value = DailyQuote(
            contentKo: "오늘의 영감을 충전 중...",
            contentEn: "Charging inspiration...",
            contentJp: "インスピレーションを充電中...",
            authorKo: "System",
            authorEn: "System",
            authorJp: "System"
        );
      }

      var allTests = await ApiService.fetchTests();
      const int maxDisplayCount = 10;

      var newTests = allTests.where((t) => (t.status ?? "").toUpperCase() == "NEW").toList();
      var oldTests = allTests.where((t) => (t.status ?? "").toUpperCase() != "NEW").toList();

      newTests.shuffle();
      oldTests.shuffle();

      List<TestItem> finalDisplayList = [];
      finalDisplayList.addAll(newTests.take(maxDisplayCount));

      int remainingSlots = maxDisplayCount - finalDisplayList.length;
      if (remainingSlots > 0) {
        finalDisplayList.addAll(oldTests.take(remainingSlots));
      }

      finalDisplayList.shuffle();
      testList.assignAll(finalDisplayList);

    } catch (e) {
      print("데이터 로딩 중 에러 발생: $e");
      testList.clear();
    } finally {
      isLoading.value = false;
    }
  }
}