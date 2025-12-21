import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:rowan_mind_lab/controller/mirror_controller.dart';
import 'package:rowan_mind_lab/l10n/app_localizations.dart';

class MirrorScreen extends StatelessWidget {
  const MirrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MirrorController());
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Get.back(),
        ),
        title: Text(l10n.mirrorTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          // 🔥 [수정 1] 상단 공유 버튼 삭제. 여기 있으면 아무도 안 누름.

          Container(
            margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
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
                // 🍎 [수정] homeController의 사과 개수를 보여줌
                Text(
                  "${controller.homeController.appleCount.value}",
                  style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp),
                ),
              ],
            )),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Center(
                  child: RepaintBoundary(
                    key: controller.captureKey,
                    child: Container(
                      width: 0.85.sw,
                      constraints: BoxConstraints(
                        minHeight: 0.5.sh,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF2E1A47),
                            const Color(0xFF1A1A2E),
                            const Color(0xFF000000),
                            const Color(0xFF4B0082).withOpacity(0.8),
                          ],
                          stops: const [0.1, 0.4, 0.7, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6A00FF).withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 40.h),
                        child: Center(
                          child: Obx(() {
                            if (controller.isLoading.value) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(color: Colors.amber),
                                  SizedBox(height: 16.h),
                                  Text(l10n.mirrorLoading,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.white54, fontSize: 14.sp)),
                                ],
                              );
                            }
                            if (controller.answerText.value.isEmpty) {
                              return Text(
                                l10n.mirrorGuide,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.amber.shade200,
                                  fontSize: 22.sp,
                                  height: 1.5,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'GowunBatang',
                                ),
                              );
                            }
                            // 답변이 있을 때 표시되는 UI
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DefaultTextStyle(
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    color: const Color(0xFFFFD700),
                                    height: 1.6,
                                    fontFamily: 'GowunBatang',
                                    shadows: [
                                      Shadow(offset: const Offset(1, 1), color: Colors.black54, blurRadius: 2),
                                    ],
                                  ),
                                  child: AnimatedTextKit(
                                    animatedTexts: [
                                      TypewriterAnimatedText(
                                        controller.answerText.value,
                                        speed: const Duration(milliseconds: 60),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                    isRepeatingAnimation: false,
                                    displayFullTextOnTap: true,
                                  ),
                                ),

                                SizedBox(height: 30.h),

                                // 🔥 [핵심 추가] 답변 아래에 공유 버튼 생성
                                GestureDetector(
                                  onTap: controller.captureAndShare,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20.r),
                                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.share_rounded, color: Colors.amber, size: 16.sp),
                                        SizedBox(width: 8.w),
                                        Text(
                                            "이 답변 공유하기",
                                            style: TextStyle(
                                                color: Colors.amber,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.sp
                                            )
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

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
                        hintText: l10n.mirrorHint(controller.costPerQuestion),
                        hintStyle: TextStyle(
                            color: Colors.grey[500], fontSize: 14.sp),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Obx(() => CircleAvatar(
                    backgroundColor: controller.isLoading.value
                        ? Colors.grey
                        : Colors.deepPurpleAccent,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.askMirror,
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}