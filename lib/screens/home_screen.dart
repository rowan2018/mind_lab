import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rowan_mind_lab/l10n/app_localizations.dart';
import 'package:rowan_mind_lab/controller/home_controller.dart';
import 'package:rowan_mind_lab/routers/routers.dart';
import 'package:rowan_mind_lab/screens/mirror_screen.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  static const Color bgBase = Color(0xFFFFFCFC);
  static const Color mainPoint = Color(0xFFFF9EAA);
  static const Color subPoint = Color(0xFFFFF0F1);
  static const Color textDark = Color(0xFF5D4037);
  static const Color borderLine = Color(0xFFFFCDD2);

  @override
  Widget build(BuildContext context) {
    // 1. 다국어 객체 가져오기
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
            icon: Icon(Icons.settings_outlined, color: textDark.withOpacity(0.5), size: 24.sp),
            onPressed: () {},
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

              // TODAY 섹션
              Row(
                children: [
                  Text("TODAY", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: mainPoint)),
                  SizedBox(width: 8.w),
                  Text(l10n.homeDailyTitle,
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textDark),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _buildDailyCard(),

              SizedBox(height: 30.h),

              // SECRET 섹션
              Row(
                children: [
                  Text("SECRET", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: const Color(0xFF6A00FF))),
                  SizedBox(width: 8.w),
                  Text(l10n.secretTitle, // "신비한 거울 상담소" -> 변수 교체
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textDark),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _buildMirrorCard(l10n), // l10n 전달

              SizedBox(height: 30.h),

              // TEST 섹션
              Row(
                children: [
                  Text("TEST", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: mainPoint)),
                  SizedBox(width: 8.w),
                  Text(l10n.homeTestTitle,
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textDark),
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
        height: 60.h,
        color: Colors.white,
        alignment: Alignment.center,
        child: Text("AdMob Banner Area", style: TextStyle(color: Colors.grey[300], fontSize: 12.sp)),
      ),
    );
  }

  // ✨ l10n을 인자로 받아서 텍스트 처리
  Widget _buildMirrorCard(AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        Get.to(() => const MirrorScreen());
      },
      child: Container(
        height: 110.h,
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
                          l10n.secretTitle, // "신비한 거울 상담소"
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          l10n.secretDesc, // "지니에게 속삭여보세요"
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(1, 2),
                          )
                        ]
                    ),
                    child: Row(
                      children: [
                        Text(
                          l10n.btnEnter, // "입장"
                          style: TextStyle(
                            color: const Color(0xFF2E1A47),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(Icons.arrow_forward_rounded, size: 14.sp, color: const Color(0xFF2E1A47)),
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
          Icon(Icons.format_quote_rounded, size: 36.sp, color: mainPoint.withOpacity(0.3)),
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
                    return Icon(Icons.broken_image_rounded, color: Colors.grey, size: 30.sp);
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
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
                    maxLines: 1,
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
                    maxLines: 2,
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
}