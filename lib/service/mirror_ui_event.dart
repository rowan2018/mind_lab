enum MirrorEventType {
  captureAreaNotFound,
  shareFailed,
  shareRewarded,
  notEnoughApples,
  serverError,
  networkError,
}

class MirrorUiEvent {
  final MirrorEventType type;

  // 필요하면 숫자/값 전달 (번역 파라미터용)
  final int? rewardApple;
  final int? todayCount;
  final int? dailyLimit;
  final int? costPerQuestion;
  final int? currentApple;

  const MirrorUiEvent(
      this.type, {
        this.rewardApple,
        this.todayCount,
        this.dailyLimit,
        this.costPerQuestion,
        this.currentApple,
      });
}
