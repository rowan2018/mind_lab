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

  // lib/controller/home_controller.dart 내부의 loadData() 함수

  void loadData() async {
    isLoading.value = true;

    try {
      // 1. 명언 로드
      var quotes = await ApiService.fetchQuotes();
      if (quotes.isNotEmpty) {
        todayQuote.value = quotes[Random().nextInt(quotes.length)];
      } else {
        todayQuote.value = DailyQuote(content: "오늘의 영감을 충전 중...", author: "System");
      }

      // 2. 전체 테스트 리스트 로드
      var allTests = await ApiService.fetchTests();

      // ============================================================
      // 🎲 [핵심 로직] NEW 보장 + 랜덤 섞기 알고리즘
      // ============================================================

      // 설정: 화면에 보여줄 최대 개수 (나중에 이 숫자만 8로 바꾸면 8개 나옴)
      const int maxDisplayCount = 5;

      // 1. 'NEW'인 것과 '일반(OLD)'인 것 분리하기
      // (status가 null일 수도 있으니 안전하게 처리)
      var newTests = allTests.where((t) => (t.status ?? "").toUpperCase() == "NEW").toList();
      var oldTests = allTests.where((t) => (t.status ?? "").toUpperCase() != "NEW").toList();

      // 2. 각각 섞기 (NEW가 여러 개일 때 매번 순서 바뀌게)
      newTests.shuffle();
      oldTests.shuffle();

      // 3. 리스트 합치기 (그릇 만들기)
      List<TestItem> finalDisplayList = [];

      // 3-1. NEW는 무조건 다 넣기 (단, 우리가 정한 5개를 넘치면 안 됨)
      finalDisplayList.addAll(newTests.take(maxDisplayCount));

      // 3-2. 자리가 남았다면 OLD로 채우기
      int remainingSlots = maxDisplayCount - finalDisplayList.length;
      if (remainingSlots > 0) {
        // 남은 자리만큼 일반 테스트에서 가져와 채움
        finalDisplayList.addAll(oldTests.take(remainingSlots));
      }

      // 4. 마지막으로 전체 섞기
      // (이걸 안 하면 NEW가 무조건 1,2,3등으로 고정되니까 재미없음)
      finalDisplayList.shuffle();

      // 5. 결과 적용
      testList.assignAll(finalDisplayList);

      print("총 로딩된 테스트: ${allTests.length}개 -> 화면 표시: ${finalDisplayList.length}개 (NEW 포함)");

    } catch (e) {
      print("데이터 로딩 중 에러 발생: $e");
      testList.clear();
    } finally {
      isLoading.value = false;
    }
  }

}