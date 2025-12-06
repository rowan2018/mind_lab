import 'package:get/get.dart';
import 'package:rowan_mind_lab/controller/result_controller.dart';

class ResultBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ResultController>(() => ResultController());
  }
}