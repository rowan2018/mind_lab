import 'package:get/get.dart';
import 'package:rowan_mind_lab/controller/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // 1. put: 즉시 생성 (메인이라서 바로 필요)
    // 2. lazyPut: 필요할 때 생성 (메모리 절약)
    Get.put<HomeController>(HomeController());
  }
}