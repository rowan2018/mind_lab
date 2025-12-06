import 'package:get/get.dart';
// 화면들 import
import 'package:rowan_mind_lab/screens/home_screen.dart';
import 'package:rowan_mind_lab/screens/test_play_screen.dart';
import 'package:rowan_mind_lab/screens/result_screen.dart';
// 바인딩들 import (이미 만들어둔 파일 활용)
import 'package:rowan_mind_lab/bindings/home_binding.dart';
import 'package:rowan_mind_lab/bindings/test_play_binding.dart';
import 'package:rowan_mind_lab/bindings/result_binding.dart';

class Routes {
  // 경로 이름 상수 관리 (오타 방지)
  static const HOME = '/';
  static const TEST = '/test';
  static const RESULT = '/result';
}

class AppPages {
  // 초기 페이지 설정
  static const INITIAL = Routes.HOME;

  static final routes = [
    // 1. 메인 화면
    GetPage(
      name: Routes.HOME,
      page: () => const HomeScreen(),
      binding: HomeBinding(), // 깔끔하게 클래스로 분리
      transition: Transition.fadeIn, // 화면 전환 효과 추가 (선택)
    ),

    // 2. 테스트 플레이 화면
    GetPage(
      name: Routes.TEST,
      page: () => const TestPlayScreen(),
      binding: TestPlayBinding(),
      transition: Transition.rightToLeft, // 슬라이드 효과
    ),

    // 3. 결과 화면
    GetPage(
      name: Routes.RESULT,
      page: () => const ResultScreen(),
      binding: ResultBinding(),
      transition: Transition.fadeIn,
    ),
  ];
}