import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class UserActivityController extends GetxController {
  RxList<DateTime> activityLog = <DateTime>[].obs;
  RxInt totalAppOpens = 0.obs;
  RxInt totalPagesRead = 0.obs;
  RxInt currentStreak = 0.obs;

  // Map to store pages read by date
  final RxMap<String, int> pagesReadByDate = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadActivityData();
  }

  void logAppOpen() async {
    final now = DateTime.now();
    activityLog.add(now);
    totalAppOpens.value++;
    _calculateStreak();
    await saveActivityData();
  }

  void logPageRead() async {
    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);

    if (pagesReadByDate.containsKey(dateKey)) {
      pagesReadByDate[dateKey] = pagesReadByDate[dateKey]! + 1;
    } else {
      pagesReadByDate[dateKey] = 1;
    }

    totalPagesRead.value++;
    _calculateStreak();
    await saveActivityData();
  }

  void _calculateStreak() {
    if (activityLog.isEmpty) {
      currentStreak.value = 0;
      return;
    }

    // Get all unique dates from activity log
    final Set<String> activeDates = activityLog
        .map((date) => DateFormat('yyyy-MM-dd').format(date))
        .toSet();

    // Sort dates
    final List<String> sortedDates = activeDates.toList()..sort();

    if (sortedDates.isEmpty) return;

    // Check if today is in the active dates
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (!activeDates.contains(today)) {
      // If user hasn't been active today, check yesterday
      final yesterday = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(const Duration(days: 1)));
      if (!activeDates.contains(yesterday)) {
        currentStreak.value = 0;
        return;
      }
    }

    // Calculate current streak
    int streak = 1;
    final DateTime lastDate = DateTime.parse(sortedDates.last);

    for (int i = 1; i <= 366; i++) { // Cap at 366 to avoid infinite loop
      final DateTime previousDate = lastDate.subtract(Duration(days: i));
      final String previousDateStr = DateFormat('yyyy-MM-dd').format(previousDate);

      if (activeDates.contains(previousDateStr)) {
        streak++;
      } else {
        break;
      }
    }

    currentStreak.value = streak;
  }

  Future<void> saveActivityData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = activityLog.map((date) => date.toIso8601String()).toList();
    await prefs.setStringList('activity_log', logs);
    await prefs.setInt('total_app_opens', totalAppOpens.value);
    await prefs.setInt('total_pages_read', totalPagesRead.value);
    await prefs.setInt('current_streak', currentStreak.value);

    // Save pages read by date
    final Map<String, String> pagesReadMap = {};
    pagesReadByDate.forEach((key, value) {
      pagesReadMap[key] = value.toString();
    });
    await prefs.setString('pages_read_by_date', pagesReadMap.toString());
  }

  Future<void> loadActivityData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? logs = prefs.getStringList('activity_log');
    if (logs != null) {
      activityLog.assignAll(logs.map((log) => DateTime.parse(log)).toList());
    }

    totalAppOpens.value = prefs.getInt('total_app_opens') ?? 0;
    totalPagesRead.value = prefs.getInt('total_pages_read') ?? 0;
    currentStreak.value = prefs.getInt('current_streak') ?? 0;

    // Load pages read by date
    final String? pagesReadMapString = prefs.getString('pages_read_by_date');
    if (pagesReadMapString != null && pagesReadMapString.isNotEmpty) {
      try {
        // Parse the string back to a map
        final String cleanString = pagesReadMapString
            .replaceAll('{', '')
            .replaceAll('}', '');
        final List<String> pairs = cleanString.split(', ');

        for (String pair in pairs) {
          final List<String> keyValue = pair.split(': ');
          if (keyValue.length == 2) {
            final String key = keyValue[0].trim();
            final int value = int.tryParse(keyValue[1]) ?? 0;
            pagesReadByDate[key] = value;
          }
        }
      } catch (e) {
        print('Error parsing pages read map: $e');
      }
    }

    // Calculate streak on load
    _calculateStreak();
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

  Map<String, int> getWeeklyActivity() {
    Map<String, int> weeklyData = {};
    final now = DateTime.now();

    // Get activities for the last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('MM-dd').format(date);
      final dayKey = DateFormat('yyyy-MM-dd').format(date);

      // Count activities for this day
      int count = 0;
      for (var log in activityLog) {
        if (DateFormat('yyyy-MM-dd').format(log) == dayKey) {
          count++;
        }
      }

      weeklyData[dateStr] = count;
    }

    return weeklyData;
  }

  // Get reading statistics
  Map<String, int> getWeeklyReadingStats() {
    Map<String, int> weeklyReading = {};
    final now = DateTime.now();

    // Get pages read for the last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('MM-dd').format(date);
      final dayKey = DateFormat('yyyy-MM-dd').format(date);

      weeklyReading[dateStr] = pagesReadByDate[dayKey] ?? 0;
    }

    return weeklyReading;
  }
}