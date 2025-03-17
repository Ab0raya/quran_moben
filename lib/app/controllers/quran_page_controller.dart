import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/db/quarters.dart';
import '../../data/db/surahs_data.dart';
import '../../data/db/page_data.dart';
import '../../data/db/quran_text_data.dart';
import '../models/verse_model.dart';
import '../models/surah_model.dart';
import '../models/page_detail_model.dart';
import '../models/surah_page_model.dart';

class QuranPageController extends GetxController {
  final Rx<int> currentPageIndex = 1.obs;
  final Rx<Color> backgroundColor = Colors.white.obs;
  final Rx<Color> textColor = Colors.black.obs;
  final RxList<PageDetail> currentPageDetails = <PageDetail>[].obs;
  final RxList<SurahPage> surahStartPages = <SurahPage>[].obs;
  final RxList<Verse> allVerses = <Verse>[].obs;
  final RxList<Surah> allChapters = <Surah>[].obs;
  final selectedVerse = Rx<int?>(null);
  late PageController pageController;
  final int totalPages = pageData.length;
  String fontName = 'QCF_P001';
  bool containsMultipleSurahs = false;
  bool startsWithNewSurah = false;
  final Map<int, List<Verse>> _pageCache = {};
  static const String themeKey = 'selected_theme';
  static const String bookmarksKey = 'bookmarked_verses';
  final RxSet<String> bookmarkedVerses = <String>{}.obs;
  final player = AudioPlayer();
  var selectedTabIndex = 0.obs;

  void changeTab(int index) {
    selectedTabIndex.value = index;
  }

  Future<void> playAudio(
      {required int surahNumber, required int verseNumber}) async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      Get.snackbar("No Internet", "Please check your internet connection.");
      return;
    }

    try {
      await player.stop();

      var absoluteVerseNumber =
          getAbsoluteVerseNumber(surahNumber, verseNumber);
      final url =
          'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$absoluteVerseNumber.mp3';

      await player.setUrl(url);
      await player.play();
    } catch (e) {
      Get.snackbar("Error", "Failed to play audio: $e");
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadQuranData();
    loadTheme();
    loadBookmarks();
    generatePageJuzMap();
    generatePageHizbAndQuarterMap();
    loadPageData(currentPageIndex.value);
    pageController = PageController(initialPage: currentPageIndex.value - 1);
  }

  @override
  void onClose() {
    pageController.dispose();
    player.dispose();

    super.onClose();
  }

  final Map<int, int> pageJuzMap = {};

  void generatePageJuzMap() {
    for (int pageIndex = 0; pageIndex < pageData.length; pageIndex++) {
      final page = pageData[pageIndex];
      final firstDetail = page.first;
      final surah = firstDetail['surah'];
      final ayah = firstDetail['start'];
      pageJuzMap[pageIndex + 1] = getJuzNumber(surah, ayah);
    }
  }

  final Map<int, int> pageQuarterMap = {};

  int getQuarterForPage(int pageNumber) {
    return pageQuarterMap[pageNumber] ?? 0;
  }

  int getCountByPageNumber(int pageNumber) {
    if (pageNumber < quarters[0]['pageNumber']) {
      return -1;
    }

    for (int i = 0; i < quarters.length - 1; i++) {
      if (pageNumber >= quarters[i]['pageNumber'] &&
          pageNumber < quarters[i + 1]['pageNumber']) {
        return quarters[i]['count'] as int;
      }
    }

    return quarters.last['count'] as int;
  }

  int getHizbForPage(int pageNumber) {
    return pageHizbMap[pageNumber] ?? 1;
  }

  final Map<int, int> pageHizbMap = {};

  List<int> verseCounts = [
    7,
    286,
    200,
    176,
    120,
    165,
    206,
    75,
    129,
    109,
    123,
    111,
    43,
    52,
    99,
    128,
    111,
    110,
    98,
    135,
    112,
    78,
    118,
    64,
    77,
    227,
    93,
    88,
    69,
    60,
    34,
    30,
    73,
    54,
    45,
    83,
    182,
    88,
    75,
    85,
    54,
    53,
    89,
    59,
    37,
    35,
    38,
    29,
    18,
    45,
    60,
    49,
    62,
    55,
    78,
    96,
    29,
    22,
    24,
    13,
    14,
    11,
    11,
    18,
    12,
    12,
    30,
    52,
    52,
    44,
    28,
    28,
    20,
    56,
    40,
    31,
    50,
    40,
    46,
    42,
    29,
    19,
    36,
    25,
    22,
    17,
    19,
    26,
    30,
    20,
    15,
    21,
    11,
    8,
    8,
    19,
    5,
    8,
    8,
    11,
    11,
    8,
    3,
    9,
    5,
    4,
    7,
    3,
    6,
    3
  ];

  int getAbsoluteVerseNumber(int surahNumber, int verseNumber) {
    int absoluteNumber = verseNumber;
    for (int i = 0; i < surahNumber - 1; i++) {
      absoluteNumber += verseCounts[i];
    }
    return absoluteNumber;
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString(themeKey) ?? 'light';
    switch (theme) {
      case 'dark':
        setDarkTheme();
        break;
      case 'sepia':
        setSepiaTone();
        break;
      default:
        setLightTheme();
    }
  }

  Future<void> saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeKey, theme);
  }

  Future<void> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(bookmarksKey) ?? [];
    bookmarkedVerses.addAll(bookmarks);
  }

  Future<void> toggleBookmark(Verse verse) async {
    final verseId = '${verse.surahNumber}:${verse.verseNumber}';
    final prefs = await SharedPreferences.getInstance();

    if (bookmarkedVerses.contains(verseId)) {
      bookmarkedVerses.remove(verseId);
    } else {
      bookmarkedVerses.add(verseId);
    }

    await prefs.setStringList(bookmarksKey, bookmarkedVerses.toList());
  }

  bool isVerseBookmarked(Verse verse) {
    return bookmarkedVerses
        .contains('${verse.surahNumber}:${verse.verseNumber}');
  }

  void loadQuranData() {
    allVerses.value = quranText.map((e) => Verse.fromJson(e)).toList();
    allChapters.value = surahs;
    extractSurahStartPages();
  }

  void extractSurahStartPages() {
    surahStartPages.value = pageData.asMap().entries.expand<SurahPage>((entry) {
      return entry.value.where((detail) => detail['start'] == 1).map<SurahPage>(
          (detail) => SurahPage(surah: detail['surah'], page: entry.key + 1));
    }).toList();
  }

  Future<List<Verse>> fetchPageData(int pageIndex) async {
    if (_pageCache.containsKey(pageIndex)) {
      return _pageCache[pageIndex]!;
    }

    List<Verse> verses = [];
    for (var detail in pageData[pageIndex - 1]) {
      for (int verseNumber = detail['start'];
          verseNumber <= detail['end'];
          verseNumber++) {
        Verse? verse = allVerses.firstWhereOrNull(
          (v) =>
              v.surahNumber == detail['surah'] && v.verseNumber == verseNumber,
        );
        if (verse != null) {
          verses.add(verse);
        }
      }
    }

    _pageCache[pageIndex] = verses;
    return verses;
  }

  Map<int, List<Verse>> get cachedPages => _pageCache;

  void loadPageData(int pageIndex) {
    if (pageIndex < 1 || pageIndex > totalPages) return;
    currentPageIndex.value = pageIndex;
    fontName = 'QCF_P${pageIndex.toString().padLeft(3, '0')}';

    containsMultipleSurahs = _containsMultipleSurahs();
    startsWithNewSurah = _startsWithNewSurah();
  }

  void nextPage() => goToPage(currentPageIndex.value + 1);

  void previousPage() => goToPage(currentPageIndex.value - 1);

  void goToSurah(int surahId) {
    SurahPage? surahPage =
        surahStartPages.firstWhereOrNull((page) => page.surah == surahId);
    if (surahPage != null) goToPage(surahPage.page);
  }

  void goToPage(int pageIndex) {
    if (pageIndex < 1 || pageIndex > totalPages) return;
    loadPageData(pageIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pageController.hasClients) {
        pageController.animateToPage(
          pageIndex - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        pageController = PageController(initialPage: pageIndex - 1);
      }
    });
  }

  String getSurahInfo() {
    if (currentPageDetails.isEmpty) return '';
    Set<int> surahs = currentPageDetails.map((detail) => detail.surah).toSet();
    return surahs.length > 1
        ? 'Surahs: ${surahs.map(_getArabicSurahName).join(', ')}'
        : 'Surah: ${_getArabicSurahName(surahs.first)}';
  }

  int getJuzNumber(int surah, int ayah) {
    List juzList = [
      {"surah": 1, "ayah": 1},
      {"surah": 2, "ayah": 142},
      {"surah": 2, "ayah": 252},
      {"surah": 3, "ayah": 93},
      {"surah": 4, "ayah": 24},
      {"surah": 4, "ayah": 148},
      {"surah": 5, "ayah": 82},
      {"surah": 6, "ayah": 111},
      {"surah": 7, "ayah": 88},
      {"surah": 8, "ayah": 41},
    ];

    for (int i = 0; i < juzList.length; i++) {
      if (surah < juzList[i]["surah"] ||
          (surah == juzList[i]["surah"] && ayah < juzList[i]["ayah"])) {
        return i;
      }
    }
    return 30;
  }

  int getQuarter(int surah, int ayah) {
    for (int i = 0; i < quarters.length; i++) {
      if (surah < quarters[i]["surah"] ||
          (surah == quarters[i]["surah"] && ayah < quarters[i]["ayah"])) {
        return i;
      }
    }
    return 4;
  }

  String _getArabicSurahName(int surahId) =>
      allChapters.firstWhereOrNull((c) => c.id == surahId)?.name ?? '';

  bool _containsMultipleSurahs() {
    if (currentPageDetails.isEmpty) return false;
    return currentPageDetails.map((detail) => detail.surah).toSet().length > 1;
  }

  bool _startsWithNewSurah() {
    if (currentPageDetails.isEmpty) return false;
    return currentPageDetails.first.start == 1 &&
        currentPageDetails.first.surah != 9;
  }

  String getSurahNameForPage(int pageNumber) {
    return allChapters
        .firstWhere((s) => s.startPage <= pageNumber && s.endPage >= pageNumber)
        .name;
  }

  int getJuzForPage(int pageNumber) {
    for (var surah in surahs) {
      if (surah.startPage <= pageNumber && surah.endPage >= pageNumber) {
        return surah.juz;
      }
    }
    return 0;
  }

  void generatePageHizbAndQuarterMap() {
    for (int pageIndex = 0; pageIndex < pageData.length; pageIndex++) {
      final page = pageData[pageIndex];
      final firstDetail = page.first;
      final surah = firstDetail['surah'];
      final ayah = firstDetail['start'];

      int quarterIndex = 0;
      for (int i = 0; i < quarters.length; i++) {
        if (surah < quarters[i]["surah"] ||
            (surah == quarters[i]["surah"] && ayah < quarters[i]["ayah"])) {
          quarterIndex = i;
          break;
        }
      }
      if (quarterIndex == 0 &&
          (surah > quarters.last["surah"] ||
              (surah == quarters.last["surah"] &&
                  ayah >= quarters.last["ayah"]))) {
        quarterIndex = quarters.length - 1;
      }

      int hizbNumber = (quarterIndex ~/ 4) + 1;
      int quarterInHizb = (quarterIndex % 4) + 1;

      pageHizbMap[pageIndex + 1] = hizbNumber;
      pageQuarterMap[pageIndex + 1] = quarterInHizb;
    }
  }

  void setLightTheme() {
    backgroundColor.value = const Color(0xfffdfdfd);
    textColor.value = const Color(0xff0d0d0d);
    saveTheme('light');
  }

  void setDarkTheme() {
    backgroundColor.value = const Color(0xff0d0d0d);
    textColor.value = const Color(0xfffdfdfd);
    saveTheme('dark');
  }

  void setSepiaTone() {
    backgroundColor.value = const Color(0xFFF5E7C1);
    textColor.value = const Color(0xFF704214);
    saveTheme('sepia');
  }
}
