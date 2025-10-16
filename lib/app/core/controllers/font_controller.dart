import 'package:get/get.dart';

class FontController extends GetxController {
  final RxDouble fontSize = 16.0.obs;

  void setFontSize(double size) {
    fontSize.value = size;
  }
}
