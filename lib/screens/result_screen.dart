import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:screenshot/screenshot.dart';
// 👇 절대 경로 import
import 'package:rowan_mind_lab/controller/result_controller.dart';
import 'package:rowan_mind_lab/l10n/app_localizations.dart';
import 'package:rowan_mind_lab/controller/mirror_controller.dart';

class ResultScreen extends GetView<ResultController> {
  const ResultScreen({super.key});

  // ✨ 메인 화면과 통일된 감성 컬러 팔레트
  static const Color bgBase = Color(0xFFFFFCFC);       // 배경
  static const Color mainPoint = Color(0xFFFF9EAA);    // 메인 핑크
  static const Color subPoint = Color(0xFFFFF0F1);     // 연한 핑크
  static const Color textDark = Color(0xFF5D4037);     // 진한 브라운
  static const Color borderLine = Color(0xFFFFCDD2);   // 테두리

  @override
  Widget build(BuildContext context) {
    // 다국어 적용 (필요시 l10n.btnShare 등으로 교체)
    // final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: bgBase,
      appBar: AppBar(
        title: Text("테스트 결과", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textDark)),
        backgroundColor: bgBase,
        centerTitle: true,
        automaticallyImplyLeading: false, // 뒤로가기 숨김 (홈 버튼 유도)
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            children: [
              // 📸 1. 캡쳐 영역 (결과 카드)
              Screenshot(
                controller: controller.screenshotController,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: borderLine, width: 2), // 핑크 테두리
                    boxShadow: [
                      BoxShadow(
                        color: mainPoint.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(24.w), // 내부 여백 넉넉하게
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
                        width: 180.w,
                        height: 180.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          color: subPoint, // 이미지가 없을 때도 예쁜 핑크 배경
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.r),
                          child: CachedNetworkImage(
                            imageUrl: controller.result.imgUrl ?? "",
                            placeholder: (context, url) => Center(child: CircularProgressIndicator(color: mainPoint)),
                            errorWidget: (context, url, error) => Icon(Icons.image_not_supported_rounded, size: 50.sp, color: mainPoint.withOpacity(0.5)),
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

                      SizedBox(height: 20.h),

                      // 하단 로고 (홍보용)
                      Text("- Rowan Mind Lab -", style: TextStyle(color: mainPoint, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30.h),

              // 🎁 2. 광고/보상 버튼 (사과 & 몰약 패키지)
              // 나중에 심사 때는 이 위젯 전체를 if(false)로 감싸서 숨기면 됩니다.
              _buildSecretGiftButton(),

              SizedBox(height: 20.h),

              // 🔘 3. 하단 버튼 (공유 / 홈)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.shareResultImage, // 공유하고 사과받기 연결됨
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD54F), // 공유는 눈에 띄는 노란색 (카톡 느낌)
                        foregroundColor: textDark,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share_rounded, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text("공유하고 🍎받기", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.goHome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainPoint, // 홈 버튼은 메인 핑크
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        elevation: 0,
                      ),
                      child: Text("다른 테스트 하기", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  // 🍎 몰약 & 사과 패키지 버튼 (광고 보기 유도)
  // 🍎 몰약 & 사과 패키지 버튼
  Widget _buildSecretGiftButton() {
    // 1. 거울 컨트롤러를 찾아서 스위치 상태를 확인합니다.
    // (만약 메모리에 없으면 생성해서라도 확인)
    final mirrorController = Get.put(MirrorController());

    // 2. 심사 중(false)이면 아예 빈 공간을 리턴 -> 화면에서 사라짐!
    if (!mirrorController.isAdEnabled) {
      return const SizedBox.shrink();
    }

    // 3. 심사 통과 후(true)에는 버튼이 보임
    return GestureDetector(
      onTap: () {
        // TODO: 광고 보여주기 연결
        // AdController.to.showRewardAd();
        Get.snackbar("알림", "곧 광고 기능이 업데이트됩니다!", backgroundColor: Colors.white);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
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
              child: Text("🏺", style: TextStyle(fontSize: 22.sp)),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("신비한 몰약이 필요하신가요?", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: textDark)),
                  SizedBox(height: 2.h),
                  Text("광고 보고 사과&몰약 세트 받기", style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.play_circle_fill_rounded, color: mainPoint, size: 30.sp),
          ],
        ),
      ),
    );
  }
}