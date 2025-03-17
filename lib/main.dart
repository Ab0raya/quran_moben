import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:quran_moben/app/views/home_view/home_view.dart';
import 'app/controllers/quran_page_controller.dart';
import 'data/db/db_helper.dart';
import 'utils/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
    SystemUiOverlay.top,
  ]);

  await trackAppOpen();

  KeepScreenOn.turnOn();

  runApp(const QuranApp());
}

Future<void> trackAppOpen() async {
  DBHelper dbHelper = DBHelper();
  String openTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  await dbHelper.insertAppOpenTime(openTime);
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(QuranPageController());
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accentColor),
        useMaterial3: true,
        fontFamily: 'Tajawal',
        scaffoldBackgroundColor: AppColors.bgColor,
      ),
      locale: const Locale('ar', 'SA'),
      home: const HomeScreenWrapper(),
    );
  }
}

class HomeScreenWrapper extends StatefulWidget {
  const HomeScreenWrapper({super.key});

  @override
  State<HomeScreenWrapper> createState() => _HomeScreenWrapperState();
}

class _HomeScreenWrapperState extends State<HomeScreenWrapper> {
  final DBHelper _dbHelper = DBHelper();
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  @override
  void dispose() {
    _recordAppClose();
    super.dispose();
  }

  Future<void> _recordAppClose() async {
    DateTime closeTime = DateTime.now();
    int duration = closeTime.difference(_startTime).inSeconds;
    String formattedCloseTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(closeTime);
    await _dbHelper.updateAppCloseTime(formattedCloseTime, duration);
  }

  @override
  Widget build(BuildContext context) {
    return const HomeView();
  }
}
