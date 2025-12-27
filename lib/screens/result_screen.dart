import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:screenshot/screenshot.dart';
import 'package:rowan_mind_lab/controller/result_controller.dart';
import 'package:rowan_mind_lab/l10n/app_localizations.dart';
import 'package:rowan_mind_lab/service/api_service.dart';
import 'package:rowan_mind_lab/controller/home_controller.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:rowan_mind_lab/service/ad_unit_ids.dart';


// 광고 패키지 삭제함

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final ResultController controller = Get.find<ResultController>();
  bool _isGenieLoading = false;
  final home = Get.find<HomeController>();
  String? _genieOpinion;
  RewardedAd? _genieRewardedAd;
  bool _isGenieRewardedLoaded = false;
  // 디자인 컬러 상수
  static const Color bgBase = Color(0xFFFFFCFC);
  static const Color mainPoint = Color(0xFFFF9EAA);
  static const Color subPoint = Color(0xFFFFF0F1);
  static const Color textDark = Color(0xFF5D4037);
  static const Color borderLine = Color(0xFFFFCDD2);

  void _loadGenieRewardedAd() {
    RewardedAd.load(
      adUnitId: AdUnitIds.rewarded,
      // ✅ 너가 쓰는 rewardedId 그대로 재사용(테스트/실ID)
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _genieRewardedAd = ad;
          _isGenieRewardedLoaded = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _genieRewardedAd = null;
              _isGenieRewardedLoaded = false;
              _loadGenieRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _genieRewardedAd = null;
              _isGenieRewardedLoaded = false;
              _loadGenieRewardedAd();
            },
          );
          if (mounted) setState(() {});
        },
        onAdFailedToLoad: (err) {
          _isGenieRewardedLoaded = false;
          _genieRewardedAd = null;
          if (mounted) setState(() {});
        },
      ),
    );
  }
  void _showGenieUnlockAd() {
    final l10n = AppLocalizations.of(context)!;

    if (home.genieAdUsedToday.value) return;

    if (_isGenieRewardedLoaded && _genieRewardedAd != null) {
      final ad = _genieRewardedAd!;
      _genieRewardedAd = null;
      _isGenieRewardedLoaded = false;

      ad.show(
        onUserEarnedReward: (ad, reward) {
          // ✅ 광고 보상 성공 → 지니 추가 2회 오픈
          home.unlockGeniePaid2();

          Get.snackbar(
            l10n.genieMagicSuccessTitle,
            l10n.genieMagicSuccessMsg,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.white,
            duration: const Duration(seconds: 2),
          );

        },
      );
    } else {
      Get.snackbar(
        l10n.adLoadingTitle,
        l10n.adLoadingMsg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
      );
      _loadGenieRewardedAd();
    }
  }


  Future<void> _requestGenieOpinion(AppLocalizations l10n) async {
    if (_isGenieLoading) return;


    // ✅ 오늘 남은 횟수(무료 3 + 추가 2) 없으면 종료
    if (home.genieTotalRemain <= 0) {
      Get.snackbar(
        l10n.genieOpinionTitle,
        l10n.genieLimitReachedMsg,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // ✅ 무료 3회 먼저 소모
    if (home.canUseGenieFree) {
      home.consumeGenieFree();
    } else {
      // ✅ 추가 2회가 열려있지 않으면(=광고 아직 안봄)
      if (!home.canUseGeniePaid) {
        Get.snackbar(
          l10n.genieOpinionTitle,
          l10n.genieUnlockHintMsg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.white,
        );

        return;
      }

      // ✅ 추가 2회는 사과 1개 차감
      if (home.appleCount.value < 1) {
        Get.snackbar(
          l10n.notEnoughApplesTitle,
          l10n.notEnoughApplesMsg,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      home.addApple(-1);
      home.consumeGeniePaid();
    }

    setState(() => _isGenieLoading = true);

    try {
      final title = controller.result.resultTitle;
      final desc = controller.result.resultDesc;
      final question = l10n.genieQuestionPrompt;

      final langCode = Localizations.localeOf(context).languageCode;

      final opinion = await ApiService.sendToGenieResult(
        question,
        langCode: langCode,
        title: title,
        desc: desc,
      );

      setState(() => _genieOpinion = opinion);
    } catch (e) {
      // ✅ 실패 복구(간단 복구)
      // 방금 무료를 썼던 상황이면 무료 +1, 아니면 사과 +1 & 추가횟수 +1
      if (home.genieFreeRemain.value < 3) {
        home.genieFreeRemain.value++;
      } else {
        home.addApple(1);
        home.geniePaidRemain.value++;
      }

      Get.snackbar(
        l10n.genieOpinionTitle,
        l10n.genieOpinionError,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _isGenieLoading = false);
    }
  }


  @override
  void initState() {
    super.initState();
    _loadGenieRewardedAd();
  }

  @override
  void dispose() {
    _genieRewardedAd?.dispose();
    super.dispose();
  }




  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: bgBase,
      appBar: AppBar(
        title: Text(l10n.resultPageTitle,
            style: TextStyle(
                fontSize: 18.sp, fontWeight: FontWeight.bold, color: textDark)),
        backgroundColor: bgBase,
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 결과 카드 (스크린샷 찍히는 부분)
              Screenshot(
                controller: controller.screenshotController,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: borderLine, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: mainPoint.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    children: [
                      // 결과 제목
                      Text(
                        controller.result.resultTitle,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24.h),

                      // 결과 이미지
                      Container(
                        width: 200.w,
                        height: 200.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24.r),
                          color: subPoint,
                          boxShadow: [
                            BoxShadow(
                              color: mainPoint.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24.r),
                          child: CachedNetworkImage(
                            imageUrl: controller.result.imgUrl ?? "",
                            placeholder: (context, url) => Container(
                              alignment: Alignment.center,
                              color: subPoint,
                              child: SizedBox(
                                width: 40.w,
                                height: 40.w,
                                child: const CircularProgressIndicator(
                                    color: mainPoint, strokeWidth: 3),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[100],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_rounded,
                                      size: 40.sp, color: Colors.grey[400]),
                                  SizedBox(height: 8.h),
                                  Text(l10n.errorImage,
                                      style: TextStyle(
                                          fontSize: 12.sp, color: Colors.grey)),
                                ],
                              ),
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // 결과 설명
                      Text(
                        controller.result.resultDesc,
                        style: TextStyle(
                          fontSize: 15.sp,
                          height: 1.6,
                          color: textDark.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: _isGenieLoading ? null : () => _requestGenieOpinion(l10n),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A00FF),
                          foregroundColor: Colors.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: _isGenieLoading
                              ? Text(l10n.genieOpinionLoading)
                              : Text(l10n.genieOpinionBtn),
                        ),
                      ),

                      if (_genieOpinion != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6A00FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.genieOpinionTitle,
                                style: const TextStyle(
                                  color: Color(0xFFF8F5FF),
                                  fontWeight: FontWeight.bold,// 살짝 보라빛 화이트
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _genieOpinion!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),

                        ),
                      ],
                      SizedBox(height: 10.h),

// ✅ 오늘 남은 지니 의견 표시 (임시 문구, ARB는 나중에)
                      Obx(() => Text(
                        l10n.genieRemainText(
                          home.genieTotalRemain,
                          home.genieFreeRemain.value,
                        ),
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                      )),


// ✅ 무료 다 쓰고 + 추가 2회가 잠겨있으면 '마법(광고)' 버튼 노출
                      Obx(() {
                        final needUnlock = !home.canUseGenieFree && !home.canUseGeniePaid;
                        final canUnlockByAd = needUnlock && !home.genieAdUsedToday.value;

                        if (!canUnlockByAd) return const SizedBox.shrink();

                        return Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: OutlinedButton(
                            onPressed: _showGenieUnlockAd,
                            child: Text(l10n.genieMagicUnlockBtn),
                          ),

                        );
                      }),
                      SizedBox(height: 20.h),

                      Text("- Rowan Mind Lab -",
                          style: TextStyle(
                              color: mainPoint,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 40.h), // 간격

              // 2. 하단 버튼 2개 (공유하기 / 다른 테스트)
              Row(
                children: [
                  // [공유하기]
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.shareResultImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD54F),
                        foregroundColor: textDark,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share_rounded, size: 20.sp),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(l10n.btnShareReward,
                                  style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // [다른 테스트 하기] (광고 없이 바로 홈으로)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.goHome, // 그냥 바로 이동!
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainPoint,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r)),
                        elevation: 0,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(l10n.btnRetry, // "다른 테스트 하기" or "처음으로"
                            style: TextStyle(
                                fontSize: 14.sp, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 50.h),
            ],
          ),
        ),
      ),
    );
  }
}