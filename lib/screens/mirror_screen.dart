import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:rowan_mind_lab/controller/mirror_controller.dart';

class MirrorScreen extends StatelessWidget {
  const MirrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 컨트롤러 주입
    final controller = Get.put(MirrorController());

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // 딥 다크 네이비 (신비함)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Get.back(),
        ),
        title: const Text("신비한 거울 상담소", style: TextStyle(color: Colors.white)),
        actions: [
          // 🍎 사과 개수 표시 (심사 중에도 이건 보여도 됨, '포인트' 개념이니까)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white24),
            ),
            child: Obx(() => Row(
              children: [
                const Text("🍎"),
                SizedBox(width: 6.w),
                Text(
                  "${controller.appleCount.value}",
                  style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14.sp),
                ),
              ],
            )),
          )
        ],
      ),
      // 배경 이미지 깔기 (선택 사항)
      // body: Container(decoration: BoxDecoration(image: ...), child: ...),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. 거울 프레임 (동그란 모양)
                  Container(
                    width: 300.w,
                    height: 380.h,
                    decoration: BoxDecoration(
                      color: Colors.black, // 거울 안쪽
                      borderRadius: BorderRadius.circular(150.r), // 타원형
                      border: Border.all(color: const Color(0xFF4B4B85), width: 8), // 프레임
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF6A00FF).withOpacity(0.4), blurRadius: 40, spreadRadius: 2),
                      ],
                    ),
                  ),

                  // 2. 거울 속 텍스트 (답변)
                  Container(
                    width: 240.w,
                    padding: EdgeInsets.all(20.w),
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Colors.purpleAccent),
                            SizedBox(height: 16.h),
                            Text("거울이 운명을 읽는 중...", style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
                          ],
                        );
                      }
                      if (controller.answerText.value.isEmpty) {
                        return Text(
                          "그대의 고민을\n속삭여 보아라...",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white30, fontSize: 16.sp, height: 1.5),
                        );
                      }
                      // 타자 효과
                      return DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.6,
                          fontFamily: 'Pretendard',
                          shadows: const [Shadow(color: Colors.purple, blurRadius: 10)],
                        ),
                        child: AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(controller.answerText.value, speed: const Duration(milliseconds: 80)),
                          ],
                          isRepeatingAnimation: false,
                          displayFullTextOnTap: true,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // 3. 하단 입력창
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: const BoxDecoration(
              color: Color(0xFF16213E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "사과 ${controller.costPerQuestion}개를 바치고 질문하기",
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14.sp),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Obx(() => CircleAvatar(
                  backgroundColor: controller.isLoading.value ? Colors.grey : Colors.purpleAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: controller.isLoading.value ? null : controller.askMirror,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}