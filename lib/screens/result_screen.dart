import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:screenshot/screenshot.dart';
import 'package:rowan_mind_lab/controller/result_controller.dart';
import 'package:rowan_mind_lab/l10n/app_localizations.dart'; // import 필수
import 'package:rowan_mind_lab/controller/mirror_controller.dart';

class ResultScreen extends GetView<ResultController> {
  const ResultScreen({super.key});

  static const Color bgBase = Color(0xFFFFFCFC);
  static const Color mainPoint = Color(0xFFFF9EAA);
  static const Color subPoint = Color(0xFFFFF0F1);
  static const Color textDark = Color(0xFF5D4037);
  static const Color borderLine = Color(0xFFFFCDD2);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // l10n 생성

    return Scaffold(
      backgroundColor: bgBase,
      appBar: AppBar(
        title: Text(l10n.resultPageTitle, // "테스트 결과"
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textDark)),
        backgroundColor: bgBase,
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            children: [
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

                      // 이미지 영역
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
                                    color: mainPoint,
                                    strokeWidth: 3
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[100],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_rounded, size: 40.sp, color: Colors.grey[400]),
                                  SizedBox(height: 8.h),
                                  Text(l10n.errorImage, // "이미지 없음"
                                      style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                                ],
                              ),
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      SizedBox(height: 24.h),
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
                      Text("- Rowan Mind Lab -", style: TextStyle(color: mainPoint, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30.h),
              _buildSecretGiftButton(l10n), // l10n 전달

              SizedBox(height: 20.h),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.shareResultImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD54F),
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
                          Text(l10n.btnShareReward, // "공유하고 🍎받기"
                              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.goHome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainPoint,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        elevation: 0,
                      ),
                      child: Text(l10n.btnRetry, // "다른 테스트 하기"
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
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

  Widget _buildSecretGiftButton(AppLocalizations l10n) {
    final mirrorController = Get.put(MirrorController());

    if (!mirrorController.isAdEnabled) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        // "알림", "곧 광고 기능이..."
        Get.snackbar(l10n.alertTitle, l10n.adUpdateMsg, backgroundColor: Colors.white);
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
                  Text(l10n.adTitle, // "신비한 몰약이..."
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: textDark)),
                  SizedBox(height: 2.h),
                  Text(l10n.adDesc, // "광고 보고..."
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
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