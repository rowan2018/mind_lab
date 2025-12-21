import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rowan_mind_lab/controller/test_play_controller.dart';
import 'package:rowan_mind_lab/data/models.dart';
// import 'package:rowan_mind_lab/l10n/app_localizations.dart'; // 필요시 주석 해제

class TestPlayScreen extends GetView<TestPlayController> {
  const TestPlayScreen({super.key});

  static const Color bgBase = Color(0xFFFFFCFC);
  static const Color mainPoint = Color(0xFFFF9EAA);
  static const Color subPoint = Color(0xFFFFF0F1);
  static const Color textDark = Color(0xFF5D4037);
  static const Color borderLine = Color(0xFFFFCDD2);

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          controller.testItem.title,
          style: TextStyle(fontSize: 14.sp, color: textDark.withOpacity(0.6), fontWeight: FontWeight.normal),
        ),
      ),
      body: SafeArea(
        // 🔥 [수정 1] 화면이 작아도 무조건 스크롤 되도록 SingleChildScrollView 적용
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

              SizedBox(height: 30.h), // 간격 조금 줄임 (작은 화면 대응)

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
                physics: const NeverScrollableScrollPhysics(), // 이중 스크롤 방지
                shrinkWrap: true, // 내용물 크기만큼만 차지
                itemCount: controller.currentQuestion.options.length,
                separatorBuilder: (_, __) => SizedBox(height: 16.h),
                itemBuilder: (context, index) {
                  final option = controller.currentQuestion.options[index];
                  return _buildOptionButton(option);
                },
              )),

              SizedBox(height: 40.h), // 하단 여백
            ],
          ),
        ),
      ),
    );
  }

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
          crossAxisAlignment: CrossAxisAlignment.center, // 세로 중앙 정렬
          children: [
            CircleAvatar(
              radius: 12.r,
              backgroundColor: subPoint,
              child: Icon(Icons.check_rounded, color: mainPoint, size: 16.sp),
            ),
            SizedBox(width: 16.w),

            // 🔥 [수정 2] 가로 오버플로우(Right Overflow) 해결의 핵심!
            // Expanded로 감싸야 글자가 길 때 다음 줄로 넘어갑니다.
            Expanded(
              child: Text(
                option.text,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: textDark,
                  height: 1.2,
                ),
                maxLines: 3, // 너무 길 경우 최대 3줄
                overflow: TextOverflow.ellipsis, // 3줄 넘어가면 ... 처리
              ),
            ),
          ],
        ),
      ),
    );
  }
}