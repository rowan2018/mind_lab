import 'package:get/get.dart';
import 'package:rowan_mind_lab/controller/test_play_controller.dart';

class TestPlayBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TestPlayController>(() => TestPlayController());
  }
}
