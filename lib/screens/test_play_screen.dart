import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// 👇 절대 경로 & 다국어 import
import 'package:rowan_mind_lab/controller/test_play_controller.dart';
import 'package:rowan_mind_lab/data/models.dart';
import 'package:rowan_mind_lab/l10n/app_localizations.dart';

class TestPlayScreen extends GetView<TestPlayController> {
  const TestPlayScreen({super.key});

  // ✨ 메인 화면과 통일된 컬러 팔레트
  static const Color bgBase = Color(0xFFFFFCFC);       // 배경
  static const Color mainPoint = Color(0xFFFF9EAA);    // 메인 핑크
  static const Color subPoint = Color(0xFFFFF0F1);     // 연한 핑크
  static const Color textDark = Color(0xFF5D4037);     // 진한 브라운
  static const Color borderLine = Color(0xFFFFCDD2);   // 테두리

  @override
  Widget build(BuildContext context) {
    // 다국어 (필요시 버튼 텍스트 등에 사용)
    // final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: bgBase,
      appBar: AppBar(
        backgroundColor: bgBase,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20.sp),
          onPressed: () => Get.back(),
        ),
        // 상단에 조그맣게 테스트 제목 표시
        title: Text(
          controller.testItem.title,
          style: TextStyle(fontSize: 14.sp, color: textDark.withOpacity(0.6), fontWeight: FontWeight.normal),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 10.h),

              // ✨ 1. 예쁜 진행률 표시바 (핑크색)
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

              SizedBox(height: 40.h),

              // ✨ 2. 질문 텍스트 영역 (카드 형태)
              Expanded(
                flex: 2,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(24.w),
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
                        height: 1.5,
                        color: textDark,
                        fontFamily: 'Pretendard',
                      ),
                      textAlign: TextAlign.center,
                    )),
                  ),
                ),
              ),

              SizedBox(height: 30.h),

              // ✨ 3. 선택지 버튼 목록
              Expanded(
                flex: 3,
                child: Obx(() => ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.currentQuestion.options.length,
                  separatorBuilder: (_, __) => SizedBox(height: 16.h),
                  itemBuilder: (context, index) {
                    final option = controller.currentQuestion.options[index];
                    return _buildOptionButton(option);
                  },
                )),
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  // 🎀 선택지 버튼 디자인
  Widget _buildOptionButton(Option option) {
    return GestureDetector(
      onTap: () {
        controller.selectOption(option.score);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: mainPoint.withOpacity(0.3), width: 1.5), // 연한 핑크 테두리
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              offset: const Offset(0, 4),
              blurRadius: 10,
            )
          ],
        ),
        child: Row(
          children: [
            // 체크 아이콘
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}