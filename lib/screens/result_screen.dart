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

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final ResultController controller = Get.find<ResultController>();
  final home = Get.find<HomeController>();

  bool _isGenieLoading = false;
  String? _genieOpinion;

  RewardedAd? _genieRewardedAd;
  bool _isGenieRewardedLoaded = false;

  static const Color bgBase = Color(0xFFFFFCFC);
  static const Color mainPoint = Color(0xFFFF9EAA);
  static const Color subPoint = Color(0xFFFFF0F1);
  static const Color textDark = Color(0xFF5D4037);
  static const Color borderLine = Color(0xFFFFCDD2);

  // ---------- 광고 로드 ----------
  void _loadGenieRewardedAd() {
    RewardedAd.load(
      adUnitId: AdUnitIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) { ad.dispose(); return; }
          _genieRewardedAd = ad;
          _isGenieRewardedLoaded = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isGenieRewardedLoaded = false;
              _loadGenieRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
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
      _genieRewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          // ✅ 광고 성공 -> 유료 슬롯 2개 해금
          home.unlockGeniePaidSlots();
          Get.snackbar(
            l10n.genieUnlockAdSuccessTitle,
            l10n.genieUnlockAdSuccessMsg,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.white,
          );
        },
      );
      _genieRewardedAd = null;
      _isGenieRewardedLoaded = false;
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

  // ---------- 🧞‍♂️ 지니 의견 요청 (핵심) ----------
  Future<void> _requestGenieOpinion(AppLocalizations l10n) async {
    if (_isGenieLoading) return;

    // 1. 전체 남은 횟수 없으면 종료 (5회 다 씀)
    if (home.genieTotalRemain <= 0) {
      Get.snackbar(
        l10n.genieOpinionTitle,
        l10n.genieNoRemainMsg,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    bool usedFree = false; // 복구용 메모

    // 2. 소비 로직
    if (home.canUseGenieFree) {
      // ✅ [A] 무료 사용
      home.useGenieFree();
      usedFree = true;
    } else {
      // ✅ [B] 유료 사용
      if (!home.canUseGeniePaid) {
        // 광고 아직 안 봄
        Get.snackbar(
          l10n.genieOpinionTitle,
          l10n.genieUnlockHintMsg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.white,
        );
        return;
      }

      // 사과 차감 시도
      bool success = home.useGeniePaid(); // 내부에서 사과 -1, 횟수 -1
      if (!success) {
        Get.snackbar(
          l10n.notEnoughApplesTitle,
          l10n.notEnoughApplesMsg,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      usedFree = false;
    }

    // 3. API 호출
    setState(() => _isGenieLoading = true);

    try {
      final opinion = await ApiService.sendToGenieResult(
        l10n.genieQuestionPrompt,
        langCode: Localizations.localeOf(context).languageCode,
        title: controller.result.resultTitle,
        desc: controller.result.resultDesc,
      );
      setState(() => _genieOpinion = opinion);

    } catch (e) {
      // 🚨 실패 시 복구 (환불)
      if (usedFree) {
        home.restoreGenieFree();
      } else {
        home.restoreGeniePaid(); // 사과도 +1 됨
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
        title: Text(l10n.resultPageTitle, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textDark)),
        backgroundColor: bgBase,
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Screenshot(
                controller: controller.screenshotController,
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24.r), border: Border.all(color: borderLine, width: 2)),
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    children: [
                      Text(controller.result.resultTitle, style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: textDark)),
                      SizedBox(height: 24.h),
                      Container(width: 200.w, height: 200.w, child: CachedNetworkImage(imageUrl: controller.result.imgUrl ?? "")),
                      SizedBox(height: 24.h),
                      Text(controller.result.resultDesc, style: TextStyle(fontSize: 15.sp, height: 1.6, color: textDark.withOpacity(0.8))),
                      const SizedBox(height: 20),

                      // ✅ [버튼] 지니 의견 듣기 (실시간 반영)
                      Obx(() {
                        String btnText = l10n.genieOpinionBtn;
                        // 유료 상태면 (사과 -1) 표시
                        if (!home.canUseGenieFree && home.canUseGeniePaid) {
                          btnText = "$btnText (🍎 -1)";
                        }

                        return ElevatedButton(
                          onPressed: _isGenieLoading ? null : () => _requestGenieOpinion(l10n),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A00FF),
                            foregroundColor: Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: _isGenieLoading
                                ? Text(l10n.genieOpinionLoading)
                                : Text(btnText),
                          ),
                        );
                      }),

                      if (_genieOpinion != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFF6A00FF), borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.genieOpinionTitle, style: const TextStyle(color: Color(0xFFF8F5FF), fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(_genieOpinion!, style: const TextStyle(color: Colors.white, height: 1.5)),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 10.h),

                      // ✅ [정보] 남은 횟수 표시
                      Obx(() => Text(
                        l10n.genieRemainText(home.genieTotalRemain, home.genieFreeRemain.value),
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                      )),

                      // ✅ [광고 버튼] 무료 다 쓰고 & 추가 기회 잠겨있을 때만 노출
                      Obx(() {
                        final bool needUnlock = !home.canUseGenieFree && !home.canUseGeniePaid;
                        if (needUnlock && !home.genieAdUsedToday.value) {
                          return Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: OutlinedButton.icon(
                              onPressed: _showGenieUnlockAd,
                              icon: const Icon(Icons.play_circle_filled, size: 16),
                              label: Text(l10n.genieUnlockAdBtn),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),

                      SizedBox(height: 20.h),
                      Text("- Rowan Mind Lab -", style: TextStyle(color: mainPoint, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40.h),
              Row(children: [ Expanded(child: ElevatedButton(onPressed: controller.shareResultImage, child: Text(l10n.btnShareReward))), SizedBox(width: 12.w), Expanded(child: ElevatedButton(onPressed: controller.goHome, child: Text(l10n.btnRetry))) ]),
              SizedBox(height: 50.h),
            ],
          ),
        ),
      ),
    );
  }
}