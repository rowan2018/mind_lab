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
import 'package:rowan_mind_lab/data/models.dart';

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
          return const Center(child: CircularProgressIndicator(color: mainPoint));
        }
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 10.h),
              _buildDailyCard(), // 오늘의 명언

              SizedBox(height: 28.h), // 명언과 테스트 사이 여백
                // 🔥 주력 테스트가 로드되었다면 크게 보여주기
              Row(
                children: [
                  Text("TEST", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: mainPoint)),
                  SizedBox(width: 8.w),
                  Expanded(child: Text(l10n.homeTestTitle, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textDark))),
                ],
              ),
              SizedBox(height: 10.h),
              Obx(() {
                if (controller.primaryTest.value != null) {
                  return Column(
                    children: [
                      _buildPrimaryTestItem(controller.primaryTest.value!, l10n),
                      SizedBox(height: 20.h),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
              // 1. TEST 섹션 (최상단 유지)

              SizedBox(height: 0.h),
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: controller.testList.length,
                separatorBuilder: (_, __) => SizedBox(height: 16.h),
                itemBuilder: (context, index) {
                  return _buildTestItem(controller.testList[index], l10n);
                },
              ),

              SizedBox(height: 10.h), // 테스트와 상담소 사이 여백

              // 2. SECRET 섹션 (지니 상담소)
              Row(
                children: [
                  Text("SECRET", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: const Color(0xFF6A00FF))),
                  SizedBox(width: 8.w),
                  Expanded(child: Text(l10n.secretTitle, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textDark))),
                ],
              ),
              SizedBox(height: 16.h),
              _buildMirrorCard(l10n), // 상담소 카드

              SizedBox(height: 40.h), // 상담소와 광고 배너 사이 여백

              // 3. 🔥 광고 배너 (최하단 배치)
              _buildSecretGiftButton(l10n),

              SizedBox(height: 60.h), // 맨 밑 여유 공간
            ],
          ),
        );
      }),
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
                      controller.canRewardNow()
                          ? l10n.bonusAdPlaysOnSelect
                          : l10n.bonusComeBackLater,
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
      onTap: () { Get.to(() => const MirrorScreen()); },
      child: Container(
        height: 96.h, // 기존 120.h에서 80%인 96.h로 축소
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E1A47), Color(0xFF6A00FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r), // 높이에 맞춰 라운드 소폭 조정
          boxShadow: [
            BoxShadow(color: const Color(0xFF6A00FF).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -5.w,
              bottom: -5.h,
              child: Icon(Icons.auto_awesome, size: 70.sp, color: Colors.white.withOpacity(0.1)), // 아이콘 크기 조정
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w), // 상하 패딩은 제거하여 중앙 정렬 유도
              child: Row(
                children: [
                  Container(
                    width: 42.w, // 아이콘 영역 소폭 축소
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38),
                    ),
                    child: Icon(Icons.auto_fix_high, color: Colors.white, size: 20.sp),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
                      children: [
                        Text(l10n.secretTitle, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 2.h),
                        Text(l10n.secretDesc, style: TextStyle(fontSize: 12.sp, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  // 입장 버튼 사이즈도 높이에 맞춰 컴팩트하게 조정
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(color: const Color(0xFFFFD700), borderRadius: BorderRadius.circular(18.r)),
                    child: Icon(Icons.arrow_forward_rounded, size: 16.sp, color: const Color(0xFF2E1A47)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 [높이 50% 축소] 명언 카드
  Widget _buildDailyCard() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w), // 상하 패딩 대폭 축소
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r), // 라운드 값 조정
        border: Border.all(color: borderLine, width: 1.2),
        boxShadow: [
          BoxShadow(color: mainPoint.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // 따옴표 아이콘 크기 축소
          Icon(Icons.format_quote_rounded, size: 24.sp, color: mainPoint.withOpacity(0.3)),
          SizedBox(height: 8.h),
          Text(
            controller.todayQuote.value.content,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, height: 1.4, color: textDark),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Text(
            "- ${controller.todayQuote.value.author} -",
            style: TextStyle(fontSize: 11.sp, color: mainPoint, fontWeight: FontWeight.w600),
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
  // 🔥 주력 테스트를 크게 보여주는 위젯 함수 추가
  Widget _buildPrimaryTestItem(TestItem test, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.TEST, arguments: test),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h), // 10.h 여백 적용
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: Color(0xFFFFCDD2), width: 1.5), // borderLine 색상
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 썸네일 크게 (상단 라운드 처리)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
              child: Image.network(
                test.thumbnailUrl,
                height: 120.h, // 2배 정도 키운 높이
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.title,
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                  ),
                  SizedBox(height: 8.h),
                  // 설명문 전체 노출 (maxLines 제한 없음)
                  Text(
                    test.description,
                    style: TextStyle(fontSize: 14.sp, color: Color(0xFF5D4037).withOpacity(0.7), height: 1.4),
                  ),
                ],
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