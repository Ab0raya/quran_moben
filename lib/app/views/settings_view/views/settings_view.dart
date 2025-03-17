import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_moben/app/views/widgets/custom_textfield.dart';
import 'package:quran_moben/app/views/widgets/glass_container.dart';
import 'package:quran_moben/utils/colors.dart';
import 'package:quran_moben/utils/extensions.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../controllers/home_controller.dart';
import '../../../controllers/quran_page_controller.dart';
import '../../../controllers/user_activity_controller.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with SingleTickerProviderStateMixin {
  final HomeController controller = Get.put(HomeController());
  final TextEditingController _nameController = TextEditingController();
  final QuranPageController quranPageController =
      Get.put(QuranPageController());
  final UserActivityController activityController =
      Get.put(UserActivityController());

  late TabController _tabController;
  final List<String> _chartTypes = ['يومي', 'أسبوعي', 'ساعي'];

  @override
  void initState() {
    super.initState();
    _nameController.text = controller.savedName.value;
    _tabController = TabController(length: 3, vsync: this);

    activityController.logAppOpen();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: const Text('الإعدادات',
            style: TextStyle(color: AppColors.accentColor)),
        backgroundColor: AppColors.bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: AppColors.accentColor,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameInputSection(),
              const SizedBox(height: 20),
              _buildThemeSection(),
              const SizedBox(height: 30),
              _buildActivityStatsSection(),
              const SizedBox(height: 40),
              _buildActivityChartsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameInputSection() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            height: screenHeight(context) * 0.06,
            width: screenWidth(context),
            onChanged: (c) {},
            hint: 'أدخل أسمك',
            obscureText: false,
            controller: _nameController,
            suffixIcon: IconButton(
              icon:
                  const Icon(Icons.check_circle, color: AppColors.accentColor),
              onPressed: () => controller.saveName(_nameController.text),
            ),
            icon: Icons.person,
          ),
          if (controller.hasName.value)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'الاسم المحفوظ: ${controller.savedName.value}',
                style:
                    const TextStyle(fontSize: 16, color: AppColors.accentColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اختيار الثيم',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _buildThemeOption(
            title: 'الوضع النهاري',
            icon: Icons.light_mode,
            isSelected: quranPageController.selectedTabIndex.value == 0,
            onTap: () {
              quranPageController.changeTab(0);
              quranPageController.setLightTheme();
            },
            bgColor: const Color(0xfffdfdfd),
            textColor: const Color(0xff0d0d0d),
          ),
          _buildThemeOption(
            title: 'الوضع الليلي',
            icon: Icons.dark_mode,
            isSelected: quranPageController.selectedTabIndex.value == 1,
            onTap: () {
              quranPageController.changeTab(1);
              quranPageController.setDarkTheme();
            },
            textColor: const Color(0xfffdfdfd),
            bgColor: const Color(0xff0d0d0d),
          ),
          _buildThemeOption(
            title: 'وضع سيبيا',
            icon: Icons.color_lens,
            isSelected: quranPageController.selectedTabIndex.value == 2,
            onTap: () {
              quranPageController.changeTab(2);
              quranPageController.setSepiaTone();
            },
            bgColor: const Color(0xFFF5E7C1),
            textColor: const Color(0xFF704214),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStatsSection() {
    return Obx(() {
      final weekdayMap = {
        1: 'الإثنين',
        2: 'الثلاثاء',
        3: 'الأربعاء',
        4: 'الخميس',
        5: 'الجمعة',
        6: 'السبت',
        7: 'الأحد',
      };

      final dailyActivity = activityController.getDailyActivity();
      final mostActiveDay = dailyActivity.entries.isEmpty
          ? 'لا توجد بيانات'
          : weekdayMap[dailyActivity.entries
                  .reduce((a, b) => a.value > b.value ? a : b)
                  .key] ??
              'لا توجد بيانات';

      final hourlyActivity = activityController.getHourlyActivity();
      final mostActiveHour = hourlyActivity.entries.isEmpty
          ? 'لا توجد بيانات'
          : '${hourlyActivity.entries.reduce((a, b) => a.value > b.value ? a : b).key}:00';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إحصائيات النشاط',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'عدد الزيارات',
                  value: '${activityController.activityLog.length}',
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  title: 'اليوم الأكثر نشاطًا',
                  value: mostActiveDay,
                  icon: Icons.calendar_today,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'الساعة الأكثر نشاطًا',
                  value: mostActiveHour,
                  icon: Icons.access_time,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  title: 'آخر زيارة',
                  value: activityController.activityLog.isEmpty
                      ? 'لا توجد بيانات'
                      : DateFormat('dd/MM/yyyy')
                          .format(activityController.activityLog.last),
                  icon: Icons.history,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return GlassContainer(
      height: screenHeight(context) * 0.12,
      width: screenWidth(context) * 0.4,
      virMargin: screenHeight(context) * 0.01,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.accentColor, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.accentColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'مخططات النشاط',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 15),
        GlassContainer(
          height: screenHeight(context) * 0.4,
          width: screenWidth(context) * 0.9,
          virMargin: screenHeight(context) * 0.01,
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.accentColor,
                labelColor: AppColors.accentColor,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: _chartTypes.map((type) => Tab(text: type)).toList(),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDailyActivityChart(),
                    _buildWeeklyActivityChart(),
                    _buildHourlyActivityChart(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      height: screenHeight(context) * 0.06,
      width: screenWidth(context),
      virMargin: screenHeight(context) * 0.01,
      color: bgColor,
      border: Border.all(
        color: bgColor.withOpacity(0.5),
        width: 2,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: textColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? CircleAvatar(
                backgroundColor: bgColor.withOpacity(0.8),
                radius: 12,
                child: Icon(
                  Icons.check,
                  color: textColor,
                  size: 16,
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildDailyActivityChart() {
    final now = DateTime.now();
    final Map<String, int> dailyData = {};

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      dailyData[DateFormat('MM/dd').format(date)] = 0;
    }

    for (final activity in activityController.activityLog) {
      final dateStr = DateFormat('MM/dd').format(activity);
      if (dailyData.containsKey(dateStr)) {
        dailyData[dateStr] = (dailyData[dateStr] ?? 0) + 1;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: dailyData.values.isEmpty
              ? 1
              : (dailyData.values.reduce((a, b) => a > b ? a : b) * 1.2),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < dailyData.keys.length) {
                    return Text(
                      dailyData.keys.elementAt(value.toInt()).split('/')[1],
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(dailyData.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: dailyData.values.elementAt(index).toDouble(),
                  color: AppColors.accentColor,
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                )
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildWeeklyActivityChart() {
    final Map<int, int> weekdayData = activityController.getDailyActivity();
    final weekdayNames = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ];

    for (int i = 1; i <= 7; i++) {
      weekdayData.putIfAbsent(i, () => 0);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: weekdayData.values.isEmpty
              ? 1
              : (weekdayData.values.reduce((a, b) => a > b ? a : b) * 1.2),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final weekdayIndex = value.toInt();
                  if (weekdayIndex >= 0 && weekdayIndex < weekdayNames.length) {
                    return Text(
                      weekdayNames[weekdayIndex],
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 10),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(7, (index) {
            final weekday = index + 1;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: weekdayData[weekday]?.toDouble() ?? 0,
                  color: AppColors.accentColor,
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                )
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHourlyActivityChart() {
    final Map<int, int> hourlyData = activityController.getHourlyActivity();

    for (int i = 0; i < 24; i++) {
      hourlyData.putIfAbsent(i, () => 0);
    }

    final List<FlSpot> spots = List.generate(24, (index) {
      return FlSpot(index.toDouble(), hourlyData[index]?.toDouble() ?? 0);
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.x.toInt()}:00\n${spot.y.toInt()} زيارة',
                    const TextStyle(
                        color: AppColors.accentColor,
                        fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
          gridData: const FlGridData(
            show: true,
            drawVerticalLine: false,
            drawHorizontalLine: true,
            horizontalInterval: 1,
            getDrawingHorizontalLine: _getGridLine,
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 4,
                getTitlesWidget: (value, meta) {
                  if (value % 4 == 0) {
                    return Text(
                      '${value.toInt()}:00',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
          ),
          minX: 0,
          maxX: 23,
          minY: 0,
          maxY: hourlyData.values.isEmpty
              ? 1
              : (hourlyData.values.reduce((a, b) => a > b ? a : b) * 1.2),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.accentColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: false,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.accentColor,
                  strokeWidth: 1,
                  strokeColor: AppColors.bgColor,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.accentColor.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static FlLine _getGridLine(double value) {
    return FlLine(
      color: AppColors.textSecondary.withOpacity(0.1),
      strokeWidth: 1,
      dashArray: [5, 5],
    );
  }
}
