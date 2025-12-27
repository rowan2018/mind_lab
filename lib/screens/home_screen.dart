import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rowan_mind_lab/l10n/app_localizations.dart';
import 'package:rowan_mind_lab/controller/home_controller.dart';
import 'package:rowan_mind_lab/routers/routers.dart';
import 'package:rowan_mind_lab/screens/mirror_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // 광고 패키지
import 'dart:io';

// 광고 로딩을 위해 StatefulWidget으로 변경
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // GetView를 뺐으므로 controller 직접 찾기
  final HomeController controller = Get.find<HomeController>();

  static const Color bgBase = Color(0xFFFFFCFC);
  static const Color mainPoint = Color(0xFFFF9EAA);
  static const Color subPoint = Color(0xFFFFF0F1);
  static const Color textDark = Color(0xFF5D4037);
  static const Color borderLine = Color(0xFFFFCDD2);

  // ================= 광고 변수 (보상형) =================
  RewardedAd? _rewardedAd;
  bool _isRewardedLoaded = false;

  // ⚠️ [중요] 실제 보상형 광고 ID로 교체하세요!
  final String rewardedId = Platform.isAndroid
      ? 'ca-app-pub-9790456886445737/1793891334'
      : 'ca-app-pub-9790456886445737/6552212239';

  @override
  void initState() {
    super.initState();

    if (_rewardedAd == null) {
      _loadRewardedAd();
    }
  }
  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  // 보상형 광고 로드
  // ✅ 보상형 광고 로드 (완성본)
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }

          setState(() {
            _rewardedAd = ad;
            _isRewardedLoaded = true;
          });

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();

              if (mounted) {
                setState(() {
                  _rewardedAd = null;
                  _isRewardedLoaded = false;
                });
              }

              _loadRewardedAd(); // ✅ 리필
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();

              if (mounted) {
                setState(() {
                  _rewardedAd = null;
                  _isRewardedLoaded = false;
                });
              }

              _loadRewardedAd(); // ✅ 리필
            },
          );
        },
        onAdFailedToLoad: (err) {
          print('메인 보상형광고 실패: ${err.message}');
          if (mounted) {
            setState(() {
              _rewardedAd = null;
              _isRewardedLoaded = false;
            });
          }
        },
      ),
    );
  }


  // 보상형 광고 보여주기
  // ✅ 보상형 광고 show (완성본)
  void showRewarded() {
    final l10n = AppLocalizations.of(context)!;

    // ✅ 혹시라도 다이얼로그 외에 호출될 경우 방어
    if (!controller.canRewardNow()) return;

    if (_isRewardedLoaded && _rewardedAd != null) {
      setState(() => _isRewardedLoaded = false); // 잠금

      // ✅ show는 1회성이라 미리 null 처리
      final ad = _rewardedAd!;
      _rewardedAd = null;

      ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          controller.completeReward(); // ✅ 횟수/시간 기록
          controller.addApple(5); // ✅ 사과 지급

          Get.snackbar(
            l10n.adRewardTitle,
            l10n.adRewardMsg,
            backgroundColor: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        },
      );
    } else {
      Get.snackbar(
        l10n.adLoadingTitle,
        l10n.adLoadingMsg,
        backgroundColor: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      // ✅ 혹시 로드가 끊겼으면 다시 로드 시도
      _loadRewardedAd();
    }
  }


  // ================= UI 시작 =================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: bgBase,
      appBar: AppBar(
        backgroundColor: bgBase,
        elevation: 0,
        title: Text(
          l10n.appTitle,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: mainPoint,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined,
                color: textDark.withOpacity(0.5), size: 24.sp),
            onPressed: () {
              _showSettingBottomSheet(context);
            },
          ),
          SizedBox(width: 10.w),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: mainPoint));
        }
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 10.h),

              // TODAY 섹션
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text("TODAY",
                      style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: mainPoint)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      l10n.homeDailyTitle,
                      style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _buildDailyCard(),

              SizedBox(height: 20.h),

              // 🔥 [추가] 시크릿 선물 버튼 (명언 아래에 배치)
              _buildSecretGiftButton(l10n),

              SizedBox(height: 30.h),

              // SECRET 섹션
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text("SECRET",
                      style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6A00FF))),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      l10n.secretTitle,
                      style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _buildMirrorCard(l10n),

              SizedBox(height: 30.h),

              // TEST 섹션
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text("TEST",
                      style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: mainPoint)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      l10n.homeTestTitle,
                      style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: controller.testList.length,
                separatorBuilder: (_, __) => SizedBox(height: 16.h),
                itemBuilder: (context, index) {
                  final test = controller.testList[index];
                  return _buildTestItem(test, l10n);
                },
              ),
              SizedBox(height: 50.h),
            ],
          ),
        );
      }),
      bottomNavigationBar: Container(
        height: 40.h,
        color: Colors.white,
        alignment: Alignment.center,
        child: Text(" ",
            style: TextStyle(color: Colors.grey[300], fontSize: 12.sp)),
      ),
    );
  }

  // 🔥 [추가] 시크릿 선물 버튼 위젯
  Widget _buildSecretGiftButton(AppLocalizations l10n) {
    return Obx(() {
      return GestureDetector(
        onTap: () {
          Get.find<HomeController>().showRewardDialog(
            context,
            l10n,
            onConfirm: showRewarded,
          );
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFE0E0E0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: const BoxDecoration(
                  color: subPoint,
                  shape: BoxShape.circle,
                ),
                child: Text("🎁", style: TextStyle(fontSize: 22.sp)),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.rewardDialogTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      Get.find<HomeController>().canRewardNow()
                          ? "선택 시 광고가 재생됩니다"
                          : "잠시 후 다시 받을 수 있어요",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_circle_fill_rounded,
                  color: mainPoint, size: 30.sp),
            ],
          ),
        ),
      );
    });

  }

  Widget _buildMirrorCard(AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        Get.to(() => const MirrorScreen());
      },
      child: Container(
        height: 120.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E1A47), Color(0xFF6A00FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A00FF).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10.w,
              bottom: -10.h,
              child: Icon(
                Icons.auto_awesome,
                size: 100.sp,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: Row(
                children: [
                  Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38),
                    ),
                    child: const Icon(Icons.auto_fix_high, color: Colors.white),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.secretTitle,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          l10n.secretDesc,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.white70,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(1, 2),
                          )
                        ]),
                    child: Row(
                      children: [
                        Text(
                          l10n.btnEnter,
                          style: TextStyle(
                            color: const Color(0xFF2E1A47),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(Icons.arrow_forward_rounded,
                            size: 14.sp, color: const Color(0xFF2E1A47)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyCard() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: borderLine, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: mainPoint.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.format_quote_rounded,
              size: 36.sp, color: mainPoint.withOpacity(0.3)),
          SizedBox(height: 12.h),
          Text(
            controller.todayQuote.value.content,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              height: 1.6,
              color: textDark,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: subPoint,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              "- ${controller.todayQuote.value.author} -",
              style: TextStyle(
                fontSize: 13.sp,
                color: mainPoint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestItem(test, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(Routes.TEST, arguments: test);
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: borderLine.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 68.w,
              height: 68.w,
              decoration: BoxDecoration(
                color: subPoint,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Image.network(
                  test.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.broken_image_rounded,
                        color: Colors.grey, size: 30.sp);
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2));
                  },
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    test.description,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: textDark.withOpacity(0.6),
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: mainPoint.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                l10n.btnGo,
                style: TextStyle(
                  color: mainPoint,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingBottomSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settingsTitle,
              style: TextStyle(
                  fontSize: 20.sp, fontWeight: FontWeight.bold, color: textDark),
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsPushTitle,
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: textDark),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      l10n.settingsPushDesc,
                      style: TextStyle(
                          fontSize: 12.sp, color: textDark.withOpacity(0.5)),
                    ),
                  ],
                ),
                StatefulBuilder(
                  builder: (context, setState) {
                    bool isSwitched = true;
                    return Switch(
                      value: isSwitched,
                      activeColor: mainPoint,
                      onChanged: (value) async {
                        setState(() {
                          isSwitched = value;
                        });
                        if (value) {
                          Get.snackbar(
                              l10n.settingsPushTitle, l10n.settingsAlarmOn,
                              snackPosition: SnackPosition.BOTTOM,
                              margin: EdgeInsets.all(20.w));
                        } else {
                          Get.snackbar(
                              l10n.settingsPushTitle, l10n.settingsAlarmOff,
                              snackPosition: SnackPosition.BOTTOM,
                              margin: EdgeInsets.all(20.w));
                        }
                      },
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 30.h),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                String version = snapshot.data?.version ?? '...';
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: bgBase,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    "${l10n.settingsVersion}: $version",
                    style: TextStyle(
                        color: textDark.withOpacity(0.6), fontSize: 13.sp),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }
}