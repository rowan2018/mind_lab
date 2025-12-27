import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rowan_mind_lab/controller/test_play_controller.dart';
import 'package:rowan_mind_lab/data/models.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // 광고 패키지
import 'dart:io'; // 플랫폼 확인용

// GetView 대신 StatefulWidget으로 변경 (광고 상태 관리)
class TestPlayScreen extends StatefulWidget {
  const TestPlayScreen({super.key});

  @override
  State<TestPlayScreen> createState() => _TestPlayScreenState();
}

class _TestPlayScreenState extends State<TestPlayScreen> {
  // GetView를 뺐으므로 controller를 직접 찾습니다.
  final TestPlayController controller = Get.find<TestPlayController>();

  static const Color bgBase = Color(0xFFFFFCFC);
  static const Color mainPoint = Color(0xFFFF9EAA);
  static const Color subPoint = Color(0xFFFFF0F1);
  static const Color textDark = Color(0xFF5D4037);
  static const Color borderLine = Color(0xFFFFCDD2);

  // ================= 광고 변수 =================
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  // ⚠️ [중요] 여기에 아까 메모장에 적은 '진짜 전면광고 ID'를 넣으세요!
  // 지금은 테스트 ID입니다.
  final String interstitialId = Platform.isAndroid
      ? 'ca-app-pub-9790456886445737/4752045409' // 개발자님의 안드로이드 실제 전면광고 ID
      : 'ca-app-pub-9790456886445737/3110185897';

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd(); // 들어오자마자 광고 장전!
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }

          _interstitialAd = ad;
          _isAdLoaded = true;

          // 콜백은 로드시 한 번만 세팅해두는 게 안전
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitialAd(); // 다음번 대비 재장전
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _loadInterstitialAd(); // 실패해도 재장전
            },
          );

          setState(() {});
        },
        onAdFailedToLoad: (err) {
          if (!mounted) return;
          _isAdLoaded = false;
          _interstitialAd = null;
          // 너무 시끄러우면 print 줄이기
          debugPrint('전면광고 로드 실패: ${err.message}');
          setState(() {});
        },
      ),
    );
  }

  void _onOptionSelected(int score) {
    controller.selectOption(score);

    // 광고는 여기서 절대 show() 하지 않음.
    // (원하면 로드만 유지해서 ResultScreen에서 쓰거나,
    //  그냥 ResultScreen에서 따로 로드해도 됨)
  }


  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBase,
      appBar: AppBar(
        backgroundColor: bgBase,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textDark, size: 20.sp),
          onPressed: () => Get.back(),
        ),
        title: Text(
          controller.testItem.title,
          style: TextStyle(
              fontSize: 14.sp,
              color: textDark.withOpacity(0.6),
              fontWeight: FontWeight.normal),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
          child: Column(
            children: [
              // 진행률 표시바
              Obx(() => Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: LinearProgressIndicator(
                      value: controller.progress,
                      backgroundColor: subPoint,
                      color: mainPoint,
                      minHeight: 12.h,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    "${controller.currentQuestionIndex.value + 1} / ${controller.testItem.questions.length}",
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: mainPoint,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              )),

              SizedBox(height: 30.h),

              // 질문 텍스트 박스
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 24.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: borderLine.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: mainPoint.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Obx(() => Text(
                  controller.currentQuestion.text,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    color: textDark,
                    fontFamily: 'Pretendard',
                  ),
                  textAlign: TextAlign.center,
                )),
              ),

              SizedBox(height: 30.h),

              // 선택지 버튼 목록
              Obx(() => ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: controller.currentQuestion.options.length,
                separatorBuilder: (_, __) => SizedBox(height: 16.h),
                itemBuilder: (context, index) {
                  final option = controller.currentQuestion.options[index];
                  return _buildOptionButton(option);
                },
              )),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(Option option) {
    return GestureDetector(
      // [수정] 기존 controller.selectOption 대신 _onOptionSelected 사용
      onTap: () {
        _onOptionSelected(option.score);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: mainPoint.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              offset: const Offset(0, 4),
              blurRadius: 10,
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 12.r,
              backgroundColor: subPoint,
              child: Icon(Icons.check_rounded, color: mainPoint, size: 16.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                option.text,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: textDark,
                  height: 1.2,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}