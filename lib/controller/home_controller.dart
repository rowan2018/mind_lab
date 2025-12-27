import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:rowan_mind_lab/data/models.dart';
import 'package:rowan_mind_lab/service/api_service.dart';
import 'package:rowan_mind_lab/l10n/app_localizations.dart';

enum RewardState { available, cooldown, dailyLimit }

class RewardStatus {
  final RewardState state;
  final int nextIndex; // 1~3
  final int remainingMinutes; // cooldown

  const RewardStatus({
    required this.state,
    this.nextIndex = 1,
    this.remainingMinutes = 0,
  });
}

class HomeController extends GetxController with WidgetsBindingObserver {
  // ---- GetStorage ----
  final GetStorage _box = GetStorage();

  // 저장 키
  static const _kApple = 'appleCount';
  static const _kGenieFree = 'genieFreeRemain';
  static const _kGeniePaid = 'geniePaidRemain';
  static const _kGenieAdUsed = 'genieAdUsedToday';
  static const _kDayKey = 'genieDayKey'; // yyyy-MM-dd

  // (선택) 보상 관련도 저장하고 싶으면 사용
  static const _kRewardCount = 'todayRewardCount';
  static const _kLastRewardMs = 'lastRewardTimeMs';

  // ---- UI 상태 ----
  final isLoading = false.obs;

  // 오늘의 문구/테스트 리스트
  final todayQuote = DailyQuote(
    contentKo: "로딩 중...",
    contentEn: "Loading...",
    contentJp: "読み込み中...",
    authorKo: "",
    authorEn: "",
    authorJp: "",
  ).obs;

  final testList = <TestItem>[].obs;

  // ---- 자원(🍎/지니) 상태 ----
  final appleCount = 20.obs;

  final genieFreeRemain = 3.obs;       // 하루 무료 3회
  final geniePaidRemain = 0.obs;       // 광고로 열린 2회
  final genieAdUsedToday = false.obs;  // 하루 1회 광고 사용 여부

  int get genieTotalRemain => genieFreeRemain.value + geniePaidRemain.value;
  bool get canUseGenieFree => genieFreeRemain.value > 0;
  bool get canUseGeniePaid => geniePaidRemain.value > 0;

  // ---- 보상 정책 (하루 3회, 2시간 쿨타임) ----
  final RxInt todayRewardCount = 0.obs;
  final Rx<DateTime?> lastRewardTime = Rx<DateTime?>(null);

  final List<Worker> _workers = [];

  @override
  void onInit() {
    super.onInit();

    WidgetsBinding.instance.addObserver(this);

    _loadFromStorage();
    _resetIfNewDay();     // 날짜 바뀌면 무료/광고/보상 리셋
    _bindAutoSave();

    loadData();
  }

  @override
  void onClose() {
    for (final w in _workers) {
      w.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    // 언어 바뀌면 데이터 다시 로드
    Future.delayed(const Duration(milliseconds: 300), () {
      loadData();
    });
  }

  // -------------------- Date Key --------------------
  String _todayKey() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  // -------------------- Storage Load/Save --------------------
  void _loadFromStorage() {
    appleCount.value = _box.read(_kApple) ?? 20;

    genieFreeRemain.value = _box.read(_kGenieFree) ?? 3;
    geniePaidRemain.value = _box.read(_kGeniePaid) ?? 0;
    genieAdUsedToday.value = _box.read(_kGenieAdUsed) ?? false;

    todayRewardCount.value = _box.read(_kRewardCount) ?? 0;
    final ms = _box.read(_kLastRewardMs);
    if (ms is int) {
      lastRewardTime.value = DateTime.fromMillisecondsSinceEpoch(ms);
    }
  }

  void _saveToStorage() {
    _box.write(_kApple, appleCount.value);
    _box.write(_kGenieFree, genieFreeRemain.value);
    _box.write(_kGeniePaid, geniePaidRemain.value);
    _box.write(_kGenieAdUsed, genieAdUsedToday.value);

    _box.write(_kRewardCount, todayRewardCount.value);
    _box.write(_kLastRewardMs, lastRewardTime.value?.millisecondsSinceEpoch);

    _box.write(_kDayKey, _todayKey());
  }

  void _resetIfNewDay() {
    final savedDay = _box.read(_kDayKey);
    final today = _todayKey();

    if (savedDay != today) {
      // ✅ “하루 정책” 리셋
      genieFreeRemain.value = 3;
      geniePaidRemain.value = 0;
      genieAdUsedToday.value = false;

      todayRewardCount.value = 0;
      lastRewardTime.value = null;

      _box.write(_kDayKey, today);
      _saveToStorage();
    }
  }

  void _bindAutoSave() {
    _workers.add(ever<int>(appleCount, (_) => _saveToStorage()));
    _workers.add(ever<int>(genieFreeRemain, (_) => _saveToStorage()));
    _workers.add(ever<int>(geniePaidRemain, (_) => _saveToStorage()));
    _workers.add(ever<bool>(genieAdUsedToday, (_) => _saveToStorage()));
    _workers.add(ever<int>(todayRewardCount, (_) => _saveToStorage()));
    _workers.add(ever<DateTime?>(lastRewardTime, (_) => _saveToStorage()));
  }

  // -------------------- Genie/Apple 정책 --------------------
  void addApple(int delta) {
    appleCount.value += delta;
  }

  void consumeGenieFree() {
    if (genieFreeRemain.value > 0) genieFreeRemain.value--;
  }

  void consumeGeniePaid() {
    if (geniePaidRemain.value > 0) geniePaidRemain.value--;
  }

  void unlockGeniePaid2() {
    if (genieAdUsedToday.value) return; // 하루 1회 제한
    geniePaidRemain.value = 2;
    genieAdUsedToday.value = true;
  }

  // -------------------- Reward 정책 --------------------
  bool canRewardNow() {
    if (todayRewardCount.value >= 3) return false;
    if (lastRewardTime.value == null) return true;
    return DateTime.now().difference(lastRewardTime.value!).inMinutes >= 120;
  }

  void completeReward() {
    todayRewardCount.value++;
    lastRewardTime.value = DateTime.now();
  }

  RewardStatus getRewardStatus() {
    if (todayRewardCount.value >= 3) {
      return const RewardStatus(state: RewardState.dailyLimit);
    }

    if (lastRewardTime.value == null) {
      return RewardStatus(
        state: RewardState.available,
        nextIndex: todayRewardCount.value + 1,
      );
    }

    final diff = DateTime.now().difference(lastRewardTime.value!).inMinutes;
    if (diff < 120) {
      return RewardStatus(
        state: RewardState.cooldown,
        remainingMinutes: 120 - diff,
      );
    }

    return RewardStatus(
      state: RewardState.available,
      nextIndex: todayRewardCount.value + 1,
    );
  }

  void showRewardDialog(
      BuildContext context,
      AppLocalizations l10n, {
        required VoidCallback onConfirm,
      }) {
    Get.dialog(
      AlertDialog(
        title: Text(l10n.rewardDialogTitle),
        content: Obx(() {
          final s = getRewardStatus();
          switch (s.state) {
            case RewardState.dailyLimit:
              return Text(l10n.rewardDailyLimit);
            case RewardState.cooldown:
              return Text(l10n.rewardCooldown(s.remainingMinutes));
            case RewardState.available:
              return Text(l10n.rewardNth(s.nextIndex));
          }
        }),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(l10n.commonClose),
          ),
          Obx(
                () => ElevatedButton(
              onPressed: canRewardNow()
                  ? () {
                Get.back();
                onConfirm();
              }
                  : null,
              child: Text(l10n.rewardConfirmButton),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- API Load --------------------
  Future<void> loadData() async {
    isLoading.value = true;
    try {
      final quotes = await ApiService.fetchQuotes();
      if (quotes.isNotEmpty) {
        todayQuote.value = quotes[Random().nextInt(quotes.length)];
      } else {
        todayQuote.value = DailyQuote(
          contentKo: "오늘의 영감을 충전 중...",
          contentEn: "Charging inspiration...",
          contentJp: "インスピレーションを充電中...",
          authorKo: "System",
          authorEn: "System",
          authorJp: "System",
        );
      }

      final allTests = await ApiService.fetchTests();
      const int maxDisplayCount = 10;

      final newTests =
      allTests.where((t) => (t.status ?? "").toUpperCase() == "NEW").toList();
      final oldTests =
      allTests.where((t) => (t.status ?? "").toUpperCase() != "NEW").toList();

      newTests.shuffle();
      oldTests.shuffle();

      final List<TestItem> finalDisplayList = [];
      finalDisplayList.addAll(newTests.take(maxDisplayCount));

      final remainingSlots = maxDisplayCount - finalDisplayList.length;
      if (remainingSlots > 0) {
        finalDisplayList.addAll(oldTests.take(remainingSlots));
      }

      finalDisplayList.shuffle();
      testList.assignAll(finalDisplayList);
    } catch (e) {
      testList.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
