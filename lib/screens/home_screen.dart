import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rowan_mind_lab/l10n/app_localizations.dart';
import 'package:rowan_mind_lab/controller/home_controller.dart';
import 'package:rowan_mind_lab/routers/routers.dart';
// 👇 거울 화면 import 추가!
import 'package:rowan_mind_lab/screens/mirror_screen.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  // 테마 컬러 (기존 유지)
  static const Color bgBase = Color(0xFFFFFCFC);
  static const Color mainPoint = Color(0xFFFF9EAA);
  static const Color subPoint = Color(0xFFFFF0F1);
  static const Color textDark = Color(0xFF5D4037);
  static const Color borderLine = Color(0xFFFFCDD2);

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

              // ✨ NEW: 신비한 거울 상담소 섹션 ✨
              Row(
                children: [
                  Text("SECRET", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: const Color(0xFF6A00FF))), // 보라색 포인트
                  SizedBox(width: 8.w),
                  Text("신비한 거울 상담소", // (나중에 다국어 적용 필요)
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textDark),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _buildMirrorCard(), // 거울 버튼 추가!

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
      // 배너 광고 영역 (기존 유지)
      bottomNavigationBar: Container(
        height: 60.h,
        color: Colors.white,
        alignment: Alignment.center,
        child: Text("AdMob Banner Area", style: TextStyle(color: Colors.grey[300], fontSize: 12.sp)),
      ),
    );
  }

  // ✨ NEW: 거울 상담소 바로가기 카드 디자인
  Widget _buildMirrorCard() {
    return GestureDetector(
      onTap: () {
        // 거울 화면으로 이동!
        Get.to(() => const MirrorScreen());
      },
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          // 신비로운 어두운 보라빛 배경
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF311B92)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A00FF).withOpacity(0.4), // 보라색 그림자
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // 거울 아이콘 (반짝이는 느낌)
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.8), width: 2),
              ),
              child: Icon(Icons.auto_awesome_rounded, color: Colors.purpleAccent, size: 32.sp),
            ),
            SizedBox(width: 20.w),

            // 텍스트 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "고민이 있나요?",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    "마법 거울에게 속삭여 보세요.\n지혜로운 답을 줄 거예요.",
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // 화살표 아이콘
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.1),
              child: Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16.sp),
            ),
          ],
        ),
      ),
    );
  }

  // 💌 엽서 느낌 + 핑크 테두리
  Widget _buildDailyCard() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r), // 더 둥글게
        border: Border.all(color: borderLine, width: 1.5), // 요청하신 테두리 추가!
        boxShadow: [
          BoxShadow(
            color: mainPoint.withOpacity(0.15), // 그림자도 핑크빛으로 은은하게
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // 따옴표 아이콘
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
                color: mainPoint, // 작가 이름 포인트 컬러
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎀 리스트 아이템
  Widget _buildTestItem(test, l10n) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(Routes.TEST, arguments: test);
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: borderLine.withOpacity(0.5)), // 연한 테두리
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03), // 리스트는 깔끔하게 회색 그림자
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // 썸네일 영역
            Container(
              width: 68.w,
              height: 68.w,
              decoration: BoxDecoration(
                color: subPoint, // 연한 핑크 배경
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Icon(Icons.favorite_rounded, color: mainPoint, size: 32.sp),
                // 나중에 이미지 넣을 때: Image.network(...)
              ),
            ),
            SizedBox(width: 16.w),

            // 텍스트 영역
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

            // GO 버튼 (알약 모양)
            Container(
              margin: EdgeInsets.only(left: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: mainPoint.withOpacity(0.1), // 배경은 연하게
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                l10n.btnGo,
                style: TextStyle(
                  color: mainPoint, // 글자는 진하게
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