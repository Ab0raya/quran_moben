import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeController extends GetxController {
  var selectedTabIndex = 0.obs;
  var savedName = 'عبدالله'.obs;
  RxBool get hasName => savedName.value.isNotEmpty.obs;

  @override
  void onInit() {
    super.onInit();
    loadName();
  }

  void changeTab(int index) {
    selectedTabIndex.value = index;
  }

  Future<void> loadName() async {
    final prefs = await SharedPreferences.getInstance();
    savedName.value = prefs.getString('user_name') ?? '';
  }

  Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    savedName.value = name;
  }
}