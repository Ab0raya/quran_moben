import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';


class UserActivityController extends GetxController {
  RxList<DateTime> activityLog = <DateTime>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadActivityData();
  }

  void logAppOpen() async {
    final now = DateTime.now();
    activityLog.add(now);
    await saveActivityData();
  }

  Future<void> saveActivityData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = activityLog.map((date) => date.toIso8601String()).toList();
    await prefs.setStringList('activity_log', logs);
  }

  Future<void> loadActivityData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? logs = prefs.getStringList('activity_log');
    if (logs != null) {
      activityLog.assignAll(logs.map((log) => DateTime.parse(log)).toList());
    }
  }

  Map<int, int> getHourlyActivity() {
    Map<int, int> hourlyData = {};
    for (var log in activityLog) {
      hourlyData[log.hour] = (hourlyData[log.hour] ?? 0) + 1;
    }
    return hourlyData;
  }

  Map<int, int> getDailyActivity() {
    Map<int, int> dailyData = {};
    for (var log in activityLog) {
      dailyData[log.weekday] = (dailyData[log.weekday] ?? 0) + 1;
    }
    return dailyData;
  }
}

