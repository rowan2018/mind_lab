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
  // 💾 내부 저장소 (앱 꺼져도 기억함)
  final GetStorage _box = GetStorage();

  // 저장 키 (Key)
  static const _kApple = 'appleCount';
  static const _kGenieFree = 'genieFreeRemain';
  static const _kGeniePaid = 'geniePaidRemain';
  static const _kGenieAdUsed = 'genieAdUsedToday';
  static const _kDayKey = 'genieDayKey'; // "2023-12-25" 같은 날짜 문자열
  static const _kRewardCount = 'todayRewardCount';
  static const _kLastRewardMs = 'lastRewardTimeMs';

  // ---- UI 상태 ----
  final isLoading = false.obs;
  final todayQuote = DailyQuote(
    contentKo: "로딩 중...", contentEn: "Loading...", contentJp: "読み込み中...",
    authorKo: "", authorEn: "", authorJp: "",
  ).obs;
  final primaryTest = Rxn<TestItem>();
  final testList = <TestItem>[].obs;

  // ---- 🍎 사과 & 🧞‍♂️ 지니 상태 (관찰 가능한 변수) ----
  final appleCount = 20.obs;

  // [지니 정책] 하루 무료 3회 + (광고 후) 추가 2회
  final genieFreeRemain = 3.obs;
  final geniePaidRemain = 0.obs;
  final genieAdUsedToday = false.obs;

  // 전체 남은 횟수 (UI 표시용)
  int get genieTotalRemain => genieFreeRemain.value + geniePaidRemain.value;

  // 상태 체크
  bool get canUseGenieFree => genieFreeRemain.value > 0;
  bool get canUseGeniePaid => geniePaidRemain.value > 0;

  // ---- 🎁 홈 보상 (사과 획득용) ----
  final RxInt todayRewardCount = 0.obs;
  final Rx<DateTime?> lastRewardTime = Rx<DateTime?>(null);

  final List<Worker> _workers = [];

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    // 1. 저장된 데이터 불러오기
    _loadFromStorage();
    // 2. 날짜 바꼈으면 리셋
    _resetIfNewDay();
    // 3. 변할 때마다 자동 저장 설정
    _bindAutoSave();

    loadData();
  }

  @override
  void onClose() {
    for (final w in _workers) w.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  // -------------------- 날짜 & 저장 로직 --------------------
  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  }

  void _loadFromStorage() {
    appleCount.value = _box.read(_kApple) ?? 20; // 없으면 기본 20개
    genieFreeRemain.value = _box.read(_kGenieFree) ?? 3; // 기본 3회
    geniePaidRemain.value = _box.read(_kGeniePaid) ?? 0;
    genieAdUsedToday.value = _box.read(_kGenieAdUsed) ?? false;

    todayRewardCount.value = _box.read(_kRewardCount) ?? 0;
    final ms = _box.read(_kLastRewardMs);
    if (ms is int) lastRewardTime.value = DateTime.fromMillisecondsSinceEpoch(ms);
  }

  void _saveToStorage() {
    _box.write(_kApple, appleCount.value);
    _box.write(_kGenieFree, genieFreeRemain.value);
    _box.write(_kGeniePaid, geniePaidRemain.value);
    _box.write(_kGenieAdUsed, genieAdUsedToday.value);
    _box.write(_kRewardCount, todayRewardCount.value);
    _box.write(_kLastRewardMs, lastRewardTime.value?.millisecondsSinceEpoch);

    // 날짜 키도 같이 저장 (오늘 날짜로 갱신)
    if (_box.read(_kDayKey) == null) {
      _box.write(_kDayKey, _todayKey());
    }
  }

  // 📅 [핵심] 날짜 변경 체크 및 리셋
  void _resetIfNewDay() {
    final savedDay = _box.read(_kDayKey);
    final today = _todayKey();

    // 저장된 날짜가 없거나, 오늘과 다르면 리셋!
    if (savedDay != today) {
      print("📅 날짜 변경 감지! 데이터 리셋: $savedDay -> $today");

      genieFreeRemain.value = 3;      // 무료 3회 충전
      geniePaidRemain.value = 0;      // 유료 슬롯 잠금
      genieAdUsedToday.value = false; // 광고 기회 부활

      todayRewardCount.value = 0;     // 보상 횟수 초기화
      lastRewardTime.value = null;    // 쿨타임 초기화

      _box.write(_kDayKey, today);    // 오늘 날짜로 도장 쾅!
      _saveToStorage();
    }
  }

  void _bindAutoSave() {
    // 값이 변하면 무조건 저장소에 씀 (앱 꺼져도 안전함)
    _workers.add(ever(appleCount, (_) => _saveToStorage()));
    _workers.add(ever(genieFreeRemain, (_) => _saveToStorage()));
    _workers.add(ever(geniePaidRemain, (_) => _saveToStorage()));
    _workers.add(ever(genieAdUsedToday, (_) => _saveToStorage()));
    _workers.add(ever(todayRewardCount, (_) => _saveToStorage()));
    _workers.add(ever(lastRewardTime, (_) => _saveToStorage()));
  }

  // -------------------- 🍎 사과 관리 --------------------
  void addApple(int delta) => appleCount.value += delta;

  // -------------------- 🧞‍♂️ 지니 소비 로직 --------------------

  // 1. 무료 사용
  void useGenieFree() {
    if (genieFreeRemain.value > 0) genieFreeRemain.value--;
  }
  // 1-1. 무료 복구 (통신 에러 시)
  void restoreGenieFree() {
    if (genieFreeRemain.value < 3) genieFreeRemain.value++;
  }

  // 2. 유료 사용 (사과 1개 소모)
  bool useGeniePaid() {
    if (geniePaidRemain.value > 0) {
      if (appleCount.value >= 1) {
        appleCount.value--;      // 🍎 -1
        geniePaidRemain.value--; // 🎫 -1
        return true; // 성공
      }
    }
    return false; // 실패 (사과 부족 등)
  }
  // 2-1. 유료 복구 (통신 에러 시 사과도 돌려줌)
  void restoreGeniePaid() {
    if (geniePaidRemain.value < 2) {
      geniePaidRemain.value++;
      appleCount.value++; // 🍎 +1 환불
    }
  }

  // 3. 광고 보고 유료 슬롯 해금 (하루 1번)
  void unlockGeniePaidSlots() {
    if (genieAdUsedToday.value) return;
    geniePaidRemain.value = 2;     // 슬롯 2개 부여
    genieAdUsedToday.value = true; // 오늘 광고 봄 처리
  }

  // -------------------- 🎁 홈 보상 로직 --------------------
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
    if (todayRewardCount.value >= 3) return const RewardStatus(state: RewardState.dailyLimit);
    if (lastRewardTime.value == null) return RewardStatus(state: RewardState.available, nextIndex: todayRewardCount.value + 1);

    final diff = DateTime.now().difference(lastRewardTime.value!).inMinutes;
    if (diff < 120) return RewardStatus(state: RewardState.cooldown, remainingMinutes: 120 - diff);

    return RewardStatus(state: RewardState.available, nextIndex: todayRewardCount.value + 1);
  }

  void showRewardDialog(BuildContext context, AppLocalizations l10n, {required VoidCallback onConfirm}) {
    Get.dialog(
      AlertDialog(
        title: Text(l10n.rewardDialogTitle),
        content: Obx(() {
          final s = getRewardStatus();
          switch (s.state) {
            case RewardState.dailyLimit: return Text(l10n.rewardDailyLimit);
            case RewardState.cooldown: return Text(l10n.rewardCooldown(s.remainingMinutes));
            case RewardState.available: return Text(l10n.rewardNth(s.nextIndex));
          }
        }),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text(l10n.commonClose)),
          Obx(() => ElevatedButton(
            onPressed: canRewardNow() ? () { Get.back(); onConfirm(); } : null,
            child: Text(l10n.rewardConfirmButton),
          )),
        ],
      ),
    );
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      final quotes = await ApiService.fetchQuotes();
      if (quotes.isNotEmpty) todayQuote.value = quotes[Random().nextInt(quotes.length)];

      final allTests = await ApiService.fetchTests();
      // 1. 🔥 isPrimary가 true인 테스트 찾기 (상단 고정용)
      primaryTest.value = allTests.firstWhereOrNull((t) => t.isPrimary == true);

      // 2. 나머지 테스트 리스트 구성 (주력 테스트는 제외)
      final otherTests = allTests.where((t) => t.id != primaryTest.value?.id).toList();
      const maxDisplay = 19;
      final newTests = allTests.where((t) => (t.status ?? "").toUpperCase() == "NEW").toList()..shuffle();
      final oldTests = allTests.where((t) => (t.status ?? "").toUpperCase() != "NEW").toList()..shuffle();

      final display = [...newTests.take(maxDisplay)];
      if (display.length < maxDisplay) display.addAll(oldTests.take(maxDisplay - display.length));

      testList.assignAll(display..shuffle());

    } catch (e) {
      print("데이터 로딩 에러: $e");
      testList.clear();
      primaryTest.value = null;
    } finally {
      isLoading.value = false;
    }
  }
}