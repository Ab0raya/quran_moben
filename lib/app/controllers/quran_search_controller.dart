

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class QuranSearchController extends GetxController {
  RxList<Map<String, dynamic>> filteredQuranText = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> bookmarkedVerses = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> searchHistory = <Map<String, dynamic>>[].obs;

  // New properties for UI enhancements
  RxBool isLoading = false.obs;
  RxString searchQuery = ''.obs;
  RxBool showFilters = false.obs;
  RxBool filterByJuz = false.obs;
  RxBool filterBySurah = false.obs;
  RxBool filterByHizb = false.obs;

  // Surah names mapping
  final Map<int, String> surahNames = {
    1: "الفاتحة",
    2: "البقرة",
    // Add all 114 surah names here
    113: "الفلق",
    114: "الناس",
  };

  // Juz mapping (surah and verse ranges for each juz)
  final List<Map<String, dynamic>> juzData = [
    {"juz": 1, "start_surah": 1, "start_verse": 1, "end_surah": 2, "end_verse": 141},
    {"juz": 2, "start_surah": 2, "start_verse": 142, "end_surah": 2, "end_verse": 252},
    // Add all 30 juz here
  ];

  // Hizb mapping
  final List<Map<String, dynamic>> hizbData = [
    {"hizb": 1, "start_surah": 1, "start_verse": 1, "end_surah": 2, "end_verse": 74},
    // Add all hizb data here
  ];

  @override
  void onInit() {
    super.onInit();
    loadBookmarks();
    loadSearchHistory();
    _enhanceQuranData();
    filteredQuranText.value = [];
  }

  // Add surah names to the quran text data
  void _enhanceQuranData() {
    for (var verse in quranTextNormal) {
      int surahNum = verse['surah_number'];
      verse['surah_name'] = surahNames[surahNum] ?? 'سورة $surahNum';
    }
  }

  // Search functionality with loading state
  void searchQuran(String query) {
    searchQuery.value = query;

    // Toggle filter visibility
    showFilters.value = query.isNotEmpty;

    // Show loading for better UX
    isLoading.value = true;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (query.isEmpty) {
        filteredQuranText.value = [];
      } else {
        // Normalize Arabic text for better search (remove diacritics)
        String normalizedQuery = _normalizeArabicText(query);

        // Apply filters
        List<Map<String, dynamic>> results = quranTextNormal.where((verse) {
          final content = _normalizeArabicText(verse['content'] as String);
          bool matches = content.contains(normalizedQuery);

          // Apply additional filters if enabled
          if (matches && (filterByJuz.value || filterBySurah.value || filterByHizb.value)) {
            if (filterByJuz.value) {
              matches = _verseIsInSelectedJuz(verse);
            }
            if (matches && filterBySurah.value) {
              matches = _verseIsInSelectedSurah(verse);
            }
            if (matches && filterByHizb.value) {
              matches = _verseIsInSelectedHizb(verse);
            }
          }

          return matches;
        }).toList();

        filteredQuranText.value = results;
      }
      isLoading.value = false;
    });
  }

  // Helper method to normalize Arabic text by removing diacritics
  String _normalizeArabicText(String text) {
    // Remove tashkeel (diacritics)
    return text
        .replaceAll('\u064B', '') // fathatan
        .replaceAll('\u064C', '') // dammatan
        .replaceAll('\u064D', '') // kasratan
        .replaceAll('\u064E', '') // fatha
        .replaceAll('\u064F', '') // damma
        .replaceAll('\u0650', '') // kasra
        .replaceAll('\u0651', '') // shadda
        .replaceAll('\u0652', '') // sukun
        .replaceAll('\u0653', '') // maddah
        .replaceAll('\u0654', '') // hamza above
        .replaceAll('\u0655', '') // hamza below
        .toLowerCase();
  }

  // Clear search query
  void clearSearch() {
    searchQuery.value = '';
    filteredQuranText.value = [];
    showFilters.value = false;
    filterByJuz.value = false;
    filterBySurah.value = false;
    filterByHizb.value = false;
  }

  // Filter toggle methods
  void toggleJuzFilter() {
    filterByJuz.value = !filterByJuz.value;
    searchQuran(searchQuery.value);
  }

  void toggleSurahFilter() {
    filterBySurah.value = !filterBySurah.value;
    searchQuran(searchQuery.value);
  }

  void toggleHizbFilter() {
    filterByHizb.value = !filterByHizb.value;
    searchQuran(searchQuery.value);
  }

  // Filter implementation methods
  bool _verseIsInSelectedJuz(Map<String, dynamic> verse) {
    // In a real implementation, you'd have logic to check if verse is in the current juz
    // This is a placeholder implementation
    int currentJuz = 1; // This would come from user selection
    for (var juz in juzData) {
      if (juz['juz'] == currentJuz) {
        int surahNum = verse['surah_number'];
        int verseNum = verse['verse_number'];

        // Start condition
        bool afterStart = surahNum > juz['start_surah'] ||
            (surahNum == juz['start_surah'] && verseNum >= juz['start_verse']);

        // End condition
        bool beforeEnd = surahNum < juz['end_surah'] ||
            (surahNum == juz['end_surah'] && verseNum <= juz['end_verse']);

        return afterStart && beforeEnd;
      }
    }
    return false;
  }

  bool _verseIsInSelectedSurah(Map<String, dynamic> verse) {
    // In a real implementation, this would check against user-selected surah
    int selectedSurah = 1; // This would come from user selection
    return verse['surah_number'] == selectedSurah;
  }

  bool _verseIsInSelectedHizb(Map<String, dynamic> verse) {
    // Similar to juz check but with hizb data
    int currentHizb = 1; // This would come from user selection
    for (var hizb in hizbData) {
      if (hizb['hizb'] == currentHizb) {
        int surahNum = verse['surah_number'];
        int verseNum = verse['verse_number'];

        bool afterStart = surahNum > hizb['start_surah'] ||
            (surahNum == hizb['start_surah'] && verseNum >= hizb['start_verse']);

        bool beforeEnd = surahNum < hizb['end_surah'] ||
            (surahNum == hizb['end_surah'] && verseNum <= hizb['end_verse']);

        return afterStart && beforeEnd;
      }
    }
    return false;
  }

  // Bookmark functionality
  void bookmarkVerse(Map<String, dynamic> verse) {
    // Check if verse is already bookmarked
    bool isAlreadyBookmarked = bookmarkedVerses.any((v) =>
    v['surah_number'] == verse['surah_number'] &&
        v['verse_number'] == verse['verse_number']
    );

    if (isAlreadyBookmarked) {
      bookmarkedVerses.removeWhere((v) =>
      v['surah_number'] == verse['surah_number'] &&
          v['verse_number'] == verse['verse_number']
      );
      Get.snackbar(
        'تم إزالة الإشارة المرجعية',
        'تم إزالة الآية من المفضلة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.2),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    } else {
      bookmarkedVerses.add(verse);
      Get.snackbar(
        'تمت إضافة الإشارة المرجعية',
        'تمت إضافة الآية إلى المفضلة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.2),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    }

    saveBookmarks();
  }

  // Check if a verse is bookmarked
  bool isVerseBookmarked(Map<String, dynamic> verse) {
    return bookmarkedVerses.any((v) =>
    v['surah_number'] == verse['surah_number'] &&
        v['verse_number'] == verse['verse_number']
    );
  }

  // Search history functionality
  void addToSearchHistory(Map<String, dynamic> verse) {
    // Don't add duplicates
    bool alreadyExists = searchHistory.any((v) =>
    v['surah_number'] == verse['surah_number'] &&
        v['verse_number'] == verse['verse_number']
    );

    if (!alreadyExists) {
      // Limit history to last 20 items
      if (searchHistory.length >= 20) {
        searchHistory.removeLast();
      }

      // Add to beginning of list
      searchHistory.insert(0, verse);
      saveSearchHistory();
    }
  }

  // Persistence methods
  Future<void> saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String bookmarksJson = jsonEncode(bookmarkedVerses.toList());
      await prefs.setString('quran_bookmarks', bookmarksJson);
    } catch (e) {
      debugPrint('Error saving bookmarks: $e');
    }
  }

  Future<void> loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? bookmarksJson = prefs.getString('quran_bookmarks');
      if (bookmarksJson != null) {
        final List decoded = jsonDecode(bookmarksJson);
        bookmarkedVerses.value = decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
    }
  }

  Future<void> saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String historyJson = jsonEncode(searchHistory.toList());
      await prefs.setString('quran_search_history', historyJson);
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  Future<void> loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString('quran_search_history');
      if (historyJson != null) {
        final List decoded = jsonDecode(historyJson);
        searchHistory.value = decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error loading search history: $e');
    }
  }

  final List<Map<String, dynamic>> quranTextNormal = [
    {
      "surah_number": 1,
      "verse_number": 1,
      "content": "بسم الله الرحمان الرحيم"
    },
    {
      "surah_number": 1,
      "verse_number": 2,
      "content": "الحمد لله رب العالمين"
    },
    {
      "surah_number": 1,
      "verse_number": 3,
      "content": "الرحمان الرحيم"
    },
    {
      "surah_number": 1,
      "verse_number": 4,
      "content": "مالك يوم الدين"
    },
    {
      "surah_number": 1,
      "verse_number": 5,
      "content": "اياك نعبد واياك نستعين"
    },
    {
      "surah_number": 1,
      "verse_number": 6,
      "content": "اهدنا الصراط المستقيم"
    },
    {
      "surah_number": 1,
      "verse_number": 7,
      "content": "صراط الذين أنعمت عليهم غير المغضوب عليهم ولا الضالين"
    },
    {
      "surah_number": 2,
      "verse_number": 1,
      "content": "الم"
    },
    {
      "surah_number": 2,
      "verse_number": 2,
      "content": "ذالك الكتاب لا ريب فيه هدى للمتقين"
    },
    {
      "surah_number": 2,
      "verse_number": 3,
      "content": "الذين يؤمنون بالغيب ويقيمون الصلواه ومما رزقناهم ينفقون"
    },
    {
      "surah_number": 2,
      "verse_number": 4,
      "content": "والذين يؤمنون بما أنزل اليك وما أنزل من قبلك وبالأخره هم يوقنون"
    },
    {
      "surah_number": 2,
      "verse_number": 5,
      "content": "أولائك علىا هدى من ربهم وأولائك هم المفلحون"
    },
    {
      "surah_number": 2,
      "verse_number": 6,
      "content": "ان الذين كفروا سوا عليهم ءأنذرتهم أم لم تنذرهم لا يؤمنون"
    },
    {
      "surah_number": 2,
      "verse_number": 7,
      "content": "ختم الله علىا قلوبهم وعلىا سمعهم وعلىا أبصارهم غشاوه ولهم عذاب عظيم"
    },
    {
      "surah_number": 2,
      "verse_number": 8,
      "content": "ومن الناس من يقول امنا بالله وباليوم الأخر وما هم بمؤمنين"
    },
    {
      "surah_number": 2,
      "verse_number": 9,
      "content": "يخادعون الله والذين امنوا وما يخدعون الا أنفسهم وما يشعرون"
    },
    {
      "surah_number": 2,
      "verse_number": 10,
      "content": "في قلوبهم مرض فزادهم الله مرضا ولهم عذاب أليم بما كانوا يكذبون"
    },
    {
      "surah_number": 2,
      "verse_number": 11,
      "content": "واذا قيل لهم لا تفسدوا في الأرض قالوا انما نحن مصلحون"
    },
    {
      "surah_number": 2,
      "verse_number": 12,
      "content": "ألا انهم هم المفسدون ولاكن لا يشعرون"
    },
    {
      "surah_number": 2,
      "verse_number": 13,
      "content": "واذا قيل لهم امنوا كما امن الناس قالوا أنؤمن كما امن السفها ألا انهم هم السفها ولاكن لا يعلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 14,
      "content": "واذا لقوا الذين امنوا قالوا امنا واذا خلوا الىا شياطينهم قالوا انا معكم انما نحن مستهزون"
    },
    {
      "surah_number": 2,
      "verse_number": 15,
      "content": "الله يستهزئ بهم ويمدهم في طغيانهم يعمهون"
    },
    {
      "surah_number": 2,
      "verse_number": 16,
      "content": "أولائك الذين اشتروا الضلاله بالهدىا فما ربحت تجارتهم وما كانوا مهتدين"
    },
    {
      "surah_number": 2,
      "verse_number": 17,
      "content": "مثلهم كمثل الذي استوقد نارا فلما أضات ما حوله ذهب الله بنورهم وتركهم في ظلمات لا يبصرون"
    },
    {
      "surah_number": 2,
      "verse_number": 18,
      "content": "صم بكم عمي فهم لا يرجعون"
    },
    {
      "surah_number": 2,
      "verse_number": 19,
      "content": "أو كصيب من السما فيه ظلمات ورعد وبرق يجعلون أصابعهم في اذانهم من الصواعق حذر الموت والله محيط بالكافرين"
    },
    {
      "surah_number": 2,
      "verse_number": 20,
      "content": "يكاد البرق يخطف أبصارهم كلما أضا لهم مشوا فيه واذا أظلم عليهم قاموا ولو شا الله لذهب بسمعهم وأبصارهم ان الله علىا كل شي قدير"
    },
    {
      "surah_number": 2,
      "verse_number": 21,
      "content": "ياأيها الناس اعبدوا ربكم الذي خلقكم والذين من قبلكم لعلكم تتقون"
    },
    {
      "surah_number": 2,
      "verse_number": 22,
      "content": "الذي جعل لكم الأرض فراشا والسما بنا وأنزل من السما ما فأخرج به من الثمرات رزقا لكم فلا تجعلوا لله أندادا وأنتم تعلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 23,
      "content": "وان كنتم في ريب مما نزلنا علىا عبدنا فأتوا بسوره من مثله وادعوا شهداكم من دون الله ان كنتم صادقين"
    },
    {
      "surah_number": 2,
      "verse_number": 24,
      "content": "فان لم تفعلوا ولن تفعلوا فاتقوا النار التي وقودها الناس والحجاره أعدت للكافرين"
    },
    {
      "surah_number": 2,
      "verse_number": 25,
      "content": "وبشر الذين امنوا وعملوا الصالحات أن لهم جنات تجري من تحتها الأنهار كلما رزقوا منها من ثمره رزقا قالوا هاذا الذي رزقنا من قبل وأتوا به متشابها ولهم فيها أزواج مطهره وهم فيها خالدون"
    },
    {
      "surah_number": 2,
      "verse_number": 26,
      "content": "ان الله لا يستحي أن يضرب مثلا ما بعوضه فما فوقها فأما الذين امنوا فيعلمون أنه الحق من ربهم وأما الذين كفروا فيقولون ماذا أراد الله بهاذا مثلا يضل به كثيرا ويهدي به كثيرا وما يضل به الا الفاسقين"
    },
    {
      "surah_number": 2,
      "verse_number": 27,
      "content": "الذين ينقضون عهد الله من بعد ميثاقه ويقطعون ما أمر الله به أن يوصل ويفسدون في الأرض أولائك هم الخاسرون"
    },
    {
      "surah_number": 2,
      "verse_number": 28,
      "content": "كيف تكفرون بالله وكنتم أمواتا فأحياكم ثم يميتكم ثم يحييكم ثم اليه ترجعون"
    },
    {
      "surah_number": 2,
      "verse_number": 29,
      "content": "هو الذي خلق لكم ما في الأرض جميعا ثم استوىا الى السما فسوىاهن سبع سماوات وهو بكل شي عليم"
    },
    {
      "surah_number": 2,
      "verse_number": 30,
      "content": "واذ قال ربك للملائكه اني جاعل في الأرض خليفه قالوا أتجعل فيها من يفسد فيها ويسفك الدما ونحن نسبح بحمدك ونقدس لك قال اني أعلم ما لا تعلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 31,
      "content": "وعلم ادم الأسما كلها ثم عرضهم على الملائكه فقال أنبٔوني بأسما هاؤلا ان كنتم صادقين"
    },
    {
      "surah_number": 2,
      "verse_number": 32,
      "content": "قالوا سبحانك لا علم لنا الا ما علمتنا انك أنت العليم الحكيم"
    },
    {
      "surah_number": 2,
      "verse_number": 33,
      "content": "قال يأادم أنبئهم بأسمائهم فلما أنبأهم بأسمائهم قال ألم أقل لكم اني أعلم غيب السماوات والأرض وأعلم ما تبدون وما كنتم تكتمون"
    },
    {
      "surah_number": 2,
      "verse_number": 34,
      "content": "واذ قلنا للملائكه اسجدوا لأدم فسجدوا الا ابليس أبىا واستكبر وكان من الكافرين"
    },
    {
      "surah_number": 2,
      "verse_number": 35,
      "content": "وقلنا يأادم اسكن أنت وزوجك الجنه وكلا منها رغدا حيث شئتما ولا تقربا هاذه الشجره فتكونا من الظالمين"
    },
    {
      "surah_number": 2,
      "verse_number": 36,
      "content": "فأزلهما الشيطان عنها فأخرجهما مما كانا فيه وقلنا اهبطوا بعضكم لبعض عدو ولكم في الأرض مستقر ومتاع الىا حين"
    },
    {
      "surah_number": 2,
      "verse_number": 37,
      "content": "فتلقىا ادم من ربه كلمات فتاب عليه انه هو التواب الرحيم"
    },
    {
      "surah_number": 2,
      "verse_number": 38,
      "content": "قلنا اهبطوا منها جميعا فاما يأتينكم مني هدى فمن تبع هداي فلا خوف عليهم ولا هم يحزنون"
    },
    {
      "surah_number": 2,
      "verse_number": 39,
      "content": "والذين كفروا وكذبوا بٔاياتنا أولائك أصحاب النار هم فيها خالدون"
    },
    {
      "surah_number": 2,
      "verse_number": 40,
      "content": "يابني اسرايل اذكروا نعمتي التي أنعمت عليكم وأوفوا بعهدي أوف بعهدكم واياي فارهبون"
    },
    {
      "surah_number": 2,
      "verse_number": 41,
      "content": "وامنوا بما أنزلت مصدقا لما معكم ولا تكونوا أول كافر به ولا تشتروا بٔاياتي ثمنا قليلا واياي فاتقون"
    },
    {
      "surah_number": 2,
      "verse_number": 42,
      "content": "ولا تلبسوا الحق بالباطل وتكتموا الحق وأنتم تعلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 43,
      "content": "وأقيموا الصلواه واتوا الزكواه واركعوا مع الراكعين"
    },
    {
      "surah_number": 2,
      "verse_number": 44,
      "content": "أتأمرون الناس بالبر وتنسون أنفسكم وأنتم تتلون الكتاب أفلا تعقلون"
    },
    {
      "surah_number": 2,
      "verse_number": 45,
      "content": "واستعينوا بالصبر والصلواه وانها لكبيره الا على الخاشعين"
    },
    {
      "surah_number": 2,
      "verse_number": 46,
      "content": "الذين يظنون أنهم ملاقوا ربهم وأنهم اليه راجعون"
    },
    {
      "surah_number": 2,
      "verse_number": 47,
      "content": "يابني اسرايل اذكروا نعمتي التي أنعمت عليكم وأني فضلتكم على العالمين"
    },
    {
      "surah_number": 2,
      "verse_number": 48,
      "content": "واتقوا يوما لا تجزي نفس عن نفس شئا ولا يقبل منها شفاعه ولا يؤخذ منها عدل ولا هم ينصرون"
    },
    {
      "surah_number": 2,
      "verse_number": 49,
      "content": "واذ نجيناكم من ال فرعون يسومونكم سو العذاب يذبحون أبناكم ويستحيون نساكم وفي ذالكم بلا من ربكم عظيم"
    },
    {
      "surah_number": 2,
      "verse_number": 50,
      "content": "واذ فرقنا بكم البحر فأنجيناكم وأغرقنا ال فرعون وأنتم تنظرون"
    },
    {
      "surah_number": 2,
      "verse_number": 51,
      "content": "واذ واعدنا موسىا أربعين ليله ثم اتخذتم العجل من بعده وأنتم ظالمون"
    },
    {
      "surah_number": 2,
      "verse_number": 52,
      "content": "ثم عفونا عنكم من بعد ذالك لعلكم تشكرون"
    },
    {
      "surah_number": 2,
      "verse_number": 53,
      "content": "واذ اتينا موسى الكتاب والفرقان لعلكم تهتدون"
    },
    {
      "surah_number": 2,
      "verse_number": 54,
      "content": "واذ قال موسىا لقومه ياقوم انكم ظلمتم أنفسكم باتخاذكم العجل فتوبوا الىا بارئكم فاقتلوا أنفسكم ذالكم خير لكم عند بارئكم فتاب عليكم انه هو التواب الرحيم"
    },
    {
      "surah_number": 2,
      "verse_number": 55,
      "content": "واذ قلتم ياموسىا لن نؤمن لك حتىا نرى الله جهره فأخذتكم الصاعقه وأنتم تنظرون"
    },
    {
      "surah_number": 2,
      "verse_number": 56,
      "content": "ثم بعثناكم من بعد موتكم لعلكم تشكرون"
    },
    {
      "surah_number": 2,
      "verse_number": 57,
      "content": "وظللنا عليكم الغمام وأنزلنا عليكم المن والسلوىا كلوا من طيبات ما رزقناكم وما ظلمونا ولاكن كانوا أنفسهم يظلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 58,
      "content": "واذ قلنا ادخلوا هاذه القريه فكلوا منها حيث شئتم رغدا وادخلوا الباب سجدا وقولوا حطه نغفر لكم خطاياكم وسنزيد المحسنين"
    },
    {
      "surah_number": 2,
      "verse_number": 59,
      "content": "فبدل الذين ظلموا قولا غير الذي قيل لهم فأنزلنا على الذين ظلموا رجزا من السما بما كانوا يفسقون"
    },
    {
      "surah_number": 2,
      "verse_number": 60,
      "content": "واذ استسقىا موسىا لقومه فقلنا اضرب بعصاك الحجر فانفجرت منه اثنتا عشره عينا قد علم كل أناس مشربهم كلوا واشربوا من رزق الله ولا تعثوا في الأرض مفسدين"
    },
    {
      "surah_number": 2,
      "verse_number": 61,
      "content": "واذ قلتم ياموسىا لن نصبر علىا طعام واحد فادع لنا ربك يخرج لنا مما تنبت الأرض من بقلها وقثائها وفومها وعدسها وبصلها قال أتستبدلون الذي هو أدنىا بالذي هو خير اهبطوا مصرا فان لكم ما سألتم وضربت عليهم الذله والمسكنه وباو بغضب من الله ذالك بأنهم كانوا يكفرون بٔايات الله ويقتلون النبين بغير الحق ذالك بما عصوا وكانوا يعتدون"
    },
    {
      "surah_number": 2,
      "verse_number": 62,
      "content": "ان الذين امنوا والذين هادوا والنصارىا والصابٔين من امن بالله واليوم الأخر وعمل صالحا فلهم أجرهم عند ربهم ولا خوف عليهم ولا هم يحزنون"
    },
    {
      "surah_number": 2,
      "verse_number": 63,
      "content": "واذ أخذنا ميثاقكم ورفعنا فوقكم الطور خذوا ما اتيناكم بقوه واذكروا ما فيه لعلكم تتقون"
    },
    {
      "surah_number": 2,
      "verse_number": 64,
      "content": "ثم توليتم من بعد ذالك فلولا فضل الله عليكم ورحمته لكنتم من الخاسرين"
    },
    {
      "surah_number": 2,
      "verse_number": 65,
      "content": "ولقد علمتم الذين اعتدوا منكم في السبت فقلنا لهم كونوا قرده خاسٔين"
    },
    {
      "surah_number": 2,
      "verse_number": 66,
      "content": "فجعلناها نكالا لما بين يديها وما خلفها وموعظه للمتقين"
    },
    {
      "surah_number": 2,
      "verse_number": 67,
      "content": "واذ قال موسىا لقومه ان الله يأمركم أن تذبحوا بقره قالوا أتتخذنا هزوا قال أعوذ بالله أن أكون من الجاهلين"
    },
    {
      "surah_number": 2,
      "verse_number": 68,
      "content": "قالوا ادع لنا ربك يبين لنا ما هي قال انه يقول انها بقره لا فارض ولا بكر عوان بين ذالك فافعلوا ما تؤمرون"
    },
    {
      "surah_number": 2,
      "verse_number": 69,
      "content": "قالوا ادع لنا ربك يبين لنا ما لونها قال انه يقول انها بقره صفرا فاقع لونها تسر الناظرين"
    },
    {
      "surah_number": 2,
      "verse_number": 70,
      "content": "قالوا ادع لنا ربك يبين لنا ما هي ان البقر تشابه علينا وانا ان شا الله لمهتدون"
    },
    {
      "surah_number": 2,
      "verse_number": 71,
      "content": "قال انه يقول انها بقره لا ذلول تثير الأرض ولا تسقي الحرث مسلمه لا شيه فيها قالوا الٔان جئت بالحق فذبحوها وما كادوا يفعلون"
    },
    {
      "surah_number": 2,
      "verse_number": 72,
      "content": "واذ قتلتم نفسا فادار أتم فيها والله مخرج ما كنتم تكتمون"
    },
    {
      "surah_number": 2,
      "verse_number": 73,
      "content": "فقلنا اضربوه ببعضها كذالك يحي الله الموتىا ويريكم اياته لعلكم تعقلون"
    },
    {
      "surah_number": 2,
      "verse_number": 74,
      "content": "ثم قست قلوبكم من بعد ذالك فهي كالحجاره أو أشد قسوه وان من الحجاره لما يتفجر منه الأنهار وان منها لما يشقق فيخرج منه الما وان منها لما يهبط من خشيه الله وما الله بغافل عما تعملون"
    },
    {
      "surah_number": 2,
      "verse_number": 75,
      "content": "أفتطمعون أن يؤمنوا لكم وقد كان فريق منهم يسمعون كلام الله ثم يحرفونه من بعد ما عقلوه وهم يعلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 76,
      "content": "واذا لقوا الذين امنوا قالوا امنا واذا خلا بعضهم الىا بعض قالوا أتحدثونهم بما فتح الله عليكم ليحاجوكم به عند ربكم أفلا تعقلون"
    },
    {
      "surah_number": 2,
      "verse_number": 77,
      "content": "أولا يعلمون أن الله يعلم ما يسرون وما يعلنون"
    },
    {
      "surah_number": 2,
      "verse_number": 78,
      "content": "ومنهم أميون لا يعلمون الكتاب الا أماني وان هم الا يظنون"
    },
    {
      "surah_number": 2,
      "verse_number": 79,
      "content": "فويل للذين يكتبون الكتاب بأيديهم ثم يقولون هاذا من عند الله ليشتروا به ثمنا قليلا فويل لهم مما كتبت أيديهم وويل لهم مما يكسبون"
    },
    {
      "surah_number": 2,
      "verse_number": 80,
      "content": "وقالوا لن تمسنا النار الا أياما معدوده قل أتخذتم عند الله عهدا فلن يخلف الله عهده أم تقولون على الله ما لا تعلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 81,
      "content": "بلىا من كسب سيئه وأحاطت به خطئته فأولائك أصحاب النار هم فيها خالدون"
    },
    {
      "surah_number": 2,
      "verse_number": 82,
      "content": "والذين امنوا وعملوا الصالحات أولائك أصحاب الجنه هم فيها خالدون"
    },
    {
      "surah_number": 2,
      "verse_number": 83,
      "content": "واذ أخذنا ميثاق بني اسرايل لا تعبدون الا الله وبالوالدين احسانا وذي القربىا واليتامىا والمساكين وقولوا للناس حسنا وأقيموا الصلواه واتوا الزكواه ثم توليتم الا قليلا منكم وأنتم معرضون"
    },
    {
      "surah_number": 2,
      "verse_number": 84,
      "content": "واذ أخذنا ميثاقكم لا تسفكون دماكم ولا تخرجون أنفسكم من دياركم ثم أقررتم وأنتم تشهدون"
    },
    {
      "surah_number": 2,
      "verse_number": 85,
      "content": "ثم أنتم هاؤلا تقتلون أنفسكم وتخرجون فريقا منكم من ديارهم تظاهرون عليهم بالاثم والعدوان وان يأتوكم أسارىا تفادوهم وهو محرم عليكم اخراجهم أفتؤمنون ببعض الكتاب وتكفرون ببعض فما جزا من يفعل ذالك منكم الا خزي في الحيواه الدنيا ويوم القيامه يردون الىا أشد العذاب وما الله بغافل عما تعملون"
    },
    {
      "surah_number": 2,
      "verse_number": 86,
      "content": "أولائك الذين اشتروا الحيواه الدنيا بالأخره فلا يخفف عنهم العذاب ولا هم ينصرون"
    },
    {
      "surah_number": 2,
      "verse_number": 87,
      "content": "ولقد اتينا موسى الكتاب وقفينا من بعده بالرسل واتينا عيسى ابن مريم البينات وأيدناه بروح القدس أفكلما جاكم رسول بما لا تهوىا أنفسكم استكبرتم ففريقا كذبتم وفريقا تقتلون"
    },
    {
      "surah_number": 2,
      "verse_number": 88,
      "content": "وقالوا قلوبنا غلف بل لعنهم الله بكفرهم فقليلا ما يؤمنون"
    },
    {
      "surah_number": 2,
      "verse_number": 89,
      "content": "ولما جاهم كتاب من عند الله مصدق لما معهم وكانوا من قبل يستفتحون على الذين كفروا فلما جاهم ما عرفوا كفروا به فلعنه الله على الكافرين"
    },
    {
      "surah_number": 2,
      "verse_number": 90,
      "content": "بئسما اشتروا به أنفسهم أن يكفروا بما أنزل الله بغيا أن ينزل الله من فضله علىا من يشا من عباده فباو بغضب علىا غضب وللكافرين عذاب مهين"
    },
    {
      "surah_number": 2,
      "verse_number": 91,
      "content": "واذا قيل لهم امنوا بما أنزل الله قالوا نؤمن بما أنزل علينا ويكفرون بما وراه وهو الحق مصدقا لما معهم قل فلم تقتلون أنبيا الله من قبل ان كنتم مؤمنين"
    },
    {
      "surah_number": 2,
      "verse_number": 92,
      "content": "ولقد جاكم موسىا بالبينات ثم اتخذتم العجل من بعده وأنتم ظالمون"
    },
    {
      "surah_number": 2,
      "verse_number": 93,
      "content": "واذ أخذنا ميثاقكم ورفعنا فوقكم الطور خذوا ما اتيناكم بقوه واسمعوا قالوا سمعنا وعصينا وأشربوا في قلوبهم العجل بكفرهم قل بئسما يأمركم به ايمانكم ان كنتم مؤمنين"
    },
    {
      "surah_number": 2,
      "verse_number": 94,
      "content": "قل ان كانت لكم الدار الأخره عند الله خالصه من دون الناس فتمنوا الموت ان كنتم صادقين"
    },
    {
      "surah_number": 2,
      "verse_number": 95,
      "content": "ولن يتمنوه أبدا بما قدمت أيديهم والله عليم بالظالمين"
    },
    {
      "surah_number": 2,
      "verse_number": 96,
      "content": "ولتجدنهم أحرص الناس علىا حيواه ومن الذين أشركوا يود أحدهم لو يعمر ألف سنه وما هو بمزحزحه من العذاب أن يعمر والله بصير بما يعملون"
    },
    {
      "surah_number": 2,
      "verse_number": 97,
      "content": "قل من كان عدوا لجبريل فانه نزله علىا قلبك باذن الله مصدقا لما بين يديه وهدى وبشرىا للمؤمنين"
    },
    {
      "surah_number": 2,
      "verse_number": 98,
      "content": "من كان عدوا لله وملائكته ورسله وجبريل وميكىال فان الله عدو للكافرين"
    },
    {
      "surah_number": 2,
      "verse_number": 99,
      "content": "ولقد أنزلنا اليك ايات بينات وما يكفر بها الا الفاسقون"
    },
    {
      "surah_number": 2,
      "verse_number": 100,
      "content": "أوكلما عاهدوا عهدا نبذه فريق منهم بل أكثرهم لا يؤمنون"
    },
    {
      "surah_number": 2,
      "verse_number": 101,
      "content": "ولما جاهم رسول من عند الله مصدق لما معهم نبذ فريق من الذين أوتوا الكتاب كتاب الله ورا ظهورهم كأنهم لا يعلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 102,
      "content": "واتبعوا ما تتلوا الشياطين علىا ملك سليمان وما كفر سليمان ولاكن الشياطين كفروا يعلمون الناس السحر وما أنزل على الملكين ببابل هاروت وماروت وما يعلمان من أحد حتىا يقولا انما نحن فتنه فلا تكفر فيتعلمون منهما ما يفرقون به بين المر وزوجه وما هم بضارين به من أحد الا باذن الله ويتعلمون ما يضرهم ولا ينفعهم ولقد علموا لمن اشترىاه ما له في الأخره من خلاق ولبئس ما شروا به أنفسهم لو كانوا يعلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 103,
      "content": "ولو أنهم امنوا واتقوا لمثوبه من عند الله خير لو كانوا يعلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 104,
      "content": "ياأيها الذين امنوا لا تقولوا راعنا وقولوا انظرنا واسمعوا وللكافرين عذاب أليم"
    },
    {
      "surah_number": 2,
      "verse_number": 105,
      "content": "ما يود الذين كفروا من أهل الكتاب ولا المشركين أن ينزل عليكم من خير من ربكم والله يختص برحمته من يشا والله ذو الفضل العظيم"
    },
    {
      "surah_number": 2,
      "verse_number": 106,
      "content": "ما ننسخ من ايه أو ننسها نأت بخير منها أو مثلها ألم تعلم أن الله علىا كل شي قدير"
    },
    {
      "surah_number": 2,
      "verse_number": 107,
      "content": "ألم تعلم أن الله له ملك السماوات والأرض وما لكم من دون الله من ولي ولا نصير"
    },
    {
      "surah_number": 2,
      "verse_number": 108,
      "content": "أم تريدون أن تسٔلوا رسولكم كما سئل موسىا من قبل ومن يتبدل الكفر بالايمان فقد ضل سوا السبيل"
    },
    {
      "surah_number": 2,
      "verse_number": 109,
      "content": "ود كثير من أهل الكتاب لو يردونكم من بعد ايمانكم كفارا حسدا من عند أنفسهم من بعد ما تبين لهم الحق فاعفوا واصفحوا حتىا يأتي الله بأمره ان الله علىا كل شي قدير"
    },
    {
      "surah_number": 2,
      "verse_number": 110,
      "content": "وأقيموا الصلواه واتوا الزكواه وما تقدموا لأنفسكم من خير تجدوه عند الله ان الله بما تعملون بصير"
    },
    {
      "surah_number": 2,
      "verse_number": 111,
      "content": "وقالوا لن يدخل الجنه الا من كان هودا أو نصارىا تلك أمانيهم قل هاتوا برهانكم ان كنتم صادقين"
    },
    {
      "surah_number": 2,
      "verse_number": 112,
      "content": "بلىا من أسلم وجهه لله وهو محسن فله أجره عند ربه ولا خوف عليهم ولا هم يحزنون"
    },
    {
      "surah_number": 2,
      "verse_number": 113,
      "content": "وقالت اليهود ليست النصارىا علىا شي وقالت النصارىا ليست اليهود علىا شي وهم يتلون الكتاب كذالك قال الذين لا يعلمون مثل قولهم فالله يحكم بينهم يوم القيامه فيما كانوا فيه يختلفون"
    },
    {
      "surah_number": 2,
      "verse_number": 114,
      "content": "ومن أظلم ممن منع مساجد الله أن يذكر فيها اسمه وسعىا في خرابها أولائك ما كان لهم أن يدخلوها الا خائفين لهم في الدنيا خزي ولهم في الأخره عذاب عظيم"
    },
    {
      "surah_number": 2,
      "verse_number": 115,
      "content": "ولله المشرق والمغرب فأينما تولوا فثم وجه الله ان الله واسع عليم"
    },
    {
      "surah_number": 2,
      "verse_number": 116,
      "content": "وقالوا اتخذ الله ولدا سبحانه بل له ما في السماوات والأرض كل له قانتون"
    },
    {
      "surah_number": 2,
      "verse_number": 117,
      "content": "بديع السماوات والأرض واذا قضىا أمرا فانما يقول له كن فيكون"
    },
    {
      "surah_number": 2,
      "verse_number": 118,
      "content": "وقال الذين لا يعلمون لولا يكلمنا الله أو تأتينا ايه كذالك قال الذين من قبلهم مثل قولهم تشابهت قلوبهم قد بينا الأيات لقوم يوقنون"
    },
    {
      "surah_number": 2,
      "verse_number": 119,
      "content": "انا أرسلناك بالحق بشيرا ونذيرا ولا تسٔل عن أصحاب الجحيم"
    },
    {
      "surah_number": 2,
      "verse_number": 120,
      "content": "ولن ترضىا عنك اليهود ولا النصارىا حتىا تتبع ملتهم قل ان هدى الله هو الهدىا ولئن اتبعت أهواهم بعد الذي جاك من العلم ما لك من الله من ولي ولا نصير"
    },
    {
      "surah_number": 2,
      "verse_number": 121,
      "content": "الذين اتيناهم الكتاب يتلونه حق تلاوته أولائك يؤمنون به ومن يكفر به فأولائك هم الخاسرون"
    },
    {
      "surah_number": 2,
      "verse_number": 122,
      "content": "يابني اسرايل اذكروا نعمتي التي أنعمت عليكم وأني فضلتكم على العالمين"
    },
    {
      "surah_number": 2,
      "verse_number": 123,
      "content": "واتقوا يوما لا تجزي نفس عن نفس شئا ولا يقبل منها عدل ولا تنفعها شفاعه ولا هم ينصرون"
    },
    {
      "surah_number": 2,
      "verse_number": 124,
      "content": "واذ ابتلىا ابراهم ربه بكلمات فأتمهن قال اني جاعلك للناس اماما قال ومن ذريتي قال لا ينال عهدي الظالمين"
    },
    {
      "surah_number": 2,
      "verse_number": 125,
      "content": "واذ جعلنا البيت مثابه للناس وأمنا واتخذوا من مقام ابراهم مصلى وعهدنا الىا ابراهم واسماعيل أن طهرا بيتي للطائفين والعاكفين والركع السجود"
    },
    {
      "surah_number": 2,
      "verse_number": 126,
      "content": "واذ قال ابراهم رب اجعل هاذا بلدا امنا وارزق أهله من الثمرات من امن منهم بالله واليوم الأخر قال ومن كفر فأمتعه قليلا ثم أضطره الىا عذاب النار وبئس المصير"
    },
    {
      "surah_number": 2,
      "verse_number": 127,
      "content": "واذ يرفع ابراهم القواعد من البيت واسماعيل ربنا تقبل منا انك أنت السميع العليم"
    },
    {
      "surah_number": 2,
      "verse_number": 128,
      "content": "ربنا واجعلنا مسلمين لك ومن ذريتنا أمه مسلمه لك وأرنا مناسكنا وتب علينا انك أنت التواب الرحيم"
    },
    {
      "surah_number": 2,
      "verse_number": 129,
      "content": "ربنا وابعث فيهم رسولا منهم يتلوا عليهم اياتك ويعلمهم الكتاب والحكمه ويزكيهم انك أنت العزيز الحكيم"
    },
    {
      "surah_number": 2,
      "verse_number": 130,
      "content": "ومن يرغب عن مله ابراهم الا من سفه نفسه ولقد اصطفيناه في الدنيا وانه في الأخره لمن الصالحين"
    },
    {
      "surah_number": 2,
      "verse_number": 131,
      "content": "اذ قال له ربه أسلم قال أسلمت لرب العالمين"
    },
    {
      "surah_number": 2,
      "verse_number": 132,
      "content": "ووصىا بها ابراهم بنيه ويعقوب يابني ان الله اصطفىا لكم الدين فلا تموتن الا وأنتم مسلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 133,
      "content": "أم كنتم شهدا اذ حضر يعقوب الموت اذ قال لبنيه ما تعبدون من بعدي قالوا نعبد الاهك والاه ابائك ابراهم واسماعيل واسحاق الاها واحدا ونحن له مسلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 134,
      "content": "تلك أمه قد خلت لها ما كسبت ولكم ما كسبتم ولا تسٔلون عما كانوا يعملون"
    },
    {
      "surah_number": 2,
      "verse_number": 135,
      "content": "وقالوا كونوا هودا أو نصارىا تهتدوا قل بل مله ابراهم حنيفا وما كان من المشركين"
    },
    {
      "surah_number": 2,
      "verse_number": 136,
      "content": "قولوا امنا بالله وما أنزل الينا وما أنزل الىا ابراهم واسماعيل واسحاق ويعقوب والأسباط وما أوتي موسىا وعيسىا وما أوتي النبيون من ربهم لا نفرق بين أحد منهم ونحن له مسلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 137,
      "content": "فان امنوا بمثل ما امنتم به فقد اهتدوا وان تولوا فانما هم في شقاق فسيكفيكهم الله وهو السميع العليم"
    },
    {
      "surah_number": 2,
      "verse_number": 138,
      "content": "صبغه الله ومن أحسن من الله صبغه ونحن له عابدون"
    },
    {
      "surah_number": 2,
      "verse_number": 139,
      "content": "قل أتحاجوننا في الله وهو ربنا وربكم ولنا أعمالنا ولكم أعمالكم ونحن له مخلصون"
    },
    {
      "surah_number": 2,
      "verse_number": 140,
      "content": "أم تقولون ان ابراهم واسماعيل واسحاق ويعقوب والأسباط كانوا هودا أو نصارىا قل ءأنتم أعلم أم الله ومن أظلم ممن كتم شهاده عنده من الله وما الله بغافل عما تعملون"
    },
    {
      "surah_number": 2,
      "verse_number": 141,
      "content": "تلك أمه قد خلت لها ما كسبت ولكم ما كسبتم ولا تسٔلون عما كانوا يعملون"
    },
    {
      "surah_number": 2,
      "verse_number": 142,
      "content": "سيقول السفها من الناس ما ولىاهم عن قبلتهم التي كانوا عليها قل لله المشرق والمغرب يهدي من يشا الىا صراط مستقيم"
    },
    {
      "surah_number": 2,
      "verse_number": 143,
      "content": "وكذالك جعلناكم أمه وسطا لتكونوا شهدا على الناس ويكون الرسول عليكم شهيدا وما جعلنا القبله التي كنت عليها الا لنعلم من يتبع الرسول ممن ينقلب علىا عقبيه وان كانت لكبيره الا على الذين هدى الله وما كان الله ليضيع ايمانكم ان الله بالناس لروف رحيم"
    },
    {
      "surah_number": 2,
      "verse_number": 144,
      "content": "قد نرىا تقلب وجهك في السما فلنولينك قبله ترضىاها فول وجهك شطر المسجد الحرام وحيث ما كنتم فولوا وجوهكم شطره وان الذين أوتوا الكتاب ليعلمون أنه الحق من ربهم وما الله بغافل عما يعملون"
    },
    {
      "surah_number": 2,
      "verse_number": 145,
      "content": "ولئن أتيت الذين أوتوا الكتاب بكل ايه ما تبعوا قبلتك وما أنت بتابع قبلتهم وما بعضهم بتابع قبله بعض ولئن اتبعت أهواهم من بعد ما جاك من العلم انك اذا لمن الظالمين"
    },
    {
      "surah_number": 2,
      "verse_number": 146,
      "content": "الذين اتيناهم الكتاب يعرفونه كما يعرفون أبناهم وان فريقا منهم ليكتمون الحق وهم يعلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 147,
      "content": "الحق من ربك فلا تكونن من الممترين"
    },
    {
      "surah_number": 2,
      "verse_number": 148,
      "content": "ولكل وجهه هو موليها فاستبقوا الخيرات أين ما تكونوا يأت بكم الله جميعا ان الله علىا كل شي قدير"
    },
    {
      "surah_number": 2,
      "verse_number": 149,
      "content": "ومن حيث خرجت فول وجهك شطر المسجد الحرام وانه للحق من ربك وما الله بغافل عما تعملون"
    },
    {
      "surah_number": 2,
      "verse_number": 150,
      "content": "ومن حيث خرجت فول وجهك شطر المسجد الحرام وحيث ما كنتم فولوا وجوهكم شطره لئلا يكون للناس عليكم حجه الا الذين ظلموا منهم فلا تخشوهم واخشوني ولأتم نعمتي عليكم ولعلكم تهتدون"
    },
    {
      "surah_number": 2,
      "verse_number": 151,
      "content": "كما أرسلنا فيكم رسولا منكم يتلوا عليكم اياتنا ويزكيكم ويعلمكم الكتاب والحكمه ويعلمكم ما لم تكونوا تعلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 152,
      "content": "فاذكروني أذكركم واشكروا لي ولا تكفرون"
    },
    {
      "surah_number": 2,
      "verse_number": 153,
      "content": "ياأيها الذين امنوا استعينوا بالصبر والصلواه ان الله مع الصابرين"
    },
    {
      "surah_number": 2,
      "verse_number": 154,
      "content": "ولا تقولوا لمن يقتل في سبيل الله أموات بل أحيا ولاكن لا تشعرون"
    },
    {
      "surah_number": 2,
      "verse_number": 155,
      "content": "ولنبلونكم بشي من الخوف والجوع ونقص من الأموال والأنفس والثمرات وبشر الصابرين"
    },
    {
      "surah_number": 2,
      "verse_number": 156,
      "content": "الذين اذا أصابتهم مصيبه قالوا انا لله وانا اليه راجعون"
    },
    {
      "surah_number": 2,
      "verse_number": 157,
      "content": "أولائك عليهم صلوات من ربهم ورحمه وأولائك هم المهتدون"
    },
    {
      "surah_number": 2,
      "verse_number": 158,
      "content": "ان الصفا والمروه من شعائر الله فمن حج البيت أو اعتمر فلا جناح عليه أن يطوف بهما ومن تطوع خيرا فان الله شاكر عليم"
    },
    {
      "surah_number": 2,
      "verse_number": 159,
      "content": "ان الذين يكتمون ما أنزلنا من البينات والهدىا من بعد ما بيناه للناس في الكتاب أولائك يلعنهم الله ويلعنهم اللاعنون"
    },
    {
      "surah_number": 2,
      "verse_number": 160,
      "content": "الا الذين تابوا وأصلحوا وبينوا فأولائك أتوب عليهم وأنا التواب الرحيم"
    },
    {
      "surah_number": 2,
      "verse_number": 161,
      "content": "ان الذين كفروا وماتوا وهم كفار أولائك عليهم لعنه الله والملائكه والناس أجمعين"
    },
    {
      "surah_number": 2,
      "verse_number": 162,
      "content": "خالدين فيها لا يخفف عنهم العذاب ولا هم ينظرون"
    },
    {
      "surah_number": 2,
      "verse_number": 163,
      "content": "والاهكم الاه واحد لا الاه الا هو الرحمان الرحيم"
    },
    {
      "surah_number": 2,
      "verse_number": 164,
      "content": "ان في خلق السماوات والأرض واختلاف اليل والنهار والفلك التي تجري في البحر بما ينفع الناس وما أنزل الله من السما من ما فأحيا به الأرض بعد موتها وبث فيها من كل دابه وتصريف الرياح والسحاب المسخر بين السما والأرض لأيات لقوم يعقلون"
    },
    {
      "surah_number": 2,
      "verse_number": 165,
      "content": "ومن الناس من يتخذ من دون الله أندادا يحبونهم كحب الله والذين امنوا أشد حبا لله ولو يرى الذين ظلموا اذ يرون العذاب أن القوه لله جميعا وأن الله شديد العذاب"
    },
    {
      "surah_number": 2,
      "verse_number": 166,
      "content": "اذ تبرأ الذين اتبعوا من الذين اتبعوا ورأوا العذاب وتقطعت بهم الأسباب"
    },
    {
      "surah_number": 2,
      "verse_number": 167,
      "content": "وقال الذين اتبعوا لو أن لنا كره فنتبرأ منهم كما تبروا منا كذالك يريهم الله أعمالهم حسرات عليهم وما هم بخارجين من النار"
    },
    {
      "surah_number": 2,
      "verse_number": 168,
      "content": "ياأيها الناس كلوا مما في الأرض حلالا طيبا ولا تتبعوا خطوات الشيطان انه لكم عدو مبين"
    },
    {
      "surah_number": 2,
      "verse_number": 169,
      "content": "انما يأمركم بالسو والفحشا وأن تقولوا على الله ما لا تعلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 170,
      "content": "واذا قيل لهم اتبعوا ما أنزل الله قالوا بل نتبع ما ألفينا عليه ابانا أولو كان اباؤهم لا يعقلون شئا ولا يهتدون"
    },
    {
      "surah_number": 2,
      "verse_number": 171,
      "content": "ومثل الذين كفروا كمثل الذي ينعق بما لا يسمع الا دعا وندا صم بكم عمي فهم لا يعقلون"
    },
    {
      "surah_number": 2,
      "verse_number": 172,
      "content": "ياأيها الذين امنوا كلوا من طيبات ما رزقناكم واشكروا لله ان كنتم اياه تعبدون"
    },
    {
      "surah_number": 2,
      "verse_number": 173,
      "content": "انما حرم عليكم الميته والدم ولحم الخنزير وما أهل به لغير الله فمن اضطر غير باغ ولا عاد فلا اثم عليه ان الله غفور رحيم"
    },
    {
      "surah_number": 2,
      "verse_number": 174,
      "content": "ان الذين يكتمون ما أنزل الله من الكتاب ويشترون به ثمنا قليلا أولائك ما يأكلون في بطونهم الا النار ولا يكلمهم الله يوم القيامه ولا يزكيهم ولهم عذاب أليم"
    },
    {
      "surah_number": 2,
      "verse_number": 175,
      "content": "أولائك الذين اشتروا الضلاله بالهدىا والعذاب بالمغفره فما أصبرهم على النار"
    },
    {
      "surah_number": 2,
      "verse_number": 176,
      "content": "ذالك بأن الله نزل الكتاب بالحق وان الذين اختلفوا في الكتاب لفي شقاق بعيد"
    },
    {
      "surah_number": 2,
      "verse_number": 177,
      "content": "ليس البر أن تولوا وجوهكم قبل المشرق والمغرب ولاكن البر من امن بالله واليوم الأخر والملائكه والكتاب والنبين واتى المال علىا حبه ذوي القربىا واليتامىا والمساكين وابن السبيل والسائلين وفي الرقاب وأقام الصلواه واتى الزكواه والموفون بعهدهم اذا عاهدوا والصابرين في البأسا والضرا وحين البأس أولائك الذين صدقوا وأولائك هم المتقون"
    },
    {
      "surah_number": 2,
      "verse_number": 178,
      "content": "ياأيها الذين امنوا كتب عليكم القصاص في القتلى الحر بالحر والعبد بالعبد والأنثىا بالأنثىا فمن عفي له من أخيه شي فاتباع بالمعروف وأدا اليه باحسان ذالك تخفيف من ربكم ورحمه فمن اعتدىا بعد ذالك فله عذاب أليم"
    },
    {
      "surah_number": 2,
      "verse_number": 179,
      "content": "ولكم في القصاص حيواه ياأولي الألباب لعلكم تتقون"
    },
    {
      "surah_number": 2,
      "verse_number": 180,
      "content": "كتب عليكم اذا حضر أحدكم الموت ان ترك خيرا الوصيه للوالدين والأقربين بالمعروف حقا على المتقين"
    },
    {
      "surah_number": 2,
      "verse_number": 181,
      "content": "فمن بدله بعد ما سمعه فانما اثمه على الذين يبدلونه ان الله سميع عليم"
    },
    {
      "surah_number": 2,
      "verse_number": 182,
      "content": "فمن خاف من موص جنفا أو اثما فأصلح بينهم فلا اثم عليه ان الله غفور رحيم"
    },
    {
      "surah_number": 2,
      "verse_number": 183,
      "content": "ياأيها الذين امنوا كتب عليكم الصيام كما كتب على الذين من قبلكم لعلكم تتقون"
    },
    {
      "surah_number": 2,
      "verse_number": 184,
      "content": "أياما معدودات فمن كان منكم مريضا أو علىا سفر فعده من أيام أخر وعلى الذين يطيقونه فديه طعام مسكين فمن تطوع خيرا فهو خير له وأن تصوموا خير لكم ان كنتم تعلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 185,
      "content": "شهر رمضان الذي أنزل فيه القران هدى للناس وبينات من الهدىا والفرقان فمن شهد منكم الشهر فليصمه ومن كان مريضا أو علىا سفر فعده من أيام أخر يريد الله بكم اليسر ولا يريد بكم العسر ولتكملوا العده ولتكبروا الله علىا ما هدىاكم ولعلكم تشكرون"
    },
    {
      "surah_number": 2,
      "verse_number": 186,
      "content": "واذا سألك عبادي عني فاني قريب أجيب دعوه الداع اذا دعان فليستجيبوا لي وليؤمنوا بي لعلهم يرشدون"
    },
    {
      "surah_number": 2,
      "verse_number": 187,
      "content": "أحل لكم ليله الصيام الرفث الىا نسائكم هن لباس لكم وأنتم لباس لهن علم الله أنكم كنتم تختانون أنفسكم فتاب عليكم وعفا عنكم فالٔان باشروهن وابتغوا ما كتب الله لكم وكلوا واشربوا حتىا يتبين لكم الخيط الأبيض من الخيط الأسود من الفجر ثم أتموا الصيام الى اليل ولا تباشروهن وأنتم عاكفون في المساجد تلك حدود الله فلا تقربوها كذالك يبين الله اياته للناس لعلهم يتقون"
    },
    {
      "surah_number": 2,
      "verse_number": 188,
      "content": "ولا تأكلوا أموالكم بينكم بالباطل وتدلوا بها الى الحكام لتأكلوا فريقا من أموال الناس بالاثم وأنتم تعلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 189,
      "content": "يسٔلونك عن الأهله قل هي مواقيت للناس والحج وليس البر بأن تأتوا البيوت من ظهورها ولاكن البر من اتقىا وأتوا البيوت من أبوابها واتقوا الله لعلكم تفلحون"
    },
    {
      "surah_number": 2,
      "verse_number": 190,
      "content": "وقاتلوا في سبيل الله الذين يقاتلونكم ولا تعتدوا ان الله لا يحب المعتدين"
    },
    {
      "surah_number": 2,
      "verse_number": 191,
      "content": "واقتلوهم حيث ثقفتموهم وأخرجوهم من حيث أخرجوكم والفتنه أشد من القتل ولا تقاتلوهم عند المسجد الحرام حتىا يقاتلوكم فيه فان قاتلوكم فاقتلوهم كذالك جزا الكافرين"
    },
    {
      "surah_number": 2,
      "verse_number": 192,
      "content": "فان انتهوا فان الله غفور رحيم"
    },
    {
      "surah_number": 2,
      "verse_number": 193,
      "content": "وقاتلوهم حتىا لا تكون فتنه ويكون الدين لله فان انتهوا فلا عدوان الا على الظالمين"
    },
    {
      "surah_number": 2,
      "verse_number": 194,
      "content": "الشهر الحرام بالشهر الحرام والحرمات قصاص فمن اعتدىا عليكم فاعتدوا عليه بمثل ما اعتدىا عليكم واتقوا الله واعلموا أن الله مع المتقين"
    },
    {
      "surah_number": 2,
      "verse_number": 195,
      "content": "وأنفقوا في سبيل الله ولا تلقوا بأيديكم الى التهلكه وأحسنوا ان الله يحب المحسنين"
    },
    {
      "surah_number": 2,
      "verse_number": 196,
      "content": "وأتموا الحج والعمره لله فان أحصرتم فما استيسر من الهدي ولا تحلقوا روسكم حتىا يبلغ الهدي محله فمن كان منكم مريضا أو به أذى من رأسه ففديه من صيام أو صدقه أو نسك فاذا أمنتم فمن تمتع بالعمره الى الحج فما استيسر من الهدي فمن لم يجد فصيام ثلاثه أيام في الحج وسبعه اذا رجعتم تلك عشره كامله ذالك لمن لم يكن أهله حاضري المسجد الحرام واتقوا الله واعلموا أن الله شديد العقاب"
    },
    {
      "surah_number": 2,
      "verse_number": 197,
      "content": "الحج أشهر معلومات فمن فرض فيهن الحج فلا رفث ولا فسوق ولا جدال في الحج وما تفعلوا من خير يعلمه الله وتزودوا فان خير الزاد التقوىا واتقون ياأولي الألباب"
    },
    {
      "surah_number": 2,
      "verse_number": 198,
      "content": "ليس عليكم جناح أن تبتغوا فضلا من ربكم فاذا أفضتم من عرفات فاذكروا الله عند المشعر الحرام واذكروه كما هدىاكم وان كنتم من قبله لمن الضالين"
    },
    {
      "surah_number": 2,
      "verse_number": 199,
      "content": "ثم أفيضوا من حيث أفاض الناس واستغفروا الله ان الله غفور رحيم"
    },
    {
      "surah_number": 2,
      "verse_number": 200,
      "content": "فاذا قضيتم مناسككم فاذكروا الله كذكركم اباكم أو أشد ذكرا فمن الناس من يقول ربنا اتنا في الدنيا وما له في الأخره من خلاق"
    },
    {
      "surah_number": 2,
      "verse_number": 201,
      "content": "ومنهم من يقول ربنا اتنا في الدنيا حسنه وفي الأخره حسنه وقنا عذاب النار"
    },
    {
      "surah_number": 2,
      "verse_number": 202,
      "content": "أولائك لهم نصيب مما كسبوا والله سريع الحساب"
    },
    {
      "surah_number": 2,
      "verse_number": 203,
      "content": "واذكروا الله في أيام معدودات فمن تعجل في يومين فلا اثم عليه ومن تأخر فلا اثم عليه لمن اتقىا واتقوا الله واعلموا أنكم اليه تحشرون"
    },
    {
      "surah_number": 2,
      "verse_number": 204,
      "content": "ومن الناس من يعجبك قوله في الحيواه الدنيا ويشهد الله علىا ما في قلبه وهو ألد الخصام"
    },
    {
      "surah_number": 2,
      "verse_number": 205,
      "content": "واذا تولىا سعىا في الأرض ليفسد فيها ويهلك الحرث والنسل والله لا يحب الفساد"
    },
    {
      "surah_number": 2,
      "verse_number": 206,
      "content": "واذا قيل له اتق الله أخذته العزه بالاثم فحسبه جهنم ولبئس المهاد"
    },
    {
      "surah_number": 2,
      "verse_number": 207,
      "content": "ومن الناس من يشري نفسه ابتغا مرضات الله والله روف بالعباد"
    },
    {
      "surah_number": 2,
      "verse_number": 208,
      "content": "ياأيها الذين امنوا ادخلوا في السلم كافه ولا تتبعوا خطوات الشيطان انه لكم عدو مبين"
    },
    {
      "surah_number": 2,
      "verse_number": 209,
      "content": "فان زللتم من بعد ما جاتكم البينات فاعلموا أن الله عزيز حكيم"
    },
    {
      "surah_number": 2,
      "verse_number": 210,
      "content": "هل ينظرون الا أن يأتيهم الله في ظلل من الغمام والملائكه وقضي الأمر والى الله ترجع الأمور"
    },
    {
      "surah_number": 2,
      "verse_number": 211,
      "content": "سل بني اسرايل كم اتيناهم من ايه بينه ومن يبدل نعمه الله من بعد ما جاته فان الله شديد العقاب"
    },
    {
      "surah_number": 2,
      "verse_number": 212,
      "content": "زين للذين كفروا الحيواه الدنيا ويسخرون من الذين امنوا والذين اتقوا فوقهم يوم القيامه والله يرزق من يشا بغير حساب"
    },
    {
      "surah_number": 2,
      "verse_number": 213,
      "content": "كان الناس أمه واحده فبعث الله النبين مبشرين ومنذرين وأنزل معهم الكتاب بالحق ليحكم بين الناس فيما اختلفوا فيه وما اختلف فيه الا الذين أوتوه من بعد ما جاتهم البينات بغيا بينهم فهدى الله الذين امنوا لما اختلفوا فيه من الحق باذنه والله يهدي من يشا الىا صراط مستقيم"
    },
    {
      "surah_number": 2,
      "verse_number": 214,
      "content": "أم حسبتم أن تدخلوا الجنه ولما يأتكم مثل الذين خلوا من قبلكم مستهم البأسا والضرا وزلزلوا حتىا يقول الرسول والذين امنوا معه متىا نصر الله ألا ان نصر الله قريب"
    },
    {
      "surah_number": 2,
      "verse_number": 215,
      "content": "يسٔلونك ماذا ينفقون قل ما أنفقتم من خير فللوالدين والأقربين واليتامىا والمساكين وابن السبيل وما تفعلوا من خير فان الله به عليم"
    },
    {
      "surah_number": 2,
      "verse_number": 216,
      "content": "كتب عليكم القتال وهو كره لكم وعسىا أن تكرهوا شئا وهو خير لكم وعسىا أن تحبوا شئا وهو شر لكم والله يعلم وأنتم لا تعلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 217,
      "content": "يسٔلونك عن الشهر الحرام قتال فيه قل قتال فيه كبير وصد عن سبيل الله وكفر به والمسجد الحرام واخراج أهله منه أكبر عند الله والفتنه أكبر من القتل ولا يزالون يقاتلونكم حتىا يردوكم عن دينكم ان استطاعوا ومن يرتدد منكم عن دينه فيمت وهو كافر فأولائك حبطت أعمالهم في الدنيا والأخره وأولائك أصحاب النار هم فيها خالدون"
    },
    {
      "surah_number": 2,
      "verse_number": 218,
      "content": "ان الذين امنوا والذين هاجروا وجاهدوا في سبيل الله أولائك يرجون رحمت الله والله غفور رحيم"
    },
    {
      "surah_number": 2,
      "verse_number": 219,
      "content": "يسٔلونك عن الخمر والميسر قل فيهما اثم كبير ومنافع للناس واثمهما أكبر من نفعهما ويسٔلونك ماذا ينفقون قل العفو كذالك يبين الله لكم الأيات لعلكم تتفكرون"
    },
    {
      "surah_number": 2,
      "verse_number": 220,
      "content": "في الدنيا والأخره ويسٔلونك عن اليتامىا قل اصلاح لهم خير وان تخالطوهم فاخوانكم والله يعلم المفسد من المصلح ولو شا الله لأعنتكم ان الله عزيز حكيم"
    },
    {
      "surah_number": 2,
      "verse_number": 221,
      "content": "ولا تنكحوا المشركات حتىا يؤمن ولأمه مؤمنه خير من مشركه ولو أعجبتكم ولا تنكحوا المشركين حتىا يؤمنوا ولعبد مؤمن خير من مشرك ولو أعجبكم أولائك يدعون الى النار والله يدعوا الى الجنه والمغفره باذنه ويبين اياته للناس لعلهم يتذكرون"
    },
    {
      "surah_number": 2,
      "verse_number": 222,
      "content": "ويسٔلونك عن المحيض قل هو أذى فاعتزلوا النسا في المحيض ولا تقربوهن حتىا يطهرن فاذا تطهرن فأتوهن من حيث أمركم الله ان الله يحب التوابين ويحب المتطهرين"
    },
    {
      "surah_number": 2,
      "verse_number": 223,
      "content": "نساؤكم حرث لكم فأتوا حرثكم أنىا شئتم وقدموا لأنفسكم واتقوا الله واعلموا أنكم ملاقوه وبشر المؤمنين"
    },
    {
      "surah_number": 2,
      "verse_number": 224,
      "content": "ولا تجعلوا الله عرضه لأيمانكم أن تبروا وتتقوا وتصلحوا بين الناس والله سميع عليم"
    },
    {
      "surah_number": 2,
      "verse_number": 225,
      "content": "لا يؤاخذكم الله باللغو في أيمانكم ولاكن يؤاخذكم بما كسبت قلوبكم والله غفور حليم"
    },
    {
      "surah_number": 2,
      "verse_number": 226,
      "content": "للذين يؤلون من نسائهم تربص أربعه أشهر فان فاو فان الله غفور رحيم"
    },
    {
      "surah_number": 2,
      "verse_number": 227,
      "content": "وان عزموا الطلاق فان الله سميع عليم"
    },
    {
      "surah_number": 2,
      "verse_number": 228,
      "content": "والمطلقات يتربصن بأنفسهن ثلاثه قرو ولا يحل لهن أن يكتمن ما خلق الله في أرحامهن ان كن يؤمن بالله واليوم الأخر وبعولتهن أحق بردهن في ذالك ان أرادوا اصلاحا ولهن مثل الذي عليهن بالمعروف وللرجال عليهن درجه والله عزيز حكيم"
    },
    {
      "surah_number": 2,
      "verse_number": 229,
      "content": "الطلاق مرتان فامساك بمعروف أو تسريح باحسان ولا يحل لكم أن تأخذوا مما اتيتموهن شئا الا أن يخافا ألا يقيما حدود الله فان خفتم ألا يقيما حدود الله فلا جناح عليهما فيما افتدت به تلك حدود الله فلا تعتدوها ومن يتعد حدود الله فأولائك هم الظالمون"
    },
    {
      "surah_number": 2,
      "verse_number": 230,
      "content": "فان طلقها فلا تحل له من بعد حتىا تنكح زوجا غيره فان طلقها فلا جناح عليهما أن يتراجعا ان ظنا أن يقيما حدود الله وتلك حدود الله يبينها لقوم يعلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 231,
      "content": "واذا طلقتم النسا فبلغن أجلهن فأمسكوهن بمعروف أو سرحوهن بمعروف ولا تمسكوهن ضرارا لتعتدوا ومن يفعل ذالك فقد ظلم نفسه ولا تتخذوا ايات الله هزوا واذكروا نعمت الله عليكم وما أنزل عليكم من الكتاب والحكمه يعظكم به واتقوا الله واعلموا أن الله بكل شي عليم"
    },
    {
      "surah_number": 2,
      "verse_number": 232,
      "content": "واذا طلقتم النسا فبلغن أجلهن فلا تعضلوهن أن ينكحن أزواجهن اذا تراضوا بينهم بالمعروف ذالك يوعظ به من كان منكم يؤمن بالله واليوم الأخر ذالكم أزكىا لكم وأطهر والله يعلم وأنتم لا تعلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 233,
      "content": "والوالدات يرضعن أولادهن حولين كاملين لمن أراد أن يتم الرضاعه وعلى المولود له رزقهن وكسوتهن بالمعروف لا تكلف نفس الا وسعها لا تضار والده بولدها ولا مولود له بولده وعلى الوارث مثل ذالك فان أرادا فصالا عن تراض منهما وتشاور فلا جناح عليهما وان أردتم أن تسترضعوا أولادكم فلا جناح عليكم اذا سلمتم ما اتيتم بالمعروف واتقوا الله واعلموا أن الله بما تعملون بصير"
    },
    {
      "surah_number": 2,
      "verse_number": 234,
      "content": "والذين يتوفون منكم ويذرون أزواجا يتربصن بأنفسهن أربعه أشهر وعشرا فاذا بلغن أجلهن فلا جناح عليكم فيما فعلن في أنفسهن بالمعروف والله بما تعملون خبير"
    },
    {
      "surah_number": 2,
      "verse_number": 235,
      "content": "ولا جناح عليكم فيما عرضتم به من خطبه النسا أو أكننتم في أنفسكم علم الله أنكم ستذكرونهن ولاكن لا تواعدوهن سرا الا أن تقولوا قولا معروفا ولا تعزموا عقده النكاح حتىا يبلغ الكتاب أجله واعلموا أن الله يعلم ما في أنفسكم فاحذروه واعلموا أن الله غفور حليم"
    },
    {
      "surah_number": 2,
      "verse_number": 236,
      "content": "لا جناح عليكم ان طلقتم النسا ما لم تمسوهن أو تفرضوا لهن فريضه ومتعوهن على الموسع قدره وعلى المقتر قدره متاعا بالمعروف حقا على المحسنين"
    },
    {
      "surah_number": 2,
      "verse_number": 237,
      "content": "وان طلقتموهن من قبل أن تمسوهن وقد فرضتم لهن فريضه فنصف ما فرضتم الا أن يعفون أو يعفوا الذي بيده عقده النكاح وأن تعفوا أقرب للتقوىا ولا تنسوا الفضل بينكم ان الله بما تعملون بصير"
    },
    {
      "surah_number": 2,
      "verse_number": 238,
      "content": "حافظوا على الصلوات والصلواه الوسطىا وقوموا لله قانتين"
    },
    {
      "surah_number": 2,
      "verse_number": 239,
      "content": "فان خفتم فرجالا أو ركبانا فاذا أمنتم فاذكروا الله كما علمكم ما لم تكونوا تعلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 240,
      "content": "والذين يتوفون منكم ويذرون أزواجا وصيه لأزواجهم متاعا الى الحول غير اخراج فان خرجن فلا جناح عليكم في ما فعلن في أنفسهن من معروف والله عزيز حكيم"
    },
    {
      "surah_number": 2,
      "verse_number": 241,
      "content": "وللمطلقات متاع بالمعروف حقا على المتقين"
    },
    {
      "surah_number": 2,
      "verse_number": 242,
      "content": "كذالك يبين الله لكم اياته لعلكم تعقلون"
    },
    {
      "surah_number": 2,
      "verse_number": 243,
      "content": "ألم تر الى الذين خرجوا من ديارهم وهم ألوف حذر الموت فقال لهم الله موتوا ثم أحياهم ان الله لذو فضل على الناس ولاكن أكثر الناس لا يشكرون"
    },
    {
      "surah_number": 2,
      "verse_number": 244,
      "content": "وقاتلوا في سبيل الله واعلموا أن الله سميع عليم"
    },
    {
      "surah_number": 2,
      "verse_number": 245,
      "content": "من ذا الذي يقرض الله قرضا حسنا فيضاعفه له أضعافا كثيره والله يقبض ويبصط واليه ترجعون"
    },
    {
      "surah_number": 2,
      "verse_number": 246,
      "content": "ألم تر الى الملا من بني اسرايل من بعد موسىا اذ قالوا لنبي لهم ابعث لنا ملكا نقاتل في سبيل الله قال هل عسيتم ان كتب عليكم القتال ألا تقاتلوا قالوا وما لنا ألا نقاتل في سبيل الله وقد أخرجنا من ديارنا وأبنائنا فلما كتب عليهم القتال تولوا الا قليلا منهم والله عليم بالظالمين"
    },
    {
      "surah_number": 2,
      "verse_number": 247,
      "content": "وقال لهم نبيهم ان الله قد بعث لكم طالوت ملكا قالوا أنىا يكون له الملك علينا ونحن أحق بالملك منه ولم يؤت سعه من المال قال ان الله اصطفىاه عليكم وزاده بسطه في العلم والجسم والله يؤتي ملكه من يشا والله واسع عليم"
    },
    {
      "surah_number": 2,
      "verse_number": 248,
      "content": "وقال لهم نبيهم ان ايه ملكه أن يأتيكم التابوت فيه سكينه من ربكم وبقيه مما ترك ال موسىا وال هارون تحمله الملائكه ان في ذالك لأيه لكم ان كنتم مؤمنين"
    },
    {
      "surah_number": 2,
      "verse_number": 249,
      "content": "فلما فصل طالوت بالجنود قال ان الله مبتليكم بنهر فمن شرب منه فليس مني ومن لم يطعمه فانه مني الا من اغترف غرفه بيده فشربوا منه الا قليلا منهم فلما جاوزه هو والذين امنوا معه قالوا لا طاقه لنا اليوم بجالوت وجنوده قال الذين يظنون أنهم ملاقوا الله كم من فئه قليله غلبت فئه كثيره باذن الله والله مع الصابرين"
    },
    {
      "surah_number": 2,
      "verse_number": 250,
      "content": "ولما برزوا لجالوت وجنوده قالوا ربنا أفرغ علينا صبرا وثبت أقدامنا وانصرنا على القوم الكافرين"
    },
    {
      "surah_number": 2,
      "verse_number": 251,
      "content": "فهزموهم باذن الله وقتل داود جالوت واتىاه الله الملك والحكمه وعلمه مما يشا ولولا دفع الله الناس بعضهم ببعض لفسدت الأرض ولاكن الله ذو فضل على العالمين"
    },
    {
      "surah_number": 2,
      "verse_number": 252,
      "content": "تلك ايات الله نتلوها عليك بالحق وانك لمن المرسلين"
    },
    {
      "surah_number": 2,
      "verse_number": 253,
      "content": "تلك الرسل فضلنا بعضهم علىا بعض منهم من كلم الله ورفع بعضهم درجات واتينا عيسى ابن مريم البينات وأيدناه بروح القدس ولو شا الله ما اقتتل الذين من بعدهم من بعد ما جاتهم البينات ولاكن اختلفوا فمنهم من امن ومنهم من كفر ولو شا الله ما اقتتلوا ولاكن الله يفعل ما يريد"
    },
    {
      "surah_number": 2,
      "verse_number": 254,
      "content": "ياأيها الذين امنوا أنفقوا مما رزقناكم من قبل أن يأتي يوم لا بيع فيه ولا خله ولا شفاعه والكافرون هم الظالمون"
    },
    {
      "surah_number": 2,
      "verse_number": 255,
      "content": "الله لا الاه الا هو الحي القيوم لا تأخذه سنه ولا نوم له ما في السماوات وما في الأرض من ذا الذي يشفع عنده الا باذنه يعلم ما بين أيديهم وما خلفهم ولا يحيطون بشي من علمه الا بما شا وسع كرسيه السماوات والأرض ولا ئوده حفظهما وهو العلي العظيم"
    },
    {
      "surah_number": 2,
      "verse_number": 256,
      "content": "لا اكراه في الدين قد تبين الرشد من الغي فمن يكفر بالطاغوت ويؤمن بالله فقد استمسك بالعروه الوثقىا لا انفصام لها والله سميع عليم"
    },
    {
      "surah_number": 2,
      "verse_number": 257,
      "content": "الله ولي الذين امنوا يخرجهم من الظلمات الى النور والذين كفروا أولياؤهم الطاغوت يخرجونهم من النور الى الظلمات أولائك أصحاب النار هم فيها خالدون"
    },
    {
      "surah_number": 2,
      "verse_number": 258,
      "content": "ألم تر الى الذي حاج ابراهم في ربه أن اتىاه الله الملك اذ قال ابراهم ربي الذي يحي ويميت قال أنا أحي وأميت قال ابراهم فان الله يأتي بالشمس من المشرق فأت بها من المغرب فبهت الذي كفر والله لا يهدي القوم الظالمين"
    },
    {
      "surah_number": 2,
      "verse_number": 259,
      "content": "أو كالذي مر علىا قريه وهي خاويه علىا عروشها قال أنىا يحي هاذه الله بعد موتها فأماته الله مائه عام ثم بعثه قال كم لبثت قال لبثت يوما أو بعض يوم قال بل لبثت مائه عام فانظر الىا طعامك وشرابك لم يتسنه وانظر الىا حمارك ولنجعلك ايه للناس وانظر الى العظام كيف ننشزها ثم نكسوها لحما فلما تبين له قال أعلم أن الله علىا كل شي قدير"
    },
    {
      "surah_number": 2,
      "verse_number": 260,
      "content": "واذ قال ابراهم رب أرني كيف تحي الموتىا قال أولم تؤمن قال بلىا ولاكن ليطمئن قلبي قال فخذ أربعه من الطير فصرهن اليك ثم اجعل علىا كل جبل منهن جزا ثم ادعهن يأتينك سعيا واعلم أن الله عزيز حكيم"
    },
    {
      "surah_number": 2,
      "verse_number": 261,
      "content": "مثل الذين ينفقون أموالهم في سبيل الله كمثل حبه أنبتت سبع سنابل في كل سنبله مائه حبه والله يضاعف لمن يشا والله واسع عليم"
    },
    {
      "surah_number": 2,
      "verse_number": 262,
      "content": "الذين ينفقون أموالهم في سبيل الله ثم لا يتبعون ما أنفقوا منا ولا أذى لهم أجرهم عند ربهم ولا خوف عليهم ولا هم يحزنون"
    },
    {
      "surah_number": 2,
      "verse_number": 263,
      "content": "قول معروف ومغفره خير من صدقه يتبعها أذى والله غني حليم"
    },
    {
      "surah_number": 2,
      "verse_number": 264,
      "content": "ياأيها الذين امنوا لا تبطلوا صدقاتكم بالمن والأذىا كالذي ينفق ماله رئا الناس ولا يؤمن بالله واليوم الأخر فمثله كمثل صفوان عليه تراب فأصابه وابل فتركه صلدا لا يقدرون علىا شي مما كسبوا والله لا يهدي القوم الكافرين"
    },
    {
      "surah_number": 2,
      "verse_number": 265,
      "content": "ومثل الذين ينفقون أموالهم ابتغا مرضات الله وتثبيتا من أنفسهم كمثل جنه بربوه أصابها وابل فٔاتت أكلها ضعفين فان لم يصبها وابل فطل والله بما تعملون بصير"
    },
    {
      "surah_number": 2,
      "verse_number": 266,
      "content": "أيود أحدكم أن تكون له جنه من نخيل وأعناب تجري من تحتها الأنهار له فيها من كل الثمرات وأصابه الكبر وله ذريه ضعفا فأصابها اعصار فيه نار فاحترقت كذالك يبين الله لكم الأيات لعلكم تتفكرون"
    },
    {
      "surah_number": 2,
      "verse_number": 267,
      "content": "ياأيها الذين امنوا أنفقوا من طيبات ما كسبتم ومما أخرجنا لكم من الأرض ولا تيمموا الخبيث منه تنفقون ولستم بٔاخذيه الا أن تغمضوا فيه واعلموا أن الله غني حميد"
    },
    {
      "surah_number": 2,
      "verse_number": 268,
      "content": "الشيطان يعدكم الفقر ويأمركم بالفحشا والله يعدكم مغفره منه وفضلا والله واسع عليم"
    },
    {
      "surah_number": 2,
      "verse_number": 269,
      "content": "يؤتي الحكمه من يشا ومن يؤت الحكمه فقد أوتي خيرا كثيرا وما يذكر الا أولوا الألباب"
    },
    {
      "surah_number": 2,
      "verse_number": 270,
      "content": "وما أنفقتم من نفقه أو نذرتم من نذر فان الله يعلمه وما للظالمين من أنصار"
    },
    {
      "surah_number": 2,
      "verse_number": 271,
      "content": "ان تبدوا الصدقات فنعما هي وان تخفوها وتؤتوها الفقرا فهو خير لكم ويكفر عنكم من سئاتكم والله بما تعملون خبير"
    },
    {
      "surah_number": 2,
      "verse_number": 272,
      "content": "ليس عليك هدىاهم ولاكن الله يهدي من يشا وما تنفقوا من خير فلأنفسكم وما تنفقون الا ابتغا وجه الله وما تنفقوا من خير يوف اليكم وأنتم لا تظلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 273,
      "content": "للفقرا الذين أحصروا في سبيل الله لا يستطيعون ضربا في الأرض يحسبهم الجاهل أغنيا من التعفف تعرفهم بسيماهم لا يسٔلون الناس الحافا وما تنفقوا من خير فان الله به عليم"
    },
    {
      "surah_number": 2,
      "verse_number": 274,
      "content": "الذين ينفقون أموالهم باليل والنهار سرا وعلانيه فلهم أجرهم عند ربهم ولا خوف عليهم ولا هم يحزنون"
    },
    {
      "surah_number": 2,
      "verse_number": 275,
      "content": "الذين يأكلون الربواا لا يقومون الا كما يقوم الذي يتخبطه الشيطان من المس ذالك بأنهم قالوا انما البيع مثل الربواا وأحل الله البيع وحرم الربواا فمن جاه موعظه من ربه فانتهىا فله ما سلف وأمره الى الله ومن عاد فأولائك أصحاب النار هم فيها خالدون"
    },
    {
      "surah_number": 2,
      "verse_number": 276,
      "content": "يمحق الله الربواا ويربي الصدقات والله لا يحب كل كفار أثيم"
    },
    {
      "surah_number": 2,
      "verse_number": 277,
      "content": "ان الذين امنوا وعملوا الصالحات وأقاموا الصلواه واتوا الزكواه لهم أجرهم عند ربهم ولا خوف عليهم ولا هم يحزنون"
    },
    {
      "surah_number": 2,
      "verse_number": 278,
      "content": "ياأيها الذين امنوا اتقوا الله وذروا ما بقي من الربواا ان كنتم مؤمنين"
    },
    {
      "surah_number": 2,
      "verse_number": 279,
      "content": "فان لم تفعلوا فأذنوا بحرب من الله ورسوله وان تبتم فلكم روس أموالكم لا تظلمون ولا تظلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 280,
      "content": "وان كان ذو عسره فنظره الىا ميسره وأن تصدقوا خير لكم ان كنتم تعلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 281,
      "content": "واتقوا يوما ترجعون فيه الى الله ثم توفىا كل نفس ما كسبت وهم لا يظلمون"
    },
    {
      "surah_number": 2,
      "verse_number": 282,
      "content": "ياأيها الذين امنوا اذا تداينتم بدين الىا أجل مسمى فاكتبوه وليكتب بينكم كاتب بالعدل ولا يأب كاتب أن يكتب كما علمه الله فليكتب وليملل الذي عليه الحق وليتق الله ربه ولا يبخس منه شئا فان كان الذي عليه الحق سفيها أو ضعيفا أو لا يستطيع أن يمل هو فليملل وليه بالعدل واستشهدوا شهيدين من رجالكم فان لم يكونا رجلين فرجل وامرأتان ممن ترضون من الشهدا أن تضل احدىاهما فتذكر احدىاهما الأخرىا ولا يأب الشهدا اذا ما دعوا ولا تسٔموا أن تكتبوه صغيرا أو كبيرا الىا أجله ذالكم أقسط عند الله وأقوم للشهاده وأدنىا ألا ترتابوا الا أن تكون تجاره حاضره تديرونها بينكم فليس عليكم جناح ألا تكتبوها وأشهدوا اذا تبايعتم ولا يضار كاتب ولا شهيد وان تفعلوا فانه فسوق بكم واتقوا الله ويعلمكم الله والله بكل شي عليم"
    },
    {
      "surah_number": 2,
      "verse_number": 283,
      "content": "وان كنتم علىا سفر ولم تجدوا كاتبا فرهان مقبوضه فان أمن بعضكم بعضا فليؤد الذي اؤتمن أمانته وليتق الله ربه ولا تكتموا الشهاده ومن يكتمها فانه اثم قلبه والله بما تعملون عليم"
    },
    {
      "surah_number": 2,
      "verse_number": 284,
      "content": "لله ما في السماوات وما في الأرض وان تبدوا ما في أنفسكم أو تخفوه يحاسبكم به الله فيغفر لمن يشا ويعذب من يشا والله علىا كل شي قدير"
    },
    {
      "surah_number": 2,
      "verse_number": 285,
      "content": "امن الرسول بما أنزل اليه من ربه والمؤمنون كل امن بالله وملائكته وكتبه ورسله لا نفرق بين أحد من رسله وقالوا سمعنا وأطعنا غفرانك ربنا واليك المصير"
    },
    {
      "surah_number": 2,
      "verse_number": 286,
      "content": "لا يكلف الله نفسا الا وسعها لها ما كسبت وعليها ما اكتسبت ربنا لا تؤاخذنا ان نسينا أو أخطأنا ربنا ولا تحمل علينا اصرا كما حملته على الذين من قبلنا ربنا ولا تحملنا ما لا طاقه لنا به واعف عنا واغفر لنا وارحمنا أنت مولىانا فانصرنا على القوم الكافرين"
    },
    {
      "surah_number": 3,
      "verse_number": 1,
      "content": "الم"
    },
    {
      "surah_number": 3,
      "verse_number": 2,
      "content": "الله لا الاه الا هو الحي القيوم"
    },
    {
      "surah_number": 3,
      "verse_number": 3,
      "content": "نزل عليك الكتاب بالحق مصدقا لما بين يديه وأنزل التورىاه والانجيل"
    },
    {
      "surah_number": 3,
      "verse_number": 4,
      "content": "من قبل هدى للناس وأنزل الفرقان ان الذين كفروا بٔايات الله لهم عذاب شديد والله عزيز ذو انتقام"
    },
    {
      "surah_number": 3,
      "verse_number": 5,
      "content": "ان الله لا يخفىا عليه شي في الأرض ولا في السما"
    },
    {
      "surah_number": 3,
      "verse_number": 6,
      "content": "هو الذي يصوركم في الأرحام كيف يشا لا الاه الا هو العزيز الحكيم"
    },
    {
      "surah_number": 3,
      "verse_number": 7,
      "content": "هو الذي أنزل عليك الكتاب منه ايات محكمات هن أم الكتاب وأخر متشابهات فأما الذين في قلوبهم زيغ فيتبعون ما تشابه منه ابتغا الفتنه وابتغا تأويله وما يعلم تأويله الا الله والراسخون في العلم يقولون امنا به كل من عند ربنا وما يذكر الا أولوا الألباب"
    },
    {
      "surah_number": 3,
      "verse_number": 8,
      "content": "ربنا لا تزغ قلوبنا بعد اذ هديتنا وهب لنا من لدنك رحمه انك أنت الوهاب"
    },
    {
      "surah_number": 3,
      "verse_number": 9,
      "content": "ربنا انك جامع الناس ليوم لا ريب فيه ان الله لا يخلف الميعاد"
    },
    {
      "surah_number": 3,
      "verse_number": 10,
      "content": "ان الذين كفروا لن تغني عنهم أموالهم ولا أولادهم من الله شئا وأولائك هم وقود النار"
    },
    {
      "surah_number": 3,
      "verse_number": 11,
      "content": "كدأب ال فرعون والذين من قبلهم كذبوا بٔاياتنا فأخذهم الله بذنوبهم والله شديد العقاب"
    },
    {
      "surah_number": 3,
      "verse_number": 12,
      "content": "قل للذين كفروا ستغلبون وتحشرون الىا جهنم وبئس المهاد"
    },
    {
      "surah_number": 3,
      "verse_number": 13,
      "content": "قد كان لكم ايه في فئتين التقتا فئه تقاتل في سبيل الله وأخرىا كافره يرونهم مثليهم رأي العين والله يؤيد بنصره من يشا ان في ذالك لعبره لأولي الأبصار"
    },
    {
      "surah_number": 3,
      "verse_number": 14,
      "content": "زين للناس حب الشهوات من النسا والبنين والقناطير المقنطره من الذهب والفضه والخيل المسومه والأنعام والحرث ذالك متاع الحيواه الدنيا والله عنده حسن المٔاب"
    },
    {
      "surah_number": 3,
      "verse_number": 15,
      "content": "قل أؤنبئكم بخير من ذالكم للذين اتقوا عند ربهم جنات تجري من تحتها الأنهار خالدين فيها وأزواج مطهره ورضوان من الله والله بصير بالعباد"
    },
    {
      "surah_number": 3,
      "verse_number": 16,
      "content": "الذين يقولون ربنا اننا امنا فاغفر لنا ذنوبنا وقنا عذاب النار"
    },
    {
      "surah_number": 3,
      "verse_number": 17,
      "content": "الصابرين والصادقين والقانتين والمنفقين والمستغفرين بالأسحار"
    },
    {
      "surah_number": 3,
      "verse_number": 18,
      "content": "شهد الله أنه لا الاه الا هو والملائكه وأولوا العلم قائما بالقسط لا الاه الا هو العزيز الحكيم"
    },
    {
      "surah_number": 3,
      "verse_number": 19,
      "content": "ان الدين عند الله الاسلام وما اختلف الذين أوتوا الكتاب الا من بعد ما جاهم العلم بغيا بينهم ومن يكفر بٔايات الله فان الله سريع الحساب"
    },
    {
      "surah_number": 3,
      "verse_number": 20,
      "content": "فان حاجوك فقل أسلمت وجهي لله ومن اتبعن وقل للذين أوتوا الكتاب والأمين ءأسلمتم فان أسلموا فقد اهتدوا وان تولوا فانما عليك البلاغ والله بصير بالعباد"
    },
    {
      "surah_number": 3,
      "verse_number": 21,
      "content": "ان الذين يكفرون بٔايات الله ويقتلون النبين بغير حق ويقتلون الذين يأمرون بالقسط من الناس فبشرهم بعذاب أليم"
    },
    {
      "surah_number": 3,
      "verse_number": 22,
      "content": "أولائك الذين حبطت أعمالهم في الدنيا والأخره وما لهم من ناصرين"
    },
    {
      "surah_number": 3,
      "verse_number": 23,
      "content": "ألم تر الى الذين أوتوا نصيبا من الكتاب يدعون الىا كتاب الله ليحكم بينهم ثم يتولىا فريق منهم وهم معرضون"
    },
    {
      "surah_number": 3,
      "verse_number": 24,
      "content": "ذالك بأنهم قالوا لن تمسنا النار الا أياما معدودات وغرهم في دينهم ما كانوا يفترون"
    },
    {
      "surah_number": 3,
      "verse_number": 25,
      "content": "فكيف اذا جمعناهم ليوم لا ريب فيه ووفيت كل نفس ما كسبت وهم لا يظلمون"
    },
    {
      "surah_number": 3,
      "verse_number": 26,
      "content": "قل اللهم مالك الملك تؤتي الملك من تشا وتنزع الملك ممن تشا وتعز من تشا وتذل من تشا بيدك الخير انك علىا كل شي قدير"
    },
    {
      "surah_number": 3,
      "verse_number": 27,
      "content": "تولج اليل في النهار وتولج النهار في اليل وتخرج الحي من الميت وتخرج الميت من الحي وترزق من تشا بغير حساب"
    },
    {
      "surah_number": 3,
      "verse_number": 28,
      "content": "لا يتخذ المؤمنون الكافرين أوليا من دون المؤمنين ومن يفعل ذالك فليس من الله في شي الا أن تتقوا منهم تقىاه ويحذركم الله نفسه والى الله المصير"
    },
    {
      "surah_number": 3,
      "verse_number": 29,
      "content": "قل ان تخفوا ما في صدوركم أو تبدوه يعلمه الله ويعلم ما في السماوات وما في الأرض والله علىا كل شي قدير"
    },
    {
      "surah_number": 3,
      "verse_number": 30,
      "content": "يوم تجد كل نفس ما عملت من خير محضرا وما عملت من سو تود لو أن بينها وبينه أمدا بعيدا ويحذركم الله نفسه والله روف بالعباد"
    },
    {
      "surah_number": 3,
      "verse_number": 31,
      "content": "قل ان كنتم تحبون الله فاتبعوني يحببكم الله ويغفر لكم ذنوبكم والله غفور رحيم"
    },
    {
      "surah_number": 3,
      "verse_number": 32,
      "content": "قل أطيعوا الله والرسول فان تولوا فان الله لا يحب الكافرين"
    },
    {
      "surah_number": 3,
      "verse_number": 33,
      "content": "ان الله اصطفىا ادم ونوحا وال ابراهيم وال عمران على العالمين"
    },
    {
      "surah_number": 3,
      "verse_number": 34,
      "content": "ذريه بعضها من بعض والله سميع عليم"
    },
    {
      "surah_number": 3,
      "verse_number": 35,
      "content": "اذ قالت امرأت عمران رب اني نذرت لك ما في بطني محررا فتقبل مني انك أنت السميع العليم"
    },
    {
      "surah_number": 3,
      "verse_number": 36,
      "content": "فلما وضعتها قالت رب اني وضعتها أنثىا والله أعلم بما وضعت وليس الذكر كالأنثىا واني سميتها مريم واني أعيذها بك وذريتها من الشيطان الرجيم"
    },
    {
      "surah_number": 3,
      "verse_number": 37,
      "content": "فتقبلها ربها بقبول حسن وأنبتها نباتا حسنا وكفلها زكريا كلما دخل عليها زكريا المحراب وجد عندها رزقا قال يامريم أنىا لك هاذا قالت هو من عند الله ان الله يرزق من يشا بغير حساب"
    },
    {
      "surah_number": 3,
      "verse_number": 38,
      "content": "هنالك دعا زكريا ربه قال رب هب لي من لدنك ذريه طيبه انك سميع الدعا"
    },
    {
      "surah_number": 3,
      "verse_number": 39,
      "content": "فنادته الملائكه وهو قائم يصلي في المحراب أن الله يبشرك بيحيىا مصدقا بكلمه من الله وسيدا وحصورا ونبيا من الصالحين"
    },
    {
      "surah_number": 3,
      "verse_number": 40,
      "content": "قال رب أنىا يكون لي غلام وقد بلغني الكبر وامرأتي عاقر قال كذالك الله يفعل ما يشا"
    },
    {
      "surah_number": 3,
      "verse_number": 41,
      "content": "قال رب اجعل لي ايه قال ايتك ألا تكلم الناس ثلاثه أيام الا رمزا واذكر ربك كثيرا وسبح بالعشي والابكار"
    },
    {
      "surah_number": 3,
      "verse_number": 42,
      "content": "واذ قالت الملائكه يامريم ان الله اصطفىاك وطهرك واصطفىاك علىا نسا العالمين"
    },
    {
      "surah_number": 3,
      "verse_number": 43,
      "content": "يامريم اقنتي لربك واسجدي واركعي مع الراكعين"
    },
    {
      "surah_number": 3,
      "verse_number": 44,
      "content": "ذالك من أنبا الغيب نوحيه اليك وما كنت لديهم اذ يلقون أقلامهم أيهم يكفل مريم وما كنت لديهم اذ يختصمون"
    },
    {
      "surah_number": 3,
      "verse_number": 45,
      "content": "اذ قالت الملائكه يامريم ان الله يبشرك بكلمه منه اسمه المسيح عيسى ابن مريم وجيها في الدنيا والأخره ومن المقربين"
    },
    {
      "surah_number": 3,
      "verse_number": 46,
      "content": "ويكلم الناس في المهد وكهلا ومن الصالحين"
    },
    {
      "surah_number": 3,
      "verse_number": 47,
      "content": "قالت رب أنىا يكون لي ولد ولم يمسسني بشر قال كذالك الله يخلق ما يشا اذا قضىا أمرا فانما يقول له كن فيكون"
    },
    {
      "surah_number": 3,
      "verse_number": 48,
      "content": "ويعلمه الكتاب والحكمه والتورىاه والانجيل"
    },
    {
      "surah_number": 3,
      "verse_number": 49,
      "content": "ورسولا الىا بني اسرايل أني قد جئتكم بٔايه من ربكم أني أخلق لكم من الطين كهئه الطير فأنفخ فيه فيكون طيرا باذن الله وأبرئ الأكمه والأبرص وأحي الموتىا باذن الله وأنبئكم بما تأكلون وما تدخرون في بيوتكم ان في ذالك لأيه لكم ان كنتم مؤمنين"
    },
    {
      "surah_number": 3,
      "verse_number": 50,
      "content": "ومصدقا لما بين يدي من التورىاه ولأحل لكم بعض الذي حرم عليكم وجئتكم بٔايه من ربكم فاتقوا الله وأطيعون"
    },
    {
      "surah_number": 3,
      "verse_number": 51,
      "content": "ان الله ربي وربكم فاعبدوه هاذا صراط مستقيم"
    },
    {
      "surah_number": 3,
      "verse_number": 52,
      "content": "فلما أحس عيسىا منهم الكفر قال من أنصاري الى الله قال الحواريون نحن أنصار الله امنا بالله واشهد بأنا مسلمون"
    },
    {
      "surah_number": 3,
      "verse_number": 53,
      "content": "ربنا امنا بما أنزلت واتبعنا الرسول فاكتبنا مع الشاهدين"
    },
    {
      "surah_number": 3,
      "verse_number": 54,
      "content": "ومكروا ومكر الله والله خير الماكرين"
    },
    {
      "surah_number": 3,
      "verse_number": 55,
      "content": "اذ قال الله ياعيسىا اني متوفيك ورافعك الي ومطهرك من الذين كفروا وجاعل الذين اتبعوك فوق الذين كفروا الىا يوم القيامه ثم الي مرجعكم فأحكم بينكم فيما كنتم فيه تختلفون"
    },
    {
      "surah_number": 3,
      "verse_number": 56,
      "content": "فأما الذين كفروا فأعذبهم عذابا شديدا في الدنيا والأخره وما لهم من ناصرين"
    },
    {
      "surah_number": 3,
      "verse_number": 57,
      "content": "وأما الذين امنوا وعملوا الصالحات فيوفيهم أجورهم والله لا يحب الظالمين"
    },
    {
      "surah_number": 3,
      "verse_number": 58,
      "content": "ذالك نتلوه عليك من الأيات والذكر الحكيم"
    },
    {
      "surah_number": 3,
      "verse_number": 59,
      "content": "ان مثل عيسىا عند الله كمثل ادم خلقه من تراب ثم قال له كن فيكون"
    },
    {
      "surah_number": 3,
      "verse_number": 60,
      "content": "الحق من ربك فلا تكن من الممترين"
    },
    {
      "surah_number": 3,
      "verse_number": 61,
      "content": "فمن حاجك فيه من بعد ما جاك من العلم فقل تعالوا ندع أبنانا وأبناكم ونسانا ونساكم وأنفسنا وأنفسكم ثم نبتهل فنجعل لعنت الله على الكاذبين"
    },
    {
      "surah_number": 3,
      "verse_number": 62,
      "content": "ان هاذا لهو القصص الحق وما من الاه الا الله وان الله لهو العزيز الحكيم"
    },
    {
      "surah_number": 3,
      "verse_number": 63,
      "content": "فان تولوا فان الله عليم بالمفسدين"
    },
    {
      "surah_number": 3,
      "verse_number": 64,
      "content": "قل ياأهل الكتاب تعالوا الىا كلمه سوا بيننا وبينكم ألا نعبد الا الله ولا نشرك به شئا ولا يتخذ بعضنا بعضا أربابا من دون الله فان تولوا فقولوا اشهدوا بأنا مسلمون"
    },
    {
      "surah_number": 3,
      "verse_number": 65,
      "content": "ياأهل الكتاب لم تحاجون في ابراهيم وما أنزلت التورىاه والانجيل الا من بعده أفلا تعقلون"
    },
    {
      "surah_number": 3,
      "verse_number": 66,
      "content": "هاأنتم هاؤلا حاججتم فيما لكم به علم فلم تحاجون فيما ليس لكم به علم والله يعلم وأنتم لا تعلمون"
    },
    {
      "surah_number": 3,
      "verse_number": 67,
      "content": "ما كان ابراهيم يهوديا ولا نصرانيا ولاكن كان حنيفا مسلما وما كان من المشركين"
    },
    {
      "surah_number": 3,
      "verse_number": 68,
      "content": "ان أولى الناس بابراهيم للذين اتبعوه وهاذا النبي والذين امنوا والله ولي المؤمنين"
    },
    {
      "surah_number": 3,
      "verse_number": 69,
      "content": "ودت طائفه من أهل الكتاب لو يضلونكم وما يضلون الا أنفسهم وما يشعرون"
    },
    {
      "surah_number": 3,
      "verse_number": 70,
      "content": "ياأهل الكتاب لم تكفرون بٔايات الله وأنتم تشهدون"
    },
    {
      "surah_number": 3,
      "verse_number": 71,
      "content": "ياأهل الكتاب لم تلبسون الحق بالباطل وتكتمون الحق وأنتم تعلمون"
    },
    {
      "surah_number": 3,
      "verse_number": 72,
      "content": "وقالت طائفه من أهل الكتاب امنوا بالذي أنزل على الذين امنوا وجه النهار واكفروا اخره لعلهم يرجعون"
    },
    {
      "surah_number": 3,
      "verse_number": 73,
      "content": "ولا تؤمنوا الا لمن تبع دينكم قل ان الهدىا هدى الله أن يؤتىا أحد مثل ما أوتيتم أو يحاجوكم عند ربكم قل ان الفضل بيد الله يؤتيه من يشا والله واسع عليم"
    },
    {
      "surah_number": 3,
      "verse_number": 74,
      "content": "يختص برحمته من يشا والله ذو الفضل العظيم"
    },
    {
      "surah_number": 3,
      "verse_number": 75,
      "content": "ومن أهل الكتاب من ان تأمنه بقنطار يؤده اليك ومنهم من ان تأمنه بدينار لا يؤده اليك الا ما دمت عليه قائما ذالك بأنهم قالوا ليس علينا في الأمين سبيل ويقولون على الله الكذب وهم يعلمون"
    },
    {
      "surah_number": 3,
      "verse_number": 76,
      "content": "بلىا من أوفىا بعهده واتقىا فان الله يحب المتقين"
    },
    {
      "surah_number": 3,
      "verse_number": 77,
      "content": "ان الذين يشترون بعهد الله وأيمانهم ثمنا قليلا أولائك لا خلاق لهم في الأخره ولا يكلمهم الله ولا ينظر اليهم يوم القيامه ولا يزكيهم ولهم عذاب أليم"
    },
    {
      "surah_number": 3,
      "verse_number": 78,
      "content": "وان منهم لفريقا يلون ألسنتهم بالكتاب لتحسبوه من الكتاب وما هو من الكتاب ويقولون هو من عند الله وما هو من عند الله ويقولون على الله الكذب وهم يعلمون"
    },
    {
      "surah_number": 3,
      "verse_number": 79,
      "content": "ما كان لبشر أن يؤتيه الله الكتاب والحكم والنبوه ثم يقول للناس كونوا عبادا لي من دون الله ولاكن كونوا ربانين بما كنتم تعلمون الكتاب وبما كنتم تدرسون"
    },
    {
      "surah_number": 3,
      "verse_number": 80,
      "content": "ولا يأمركم أن تتخذوا الملائكه والنبين أربابا أيأمركم بالكفر بعد اذ أنتم مسلمون"
    },
    {
      "surah_number": 3,
      "verse_number": 81,
      "content": "واذ أخذ الله ميثاق النبين لما اتيتكم من كتاب وحكمه ثم جاكم رسول مصدق لما معكم لتؤمنن به ولتنصرنه قال ءأقررتم وأخذتم علىا ذالكم اصري قالوا أقررنا قال فاشهدوا وأنا معكم من الشاهدين"
    },
    {
      "surah_number": 3,
      "verse_number": 82,
      "content": "فمن تولىا بعد ذالك فأولائك هم الفاسقون"
    },
    {
      "surah_number": 3,
      "verse_number": 83,
      "content": "أفغير دين الله يبغون وله أسلم من في السماوات والأرض طوعا وكرها واليه يرجعون"
    },
    {
      "surah_number": 3,
      "verse_number": 84,
      "content": "قل امنا بالله وما أنزل علينا وما أنزل علىا ابراهيم واسماعيل واسحاق ويعقوب والأسباط وما أوتي موسىا وعيسىا والنبيون من ربهم لا نفرق بين أحد منهم ونحن له مسلمون"
    },
    {
      "surah_number": 3,
      "verse_number": 85,
      "content": "ومن يبتغ غير الاسلام دينا فلن يقبل منه وهو في الأخره من الخاسرين"
    },
    {
      "surah_number": 3,
      "verse_number": 86,
      "content": "كيف يهدي الله قوما كفروا بعد ايمانهم وشهدوا أن الرسول حق وجاهم البينات والله لا يهدي القوم الظالمين"
    },
    {
      "surah_number": 3,
      "verse_number": 87,
      "content": "أولائك جزاؤهم أن عليهم لعنه الله والملائكه والناس أجمعين"
    },
    {
      "surah_number": 3,
      "verse_number": 88,
      "content": "خالدين فيها لا يخفف عنهم العذاب ولا هم ينظرون"
    },
    {
      "surah_number": 3,
      "verse_number": 89,
      "content": "الا الذين تابوا من بعد ذالك وأصلحوا فان الله غفور رحيم"
    },
    {
      "surah_number": 3,
      "verse_number": 90,
      "content": "ان الذين كفروا بعد ايمانهم ثم ازدادوا كفرا لن تقبل توبتهم وأولائك هم الضالون"
    },
    {
      "surah_number": 3,
      "verse_number": 91,
      "content": "ان الذين كفروا وماتوا وهم كفار فلن يقبل من أحدهم مل الأرض ذهبا ولو افتدىا به أولائك لهم عذاب أليم وما لهم من ناصرين"
    },
    {
      "surah_number": 3,
      "verse_number": 92,
      "content": "لن تنالوا البر حتىا تنفقوا مما تحبون وما تنفقوا من شي فان الله به عليم"
    },
    {
      "surah_number": 3,
      "verse_number": 93,
      "content": "كل الطعام كان حلا لبني اسرايل الا ما حرم اسرايل علىا نفسه من قبل أن تنزل التورىاه قل فأتوا بالتورىاه فاتلوها ان كنتم صادقين"
    },
    {
      "surah_number": 3,
      "verse_number": 94,
      "content": "فمن افترىا على الله الكذب من بعد ذالك فأولائك هم الظالمون"
    },
    {
      "surah_number": 3,
      "verse_number": 95,
      "content": "قل صدق الله فاتبعوا مله ابراهيم حنيفا وما كان من المشركين"
    },
    {
      "surah_number": 3,
      "verse_number": 96,
      "content": "ان أول بيت وضع للناس للذي ببكه مباركا وهدى للعالمين"
    },
    {
      "surah_number": 3,
      "verse_number": 97,
      "content": "فيه ايات بينات مقام ابراهيم ومن دخله كان امنا ولله على الناس حج البيت من استطاع اليه سبيلا ومن كفر فان الله غني عن العالمين"
    },
    {
      "surah_number": 3,
      "verse_number": 98,
      "content": "قل ياأهل الكتاب لم تكفرون بٔايات الله والله شهيد علىا ما تعملون"
    },
    {
      "surah_number": 3,
      "verse_number": 99,
      "content": "قل ياأهل الكتاب لم تصدون عن سبيل الله من امن تبغونها عوجا وأنتم شهدا وما الله بغافل عما تعملون"
    },
    {
      "surah_number": 3,
      "verse_number": 100,
      "content": "ياأيها الذين امنوا ان تطيعوا فريقا من الذين أوتوا الكتاب يردوكم بعد ايمانكم كافرين"
    },
    {
      "surah_number": 3,
      "verse_number": 101,
      "content": "وكيف تكفرون وأنتم تتلىا عليكم ايات الله وفيكم رسوله ومن يعتصم بالله فقد هدي الىا صراط مستقيم"
    },
    {
      "surah_number": 3,
      "verse_number": 102,
      "content": "ياأيها الذين امنوا اتقوا الله حق تقاته ولا تموتن الا وأنتم مسلمون"
    },
    {
      "surah_number": 3,
      "verse_number": 103,
      "content": "واعتصموا بحبل الله جميعا ولا تفرقوا واذكروا نعمت الله عليكم اذ كنتم أعدا فألف بين قلوبكم فأصبحتم بنعمته اخوانا وكنتم علىا شفا حفره من النار فأنقذكم منها كذالك يبين الله لكم اياته لعلكم تهتدون"
    },
    {
      "surah_number": 3,
      "verse_number": 104,
      "content": "ولتكن منكم أمه يدعون الى الخير ويأمرون بالمعروف وينهون عن المنكر وأولائك هم المفلحون"
    },
    {
      "surah_number": 3,
      "verse_number": 105,
      "content": "ولا تكونوا كالذين تفرقوا واختلفوا من بعد ما جاهم البينات وأولائك لهم عذاب عظيم"
    },
    {
      "surah_number": 3,
      "verse_number": 106,
      "content": "يوم تبيض وجوه وتسود وجوه فأما الذين اسودت وجوههم أكفرتم بعد ايمانكم فذوقوا العذاب بما كنتم تكفرون"
    },
    {
      "surah_number": 3,
      "verse_number": 107,
      "content": "وأما الذين ابيضت وجوههم ففي رحمه الله هم فيها خالدون"
    },
    {
      "surah_number": 3,
      "verse_number": 108,
      "content": "تلك ايات الله نتلوها عليك بالحق وما الله يريد ظلما للعالمين"
    },
    {
      "surah_number": 3,
      "verse_number": 109,
      "content": "ولله ما في السماوات وما في الأرض والى الله ترجع الأمور"
    },
    {
      "surah_number": 3,
      "verse_number": 110,
      "content": "كنتم خير أمه أخرجت للناس تأمرون بالمعروف وتنهون عن المنكر وتؤمنون بالله ولو امن أهل الكتاب لكان خيرا لهم منهم المؤمنون وأكثرهم الفاسقون"
    },
    {
      "surah_number": 3,
      "verse_number": 111,
      "content": "لن يضروكم الا أذى وان يقاتلوكم يولوكم الأدبار ثم لا ينصرون"
    },
    {
      "surah_number": 3,
      "verse_number": 112,
      "content": "ضربت عليهم الذله أين ما ثقفوا الا بحبل من الله وحبل من الناس وباو بغضب من الله وضربت عليهم المسكنه ذالك بأنهم كانوا يكفرون بٔايات الله ويقتلون الأنبيا بغير حق ذالك بما عصوا وكانوا يعتدون"
    },
    {
      "surah_number": 3,
      "verse_number": 113,
      "content": "ليسوا سوا من أهل الكتاب أمه قائمه يتلون ايات الله انا اليل وهم يسجدون"
    },
    {
      "surah_number": 3,
      "verse_number": 114,
      "content": "يؤمنون بالله واليوم الأخر ويأمرون بالمعروف وينهون عن المنكر ويسارعون في الخيرات وأولائك من الصالحين"
    },
    {
      "surah_number": 3,
      "verse_number": 115,
      "content": "وما يفعلوا من خير فلن يكفروه والله عليم بالمتقين"
    },
    {
      "surah_number": 3,
      "verse_number": 116,
      "content": "ان الذين كفروا لن تغني عنهم أموالهم ولا أولادهم من الله شئا وأولائك أصحاب النار هم فيها خالدون"
    },
    {
      "surah_number": 3,
      "verse_number": 117,
      "content": "مثل ما ينفقون في هاذه الحيواه الدنيا كمثل ريح فيها صر أصابت حرث قوم ظلموا أنفسهم فأهلكته وما ظلمهم الله ولاكن أنفسهم يظلمون"
    },
    {
      "surah_number": 3,
      "verse_number": 118,
      "content": "ياأيها الذين امنوا لا تتخذوا بطانه من دونكم لا يألونكم خبالا ودوا ما عنتم قد بدت البغضا من أفواههم وما تخفي صدورهم أكبر قد بينا لكم الأيات ان كنتم تعقلون"
    },
    {
      "surah_number": 3,
      "verse_number": 119,
      "content": "هاأنتم أولا تحبونهم ولا يحبونكم وتؤمنون بالكتاب كله واذا لقوكم قالوا امنا واذا خلوا عضوا عليكم الأنامل من الغيظ قل موتوا بغيظكم ان الله عليم بذات الصدور"
    },
    {
      "surah_number": 3,
      "verse_number": 120,
      "content": "ان تمسسكم حسنه تسؤهم وان تصبكم سيئه يفرحوا بها وان تصبروا وتتقوا لا يضركم كيدهم شئا ان الله بما يعملون محيط"
    },
    {
      "surah_number": 3,
      "verse_number": 121,
      "content": "واذ غدوت من أهلك تبوئ المؤمنين مقاعد للقتال والله سميع عليم"
    },
    {
      "surah_number": 3,
      "verse_number": 122,
      "content": "اذ همت طائفتان منكم أن تفشلا والله وليهما وعلى الله فليتوكل المؤمنون"
    },
    {
      "surah_number": 3,
      "verse_number": 123,
      "content": "ولقد نصركم الله ببدر وأنتم أذله فاتقوا الله لعلكم تشكرون"
    },
    {
      "surah_number": 3,
      "verse_number": 124,
      "content": "اذ تقول للمؤمنين ألن يكفيكم أن يمدكم ربكم بثلاثه الاف من الملائكه منزلين"
    },
    {
      "surah_number": 3,
      "verse_number": 125,
      "content": "بلىا ان تصبروا وتتقوا ويأتوكم من فورهم هاذا يمددكم ربكم بخمسه الاف من الملائكه مسومين"
    },
    {
      "surah_number": 3,
      "verse_number": 126,
      "content": "وما جعله الله الا بشرىا لكم ولتطمئن قلوبكم به وما النصر الا من عند الله العزيز الحكيم"
    },
    {
      "surah_number": 3,
      "verse_number": 127,
      "content": "ليقطع طرفا من الذين كفروا أو يكبتهم فينقلبوا خائبين"
    },
    {
      "surah_number": 3,
      "verse_number": 128,
      "content": "ليس لك من الأمر شي أو يتوب عليهم أو يعذبهم فانهم ظالمون"
    },
    {
      "surah_number": 3,
      "verse_number": 129,
      "content": "ولله ما في السماوات وما في الأرض يغفر لمن يشا ويعذب من يشا والله غفور رحيم"
    },
    {
      "surah_number": 3,
      "verse_number": 130,
      "content": "ياأيها الذين امنوا لا تأكلوا الربواا أضعافا مضاعفه واتقوا الله لعلكم تفلحون"
    },
    {
      "surah_number": 3,
      "verse_number": 131,
      "content": "واتقوا النار التي أعدت للكافرين"
    },
    {
      "surah_number": 3,
      "verse_number": 132,
      "content": "وأطيعوا الله والرسول لعلكم ترحمون"
    },
    {
      "surah_number": 3,
      "verse_number": 133,
      "content": "وسارعوا الىا مغفره من ربكم وجنه عرضها السماوات والأرض أعدت للمتقين"
    },
    {
      "surah_number": 3,
      "verse_number": 134,
      "content": "الذين ينفقون في السرا والضرا والكاظمين الغيظ والعافين عن الناس والله يحب المحسنين"
    },
    {
      "surah_number": 3,
      "verse_number": 135,
      "content": "والذين اذا فعلوا فاحشه أو ظلموا أنفسهم ذكروا الله فاستغفروا لذنوبهم ومن يغفر الذنوب الا الله ولم يصروا علىا ما فعلوا وهم يعلمون"
    },
    {
      "surah_number": 3,
      "verse_number": 136,
      "content": "أولائك جزاؤهم مغفره من ربهم وجنات تجري من تحتها الأنهار خالدين فيها ونعم أجر العاملين"
    },
    {
      "surah_number": 3,
      "verse_number": 137,
      "content": "قد خلت من قبلكم سنن فسيروا في الأرض فانظروا كيف كان عاقبه المكذبين"
    },
    {
      "surah_number": 3,
      "verse_number": 138,
      "content": "هاذا بيان للناس وهدى وموعظه للمتقين"
    },
    {
      "surah_number": 3,
      "verse_number": 139,
      "content": "ولا تهنوا ولا تحزنوا وأنتم الأعلون ان كنتم مؤمنين"
    },
    {
      "surah_number": 3,
      "verse_number": 140,
      "content": "ان يمسسكم قرح فقد مس القوم قرح مثله وتلك الأيام نداولها بين الناس وليعلم الله الذين امنوا ويتخذ منكم شهدا والله لا يحب الظالمين"
    },
    {
      "surah_number": 3,
      "verse_number": 141,
      "content": "وليمحص الله الذين امنوا ويمحق الكافرين"
    },
    {
      "surah_number": 3,
      "verse_number": 142,
      "content": "أم حسبتم أن تدخلوا الجنه ولما يعلم الله الذين جاهدوا منكم ويعلم الصابرين"
    },
    {
      "surah_number": 3,
      "verse_number": 143,
      "content": "ولقد كنتم تمنون الموت من قبل أن تلقوه فقد رأيتموه وأنتم تنظرون"
    },
    {
      "surah_number": 3,
      "verse_number": 144,
      "content": "وما محمد الا رسول قد خلت من قبله الرسل أفاين مات أو قتل انقلبتم علىا أعقابكم ومن ينقلب علىا عقبيه فلن يضر الله شئا وسيجزي الله الشاكرين"
    },
    {
      "surah_number": 3,
      "verse_number": 145,
      "content": "وما كان لنفس أن تموت الا باذن الله كتابا مؤجلا ومن يرد ثواب الدنيا نؤته منها ومن يرد ثواب الأخره نؤته منها وسنجزي الشاكرين"
    },
    {
      "surah_number": 3,
      "verse_number": 146,
      "content": "وكأين من نبي قاتل معه ربيون كثير فما وهنوا لما أصابهم في سبيل الله وما ضعفوا وما استكانوا والله يحب الصابرين"
    },
    {
      "surah_number": 3,
      "verse_number": 147,
      "content": "وما كان قولهم الا أن قالوا ربنا اغفر لنا ذنوبنا واسرافنا في أمرنا وثبت أقدامنا وانصرنا على القوم الكافرين"
    },
    {
      "surah_number": 3,
      "verse_number": 148,
      "content": "فٔاتىاهم الله ثواب الدنيا وحسن ثواب الأخره والله يحب المحسنين"
    },
    {
      "surah_number": 3,
      "verse_number": 149,
      "content": "ياأيها الذين امنوا ان تطيعوا الذين كفروا يردوكم علىا أعقابكم فتنقلبوا خاسرين"
    },
    {
      "surah_number": 3,
      "verse_number": 150,
      "content": "بل الله مولىاكم وهو خير الناصرين"
    },
    {
      "surah_number": 3,
      "verse_number": 151,
      "content": "سنلقي في قلوب الذين كفروا الرعب بما أشركوا بالله ما لم ينزل به سلطانا ومأوىاهم النار وبئس مثوى الظالمين"
    },
    {
      "surah_number": 3,
      "verse_number": 152,
      "content": "ولقد صدقكم الله وعده اذ تحسونهم باذنه حتىا اذا فشلتم وتنازعتم في الأمر وعصيتم من بعد ما أرىاكم ما تحبون منكم من يريد الدنيا ومنكم من يريد الأخره ثم صرفكم عنهم ليبتليكم ولقد عفا عنكم والله ذو فضل على المؤمنين"
    },
    {
      "surah_number": 3,
      "verse_number": 153,
      "content": "اذ تصعدون ولا تلون علىا أحد والرسول يدعوكم في أخرىاكم فأثابكم غما بغم لكيلا تحزنوا علىا ما فاتكم ولا ما أصابكم والله خبير بما تعملون"
    },
    {
      "surah_number": 3,
      "verse_number": 154,
      "content": "ثم أنزل عليكم من بعد الغم أمنه نعاسا يغشىا طائفه منكم وطائفه قد أهمتهم أنفسهم يظنون بالله غير الحق ظن الجاهليه يقولون هل لنا من الأمر من شي قل ان الأمر كله لله يخفون في أنفسهم ما لا يبدون لك يقولون لو كان لنا من الأمر شي ما قتلنا هاهنا قل لو كنتم في بيوتكم لبرز الذين كتب عليهم القتل الىا مضاجعهم وليبتلي الله ما في صدوركم وليمحص ما في قلوبكم والله عليم بذات الصدور"
    },
    {
      "surah_number": 3,
      "verse_number": 155,
      "content": "ان الذين تولوا منكم يوم التقى الجمعان انما استزلهم الشيطان ببعض ما كسبوا ولقد عفا الله عنهم ان الله غفور حليم"
    },
    {
      "surah_number": 3,
      "verse_number": 156,
      "content": "ياأيها الذين امنوا لا تكونوا كالذين كفروا وقالوا لاخوانهم اذا ضربوا في الأرض أو كانوا غزى لو كانوا عندنا ما ماتوا وما قتلوا ليجعل الله ذالك حسره في قلوبهم والله يحي ويميت والله بما تعملون بصير"
    },
    {
      "surah_number": 3,
      "verse_number": 157,
      "content": "ولئن قتلتم في سبيل الله أو متم لمغفره من الله ورحمه خير مما يجمعون"
    },
    {
      "surah_number": 3,
      "verse_number": 158,
      "content": "ولئن متم أو قتلتم لالى الله تحشرون"
    },
    {
      "surah_number": 3,
      "verse_number": 159,
      "content": "فبما رحمه من الله لنت لهم ولو كنت فظا غليظ القلب لانفضوا من حولك فاعف عنهم واستغفر لهم وشاورهم في الأمر فاذا عزمت فتوكل على الله ان الله يحب المتوكلين"
    },
    {
      "surah_number": 3,
      "verse_number": 160,
      "content": "ان ينصركم الله فلا غالب لكم وان يخذلكم فمن ذا الذي ينصركم من بعده وعلى الله فليتوكل المؤمنون"
    },
    {
      "surah_number": 3,
      "verse_number": 161,
      "content": "وما كان لنبي أن يغل ومن يغلل يأت بما غل يوم القيامه ثم توفىا كل نفس ما كسبت وهم لا يظلمون"
    },
    {
      "surah_number": 3,
      "verse_number": 162,
      "content": "أفمن اتبع رضوان الله كمن با بسخط من الله ومأوىاه جهنم وبئس المصير"
    },
    {
      "surah_number": 3,
      "verse_number": 163,
      "content": "هم درجات عند الله والله بصير بما يعملون"
    },
    {
      "surah_number": 3,
      "verse_number": 164,
      "content": "لقد من الله على المؤمنين اذ بعث فيهم رسولا من أنفسهم يتلوا عليهم اياته ويزكيهم ويعلمهم الكتاب والحكمه وان كانوا من قبل لفي ضلال مبين"
    },
    {
      "surah_number": 3,
      "verse_number": 165,
      "content": "أولما أصابتكم مصيبه قد أصبتم مثليها قلتم أنىا هاذا قل هو من عند أنفسكم ان الله علىا كل شي قدير"
    },
    {
      "surah_number": 3,
      "verse_number": 166,
      "content": "وما أصابكم يوم التقى الجمعان فباذن الله وليعلم المؤمنين"
    },
    {
      "surah_number": 3,
      "verse_number": 167,
      "content": "وليعلم الذين نافقوا وقيل لهم تعالوا قاتلوا في سبيل الله أو ادفعوا قالوا لو نعلم قتالا لاتبعناكم هم للكفر يومئذ أقرب منهم للايمان يقولون بأفواههم ما ليس في قلوبهم والله أعلم بما يكتمون"
    },
    {
      "surah_number": 3,
      "verse_number": 168,
      "content": "الذين قالوا لاخوانهم وقعدوا لو أطاعونا ما قتلوا قل فادروا عن أنفسكم الموت ان كنتم صادقين"
    },
    {
      "surah_number": 3,
      "verse_number": 169,
      "content": "ولا تحسبن الذين قتلوا في سبيل الله أمواتا بل أحيا عند ربهم يرزقون"
    },
    {
      "surah_number": 3,
      "verse_number": 170,
      "content": "فرحين بما اتىاهم الله من فضله ويستبشرون بالذين لم يلحقوا بهم من خلفهم ألا خوف عليهم ولا هم يحزنون"
    },
    {
      "surah_number": 3,
      "verse_number": 171,
      "content": "يستبشرون بنعمه من الله وفضل وأن الله لا يضيع أجر المؤمنين"
    },
    {
      "surah_number": 3,
      "verse_number": 172,
      "content": "الذين استجابوا لله والرسول من بعد ما أصابهم القرح للذين أحسنوا منهم واتقوا أجر عظيم"
    },
    {
      "surah_number": 3,
      "verse_number": 173,
      "content": "الذين قال لهم الناس ان الناس قد جمعوا لكم فاخشوهم فزادهم ايمانا وقالوا حسبنا الله ونعم الوكيل"
    },
    {
      "surah_number": 3,
      "verse_number": 174,
      "content": "فانقلبوا بنعمه من الله وفضل لم يمسسهم سو واتبعوا رضوان الله والله ذو فضل عظيم"
    },
    {
      "surah_number": 3,
      "verse_number": 175,
      "content": "انما ذالكم الشيطان يخوف أولياه فلا تخافوهم وخافون ان كنتم مؤمنين"
    },
    {
      "surah_number": 3,
      "verse_number": 176,
      "content": "ولا يحزنك الذين يسارعون في الكفر انهم لن يضروا الله شئا يريد الله ألا يجعل لهم حظا في الأخره ولهم عذاب عظيم"
    },
    {
      "surah_number": 3,
      "verse_number": 177,
      "content": "ان الذين اشتروا الكفر بالايمان لن يضروا الله شئا ولهم عذاب أليم"
    },
    {
      "surah_number": 3,
      "verse_number": 178,
      "content": "ولا يحسبن الذين كفروا أنما نملي لهم خير لأنفسهم انما نملي لهم ليزدادوا اثما ولهم عذاب مهين"
    },
    {
      "surah_number": 3,
      "verse_number": 179,
      "content": "ما كان الله ليذر المؤمنين علىا ما أنتم عليه حتىا يميز الخبيث من الطيب وما كان الله ليطلعكم على الغيب ولاكن الله يجتبي من رسله من يشا فٔامنوا بالله ورسله وان تؤمنوا وتتقوا فلكم أجر عظيم"
    },
    {
      "surah_number": 3,
      "verse_number": 180,
      "content": "ولا يحسبن الذين يبخلون بما اتىاهم الله من فضله هو خيرا لهم بل هو شر لهم سيطوقون ما بخلوا به يوم القيامه ولله ميراث السماوات والأرض والله بما تعملون خبير"
    },
    {
      "surah_number": 3,
      "verse_number": 181,
      "content": "لقد سمع الله قول الذين قالوا ان الله فقير ونحن أغنيا سنكتب ما قالوا وقتلهم الأنبيا بغير حق ونقول ذوقوا عذاب الحريق"
    },
    {
      "surah_number": 3,
      "verse_number": 182,
      "content": "ذالك بما قدمت أيديكم وأن الله ليس بظلام للعبيد"
    },
    {
      "surah_number": 3,
      "verse_number": 183,
      "content": "الذين قالوا ان الله عهد الينا ألا نؤمن لرسول حتىا يأتينا بقربان تأكله النار قل قد جاكم رسل من قبلي بالبينات وبالذي قلتم فلم قتلتموهم ان كنتم صادقين"
    },
    {
      "surah_number": 3,
      "verse_number": 184,
      "content": "فان كذبوك فقد كذب رسل من قبلك جاو بالبينات والزبر والكتاب المنير"
    },
    {
      "surah_number": 3,
      "verse_number": 185,
      "content": "كل نفس ذائقه الموت وانما توفون أجوركم يوم القيامه فمن زحزح عن النار وأدخل الجنه فقد فاز وما الحيواه الدنيا الا متاع الغرور"
    },
    {
      "surah_number": 3,
      "verse_number": 186,
      "content": "لتبلون في أموالكم وأنفسكم ولتسمعن من الذين أوتوا الكتاب من قبلكم ومن الذين أشركوا أذى كثيرا وان تصبروا وتتقوا فان ذالك من عزم الأمور"
    },
    {
      "surah_number": 3,
      "verse_number": 187,
      "content": "واذ أخذ الله ميثاق الذين أوتوا الكتاب لتبيننه للناس ولا تكتمونه فنبذوه ورا ظهورهم واشتروا به ثمنا قليلا فبئس ما يشترون"
    },
    {
      "surah_number": 3,
      "verse_number": 188,
      "content": "لا تحسبن الذين يفرحون بما أتوا ويحبون أن يحمدوا بما لم يفعلوا فلا تحسبنهم بمفازه من العذاب ولهم عذاب أليم"
    },
    {
      "surah_number": 3,
      "verse_number": 189,
      "content": "ولله ملك السماوات والأرض والله علىا كل شي قدير"
    },
    {
      "surah_number": 3,
      "verse_number": 190,
      "content": "ان في خلق السماوات والأرض واختلاف اليل والنهار لأيات لأولي الألباب"
    },
    {
      "surah_number": 3,
      "verse_number": 191,
      "content": "الذين يذكرون الله قياما وقعودا وعلىا جنوبهم ويتفكرون في خلق السماوات والأرض ربنا ما خلقت هاذا باطلا سبحانك فقنا عذاب النار"
    },
    {
      "surah_number": 3,
      "verse_number": 192,
      "content": "ربنا انك من تدخل النار فقد أخزيته وما للظالمين من أنصار"
    },
    {
      "surah_number": 3,
      "verse_number": 193,
      "content": "ربنا اننا سمعنا مناديا ينادي للايمان أن امنوا بربكم فٔامنا ربنا فاغفر لنا ذنوبنا وكفر عنا سئاتنا وتوفنا مع الأبرار"
    },
    {
      "surah_number": 3,
      "verse_number": 194,
      "content": "ربنا واتنا ما وعدتنا علىا رسلك ولا تخزنا يوم القيامه انك لا تخلف الميعاد"
    },
    {
      "surah_number": 3,
      "verse_number": 195,
      "content": "فاستجاب لهم ربهم أني لا أضيع عمل عامل منكم من ذكر أو أنثىا بعضكم من بعض فالذين هاجروا وأخرجوا من ديارهم وأوذوا في سبيلي وقاتلوا وقتلوا لأكفرن عنهم سئاتهم ولأدخلنهم جنات تجري من تحتها الأنهار ثوابا من عند الله والله عنده حسن الثواب"
    },
    {
      "surah_number": 3,
      "verse_number": 196,
      "content": "لا يغرنك تقلب الذين كفروا في البلاد"
    },
    {
      "surah_number": 3,
      "verse_number": 197,
      "content": "متاع قليل ثم مأوىاهم جهنم وبئس المهاد"
    },
    {
      "surah_number": 3,
      "verse_number": 198,
      "content": "لاكن الذين اتقوا ربهم لهم جنات تجري من تحتها الأنهار خالدين فيها نزلا من عند الله وما عند الله خير للأبرار"
    },
    {
      "surah_number": 3,
      "verse_number": 199,
      "content": "وان من أهل الكتاب لمن يؤمن بالله وما أنزل اليكم وما أنزل اليهم خاشعين لله لا يشترون بٔايات الله ثمنا قليلا أولائك لهم أجرهم عند ربهم ان الله سريع الحساب"
    },
    {
      "surah_number": 3,
      "verse_number": 200,
      "content": "ياأيها الذين امنوا اصبروا وصابروا ورابطوا واتقوا الله لعلكم تفلحون"
    },
    {
      "surah_number": 4,
      "verse_number": 1,
      "content": "ياأيها الناس اتقوا ربكم الذي خلقكم من نفس واحده وخلق منها زوجها وبث منهما رجالا كثيرا ونسا واتقوا الله الذي تسالون به والأرحام ان الله كان عليكم رقيبا"
    },
    {
      "surah_number": 4,
      "verse_number": 2,
      "content": "واتوا اليتامىا أموالهم ولا تتبدلوا الخبيث بالطيب ولا تأكلوا أموالهم الىا أموالكم انه كان حوبا كبيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 3,
      "content": "وان خفتم ألا تقسطوا في اليتامىا فانكحوا ما طاب لكم من النسا مثنىا وثلاث ورباع فان خفتم ألا تعدلوا فواحده أو ما ملكت أيمانكم ذالك أدنىا ألا تعولوا"
    },
    {
      "surah_number": 4,
      "verse_number": 4,
      "content": "واتوا النسا صدقاتهن نحله فان طبن لكم عن شي منه نفسا فكلوه هنئا مرئا"
    },
    {
      "surah_number": 4,
      "verse_number": 5,
      "content": "ولا تؤتوا السفها أموالكم التي جعل الله لكم قياما وارزقوهم فيها واكسوهم وقولوا لهم قولا معروفا"
    },
    {
      "surah_number": 4,
      "verse_number": 6,
      "content": "وابتلوا اليتامىا حتىا اذا بلغوا النكاح فان انستم منهم رشدا فادفعوا اليهم أموالهم ولا تأكلوها اسرافا وبدارا أن يكبروا ومن كان غنيا فليستعفف ومن كان فقيرا فليأكل بالمعروف فاذا دفعتم اليهم أموالهم فأشهدوا عليهم وكفىا بالله حسيبا"
    },
    {
      "surah_number": 4,
      "verse_number": 7,
      "content": "للرجال نصيب مما ترك الوالدان والأقربون وللنسا نصيب مما ترك الوالدان والأقربون مما قل منه أو كثر نصيبا مفروضا"
    },
    {
      "surah_number": 4,
      "verse_number": 8,
      "content": "واذا حضر القسمه أولوا القربىا واليتامىا والمساكين فارزقوهم منه وقولوا لهم قولا معروفا"
    },
    {
      "surah_number": 4,
      "verse_number": 9,
      "content": "وليخش الذين لو تركوا من خلفهم ذريه ضعافا خافوا عليهم فليتقوا الله وليقولوا قولا سديدا"
    },
    {
      "surah_number": 4,
      "verse_number": 10,
      "content": "ان الذين يأكلون أموال اليتامىا ظلما انما يأكلون في بطونهم نارا وسيصلون سعيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 11,
      "content": "يوصيكم الله في أولادكم للذكر مثل حظ الأنثيين فان كن نسا فوق اثنتين فلهن ثلثا ما ترك وان كانت واحده فلها النصف ولأبويه لكل واحد منهما السدس مما ترك ان كان له ولد فان لم يكن له ولد وورثه أبواه فلأمه الثلث فان كان له اخوه فلأمه السدس من بعد وصيه يوصي بها أو دين اباؤكم وأبناؤكم لا تدرون أيهم أقرب لكم نفعا فريضه من الله ان الله كان عليما حكيما"
    },
    {
      "surah_number": 4,
      "verse_number": 12,
      "content": "ولكم نصف ما ترك أزواجكم ان لم يكن لهن ولد فان كان لهن ولد فلكم الربع مما تركن من بعد وصيه يوصين بها أو دين ولهن الربع مما تركتم ان لم يكن لكم ولد فان كان لكم ولد فلهن الثمن مما تركتم من بعد وصيه توصون بها أو دين وان كان رجل يورث كلاله أو امرأه وله أخ أو أخت فلكل واحد منهما السدس فان كانوا أكثر من ذالك فهم شركا في الثلث من بعد وصيه يوصىا بها أو دين غير مضار وصيه من الله والله عليم حليم"
    },
    {
      "surah_number": 4,
      "verse_number": 13,
      "content": "تلك حدود الله ومن يطع الله ورسوله يدخله جنات تجري من تحتها الأنهار خالدين فيها وذالك الفوز العظيم"
    },
    {
      "surah_number": 4,
      "verse_number": 14,
      "content": "ومن يعص الله ورسوله ويتعد حدوده يدخله نارا خالدا فيها وله عذاب مهين"
    },
    {
      "surah_number": 4,
      "verse_number": 15,
      "content": "والاتي يأتين الفاحشه من نسائكم فاستشهدوا عليهن أربعه منكم فان شهدوا فأمسكوهن في البيوت حتىا يتوفىاهن الموت أو يجعل الله لهن سبيلا"
    },
    {
      "surah_number": 4,
      "verse_number": 16,
      "content": "والذان يأتيانها منكم فٔاذوهما فان تابا وأصلحا فأعرضوا عنهما ان الله كان توابا رحيما"
    },
    {
      "surah_number": 4,
      "verse_number": 17,
      "content": "انما التوبه على الله للذين يعملون السو بجهاله ثم يتوبون من قريب فأولائك يتوب الله عليهم وكان الله عليما حكيما"
    },
    {
      "surah_number": 4,
      "verse_number": 18,
      "content": "وليست التوبه للذين يعملون السئات حتىا اذا حضر أحدهم الموت قال اني تبت الٔان ولا الذين يموتون وهم كفار أولائك أعتدنا لهم عذابا أليما"
    },
    {
      "surah_number": 4,
      "verse_number": 19,
      "content": "ياأيها الذين امنوا لا يحل لكم أن ترثوا النسا كرها ولا تعضلوهن لتذهبوا ببعض ما اتيتموهن الا أن يأتين بفاحشه مبينه وعاشروهن بالمعروف فان كرهتموهن فعسىا أن تكرهوا شئا ويجعل الله فيه خيرا كثيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 20,
      "content": "وان أردتم استبدال زوج مكان زوج واتيتم احدىاهن قنطارا فلا تأخذوا منه شئا أتأخذونه بهتانا واثما مبينا"
    },
    {
      "surah_number": 4,
      "verse_number": 21,
      "content": "وكيف تأخذونه وقد أفضىا بعضكم الىا بعض وأخذن منكم ميثاقا غليظا"
    },
    {
      "surah_number": 4,
      "verse_number": 22,
      "content": "ولا تنكحوا ما نكح اباؤكم من النسا الا ما قد سلف انه كان فاحشه ومقتا وسا سبيلا"
    },
    {
      "surah_number": 4,
      "verse_number": 23,
      "content": "حرمت عليكم أمهاتكم وبناتكم وأخواتكم وعماتكم وخالاتكم وبنات الأخ وبنات الأخت وأمهاتكم الاتي أرضعنكم وأخواتكم من الرضاعه وأمهات نسائكم وربائبكم الاتي في حجوركم من نسائكم الاتي دخلتم بهن فان لم تكونوا دخلتم بهن فلا جناح عليكم وحلائل أبنائكم الذين من أصلابكم وأن تجمعوا بين الأختين الا ما قد سلف ان الله كان غفورا رحيما"
    },
    {
      "surah_number": 4,
      "verse_number": 24,
      "content": "والمحصنات من النسا الا ما ملكت أيمانكم كتاب الله عليكم وأحل لكم ما ورا ذالكم أن تبتغوا بأموالكم محصنين غير مسافحين فما استمتعتم به منهن فٔاتوهن أجورهن فريضه ولا جناح عليكم فيما تراضيتم به من بعد الفريضه ان الله كان عليما حكيما"
    },
    {
      "surah_number": 4,
      "verse_number": 25,
      "content": "ومن لم يستطع منكم طولا أن ينكح المحصنات المؤمنات فمن ما ملكت أيمانكم من فتياتكم المؤمنات والله أعلم بايمانكم بعضكم من بعض فانكحوهن باذن أهلهن واتوهن أجورهن بالمعروف محصنات غير مسافحات ولا متخذات أخدان فاذا أحصن فان أتين بفاحشه فعليهن نصف ما على المحصنات من العذاب ذالك لمن خشي العنت منكم وأن تصبروا خير لكم والله غفور رحيم"
    },
    {
      "surah_number": 4,
      "verse_number": 26,
      "content": "يريد الله ليبين لكم ويهديكم سنن الذين من قبلكم ويتوب عليكم والله عليم حكيم"
    },
    {
      "surah_number": 4,
      "verse_number": 27,
      "content": "والله يريد أن يتوب عليكم ويريد الذين يتبعون الشهوات أن تميلوا ميلا عظيما"
    },
    {
      "surah_number": 4,
      "verse_number": 28,
      "content": "يريد الله أن يخفف عنكم وخلق الانسان ضعيفا"
    },
    {
      "surah_number": 4,
      "verse_number": 29,
      "content": "ياأيها الذين امنوا لا تأكلوا أموالكم بينكم بالباطل الا أن تكون تجاره عن تراض منكم ولا تقتلوا أنفسكم ان الله كان بكم رحيما"
    },
    {
      "surah_number": 4,
      "verse_number": 30,
      "content": "ومن يفعل ذالك عدوانا وظلما فسوف نصليه نارا وكان ذالك على الله يسيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 31,
      "content": "ان تجتنبوا كبائر ما تنهون عنه نكفر عنكم سئاتكم وندخلكم مدخلا كريما"
    },
    {
      "surah_number": 4,
      "verse_number": 32,
      "content": "ولا تتمنوا ما فضل الله به بعضكم علىا بعض للرجال نصيب مما اكتسبوا وللنسا نصيب مما اكتسبن وسٔلوا الله من فضله ان الله كان بكل شي عليما"
    },
    {
      "surah_number": 4,
      "verse_number": 33,
      "content": "ولكل جعلنا موالي مما ترك الوالدان والأقربون والذين عقدت أيمانكم فٔاتوهم نصيبهم ان الله كان علىا كل شي شهيدا"
    },
    {
      "surah_number": 4,
      "verse_number": 34,
      "content": "الرجال قوامون على النسا بما فضل الله بعضهم علىا بعض وبما أنفقوا من أموالهم فالصالحات قانتات حافظات للغيب بما حفظ الله والاتي تخافون نشوزهن فعظوهن واهجروهن في المضاجع واضربوهن فان أطعنكم فلا تبغوا عليهن سبيلا ان الله كان عليا كبيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 35,
      "content": "وان خفتم شقاق بينهما فابعثوا حكما من أهله وحكما من أهلها ان يريدا اصلاحا يوفق الله بينهما ان الله كان عليما خبيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 36,
      "content": "واعبدوا الله ولا تشركوا به شئا وبالوالدين احسانا وبذي القربىا واليتامىا والمساكين والجار ذي القربىا والجار الجنب والصاحب بالجنب وابن السبيل وما ملكت أيمانكم ان الله لا يحب من كان مختالا فخورا"
    },
    {
      "surah_number": 4,
      "verse_number": 37,
      "content": "الذين يبخلون ويأمرون الناس بالبخل ويكتمون ما اتىاهم الله من فضله وأعتدنا للكافرين عذابا مهينا"
    },
    {
      "surah_number": 4,
      "verse_number": 38,
      "content": "والذين ينفقون أموالهم رئا الناس ولا يؤمنون بالله ولا باليوم الأخر ومن يكن الشيطان له قرينا فسا قرينا"
    },
    {
      "surah_number": 4,
      "verse_number": 39,
      "content": "وماذا عليهم لو امنوا بالله واليوم الأخر وأنفقوا مما رزقهم الله وكان الله بهم عليما"
    },
    {
      "surah_number": 4,
      "verse_number": 40,
      "content": "ان الله لا يظلم مثقال ذره وان تك حسنه يضاعفها ويؤت من لدنه أجرا عظيما"
    },
    {
      "surah_number": 4,
      "verse_number": 41,
      "content": "فكيف اذا جئنا من كل أمه بشهيد وجئنا بك علىا هاؤلا شهيدا"
    },
    {
      "surah_number": 4,
      "verse_number": 42,
      "content": "يومئذ يود الذين كفروا وعصوا الرسول لو تسوىا بهم الأرض ولا يكتمون الله حديثا"
    },
    {
      "surah_number": 4,
      "verse_number": 43,
      "content": "ياأيها الذين امنوا لا تقربوا الصلواه وأنتم سكارىا حتىا تعلموا ما تقولون ولا جنبا الا عابري سبيل حتىا تغتسلوا وان كنتم مرضىا أو علىا سفر أو جا أحد منكم من الغائط أو لامستم النسا فلم تجدوا ما فتيمموا صعيدا طيبا فامسحوا بوجوهكم وأيديكم ان الله كان عفوا غفورا"
    },
    {
      "surah_number": 4,
      "verse_number": 44,
      "content": "ألم تر الى الذين أوتوا نصيبا من الكتاب يشترون الضلاله ويريدون أن تضلوا السبيل"
    },
    {
      "surah_number": 4,
      "verse_number": 45,
      "content": "والله أعلم بأعدائكم وكفىا بالله وليا وكفىا بالله نصيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 46,
      "content": "من الذين هادوا يحرفون الكلم عن مواضعه ويقولون سمعنا وعصينا واسمع غير مسمع وراعنا ليا بألسنتهم وطعنا في الدين ولو أنهم قالوا سمعنا وأطعنا واسمع وانظرنا لكان خيرا لهم وأقوم ولاكن لعنهم الله بكفرهم فلا يؤمنون الا قليلا"
    },
    {
      "surah_number": 4,
      "verse_number": 47,
      "content": "ياأيها الذين أوتوا الكتاب امنوا بما نزلنا مصدقا لما معكم من قبل أن نطمس وجوها فنردها علىا أدبارها أو نلعنهم كما لعنا أصحاب السبت وكان أمر الله مفعولا"
    },
    {
      "surah_number": 4,
      "verse_number": 48,
      "content": "ان الله لا يغفر أن يشرك به ويغفر ما دون ذالك لمن يشا ومن يشرك بالله فقد افترىا اثما عظيما"
    },
    {
      "surah_number": 4,
      "verse_number": 49,
      "content": "ألم تر الى الذين يزكون أنفسهم بل الله يزكي من يشا ولا يظلمون فتيلا"
    },
    {
      "surah_number": 4,
      "verse_number": 50,
      "content": "انظر كيف يفترون على الله الكذب وكفىا به اثما مبينا"
    },
    {
      "surah_number": 4,
      "verse_number": 51,
      "content": "ألم تر الى الذين أوتوا نصيبا من الكتاب يؤمنون بالجبت والطاغوت ويقولون للذين كفروا هاؤلا أهدىا من الذين امنوا سبيلا"
    },
    {
      "surah_number": 4,
      "verse_number": 52,
      "content": "أولائك الذين لعنهم الله ومن يلعن الله فلن تجد له نصيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 53,
      "content": "أم لهم نصيب من الملك فاذا لا يؤتون الناس نقيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 54,
      "content": "أم يحسدون الناس علىا ما اتىاهم الله من فضله فقد اتينا ال ابراهيم الكتاب والحكمه واتيناهم ملكا عظيما"
    },
    {
      "surah_number": 4,
      "verse_number": 55,
      "content": "فمنهم من امن به ومنهم من صد عنه وكفىا بجهنم سعيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 56,
      "content": "ان الذين كفروا بٔاياتنا سوف نصليهم نارا كلما نضجت جلودهم بدلناهم جلودا غيرها ليذوقوا العذاب ان الله كان عزيزا حكيما"
    },
    {
      "surah_number": 4,
      "verse_number": 57,
      "content": "والذين امنوا وعملوا الصالحات سندخلهم جنات تجري من تحتها الأنهار خالدين فيها أبدا لهم فيها أزواج مطهره وندخلهم ظلا ظليلا"
    },
    {
      "surah_number": 4,
      "verse_number": 58,
      "content": "ان الله يأمركم أن تؤدوا الأمانات الىا أهلها واذا حكمتم بين الناس أن تحكموا بالعدل ان الله نعما يعظكم به ان الله كان سميعا بصيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 59,
      "content": "ياأيها الذين امنوا أطيعوا الله وأطيعوا الرسول وأولي الأمر منكم فان تنازعتم في شي فردوه الى الله والرسول ان كنتم تؤمنون بالله واليوم الأخر ذالك خير وأحسن تأويلا"
    },
    {
      "surah_number": 4,
      "verse_number": 60,
      "content": "ألم تر الى الذين يزعمون أنهم امنوا بما أنزل اليك وما أنزل من قبلك يريدون أن يتحاكموا الى الطاغوت وقد أمروا أن يكفروا به ويريد الشيطان أن يضلهم ضلالا بعيدا"
    },
    {
      "surah_number": 4,
      "verse_number": 61,
      "content": "واذا قيل لهم تعالوا الىا ما أنزل الله والى الرسول رأيت المنافقين يصدون عنك صدودا"
    },
    {
      "surah_number": 4,
      "verse_number": 62,
      "content": "فكيف اذا أصابتهم مصيبه بما قدمت أيديهم ثم جاوك يحلفون بالله ان أردنا الا احسانا وتوفيقا"
    },
    {
      "surah_number": 4,
      "verse_number": 63,
      "content": "أولائك الذين يعلم الله ما في قلوبهم فأعرض عنهم وعظهم وقل لهم في أنفسهم قولا بليغا"
    },
    {
      "surah_number": 4,
      "verse_number": 64,
      "content": "وما أرسلنا من رسول الا ليطاع باذن الله ولو أنهم اذ ظلموا أنفسهم جاوك فاستغفروا الله واستغفر لهم الرسول لوجدوا الله توابا رحيما"
    },
    {
      "surah_number": 4,
      "verse_number": 65,
      "content": "فلا وربك لا يؤمنون حتىا يحكموك فيما شجر بينهم ثم لا يجدوا في أنفسهم حرجا مما قضيت ويسلموا تسليما"
    },
    {
      "surah_number": 4,
      "verse_number": 66,
      "content": "ولو أنا كتبنا عليهم أن اقتلوا أنفسكم أو اخرجوا من دياركم ما فعلوه الا قليل منهم ولو أنهم فعلوا ما يوعظون به لكان خيرا لهم وأشد تثبيتا"
    },
    {
      "surah_number": 4,
      "verse_number": 67,
      "content": "واذا لأتيناهم من لدنا أجرا عظيما"
    },
    {
      "surah_number": 4,
      "verse_number": 68,
      "content": "ولهديناهم صراطا مستقيما"
    },
    {
      "surah_number": 4,
      "verse_number": 69,
      "content": "ومن يطع الله والرسول فأولائك مع الذين أنعم الله عليهم من النبين والصديقين والشهدا والصالحين وحسن أولائك رفيقا"
    },
    {
      "surah_number": 4,
      "verse_number": 70,
      "content": "ذالك الفضل من الله وكفىا بالله عليما"
    },
    {
      "surah_number": 4,
      "verse_number": 71,
      "content": "ياأيها الذين امنوا خذوا حذركم فانفروا ثبات أو انفروا جميعا"
    },
    {
      "surah_number": 4,
      "verse_number": 72,
      "content": "وان منكم لمن ليبطئن فان أصابتكم مصيبه قال قد أنعم الله علي اذ لم أكن معهم شهيدا"
    },
    {
      "surah_number": 4,
      "verse_number": 73,
      "content": "ولئن أصابكم فضل من الله ليقولن كأن لم تكن بينكم وبينه موده ياليتني كنت معهم فأفوز فوزا عظيما"
    },
    {
      "surah_number": 4,
      "verse_number": 74,
      "content": "فليقاتل في سبيل الله الذين يشرون الحيواه الدنيا بالأخره ومن يقاتل في سبيل الله فيقتل أو يغلب فسوف نؤتيه أجرا عظيما"
    },
    {
      "surah_number": 4,
      "verse_number": 75,
      "content": "وما لكم لا تقاتلون في سبيل الله والمستضعفين من الرجال والنسا والولدان الذين يقولون ربنا أخرجنا من هاذه القريه الظالم أهلها واجعل لنا من لدنك وليا واجعل لنا من لدنك نصيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 76,
      "content": "الذين امنوا يقاتلون في سبيل الله والذين كفروا يقاتلون في سبيل الطاغوت فقاتلوا أوليا الشيطان ان كيد الشيطان كان ضعيفا"
    },
    {
      "surah_number": 4,
      "verse_number": 77,
      "content": "ألم تر الى الذين قيل لهم كفوا أيديكم وأقيموا الصلواه واتوا الزكواه فلما كتب عليهم القتال اذا فريق منهم يخشون الناس كخشيه الله أو أشد خشيه وقالوا ربنا لم كتبت علينا القتال لولا أخرتنا الىا أجل قريب قل متاع الدنيا قليل والأخره خير لمن اتقىا ولا تظلمون فتيلا"
    },
    {
      "surah_number": 4,
      "verse_number": 78,
      "content": "أينما تكونوا يدرككم الموت ولو كنتم في بروج مشيده وان تصبهم حسنه يقولوا هاذه من عند الله وان تصبهم سيئه يقولوا هاذه من عندك قل كل من عند الله فمال هاؤلا القوم لا يكادون يفقهون حديثا"
    },
    {
      "surah_number": 4,
      "verse_number": 79,
      "content": "ما أصابك من حسنه فمن الله وما أصابك من سيئه فمن نفسك وأرسلناك للناس رسولا وكفىا بالله شهيدا"
    },
    {
      "surah_number": 4,
      "verse_number": 80,
      "content": "من يطع الرسول فقد أطاع الله ومن تولىا فما أرسلناك عليهم حفيظا"
    },
    {
      "surah_number": 4,
      "verse_number": 81,
      "content": "ويقولون طاعه فاذا برزوا من عندك بيت طائفه منهم غير الذي تقول والله يكتب ما يبيتون فأعرض عنهم وتوكل على الله وكفىا بالله وكيلا"
    },
    {
      "surah_number": 4,
      "verse_number": 82,
      "content": "أفلا يتدبرون القران ولو كان من عند غير الله لوجدوا فيه اختلافا كثيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 83,
      "content": "واذا جاهم أمر من الأمن أو الخوف أذاعوا به ولو ردوه الى الرسول والىا أولي الأمر منهم لعلمه الذين يستنبطونه منهم ولولا فضل الله عليكم ورحمته لاتبعتم الشيطان الا قليلا"
    },
    {
      "surah_number": 4,
      "verse_number": 84,
      "content": "فقاتل في سبيل الله لا تكلف الا نفسك وحرض المؤمنين عسى الله أن يكف بأس الذين كفروا والله أشد بأسا وأشد تنكيلا"
    },
    {
      "surah_number": 4,
      "verse_number": 85,
      "content": "من يشفع شفاعه حسنه يكن له نصيب منها ومن يشفع شفاعه سيئه يكن له كفل منها وكان الله علىا كل شي مقيتا"
    },
    {
      "surah_number": 4,
      "verse_number": 86,
      "content": "واذا حييتم بتحيه فحيوا بأحسن منها أو ردوها ان الله كان علىا كل شي حسيبا"
    },
    {
      "surah_number": 4,
      "verse_number": 87,
      "content": "الله لا الاه الا هو ليجمعنكم الىا يوم القيامه لا ريب فيه ومن أصدق من الله حديثا"
    },
    {
      "surah_number": 4,
      "verse_number": 88,
      "content": "فما لكم في المنافقين فئتين والله أركسهم بما كسبوا أتريدون أن تهدوا من أضل الله ومن يضلل الله فلن تجد له سبيلا"
    },
    {
      "surah_number": 4,
      "verse_number": 89,
      "content": "ودوا لو تكفرون كما كفروا فتكونون سوا فلا تتخذوا منهم أوليا حتىا يهاجروا في سبيل الله فان تولوا فخذوهم واقتلوهم حيث وجدتموهم ولا تتخذوا منهم وليا ولا نصيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 90,
      "content": "الا الذين يصلون الىا قوم بينكم وبينهم ميثاق أو جاوكم حصرت صدورهم أن يقاتلوكم أو يقاتلوا قومهم ولو شا الله لسلطهم عليكم فلقاتلوكم فان اعتزلوكم فلم يقاتلوكم وألقوا اليكم السلم فما جعل الله لكم عليهم سبيلا"
    },
    {
      "surah_number": 4,
      "verse_number": 91,
      "content": "ستجدون اخرين يريدون أن يأمنوكم ويأمنوا قومهم كل ما ردوا الى الفتنه أركسوا فيها فان لم يعتزلوكم ويلقوا اليكم السلم ويكفوا أيديهم فخذوهم واقتلوهم حيث ثقفتموهم وأولائكم جعلنا لكم عليهم سلطانا مبينا"
    },
    {
      "surah_number": 4,
      "verse_number": 92,
      "content": "وما كان لمؤمن أن يقتل مؤمنا الا خطٔا ومن قتل مؤمنا خطٔا فتحرير رقبه مؤمنه وديه مسلمه الىا أهله الا أن يصدقوا فان كان من قوم عدو لكم وهو مؤمن فتحرير رقبه مؤمنه وان كان من قوم بينكم وبينهم ميثاق فديه مسلمه الىا أهله وتحرير رقبه مؤمنه فمن لم يجد فصيام شهرين متتابعين توبه من الله وكان الله عليما حكيما"
    },
    {
      "surah_number": 4,
      "verse_number": 93,
      "content": "ومن يقتل مؤمنا متعمدا فجزاؤه جهنم خالدا فيها وغضب الله عليه ولعنه وأعد له عذابا عظيما"
    },
    {
      "surah_number": 4,
      "verse_number": 94,
      "content": "ياأيها الذين امنوا اذا ضربتم في سبيل الله فتبينوا ولا تقولوا لمن ألقىا اليكم السلام لست مؤمنا تبتغون عرض الحيواه الدنيا فعند الله مغانم كثيره كذالك كنتم من قبل فمن الله عليكم فتبينوا ان الله كان بما تعملون خبيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 95,
      "content": "لا يستوي القاعدون من المؤمنين غير أولي الضرر والمجاهدون في سبيل الله بأموالهم وأنفسهم فضل الله المجاهدين بأموالهم وأنفسهم على القاعدين درجه وكلا وعد الله الحسنىا وفضل الله المجاهدين على القاعدين أجرا عظيما"
    },
    {
      "surah_number": 4,
      "verse_number": 96,
      "content": "درجات منه ومغفره ورحمه وكان الله غفورا رحيما"
    },
    {
      "surah_number": 4,
      "verse_number": 97,
      "content": "ان الذين توفىاهم الملائكه ظالمي أنفسهم قالوا فيم كنتم قالوا كنا مستضعفين في الأرض قالوا ألم تكن أرض الله واسعه فتهاجروا فيها فأولائك مأوىاهم جهنم وسات مصيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 98,
      "content": "الا المستضعفين من الرجال والنسا والولدان لا يستطيعون حيله ولا يهتدون سبيلا"
    },
    {
      "surah_number": 4,
      "verse_number": 99,
      "content": "فأولائك عسى الله أن يعفو عنهم وكان الله عفوا غفورا"
    },
    {
      "surah_number": 4,
      "verse_number": 100,
      "content": "ومن يهاجر في سبيل الله يجد في الأرض مراغما كثيرا وسعه ومن يخرج من بيته مهاجرا الى الله ورسوله ثم يدركه الموت فقد وقع أجره على الله وكان الله غفورا رحيما"
    },
    {
      "surah_number": 4,
      "verse_number": 101,
      "content": "واذا ضربتم في الأرض فليس عليكم جناح أن تقصروا من الصلواه ان خفتم أن يفتنكم الذين كفروا ان الكافرين كانوا لكم عدوا مبينا"
    },
    {
      "surah_number": 4,
      "verse_number": 102,
      "content": "واذا كنت فيهم فأقمت لهم الصلواه فلتقم طائفه منهم معك وليأخذوا أسلحتهم فاذا سجدوا فليكونوا من ورائكم ولتأت طائفه أخرىا لم يصلوا فليصلوا معك وليأخذوا حذرهم وأسلحتهم ود الذين كفروا لو تغفلون عن أسلحتكم وأمتعتكم فيميلون عليكم ميله واحده ولا جناح عليكم ان كان بكم أذى من مطر أو كنتم مرضىا أن تضعوا أسلحتكم وخذوا حذركم ان الله أعد للكافرين عذابا مهينا"
    },
    {
      "surah_number": 4,
      "verse_number": 103,
      "content": "فاذا قضيتم الصلواه فاذكروا الله قياما وقعودا وعلىا جنوبكم فاذا اطمأننتم فأقيموا الصلواه ان الصلواه كانت على المؤمنين كتابا موقوتا"
    },
    {
      "surah_number": 4,
      "verse_number": 104,
      "content": "ولا تهنوا في ابتغا القوم ان تكونوا تألمون فانهم يألمون كما تألمون وترجون من الله ما لا يرجون وكان الله عليما حكيما"
    },
    {
      "surah_number": 4,
      "verse_number": 105,
      "content": "انا أنزلنا اليك الكتاب بالحق لتحكم بين الناس بما أرىاك الله ولا تكن للخائنين خصيما"
    },
    {
      "surah_number": 4,
      "verse_number": 106,
      "content": "واستغفر الله ان الله كان غفورا رحيما"
    },
    {
      "surah_number": 4,
      "verse_number": 107,
      "content": "ولا تجادل عن الذين يختانون أنفسهم ان الله لا يحب من كان خوانا أثيما"
    },
    {
      "surah_number": 4,
      "verse_number": 108,
      "content": "يستخفون من الناس ولا يستخفون من الله وهو معهم اذ يبيتون ما لا يرضىا من القول وكان الله بما يعملون محيطا"
    },
    {
      "surah_number": 4,
      "verse_number": 109,
      "content": "هاأنتم هاؤلا جادلتم عنهم في الحيواه الدنيا فمن يجادل الله عنهم يوم القيامه أم من يكون عليهم وكيلا"
    },
    {
      "surah_number": 4,
      "verse_number": 110,
      "content": "ومن يعمل سوا أو يظلم نفسه ثم يستغفر الله يجد الله غفورا رحيما"
    },
    {
      "surah_number": 4,
      "verse_number": 111,
      "content": "ومن يكسب اثما فانما يكسبه علىا نفسه وكان الله عليما حكيما"
    },
    {
      "surah_number": 4,
      "verse_number": 112,
      "content": "ومن يكسب خطئه أو اثما ثم يرم به برئا فقد احتمل بهتانا واثما مبينا"
    },
    {
      "surah_number": 4,
      "verse_number": 113,
      "content": "ولولا فضل الله عليك ورحمته لهمت طائفه منهم أن يضلوك وما يضلون الا أنفسهم وما يضرونك من شي وأنزل الله عليك الكتاب والحكمه وعلمك ما لم تكن تعلم وكان فضل الله عليك عظيما"
    },
    {
      "surah_number": 4,
      "verse_number": 114,
      "content": "لا خير في كثير من نجوىاهم الا من أمر بصدقه أو معروف أو اصلاح بين الناس ومن يفعل ذالك ابتغا مرضات الله فسوف نؤتيه أجرا عظيما"
    },
    {
      "surah_number": 4,
      "verse_number": 115,
      "content": "ومن يشاقق الرسول من بعد ما تبين له الهدىا ويتبع غير سبيل المؤمنين نوله ما تولىا ونصله جهنم وسات مصيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 116,
      "content": "ان الله لا يغفر أن يشرك به ويغفر ما دون ذالك لمن يشا ومن يشرك بالله فقد ضل ضلالا بعيدا"
    },
    {
      "surah_number": 4,
      "verse_number": 117,
      "content": "ان يدعون من دونه الا اناثا وان يدعون الا شيطانا مريدا"
    },
    {
      "surah_number": 4,
      "verse_number": 118,
      "content": "لعنه الله وقال لأتخذن من عبادك نصيبا مفروضا"
    },
    {
      "surah_number": 4,
      "verse_number": 119,
      "content": "ولأضلنهم ولأمنينهم ولأمرنهم فليبتكن اذان الأنعام ولأمرنهم فليغيرن خلق الله ومن يتخذ الشيطان وليا من دون الله فقد خسر خسرانا مبينا"
    },
    {
      "surah_number": 4,
      "verse_number": 120,
      "content": "يعدهم ويمنيهم وما يعدهم الشيطان الا غرورا"
    },
    {
      "surah_number": 4,
      "verse_number": 121,
      "content": "أولائك مأوىاهم جهنم ولا يجدون عنها محيصا"
    },
    {
      "surah_number": 4,
      "verse_number": 122,
      "content": "والذين امنوا وعملوا الصالحات سندخلهم جنات تجري من تحتها الأنهار خالدين فيها أبدا وعد الله حقا ومن أصدق من الله قيلا"
    },
    {
      "surah_number": 4,
      "verse_number": 123,
      "content": "ليس بأمانيكم ولا أماني أهل الكتاب من يعمل سوا يجز به ولا يجد له من دون الله وليا ولا نصيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 124,
      "content": "ومن يعمل من الصالحات من ذكر أو أنثىا وهو مؤمن فأولائك يدخلون الجنه ولا يظلمون نقيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 125,
      "content": "ومن أحسن دينا ممن أسلم وجهه لله وهو محسن واتبع مله ابراهيم حنيفا واتخذ الله ابراهيم خليلا"
    },
    {
      "surah_number": 4,
      "verse_number": 126,
      "content": "ولله ما في السماوات وما في الأرض وكان الله بكل شي محيطا"
    },
    {
      "surah_number": 4,
      "verse_number": 127,
      "content": "ويستفتونك في النسا قل الله يفتيكم فيهن وما يتلىا عليكم في الكتاب في يتامى النسا الاتي لا تؤتونهن ما كتب لهن وترغبون أن تنكحوهن والمستضعفين من الولدان وأن تقوموا لليتامىا بالقسط وما تفعلوا من خير فان الله كان به عليما"
    },
    {
      "surah_number": 4,
      "verse_number": 128,
      "content": "وان امرأه خافت من بعلها نشوزا أو اعراضا فلا جناح عليهما أن يصلحا بينهما صلحا والصلح خير وأحضرت الأنفس الشح وان تحسنوا وتتقوا فان الله كان بما تعملون خبيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 129,
      "content": "ولن تستطيعوا أن تعدلوا بين النسا ولو حرصتم فلا تميلوا كل الميل فتذروها كالمعلقه وان تصلحوا وتتقوا فان الله كان غفورا رحيما"
    },
    {
      "surah_number": 4,
      "verse_number": 130,
      "content": "وان يتفرقا يغن الله كلا من سعته وكان الله واسعا حكيما"
    },
    {
      "surah_number": 4,
      "verse_number": 131,
      "content": "ولله ما في السماوات وما في الأرض ولقد وصينا الذين أوتوا الكتاب من قبلكم واياكم أن اتقوا الله وان تكفروا فان لله ما في السماوات وما في الأرض وكان الله غنيا حميدا"
    },
    {
      "surah_number": 4,
      "verse_number": 132,
      "content": "ولله ما في السماوات وما في الأرض وكفىا بالله وكيلا"
    },
    {
      "surah_number": 4,
      "verse_number": 133,
      "content": "ان يشأ يذهبكم أيها الناس ويأت بٔاخرين وكان الله علىا ذالك قديرا"
    },
    {
      "surah_number": 4,
      "verse_number": 134,
      "content": "من كان يريد ثواب الدنيا فعند الله ثواب الدنيا والأخره وكان الله سميعا بصيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 135,
      "content": "ياأيها الذين امنوا كونوا قوامين بالقسط شهدا لله ولو علىا أنفسكم أو الوالدين والأقربين ان يكن غنيا أو فقيرا فالله أولىا بهما فلا تتبعوا الهوىا أن تعدلوا وان تلوا أو تعرضوا فان الله كان بما تعملون خبيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 136,
      "content": "ياأيها الذين امنوا امنوا بالله ورسوله والكتاب الذي نزل علىا رسوله والكتاب الذي أنزل من قبل ومن يكفر بالله وملائكته وكتبه ورسله واليوم الأخر فقد ضل ضلالا بعيدا"
    },
    {
      "surah_number": 4,
      "verse_number": 137,
      "content": "ان الذين امنوا ثم كفروا ثم امنوا ثم كفروا ثم ازدادوا كفرا لم يكن الله ليغفر لهم ولا ليهديهم سبيلا"
    },
    {
      "surah_number": 4,
      "verse_number": 138,
      "content": "بشر المنافقين بأن لهم عذابا أليما"
    },
    {
      "surah_number": 4,
      "verse_number": 139,
      "content": "الذين يتخذون الكافرين أوليا من دون المؤمنين أيبتغون عندهم العزه فان العزه لله جميعا"
    },
    {
      "surah_number": 4,
      "verse_number": 140,
      "content": "وقد نزل عليكم في الكتاب أن اذا سمعتم ايات الله يكفر بها ويستهزأ بها فلا تقعدوا معهم حتىا يخوضوا في حديث غيره انكم اذا مثلهم ان الله جامع المنافقين والكافرين في جهنم جميعا"
    },
    {
      "surah_number": 4,
      "verse_number": 141,
      "content": "الذين يتربصون بكم فان كان لكم فتح من الله قالوا ألم نكن معكم وان كان للكافرين نصيب قالوا ألم نستحوذ عليكم ونمنعكم من المؤمنين فالله يحكم بينكم يوم القيامه ولن يجعل الله للكافرين على المؤمنين سبيلا"
    },
    {
      "surah_number": 4,
      "verse_number": 142,
      "content": "ان المنافقين يخادعون الله وهو خادعهم واذا قاموا الى الصلواه قاموا كسالىا يراون الناس ولا يذكرون الله الا قليلا"
    },
    {
      "surah_number": 4,
      "verse_number": 143,
      "content": "مذبذبين بين ذالك لا الىا هاؤلا ولا الىا هاؤلا ومن يضلل الله فلن تجد له سبيلا"
    },
    {
      "surah_number": 4,
      "verse_number": 144,
      "content": "ياأيها الذين امنوا لا تتخذوا الكافرين أوليا من دون المؤمنين أتريدون أن تجعلوا لله عليكم سلطانا مبينا"
    },
    {
      "surah_number": 4,
      "verse_number": 145,
      "content": "ان المنافقين في الدرك الأسفل من النار ولن تجد لهم نصيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 146,
      "content": "الا الذين تابوا وأصلحوا واعتصموا بالله وأخلصوا دينهم لله فأولائك مع المؤمنين وسوف يؤت الله المؤمنين أجرا عظيما"
    },
    {
      "surah_number": 4,
      "verse_number": 147,
      "content": "ما يفعل الله بعذابكم ان شكرتم وامنتم وكان الله شاكرا عليما"
    },
    {
      "surah_number": 4,
      "verse_number": 148,
      "content": "لا يحب الله الجهر بالسو من القول الا من ظلم وكان الله سميعا عليما"
    },
    {
      "surah_number": 4,
      "verse_number": 149,
      "content": "ان تبدوا خيرا أو تخفوه أو تعفوا عن سو فان الله كان عفوا قديرا"
    },
    {
      "surah_number": 4,
      "verse_number": 150,
      "content": "ان الذين يكفرون بالله ورسله ويريدون أن يفرقوا بين الله ورسله ويقولون نؤمن ببعض ونكفر ببعض ويريدون أن يتخذوا بين ذالك سبيلا"
    },
    {
      "surah_number": 4,
      "verse_number": 151,
      "content": "أولائك هم الكافرون حقا وأعتدنا للكافرين عذابا مهينا"
    },
    {
      "surah_number": 4,
      "verse_number": 152,
      "content": "والذين امنوا بالله ورسله ولم يفرقوا بين أحد منهم أولائك سوف يؤتيهم أجورهم وكان الله غفورا رحيما"
    },
    {
      "surah_number": 4,
      "verse_number": 153,
      "content": "يسٔلك أهل الكتاب أن تنزل عليهم كتابا من السما فقد سألوا موسىا أكبر من ذالك فقالوا أرنا الله جهره فأخذتهم الصاعقه بظلمهم ثم اتخذوا العجل من بعد ما جاتهم البينات فعفونا عن ذالك واتينا موسىا سلطانا مبينا"
    },
    {
      "surah_number": 4,
      "verse_number": 154,
      "content": "ورفعنا فوقهم الطور بميثاقهم وقلنا لهم ادخلوا الباب سجدا وقلنا لهم لا تعدوا في السبت وأخذنا منهم ميثاقا غليظا"
    },
    {
      "surah_number": 4,
      "verse_number": 155,
      "content": "فبما نقضهم ميثاقهم وكفرهم بٔايات الله وقتلهم الأنبيا بغير حق وقولهم قلوبنا غلف بل طبع الله عليها بكفرهم فلا يؤمنون الا قليلا"
    },
    {
      "surah_number": 4,
      "verse_number": 156,
      "content": "وبكفرهم وقولهم علىا مريم بهتانا عظيما"
    },
    {
      "surah_number": 4,
      "verse_number": 157,
      "content": "وقولهم انا قتلنا المسيح عيسى ابن مريم رسول الله وما قتلوه وما صلبوه ولاكن شبه لهم وان الذين اختلفوا فيه لفي شك منه ما لهم به من علم الا اتباع الظن وما قتلوه يقينا"
    },
    {
      "surah_number": 4,
      "verse_number": 158,
      "content": "بل رفعه الله اليه وكان الله عزيزا حكيما"
    },
    {
      "surah_number": 4,
      "verse_number": 159,
      "content": "وان من أهل الكتاب الا ليؤمنن به قبل موته ويوم القيامه يكون عليهم شهيدا"
    },
    {
      "surah_number": 4,
      "verse_number": 160,
      "content": "فبظلم من الذين هادوا حرمنا عليهم طيبات أحلت لهم وبصدهم عن سبيل الله كثيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 161,
      "content": "وأخذهم الربواا وقد نهوا عنه وأكلهم أموال الناس بالباطل وأعتدنا للكافرين منهم عذابا أليما"
    },
    {
      "surah_number": 4,
      "verse_number": 162,
      "content": "لاكن الراسخون في العلم منهم والمؤمنون يؤمنون بما أنزل اليك وما أنزل من قبلك والمقيمين الصلواه والمؤتون الزكواه والمؤمنون بالله واليوم الأخر أولائك سنؤتيهم أجرا عظيما"
    },
    {
      "surah_number": 4,
      "verse_number": 163,
      "content": "انا أوحينا اليك كما أوحينا الىا نوح والنبين من بعده وأوحينا الىا ابراهيم واسماعيل واسحاق ويعقوب والأسباط وعيسىا وأيوب ويونس وهارون وسليمان واتينا داود زبورا"
    },
    {
      "surah_number": 4,
      "verse_number": 164,
      "content": "ورسلا قد قصصناهم عليك من قبل ورسلا لم نقصصهم عليك وكلم الله موسىا تكليما"
    },
    {
      "surah_number": 4,
      "verse_number": 165,
      "content": "رسلا مبشرين ومنذرين لئلا يكون للناس على الله حجه بعد الرسل وكان الله عزيزا حكيما"
    },
    {
      "surah_number": 4,
      "verse_number": 166,
      "content": "لاكن الله يشهد بما أنزل اليك أنزله بعلمه والملائكه يشهدون وكفىا بالله شهيدا"
    },
    {
      "surah_number": 4,
      "verse_number": 167,
      "content": "ان الذين كفروا وصدوا عن سبيل الله قد ضلوا ضلالا بعيدا"
    },
    {
      "surah_number": 4,
      "verse_number": 168,
      "content": "ان الذين كفروا وظلموا لم يكن الله ليغفر لهم ولا ليهديهم طريقا"
    },
    {
      "surah_number": 4,
      "verse_number": 169,
      "content": "الا طريق جهنم خالدين فيها أبدا وكان ذالك على الله يسيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 170,
      "content": "ياأيها الناس قد جاكم الرسول بالحق من ربكم فٔامنوا خيرا لكم وان تكفروا فان لله ما في السماوات والأرض وكان الله عليما حكيما"
    },
    {
      "surah_number": 4,
      "verse_number": 171,
      "content": "ياأهل الكتاب لا تغلوا في دينكم ولا تقولوا على الله الا الحق انما المسيح عيسى ابن مريم رسول الله وكلمته ألقىاها الىا مريم وروح منه فٔامنوا بالله ورسله ولا تقولوا ثلاثه انتهوا خيرا لكم انما الله الاه واحد سبحانه أن يكون له ولد له ما في السماوات وما في الأرض وكفىا بالله وكيلا"
    },
    {
      "surah_number": 4,
      "verse_number": 172,
      "content": "لن يستنكف المسيح أن يكون عبدا لله ولا الملائكه المقربون ومن يستنكف عن عبادته ويستكبر فسيحشرهم اليه جميعا"
    },
    {
      "surah_number": 4,
      "verse_number": 173,
      "content": "فأما الذين امنوا وعملوا الصالحات فيوفيهم أجورهم ويزيدهم من فضله وأما الذين استنكفوا واستكبروا فيعذبهم عذابا أليما ولا يجدون لهم من دون الله وليا ولا نصيرا"
    },
    {
      "surah_number": 4,
      "verse_number": 174,
      "content": "ياأيها الناس قد جاكم برهان من ربكم وأنزلنا اليكم نورا مبينا"
    },
    {
      "surah_number": 4,
      "verse_number": 175,
      "content": "فأما الذين امنوا بالله واعتصموا به فسيدخلهم في رحمه منه وفضل ويهديهم اليه صراطا مستقيما"
    },
    {
      "surah_number": 4,
      "verse_number": 176,
      "content": "يستفتونك قل الله يفتيكم في الكلاله ان امرؤا هلك ليس له ولد وله أخت فلها نصف ما ترك وهو يرثها ان لم يكن لها ولد فان كانتا اثنتين فلهما الثلثان مما ترك وان كانوا اخوه رجالا ونسا فللذكر مثل حظ الأنثيين يبين الله لكم أن تضلوا والله بكل شي عليم"
    },
    {
      "surah_number": 5,
      "verse_number": 1,
      "content": "ياأيها الذين امنوا أوفوا بالعقود أحلت لكم بهيمه الأنعام الا ما يتلىا عليكم غير محلي الصيد وأنتم حرم ان الله يحكم ما يريد"
    },
    {
      "surah_number": 5,
      "verse_number": 2,
      "content": "ياأيها الذين امنوا لا تحلوا شعائر الله ولا الشهر الحرام ولا الهدي ولا القلائد ولا امين البيت الحرام يبتغون فضلا من ربهم ورضوانا واذا حللتم فاصطادوا ولا يجرمنكم شنٔان قوم أن صدوكم عن المسجد الحرام أن تعتدوا وتعاونوا على البر والتقوىا ولا تعاونوا على الاثم والعدوان واتقوا الله ان الله شديد العقاب"
    },
    {
      "surah_number": 5,
      "verse_number": 3,
      "content": "حرمت عليكم الميته والدم ولحم الخنزير وما أهل لغير الله به والمنخنقه والموقوذه والمترديه والنطيحه وما أكل السبع الا ما ذكيتم وما ذبح على النصب وأن تستقسموا بالأزلام ذالكم فسق اليوم يئس الذين كفروا من دينكم فلا تخشوهم واخشون اليوم أكملت لكم دينكم وأتممت عليكم نعمتي ورضيت لكم الاسلام دينا فمن اضطر في مخمصه غير متجانف لاثم فان الله غفور رحيم"
    },
    {
      "surah_number": 5,
      "verse_number": 4,
      "content": "يسٔلونك ماذا أحل لهم قل أحل لكم الطيبات وما علمتم من الجوارح مكلبين تعلمونهن مما علمكم الله فكلوا مما أمسكن عليكم واذكروا اسم الله عليه واتقوا الله ان الله سريع الحساب"
    },
    {
      "surah_number": 5,
      "verse_number": 5,
      "content": "اليوم أحل لكم الطيبات وطعام الذين أوتوا الكتاب حل لكم وطعامكم حل لهم والمحصنات من المؤمنات والمحصنات من الذين أوتوا الكتاب من قبلكم اذا اتيتموهن أجورهن محصنين غير مسافحين ولا متخذي أخدان ومن يكفر بالايمان فقد حبط عمله وهو في الأخره من الخاسرين"
    },
    {
      "surah_number": 5,
      "verse_number": 6,
      "content": "ياأيها الذين امنوا اذا قمتم الى الصلواه فاغسلوا وجوهكم وأيديكم الى المرافق وامسحوا بروسكم وأرجلكم الى الكعبين وان كنتم جنبا فاطهروا وان كنتم مرضىا أو علىا سفر أو جا أحد منكم من الغائط أو لامستم النسا فلم تجدوا ما فتيمموا صعيدا طيبا فامسحوا بوجوهكم وأيديكم منه ما يريد الله ليجعل عليكم من حرج ولاكن يريد ليطهركم وليتم نعمته عليكم لعلكم تشكرون"
    },
    {
      "surah_number": 5,
      "verse_number": 7,
      "content": "واذكروا نعمه الله عليكم وميثاقه الذي واثقكم به اذ قلتم سمعنا وأطعنا واتقوا الله ان الله عليم بذات الصدور"
    },
    {
      "surah_number": 5,
      "verse_number": 8,
      "content": "ياأيها الذين امنوا كونوا قوامين لله شهدا بالقسط ولا يجرمنكم شنٔان قوم علىا ألا تعدلوا اعدلوا هو أقرب للتقوىا واتقوا الله ان الله خبير بما تعملون"
    },
    {
      "surah_number": 5,
      "verse_number": 9,
      "content": "وعد الله الذين امنوا وعملوا الصالحات لهم مغفره وأجر عظيم"
    },
    {
      "surah_number": 5,
      "verse_number": 10,
      "content": "والذين كفروا وكذبوا بٔاياتنا أولائك أصحاب الجحيم"
    },
    {
      "surah_number": 5,
      "verse_number": 11,
      "content": "ياأيها الذين امنوا اذكروا نعمت الله عليكم اذ هم قوم أن يبسطوا اليكم أيديهم فكف أيديهم عنكم واتقوا الله وعلى الله فليتوكل المؤمنون"
    },
    {
      "surah_number": 5,
      "verse_number": 12,
      "content": "ولقد أخذ الله ميثاق بني اسرايل وبعثنا منهم اثني عشر نقيبا وقال الله اني معكم لئن أقمتم الصلواه واتيتم الزكواه وامنتم برسلي وعزرتموهم وأقرضتم الله قرضا حسنا لأكفرن عنكم سئاتكم ولأدخلنكم جنات تجري من تحتها الأنهار فمن كفر بعد ذالك منكم فقد ضل سوا السبيل"
    },
    {
      "surah_number": 5,
      "verse_number": 13,
      "content": "فبما نقضهم ميثاقهم لعناهم وجعلنا قلوبهم قاسيه يحرفون الكلم عن مواضعه ونسوا حظا مما ذكروا به ولا تزال تطلع علىا خائنه منهم الا قليلا منهم فاعف عنهم واصفح ان الله يحب المحسنين"
    },
    {
      "surah_number": 5,
      "verse_number": 14,
      "content": "ومن الذين قالوا انا نصارىا أخذنا ميثاقهم فنسوا حظا مما ذكروا به فأغرينا بينهم العداوه والبغضا الىا يوم القيامه وسوف ينبئهم الله بما كانوا يصنعون"
    },
    {
      "surah_number": 5,
      "verse_number": 15,
      "content": "ياأهل الكتاب قد جاكم رسولنا يبين لكم كثيرا مما كنتم تخفون من الكتاب ويعفوا عن كثير قد جاكم من الله نور وكتاب مبين"
    },
    {
      "surah_number": 5,
      "verse_number": 16,
      "content": "يهدي به الله من اتبع رضوانه سبل السلام ويخرجهم من الظلمات الى النور باذنه ويهديهم الىا صراط مستقيم"
    },
    {
      "surah_number": 5,
      "verse_number": 17,
      "content": "لقد كفر الذين قالوا ان الله هو المسيح ابن مريم قل فمن يملك من الله شئا ان أراد أن يهلك المسيح ابن مريم وأمه ومن في الأرض جميعا ولله ملك السماوات والأرض وما بينهما يخلق ما يشا والله علىا كل شي قدير"
    },
    {
      "surah_number": 5,
      "verse_number": 18,
      "content": "وقالت اليهود والنصارىا نحن أبناؤا الله وأحباؤه قل فلم يعذبكم بذنوبكم بل أنتم بشر ممن خلق يغفر لمن يشا ويعذب من يشا ولله ملك السماوات والأرض وما بينهما واليه المصير"
    },
    {
      "surah_number": 5,
      "verse_number": 19,
      "content": "ياأهل الكتاب قد جاكم رسولنا يبين لكم علىا فتره من الرسل أن تقولوا ما جانا من بشير ولا نذير فقد جاكم بشير ونذير والله علىا كل شي قدير"
    },
    {
      "surah_number": 5,
      "verse_number": 20,
      "content": "واذ قال موسىا لقومه ياقوم اذكروا نعمه الله عليكم اذ جعل فيكم أنبيا وجعلكم ملوكا واتىاكم ما لم يؤت أحدا من العالمين"
    },
    {
      "surah_number": 5,
      "verse_number": 21,
      "content": "ياقوم ادخلوا الأرض المقدسه التي كتب الله لكم ولا ترتدوا علىا أدباركم فتنقلبوا خاسرين"
    },
    {
      "surah_number": 5,
      "verse_number": 22,
      "content": "قالوا ياموسىا ان فيها قوما جبارين وانا لن ندخلها حتىا يخرجوا منها فان يخرجوا منها فانا داخلون"
    },
    {
      "surah_number": 5,
      "verse_number": 23,
      "content": "قال رجلان من الذين يخافون أنعم الله عليهما ادخلوا عليهم الباب فاذا دخلتموه فانكم غالبون وعلى الله فتوكلوا ان كنتم مؤمنين"
    },
    {
      "surah_number": 5,
      "verse_number": 24,
      "content": "قالوا ياموسىا انا لن ندخلها أبدا ما داموا فيها فاذهب أنت وربك فقاتلا انا هاهنا قاعدون"
    },
    {
      "surah_number": 5,
      "verse_number": 25,
      "content": "قال رب اني لا أملك الا نفسي وأخي فافرق بيننا وبين القوم الفاسقين"
    },
    {
      "surah_number": 5,
      "verse_number": 26,
      "content": "قال فانها محرمه عليهم أربعين سنه يتيهون في الأرض فلا تأس على القوم الفاسقين"
    },
    {
      "surah_number": 5,
      "verse_number": 27,
      "content": "واتل عليهم نبأ ابني ادم بالحق اذ قربا قربانا فتقبل من أحدهما ولم يتقبل من الأخر قال لأقتلنك قال انما يتقبل الله من المتقين"
    },
    {
      "surah_number": 5,
      "verse_number": 28,
      "content": "لئن بسطت الي يدك لتقتلني ما أنا بباسط يدي اليك لأقتلك اني أخاف الله رب العالمين"
    },
    {
      "surah_number": 5,
      "verse_number": 29,
      "content": "اني أريد أن تبوأ باثمي واثمك فتكون من أصحاب النار وذالك جزاؤا الظالمين"
    },
    {
      "surah_number": 5,
      "verse_number": 30,
      "content": "فطوعت له نفسه قتل أخيه فقتله فأصبح من الخاسرين"
    },
    {
      "surah_number": 5,
      "verse_number": 31,
      "content": "فبعث الله غرابا يبحث في الأرض ليريه كيف يواري سوه أخيه قال ياويلتىا أعجزت أن أكون مثل هاذا الغراب فأواري سوه أخي فأصبح من النادمين"
    },
    {
      "surah_number": 5,
      "verse_number": 32,
      "content": "من أجل ذالك كتبنا علىا بني اسرايل أنه من قتل نفسا بغير نفس أو فساد في الأرض فكأنما قتل الناس جميعا ومن أحياها فكأنما أحيا الناس جميعا ولقد جاتهم رسلنا بالبينات ثم ان كثيرا منهم بعد ذالك في الأرض لمسرفون"
    },
    {
      "surah_number": 5,
      "verse_number": 33,
      "content": "انما جزاؤا الذين يحاربون الله ورسوله ويسعون في الأرض فسادا أن يقتلوا أو يصلبوا أو تقطع أيديهم وأرجلهم من خلاف أو ينفوا من الأرض ذالك لهم خزي في الدنيا ولهم في الأخره عذاب عظيم"
    },
    {
      "surah_number": 5,
      "verse_number": 34,
      "content": "الا الذين تابوا من قبل أن تقدروا عليهم فاعلموا أن الله غفور رحيم"
    },
    {
      "surah_number": 5,
      "verse_number": 35,
      "content": "ياأيها الذين امنوا اتقوا الله وابتغوا اليه الوسيله وجاهدوا في سبيله لعلكم تفلحون"
    },
    {
      "surah_number": 5,
      "verse_number": 36,
      "content": "ان الذين كفروا لو أن لهم ما في الأرض جميعا ومثله معه ليفتدوا به من عذاب يوم القيامه ما تقبل منهم ولهم عذاب أليم"
    },
    {
      "surah_number": 5,
      "verse_number": 37,
      "content": "يريدون أن يخرجوا من النار وما هم بخارجين منها ولهم عذاب مقيم"
    },
    {
      "surah_number": 5,
      "verse_number": 38,
      "content": "والسارق والسارقه فاقطعوا أيديهما جزا بما كسبا نكالا من الله والله عزيز حكيم"
    },
    {
      "surah_number": 5,
      "verse_number": 39,
      "content": "فمن تاب من بعد ظلمه وأصلح فان الله يتوب عليه ان الله غفور رحيم"
    },
    {
      "surah_number": 5,
      "verse_number": 40,
      "content": "ألم تعلم أن الله له ملك السماوات والأرض يعذب من يشا ويغفر لمن يشا والله علىا كل شي قدير"
    },
    {
      "surah_number": 5,
      "verse_number": 41,
      "content": "ياأيها الرسول لا يحزنك الذين يسارعون في الكفر من الذين قالوا امنا بأفواههم ولم تؤمن قلوبهم ومن الذين هادوا سماعون للكذب سماعون لقوم اخرين لم يأتوك يحرفون الكلم من بعد مواضعه يقولون ان أوتيتم هاذا فخذوه وان لم تؤتوه فاحذروا ومن يرد الله فتنته فلن تملك له من الله شئا أولائك الذين لم يرد الله أن يطهر قلوبهم لهم في الدنيا خزي ولهم في الأخره عذاب عظيم"
    },
    {
      "surah_number": 5,
      "verse_number": 42,
      "content": "سماعون للكذب أكالون للسحت فان جاوك فاحكم بينهم أو أعرض عنهم وان تعرض عنهم فلن يضروك شئا وان حكمت فاحكم بينهم بالقسط ان الله يحب المقسطين"
    },
    {
      "surah_number": 5,
      "verse_number": 43,
      "content": "وكيف يحكمونك وعندهم التورىاه فيها حكم الله ثم يتولون من بعد ذالك وما أولائك بالمؤمنين"
    },
    {
      "surah_number": 5,
      "verse_number": 44,
      "content": "انا أنزلنا التورىاه فيها هدى ونور يحكم بها النبيون الذين أسلموا للذين هادوا والربانيون والأحبار بما استحفظوا من كتاب الله وكانوا عليه شهدا فلا تخشوا الناس واخشون ولا تشتروا بٔاياتي ثمنا قليلا ومن لم يحكم بما أنزل الله فأولائك هم الكافرون"
    },
    {
      "surah_number": 5,
      "verse_number": 45,
      "content": "وكتبنا عليهم فيها أن النفس بالنفس والعين بالعين والأنف بالأنف والأذن بالأذن والسن بالسن والجروح قصاص فمن تصدق به فهو كفاره له ومن لم يحكم بما أنزل الله فأولائك هم الظالمون"
    },
    {
      "surah_number": 5,
      "verse_number": 46,
      "content": "وقفينا علىا اثارهم بعيسى ابن مريم مصدقا لما بين يديه من التورىاه واتيناه الانجيل فيه هدى ونور ومصدقا لما بين يديه من التورىاه وهدى وموعظه للمتقين"
    },
    {
      "surah_number": 5,
      "verse_number": 47,
      "content": "وليحكم أهل الانجيل بما أنزل الله فيه ومن لم يحكم بما أنزل الله فأولائك هم الفاسقون"
    },
    {
      "surah_number": 5,
      "verse_number": 48,
      "content": "وأنزلنا اليك الكتاب بالحق مصدقا لما بين يديه من الكتاب ومهيمنا عليه فاحكم بينهم بما أنزل الله ولا تتبع أهواهم عما جاك من الحق لكل جعلنا منكم شرعه ومنهاجا ولو شا الله لجعلكم أمه واحده ولاكن ليبلوكم في ما اتىاكم فاستبقوا الخيرات الى الله مرجعكم جميعا فينبئكم بما كنتم فيه تختلفون"
    },
    {
      "surah_number": 5,
      "verse_number": 49,
      "content": "وأن احكم بينهم بما أنزل الله ولا تتبع أهواهم واحذرهم أن يفتنوك عن بعض ما أنزل الله اليك فان تولوا فاعلم أنما يريد الله أن يصيبهم ببعض ذنوبهم وان كثيرا من الناس لفاسقون"
    },
    {
      "surah_number": 5,
      "verse_number": 50,
      "content": "أفحكم الجاهليه يبغون ومن أحسن من الله حكما لقوم يوقنون"
    },
    {
      "surah_number": 5,
      "verse_number": 51,
      "content": "ياأيها الذين امنوا لا تتخذوا اليهود والنصارىا أوليا بعضهم أوليا بعض ومن يتولهم منكم فانه منهم ان الله لا يهدي القوم الظالمين"
    },
    {
      "surah_number": 5,
      "verse_number": 52,
      "content": "فترى الذين في قلوبهم مرض يسارعون فيهم يقولون نخشىا أن تصيبنا دائره فعسى الله أن يأتي بالفتح أو أمر من عنده فيصبحوا علىا ما أسروا في أنفسهم نادمين"
    },
    {
      "surah_number": 5,
      "verse_number": 53,
      "content": "ويقول الذين امنوا أهاؤلا الذين أقسموا بالله جهد أيمانهم انهم لمعكم حبطت أعمالهم فأصبحوا خاسرين"
    },
    {
      "surah_number": 5,
      "verse_number": 54,
      "content": "ياأيها الذين امنوا من يرتد منكم عن دينه فسوف يأتي الله بقوم يحبهم ويحبونه أذله على المؤمنين أعزه على الكافرين يجاهدون في سبيل الله ولا يخافون لومه لائم ذالك فضل الله يؤتيه من يشا والله واسع عليم"
    },
    {
      "surah_number": 5,
      "verse_number": 55,
      "content": "انما وليكم الله ورسوله والذين امنوا الذين يقيمون الصلواه ويؤتون الزكواه وهم راكعون"
    },
    {
      "surah_number": 5,
      "verse_number": 56,
      "content": "ومن يتول الله ورسوله والذين امنوا فان حزب الله هم الغالبون"
    },
    {
      "surah_number": 5,
      "verse_number": 57,
      "content": "ياأيها الذين امنوا لا تتخذوا الذين اتخذوا دينكم هزوا ولعبا من الذين أوتوا الكتاب من قبلكم والكفار أوليا واتقوا الله ان كنتم مؤمنين"
    },
    {
      "surah_number": 5,
      "verse_number": 58,
      "content": "واذا ناديتم الى الصلواه اتخذوها هزوا ولعبا ذالك بأنهم قوم لا يعقلون"
    },
    {
      "surah_number": 5,
      "verse_number": 59,
      "content": "قل ياأهل الكتاب هل تنقمون منا الا أن امنا بالله وما أنزل الينا وما أنزل من قبل وأن أكثركم فاسقون"
    },
    {
      "surah_number": 5,
      "verse_number": 60,
      "content": "قل هل أنبئكم بشر من ذالك مثوبه عند الله من لعنه الله وغضب عليه وجعل منهم القرده والخنازير وعبد الطاغوت أولائك شر مكانا وأضل عن سوا السبيل"
    },
    {
      "surah_number": 5,
      "verse_number": 61,
      "content": "واذا جاوكم قالوا امنا وقد دخلوا بالكفر وهم قد خرجوا به والله أعلم بما كانوا يكتمون"
    },
    {
      "surah_number": 5,
      "verse_number": 62,
      "content": "وترىا كثيرا منهم يسارعون في الاثم والعدوان وأكلهم السحت لبئس ما كانوا يعملون"
    },
    {
      "surah_number": 5,
      "verse_number": 63,
      "content": "لولا ينهىاهم الربانيون والأحبار عن قولهم الاثم وأكلهم السحت لبئس ما كانوا يصنعون"
    },
    {
      "surah_number": 5,
      "verse_number": 64,
      "content": "وقالت اليهود يد الله مغلوله غلت أيديهم ولعنوا بما قالوا بل يداه مبسوطتان ينفق كيف يشا وليزيدن كثيرا منهم ما أنزل اليك من ربك طغيانا وكفرا وألقينا بينهم العداوه والبغضا الىا يوم القيامه كلما أوقدوا نارا للحرب أطفأها الله ويسعون في الأرض فسادا والله لا يحب المفسدين"
    },
    {
      "surah_number": 5,
      "verse_number": 65,
      "content": "ولو أن أهل الكتاب امنوا واتقوا لكفرنا عنهم سئاتهم ولأدخلناهم جنات النعيم"
    },
    {
      "surah_number": 5,
      "verse_number": 66,
      "content": "ولو أنهم أقاموا التورىاه والانجيل وما أنزل اليهم من ربهم لأكلوا من فوقهم ومن تحت أرجلهم منهم أمه مقتصده وكثير منهم سا ما يعملون"
    },
    {
      "surah_number": 5,
      "verse_number": 67,
      "content": "ياأيها الرسول بلغ ما أنزل اليك من ربك وان لم تفعل فما بلغت رسالته والله يعصمك من الناس ان الله لا يهدي القوم الكافرين"
    },
    {
      "surah_number": 5,
      "verse_number": 68,
      "content": "قل ياأهل الكتاب لستم علىا شي حتىا تقيموا التورىاه والانجيل وما أنزل اليكم من ربكم وليزيدن كثيرا منهم ما أنزل اليك من ربك طغيانا وكفرا فلا تأس على القوم الكافرين"
    },
    {
      "surah_number": 5,
      "verse_number": 69,
      "content": "ان الذين امنوا والذين هادوا والصابٔون والنصارىا من امن بالله واليوم الأخر وعمل صالحا فلا خوف عليهم ولا هم يحزنون"
    },
    {
      "surah_number": 5,
      "verse_number": 70,
      "content": "لقد أخذنا ميثاق بني اسرايل وأرسلنا اليهم رسلا كلما جاهم رسول بما لا تهوىا أنفسهم فريقا كذبوا وفريقا يقتلون"
    },
    {
      "surah_number": 5,
      "verse_number": 71,
      "content": "وحسبوا ألا تكون فتنه فعموا وصموا ثم تاب الله عليهم ثم عموا وصموا كثير منهم والله بصير بما يعملون"
    },
    {
      "surah_number": 5,
      "verse_number": 72,
      "content": "لقد كفر الذين قالوا ان الله هو المسيح ابن مريم وقال المسيح يابني اسرايل اعبدوا الله ربي وربكم انه من يشرك بالله فقد حرم الله عليه الجنه ومأوىاه النار وما للظالمين من أنصار"
    },
    {
      "surah_number": 5,
      "verse_number": 73,
      "content": "لقد كفر الذين قالوا ان الله ثالث ثلاثه وما من الاه الا الاه واحد وان لم ينتهوا عما يقولون ليمسن الذين كفروا منهم عذاب أليم"
    },
    {
      "surah_number": 5,
      "verse_number": 74,
      "content": "أفلا يتوبون الى الله ويستغفرونه والله غفور رحيم"
    },
    {
      "surah_number": 5,
      "verse_number": 75,
      "content": "ما المسيح ابن مريم الا رسول قد خلت من قبله الرسل وأمه صديقه كانا يأكلان الطعام انظر كيف نبين لهم الأيات ثم انظر أنىا يؤفكون"
    },
    {
      "surah_number": 5,
      "verse_number": 76,
      "content": "قل أتعبدون من دون الله ما لا يملك لكم ضرا ولا نفعا والله هو السميع العليم"
    },
    {
      "surah_number": 5,
      "verse_number": 77,
      "content": "قل ياأهل الكتاب لا تغلوا في دينكم غير الحق ولا تتبعوا أهوا قوم قد ضلوا من قبل وأضلوا كثيرا وضلوا عن سوا السبيل"
    },
    {
      "surah_number": 5,
      "verse_number": 78,
      "content": "لعن الذين كفروا من بني اسرايل علىا لسان داود وعيسى ابن مريم ذالك بما عصوا وكانوا يعتدون"
    },
    {
      "surah_number": 5,
      "verse_number": 79,
      "content": "كانوا لا يتناهون عن منكر فعلوه لبئس ما كانوا يفعلون"
    },
    {
      "surah_number": 5,
      "verse_number": 80,
      "content": "ترىا كثيرا منهم يتولون الذين كفروا لبئس ما قدمت لهم أنفسهم أن سخط الله عليهم وفي العذاب هم خالدون"
    },
    {
      "surah_number": 5,
      "verse_number": 81,
      "content": "ولو كانوا يؤمنون بالله والنبي وما أنزل اليه ما اتخذوهم أوليا ولاكن كثيرا منهم فاسقون"
    },
    {
      "surah_number": 5,
      "verse_number": 82,
      "content": "لتجدن أشد الناس عداوه للذين امنوا اليهود والذين أشركوا ولتجدن أقربهم موده للذين امنوا الذين قالوا انا نصارىا ذالك بأن منهم قسيسين ورهبانا وأنهم لا يستكبرون"
    },
    {
      "surah_number": 5,
      "verse_number": 83,
      "content": "واذا سمعوا ما أنزل الى الرسول ترىا أعينهم تفيض من الدمع مما عرفوا من الحق يقولون ربنا امنا فاكتبنا مع الشاهدين"
    },
    {
      "surah_number": 5,
      "verse_number": 84,
      "content": "وما لنا لا نؤمن بالله وما جانا من الحق ونطمع أن يدخلنا ربنا مع القوم الصالحين"
    },
    {
      "surah_number": 5,
      "verse_number": 85,
      "content": "فأثابهم الله بما قالوا جنات تجري من تحتها الأنهار خالدين فيها وذالك جزا المحسنين"
    },
    {
      "surah_number": 5,
      "verse_number": 86,
      "content": "والذين كفروا وكذبوا بٔاياتنا أولائك أصحاب الجحيم"
    },
    {
      "surah_number": 5,
      "verse_number": 87,
      "content": "ياأيها الذين امنوا لا تحرموا طيبات ما أحل الله لكم ولا تعتدوا ان الله لا يحب المعتدين"
    },
    {
      "surah_number": 5,
      "verse_number": 88,
      "content": "وكلوا مما رزقكم الله حلالا طيبا واتقوا الله الذي أنتم به مؤمنون"
    },
    {
      "surah_number": 5,
      "verse_number": 89,
      "content": "لا يؤاخذكم الله باللغو في أيمانكم ولاكن يؤاخذكم بما عقدتم الأيمان فكفارته اطعام عشره مساكين من أوسط ما تطعمون أهليكم أو كسوتهم أو تحرير رقبه فمن لم يجد فصيام ثلاثه أيام ذالك كفاره أيمانكم اذا حلفتم واحفظوا أيمانكم كذالك يبين الله لكم اياته لعلكم تشكرون"
    },
    {
      "surah_number": 5,
      "verse_number": 90,
      "content": "ياأيها الذين امنوا انما الخمر والميسر والأنصاب والأزلام رجس من عمل الشيطان فاجتنبوه لعلكم تفلحون"
    },
    {
      "surah_number": 5,
      "verse_number": 91,
      "content": "انما يريد الشيطان أن يوقع بينكم العداوه والبغضا في الخمر والميسر ويصدكم عن ذكر الله وعن الصلواه فهل أنتم منتهون"
    },
    {
      "surah_number": 5,
      "verse_number": 92,
      "content": "وأطيعوا الله وأطيعوا الرسول واحذروا فان توليتم فاعلموا أنما علىا رسولنا البلاغ المبين"
    },
    {
      "surah_number": 5,
      "verse_number": 93,
      "content": "ليس على الذين امنوا وعملوا الصالحات جناح فيما طعموا اذا ما اتقوا وامنوا وعملوا الصالحات ثم اتقوا وامنوا ثم اتقوا وأحسنوا والله يحب المحسنين"
    },
    {
      "surah_number": 5,
      "verse_number": 94,
      "content": "ياأيها الذين امنوا ليبلونكم الله بشي من الصيد تناله أيديكم ورماحكم ليعلم الله من يخافه بالغيب فمن اعتدىا بعد ذالك فله عذاب أليم"
    },
    {
      "surah_number": 5,
      "verse_number": 95,
      "content": "ياأيها الذين امنوا لا تقتلوا الصيد وأنتم حرم ومن قتله منكم متعمدا فجزا مثل ما قتل من النعم يحكم به ذوا عدل منكم هديا بالغ الكعبه أو كفاره طعام مساكين أو عدل ذالك صياما ليذوق وبال أمره عفا الله عما سلف ومن عاد فينتقم الله منه والله عزيز ذو انتقام"
    },
    {
      "surah_number": 5,
      "verse_number": 96,
      "content": "أحل لكم صيد البحر وطعامه متاعا لكم وللسياره وحرم عليكم صيد البر ما دمتم حرما واتقوا الله الذي اليه تحشرون"
    },
    {
      "surah_number": 5,
      "verse_number": 97,
      "content": "جعل الله الكعبه البيت الحرام قياما للناس والشهر الحرام والهدي والقلائد ذالك لتعلموا أن الله يعلم ما في السماوات وما في الأرض وأن الله بكل شي عليم"
    },
    {
      "surah_number": 5,
      "verse_number": 98,
      "content": "اعلموا أن الله شديد العقاب وأن الله غفور رحيم"
    },
    {
      "surah_number": 5,
      "verse_number": 99,
      "content": "ما على الرسول الا البلاغ والله يعلم ما تبدون وما تكتمون"
    },
    {
      "surah_number": 5,
      "verse_number": 100,
      "content": "قل لا يستوي الخبيث والطيب ولو أعجبك كثره الخبيث فاتقوا الله ياأولي الألباب لعلكم تفلحون"
    },
    {
      "surah_number": 5,
      "verse_number": 101,
      "content": "ياأيها الذين امنوا لا تسٔلوا عن أشيا ان تبد لكم تسؤكم وان تسٔلوا عنها حين ينزل القران تبد لكم عفا الله عنها والله غفور حليم"
    },
    {
      "surah_number": 5,
      "verse_number": 102,
      "content": "قد سألها قوم من قبلكم ثم أصبحوا بها كافرين"
    },
    {
      "surah_number": 5,
      "verse_number": 103,
      "content": "ما جعل الله من بحيره ولا سائبه ولا وصيله ولا حام ولاكن الذين كفروا يفترون على الله الكذب وأكثرهم لا يعقلون"
    },
    {
      "surah_number": 5,
      "verse_number": 104,
      "content": "واذا قيل لهم تعالوا الىا ما أنزل الله والى الرسول قالوا حسبنا ما وجدنا عليه ابانا أولو كان اباؤهم لا يعلمون شئا ولا يهتدون"
    },
    {
      "surah_number": 5,
      "verse_number": 105,
      "content": "ياأيها الذين امنوا عليكم أنفسكم لا يضركم من ضل اذا اهتديتم الى الله مرجعكم جميعا فينبئكم بما كنتم تعملون"
    },
    {
      "surah_number": 5,
      "verse_number": 106,
      "content": "ياأيها الذين امنوا شهاده بينكم اذا حضر أحدكم الموت حين الوصيه اثنان ذوا عدل منكم أو اخران من غيركم ان أنتم ضربتم في الأرض فأصابتكم مصيبه الموت تحبسونهما من بعد الصلواه فيقسمان بالله ان ارتبتم لا نشتري به ثمنا ولو كان ذا قربىا ولا نكتم شهاده الله انا اذا لمن الأثمين"
    },
    {
      "surah_number": 5,
      "verse_number": 107,
      "content": "فان عثر علىا أنهما استحقا اثما فٔاخران يقومان مقامهما من الذين استحق عليهم الأوليان فيقسمان بالله لشهادتنا أحق من شهادتهما وما اعتدينا انا اذا لمن الظالمين"
    },
    {
      "surah_number": 5,
      "verse_number": 108,
      "content": "ذالك أدنىا أن يأتوا بالشهاده علىا وجهها أو يخافوا أن ترد أيمان بعد أيمانهم واتقوا الله واسمعوا والله لا يهدي القوم الفاسقين"
    },
    {
      "surah_number": 5,
      "verse_number": 109,
      "content": "يوم يجمع الله الرسل فيقول ماذا أجبتم قالوا لا علم لنا انك أنت علام الغيوب"
    },
    {
      "surah_number": 5,
      "verse_number": 110,
      "content": "اذ قال الله ياعيسى ابن مريم اذكر نعمتي عليك وعلىا والدتك اذ أيدتك بروح القدس تكلم الناس في المهد وكهلا واذ علمتك الكتاب والحكمه والتورىاه والانجيل واذ تخلق من الطين كهئه الطير باذني فتنفخ فيها فتكون طيرا باذني وتبرئ الأكمه والأبرص باذني واذ تخرج الموتىا باذني واذ كففت بني اسرايل عنك اذ جئتهم بالبينات فقال الذين كفروا منهم ان هاذا الا سحر مبين"
    },
    {
      "surah_number": 5,
      "verse_number": 111,
      "content": "واذ أوحيت الى الحوارين أن امنوا بي وبرسولي قالوا امنا واشهد بأننا مسلمون"
    },
    {
      "surah_number": 5,
      "verse_number": 112,
      "content": "اذ قال الحواريون ياعيسى ابن مريم هل يستطيع ربك أن ينزل علينا مائده من السما قال اتقوا الله ان كنتم مؤمنين"
    },
    {
      "surah_number": 5,
      "verse_number": 113,
      "content": "قالوا نريد أن نأكل منها وتطمئن قلوبنا ونعلم أن قد صدقتنا ونكون عليها من الشاهدين"
    },
    {
      "surah_number": 5,
      "verse_number": 114,
      "content": "قال عيسى ابن مريم اللهم ربنا أنزل علينا مائده من السما تكون لنا عيدا لأولنا واخرنا وايه منك وارزقنا وأنت خير الرازقين"
    },
    {
      "surah_number": 5,
      "verse_number": 115,
      "content": "قال الله اني منزلها عليكم فمن يكفر بعد منكم فاني أعذبه عذابا لا أعذبه أحدا من العالمين"
    },
    {
      "surah_number": 5,
      "verse_number": 116,
      "content": "واذ قال الله ياعيسى ابن مريم ءأنت قلت للناس اتخذوني وأمي الاهين من دون الله قال سبحانك ما يكون لي أن أقول ما ليس لي بحق ان كنت قلته فقد علمته تعلم ما في نفسي ولا أعلم ما في نفسك انك أنت علام الغيوب"
    },
    {
      "surah_number": 5,
      "verse_number": 117,
      "content": "ما قلت لهم الا ما أمرتني به أن اعبدوا الله ربي وربكم وكنت عليهم شهيدا ما دمت فيهم فلما توفيتني كنت أنت الرقيب عليهم وأنت علىا كل شي شهيد"
    },
    {
      "surah_number": 5,
      "verse_number": 118,
      "content": "ان تعذبهم فانهم عبادك وان تغفر لهم فانك أنت العزيز الحكيم"
    },
    {
      "surah_number": 5,
      "verse_number": 119,
      "content": "قال الله هاذا يوم ينفع الصادقين صدقهم لهم جنات تجري من تحتها الأنهار خالدين فيها أبدا رضي الله عنهم ورضوا عنه ذالك الفوز العظيم"
    },
    {
      "surah_number": 5,
      "verse_number": 120,
      "content": "لله ملك السماوات والأرض وما فيهن وهو علىا كل شي قدير"
    },
    {
      "surah_number": 6,
      "verse_number": 1,
      "content": "الحمد لله الذي خلق السماوات والأرض وجعل الظلمات والنور ثم الذين كفروا بربهم يعدلون"
    },
    {
      "surah_number": 6,
      "verse_number": 2,
      "content": "هو الذي خلقكم من طين ثم قضىا أجلا وأجل مسمى عنده ثم أنتم تمترون"
    },
    {
      "surah_number": 6,
      "verse_number": 3,
      "content": "وهو الله في السماوات وفي الأرض يعلم سركم وجهركم ويعلم ما تكسبون"
    },
    {
      "surah_number": 6,
      "verse_number": 4,
      "content": "وما تأتيهم من ايه من ايات ربهم الا كانوا عنها معرضين"
    },
    {
      "surah_number": 6,
      "verse_number": 5,
      "content": "فقد كذبوا بالحق لما جاهم فسوف يأتيهم أنباؤا ما كانوا به يستهزون"
    },
    {
      "surah_number": 6,
      "verse_number": 6,
      "content": "ألم يروا كم أهلكنا من قبلهم من قرن مكناهم في الأرض ما لم نمكن لكم وأرسلنا السما عليهم مدرارا وجعلنا الأنهار تجري من تحتهم فأهلكناهم بذنوبهم وأنشأنا من بعدهم قرنا اخرين"
    },
    {
      "surah_number": 6,
      "verse_number": 7,
      "content": "ولو نزلنا عليك كتابا في قرطاس فلمسوه بأيديهم لقال الذين كفروا ان هاذا الا سحر مبين"
    },
    {
      "surah_number": 6,
      "verse_number": 8,
      "content": "وقالوا لولا أنزل عليه ملك ولو أنزلنا ملكا لقضي الأمر ثم لا ينظرون"
    },
    {
      "surah_number": 6,
      "verse_number": 9,
      "content": "ولو جعلناه ملكا لجعلناه رجلا وللبسنا عليهم ما يلبسون"
    },
    {
      "surah_number": 6,
      "verse_number": 10,
      "content": "ولقد استهزئ برسل من قبلك فحاق بالذين سخروا منهم ما كانوا به يستهزون"
    },
    {
      "surah_number": 6,
      "verse_number": 11,
      "content": "قل سيروا في الأرض ثم انظروا كيف كان عاقبه المكذبين"
    },
    {
      "surah_number": 6,
      "verse_number": 12,
      "content": "قل لمن ما في السماوات والأرض قل لله كتب علىا نفسه الرحمه ليجمعنكم الىا يوم القيامه لا ريب فيه الذين خسروا أنفسهم فهم لا يؤمنون"
    },
    {
      "surah_number": 6,
      "verse_number": 13,
      "content": "وله ما سكن في اليل والنهار وهو السميع العليم"
    },
    {
      "surah_number": 6,
      "verse_number": 14,
      "content": "قل أغير الله أتخذ وليا فاطر السماوات والأرض وهو يطعم ولا يطعم قل اني أمرت أن أكون أول من أسلم ولا تكونن من المشركين"
    },
    {
      "surah_number": 6,
      "verse_number": 15,
      "content": "قل اني أخاف ان عصيت ربي عذاب يوم عظيم"
    },
    {
      "surah_number": 6,
      "verse_number": 16,
      "content": "من يصرف عنه يومئذ فقد رحمه وذالك الفوز المبين"
    },
    {
      "surah_number": 6,
      "verse_number": 17,
      "content": "وان يمسسك الله بضر فلا كاشف له الا هو وان يمسسك بخير فهو علىا كل شي قدير"
    },
    {
      "surah_number": 6,
      "verse_number": 18,
      "content": "وهو القاهر فوق عباده وهو الحكيم الخبير"
    },
    {
      "surah_number": 6,
      "verse_number": 19,
      "content": "قل أي شي أكبر شهاده قل الله شهيد بيني وبينكم وأوحي الي هاذا القران لأنذركم به ومن بلغ أئنكم لتشهدون أن مع الله الهه أخرىا قل لا أشهد قل انما هو الاه واحد وانني بري مما تشركون"
    },
    {
      "surah_number": 6,
      "verse_number": 20,
      "content": "الذين اتيناهم الكتاب يعرفونه كما يعرفون أبناهم الذين خسروا أنفسهم فهم لا يؤمنون"
    },
    {
      "surah_number": 6,
      "verse_number": 21,
      "content": "ومن أظلم ممن افترىا على الله كذبا أو كذب بٔاياته انه لا يفلح الظالمون"
    },
    {
      "surah_number": 6,
      "verse_number": 22,
      "content": "ويوم نحشرهم جميعا ثم نقول للذين أشركوا أين شركاؤكم الذين كنتم تزعمون"
    },
    {
      "surah_number": 6,
      "verse_number": 23,
      "content": "ثم لم تكن فتنتهم الا أن قالوا والله ربنا ما كنا مشركين"
    },
    {
      "surah_number": 6,
      "verse_number": 24,
      "content": "انظر كيف كذبوا علىا أنفسهم وضل عنهم ما كانوا يفترون"
    },
    {
      "surah_number": 6,
      "verse_number": 25,
      "content": "ومنهم من يستمع اليك وجعلنا علىا قلوبهم أكنه أن يفقهوه وفي اذانهم وقرا وان يروا كل ايه لا يؤمنوا بها حتىا اذا جاوك يجادلونك يقول الذين كفروا ان هاذا الا أساطير الأولين"
    },
    {
      "surah_number": 6,
      "verse_number": 26,
      "content": "وهم ينهون عنه وينٔون عنه وان يهلكون الا أنفسهم وما يشعرون"
    },
    {
      "surah_number": 6,
      "verse_number": 27,
      "content": "ولو ترىا اذ وقفوا على النار فقالوا ياليتنا نرد ولا نكذب بٔايات ربنا ونكون من المؤمنين"
    },
    {
      "surah_number": 6,
      "verse_number": 28,
      "content": "بل بدا لهم ما كانوا يخفون من قبل ولو ردوا لعادوا لما نهوا عنه وانهم لكاذبون"
    },
    {
      "surah_number": 6,
      "verse_number": 29,
      "content": "وقالوا ان هي الا حياتنا الدنيا وما نحن بمبعوثين"
    },
    {
      "surah_number": 6,
      "verse_number": 30,
      "content": "ولو ترىا اذ وقفوا علىا ربهم قال أليس هاذا بالحق قالوا بلىا وربنا قال فذوقوا العذاب بما كنتم تكفرون"
    },
    {
      "surah_number": 6,
      "verse_number": 31,
      "content": "قد خسر الذين كذبوا بلقا الله حتىا اذا جاتهم الساعه بغته قالوا ياحسرتنا علىا ما فرطنا فيها وهم يحملون أوزارهم علىا ظهورهم ألا سا ما يزرون"
    },
    {
      "surah_number": 6,
      "verse_number": 32,
      "content": "وما الحيواه الدنيا الا لعب ولهو وللدار الأخره خير للذين يتقون أفلا تعقلون"
    },
    {
      "surah_number": 6,
      "verse_number": 33,
      "content": "قد نعلم انه ليحزنك الذي يقولون فانهم لا يكذبونك ولاكن الظالمين بٔايات الله يجحدون"
    },
    {
      "surah_number": 6,
      "verse_number": 34,
      "content": "ولقد كذبت رسل من قبلك فصبروا علىا ما كذبوا وأوذوا حتىا أتىاهم نصرنا ولا مبدل لكلمات الله ولقد جاك من نباي المرسلين"
    },
    {
      "surah_number": 6,
      "verse_number": 35,
      "content": "وان كان كبر عليك اعراضهم فان استطعت أن تبتغي نفقا في الأرض أو سلما في السما فتأتيهم بٔايه ولو شا الله لجمعهم على الهدىا فلا تكونن من الجاهلين"
    },
    {
      "surah_number": 6,
      "verse_number": 36,
      "content": "انما يستجيب الذين يسمعون والموتىا يبعثهم الله ثم اليه يرجعون"
    },
    {
      "surah_number": 6,
      "verse_number": 37,
      "content": "وقالوا لولا نزل عليه ايه من ربه قل ان الله قادر علىا أن ينزل ايه ولاكن أكثرهم لا يعلمون"
    },
    {
      "surah_number": 6,
      "verse_number": 38,
      "content": "وما من دابه في الأرض ولا طائر يطير بجناحيه الا أمم أمثالكم ما فرطنا في الكتاب من شي ثم الىا ربهم يحشرون"
    },
    {
      "surah_number": 6,
      "verse_number": 39,
      "content": "والذين كذبوا بٔاياتنا صم وبكم في الظلمات من يشا الله يضلله ومن يشأ يجعله علىا صراط مستقيم"
    },
    {
      "surah_number": 6,
      "verse_number": 40,
      "content": "قل أريتكم ان أتىاكم عذاب الله أو أتتكم الساعه أغير الله تدعون ان كنتم صادقين"
    },
    {
      "surah_number": 6,
      "verse_number": 41,
      "content": "بل اياه تدعون فيكشف ما تدعون اليه ان شا وتنسون ما تشركون"
    },
    {
      "surah_number": 6,
      "verse_number": 42,
      "content": "ولقد أرسلنا الىا أمم من قبلك فأخذناهم بالبأسا والضرا لعلهم يتضرعون"
    },
    {
      "surah_number": 6,
      "verse_number": 43,
      "content": "فلولا اذ جاهم بأسنا تضرعوا ولاكن قست قلوبهم وزين لهم الشيطان ما كانوا يعملون"
    },
    {
      "surah_number": 6,
      "verse_number": 44,
      "content": "فلما نسوا ما ذكروا به فتحنا عليهم أبواب كل شي حتىا اذا فرحوا بما أوتوا أخذناهم بغته فاذا هم مبلسون"
    },
    {
      "surah_number": 6,
      "verse_number": 45,
      "content": "فقطع دابر القوم الذين ظلموا والحمد لله رب العالمين"
    },
    {
      "surah_number": 6,
      "verse_number": 46,
      "content": "قل أريتم ان أخذ الله سمعكم وأبصاركم وختم علىا قلوبكم من الاه غير الله يأتيكم به انظر كيف نصرف الأيات ثم هم يصدفون"
    },
    {
      "surah_number": 6,
      "verse_number": 47,
      "content": "قل أريتكم ان أتىاكم عذاب الله بغته أو جهره هل يهلك الا القوم الظالمون"
    },
    {
      "surah_number": 6,
      "verse_number": 48,
      "content": "وما نرسل المرسلين الا مبشرين ومنذرين فمن امن وأصلح فلا خوف عليهم ولا هم يحزنون"
    },
    {
      "surah_number": 6,
      "verse_number": 49,
      "content": "والذين كذبوا بٔاياتنا يمسهم العذاب بما كانوا يفسقون"
    },
    {
      "surah_number": 6,
      "verse_number": 50,
      "content": "قل لا أقول لكم عندي خزائن الله ولا أعلم الغيب ولا أقول لكم اني ملك ان أتبع الا ما يوحىا الي قل هل يستوي الأعمىا والبصير أفلا تتفكرون"
    },
    {
      "surah_number": 6,
      "verse_number": 51,
      "content": "وأنذر به الذين يخافون أن يحشروا الىا ربهم ليس لهم من دونه ولي ولا شفيع لعلهم يتقون"
    },
    {
      "surah_number": 6,
      "verse_number": 52,
      "content": "ولا تطرد الذين يدعون ربهم بالغدواه والعشي يريدون وجهه ما عليك من حسابهم من شي وما من حسابك عليهم من شي فتطردهم فتكون من الظالمين"
    },
    {
      "surah_number": 6,
      "verse_number": 53,
      "content": "وكذالك فتنا بعضهم ببعض ليقولوا أهاؤلا من الله عليهم من بيننا أليس الله بأعلم بالشاكرين"
    },
    {
      "surah_number": 6,
      "verse_number": 54,
      "content": "واذا جاك الذين يؤمنون بٔاياتنا فقل سلام عليكم كتب ربكم علىا نفسه الرحمه أنه من عمل منكم سوا بجهاله ثم تاب من بعده وأصلح فأنه غفور رحيم"
    },
    {
      "surah_number": 6,
      "verse_number": 55,
      "content": "وكذالك نفصل الأيات ولتستبين سبيل المجرمين"
    },
    {
      "surah_number": 6,
      "verse_number": 56,
      "content": "قل اني نهيت أن أعبد الذين تدعون من دون الله قل لا أتبع أهواكم قد ضللت اذا وما أنا من المهتدين"
    },
    {
      "surah_number": 6,
      "verse_number": 57,
      "content": "قل اني علىا بينه من ربي وكذبتم به ما عندي ما تستعجلون به ان الحكم الا لله يقص الحق وهو خير الفاصلين"
    },
    {
      "surah_number": 6,
      "verse_number": 58,
      "content": "قل لو أن عندي ما تستعجلون به لقضي الأمر بيني وبينكم والله أعلم بالظالمين"
    },
    {
      "surah_number": 6,
      "verse_number": 59,
      "content": "وعنده مفاتح الغيب لا يعلمها الا هو ويعلم ما في البر والبحر وما تسقط من ورقه الا يعلمها ولا حبه في ظلمات الأرض ولا رطب ولا يابس الا في كتاب مبين"
    },
    {
      "surah_number": 6,
      "verse_number": 60,
      "content": "وهو الذي يتوفىاكم باليل ويعلم ما جرحتم بالنهار ثم يبعثكم فيه ليقضىا أجل مسمى ثم اليه مرجعكم ثم ينبئكم بما كنتم تعملون"
    },
    {
      "surah_number": 6,
      "verse_number": 61,
      "content": "وهو القاهر فوق عباده ويرسل عليكم حفظه حتىا اذا جا أحدكم الموت توفته رسلنا وهم لا يفرطون"
    },
    {
      "surah_number": 6,
      "verse_number": 62,
      "content": "ثم ردوا الى الله مولىاهم الحق ألا له الحكم وهو أسرع الحاسبين"
    },
    {
      "surah_number": 6,
      "verse_number": 63,
      "content": "قل من ينجيكم من ظلمات البر والبحر تدعونه تضرعا وخفيه لئن أنجىانا من هاذه لنكونن من الشاكرين"
    },
    {
      "surah_number": 6,
      "verse_number": 64,
      "content": "قل الله ينجيكم منها ومن كل كرب ثم أنتم تشركون"
    },
    {
      "surah_number": 6,
      "verse_number": 65,
      "content": "قل هو القادر علىا أن يبعث عليكم عذابا من فوقكم أو من تحت أرجلكم أو يلبسكم شيعا ويذيق بعضكم بأس بعض انظر كيف نصرف الأيات لعلهم يفقهون"
    },
    {
      "surah_number": 6,
      "verse_number": 66,
      "content": "وكذب به قومك وهو الحق قل لست عليكم بوكيل"
    },
    {
      "surah_number": 6,
      "verse_number": 67,
      "content": "لكل نبا مستقر وسوف تعلمون"
    },
    {
      "surah_number": 6,
      "verse_number": 68,
      "content": "واذا رأيت الذين يخوضون في اياتنا فأعرض عنهم حتىا يخوضوا في حديث غيره واما ينسينك الشيطان فلا تقعد بعد الذكرىا مع القوم الظالمين"
    },
    {
      "surah_number": 6,
      "verse_number": 69,
      "content": "وما على الذين يتقون من حسابهم من شي ولاكن ذكرىا لعلهم يتقون"
    },
    {
      "surah_number": 6,
      "verse_number": 70,
      "content": "وذر الذين اتخذوا دينهم لعبا ولهوا وغرتهم الحيواه الدنيا وذكر به أن تبسل نفس بما كسبت ليس لها من دون الله ولي ولا شفيع وان تعدل كل عدل لا يؤخذ منها أولائك الذين أبسلوا بما كسبوا لهم شراب من حميم وعذاب أليم بما كانوا يكفرون"
    },
    {
      "surah_number": 6,
      "verse_number": 71,
      "content": "قل أندعوا من دون الله ما لا ينفعنا ولا يضرنا ونرد علىا أعقابنا بعد اذ هدىانا الله كالذي استهوته الشياطين في الأرض حيران له أصحاب يدعونه الى الهدى ائتنا قل ان هدى الله هو الهدىا وأمرنا لنسلم لرب العالمين"
    },
    {
      "surah_number": 6,
      "verse_number": 72,
      "content": "وأن أقيموا الصلواه واتقوه وهو الذي اليه تحشرون"
    },
    {
      "surah_number": 6,
      "verse_number": 73,
      "content": "وهو الذي خلق السماوات والأرض بالحق ويوم يقول كن فيكون قوله الحق وله الملك يوم ينفخ في الصور عالم الغيب والشهاده وهو الحكيم الخبير"
    },
    {
      "surah_number": 6,
      "verse_number": 74,
      "content": "واذ قال ابراهيم لأبيه ازر أتتخذ أصناما الهه اني أرىاك وقومك في ضلال مبين"
    },
    {
      "surah_number": 6,
      "verse_number": 75,
      "content": "وكذالك نري ابراهيم ملكوت السماوات والأرض وليكون من الموقنين"
    },
    {
      "surah_number": 6,
      "verse_number": 76,
      "content": "فلما جن عليه اليل را كوكبا قال هاذا ربي فلما أفل قال لا أحب الأفلين"
    },
    {
      "surah_number": 6,
      "verse_number": 77,
      "content": "فلما را القمر بازغا قال هاذا ربي فلما أفل قال لئن لم يهدني ربي لأكونن من القوم الضالين"
    },
    {
      "surah_number": 6,
      "verse_number": 78,
      "content": "فلما را الشمس بازغه قال هاذا ربي هاذا أكبر فلما أفلت قال ياقوم اني بري مما تشركون"
    },
    {
      "surah_number": 6,
      "verse_number": 79,
      "content": "اني وجهت وجهي للذي فطر السماوات والأرض حنيفا وما أنا من المشركين"
    },
    {
      "surah_number": 6,
      "verse_number": 80,
      "content": "وحاجه قومه قال أتحاجوني في الله وقد هدىان ولا أخاف ما تشركون به الا أن يشا ربي شئا وسع ربي كل شي علما أفلا تتذكرون"
    },
    {
      "surah_number": 6,
      "verse_number": 81,
      "content": "وكيف أخاف ما أشركتم ولا تخافون أنكم أشركتم بالله ما لم ينزل به عليكم سلطانا فأي الفريقين أحق بالأمن ان كنتم تعلمون"
    },
    {
      "surah_number": 6,
      "verse_number": 82,
      "content": "الذين امنوا ولم يلبسوا ايمانهم بظلم أولائك لهم الأمن وهم مهتدون"
    },
    {
      "surah_number": 6,
      "verse_number": 83,
      "content": "وتلك حجتنا اتيناها ابراهيم علىا قومه نرفع درجات من نشا ان ربك حكيم عليم"
    },
    {
      "surah_number": 6,
      "verse_number": 84,
      "content": "ووهبنا له اسحاق ويعقوب كلا هدينا ونوحا هدينا من قبل ومن ذريته داود وسليمان وأيوب ويوسف وموسىا وهارون وكذالك نجزي المحسنين"
    },
    {
      "surah_number": 6,
      "verse_number": 85,
      "content": "وزكريا ويحيىا وعيسىا والياس كل من الصالحين"
    },
    {
      "surah_number": 6,
      "verse_number": 86,
      "content": "واسماعيل واليسع ويونس ولوطا وكلا فضلنا على العالمين"
    },
    {
      "surah_number": 6,
      "verse_number": 87,
      "content": "ومن ابائهم وذرياتهم واخوانهم واجتبيناهم وهديناهم الىا صراط مستقيم"
    },
    {
      "surah_number": 6,
      "verse_number": 88,
      "content": "ذالك هدى الله يهدي به من يشا من عباده ولو أشركوا لحبط عنهم ما كانوا يعملون"
    },
    {
      "surah_number": 6,
      "verse_number": 89,
      "content": "أولائك الذين اتيناهم الكتاب والحكم والنبوه فان يكفر بها هاؤلا فقد وكلنا بها قوما ليسوا بها بكافرين"
    },
    {
      "surah_number": 6,
      "verse_number": 90,
      "content": "أولائك الذين هدى الله فبهدىاهم اقتده قل لا أسٔلكم عليه أجرا ان هو الا ذكرىا للعالمين"
    },
    {
      "surah_number": 6,
      "verse_number": 91,
      "content": "وما قدروا الله حق قدره اذ قالوا ما أنزل الله علىا بشر من شي قل من أنزل الكتاب الذي جا به موسىا نورا وهدى للناس تجعلونه قراطيس تبدونها وتخفون كثيرا وعلمتم ما لم تعلموا أنتم ولا اباؤكم قل الله ثم ذرهم في خوضهم يلعبون"
    },
    {
      "surah_number": 6,
      "verse_number": 92,
      "content": "وهاذا كتاب أنزلناه مبارك مصدق الذي بين يديه ولتنذر أم القرىا ومن حولها والذين يؤمنون بالأخره يؤمنون به وهم علىا صلاتهم يحافظون"
    },
    {
      "surah_number": 6,
      "verse_number": 93,
      "content": "ومن أظلم ممن افترىا على الله كذبا أو قال أوحي الي ولم يوح اليه شي ومن قال سأنزل مثل ما أنزل الله ولو ترىا اذ الظالمون في غمرات الموت والملائكه باسطوا أيديهم أخرجوا أنفسكم اليوم تجزون عذاب الهون بما كنتم تقولون على الله غير الحق وكنتم عن اياته تستكبرون"
    },
    {
      "surah_number": 6,
      "verse_number": 94,
      "content": "ولقد جئتمونا فرادىا كما خلقناكم أول مره وتركتم ما خولناكم ورا ظهوركم وما نرىا معكم شفعاكم الذين زعمتم أنهم فيكم شركاؤا لقد تقطع بينكم وضل عنكم ما كنتم تزعمون"
    },
    {
      "surah_number": 6,
      "verse_number": 95,
      "content": "ان الله فالق الحب والنوىا يخرج الحي من الميت ومخرج الميت من الحي ذالكم الله فأنىا تؤفكون"
    },
    {
      "surah_number": 6,
      "verse_number": 96,
      "content": "فالق الاصباح وجعل اليل سكنا والشمس والقمر حسبانا ذالك تقدير العزيز العليم"
    },
    {
      "surah_number": 6,
      "verse_number": 97,
      "content": "وهو الذي جعل لكم النجوم لتهتدوا بها في ظلمات البر والبحر قد فصلنا الأيات لقوم يعلمون"
    },
    {
      "surah_number": 6,
      "verse_number": 98,
      "content": "وهو الذي أنشأكم من نفس واحده فمستقر ومستودع قد فصلنا الأيات لقوم يفقهون"
    },
    {
      "surah_number": 6,
      "verse_number": 99,
      "content": "وهو الذي أنزل من السما ما فأخرجنا به نبات كل شي فأخرجنا منه خضرا نخرج منه حبا متراكبا ومن النخل من طلعها قنوان دانيه وجنات من أعناب والزيتون والرمان مشتبها وغير متشابه انظروا الىا ثمره اذا أثمر وينعه ان في ذالكم لأيات لقوم يؤمنون"
    },
    {
      "surah_number": 6,
      "verse_number": 100,
      "content": "وجعلوا لله شركا الجن وخلقهم وخرقوا له بنين وبنات بغير علم سبحانه وتعالىا عما يصفون"
    },
    {
      "surah_number": 6,
      "verse_number": 101,
      "content": "بديع السماوات والأرض أنىا يكون له ولد ولم تكن له صاحبه وخلق كل شي وهو بكل شي عليم"
    },
    {
      "surah_number": 6,
      "verse_number": 102,
      "content": "ذالكم الله ربكم لا الاه الا هو خالق كل شي فاعبدوه وهو علىا كل شي وكيل"
    },
    {
      "surah_number": 6,
      "verse_number": 103,
      "content": "لا تدركه الأبصار وهو يدرك الأبصار وهو اللطيف الخبير"
    },
    {
      "surah_number": 6,
      "verse_number": 104,
      "content": "قد جاكم بصائر من ربكم فمن أبصر فلنفسه ومن عمي فعليها وما أنا عليكم بحفيظ"
    },
    {
      "surah_number": 6,
      "verse_number": 105,
      "content": "وكذالك نصرف الأيات وليقولوا درست ولنبينه لقوم يعلمون"
    },
    {
      "surah_number": 6,
      "verse_number": 106,
      "content": "اتبع ما أوحي اليك من ربك لا الاه الا هو وأعرض عن المشركين"
    },
    {
      "surah_number": 6,
      "verse_number": 107,
      "content": "ولو شا الله ما أشركوا وما جعلناك عليهم حفيظا وما أنت عليهم بوكيل"
    },
    {
      "surah_number": 6,
      "verse_number": 108,
      "content": "ولا تسبوا الذين يدعون من دون الله فيسبوا الله عدوا بغير علم كذالك زينا لكل أمه عملهم ثم الىا ربهم مرجعهم فينبئهم بما كانوا يعملون"
    },
    {
      "surah_number": 6,
      "verse_number": 109,
      "content": "وأقسموا بالله جهد أيمانهم لئن جاتهم ايه ليؤمنن بها قل انما الأيات عند الله وما يشعركم أنها اذا جات لا يؤمنون"
    },
    {
      "surah_number": 6,
      "verse_number": 110,
      "content": "ونقلب أفٔدتهم وأبصارهم كما لم يؤمنوا به أول مره ونذرهم في طغيانهم يعمهون"
    },
    {
      "surah_number": 6,
      "verse_number": 111,
      "content": "ولو أننا نزلنا اليهم الملائكه وكلمهم الموتىا وحشرنا عليهم كل شي قبلا ما كانوا ليؤمنوا الا أن يشا الله ولاكن أكثرهم يجهلون"
    },
    {
      "surah_number": 6,
      "verse_number": 112,
      "content": "وكذالك جعلنا لكل نبي عدوا شياطين الانس والجن يوحي بعضهم الىا بعض زخرف القول غرورا ولو شا ربك ما فعلوه فذرهم وما يفترون"
    },
    {
      "surah_number": 6,
      "verse_number": 113,
      "content": "ولتصغىا اليه أفٔده الذين لا يؤمنون بالأخره وليرضوه وليقترفوا ما هم مقترفون"
    },
    {
      "surah_number": 6,
      "verse_number": 114,
      "content": "أفغير الله أبتغي حكما وهو الذي أنزل اليكم الكتاب مفصلا والذين اتيناهم الكتاب يعلمون أنه منزل من ربك بالحق فلا تكونن من الممترين"
    },
    {
      "surah_number": 6,
      "verse_number": 115,
      "content": "وتمت كلمت ربك صدقا وعدلا لا مبدل لكلماته وهو السميع العليم"
    },
    {
      "surah_number": 6,
      "verse_number": 116,
      "content": "وان تطع أكثر من في الأرض يضلوك عن سبيل الله ان يتبعون الا الظن وان هم الا يخرصون"
    },
    {
      "surah_number": 6,
      "verse_number": 117,
      "content": "ان ربك هو أعلم من يضل عن سبيله وهو أعلم بالمهتدين"
    },
    {
      "surah_number": 6,
      "verse_number": 118,
      "content": "فكلوا مما ذكر اسم الله عليه ان كنتم بٔاياته مؤمنين"
    },
    {
      "surah_number": 6,
      "verse_number": 119,
      "content": "وما لكم ألا تأكلوا مما ذكر اسم الله عليه وقد فصل لكم ما حرم عليكم الا ما اضطررتم اليه وان كثيرا ليضلون بأهوائهم بغير علم ان ربك هو أعلم بالمعتدين"
    },
    {
      "surah_number": 6,
      "verse_number": 120,
      "content": "وذروا ظاهر الاثم وباطنه ان الذين يكسبون الاثم سيجزون بما كانوا يقترفون"
    },
    {
      "surah_number": 6,
      "verse_number": 121,
      "content": "ولا تأكلوا مما لم يذكر اسم الله عليه وانه لفسق وان الشياطين ليوحون الىا أوليائهم ليجادلوكم وان أطعتموهم انكم لمشركون"
    },
    {
      "surah_number": 6,
      "verse_number": 122,
      "content": "أومن كان ميتا فأحييناه وجعلنا له نورا يمشي به في الناس كمن مثله في الظلمات ليس بخارج منها كذالك زين للكافرين ما كانوا يعملون"
    },
    {
      "surah_number": 6,
      "verse_number": 123,
      "content": "وكذالك جعلنا في كل قريه أكابر مجرميها ليمكروا فيها وما يمكرون الا بأنفسهم وما يشعرون"
    },
    {
      "surah_number": 6,
      "verse_number": 124,
      "content": "واذا جاتهم ايه قالوا لن نؤمن حتىا نؤتىا مثل ما أوتي رسل الله الله أعلم حيث يجعل رسالته سيصيب الذين أجرموا صغار عند الله وعذاب شديد بما كانوا يمكرون"
    },
    {
      "surah_number": 6,
      "verse_number": 125,
      "content": "فمن يرد الله أن يهديه يشرح صدره للاسلام ومن يرد أن يضله يجعل صدره ضيقا حرجا كأنما يصعد في السما كذالك يجعل الله الرجس على الذين لا يؤمنون"
    },
    {
      "surah_number": 6,
      "verse_number": 126,
      "content": "وهاذا صراط ربك مستقيما قد فصلنا الأيات لقوم يذكرون"
    },
    {
      "surah_number": 6,
      "verse_number": 127,
      "content": "لهم دار السلام عند ربهم وهو وليهم بما كانوا يعملون"
    },
    {
      "surah_number": 6,
      "verse_number": 128,
      "content": "ويوم يحشرهم جميعا يامعشر الجن قد استكثرتم من الانس وقال أولياؤهم من الانس ربنا استمتع بعضنا ببعض وبلغنا أجلنا الذي أجلت لنا قال النار مثوىاكم خالدين فيها الا ما شا الله ان ربك حكيم عليم"
    },
    {
      "surah_number": 6,
      "verse_number": 129,
      "content": "وكذالك نولي بعض الظالمين بعضا بما كانوا يكسبون"
    },
    {
      "surah_number": 6,
      "verse_number": 130,
      "content": "يامعشر الجن والانس ألم يأتكم رسل منكم يقصون عليكم اياتي وينذرونكم لقا يومكم هاذا قالوا شهدنا علىا أنفسنا وغرتهم الحيواه الدنيا وشهدوا علىا أنفسهم أنهم كانوا كافرين"
    },
    {
      "surah_number": 6,
      "verse_number": 131,
      "content": "ذالك أن لم يكن ربك مهلك القرىا بظلم وأهلها غافلون"
    },
    {
      "surah_number": 6,
      "verse_number": 132,
      "content": "ولكل درجات مما عملوا وما ربك بغافل عما يعملون"
    },
    {
      "surah_number": 6,
      "verse_number": 133,
      "content": "وربك الغني ذو الرحمه ان يشأ يذهبكم ويستخلف من بعدكم ما يشا كما أنشأكم من ذريه قوم اخرين"
    },
    {
      "surah_number": 6,
      "verse_number": 134,
      "content": "ان ما توعدون لأت وما أنتم بمعجزين"
    },
    {
      "surah_number": 6,
      "verse_number": 135,
      "content": "قل ياقوم اعملوا علىا مكانتكم اني عامل فسوف تعلمون من تكون له عاقبه الدار انه لا يفلح الظالمون"
    },
    {
      "surah_number": 6,
      "verse_number": 136,
      "content": "وجعلوا لله مما ذرأ من الحرث والأنعام نصيبا فقالوا هاذا لله بزعمهم وهاذا لشركائنا فما كان لشركائهم فلا يصل الى الله وما كان لله فهو يصل الىا شركائهم سا ما يحكمون"
    },
    {
      "surah_number": 6,
      "verse_number": 137,
      "content": "وكذالك زين لكثير من المشركين قتل أولادهم شركاؤهم ليردوهم وليلبسوا عليهم دينهم ولو شا الله ما فعلوه فذرهم وما يفترون"
    },
    {
      "surah_number": 6,
      "verse_number": 138,
      "content": "وقالوا هاذه أنعام وحرث حجر لا يطعمها الا من نشا بزعمهم وأنعام حرمت ظهورها وأنعام لا يذكرون اسم الله عليها افترا عليه سيجزيهم بما كانوا يفترون"
    },
    {
      "surah_number": 6,
      "verse_number": 139,
      "content": "وقالوا ما في بطون هاذه الأنعام خالصه لذكورنا ومحرم علىا أزواجنا وان يكن ميته فهم فيه شركا سيجزيهم وصفهم انه حكيم عليم"
    },
    {
      "surah_number": 6,
      "verse_number": 140,
      "content": "قد خسر الذين قتلوا أولادهم سفها بغير علم وحرموا ما رزقهم الله افترا على الله قد ضلوا وما كانوا مهتدين"
    },
    {
      "surah_number": 6,
      "verse_number": 141,
      "content": "وهو الذي أنشأ جنات معروشات وغير معروشات والنخل والزرع مختلفا أكله والزيتون والرمان متشابها وغير متشابه كلوا من ثمره اذا أثمر واتوا حقه يوم حصاده ولا تسرفوا انه لا يحب المسرفين"
    },
    {
      "surah_number": 6,
      "verse_number": 142,
      "content": "ومن الأنعام حموله وفرشا كلوا مما رزقكم الله ولا تتبعوا خطوات الشيطان انه لكم عدو مبين"
    },
    {
      "surah_number": 6,
      "verse_number": 143,
      "content": "ثمانيه أزواج من الضأن اثنين ومن المعز اثنين قل الذكرين حرم أم الأنثيين أما اشتملت عليه أرحام الأنثيين نبٔوني بعلم ان كنتم صادقين"
    },
    {
      "surah_number": 6,
      "verse_number": 144,
      "content": "ومن الابل اثنين ومن البقر اثنين قل الذكرين حرم أم الأنثيين أما اشتملت عليه أرحام الأنثيين أم كنتم شهدا اذ وصىاكم الله بهاذا فمن أظلم ممن افترىا على الله كذبا ليضل الناس بغير علم ان الله لا يهدي القوم الظالمين"
    },
    {
      "surah_number": 6,
      "verse_number": 145,
      "content": "قل لا أجد في ما أوحي الي محرما علىا طاعم يطعمه الا أن يكون ميته أو دما مسفوحا أو لحم خنزير فانه رجس أو فسقا أهل لغير الله به فمن اضطر غير باغ ولا عاد فان ربك غفور رحيم"
    },
    {
      "surah_number": 6,
      "verse_number": 146,
      "content": "وعلى الذين هادوا حرمنا كل ذي ظفر ومن البقر والغنم حرمنا عليهم شحومهما الا ما حملت ظهورهما أو الحوايا أو ما اختلط بعظم ذالك جزيناهم ببغيهم وانا لصادقون"
    },
    {
      "surah_number": 6,
      "verse_number": 147,
      "content": "فان كذبوك فقل ربكم ذو رحمه واسعه ولا يرد بأسه عن القوم المجرمين"
    },
    {
      "surah_number": 6,
      "verse_number": 148,
      "content": "سيقول الذين أشركوا لو شا الله ما أشركنا ولا اباؤنا ولا حرمنا من شي كذالك كذب الذين من قبلهم حتىا ذاقوا بأسنا قل هل عندكم من علم فتخرجوه لنا ان تتبعون الا الظن وان أنتم الا تخرصون"
    },
    {
      "surah_number": 6,
      "verse_number": 149,
      "content": "قل فلله الحجه البالغه فلو شا لهدىاكم أجمعين"
    },
    {
      "surah_number": 6,
      "verse_number": 150,
      "content": "قل هلم شهداكم الذين يشهدون أن الله حرم هاذا فان شهدوا فلا تشهد معهم ولا تتبع أهوا الذين كذبوا بٔاياتنا والذين لا يؤمنون بالأخره وهم بربهم يعدلون"
    },
    {
      "surah_number": 6,
      "verse_number": 151,
      "content": "قل تعالوا أتل ما حرم ربكم عليكم ألا تشركوا به شئا وبالوالدين احسانا ولا تقتلوا أولادكم من املاق نحن نرزقكم واياهم ولا تقربوا الفواحش ما ظهر منها وما بطن ولا تقتلوا النفس التي حرم الله الا بالحق ذالكم وصىاكم به لعلكم تعقلون"
    },
    {
      "surah_number": 6,
      "verse_number": 152,
      "content": "ولا تقربوا مال اليتيم الا بالتي هي أحسن حتىا يبلغ أشده وأوفوا الكيل والميزان بالقسط لا نكلف نفسا الا وسعها واذا قلتم فاعدلوا ولو كان ذا قربىا وبعهد الله أوفوا ذالكم وصىاكم به لعلكم تذكرون"
    },
    {
      "surah_number": 6,
      "verse_number": 153,
      "content": "وأن هاذا صراطي مستقيما فاتبعوه ولا تتبعوا السبل فتفرق بكم عن سبيله ذالكم وصىاكم به لعلكم تتقون"
    },
    {
      "surah_number": 6,
      "verse_number": 154,
      "content": "ثم اتينا موسى الكتاب تماما على الذي أحسن وتفصيلا لكل شي وهدى ورحمه لعلهم بلقا ربهم يؤمنون"
    },
    {
      "surah_number": 6,
      "verse_number": 155,
      "content": "وهاذا كتاب أنزلناه مبارك فاتبعوه واتقوا لعلكم ترحمون"
    },
    {
      "surah_number": 6,
      "verse_number": 156,
      "content": "أن تقولوا انما أنزل الكتاب علىا طائفتين من قبلنا وان كنا عن دراستهم لغافلين"
    },
    {
      "surah_number": 6,
      "verse_number": 157,
      "content": "أو تقولوا لو أنا أنزل علينا الكتاب لكنا أهدىا منهم فقد جاكم بينه من ربكم وهدى ورحمه فمن أظلم ممن كذب بٔايات الله وصدف عنها سنجزي الذين يصدفون عن اياتنا سو العذاب بما كانوا يصدفون"
    },
    {
      "surah_number": 6,
      "verse_number": 158,
      "content": "هل ينظرون الا أن تأتيهم الملائكه أو يأتي ربك أو يأتي بعض ايات ربك يوم يأتي بعض ايات ربك لا ينفع نفسا ايمانها لم تكن امنت من قبل أو كسبت في ايمانها خيرا قل انتظروا انا منتظرون"
    },
    {
      "surah_number": 6,
      "verse_number": 159,
      "content": "ان الذين فرقوا دينهم وكانوا شيعا لست منهم في شي انما أمرهم الى الله ثم ينبئهم بما كانوا يفعلون"
    },
    {
      "surah_number": 6,
      "verse_number": 160,
      "content": "من جا بالحسنه فله عشر أمثالها ومن جا بالسيئه فلا يجزىا الا مثلها وهم لا يظلمون"
    },
    {
      "surah_number": 6,
      "verse_number": 161,
      "content": "قل انني هدىاني ربي الىا صراط مستقيم دينا قيما مله ابراهيم حنيفا وما كان من المشركين"
    },
    {
      "surah_number": 6,
      "verse_number": 162,
      "content": "قل ان صلاتي ونسكي ومحياي ومماتي لله رب العالمين"
    },
    {
      "surah_number": 6,
      "verse_number": 163,
      "content": "لا شريك له وبذالك أمرت وأنا أول المسلمين"
    },
    {
      "surah_number": 6,
      "verse_number": 164,
      "content": "قل أغير الله أبغي ربا وهو رب كل شي ولا تكسب كل نفس الا عليها ولا تزر وازره وزر أخرىا ثم الىا ربكم مرجعكم فينبئكم بما كنتم فيه تختلفون"
    },
    {
      "surah_number": 6,
      "verse_number": 165,
      "content": "وهو الذي جعلكم خلائف الأرض ورفع بعضكم فوق بعض درجات ليبلوكم في ما اتىاكم ان ربك سريع العقاب وانه لغفور رحيم"
    },
    {
      "surah_number": 7,
      "verse_number": 1,
      "content": "المص"
    },
    {
      "surah_number": 7,
      "verse_number": 2,
      "content": "كتاب أنزل اليك فلا يكن في صدرك حرج منه لتنذر به وذكرىا للمؤمنين"
    },
    {
      "surah_number": 7,
      "verse_number": 3,
      "content": "اتبعوا ما أنزل اليكم من ربكم ولا تتبعوا من دونه أوليا قليلا ما تذكرون"
    },
    {
      "surah_number": 7,
      "verse_number": 4,
      "content": "وكم من قريه أهلكناها فجاها بأسنا بياتا أو هم قائلون"
    },
    {
      "surah_number": 7,
      "verse_number": 5,
      "content": "فما كان دعوىاهم اذ جاهم بأسنا الا أن قالوا انا كنا ظالمين"
    },
    {
      "surah_number": 7,
      "verse_number": 6,
      "content": "فلنسٔلن الذين أرسل اليهم ولنسٔلن المرسلين"
    },
    {
      "surah_number": 7,
      "verse_number": 7,
      "content": "فلنقصن عليهم بعلم وما كنا غائبين"
    },
    {
      "surah_number": 7,
      "verse_number": 8,
      "content": "والوزن يومئذ الحق فمن ثقلت موازينه فأولائك هم المفلحون"
    },
    {
      "surah_number": 7,
      "verse_number": 9,
      "content": "ومن خفت موازينه فأولائك الذين خسروا أنفسهم بما كانوا بٔاياتنا يظلمون"
    },
    {
      "surah_number": 7,
      "verse_number": 10,
      "content": "ولقد مكناكم في الأرض وجعلنا لكم فيها معايش قليلا ما تشكرون"
    },
    {
      "surah_number": 7,
      "verse_number": 11,
      "content": "ولقد خلقناكم ثم صورناكم ثم قلنا للملائكه اسجدوا لأدم فسجدوا الا ابليس لم يكن من الساجدين"
    },
    {
      "surah_number": 7,
      "verse_number": 12,
      "content": "قال ما منعك ألا تسجد اذ أمرتك قال أنا خير منه خلقتني من نار وخلقته من طين"
    },
    {
      "surah_number": 7,
      "verse_number": 13,
      "content": "قال فاهبط منها فما يكون لك أن تتكبر فيها فاخرج انك من الصاغرين"
    },
    {
      "surah_number": 7,
      "verse_number": 14,
      "content": "قال أنظرني الىا يوم يبعثون"
    },
    {
      "surah_number": 7,
      "verse_number": 15,
      "content": "قال انك من المنظرين"
    },
    {
      "surah_number": 7,
      "verse_number": 16,
      "content": "قال فبما أغويتني لأقعدن لهم صراطك المستقيم"
    },
    {
      "surah_number": 7,
      "verse_number": 17,
      "content": "ثم لأتينهم من بين أيديهم ومن خلفهم وعن أيمانهم وعن شمائلهم ولا تجد أكثرهم شاكرين"
    },
    {
      "surah_number": 7,
      "verse_number": 18,
      "content": "قال اخرج منها مذوما مدحورا لمن تبعك منهم لأملأن جهنم منكم أجمعين"
    },
    {
      "surah_number": 7,
      "verse_number": 19,
      "content": "ويأادم اسكن أنت وزوجك الجنه فكلا من حيث شئتما ولا تقربا هاذه الشجره فتكونا من الظالمين"
    },
    {
      "surah_number": 7,
      "verse_number": 20,
      "content": "فوسوس لهما الشيطان ليبدي لهما ما وري عنهما من سواتهما وقال ما نهىاكما ربكما عن هاذه الشجره الا أن تكونا ملكين أو تكونا من الخالدين"
    },
    {
      "surah_number": 7,
      "verse_number": 21,
      "content": "وقاسمهما اني لكما لمن الناصحين"
    },
    {
      "surah_number": 7,
      "verse_number": 22,
      "content": "فدلىاهما بغرور فلما ذاقا الشجره بدت لهما سواتهما وطفقا يخصفان عليهما من ورق الجنه ونادىاهما ربهما ألم أنهكما عن تلكما الشجره وأقل لكما ان الشيطان لكما عدو مبين"
    },
    {
      "surah_number": 7,
      "verse_number": 23,
      "content": "قالا ربنا ظلمنا أنفسنا وان لم تغفر لنا وترحمنا لنكونن من الخاسرين"
    },
    {
      "surah_number": 7,
      "verse_number": 24,
      "content": "قال اهبطوا بعضكم لبعض عدو ولكم في الأرض مستقر ومتاع الىا حين"
    },
    {
      "surah_number": 7,
      "verse_number": 25,
      "content": "قال فيها تحيون وفيها تموتون ومنها تخرجون"
    },
    {
      "surah_number": 7,
      "verse_number": 26,
      "content": "يابني ادم قد أنزلنا عليكم لباسا يواري سواتكم وريشا ولباس التقوىا ذالك خير ذالك من ايات الله لعلهم يذكرون"
    },
    {
      "surah_number": 7,
      "verse_number": 27,
      "content": "يابني ادم لا يفتننكم الشيطان كما أخرج أبويكم من الجنه ينزع عنهما لباسهما ليريهما سواتهما انه يرىاكم هو وقبيله من حيث لا ترونهم انا جعلنا الشياطين أوليا للذين لا يؤمنون"
    },
    {
      "surah_number": 7,
      "verse_number": 28,
      "content": "واذا فعلوا فاحشه قالوا وجدنا عليها ابانا والله أمرنا بها قل ان الله لا يأمر بالفحشا أتقولون على الله ما لا تعلمون"
    },
    {
      "surah_number": 7,
      "verse_number": 29,
      "content": "قل أمر ربي بالقسط وأقيموا وجوهكم عند كل مسجد وادعوه مخلصين له الدين كما بدأكم تعودون"
    },
    {
      "surah_number": 7,
      "verse_number": 30,
      "content": "فريقا هدىا وفريقا حق عليهم الضلاله انهم اتخذوا الشياطين أوليا من دون الله ويحسبون أنهم مهتدون"
    },
    {
      "surah_number": 7,
      "verse_number": 31,
      "content": "يابني ادم خذوا زينتكم عند كل مسجد وكلوا واشربوا ولا تسرفوا انه لا يحب المسرفين"
    },
    {
      "surah_number": 7,
      "verse_number": 32,
      "content": "قل من حرم زينه الله التي أخرج لعباده والطيبات من الرزق قل هي للذين امنوا في الحيواه الدنيا خالصه يوم القيامه كذالك نفصل الأيات لقوم يعلمون"
    },
    {
      "surah_number": 7,
      "verse_number": 33,
      "content": "قل انما حرم ربي الفواحش ما ظهر منها وما بطن والاثم والبغي بغير الحق وأن تشركوا بالله ما لم ينزل به سلطانا وأن تقولوا على الله ما لا تعلمون"
    },
    {
      "surah_number": 7,
      "verse_number": 34,
      "content": "ولكل أمه أجل فاذا جا أجلهم لا يستأخرون ساعه ولا يستقدمون"
    },
    {
      "surah_number": 7,
      "verse_number": 35,
      "content": "يابني ادم اما يأتينكم رسل منكم يقصون عليكم اياتي فمن اتقىا وأصلح فلا خوف عليهم ولا هم يحزنون"
    },
    {
      "surah_number": 7,
      "verse_number": 36,
      "content": "والذين كذبوا بٔاياتنا واستكبروا عنها أولائك أصحاب النار هم فيها خالدون"
    },
    {
      "surah_number": 7,
      "verse_number": 37,
      "content": "فمن أظلم ممن افترىا على الله كذبا أو كذب بٔاياته أولائك ينالهم نصيبهم من الكتاب حتىا اذا جاتهم رسلنا يتوفونهم قالوا أين ما كنتم تدعون من دون الله قالوا ضلوا عنا وشهدوا علىا أنفسهم أنهم كانوا كافرين"
    },
    {
      "surah_number": 7,
      "verse_number": 38,
      "content": "قال ادخلوا في أمم قد خلت من قبلكم من الجن والانس في النار كلما دخلت أمه لعنت أختها حتىا اذا اداركوا فيها جميعا قالت أخرىاهم لأولىاهم ربنا هاؤلا أضلونا فٔاتهم عذابا ضعفا من النار قال لكل ضعف ولاكن لا تعلمون"
    },
    {
      "surah_number": 7,
      "verse_number": 39,
      "content": "وقالت أولىاهم لأخرىاهم فما كان لكم علينا من فضل فذوقوا العذاب بما كنتم تكسبون"
    },
    {
      "surah_number": 7,
      "verse_number": 40,
      "content": "ان الذين كذبوا بٔاياتنا واستكبروا عنها لا تفتح لهم أبواب السما ولا يدخلون الجنه حتىا يلج الجمل في سم الخياط وكذالك نجزي المجرمين"
    },
    {
      "surah_number": 7,
      "verse_number": 41,
      "content": "لهم من جهنم مهاد ومن فوقهم غواش وكذالك نجزي الظالمين"
    },
    {
      "surah_number": 7,
      "verse_number": 42,
      "content": "والذين امنوا وعملوا الصالحات لا نكلف نفسا الا وسعها أولائك أصحاب الجنه هم فيها خالدون"
    },
    {
      "surah_number": 7,
      "verse_number": 43,
      "content": "ونزعنا ما في صدورهم من غل تجري من تحتهم الأنهار وقالوا الحمد لله الذي هدىانا لهاذا وما كنا لنهتدي لولا أن هدىانا الله لقد جات رسل ربنا بالحق ونودوا أن تلكم الجنه أورثتموها بما كنتم تعملون"
    },
    {
      "surah_number": 7,
      "verse_number": 44,
      "content": "ونادىا أصحاب الجنه أصحاب النار أن قد وجدنا ما وعدنا ربنا حقا فهل وجدتم ما وعد ربكم حقا قالوا نعم فأذن مؤذن بينهم أن لعنه الله على الظالمين"
    },
    {
      "surah_number": 7,
      "verse_number": 45,
      "content": "الذين يصدون عن سبيل الله ويبغونها عوجا وهم بالأخره كافرون"
    },
    {
      "surah_number": 7,
      "verse_number": 46,
      "content": "وبينهما حجاب وعلى الأعراف رجال يعرفون كلا بسيمىاهم ونادوا أصحاب الجنه أن سلام عليكم لم يدخلوها وهم يطمعون"
    },
    {
      "surah_number": 7,
      "verse_number": 47,
      "content": "واذا صرفت أبصارهم تلقا أصحاب النار قالوا ربنا لا تجعلنا مع القوم الظالمين"
    },
    {
      "surah_number": 7,
      "verse_number": 48,
      "content": "ونادىا أصحاب الأعراف رجالا يعرفونهم بسيمىاهم قالوا ما أغنىا عنكم جمعكم وما كنتم تستكبرون"
    },
    {
      "surah_number": 7,
      "verse_number": 49,
      "content": "أهاؤلا الذين أقسمتم لا ينالهم الله برحمه ادخلوا الجنه لا خوف عليكم ولا أنتم تحزنون"
    },
    {
      "surah_number": 7,
      "verse_number": 50,
      "content": "ونادىا أصحاب النار أصحاب الجنه أن أفيضوا علينا من الما أو مما رزقكم الله قالوا ان الله حرمهما على الكافرين"
    },
    {
      "surah_number": 7,
      "verse_number": 51,
      "content": "الذين اتخذوا دينهم لهوا ولعبا وغرتهم الحيواه الدنيا فاليوم ننسىاهم كما نسوا لقا يومهم هاذا وما كانوا بٔاياتنا يجحدون"
    },
    {
      "surah_number": 7,
      "verse_number": 52,
      "content": "ولقد جئناهم بكتاب فصلناه علىا علم هدى ورحمه لقوم يؤمنون"
    },
    {
      "surah_number": 7,
      "verse_number": 53,
      "content": "هل ينظرون الا تأويله يوم يأتي تأويله يقول الذين نسوه من قبل قد جات رسل ربنا بالحق فهل لنا من شفعا فيشفعوا لنا أو نرد فنعمل غير الذي كنا نعمل قد خسروا أنفسهم وضل عنهم ما كانوا يفترون"
    },
    {
      "surah_number": 7,
      "verse_number": 54,
      "content": "ان ربكم الله الذي خلق السماوات والأرض في سته أيام ثم استوىا على العرش يغشي اليل النهار يطلبه حثيثا والشمس والقمر والنجوم مسخرات بأمره ألا له الخلق والأمر تبارك الله رب العالمين"
    },
    {
      "surah_number": 7,
      "verse_number": 55,
      "content": "ادعوا ربكم تضرعا وخفيه انه لا يحب المعتدين"
    },
    {
      "surah_number": 7,
      "verse_number": 56,
      "content": "ولا تفسدوا في الأرض بعد اصلاحها وادعوه خوفا وطمعا ان رحمت الله قريب من المحسنين"
    },
    {
      "surah_number": 7,
      "verse_number": 57,
      "content": "وهو الذي يرسل الرياح بشرا بين يدي رحمته حتىا اذا أقلت سحابا ثقالا سقناه لبلد ميت فأنزلنا به الما فأخرجنا به من كل الثمرات كذالك نخرج الموتىا لعلكم تذكرون"
    },
    {
      "surah_number": 7,
      "verse_number": 58,
      "content": "والبلد الطيب يخرج نباته باذن ربه والذي خبث لا يخرج الا نكدا كذالك نصرف الأيات لقوم يشكرون"
    },
    {
      "surah_number": 7,
      "verse_number": 59,
      "content": "لقد أرسلنا نوحا الىا قومه فقال ياقوم اعبدوا الله ما لكم من الاه غيره اني أخاف عليكم عذاب يوم عظيم"
    },
    {
      "surah_number": 7,
      "verse_number": 60,
      "content": "قال الملأ من قومه انا لنرىاك في ضلال مبين"
    },
    {
      "surah_number": 7,
      "verse_number": 61,
      "content": "قال ياقوم ليس بي ضلاله ولاكني رسول من رب العالمين"
    },
    {
      "surah_number": 7,
      "verse_number": 62,
      "content": "أبلغكم رسالات ربي وأنصح لكم وأعلم من الله ما لا تعلمون"
    },
    {
      "surah_number": 7,
      "verse_number": 63,
      "content": "أوعجبتم أن جاكم ذكر من ربكم علىا رجل منكم لينذركم ولتتقوا ولعلكم ترحمون"
    },
    {
      "surah_number": 7,
      "verse_number": 64,
      "content": "فكذبوه فأنجيناه والذين معه في الفلك وأغرقنا الذين كذبوا بٔاياتنا انهم كانوا قوما عمين"
    },
    {
      "surah_number": 7,
      "verse_number": 65,
      "content": "والىا عاد أخاهم هودا قال ياقوم اعبدوا الله ما لكم من الاه غيره أفلا تتقون"
    },
    {
      "surah_number": 7,
      "verse_number": 66,
      "content": "قال الملأ الذين كفروا من قومه انا لنرىاك في سفاهه وانا لنظنك من الكاذبين"
    },
    {
      "surah_number": 7,
      "verse_number": 67,
      "content": "قال ياقوم ليس بي سفاهه ولاكني رسول من رب العالمين"
    },
    {
      "surah_number": 7,
      "verse_number": 68,
      "content": "أبلغكم رسالات ربي وأنا لكم ناصح أمين"
    },
    {
      "surah_number": 7,
      "verse_number": 69,
      "content": "أوعجبتم أن جاكم ذكر من ربكم علىا رجل منكم لينذركم واذكروا اذ جعلكم خلفا من بعد قوم نوح وزادكم في الخلق بصطه فاذكروا الا الله لعلكم تفلحون"
    },
    {
      "surah_number": 7,
      "verse_number": 70,
      "content": "قالوا أجئتنا لنعبد الله وحده ونذر ما كان يعبد اباؤنا فأتنا بما تعدنا ان كنت من الصادقين"
    },
    {
      "surah_number": 7,
      "verse_number": 71,
      "content": "قال قد وقع عليكم من ربكم رجس وغضب أتجادلونني في أسما سميتموها أنتم واباؤكم ما نزل الله بها من سلطان فانتظروا اني معكم من المنتظرين"
    },
    {
      "surah_number": 7,
      "verse_number": 72,
      "content": "فأنجيناه والذين معه برحمه منا وقطعنا دابر الذين كذبوا بٔاياتنا وما كانوا مؤمنين"
    },
    {
      "surah_number": 7,
      "verse_number": 73,
      "content": "والىا ثمود أخاهم صالحا قال ياقوم اعبدوا الله ما لكم من الاه غيره قد جاتكم بينه من ربكم هاذه ناقه الله لكم ايه فذروها تأكل في أرض الله ولا تمسوها بسو فيأخذكم عذاب أليم"
    },
    {
      "surah_number": 7,
      "verse_number": 74,
      "content": "واذكروا اذ جعلكم خلفا من بعد عاد وبوأكم في الأرض تتخذون من سهولها قصورا وتنحتون الجبال بيوتا فاذكروا الا الله ولا تعثوا في الأرض مفسدين"
    },
    {
      "surah_number": 7,
      "verse_number": 75,
      "content": "قال الملأ الذين استكبروا من قومه للذين استضعفوا لمن امن منهم أتعلمون أن صالحا مرسل من ربه قالوا انا بما أرسل به مؤمنون"
    },
    {
      "surah_number": 7,
      "verse_number": 76,
      "content": "قال الذين استكبروا انا بالذي امنتم به كافرون"
    },
    {
      "surah_number": 7,
      "verse_number": 77,
      "content": "فعقروا الناقه وعتوا عن أمر ربهم وقالوا ياصالح ائتنا بما تعدنا ان كنت من المرسلين"
    },
    {
      "surah_number": 7,
      "verse_number": 78,
      "content": "فأخذتهم الرجفه فأصبحوا في دارهم جاثمين"
    },
    {
      "surah_number": 7,
      "verse_number": 79,
      "content": "فتولىا عنهم وقال ياقوم لقد أبلغتكم رساله ربي ونصحت لكم ولاكن لا تحبون الناصحين"
    },
    {
      "surah_number": 7,
      "verse_number": 80,
      "content": "ولوطا اذ قال لقومه أتأتون الفاحشه ما سبقكم بها من أحد من العالمين"
    },
    {
      "surah_number": 7,
      "verse_number": 81,
      "content": "انكم لتأتون الرجال شهوه من دون النسا بل أنتم قوم مسرفون"
    },
    {
      "surah_number": 7,
      "verse_number": 82,
      "content": "وما كان جواب قومه الا أن قالوا أخرجوهم من قريتكم انهم أناس يتطهرون"
    },
    {
      "surah_number": 7,
      "verse_number": 83,
      "content": "فأنجيناه وأهله الا امرأته كانت من الغابرين"
    },
    {
      "surah_number": 7,
      "verse_number": 84,
      "content": "وأمطرنا عليهم مطرا فانظر كيف كان عاقبه المجرمين"
    },
    {
      "surah_number": 7,
      "verse_number": 85,
      "content": "والىا مدين أخاهم شعيبا قال ياقوم اعبدوا الله ما لكم من الاه غيره قد جاتكم بينه من ربكم فأوفوا الكيل والميزان ولا تبخسوا الناس أشياهم ولا تفسدوا في الأرض بعد اصلاحها ذالكم خير لكم ان كنتم مؤمنين"
    },
    {
      "surah_number": 7,
      "verse_number": 86,
      "content": "ولا تقعدوا بكل صراط توعدون وتصدون عن سبيل الله من امن به وتبغونها عوجا واذكروا اذ كنتم قليلا فكثركم وانظروا كيف كان عاقبه المفسدين"
    },
    {
      "surah_number": 7,
      "verse_number": 87,
      "content": "وان كان طائفه منكم امنوا بالذي أرسلت به وطائفه لم يؤمنوا فاصبروا حتىا يحكم الله بيننا وهو خير الحاكمين"
    },
    {
      "surah_number": 7,
      "verse_number": 88,
      "content": "قال الملأ الذين استكبروا من قومه لنخرجنك ياشعيب والذين امنوا معك من قريتنا أو لتعودن في ملتنا قال أولو كنا كارهين"
    },
    {
      "surah_number": 7,
      "verse_number": 89,
      "content": "قد افترينا على الله كذبا ان عدنا في ملتكم بعد اذ نجىانا الله منها وما يكون لنا أن نعود فيها الا أن يشا الله ربنا وسع ربنا كل شي علما على الله توكلنا ربنا افتح بيننا وبين قومنا بالحق وأنت خير الفاتحين"
    },
    {
      "surah_number": 7,
      "verse_number": 90,
      "content": "وقال الملأ الذين كفروا من قومه لئن اتبعتم شعيبا انكم اذا لخاسرون"
    },
    {
      "surah_number": 7,
      "verse_number": 91,
      "content": "فأخذتهم الرجفه فأصبحوا في دارهم جاثمين"
    },
    {
      "surah_number": 7,
      "verse_number": 92,
      "content": "الذين كذبوا شعيبا كأن لم يغنوا فيها الذين كذبوا شعيبا كانوا هم الخاسرين"
    },
    {
      "surah_number": 7,
      "verse_number": 93,
      "content": "فتولىا عنهم وقال ياقوم لقد أبلغتكم رسالات ربي ونصحت لكم فكيف اسىا علىا قوم كافرين"
    },
    {
      "surah_number": 7,
      "verse_number": 94,
      "content": "وما أرسلنا في قريه من نبي الا أخذنا أهلها بالبأسا والضرا لعلهم يضرعون"
    },
    {
      "surah_number": 7,
      "verse_number": 95,
      "content": "ثم بدلنا مكان السيئه الحسنه حتىا عفوا وقالوا قد مس ابانا الضرا والسرا فأخذناهم بغته وهم لا يشعرون"
    },
    {
      "surah_number": 7,
      "verse_number": 96,
      "content": "ولو أن أهل القرىا امنوا واتقوا لفتحنا عليهم بركات من السما والأرض ولاكن كذبوا فأخذناهم بما كانوا يكسبون"
    },
    {
      "surah_number": 7,
      "verse_number": 97,
      "content": "أفأمن أهل القرىا أن يأتيهم بأسنا بياتا وهم نائمون"
    },
    {
      "surah_number": 7,
      "verse_number": 98,
      "content": "أوأمن أهل القرىا أن يأتيهم بأسنا ضحى وهم يلعبون"
    },
    {
      "surah_number": 7,
      "verse_number": 99,
      "content": "أفأمنوا مكر الله فلا يأمن مكر الله الا القوم الخاسرون"
    },
    {
      "surah_number": 7,
      "verse_number": 100,
      "content": "أولم يهد للذين يرثون الأرض من بعد أهلها أن لو نشا أصبناهم بذنوبهم ونطبع علىا قلوبهم فهم لا يسمعون"
    },
    {
      "surah_number": 7,
      "verse_number": 101,
      "content": "تلك القرىا نقص عليك من أنبائها ولقد جاتهم رسلهم بالبينات فما كانوا ليؤمنوا بما كذبوا من قبل كذالك يطبع الله علىا قلوب الكافرين"
    },
    {
      "surah_number": 7,
      "verse_number": 102,
      "content": "وما وجدنا لأكثرهم من عهد وان وجدنا أكثرهم لفاسقين"
    },
    {
      "surah_number": 7,
      "verse_number": 103,
      "content": "ثم بعثنا من بعدهم موسىا بٔاياتنا الىا فرعون وملايه فظلموا بها فانظر كيف كان عاقبه المفسدين"
    },
    {
      "surah_number": 7,
      "verse_number": 104,
      "content": "وقال موسىا يافرعون اني رسول من رب العالمين"
    },
    {
      "surah_number": 7,
      "verse_number": 105,
      "content": "حقيق علىا أن لا أقول على الله الا الحق قد جئتكم ببينه من ربكم فأرسل معي بني اسرايل"
    },
    {
      "surah_number": 7,
      "verse_number": 106,
      "content": "قال ان كنت جئت بٔايه فأت بها ان كنت من الصادقين"
    },
    {
      "surah_number": 7,
      "verse_number": 107,
      "content": "فألقىا عصاه فاذا هي ثعبان مبين"
    },
    {
      "surah_number": 7,
      "verse_number": 108,
      "content": "ونزع يده فاذا هي بيضا للناظرين"
    },
    {
      "surah_number": 7,
      "verse_number": 109,
      "content": "قال الملأ من قوم فرعون ان هاذا لساحر عليم"
    },
    {
      "surah_number": 7,
      "verse_number": 110,
      "content": "يريد أن يخرجكم من أرضكم فماذا تأمرون"
    },
    {
      "surah_number": 7,
      "verse_number": 111,
      "content": "قالوا أرجه وأخاه وأرسل في المدائن حاشرين"
    },
    {
      "surah_number": 7,
      "verse_number": 112,
      "content": "يأتوك بكل ساحر عليم"
    },
    {
      "surah_number": 7,
      "verse_number": 113,
      "content": "وجا السحره فرعون قالوا ان لنا لأجرا ان كنا نحن الغالبين"
    },
    {
      "surah_number": 7,
      "verse_number": 114,
      "content": "قال نعم وانكم لمن المقربين"
    },
    {
      "surah_number": 7,
      "verse_number": 115,
      "content": "قالوا ياموسىا اما أن تلقي واما أن نكون نحن الملقين"
    },
    {
      "surah_number": 7,
      "verse_number": 116,
      "content": "قال ألقوا فلما ألقوا سحروا أعين الناس واسترهبوهم وجاو بسحر عظيم"
    },
    {
      "surah_number": 7,
      "verse_number": 117,
      "content": "وأوحينا الىا موسىا أن ألق عصاك فاذا هي تلقف ما يأفكون"
    },
    {
      "surah_number": 7,
      "verse_number": 118,
      "content": "فوقع الحق وبطل ما كانوا يعملون"
    },
    {
      "surah_number": 7,
      "verse_number": 119,
      "content": "فغلبوا هنالك وانقلبوا صاغرين"
    },
    {
      "surah_number": 7,
      "verse_number": 120,
      "content": "وألقي السحره ساجدين"
    },
    {
      "surah_number": 7,
      "verse_number": 121,
      "content": "قالوا امنا برب العالمين"
    },
    {
      "surah_number": 7,
      "verse_number": 122,
      "content": "رب موسىا وهارون"
    },
    {
      "surah_number": 7,
      "verse_number": 123,
      "content": "قال فرعون امنتم به قبل أن اذن لكم ان هاذا لمكر مكرتموه في المدينه لتخرجوا منها أهلها فسوف تعلمون"
    },
    {
      "surah_number": 7,
      "verse_number": 124,
      "content": "لأقطعن أيديكم وأرجلكم من خلاف ثم لأصلبنكم أجمعين"
    },
    {
      "surah_number": 7,
      "verse_number": 125,
      "content": "قالوا انا الىا ربنا منقلبون"
    },
    {
      "surah_number": 7,
      "verse_number": 126,
      "content": "وما تنقم منا الا أن امنا بٔايات ربنا لما جاتنا ربنا أفرغ علينا صبرا وتوفنا مسلمين"
    },
    {
      "surah_number": 7,
      "verse_number": 127,
      "content": "وقال الملأ من قوم فرعون أتذر موسىا وقومه ليفسدوا في الأرض ويذرك والهتك قال سنقتل أبناهم ونستحي نساهم وانا فوقهم قاهرون"
    },
    {
      "surah_number": 7,
      "verse_number": 128,
      "content": "قال موسىا لقومه استعينوا بالله واصبروا ان الأرض لله يورثها من يشا من عباده والعاقبه للمتقين"
    },
    {
      "surah_number": 7,
      "verse_number": 129,
      "content": "قالوا أوذينا من قبل أن تأتينا ومن بعد ما جئتنا قال عسىا ربكم أن يهلك عدوكم ويستخلفكم في الأرض فينظر كيف تعملون"
    },
    {
      "surah_number": 7,
      "verse_number": 130,
      "content": "ولقد أخذنا ال فرعون بالسنين ونقص من الثمرات لعلهم يذكرون"
    },
    {
      "surah_number": 7,
      "verse_number": 131,
      "content": "فاذا جاتهم الحسنه قالوا لنا هاذه وان تصبهم سيئه يطيروا بموسىا ومن معه ألا انما طائرهم عند الله ولاكن أكثرهم لا يعلمون"
    },
    {
      "surah_number": 7,
      "verse_number": 132,
      "content": "وقالوا مهما تأتنا به من ايه لتسحرنا بها فما نحن لك بمؤمنين"
    },
    {
      "surah_number": 7,
      "verse_number": 133,
      "content": "فأرسلنا عليهم الطوفان والجراد والقمل والضفادع والدم ايات مفصلات فاستكبروا وكانوا قوما مجرمين"
    },
    {
      "surah_number": 7,
      "verse_number": 134,
      "content": "ولما وقع عليهم الرجز قالوا ياموسى ادع لنا ربك بما عهد عندك لئن كشفت عنا الرجز لنؤمنن لك ولنرسلن معك بني اسرايل"
    },
    {
      "surah_number": 7,
      "verse_number": 135,
      "content": "فلما كشفنا عنهم الرجز الىا أجل هم بالغوه اذا هم ينكثون"
    },
    {
      "surah_number": 7,
      "verse_number": 136,
      "content": "فانتقمنا منهم فأغرقناهم في اليم بأنهم كذبوا بٔاياتنا وكانوا عنها غافلين"
    },
    {
      "surah_number": 7,
      "verse_number": 137,
      "content": "وأورثنا القوم الذين كانوا يستضعفون مشارق الأرض ومغاربها التي باركنا فيها وتمت كلمت ربك الحسنىا علىا بني اسرايل بما صبروا ودمرنا ما كان يصنع فرعون وقومه وما كانوا يعرشون"
    },
    {
      "surah_number": 7,
      "verse_number": 138,
      "content": "وجاوزنا ببني اسرايل البحر فأتوا علىا قوم يعكفون علىا أصنام لهم قالوا ياموسى اجعل لنا الاها كما لهم الهه قال انكم قوم تجهلون"
    },
    {
      "surah_number": 7,
      "verse_number": 139,
      "content": "ان هاؤلا متبر ما هم فيه وباطل ما كانوا يعملون"
    },
    {
      "surah_number": 7,
      "verse_number": 140,
      "content": "قال أغير الله أبغيكم الاها وهو فضلكم على العالمين"
    },
    {
      "surah_number": 7,
      "verse_number": 141,
      "content": "واذ أنجيناكم من ال فرعون يسومونكم سو العذاب يقتلون أبناكم ويستحيون نساكم وفي ذالكم بلا من ربكم عظيم"
    },
    {
      "surah_number": 7,
      "verse_number": 142,
      "content": "وواعدنا موسىا ثلاثين ليله وأتممناها بعشر فتم ميقات ربه أربعين ليله وقال موسىا لأخيه هارون اخلفني في قومي وأصلح ولا تتبع سبيل المفسدين"
    },
    {
      "surah_number": 7,
      "verse_number": 143,
      "content": "ولما جا موسىا لميقاتنا وكلمه ربه قال رب أرني أنظر اليك قال لن ترىاني ولاكن انظر الى الجبل فان استقر مكانه فسوف ترىاني فلما تجلىا ربه للجبل جعله دكا وخر موسىا صعقا فلما أفاق قال سبحانك تبت اليك وأنا أول المؤمنين"
    },
    {
      "surah_number": 7,
      "verse_number": 144,
      "content": "قال ياموسىا اني اصطفيتك على الناس برسالاتي وبكلامي فخذ ما اتيتك وكن من الشاكرين"
    },
    {
      "surah_number": 7,
      "verse_number": 145,
      "content": "وكتبنا له في الألواح من كل شي موعظه وتفصيلا لكل شي فخذها بقوه وأمر قومك يأخذوا بأحسنها سأوريكم دار الفاسقين"
    },
    {
      "surah_number": 7,
      "verse_number": 146,
      "content": "سأصرف عن اياتي الذين يتكبرون في الأرض بغير الحق وان يروا كل ايه لا يؤمنوا بها وان يروا سبيل الرشد لا يتخذوه سبيلا وان يروا سبيل الغي يتخذوه سبيلا ذالك بأنهم كذبوا بٔاياتنا وكانوا عنها غافلين"
    },
    {
      "surah_number": 7,
      "verse_number": 147,
      "content": "والذين كذبوا بٔاياتنا ولقا الأخره حبطت أعمالهم هل يجزون الا ما كانوا يعملون"
    },
    {
      "surah_number": 7,
      "verse_number": 148,
      "content": "واتخذ قوم موسىا من بعده من حليهم عجلا جسدا له خوار ألم يروا أنه لا يكلمهم ولا يهديهم سبيلا اتخذوه وكانوا ظالمين"
    },
    {
      "surah_number": 7,
      "verse_number": 149,
      "content": "ولما سقط في أيديهم ورأوا أنهم قد ضلوا قالوا لئن لم يرحمنا ربنا ويغفر لنا لنكونن من الخاسرين"
    },
    {
      "surah_number": 7,
      "verse_number": 150,
      "content": "ولما رجع موسىا الىا قومه غضبان أسفا قال بئسما خلفتموني من بعدي أعجلتم أمر ربكم وألقى الألواح وأخذ برأس أخيه يجره اليه قال ابن أم ان القوم استضعفوني وكادوا يقتلونني فلا تشمت بي الأعدا ولا تجعلني مع القوم الظالمين"
    },
    {
      "surah_number": 7,
      "verse_number": 151,
      "content": "قال رب اغفر لي ولأخي وأدخلنا في رحمتك وأنت أرحم الراحمين"
    },
    {
      "surah_number": 7,
      "verse_number": 152,
      "content": "ان الذين اتخذوا العجل سينالهم غضب من ربهم وذله في الحيواه الدنيا وكذالك نجزي المفترين"
    },
    {
      "surah_number": 7,
      "verse_number": 153,
      "content": "والذين عملوا السئات ثم تابوا من بعدها وامنوا ان ربك من بعدها لغفور رحيم"
    },
    {
      "surah_number": 7,
      "verse_number": 154,
      "content": "ولما سكت عن موسى الغضب أخذ الألواح وفي نسختها هدى ورحمه للذين هم لربهم يرهبون"
    },
    {
      "surah_number": 7,
      "verse_number": 155,
      "content": "واختار موسىا قومه سبعين رجلا لميقاتنا فلما أخذتهم الرجفه قال رب لو شئت أهلكتهم من قبل واياي أتهلكنا بما فعل السفها منا ان هي الا فتنتك تضل بها من تشا وتهدي من تشا أنت ولينا فاغفر لنا وارحمنا وأنت خير الغافرين"
    },
    {
      "surah_number": 7,
      "verse_number": 156,
      "content": "واكتب لنا في هاذه الدنيا حسنه وفي الأخره انا هدنا اليك قال عذابي أصيب به من أشا ورحمتي وسعت كل شي فسأكتبها للذين يتقون ويؤتون الزكواه والذين هم بٔاياتنا يؤمنون"
    },
    {
      "surah_number": 7,
      "verse_number": 157,
      "content": "الذين يتبعون الرسول النبي الأمي الذي يجدونه مكتوبا عندهم في التورىاه والانجيل يأمرهم بالمعروف وينهىاهم عن المنكر ويحل لهم الطيبات ويحرم عليهم الخبائث ويضع عنهم اصرهم والأغلال التي كانت عليهم فالذين امنوا به وعزروه ونصروه واتبعوا النور الذي أنزل معه أولائك هم المفلحون"
    },
    {
      "surah_number": 7,
      "verse_number": 158,
      "content": "قل ياأيها الناس اني رسول الله اليكم جميعا الذي له ملك السماوات والأرض لا الاه الا هو يحي ويميت فٔامنوا بالله ورسوله النبي الأمي الذي يؤمن بالله وكلماته واتبعوه لعلكم تهتدون"
    },
    {
      "surah_number": 7,
      "verse_number": 159,
      "content": "ومن قوم موسىا أمه يهدون بالحق وبه يعدلون"
    },
    {
      "surah_number": 7,
      "verse_number": 160,
      "content": "وقطعناهم اثنتي عشره أسباطا أمما وأوحينا الىا موسىا اذ استسقىاه قومه أن اضرب بعصاك الحجر فانبجست منه اثنتا عشره عينا قد علم كل أناس مشربهم وظللنا عليهم الغمام وأنزلنا عليهم المن والسلوىا كلوا من طيبات ما رزقناكم وما ظلمونا ولاكن كانوا أنفسهم يظلمون"
    },
    {
      "surah_number": 7,
      "verse_number": 161,
      "content": "واذ قيل لهم اسكنوا هاذه القريه وكلوا منها حيث شئتم وقولوا حطه وادخلوا الباب سجدا نغفر لكم خطئاتكم سنزيد المحسنين"
    },
    {
      "surah_number": 7,
      "verse_number": 162,
      "content": "فبدل الذين ظلموا منهم قولا غير الذي قيل لهم فأرسلنا عليهم رجزا من السما بما كانوا يظلمون"
    },
    {
      "surah_number": 7,
      "verse_number": 163,
      "content": "وسٔلهم عن القريه التي كانت حاضره البحر اذ يعدون في السبت اذ تأتيهم حيتانهم يوم سبتهم شرعا ويوم لا يسبتون لا تأتيهم كذالك نبلوهم بما كانوا يفسقون"
    },
    {
      "surah_number": 7,
      "verse_number": 164,
      "content": "واذ قالت أمه منهم لم تعظون قوما الله مهلكهم أو معذبهم عذابا شديدا قالوا معذره الىا ربكم ولعلهم يتقون"
    },
    {
      "surah_number": 7,
      "verse_number": 165,
      "content": "فلما نسوا ما ذكروا به أنجينا الذين ينهون عن السو وأخذنا الذين ظلموا بعذاب بٔيس بما كانوا يفسقون"
    },
    {
      "surah_number": 7,
      "verse_number": 166,
      "content": "فلما عتوا عن ما نهوا عنه قلنا لهم كونوا قرده خاسٔين"
    },
    {
      "surah_number": 7,
      "verse_number": 167,
      "content": "واذ تأذن ربك ليبعثن عليهم الىا يوم القيامه من يسومهم سو العذاب ان ربك لسريع العقاب وانه لغفور رحيم"
    },
    {
      "surah_number": 7,
      "verse_number": 168,
      "content": "وقطعناهم في الأرض أمما منهم الصالحون ومنهم دون ذالك وبلوناهم بالحسنات والسئات لعلهم يرجعون"
    },
    {
      "surah_number": 7,
      "verse_number": 169,
      "content": "فخلف من بعدهم خلف ورثوا الكتاب يأخذون عرض هاذا الأدنىا ويقولون سيغفر لنا وان يأتهم عرض مثله يأخذوه ألم يؤخذ عليهم ميثاق الكتاب أن لا يقولوا على الله الا الحق ودرسوا ما فيه والدار الأخره خير للذين يتقون أفلا تعقلون"
    },
    {
      "surah_number": 7,
      "verse_number": 170,
      "content": "والذين يمسكون بالكتاب وأقاموا الصلواه انا لا نضيع أجر المصلحين"
    },
    {
      "surah_number": 7,
      "verse_number": 171,
      "content": "واذ نتقنا الجبل فوقهم كأنه ظله وظنوا أنه واقع بهم خذوا ما اتيناكم بقوه واذكروا ما فيه لعلكم تتقون"
    },
    {
      "surah_number": 7,
      "verse_number": 172,
      "content": "واذ أخذ ربك من بني ادم من ظهورهم ذريتهم وأشهدهم علىا أنفسهم ألست بربكم قالوا بلىا شهدنا أن تقولوا يوم القيامه انا كنا عن هاذا غافلين"
    },
    {
      "surah_number": 7,
      "verse_number": 173,
      "content": "أو تقولوا انما أشرك اباؤنا من قبل وكنا ذريه من بعدهم أفتهلكنا بما فعل المبطلون"
    },
    {
      "surah_number": 7,
      "verse_number": 174,
      "content": "وكذالك نفصل الأيات ولعلهم يرجعون"
    },
    {
      "surah_number": 7,
      "verse_number": 175,
      "content": "واتل عليهم نبأ الذي اتيناه اياتنا فانسلخ منها فأتبعه الشيطان فكان من الغاوين"
    },
    {
      "surah_number": 7,
      "verse_number": 176,
      "content": "ولو شئنا لرفعناه بها ولاكنه أخلد الى الأرض واتبع هوىاه فمثله كمثل الكلب ان تحمل عليه يلهث أو تتركه يلهث ذالك مثل القوم الذين كذبوا بٔاياتنا فاقصص القصص لعلهم يتفكرون"
    },
    {
      "surah_number": 7,
      "verse_number": 177,
      "content": "سا مثلا القوم الذين كذبوا بٔاياتنا وأنفسهم كانوا يظلمون"
    },
    {
      "surah_number": 7,
      "verse_number": 178,
      "content": "من يهد الله فهو المهتدي ومن يضلل فأولائك هم الخاسرون"
    },
    {
      "surah_number": 7,
      "verse_number": 179,
      "content": "ولقد ذرأنا لجهنم كثيرا من الجن والانس لهم قلوب لا يفقهون بها ولهم أعين لا يبصرون بها ولهم اذان لا يسمعون بها أولائك كالأنعام بل هم أضل أولائك هم الغافلون"
    },
    {
      "surah_number": 7,
      "verse_number": 180,
      "content": "ولله الأسما الحسنىا فادعوه بها وذروا الذين يلحدون في أسمائه سيجزون ما كانوا يعملون"
    },
    {
      "surah_number": 7,
      "verse_number": 181,
      "content": "وممن خلقنا أمه يهدون بالحق وبه يعدلون"
    },
    {
      "surah_number": 7,
      "verse_number": 182,
      "content": "والذين كذبوا بٔاياتنا سنستدرجهم من حيث لا يعلمون"
    },
    {
      "surah_number": 7,
      "verse_number": 183,
      "content": "وأملي لهم ان كيدي متين"
    },
    {
      "surah_number": 7,
      "verse_number": 184,
      "content": "أولم يتفكروا ما بصاحبهم من جنه ان هو الا نذير مبين"
    },
    {
      "surah_number": 7,
      "verse_number": 185,
      "content": "أولم ينظروا في ملكوت السماوات والأرض وما خلق الله من شي وأن عسىا أن يكون قد اقترب أجلهم فبأي حديث بعده يؤمنون"
    },
    {
      "surah_number": 7,
      "verse_number": 186,
      "content": "من يضلل الله فلا هادي له ويذرهم في طغيانهم يعمهون"
    },
    {
      "surah_number": 7,
      "verse_number": 187,
      "content": "يسٔلونك عن الساعه أيان مرسىاها قل انما علمها عند ربي لا يجليها لوقتها الا هو ثقلت في السماوات والأرض لا تأتيكم الا بغته يسٔلونك كأنك حفي عنها قل انما علمها عند الله ولاكن أكثر الناس لا يعلمون"
    },
    {
      "surah_number": 7,
      "verse_number": 188,
      "content": "قل لا أملك لنفسي نفعا ولا ضرا الا ما شا الله ولو كنت أعلم الغيب لاستكثرت من الخير وما مسني السو ان أنا الا نذير وبشير لقوم يؤمنون"
    },
    {
      "surah_number": 7,
      "verse_number": 189,
      "content": "هو الذي خلقكم من نفس واحده وجعل منها زوجها ليسكن اليها فلما تغشىاها حملت حملا خفيفا فمرت به فلما أثقلت دعوا الله ربهما لئن اتيتنا صالحا لنكونن من الشاكرين"
    },
    {
      "surah_number": 7,
      "verse_number": 190,
      "content": "فلما اتىاهما صالحا جعلا له شركا فيما اتىاهما فتعالى الله عما يشركون"
    },
    {
      "surah_number": 7,
      "verse_number": 191,
      "content": "أيشركون ما لا يخلق شئا وهم يخلقون"
    },
    {
      "surah_number": 7,
      "verse_number": 192,
      "content": "ولا يستطيعون لهم نصرا ولا أنفسهم ينصرون"
    },
    {
      "surah_number": 7,
      "verse_number": 193,
      "content": "وان تدعوهم الى الهدىا لا يتبعوكم سوا عليكم أدعوتموهم أم أنتم صامتون"
    },
    {
      "surah_number": 7,
      "verse_number": 194,
      "content": "ان الذين تدعون من دون الله عباد أمثالكم فادعوهم فليستجيبوا لكم ان كنتم صادقين"
    },
    {
      "surah_number": 7,
      "verse_number": 195,
      "content": "ألهم أرجل يمشون بها أم لهم أيد يبطشون بها أم لهم أعين يبصرون بها أم لهم اذان يسمعون بها قل ادعوا شركاكم ثم كيدون فلا تنظرون"
    },
    {
      "surah_number": 7,
      "verse_number": 196,
      "content": "ان ولي الله الذي نزل الكتاب وهو يتولى الصالحين"
    },
    {
      "surah_number": 7,
      "verse_number": 197,
      "content": "والذين تدعون من دونه لا يستطيعون نصركم ولا أنفسهم ينصرون"
    },
    {
      "surah_number": 7,
      "verse_number": 198,
      "content": "وان تدعوهم الى الهدىا لا يسمعوا وترىاهم ينظرون اليك وهم لا يبصرون"
    },
    {
      "surah_number": 7,
      "verse_number": 199,
      "content": "خذ العفو وأمر بالعرف وأعرض عن الجاهلين"
    },
    {
      "surah_number": 7,
      "verse_number": 200,
      "content": "واما ينزغنك من الشيطان نزغ فاستعذ بالله انه سميع عليم"
    },
    {
      "surah_number": 7,
      "verse_number": 201,
      "content": "ان الذين اتقوا اذا مسهم طائف من الشيطان تذكروا فاذا هم مبصرون"
    },
    {
      "surah_number": 7,
      "verse_number": 202,
      "content": "واخوانهم يمدونهم في الغي ثم لا يقصرون"
    },
    {
      "surah_number": 7,
      "verse_number": 203,
      "content": "واذا لم تأتهم بٔايه قالوا لولا اجتبيتها قل انما أتبع ما يوحىا الي من ربي هاذا بصائر من ربكم وهدى ورحمه لقوم يؤمنون"
    },
    {
      "surah_number": 7,
      "verse_number": 204,
      "content": "واذا قرئ القران فاستمعوا له وأنصتوا لعلكم ترحمون"
    },
    {
      "surah_number": 7,
      "verse_number": 205,
      "content": "واذكر ربك في نفسك تضرعا وخيفه ودون الجهر من القول بالغدو والأصال ولا تكن من الغافلين"
    },
    {
      "surah_number": 7,
      "verse_number": 206,
      "content": "ان الذين عند ربك لا يستكبرون عن عبادته ويسبحونه وله يسجدون"
    },
    {
      "surah_number": 8,
      "verse_number": 1,
      "content": "يسٔلونك عن الأنفال قل الأنفال لله والرسول فاتقوا الله وأصلحوا ذات بينكم وأطيعوا الله ورسوله ان كنتم مؤمنين"
    },
    {
      "surah_number": 8,
      "verse_number": 2,
      "content": "انما المؤمنون الذين اذا ذكر الله وجلت قلوبهم واذا تليت عليهم اياته زادتهم ايمانا وعلىا ربهم يتوكلون"
    },
    {
      "surah_number": 8,
      "verse_number": 3,
      "content": "الذين يقيمون الصلواه ومما رزقناهم ينفقون"
    },
    {
      "surah_number": 8,
      "verse_number": 4,
      "content": "أولائك هم المؤمنون حقا لهم درجات عند ربهم ومغفره ورزق كريم"
    },
    {
      "surah_number": 8,
      "verse_number": 5,
      "content": "كما أخرجك ربك من بيتك بالحق وان فريقا من المؤمنين لكارهون"
    },
    {
      "surah_number": 8,
      "verse_number": 6,
      "content": "يجادلونك في الحق بعد ما تبين كأنما يساقون الى الموت وهم ينظرون"
    },
    {
      "surah_number": 8,
      "verse_number": 7,
      "content": "واذ يعدكم الله احدى الطائفتين أنها لكم وتودون أن غير ذات الشوكه تكون لكم ويريد الله أن يحق الحق بكلماته ويقطع دابر الكافرين"
    },
    {
      "surah_number": 8,
      "verse_number": 8,
      "content": "ليحق الحق ويبطل الباطل ولو كره المجرمون"
    },
    {
      "surah_number": 8,
      "verse_number": 9,
      "content": "اذ تستغيثون ربكم فاستجاب لكم أني ممدكم بألف من الملائكه مردفين"
    },
    {
      "surah_number": 8,
      "verse_number": 10,
      "content": "وما جعله الله الا بشرىا ولتطمئن به قلوبكم وما النصر الا من عند الله ان الله عزيز حكيم"
    },
    {
      "surah_number": 8,
      "verse_number": 11,
      "content": "اذ يغشيكم النعاس أمنه منه وينزل عليكم من السما ما ليطهركم به ويذهب عنكم رجز الشيطان وليربط علىا قلوبكم ويثبت به الأقدام"
    },
    {
      "surah_number": 8,
      "verse_number": 12,
      "content": "اذ يوحي ربك الى الملائكه أني معكم فثبتوا الذين امنوا سألقي في قلوب الذين كفروا الرعب فاضربوا فوق الأعناق واضربوا منهم كل بنان"
    },
    {
      "surah_number": 8,
      "verse_number": 13,
      "content": "ذالك بأنهم شاقوا الله ورسوله ومن يشاقق الله ورسوله فان الله شديد العقاب"
    },
    {
      "surah_number": 8,
      "verse_number": 14,
      "content": "ذالكم فذوقوه وأن للكافرين عذاب النار"
    },
    {
      "surah_number": 8,
      "verse_number": 15,
      "content": "ياأيها الذين امنوا اذا لقيتم الذين كفروا زحفا فلا تولوهم الأدبار"
    },
    {
      "surah_number": 8,
      "verse_number": 16,
      "content": "ومن يولهم يومئذ دبره الا متحرفا لقتال أو متحيزا الىا فئه فقد با بغضب من الله ومأوىاه جهنم وبئس المصير"
    },
    {
      "surah_number": 8,
      "verse_number": 17,
      "content": "فلم تقتلوهم ولاكن الله قتلهم وما رميت اذ رميت ولاكن الله رمىا وليبلي المؤمنين منه بلا حسنا ان الله سميع عليم"
    },
    {
      "surah_number": 8,
      "verse_number": 18,
      "content": "ذالكم وأن الله موهن كيد الكافرين"
    },
    {
      "surah_number": 8,
      "verse_number": 19,
      "content": "ان تستفتحوا فقد جاكم الفتح وان تنتهوا فهو خير لكم وان تعودوا نعد ولن تغني عنكم فئتكم شئا ولو كثرت وأن الله مع المؤمنين"
    },
    {
      "surah_number": 8,
      "verse_number": 20,
      "content": "ياأيها الذين امنوا أطيعوا الله ورسوله ولا تولوا عنه وأنتم تسمعون"
    },
    {
      "surah_number": 8,
      "verse_number": 21,
      "content": "ولا تكونوا كالذين قالوا سمعنا وهم لا يسمعون"
    },
    {
      "surah_number": 8,
      "verse_number": 22,
      "content": "ان شر الدواب عند الله الصم البكم الذين لا يعقلون"
    },
    {
      "surah_number": 8,
      "verse_number": 23,
      "content": "ولو علم الله فيهم خيرا لأسمعهم ولو أسمعهم لتولوا وهم معرضون"
    },
    {
      "surah_number": 8,
      "verse_number": 24,
      "content": "ياأيها الذين امنوا استجيبوا لله وللرسول اذا دعاكم لما يحييكم واعلموا أن الله يحول بين المر وقلبه وأنه اليه تحشرون"
    },
    {
      "surah_number": 8,
      "verse_number": 25,
      "content": "واتقوا فتنه لا تصيبن الذين ظلموا منكم خاصه واعلموا أن الله شديد العقاب"
    },
    {
      "surah_number": 8,
      "verse_number": 26,
      "content": "واذكروا اذ أنتم قليل مستضعفون في الأرض تخافون أن يتخطفكم الناس فٔاوىاكم وأيدكم بنصره ورزقكم من الطيبات لعلكم تشكرون"
    },
    {
      "surah_number": 8,
      "verse_number": 27,
      "content": "ياأيها الذين امنوا لا تخونوا الله والرسول وتخونوا أماناتكم وأنتم تعلمون"
    },
    {
      "surah_number": 8,
      "verse_number": 28,
      "content": "واعلموا أنما أموالكم وأولادكم فتنه وأن الله عنده أجر عظيم"
    },
    {
      "surah_number": 8,
      "verse_number": 29,
      "content": "ياأيها الذين امنوا ان تتقوا الله يجعل لكم فرقانا ويكفر عنكم سئاتكم ويغفر لكم والله ذو الفضل العظيم"
    },
    {
      "surah_number": 8,
      "verse_number": 30,
      "content": "واذ يمكر بك الذين كفروا ليثبتوك أو يقتلوك أو يخرجوك ويمكرون ويمكر الله والله خير الماكرين"
    },
    {
      "surah_number": 8,
      "verse_number": 31,
      "content": "واذا تتلىا عليهم اياتنا قالوا قد سمعنا لو نشا لقلنا مثل هاذا ان هاذا الا أساطير الأولين"
    },
    {
      "surah_number": 8,
      "verse_number": 32,
      "content": "واذ قالوا اللهم ان كان هاذا هو الحق من عندك فأمطر علينا حجاره من السما أو ائتنا بعذاب أليم"
    },
    {
      "surah_number": 8,
      "verse_number": 33,
      "content": "وما كان الله ليعذبهم وأنت فيهم وما كان الله معذبهم وهم يستغفرون"
    },
    {
      "surah_number": 8,
      "verse_number": 34,
      "content": "وما لهم ألا يعذبهم الله وهم يصدون عن المسجد الحرام وما كانوا أولياه ان أولياؤه الا المتقون ولاكن أكثرهم لا يعلمون"
    },
    {
      "surah_number": 8,
      "verse_number": 35,
      "content": "وما كان صلاتهم عند البيت الا مكا وتصديه فذوقوا العذاب بما كنتم تكفرون"
    },
    {
      "surah_number": 8,
      "verse_number": 36,
      "content": "ان الذين كفروا ينفقون أموالهم ليصدوا عن سبيل الله فسينفقونها ثم تكون عليهم حسره ثم يغلبون والذين كفروا الىا جهنم يحشرون"
    },
    {
      "surah_number": 8,
      "verse_number": 37,
      "content": "ليميز الله الخبيث من الطيب ويجعل الخبيث بعضه علىا بعض فيركمه جميعا فيجعله في جهنم أولائك هم الخاسرون"
    },
    {
      "surah_number": 8,
      "verse_number": 38,
      "content": "قل للذين كفروا ان ينتهوا يغفر لهم ما قد سلف وان يعودوا فقد مضت سنت الأولين"
    },
    {
      "surah_number": 8,
      "verse_number": 39,
      "content": "وقاتلوهم حتىا لا تكون فتنه ويكون الدين كله لله فان انتهوا فان الله بما يعملون بصير"
    },
    {
      "surah_number": 8,
      "verse_number": 40,
      "content": "وان تولوا فاعلموا أن الله مولىاكم نعم المولىا ونعم النصير"
    },
    {
      "surah_number": 8,
      "verse_number": 41,
      "content": "واعلموا أنما غنمتم من شي فأن لله خمسه وللرسول ولذي القربىا واليتامىا والمساكين وابن السبيل ان كنتم امنتم بالله وما أنزلنا علىا عبدنا يوم الفرقان يوم التقى الجمعان والله علىا كل شي قدير"
    },
    {
      "surah_number": 8,
      "verse_number": 42,
      "content": "اذ أنتم بالعدوه الدنيا وهم بالعدوه القصوىا والركب أسفل منكم ولو تواعدتم لاختلفتم في الميعاد ولاكن ليقضي الله أمرا كان مفعولا ليهلك من هلك عن بينه ويحيىا من حي عن بينه وان الله لسميع عليم"
    },
    {
      "surah_number": 8,
      "verse_number": 43,
      "content": "اذ يريكهم الله في منامك قليلا ولو أرىاكهم كثيرا لفشلتم ولتنازعتم في الأمر ولاكن الله سلم انه عليم بذات الصدور"
    },
    {
      "surah_number": 8,
      "verse_number": 44,
      "content": "واذ يريكموهم اذ التقيتم في أعينكم قليلا ويقللكم في أعينهم ليقضي الله أمرا كان مفعولا والى الله ترجع الأمور"
    },
    {
      "surah_number": 8,
      "verse_number": 45,
      "content": "ياأيها الذين امنوا اذا لقيتم فئه فاثبتوا واذكروا الله كثيرا لعلكم تفلحون"
    },
    {
      "surah_number": 8,
      "verse_number": 46,
      "content": "وأطيعوا الله ورسوله ولا تنازعوا فتفشلوا وتذهب ريحكم واصبروا ان الله مع الصابرين"
    },
    {
      "surah_number": 8,
      "verse_number": 47,
      "content": "ولا تكونوا كالذين خرجوا من ديارهم بطرا ورئا الناس ويصدون عن سبيل الله والله بما يعملون محيط"
    },
    {
      "surah_number": 8,
      "verse_number": 48,
      "content": "واذ زين لهم الشيطان أعمالهم وقال لا غالب لكم اليوم من الناس واني جار لكم فلما ترات الفئتان نكص علىا عقبيه وقال اني بري منكم اني أرىا ما لا ترون اني أخاف الله والله شديد العقاب"
    },
    {
      "surah_number": 8,
      "verse_number": 49,
      "content": "اذ يقول المنافقون والذين في قلوبهم مرض غر هاؤلا دينهم ومن يتوكل على الله فان الله عزيز حكيم"
    },
    {
      "surah_number": 8,
      "verse_number": 50,
      "content": "ولو ترىا اذ يتوفى الذين كفروا الملائكه يضربون وجوههم وأدبارهم وذوقوا عذاب الحريق"
    },
    {
      "surah_number": 8,
      "verse_number": 51,
      "content": "ذالك بما قدمت أيديكم وأن الله ليس بظلام للعبيد"
    },
    {
      "surah_number": 8,
      "verse_number": 52,
      "content": "كدأب ال فرعون والذين من قبلهم كفروا بٔايات الله فأخذهم الله بذنوبهم ان الله قوي شديد العقاب"
    },
    {
      "surah_number": 8,
      "verse_number": 53,
      "content": "ذالك بأن الله لم يك مغيرا نعمه أنعمها علىا قوم حتىا يغيروا ما بأنفسهم وأن الله سميع عليم"
    },
    {
      "surah_number": 8,
      "verse_number": 54,
      "content": "كدأب ال فرعون والذين من قبلهم كذبوا بٔايات ربهم فأهلكناهم بذنوبهم وأغرقنا ال فرعون وكل كانوا ظالمين"
    },
    {
      "surah_number": 8,
      "verse_number": 55,
      "content": "ان شر الدواب عند الله الذين كفروا فهم لا يؤمنون"
    },
    {
      "surah_number": 8,
      "verse_number": 56,
      "content": "الذين عاهدت منهم ثم ينقضون عهدهم في كل مره وهم لا يتقون"
    },
    {
      "surah_number": 8,
      "verse_number": 57,
      "content": "فاما تثقفنهم في الحرب فشرد بهم من خلفهم لعلهم يذكرون"
    },
    {
      "surah_number": 8,
      "verse_number": 58,
      "content": "واما تخافن من قوم خيانه فانبذ اليهم علىا سوا ان الله لا يحب الخائنين"
    },
    {
      "surah_number": 8,
      "verse_number": 59,
      "content": "ولا يحسبن الذين كفروا سبقوا انهم لا يعجزون"
    },
    {
      "surah_number": 8,
      "verse_number": 60,
      "content": "وأعدوا لهم ما استطعتم من قوه ومن رباط الخيل ترهبون به عدو الله وعدوكم واخرين من دونهم لا تعلمونهم الله يعلمهم وما تنفقوا من شي في سبيل الله يوف اليكم وأنتم لا تظلمون"
    },
    {
      "surah_number": 8,
      "verse_number": 61,
      "content": "وان جنحوا للسلم فاجنح لها وتوكل على الله انه هو السميع العليم"
    },
    {
      "surah_number": 8,
      "verse_number": 62,
      "content": "وان يريدوا أن يخدعوك فان حسبك الله هو الذي أيدك بنصره وبالمؤمنين"
    },
    {
      "surah_number": 8,
      "verse_number": 63,
      "content": "وألف بين قلوبهم لو أنفقت ما في الأرض جميعا ما ألفت بين قلوبهم ولاكن الله ألف بينهم انه عزيز حكيم"
    },
    {
      "surah_number": 8,
      "verse_number": 64,
      "content": "ياأيها النبي حسبك الله ومن اتبعك من المؤمنين"
    },
    {
      "surah_number": 8,
      "verse_number": 65,
      "content": "ياأيها النبي حرض المؤمنين على القتال ان يكن منكم عشرون صابرون يغلبوا مائتين وان يكن منكم مائه يغلبوا ألفا من الذين كفروا بأنهم قوم لا يفقهون"
    },
    {
      "surah_number": 8,
      "verse_number": 66,
      "content": "الٔان خفف الله عنكم وعلم أن فيكم ضعفا فان يكن منكم مائه صابره يغلبوا مائتين وان يكن منكم ألف يغلبوا ألفين باذن الله والله مع الصابرين"
    },
    {
      "surah_number": 8,
      "verse_number": 67,
      "content": "ما كان لنبي أن يكون له أسرىا حتىا يثخن في الأرض تريدون عرض الدنيا والله يريد الأخره والله عزيز حكيم"
    },
    {
      "surah_number": 8,
      "verse_number": 68,
      "content": "لولا كتاب من الله سبق لمسكم فيما أخذتم عذاب عظيم"
    },
    {
      "surah_number": 8,
      "verse_number": 69,
      "content": "فكلوا مما غنمتم حلالا طيبا واتقوا الله ان الله غفور رحيم"
    },
    {
      "surah_number": 8,
      "verse_number": 70,
      "content": "ياأيها النبي قل لمن في أيديكم من الأسرىا ان يعلم الله في قلوبكم خيرا يؤتكم خيرا مما أخذ منكم ويغفر لكم والله غفور رحيم"
    },
    {
      "surah_number": 8,
      "verse_number": 71,
      "content": "وان يريدوا خيانتك فقد خانوا الله من قبل فأمكن منهم والله عليم حكيم"
    },
    {
      "surah_number": 8,
      "verse_number": 72,
      "content": "ان الذين امنوا وهاجروا وجاهدوا بأموالهم وأنفسهم في سبيل الله والذين اووا ونصروا أولائك بعضهم أوليا بعض والذين امنوا ولم يهاجروا ما لكم من ولايتهم من شي حتىا يهاجروا وان استنصروكم في الدين فعليكم النصر الا علىا قوم بينكم وبينهم ميثاق والله بما تعملون بصير"
    },
    {
      "surah_number": 8,
      "verse_number": 73,
      "content": "والذين كفروا بعضهم أوليا بعض الا تفعلوه تكن فتنه في الأرض وفساد كبير"
    },
    {
      "surah_number": 8,
      "verse_number": 74,
      "content": "والذين امنوا وهاجروا وجاهدوا في سبيل الله والذين اووا ونصروا أولائك هم المؤمنون حقا لهم مغفره ورزق كريم"
    },
    {
      "surah_number": 8,
      "verse_number": 75,
      "content": "والذين امنوا من بعد وهاجروا وجاهدوا معكم فأولائك منكم وأولوا الأرحام بعضهم أولىا ببعض في كتاب الله ان الله بكل شي عليم"
    },
    {
      "surah_number": 9,
      "verse_number": 1,
      "content": "براه من الله ورسوله الى الذين عاهدتم من المشركين"
    },
    {
      "surah_number": 9,
      "verse_number": 2,
      "content": "فسيحوا في الأرض أربعه أشهر واعلموا أنكم غير معجزي الله وأن الله مخزي الكافرين"
    },
    {
      "surah_number": 9,
      "verse_number": 3,
      "content": "وأذان من الله ورسوله الى الناس يوم الحج الأكبر أن الله بري من المشركين ورسوله فان تبتم فهو خير لكم وان توليتم فاعلموا أنكم غير معجزي الله وبشر الذين كفروا بعذاب أليم"
    },
    {
      "surah_number": 9,
      "verse_number": 4,
      "content": "الا الذين عاهدتم من المشركين ثم لم ينقصوكم شئا ولم يظاهروا عليكم أحدا فأتموا اليهم عهدهم الىا مدتهم ان الله يحب المتقين"
    },
    {
      "surah_number": 9,
      "verse_number": 5,
      "content": "فاذا انسلخ الأشهر الحرم فاقتلوا المشركين حيث وجدتموهم وخذوهم واحصروهم واقعدوا لهم كل مرصد فان تابوا وأقاموا الصلواه واتوا الزكواه فخلوا سبيلهم ان الله غفور رحيم"
    },
    {
      "surah_number": 9,
      "verse_number": 6,
      "content": "وان أحد من المشركين استجارك فأجره حتىا يسمع كلام الله ثم أبلغه مأمنه ذالك بأنهم قوم لا يعلمون"
    },
    {
      "surah_number": 9,
      "verse_number": 7,
      "content": "كيف يكون للمشركين عهد عند الله وعند رسوله الا الذين عاهدتم عند المسجد الحرام فما استقاموا لكم فاستقيموا لهم ان الله يحب المتقين"
    },
    {
      "surah_number": 9,
      "verse_number": 8,
      "content": "كيف وان يظهروا عليكم لا يرقبوا فيكم الا ولا ذمه يرضونكم بأفواههم وتأبىا قلوبهم وأكثرهم فاسقون"
    },
    {
      "surah_number": 9,
      "verse_number": 9,
      "content": "اشتروا بٔايات الله ثمنا قليلا فصدوا عن سبيله انهم سا ما كانوا يعملون"
    },
    {
      "surah_number": 9,
      "verse_number": 10,
      "content": "لا يرقبون في مؤمن الا ولا ذمه وأولائك هم المعتدون"
    },
    {
      "surah_number": 9,
      "verse_number": 11,
      "content": "فان تابوا وأقاموا الصلواه واتوا الزكواه فاخوانكم في الدين ونفصل الأيات لقوم يعلمون"
    },
    {
      "surah_number": 9,
      "verse_number": 12,
      "content": "وان نكثوا أيمانهم من بعد عهدهم وطعنوا في دينكم فقاتلوا أئمه الكفر انهم لا أيمان لهم لعلهم ينتهون"
    },
    {
      "surah_number": 9,
      "verse_number": 13,
      "content": "ألا تقاتلون قوما نكثوا أيمانهم وهموا باخراج الرسول وهم بدوكم أول مره أتخشونهم فالله أحق أن تخشوه ان كنتم مؤمنين"
    },
    {
      "surah_number": 9,
      "verse_number": 14,
      "content": "قاتلوهم يعذبهم الله بأيديكم ويخزهم وينصركم عليهم ويشف صدور قوم مؤمنين"
    },
    {
      "surah_number": 9,
      "verse_number": 15,
      "content": "ويذهب غيظ قلوبهم ويتوب الله علىا من يشا والله عليم حكيم"
    },
    {
      "surah_number": 9,
      "verse_number": 16,
      "content": "أم حسبتم أن تتركوا ولما يعلم الله الذين جاهدوا منكم ولم يتخذوا من دون الله ولا رسوله ولا المؤمنين وليجه والله خبير بما تعملون"
    },
    {
      "surah_number": 9,
      "verse_number": 17,
      "content": "ما كان للمشركين أن يعمروا مساجد الله شاهدين علىا أنفسهم بالكفر أولائك حبطت أعمالهم وفي النار هم خالدون"
    },
    {
      "surah_number": 9,
      "verse_number": 18,
      "content": "انما يعمر مساجد الله من امن بالله واليوم الأخر وأقام الصلواه واتى الزكواه ولم يخش الا الله فعسىا أولائك أن يكونوا من المهتدين"
    },
    {
      "surah_number": 9,
      "verse_number": 19,
      "content": "أجعلتم سقايه الحاج وعماره المسجد الحرام كمن امن بالله واليوم الأخر وجاهد في سبيل الله لا يستون عند الله والله لا يهدي القوم الظالمين"
    },
    {
      "surah_number": 9,
      "verse_number": 20,
      "content": "الذين امنوا وهاجروا وجاهدوا في سبيل الله بأموالهم وأنفسهم أعظم درجه عند الله وأولائك هم الفائزون"
    },
    {
      "surah_number": 9,
      "verse_number": 21,
      "content": "يبشرهم ربهم برحمه منه ورضوان وجنات لهم فيها نعيم مقيم"
    },
    {
      "surah_number": 9,
      "verse_number": 22,
      "content": "خالدين فيها أبدا ان الله عنده أجر عظيم"
    },
    {
      "surah_number": 9,
      "verse_number": 23,
      "content": "ياأيها الذين امنوا لا تتخذوا اباكم واخوانكم أوليا ان استحبوا الكفر على الايمان ومن يتولهم منكم فأولائك هم الظالمون"
    },
    {
      "surah_number": 9,
      "verse_number": 24,
      "content": "قل ان كان اباؤكم وأبناؤكم واخوانكم وأزواجكم وعشيرتكم وأموال اقترفتموها وتجاره تخشون كسادها ومساكن ترضونها أحب اليكم من الله ورسوله وجهاد في سبيله فتربصوا حتىا يأتي الله بأمره والله لا يهدي القوم الفاسقين"
    },
    {
      "surah_number": 9,
      "verse_number": 25,
      "content": "لقد نصركم الله في مواطن كثيره ويوم حنين اذ أعجبتكم كثرتكم فلم تغن عنكم شئا وضاقت عليكم الأرض بما رحبت ثم وليتم مدبرين"
    },
    {
      "surah_number": 9,
      "verse_number": 26,
      "content": "ثم أنزل الله سكينته علىا رسوله وعلى المؤمنين وأنزل جنودا لم تروها وعذب الذين كفروا وذالك جزا الكافرين"
    },
    {
      "surah_number": 9,
      "verse_number": 27,
      "content": "ثم يتوب الله من بعد ذالك علىا من يشا والله غفور رحيم"
    },
    {
      "surah_number": 9,
      "verse_number": 28,
      "content": "ياأيها الذين امنوا انما المشركون نجس فلا يقربوا المسجد الحرام بعد عامهم هاذا وان خفتم عيله فسوف يغنيكم الله من فضله ان شا ان الله عليم حكيم"
    },
    {
      "surah_number": 9,
      "verse_number": 29,
      "content": "قاتلوا الذين لا يؤمنون بالله ولا باليوم الأخر ولا يحرمون ما حرم الله ورسوله ولا يدينون دين الحق من الذين أوتوا الكتاب حتىا يعطوا الجزيه عن يد وهم صاغرون"
    },
    {
      "surah_number": 9,
      "verse_number": 30,
      "content": "وقالت اليهود عزير ابن الله وقالت النصارى المسيح ابن الله ذالك قولهم بأفواههم يضاهٔون قول الذين كفروا من قبل قاتلهم الله أنىا يؤفكون"
    },
    {
      "surah_number": 9,
      "verse_number": 31,
      "content": "اتخذوا أحبارهم ورهبانهم أربابا من دون الله والمسيح ابن مريم وما أمروا الا ليعبدوا الاها واحدا لا الاه الا هو سبحانه عما يشركون"
    },
    {
      "surah_number": 9,
      "verse_number": 32,
      "content": "يريدون أن يطفٔوا نور الله بأفواههم ويأبى الله الا أن يتم نوره ولو كره الكافرون"
    },
    {
      "surah_number": 9,
      "verse_number": 33,
      "content": "هو الذي أرسل رسوله بالهدىا ودين الحق ليظهره على الدين كله ولو كره المشركون"
    },
    {
      "surah_number": 9,
      "verse_number": 34,
      "content": "ياأيها الذين امنوا ان كثيرا من الأحبار والرهبان ليأكلون أموال الناس بالباطل ويصدون عن سبيل الله والذين يكنزون الذهب والفضه ولا ينفقونها في سبيل الله فبشرهم بعذاب أليم"
    },
    {
      "surah_number": 9,
      "verse_number": 35,
      "content": "يوم يحمىا عليها في نار جهنم فتكوىا بها جباههم وجنوبهم وظهورهم هاذا ما كنزتم لأنفسكم فذوقوا ما كنتم تكنزون"
    },
    {
      "surah_number": 9,
      "verse_number": 36,
      "content": "ان عده الشهور عند الله اثنا عشر شهرا في كتاب الله يوم خلق السماوات والأرض منها أربعه حرم ذالك الدين القيم فلا تظلموا فيهن أنفسكم وقاتلوا المشركين كافه كما يقاتلونكم كافه واعلموا أن الله مع المتقين"
    },
    {
      "surah_number": 9,
      "verse_number": 37,
      "content": "انما النسي زياده في الكفر يضل به الذين كفروا يحلونه عاما ويحرمونه عاما ليواطٔوا عده ما حرم الله فيحلوا ما حرم الله زين لهم سو أعمالهم والله لا يهدي القوم الكافرين"
    },
    {
      "surah_number": 9,
      "verse_number": 38,
      "content": "ياأيها الذين امنوا ما لكم اذا قيل لكم انفروا في سبيل الله اثاقلتم الى الأرض أرضيتم بالحيواه الدنيا من الأخره فما متاع الحيواه الدنيا في الأخره الا قليل"
    },
    {
      "surah_number": 9,
      "verse_number": 39,
      "content": "الا تنفروا يعذبكم عذابا أليما ويستبدل قوما غيركم ولا تضروه شئا والله علىا كل شي قدير"
    },
    {
      "surah_number": 9,
      "verse_number": 40,
      "content": "الا تنصروه فقد نصره الله اذ أخرجه الذين كفروا ثاني اثنين اذ هما في الغار اذ يقول لصاحبه لا تحزن ان الله معنا فأنزل الله سكينته عليه وأيده بجنود لم تروها وجعل كلمه الذين كفروا السفلىا وكلمه الله هي العليا والله عزيز حكيم"
    },
    {
      "surah_number": 9,
      "verse_number": 41,
      "content": "انفروا خفافا وثقالا وجاهدوا بأموالكم وأنفسكم في سبيل الله ذالكم خير لكم ان كنتم تعلمون"
    },
    {
      "surah_number": 9,
      "verse_number": 42,
      "content": "لو كان عرضا قريبا وسفرا قاصدا لاتبعوك ولاكن بعدت عليهم الشقه وسيحلفون بالله لو استطعنا لخرجنا معكم يهلكون أنفسهم والله يعلم انهم لكاذبون"
    },
    {
      "surah_number": 9,
      "verse_number": 43,
      "content": "عفا الله عنك لم أذنت لهم حتىا يتبين لك الذين صدقوا وتعلم الكاذبين"
    },
    {
      "surah_number": 9,
      "verse_number": 44,
      "content": "لا يستٔذنك الذين يؤمنون بالله واليوم الأخر أن يجاهدوا بأموالهم وأنفسهم والله عليم بالمتقين"
    },
    {
      "surah_number": 9,
      "verse_number": 45,
      "content": "انما يستٔذنك الذين لا يؤمنون بالله واليوم الأخر وارتابت قلوبهم فهم في ريبهم يترددون"
    },
    {
      "surah_number": 9,
      "verse_number": 46,
      "content": "ولو أرادوا الخروج لأعدوا له عده ولاكن كره الله انبعاثهم فثبطهم وقيل اقعدوا مع القاعدين"
    },
    {
      "surah_number": 9,
      "verse_number": 47,
      "content": "لو خرجوا فيكم ما زادوكم الا خبالا ولأوضعوا خلالكم يبغونكم الفتنه وفيكم سماعون لهم والله عليم بالظالمين"
    },
    {
      "surah_number": 9,
      "verse_number": 48,
      "content": "لقد ابتغوا الفتنه من قبل وقلبوا لك الأمور حتىا جا الحق وظهر أمر الله وهم كارهون"
    },
    {
      "surah_number": 9,
      "verse_number": 49,
      "content": "ومنهم من يقول ائذن لي ولا تفتني ألا في الفتنه سقطوا وان جهنم لمحيطه بالكافرين"
    },
    {
      "surah_number": 9,
      "verse_number": 50,
      "content": "ان تصبك حسنه تسؤهم وان تصبك مصيبه يقولوا قد أخذنا أمرنا من قبل ويتولوا وهم فرحون"
    },
    {
      "surah_number": 9,
      "verse_number": 51,
      "content": "قل لن يصيبنا الا ما كتب الله لنا هو مولىانا وعلى الله فليتوكل المؤمنون"
    },
    {
      "surah_number": 9,
      "verse_number": 52,
      "content": "قل هل تربصون بنا الا احدى الحسنيين ونحن نتربص بكم أن يصيبكم الله بعذاب من عنده أو بأيدينا فتربصوا انا معكم متربصون"
    },
    {
      "surah_number": 9,
      "verse_number": 53,
      "content": "قل أنفقوا طوعا أو كرها لن يتقبل منكم انكم كنتم قوما فاسقين"
    },
    {
      "surah_number": 9,
      "verse_number": 54,
      "content": "وما منعهم أن تقبل منهم نفقاتهم الا أنهم كفروا بالله وبرسوله ولا يأتون الصلواه الا وهم كسالىا ولا ينفقون الا وهم كارهون"
    },
    {
      "surah_number": 9,
      "verse_number": 55,
      "content": "فلا تعجبك أموالهم ولا أولادهم انما يريد الله ليعذبهم بها في الحيواه الدنيا وتزهق أنفسهم وهم كافرون"
    },
    {
      "surah_number": 9,
      "verse_number": 56,
      "content": "ويحلفون بالله انهم لمنكم وما هم منكم ولاكنهم قوم يفرقون"
    },
    {
      "surah_number": 9,
      "verse_number": 57,
      "content": "لو يجدون ملجٔا أو مغارات أو مدخلا لولوا اليه وهم يجمحون"
    },
    {
      "surah_number": 9,
      "verse_number": 58,
      "content": "ومنهم من يلمزك في الصدقات فان أعطوا منها رضوا وان لم يعطوا منها اذا هم يسخطون"
    },
    {
      "surah_number": 9,
      "verse_number": 59,
      "content": "ولو أنهم رضوا ما اتىاهم الله ورسوله وقالوا حسبنا الله سيؤتينا الله من فضله ورسوله انا الى الله راغبون"
    },
    {
      "surah_number": 9,
      "verse_number": 60,
      "content": "انما الصدقات للفقرا والمساكين والعاملين عليها والمؤلفه قلوبهم وفي الرقاب والغارمين وفي سبيل الله وابن السبيل فريضه من الله والله عليم حكيم"
    },
    {
      "surah_number": 9,
      "verse_number": 61,
      "content": "ومنهم الذين يؤذون النبي ويقولون هو أذن قل أذن خير لكم يؤمن بالله ويؤمن للمؤمنين ورحمه للذين امنوا منكم والذين يؤذون رسول الله لهم عذاب أليم"
    },
    {
      "surah_number": 9,
      "verse_number": 62,
      "content": "يحلفون بالله لكم ليرضوكم والله ورسوله أحق أن يرضوه ان كانوا مؤمنين"
    },
    {
      "surah_number": 9,
      "verse_number": 63,
      "content": "ألم يعلموا أنه من يحادد الله ورسوله فأن له نار جهنم خالدا فيها ذالك الخزي العظيم"
    },
    {
      "surah_number": 9,
      "verse_number": 64,
      "content": "يحذر المنافقون أن تنزل عليهم سوره تنبئهم بما في قلوبهم قل استهزوا ان الله مخرج ما تحذرون"
    },
    {
      "surah_number": 9,
      "verse_number": 65,
      "content": "ولئن سألتهم ليقولن انما كنا نخوض ونلعب قل أبالله واياته ورسوله كنتم تستهزون"
    },
    {
      "surah_number": 9,
      "verse_number": 66,
      "content": "لا تعتذروا قد كفرتم بعد ايمانكم ان نعف عن طائفه منكم نعذب طائفه بأنهم كانوا مجرمين"
    },
    {
      "surah_number": 9,
      "verse_number": 67,
      "content": "المنافقون والمنافقات بعضهم من بعض يأمرون بالمنكر وينهون عن المعروف ويقبضون أيديهم نسوا الله فنسيهم ان المنافقين هم الفاسقون"
    },
    {
      "surah_number": 9,
      "verse_number": 68,
      "content": "وعد الله المنافقين والمنافقات والكفار نار جهنم خالدين فيها هي حسبهم ولعنهم الله ولهم عذاب مقيم"
    },
    {
      "surah_number": 9,
      "verse_number": 69,
      "content": "كالذين من قبلكم كانوا أشد منكم قوه وأكثر أموالا وأولادا فاستمتعوا بخلاقهم فاستمتعتم بخلاقكم كما استمتع الذين من قبلكم بخلاقهم وخضتم كالذي خاضوا أولائك حبطت أعمالهم في الدنيا والأخره وأولائك هم الخاسرون"
    },
    {
      "surah_number": 9,
      "verse_number": 70,
      "content": "ألم يأتهم نبأ الذين من قبلهم قوم نوح وعاد وثمود وقوم ابراهيم وأصحاب مدين والمؤتفكات أتتهم رسلهم بالبينات فما كان الله ليظلمهم ولاكن كانوا أنفسهم يظلمون"
    },
    {
      "surah_number": 9,
      "verse_number": 71,
      "content": "والمؤمنون والمؤمنات بعضهم أوليا بعض يأمرون بالمعروف وينهون عن المنكر ويقيمون الصلواه ويؤتون الزكواه ويطيعون الله ورسوله أولائك سيرحمهم الله ان الله عزيز حكيم"
    },
    {
      "surah_number": 9,
      "verse_number": 72,
      "content": "وعد الله المؤمنين والمؤمنات جنات تجري من تحتها الأنهار خالدين فيها ومساكن طيبه في جنات عدن ورضوان من الله أكبر ذالك هو الفوز العظيم"
    },
    {
      "surah_number": 9,
      "verse_number": 73,
      "content": "ياأيها النبي جاهد الكفار والمنافقين واغلظ عليهم ومأوىاهم جهنم وبئس المصير"
    },
    {
      "surah_number": 9,
      "verse_number": 74,
      "content": "يحلفون بالله ما قالوا ولقد قالوا كلمه الكفر وكفروا بعد اسلامهم وهموا بما لم ينالوا وما نقموا الا أن أغنىاهم الله ورسوله من فضله فان يتوبوا يك خيرا لهم وان يتولوا يعذبهم الله عذابا أليما في الدنيا والأخره وما لهم في الأرض من ولي ولا نصير"
    },
    {
      "surah_number": 9,
      "verse_number": 75,
      "content": "ومنهم من عاهد الله لئن اتىانا من فضله لنصدقن ولنكونن من الصالحين"
    },
    {
      "surah_number": 9,
      "verse_number": 76,
      "content": "فلما اتىاهم من فضله بخلوا به وتولوا وهم معرضون"
    },
    {
      "surah_number": 9,
      "verse_number": 77,
      "content": "فأعقبهم نفاقا في قلوبهم الىا يوم يلقونه بما أخلفوا الله ما وعدوه وبما كانوا يكذبون"
    },
    {
      "surah_number": 9,
      "verse_number": 78,
      "content": "ألم يعلموا أن الله يعلم سرهم ونجوىاهم وأن الله علام الغيوب"
    },
    {
      "surah_number": 9,
      "verse_number": 79,
      "content": "الذين يلمزون المطوعين من المؤمنين في الصدقات والذين لا يجدون الا جهدهم فيسخرون منهم سخر الله منهم ولهم عذاب أليم"
    },
    {
      "surah_number": 9,
      "verse_number": 80,
      "content": "استغفر لهم أو لا تستغفر لهم ان تستغفر لهم سبعين مره فلن يغفر الله لهم ذالك بأنهم كفروا بالله ورسوله والله لا يهدي القوم الفاسقين"
    },
    {
      "surah_number": 9,
      "verse_number": 81,
      "content": "فرح المخلفون بمقعدهم خلاف رسول الله وكرهوا أن يجاهدوا بأموالهم وأنفسهم في سبيل الله وقالوا لا تنفروا في الحر قل نار جهنم أشد حرا لو كانوا يفقهون"
    },
    {
      "surah_number": 9,
      "verse_number": 82,
      "content": "فليضحكوا قليلا وليبكوا كثيرا جزا بما كانوا يكسبون"
    },
    {
      "surah_number": 9,
      "verse_number": 83,
      "content": "فان رجعك الله الىا طائفه منهم فاستٔذنوك للخروج فقل لن تخرجوا معي أبدا ولن تقاتلوا معي عدوا انكم رضيتم بالقعود أول مره فاقعدوا مع الخالفين"
    },
    {
      "surah_number": 9,
      "verse_number": 84,
      "content": "ولا تصل علىا أحد منهم مات أبدا ولا تقم علىا قبره انهم كفروا بالله ورسوله وماتوا وهم فاسقون"
    },
    {
      "surah_number": 9,
      "verse_number": 85,
      "content": "ولا تعجبك أموالهم وأولادهم انما يريد الله أن يعذبهم بها في الدنيا وتزهق أنفسهم وهم كافرون"
    },
    {
      "surah_number": 9,
      "verse_number": 86,
      "content": "واذا أنزلت سوره أن امنوا بالله وجاهدوا مع رسوله استٔذنك أولوا الطول منهم وقالوا ذرنا نكن مع القاعدين"
    },
    {
      "surah_number": 9,
      "verse_number": 87,
      "content": "رضوا بأن يكونوا مع الخوالف وطبع علىا قلوبهم فهم لا يفقهون"
    },
    {
      "surah_number": 9,
      "verse_number": 88,
      "content": "لاكن الرسول والذين امنوا معه جاهدوا بأموالهم وأنفسهم وأولائك لهم الخيرات وأولائك هم المفلحون"
    },
    {
      "surah_number": 9,
      "verse_number": 89,
      "content": "أعد الله لهم جنات تجري من تحتها الأنهار خالدين فيها ذالك الفوز العظيم"
    },
    {
      "surah_number": 9,
      "verse_number": 90,
      "content": "وجا المعذرون من الأعراب ليؤذن لهم وقعد الذين كذبوا الله ورسوله سيصيب الذين كفروا منهم عذاب أليم"
    },
    {
      "surah_number": 9,
      "verse_number": 91,
      "content": "ليس على الضعفا ولا على المرضىا ولا على الذين لا يجدون ما ينفقون حرج اذا نصحوا لله ورسوله ما على المحسنين من سبيل والله غفور رحيم"
    },
    {
      "surah_number": 9,
      "verse_number": 92,
      "content": "ولا على الذين اذا ما أتوك لتحملهم قلت لا أجد ما أحملكم عليه تولوا وأعينهم تفيض من الدمع حزنا ألا يجدوا ما ينفقون"
    },
    {
      "surah_number": 9,
      "verse_number": 93,
      "content": "انما السبيل على الذين يستٔذنونك وهم أغنيا رضوا بأن يكونوا مع الخوالف وطبع الله علىا قلوبهم فهم لا يعلمون"
    },
    {
      "surah_number": 9,
      "verse_number": 94,
      "content": "يعتذرون اليكم اذا رجعتم اليهم قل لا تعتذروا لن نؤمن لكم قد نبأنا الله من أخباركم وسيرى الله عملكم ورسوله ثم تردون الىا عالم الغيب والشهاده فينبئكم بما كنتم تعملون"
    },
    {
      "surah_number": 9,
      "verse_number": 95,
      "content": "سيحلفون بالله لكم اذا انقلبتم اليهم لتعرضوا عنهم فأعرضوا عنهم انهم رجس ومأوىاهم جهنم جزا بما كانوا يكسبون"
    },
    {
      "surah_number": 9,
      "verse_number": 96,
      "content": "يحلفون لكم لترضوا عنهم فان ترضوا عنهم فان الله لا يرضىا عن القوم الفاسقين"
    },
    {
      "surah_number": 9,
      "verse_number": 97,
      "content": "الأعراب أشد كفرا ونفاقا وأجدر ألا يعلموا حدود ما أنزل الله علىا رسوله والله عليم حكيم"
    },
    {
      "surah_number": 9,
      "verse_number": 98,
      "content": "ومن الأعراب من يتخذ ما ينفق مغرما ويتربص بكم الدوائر عليهم دائره السو والله سميع عليم"
    },
    {
      "surah_number": 9,
      "verse_number": 99,
      "content": "ومن الأعراب من يؤمن بالله واليوم الأخر ويتخذ ما ينفق قربات عند الله وصلوات الرسول ألا انها قربه لهم سيدخلهم الله في رحمته ان الله غفور رحيم"
    },
    {
      "surah_number": 9,
      "verse_number": 100,
      "content": "والسابقون الأولون من المهاجرين والأنصار والذين اتبعوهم باحسان رضي الله عنهم ورضوا عنه وأعد لهم جنات تجري تحتها الأنهار خالدين فيها أبدا ذالك الفوز العظيم"
    },
    {
      "surah_number": 9,
      "verse_number": 101,
      "content": "وممن حولكم من الأعراب منافقون ومن أهل المدينه مردوا على النفاق لا تعلمهم نحن نعلمهم سنعذبهم مرتين ثم يردون الىا عذاب عظيم"
    },
    {
      "surah_number": 9,
      "verse_number": 102,
      "content": "واخرون اعترفوا بذنوبهم خلطوا عملا صالحا واخر سيئا عسى الله أن يتوب عليهم ان الله غفور رحيم"
    },
    {
      "surah_number": 9,
      "verse_number": 103,
      "content": "خذ من أموالهم صدقه تطهرهم وتزكيهم بها وصل عليهم ان صلواتك سكن لهم والله سميع عليم"
    },
    {
      "surah_number": 9,
      "verse_number": 104,
      "content": "ألم يعلموا أن الله هو يقبل التوبه عن عباده ويأخذ الصدقات وأن الله هو التواب الرحيم"
    },
    {
      "surah_number": 9,
      "verse_number": 105,
      "content": "وقل اعملوا فسيرى الله عملكم ورسوله والمؤمنون وستردون الىا عالم الغيب والشهاده فينبئكم بما كنتم تعملون"
    },
    {
      "surah_number": 9,
      "verse_number": 106,
      "content": "واخرون مرجون لأمر الله اما يعذبهم واما يتوب عليهم والله عليم حكيم"
    },
    {
      "surah_number": 9,
      "verse_number": 107,
      "content": "والذين اتخذوا مسجدا ضرارا وكفرا وتفريقا بين المؤمنين وارصادا لمن حارب الله ورسوله من قبل وليحلفن ان أردنا الا الحسنىا والله يشهد انهم لكاذبون"
    },
    {
      "surah_number": 9,
      "verse_number": 108,
      "content": "لا تقم فيه أبدا لمسجد أسس على التقوىا من أول يوم أحق أن تقوم فيه فيه رجال يحبون أن يتطهروا والله يحب المطهرين"
    },
    {
      "surah_number": 9,
      "verse_number": 109,
      "content": "أفمن أسس بنيانه علىا تقوىا من الله ورضوان خير أم من أسس بنيانه علىا شفا جرف هار فانهار به في نار جهنم والله لا يهدي القوم الظالمين"
    },
    {
      "surah_number": 9,
      "verse_number": 110,
      "content": "لا يزال بنيانهم الذي بنوا ريبه في قلوبهم الا أن تقطع قلوبهم والله عليم حكيم"
    },
    {
      "surah_number": 9,
      "verse_number": 111,
      "content": "ان الله اشترىا من المؤمنين أنفسهم وأموالهم بأن لهم الجنه يقاتلون في سبيل الله فيقتلون ويقتلون وعدا عليه حقا في التورىاه والانجيل والقران ومن أوفىا بعهده من الله فاستبشروا ببيعكم الذي بايعتم به وذالك هو الفوز العظيم"
    },
    {
      "surah_number": 9,
      "verse_number": 112,
      "content": "التائبون العابدون الحامدون السائحون الراكعون الساجدون الأمرون بالمعروف والناهون عن المنكر والحافظون لحدود الله وبشر المؤمنين"
    },
    {
      "surah_number": 9,
      "verse_number": 113,
      "content": "ما كان للنبي والذين امنوا أن يستغفروا للمشركين ولو كانوا أولي قربىا من بعد ما تبين لهم أنهم أصحاب الجحيم"
    },
    {
      "surah_number": 9,
      "verse_number": 114,
      "content": "وما كان استغفار ابراهيم لأبيه الا عن موعده وعدها اياه فلما تبين له أنه عدو لله تبرأ منه ان ابراهيم لأواه حليم"
    },
    {
      "surah_number": 9,
      "verse_number": 115,
      "content": "وما كان الله ليضل قوما بعد اذ هدىاهم حتىا يبين لهم ما يتقون ان الله بكل شي عليم"
    },
    {
      "surah_number": 9,
      "verse_number": 116,
      "content": "ان الله له ملك السماوات والأرض يحي ويميت وما لكم من دون الله من ولي ولا نصير"
    },
    {
      "surah_number": 9,
      "verse_number": 117,
      "content": "لقد تاب الله على النبي والمهاجرين والأنصار الذين اتبعوه في ساعه العسره من بعد ما كاد يزيغ قلوب فريق منهم ثم تاب عليهم انه بهم روف رحيم"
    },
    {
      "surah_number": 9,
      "verse_number": 118,
      "content": "وعلى الثلاثه الذين خلفوا حتىا اذا ضاقت عليهم الأرض بما رحبت وضاقت عليهم أنفسهم وظنوا أن لا ملجأ من الله الا اليه ثم تاب عليهم ليتوبوا ان الله هو التواب الرحيم"
    },
    {
      "surah_number": 9,
      "verse_number": 119,
      "content": "ياأيها الذين امنوا اتقوا الله وكونوا مع الصادقين"
    },
    {
      "surah_number": 9,
      "verse_number": 120,
      "content": "ما كان لأهل المدينه ومن حولهم من الأعراب أن يتخلفوا عن رسول الله ولا يرغبوا بأنفسهم عن نفسه ذالك بأنهم لا يصيبهم ظمأ ولا نصب ولا مخمصه في سبيل الله ولا يطٔون موطئا يغيظ الكفار ولا ينالون من عدو نيلا الا كتب لهم به عمل صالح ان الله لا يضيع أجر المحسنين"
    },
    {
      "surah_number": 9,
      "verse_number": 121,
      "content": "ولا ينفقون نفقه صغيره ولا كبيره ولا يقطعون واديا الا كتب لهم ليجزيهم الله أحسن ما كانوا يعملون"
    },
    {
      "surah_number": 9,
      "verse_number": 122,
      "content": "وما كان المؤمنون لينفروا كافه فلولا نفر من كل فرقه منهم طائفه ليتفقهوا في الدين ولينذروا قومهم اذا رجعوا اليهم لعلهم يحذرون"
    },
    {
      "surah_number": 9,
      "verse_number": 123,
      "content": "ياأيها الذين امنوا قاتلوا الذين يلونكم من الكفار وليجدوا فيكم غلظه واعلموا أن الله مع المتقين"
    },
    {
      "surah_number": 9,
      "verse_number": 124,
      "content": "واذا ما أنزلت سوره فمنهم من يقول أيكم زادته هاذه ايمانا فأما الذين امنوا فزادتهم ايمانا وهم يستبشرون"
    },
    {
      "surah_number": 9,
      "verse_number": 125,
      "content": "وأما الذين في قلوبهم مرض فزادتهم رجسا الىا رجسهم وماتوا وهم كافرون"
    },
    {
      "surah_number": 9,
      "verse_number": 126,
      "content": "أولا يرون أنهم يفتنون في كل عام مره أو مرتين ثم لا يتوبون ولا هم يذكرون"
    },
    {
      "surah_number": 9,
      "verse_number": 127,
      "content": "واذا ما أنزلت سوره نظر بعضهم الىا بعض هل يرىاكم من أحد ثم انصرفوا صرف الله قلوبهم بأنهم قوم لا يفقهون"
    },
    {
      "surah_number": 9,
      "verse_number": 128,
      "content": "لقد جاكم رسول من أنفسكم عزيز عليه ما عنتم حريص عليكم بالمؤمنين روف رحيم"
    },
    {
      "surah_number": 9,
      "verse_number": 129,
      "content": "فان تولوا فقل حسبي الله لا الاه الا هو عليه توكلت وهو رب العرش العظيم"
    },
    {
      "surah_number": 10,
      "verse_number": 1,
      "content": "الر تلك ايات الكتاب الحكيم"
    },
    {
      "surah_number": 10,
      "verse_number": 2,
      "content": "أكان للناس عجبا أن أوحينا الىا رجل منهم أن أنذر الناس وبشر الذين امنوا أن لهم قدم صدق عند ربهم قال الكافرون ان هاذا لساحر مبين"
    },
    {
      "surah_number": 10,
      "verse_number": 3,
      "content": "ان ربكم الله الذي خلق السماوات والأرض في سته أيام ثم استوىا على العرش يدبر الأمر ما من شفيع الا من بعد اذنه ذالكم الله ربكم فاعبدوه أفلا تذكرون"
    },
    {
      "surah_number": 10,
      "verse_number": 4,
      "content": "اليه مرجعكم جميعا وعد الله حقا انه يبدؤا الخلق ثم يعيده ليجزي الذين امنوا وعملوا الصالحات بالقسط والذين كفروا لهم شراب من حميم وعذاب أليم بما كانوا يكفرون"
    },
    {
      "surah_number": 10,
      "verse_number": 5,
      "content": "هو الذي جعل الشمس ضيا والقمر نورا وقدره منازل لتعلموا عدد السنين والحساب ما خلق الله ذالك الا بالحق يفصل الأيات لقوم يعلمون"
    },
    {
      "surah_number": 10,
      "verse_number": 6,
      "content": "ان في اختلاف اليل والنهار وما خلق الله في السماوات والأرض لأيات لقوم يتقون"
    },
    {
      "surah_number": 10,
      "verse_number": 7,
      "content": "ان الذين لا يرجون لقانا ورضوا بالحيواه الدنيا واطمأنوا بها والذين هم عن اياتنا غافلون"
    },
    {
      "surah_number": 10,
      "verse_number": 8,
      "content": "أولائك مأوىاهم النار بما كانوا يكسبون"
    },
    {
      "surah_number": 10,
      "verse_number": 9,
      "content": "ان الذين امنوا وعملوا الصالحات يهديهم ربهم بايمانهم تجري من تحتهم الأنهار في جنات النعيم"
    },
    {
      "surah_number": 10,
      "verse_number": 10,
      "content": "دعوىاهم فيها سبحانك اللهم وتحيتهم فيها سلام واخر دعوىاهم أن الحمد لله رب العالمين"
    },
    {
      "surah_number": 10,
      "verse_number": 11,
      "content": "ولو يعجل الله للناس الشر استعجالهم بالخير لقضي اليهم أجلهم فنذر الذين لا يرجون لقانا في طغيانهم يعمهون"
    },
    {
      "surah_number": 10,
      "verse_number": 12,
      "content": "واذا مس الانسان الضر دعانا لجنبه أو قاعدا أو قائما فلما كشفنا عنه ضره مر كأن لم يدعنا الىا ضر مسه كذالك زين للمسرفين ما كانوا يعملون"
    },
    {
      "surah_number": 10,
      "verse_number": 13,
      "content": "ولقد أهلكنا القرون من قبلكم لما ظلموا وجاتهم رسلهم بالبينات وما كانوا ليؤمنوا كذالك نجزي القوم المجرمين"
    },
    {
      "surah_number": 10,
      "verse_number": 14,
      "content": "ثم جعلناكم خلائف في الأرض من بعدهم لننظر كيف تعملون"
    },
    {
      "surah_number": 10,
      "verse_number": 15,
      "content": "واذا تتلىا عليهم اياتنا بينات قال الذين لا يرجون لقانا ائت بقران غير هاذا أو بدله قل ما يكون لي أن أبدله من تلقاي نفسي ان أتبع الا ما يوحىا الي اني أخاف ان عصيت ربي عذاب يوم عظيم"
    },
    {
      "surah_number": 10,
      "verse_number": 16,
      "content": "قل لو شا الله ما تلوته عليكم ولا أدرىاكم به فقد لبثت فيكم عمرا من قبله أفلا تعقلون"
    },
    {
      "surah_number": 10,
      "verse_number": 17,
      "content": "فمن أظلم ممن افترىا على الله كذبا أو كذب بٔاياته انه لا يفلح المجرمون"
    },
    {
      "surah_number": 10,
      "verse_number": 18,
      "content": "ويعبدون من دون الله ما لا يضرهم ولا ينفعهم ويقولون هاؤلا شفعاؤنا عند الله قل أتنبٔون الله بما لا يعلم في السماوات ولا في الأرض سبحانه وتعالىا عما يشركون"
    },
    {
      "surah_number": 10,
      "verse_number": 19,
      "content": "وما كان الناس الا أمه واحده فاختلفوا ولولا كلمه سبقت من ربك لقضي بينهم فيما فيه يختلفون"
    },
    {
      "surah_number": 10,
      "verse_number": 20,
      "content": "ويقولون لولا أنزل عليه ايه من ربه فقل انما الغيب لله فانتظروا اني معكم من المنتظرين"
    },
    {
      "surah_number": 10,
      "verse_number": 21,
      "content": "واذا أذقنا الناس رحمه من بعد ضرا مستهم اذا لهم مكر في اياتنا قل الله أسرع مكرا ان رسلنا يكتبون ما تمكرون"
    },
    {
      "surah_number": 10,
      "verse_number": 22,
      "content": "هو الذي يسيركم في البر والبحر حتىا اذا كنتم في الفلك وجرين بهم بريح طيبه وفرحوا بها جاتها ريح عاصف وجاهم الموج من كل مكان وظنوا أنهم أحيط بهم دعوا الله مخلصين له الدين لئن أنجيتنا من هاذه لنكونن من الشاكرين"
    },
    {
      "surah_number": 10,
      "verse_number": 23,
      "content": "فلما أنجىاهم اذا هم يبغون في الأرض بغير الحق ياأيها الناس انما بغيكم علىا أنفسكم متاع الحيواه الدنيا ثم الينا مرجعكم فننبئكم بما كنتم تعملون"
    },
    {
      "surah_number": 10,
      "verse_number": 24,
      "content": "انما مثل الحيواه الدنيا كما أنزلناه من السما فاختلط به نبات الأرض مما يأكل الناس والأنعام حتىا اذا أخذت الأرض زخرفها وازينت وظن أهلها أنهم قادرون عليها أتىاها أمرنا ليلا أو نهارا فجعلناها حصيدا كأن لم تغن بالأمس كذالك نفصل الأيات لقوم يتفكرون"
    },
    {
      "surah_number": 10,
      "verse_number": 25,
      "content": "والله يدعوا الىا دار السلام ويهدي من يشا الىا صراط مستقيم"
    },
    {
      "surah_number": 10,
      "verse_number": 26,
      "content": "للذين أحسنوا الحسنىا وزياده ولا يرهق وجوههم قتر ولا ذله أولائك أصحاب الجنه هم فيها خالدون"
    },
    {
      "surah_number": 10,
      "verse_number": 27,
      "content": "والذين كسبوا السئات جزا سيئه بمثلها وترهقهم ذله ما لهم من الله من عاصم كأنما أغشيت وجوههم قطعا من اليل مظلما أولائك أصحاب النار هم فيها خالدون"
    },
    {
      "surah_number": 10,
      "verse_number": 28,
      "content": "ويوم نحشرهم جميعا ثم نقول للذين أشركوا مكانكم أنتم وشركاؤكم فزيلنا بينهم وقال شركاؤهم ما كنتم ايانا تعبدون"
    },
    {
      "surah_number": 10,
      "verse_number": 29,
      "content": "فكفىا بالله شهيدا بيننا وبينكم ان كنا عن عبادتكم لغافلين"
    },
    {
      "surah_number": 10,
      "verse_number": 30,
      "content": "هنالك تبلوا كل نفس ما أسلفت وردوا الى الله مولىاهم الحق وضل عنهم ما كانوا يفترون"
    },
    {
      "surah_number": 10,
      "verse_number": 31,
      "content": "قل من يرزقكم من السما والأرض أمن يملك السمع والأبصار ومن يخرج الحي من الميت ويخرج الميت من الحي ومن يدبر الأمر فسيقولون الله فقل أفلا تتقون"
    },
    {
      "surah_number": 10,
      "verse_number": 32,
      "content": "فذالكم الله ربكم الحق فماذا بعد الحق الا الضلال فأنىا تصرفون"
    },
    {
      "surah_number": 10,
      "verse_number": 33,
      "content": "كذالك حقت كلمت ربك على الذين فسقوا أنهم لا يؤمنون"
    },
    {
      "surah_number": 10,
      "verse_number": 34,
      "content": "قل هل من شركائكم من يبدؤا الخلق ثم يعيده قل الله يبدؤا الخلق ثم يعيده فأنىا تؤفكون"
    },
    {
      "surah_number": 10,
      "verse_number": 35,
      "content": "قل هل من شركائكم من يهدي الى الحق قل الله يهدي للحق أفمن يهدي الى الحق أحق أن يتبع أمن لا يهدي الا أن يهدىا فما لكم كيف تحكمون"
    },
    {
      "surah_number": 10,
      "verse_number": 36,
      "content": "وما يتبع أكثرهم الا ظنا ان الظن لا يغني من الحق شئا ان الله عليم بما يفعلون"
    },
    {
      "surah_number": 10,
      "verse_number": 37,
      "content": "وما كان هاذا القران أن يفترىا من دون الله ولاكن تصديق الذي بين يديه وتفصيل الكتاب لا ريب فيه من رب العالمين"
    },
    {
      "surah_number": 10,
      "verse_number": 38,
      "content": "أم يقولون افترىاه قل فأتوا بسوره مثله وادعوا من استطعتم من دون الله ان كنتم صادقين"
    },
    {
      "surah_number": 10,
      "verse_number": 39,
      "content": "بل كذبوا بما لم يحيطوا بعلمه ولما يأتهم تأويله كذالك كذب الذين من قبلهم فانظر كيف كان عاقبه الظالمين"
    },
    {
      "surah_number": 10,
      "verse_number": 40,
      "content": "ومنهم من يؤمن به ومنهم من لا يؤمن به وربك أعلم بالمفسدين"
    },
    {
      "surah_number": 10,
      "verse_number": 41,
      "content": "وان كذبوك فقل لي عملي ولكم عملكم أنتم برئون مما أعمل وأنا بري مما تعملون"
    },
    {
      "surah_number": 10,
      "verse_number": 42,
      "content": "ومنهم من يستمعون اليك أفأنت تسمع الصم ولو كانوا لا يعقلون"
    },
    {
      "surah_number": 10,
      "verse_number": 43,
      "content": "ومنهم من ينظر اليك أفأنت تهدي العمي ولو كانوا لا يبصرون"
    },
    {
      "surah_number": 10,
      "verse_number": 44,
      "content": "ان الله لا يظلم الناس شئا ولاكن الناس أنفسهم يظلمون"
    },
    {
      "surah_number": 10,
      "verse_number": 45,
      "content": "ويوم يحشرهم كأن لم يلبثوا الا ساعه من النهار يتعارفون بينهم قد خسر الذين كذبوا بلقا الله وما كانوا مهتدين"
    },
    {
      "surah_number": 10,
      "verse_number": 46,
      "content": "واما نرينك بعض الذي نعدهم أو نتوفينك فالينا مرجعهم ثم الله شهيد علىا ما يفعلون"
    },
    {
      "surah_number": 10,
      "verse_number": 47,
      "content": "ولكل أمه رسول فاذا جا رسولهم قضي بينهم بالقسط وهم لا يظلمون"
    },
    {
      "surah_number": 10,
      "verse_number": 48,
      "content": "ويقولون متىا هاذا الوعد ان كنتم صادقين"
    },
    {
      "surah_number": 10,
      "verse_number": 49,
      "content": "قل لا أملك لنفسي ضرا ولا نفعا الا ما شا الله لكل أمه أجل اذا جا أجلهم فلا يستٔخرون ساعه ولا يستقدمون"
    },
    {
      "surah_number": 10,
      "verse_number": 50,
      "content": "قل أريتم ان أتىاكم عذابه بياتا أو نهارا ماذا يستعجل منه المجرمون"
    },
    {
      "surah_number": 10,
      "verse_number": 51,
      "content": "أثم اذا ما وقع امنتم به الٔان وقد كنتم به تستعجلون"
    },
    {
      "surah_number": 10,
      "verse_number": 52,
      "content": "ثم قيل للذين ظلموا ذوقوا عذاب الخلد هل تجزون الا بما كنتم تكسبون"
    },
    {
      "surah_number": 10,
      "verse_number": 53,
      "content": "ويستنبٔونك أحق هو قل اي وربي انه لحق وما أنتم بمعجزين"
    },
    {
      "surah_number": 10,
      "verse_number": 54,
      "content": "ولو أن لكل نفس ظلمت ما في الأرض لافتدت به وأسروا الندامه لما رأوا العذاب وقضي بينهم بالقسط وهم لا يظلمون"
    },
    {
      "surah_number": 10,
      "verse_number": 55,
      "content": "ألا ان لله ما في السماوات والأرض ألا ان وعد الله حق ولاكن أكثرهم لا يعلمون"
    },
    {
      "surah_number": 10,
      "verse_number": 56,
      "content": "هو يحي ويميت واليه ترجعون"
    },
    {
      "surah_number": 10,
      "verse_number": 57,
      "content": "ياأيها الناس قد جاتكم موعظه من ربكم وشفا لما في الصدور وهدى ورحمه للمؤمنين"
    },
    {
      "surah_number": 10,
      "verse_number": 58,
      "content": "قل بفضل الله وبرحمته فبذالك فليفرحوا هو خير مما يجمعون"
    },
    {
      "surah_number": 10,
      "verse_number": 59,
      "content": "قل أريتم ما أنزل الله لكم من رزق فجعلتم منه حراما وحلالا قل الله أذن لكم أم على الله تفترون"
    },
    {
      "surah_number": 10,
      "verse_number": 60,
      "content": "وما ظن الذين يفترون على الله الكذب يوم القيامه ان الله لذو فضل على الناس ولاكن أكثرهم لا يشكرون"
    },
    {
      "surah_number": 10,
      "verse_number": 61,
      "content": "وما تكون في شأن وما تتلوا منه من قران ولا تعملون من عمل الا كنا عليكم شهودا اذ تفيضون فيه وما يعزب عن ربك من مثقال ذره في الأرض ولا في السما ولا أصغر من ذالك ولا أكبر الا في كتاب مبين"
    },
    {
      "surah_number": 10,
      "verse_number": 62,
      "content": "ألا ان أوليا الله لا خوف عليهم ولا هم يحزنون"
    },
    {
      "surah_number": 10,
      "verse_number": 63,
      "content": "الذين امنوا وكانوا يتقون"
    },
    {
      "surah_number": 10,
      "verse_number": 64,
      "content": "لهم البشرىا في الحيواه الدنيا وفي الأخره لا تبديل لكلمات الله ذالك هو الفوز العظيم"
    },
    {
      "surah_number": 10,
      "verse_number": 65,
      "content": "ولا يحزنك قولهم ان العزه لله جميعا هو السميع العليم"
    },
    {
      "surah_number": 10,
      "verse_number": 66,
      "content": "ألا ان لله من في السماوات ومن في الأرض وما يتبع الذين يدعون من دون الله شركا ان يتبعون الا الظن وان هم الا يخرصون"
    },
    {
      "surah_number": 10,
      "verse_number": 67,
      "content": "هو الذي جعل لكم اليل لتسكنوا فيه والنهار مبصرا ان في ذالك لأيات لقوم يسمعون"
    },
    {
      "surah_number": 10,
      "verse_number": 68,
      "content": "قالوا اتخذ الله ولدا سبحانه هو الغني له ما في السماوات وما في الأرض ان عندكم من سلطان بهاذا أتقولون على الله ما لا تعلمون"
    },
    {
      "surah_number": 10,
      "verse_number": 69,
      "content": "قل ان الذين يفترون على الله الكذب لا يفلحون"
    },
    {
      "surah_number": 10,
      "verse_number": 70,
      "content": "متاع في الدنيا ثم الينا مرجعهم ثم نذيقهم العذاب الشديد بما كانوا يكفرون"
    },
    {
      "surah_number": 10,
      "verse_number": 71,
      "content": "واتل عليهم نبأ نوح اذ قال لقومه ياقوم ان كان كبر عليكم مقامي وتذكيري بٔايات الله فعلى الله توكلت فأجمعوا أمركم وشركاكم ثم لا يكن أمركم عليكم غمه ثم اقضوا الي ولا تنظرون"
    },
    {
      "surah_number": 10,
      "verse_number": 72,
      "content": "فان توليتم فما سألتكم من أجر ان أجري الا على الله وأمرت أن أكون من المسلمين"
    },
    {
      "surah_number": 10,
      "verse_number": 73,
      "content": "فكذبوه فنجيناه ومن معه في الفلك وجعلناهم خلائف وأغرقنا الذين كذبوا بٔاياتنا فانظر كيف كان عاقبه المنذرين"
    },
    {
      "surah_number": 10,
      "verse_number": 74,
      "content": "ثم بعثنا من بعده رسلا الىا قومهم فجاوهم بالبينات فما كانوا ليؤمنوا بما كذبوا به من قبل كذالك نطبع علىا قلوب المعتدين"
    },
    {
      "surah_number": 10,
      "verse_number": 75,
      "content": "ثم بعثنا من بعدهم موسىا وهارون الىا فرعون وملايه بٔاياتنا فاستكبروا وكانوا قوما مجرمين"
    },
    {
      "surah_number": 10,
      "verse_number": 76,
      "content": "فلما جاهم الحق من عندنا قالوا ان هاذا لسحر مبين"
    },
    {
      "surah_number": 10,
      "verse_number": 77,
      "content": "قال موسىا أتقولون للحق لما جاكم أسحر هاذا ولا يفلح الساحرون"
    },
    {
      "surah_number": 10,
      "verse_number": 78,
      "content": "قالوا أجئتنا لتلفتنا عما وجدنا عليه ابانا وتكون لكما الكبريا في الأرض وما نحن لكما بمؤمنين"
    },
    {
      "surah_number": 10,
      "verse_number": 79,
      "content": "وقال فرعون ائتوني بكل ساحر عليم"
    },
    {
      "surah_number": 10,
      "verse_number": 80,
      "content": "فلما جا السحره قال لهم موسىا ألقوا ما أنتم ملقون"
    },
    {
      "surah_number": 10,
      "verse_number": 81,
      "content": "فلما ألقوا قال موسىا ما جئتم به السحر ان الله سيبطله ان الله لا يصلح عمل المفسدين"
    },
    {
      "surah_number": 10,
      "verse_number": 82,
      "content": "ويحق الله الحق بكلماته ولو كره المجرمون"
    },
    {
      "surah_number": 10,
      "verse_number": 83,
      "content": "فما امن لموسىا الا ذريه من قومه علىا خوف من فرعون وملايهم أن يفتنهم وان فرعون لعال في الأرض وانه لمن المسرفين"
    },
    {
      "surah_number": 10,
      "verse_number": 84,
      "content": "وقال موسىا ياقوم ان كنتم امنتم بالله فعليه توكلوا ان كنتم مسلمين"
    },
    {
      "surah_number": 10,
      "verse_number": 85,
      "content": "فقالوا على الله توكلنا ربنا لا تجعلنا فتنه للقوم الظالمين"
    },
    {
      "surah_number": 10,
      "verse_number": 86,
      "content": "ونجنا برحمتك من القوم الكافرين"
    },
    {
      "surah_number": 10,
      "verse_number": 87,
      "content": "وأوحينا الىا موسىا وأخيه أن تبوا لقومكما بمصر بيوتا واجعلوا بيوتكم قبله وأقيموا الصلواه وبشر المؤمنين"
    },
    {
      "surah_number": 10,
      "verse_number": 88,
      "content": "وقال موسىا ربنا انك اتيت فرعون وملأه زينه وأموالا في الحيواه الدنيا ربنا ليضلوا عن سبيلك ربنا اطمس علىا أموالهم واشدد علىا قلوبهم فلا يؤمنوا حتىا يروا العذاب الأليم"
    },
    {
      "surah_number": 10,
      "verse_number": 89,
      "content": "قال قد أجيبت دعوتكما فاستقيما ولا تتبعان سبيل الذين لا يعلمون"
    },
    {
      "surah_number": 10,
      "verse_number": 90,
      "content": "وجاوزنا ببني اسرايل البحر فأتبعهم فرعون وجنوده بغيا وعدوا حتىا اذا أدركه الغرق قال امنت أنه لا الاه الا الذي امنت به بنوا اسرايل وأنا من المسلمين"
    },
    {
      "surah_number": 10,
      "verse_number": 91,
      "content": "الٔان وقد عصيت قبل وكنت من المفسدين"
    },
    {
      "surah_number": 10,
      "verse_number": 92,
      "content": "فاليوم ننجيك ببدنك لتكون لمن خلفك ايه وان كثيرا من الناس عن اياتنا لغافلون"
    },
    {
      "surah_number": 10,
      "verse_number": 93,
      "content": "ولقد بوأنا بني اسرايل مبوأ صدق ورزقناهم من الطيبات فما اختلفوا حتىا جاهم العلم ان ربك يقضي بينهم يوم القيامه فيما كانوا فيه يختلفون"
    },
    {
      "surah_number": 10,
      "verse_number": 94,
      "content": "فان كنت في شك مما أنزلنا اليك فسٔل الذين يقرون الكتاب من قبلك لقد جاك الحق من ربك فلا تكونن من الممترين"
    },
    {
      "surah_number": 10,
      "verse_number": 95,
      "content": "ولا تكونن من الذين كذبوا بٔايات الله فتكون من الخاسرين"
    },
    {
      "surah_number": 10,
      "verse_number": 96,
      "content": "ان الذين حقت عليهم كلمت ربك لا يؤمنون"
    },
    {
      "surah_number": 10,
      "verse_number": 97,
      "content": "ولو جاتهم كل ايه حتىا يروا العذاب الأليم"
    },
    {
      "surah_number": 10,
      "verse_number": 98,
      "content": "فلولا كانت قريه امنت فنفعها ايمانها الا قوم يونس لما امنوا كشفنا عنهم عذاب الخزي في الحيواه الدنيا ومتعناهم الىا حين"
    },
    {
      "surah_number": 10,
      "verse_number": 99,
      "content": "ولو شا ربك لأمن من في الأرض كلهم جميعا أفأنت تكره الناس حتىا يكونوا مؤمنين"
    },
    {
      "surah_number": 10,
      "verse_number": 100,
      "content": "وما كان لنفس أن تؤمن الا باذن الله ويجعل الرجس على الذين لا يعقلون"
    },
    {
      "surah_number": 10,
      "verse_number": 101,
      "content": "قل انظروا ماذا في السماوات والأرض وما تغني الأيات والنذر عن قوم لا يؤمنون"
    },
    {
      "surah_number": 10,
      "verse_number": 102,
      "content": "فهل ينتظرون الا مثل أيام الذين خلوا من قبلهم قل فانتظروا اني معكم من المنتظرين"
    },
    {
      "surah_number": 10,
      "verse_number": 103,
      "content": "ثم ننجي رسلنا والذين امنوا كذالك حقا علينا ننج المؤمنين"
    },
    {
      "surah_number": 10,
      "verse_number": 104,
      "content": "قل ياأيها الناس ان كنتم في شك من ديني فلا أعبد الذين تعبدون من دون الله ولاكن أعبد الله الذي يتوفىاكم وأمرت أن أكون من المؤمنين"
    },
    {
      "surah_number": 10,
      "verse_number": 105,
      "content": "وأن أقم وجهك للدين حنيفا ولا تكونن من المشركين"
    },
    {
      "surah_number": 10,
      "verse_number": 106,
      "content": "ولا تدع من دون الله ما لا ينفعك ولا يضرك فان فعلت فانك اذا من الظالمين"
    },
    {
      "surah_number": 10,
      "verse_number": 107,
      "content": "وان يمسسك الله بضر فلا كاشف له الا هو وان يردك بخير فلا راد لفضله يصيب به من يشا من عباده وهو الغفور الرحيم"
    },
    {
      "surah_number": 10,
      "verse_number": 108,
      "content": "قل ياأيها الناس قد جاكم الحق من ربكم فمن اهتدىا فانما يهتدي لنفسه ومن ضل فانما يضل عليها وما أنا عليكم بوكيل"
    },
    {
      "surah_number": 10,
      "verse_number": 109,
      "content": "واتبع ما يوحىا اليك واصبر حتىا يحكم الله وهو خير الحاكمين"
    },
    {
      "surah_number": 11,
      "verse_number": 1,
      "content": "الر كتاب أحكمت اياته ثم فصلت من لدن حكيم خبير"
    },
    {
      "surah_number": 11,
      "verse_number": 2,
      "content": "ألا تعبدوا الا الله انني لكم منه نذير وبشير"
    },
    {
      "surah_number": 11,
      "verse_number": 3,
      "content": "وأن استغفروا ربكم ثم توبوا اليه يمتعكم متاعا حسنا الىا أجل مسمى ويؤت كل ذي فضل فضله وان تولوا فاني أخاف عليكم عذاب يوم كبير"
    },
    {
      "surah_number": 11,
      "verse_number": 4,
      "content": "الى الله مرجعكم وهو علىا كل شي قدير"
    },
    {
      "surah_number": 11,
      "verse_number": 5,
      "content": "ألا انهم يثنون صدورهم ليستخفوا منه ألا حين يستغشون ثيابهم يعلم ما يسرون وما يعلنون انه عليم بذات الصدور"
    },
    {
      "surah_number": 11,
      "verse_number": 6,
      "content": "وما من دابه في الأرض الا على الله رزقها ويعلم مستقرها ومستودعها كل في كتاب مبين"
    },
    {
      "surah_number": 11,
      "verse_number": 7,
      "content": "وهو الذي خلق السماوات والأرض في سته أيام وكان عرشه على الما ليبلوكم أيكم أحسن عملا ولئن قلت انكم مبعوثون من بعد الموت ليقولن الذين كفروا ان هاذا الا سحر مبين"
    },
    {
      "surah_number": 11,
      "verse_number": 8,
      "content": "ولئن أخرنا عنهم العذاب الىا أمه معدوده ليقولن ما يحبسه ألا يوم يأتيهم ليس مصروفا عنهم وحاق بهم ما كانوا به يستهزون"
    },
    {
      "surah_number": 11,
      "verse_number": 9,
      "content": "ولئن أذقنا الانسان منا رحمه ثم نزعناها منه انه لئوس كفور"
    },
    {
      "surah_number": 11,
      "verse_number": 10,
      "content": "ولئن أذقناه نعما بعد ضرا مسته ليقولن ذهب السئات عني انه لفرح فخور"
    },
    {
      "surah_number": 11,
      "verse_number": 11,
      "content": "الا الذين صبروا وعملوا الصالحات أولائك لهم مغفره وأجر كبير"
    },
    {
      "surah_number": 11,
      "verse_number": 12,
      "content": "فلعلك تارك بعض ما يوحىا اليك وضائق به صدرك أن يقولوا لولا أنزل عليه كنز أو جا معه ملك انما أنت نذير والله علىا كل شي وكيل"
    },
    {
      "surah_number": 11,
      "verse_number": 13,
      "content": "أم يقولون افترىاه قل فأتوا بعشر سور مثله مفتريات وادعوا من استطعتم من دون الله ان كنتم صادقين"
    },
    {
      "surah_number": 11,
      "verse_number": 14,
      "content": "فالم يستجيبوا لكم فاعلموا أنما أنزل بعلم الله وأن لا الاه الا هو فهل أنتم مسلمون"
    },
    {
      "surah_number": 11,
      "verse_number": 15,
      "content": "من كان يريد الحيواه الدنيا وزينتها نوف اليهم أعمالهم فيها وهم فيها لا يبخسون"
    },
    {
      "surah_number": 11,
      "verse_number": 16,
      "content": "أولائك الذين ليس لهم في الأخره الا النار وحبط ما صنعوا فيها وباطل ما كانوا يعملون"
    },
    {
      "surah_number": 11,
      "verse_number": 17,
      "content": "أفمن كان علىا بينه من ربه ويتلوه شاهد منه ومن قبله كتاب موسىا اماما ورحمه أولائك يؤمنون به ومن يكفر به من الأحزاب فالنار موعده فلا تك في مريه منه انه الحق من ربك ولاكن أكثر الناس لا يؤمنون"
    },
    {
      "surah_number": 11,
      "verse_number": 18,
      "content": "ومن أظلم ممن افترىا على الله كذبا أولائك يعرضون علىا ربهم ويقول الأشهاد هاؤلا الذين كذبوا علىا ربهم ألا لعنه الله على الظالمين"
    },
    {
      "surah_number": 11,
      "verse_number": 19,
      "content": "الذين يصدون عن سبيل الله ويبغونها عوجا وهم بالأخره هم كافرون"
    },
    {
      "surah_number": 11,
      "verse_number": 20,
      "content": "أولائك لم يكونوا معجزين في الأرض وما كان لهم من دون الله من أوليا يضاعف لهم العذاب ما كانوا يستطيعون السمع وما كانوا يبصرون"
    },
    {
      "surah_number": 11,
      "verse_number": 21,
      "content": "أولائك الذين خسروا أنفسهم وضل عنهم ما كانوا يفترون"
    },
    {
      "surah_number": 11,
      "verse_number": 22,
      "content": "لا جرم أنهم في الأخره هم الأخسرون"
    },
    {
      "surah_number": 11,
      "verse_number": 23,
      "content": "ان الذين امنوا وعملوا الصالحات وأخبتوا الىا ربهم أولائك أصحاب الجنه هم فيها خالدون"
    },
    {
      "surah_number": 11,
      "verse_number": 24,
      "content": "مثل الفريقين كالأعمىا والأصم والبصير والسميع هل يستويان مثلا أفلا تذكرون"
    },
    {
      "surah_number": 11,
      "verse_number": 25,
      "content": "ولقد أرسلنا نوحا الىا قومه اني لكم نذير مبين"
    },
    {
      "surah_number": 11,
      "verse_number": 26,
      "content": "أن لا تعبدوا الا الله اني أخاف عليكم عذاب يوم أليم"
    },
    {
      "surah_number": 11,
      "verse_number": 27,
      "content": "فقال الملأ الذين كفروا من قومه ما نرىاك الا بشرا مثلنا وما نرىاك اتبعك الا الذين هم أراذلنا بادي الرأي وما نرىا لكم علينا من فضل بل نظنكم كاذبين"
    },
    {
      "surah_number": 11,
      "verse_number": 28,
      "content": "قال ياقوم أريتم ان كنت علىا بينه من ربي واتىاني رحمه من عنده فعميت عليكم أنلزمكموها وأنتم لها كارهون"
    },
    {
      "surah_number": 11,
      "verse_number": 29,
      "content": "وياقوم لا أسٔلكم عليه مالا ان أجري الا على الله وما أنا بطارد الذين امنوا انهم ملاقوا ربهم ولاكني أرىاكم قوما تجهلون"
    },
    {
      "surah_number": 11,
      "verse_number": 30,
      "content": "وياقوم من ينصرني من الله ان طردتهم أفلا تذكرون"
    },
    {
      "surah_number": 11,
      "verse_number": 31,
      "content": "ولا أقول لكم عندي خزائن الله ولا أعلم الغيب ولا أقول اني ملك ولا أقول للذين تزدري أعينكم لن يؤتيهم الله خيرا الله أعلم بما في أنفسهم اني اذا لمن الظالمين"
    },
    {
      "surah_number": 11,
      "verse_number": 32,
      "content": "قالوا يانوح قد جادلتنا فأكثرت جدالنا فأتنا بما تعدنا ان كنت من الصادقين"
    },
    {
      "surah_number": 11,
      "verse_number": 33,
      "content": "قال انما يأتيكم به الله ان شا وما أنتم بمعجزين"
    },
    {
      "surah_number": 11,
      "verse_number": 34,
      "content": "ولا ينفعكم نصحي ان أردت أن أنصح لكم ان كان الله يريد أن يغويكم هو ربكم واليه ترجعون"
    },
    {
      "surah_number": 11,
      "verse_number": 35,
      "content": "أم يقولون افترىاه قل ان افتريته فعلي اجرامي وأنا بري مما تجرمون"
    },
    {
      "surah_number": 11,
      "verse_number": 36,
      "content": "وأوحي الىا نوح أنه لن يؤمن من قومك الا من قد امن فلا تبتئس بما كانوا يفعلون"
    },
    {
      "surah_number": 11,
      "verse_number": 37,
      "content": "واصنع الفلك بأعيننا ووحينا ولا تخاطبني في الذين ظلموا انهم مغرقون"
    },
    {
      "surah_number": 11,
      "verse_number": 38,
      "content": "ويصنع الفلك وكلما مر عليه ملأ من قومه سخروا منه قال ان تسخروا منا فانا نسخر منكم كما تسخرون"
    },
    {
      "surah_number": 11,
      "verse_number": 39,
      "content": "فسوف تعلمون من يأتيه عذاب يخزيه ويحل عليه عذاب مقيم"
    },
    {
      "surah_number": 11,
      "verse_number": 40,
      "content": "حتىا اذا جا أمرنا وفار التنور قلنا احمل فيها من كل زوجين اثنين وأهلك الا من سبق عليه القول ومن امن وما امن معه الا قليل"
    },
    {
      "surah_number": 11,
      "verse_number": 41,
      "content": "وقال اركبوا فيها بسم الله مجرىاها ومرسىاها ان ربي لغفور رحيم"
    },
    {
      "surah_number": 11,
      "verse_number": 42,
      "content": "وهي تجري بهم في موج كالجبال ونادىا نوح ابنه وكان في معزل يابني اركب معنا ولا تكن مع الكافرين"
    },
    {
      "surah_number": 11,
      "verse_number": 43,
      "content": "قال سٔاوي الىا جبل يعصمني من الما قال لا عاصم اليوم من أمر الله الا من رحم وحال بينهما الموج فكان من المغرقين"
    },
    {
      "surah_number": 11,
      "verse_number": 44,
      "content": "وقيل ياأرض ابلعي ماك وياسما أقلعي وغيض الما وقضي الأمر واستوت على الجودي وقيل بعدا للقوم الظالمين"
    },
    {
      "surah_number": 11,
      "verse_number": 45,
      "content": "ونادىا نوح ربه فقال رب ان ابني من أهلي وان وعدك الحق وأنت أحكم الحاكمين"
    },
    {
      "surah_number": 11,
      "verse_number": 46,
      "content": "قال يانوح انه ليس من أهلك انه عمل غير صالح فلا تسٔلن ما ليس لك به علم اني أعظك أن تكون من الجاهلين"
    },
    {
      "surah_number": 11,
      "verse_number": 47,
      "content": "قال رب اني أعوذ بك أن أسٔلك ما ليس لي به علم والا تغفر لي وترحمني أكن من الخاسرين"
    },
    {
      "surah_number": 11,
      "verse_number": 48,
      "content": "قيل يانوح اهبط بسلام منا وبركات عليك وعلىا أمم ممن معك وأمم سنمتعهم ثم يمسهم منا عذاب أليم"
    },
    {
      "surah_number": 11,
      "verse_number": 49,
      "content": "تلك من أنبا الغيب نوحيها اليك ما كنت تعلمها أنت ولا قومك من قبل هاذا فاصبر ان العاقبه للمتقين"
    },
    {
      "surah_number": 11,
      "verse_number": 50,
      "content": "والىا عاد أخاهم هودا قال ياقوم اعبدوا الله ما لكم من الاه غيره ان أنتم الا مفترون"
    },
    {
      "surah_number": 11,
      "verse_number": 51,
      "content": "ياقوم لا أسٔلكم عليه أجرا ان أجري الا على الذي فطرني أفلا تعقلون"
    },
    {
      "surah_number": 11,
      "verse_number": 52,
      "content": "وياقوم استغفروا ربكم ثم توبوا اليه يرسل السما عليكم مدرارا ويزدكم قوه الىا قوتكم ولا تتولوا مجرمين"
    },
    {
      "surah_number": 11,
      "verse_number": 53,
      "content": "قالوا ياهود ما جئتنا ببينه وما نحن بتاركي الهتنا عن قولك وما نحن لك بمؤمنين"
    },
    {
      "surah_number": 11,
      "verse_number": 54,
      "content": "ان نقول الا اعترىاك بعض الهتنا بسو قال اني أشهد الله واشهدوا أني بري مما تشركون"
    },
    {
      "surah_number": 11,
      "verse_number": 55,
      "content": "من دونه فكيدوني جميعا ثم لا تنظرون"
    },
    {
      "surah_number": 11,
      "verse_number": 56,
      "content": "اني توكلت على الله ربي وربكم ما من دابه الا هو اخذ بناصيتها ان ربي علىا صراط مستقيم"
    },
    {
      "surah_number": 11,
      "verse_number": 57,
      "content": "فان تولوا فقد أبلغتكم ما أرسلت به اليكم ويستخلف ربي قوما غيركم ولا تضرونه شئا ان ربي علىا كل شي حفيظ"
    },
    {
      "surah_number": 11,
      "verse_number": 58,
      "content": "ولما جا أمرنا نجينا هودا والذين امنوا معه برحمه منا ونجيناهم من عذاب غليظ"
    },
    {
      "surah_number": 11,
      "verse_number": 59,
      "content": "وتلك عاد جحدوا بٔايات ربهم وعصوا رسله واتبعوا أمر كل جبار عنيد"
    },
    {
      "surah_number": 11,
      "verse_number": 60,
      "content": "وأتبعوا في هاذه الدنيا لعنه ويوم القيامه ألا ان عادا كفروا ربهم ألا بعدا لعاد قوم هود"
    },
    {
      "surah_number": 11,
      "verse_number": 61,
      "content": "والىا ثمود أخاهم صالحا قال ياقوم اعبدوا الله ما لكم من الاه غيره هو أنشأكم من الأرض واستعمركم فيها فاستغفروه ثم توبوا اليه ان ربي قريب مجيب"
    },
    {
      "surah_number": 11,
      "verse_number": 62,
      "content": "قالوا ياصالح قد كنت فينا مرجوا قبل هاذا أتنهىانا أن نعبد ما يعبد اباؤنا واننا لفي شك مما تدعونا اليه مريب"
    },
    {
      "surah_number": 11,
      "verse_number": 63,
      "content": "قال ياقوم أريتم ان كنت علىا بينه من ربي واتىاني منه رحمه فمن ينصرني من الله ان عصيته فما تزيدونني غير تخسير"
    },
    {
      "surah_number": 11,
      "verse_number": 64,
      "content": "وياقوم هاذه ناقه الله لكم ايه فذروها تأكل في أرض الله ولا تمسوها بسو فيأخذكم عذاب قريب"
    },
    {
      "surah_number": 11,
      "verse_number": 65,
      "content": "فعقروها فقال تمتعوا في داركم ثلاثه أيام ذالك وعد غير مكذوب"
    },
    {
      "surah_number": 11,
      "verse_number": 66,
      "content": "فلما جا أمرنا نجينا صالحا والذين امنوا معه برحمه منا ومن خزي يومئذ ان ربك هو القوي العزيز"
    },
    {
      "surah_number": 11,
      "verse_number": 67,
      "content": "وأخذ الذين ظلموا الصيحه فأصبحوا في ديارهم جاثمين"
    },
    {
      "surah_number": 11,
      "verse_number": 68,
      "content": "كأن لم يغنوا فيها ألا ان ثمودا كفروا ربهم ألا بعدا لثمود"
    },
    {
      "surah_number": 11,
      "verse_number": 69,
      "content": "ولقد جات رسلنا ابراهيم بالبشرىا قالوا سلاما قال سلام فما لبث أن جا بعجل حنيذ"
    },
    {
      "surah_number": 11,
      "verse_number": 70,
      "content": "فلما را أيديهم لا تصل اليه نكرهم وأوجس منهم خيفه قالوا لا تخف انا أرسلنا الىا قوم لوط"
    },
    {
      "surah_number": 11,
      "verse_number": 71,
      "content": "وامرأته قائمه فضحكت فبشرناها باسحاق ومن ورا اسحاق يعقوب"
    },
    {
      "surah_number": 11,
      "verse_number": 72,
      "content": "قالت ياويلتىا ءألد وأنا عجوز وهاذا بعلي شيخا ان هاذا لشي عجيب"
    },
    {
      "surah_number": 11,
      "verse_number": 73,
      "content": "قالوا أتعجبين من أمر الله رحمت الله وبركاته عليكم أهل البيت انه حميد مجيد"
    },
    {
      "surah_number": 11,
      "verse_number": 74,
      "content": "فلما ذهب عن ابراهيم الروع وجاته البشرىا يجادلنا في قوم لوط"
    },
    {
      "surah_number": 11,
      "verse_number": 75,
      "content": "ان ابراهيم لحليم أواه منيب"
    },
    {
      "surah_number": 11,
      "verse_number": 76,
      "content": "ياابراهيم أعرض عن هاذا انه قد جا أمر ربك وانهم اتيهم عذاب غير مردود"
    },
    {
      "surah_number": 11,
      "verse_number": 77,
      "content": "ولما جات رسلنا لوطا سي بهم وضاق بهم ذرعا وقال هاذا يوم عصيب"
    },
    {
      "surah_number": 11,
      "verse_number": 78,
      "content": "وجاه قومه يهرعون اليه ومن قبل كانوا يعملون السئات قال ياقوم هاؤلا بناتي هن أطهر لكم فاتقوا الله ولا تخزون في ضيفي أليس منكم رجل رشيد"
    },
    {
      "surah_number": 11,
      "verse_number": 79,
      "content": "قالوا لقد علمت ما لنا في بناتك من حق وانك لتعلم ما نريد"
    },
    {
      "surah_number": 11,
      "verse_number": 80,
      "content": "قال لو أن لي بكم قوه أو اوي الىا ركن شديد"
    },
    {
      "surah_number": 11,
      "verse_number": 81,
      "content": "قالوا يالوط انا رسل ربك لن يصلوا اليك فأسر بأهلك بقطع من اليل ولا يلتفت منكم أحد الا امرأتك انه مصيبها ما أصابهم ان موعدهم الصبح أليس الصبح بقريب"
    },
    {
      "surah_number": 11,
      "verse_number": 82,
      "content": "فلما جا أمرنا جعلنا عاليها سافلها وأمطرنا عليها حجاره من سجيل منضود"
    },
    {
      "surah_number": 11,
      "verse_number": 83,
      "content": "مسومه عند ربك وما هي من الظالمين ببعيد"
    },
    {
      "surah_number": 11,
      "verse_number": 84,
      "content": "والىا مدين أخاهم شعيبا قال ياقوم اعبدوا الله ما لكم من الاه غيره ولا تنقصوا المكيال والميزان اني أرىاكم بخير واني أخاف عليكم عذاب يوم محيط"
    },
    {
      "surah_number": 11,
      "verse_number": 85,
      "content": "وياقوم أوفوا المكيال والميزان بالقسط ولا تبخسوا الناس أشياهم ولا تعثوا في الأرض مفسدين"
    },
    {
      "surah_number": 11,
      "verse_number": 86,
      "content": "بقيت الله خير لكم ان كنتم مؤمنين وما أنا عليكم بحفيظ"
    },
    {
      "surah_number": 11,
      "verse_number": 87,
      "content": "قالوا ياشعيب أصلواتك تأمرك أن نترك ما يعبد اباؤنا أو أن نفعل في أموالنا ما نشاؤا انك لأنت الحليم الرشيد"
    },
    {
      "surah_number": 11,
      "verse_number": 88,
      "content": "قال ياقوم أريتم ان كنت علىا بينه من ربي ورزقني منه رزقا حسنا وما أريد أن أخالفكم الىا ما أنهىاكم عنه ان أريد الا الاصلاح ما استطعت وما توفيقي الا بالله عليه توكلت واليه أنيب"
    },
    {
      "surah_number": 11,
      "verse_number": 89,
      "content": "وياقوم لا يجرمنكم شقاقي أن يصيبكم مثل ما أصاب قوم نوح أو قوم هود أو قوم صالح وما قوم لوط منكم ببعيد"
    },
    {
      "surah_number": 11,
      "verse_number": 90,
      "content": "واستغفروا ربكم ثم توبوا اليه ان ربي رحيم ودود"
    },
    {
      "surah_number": 11,
      "verse_number": 91,
      "content": "قالوا ياشعيب ما نفقه كثيرا مما تقول وانا لنرىاك فينا ضعيفا ولولا رهطك لرجمناك وما أنت علينا بعزيز"
    },
    {
      "surah_number": 11,
      "verse_number": 92,
      "content": "قال ياقوم أرهطي أعز عليكم من الله واتخذتموه وراكم ظهريا ان ربي بما تعملون محيط"
    },
    {
      "surah_number": 11,
      "verse_number": 93,
      "content": "وياقوم اعملوا علىا مكانتكم اني عامل سوف تعلمون من يأتيه عذاب يخزيه ومن هو كاذب وارتقبوا اني معكم رقيب"
    },
    {
      "surah_number": 11,
      "verse_number": 94,
      "content": "ولما جا أمرنا نجينا شعيبا والذين امنوا معه برحمه منا وأخذت الذين ظلموا الصيحه فأصبحوا في ديارهم جاثمين"
    },
    {
      "surah_number": 11,
      "verse_number": 95,
      "content": "كأن لم يغنوا فيها ألا بعدا لمدين كما بعدت ثمود"
    },
    {
      "surah_number": 11,
      "verse_number": 96,
      "content": "ولقد أرسلنا موسىا بٔاياتنا وسلطان مبين"
    },
    {
      "surah_number": 11,
      "verse_number": 97,
      "content": "الىا فرعون وملايه فاتبعوا أمر فرعون وما أمر فرعون برشيد"
    },
    {
      "surah_number": 11,
      "verse_number": 98,
      "content": "يقدم قومه يوم القيامه فأوردهم النار وبئس الورد المورود"
    },
    {
      "surah_number": 11,
      "verse_number": 99,
      "content": "وأتبعوا في هاذه لعنه ويوم القيامه بئس الرفد المرفود"
    },
    {
      "surah_number": 11,
      "verse_number": 100,
      "content": "ذالك من أنبا القرىا نقصه عليك منها قائم وحصيد"
    },
    {
      "surah_number": 11,
      "verse_number": 101,
      "content": "وما ظلمناهم ولاكن ظلموا أنفسهم فما أغنت عنهم الهتهم التي يدعون من دون الله من شي لما جا أمر ربك وما زادوهم غير تتبيب"
    },
    {
      "surah_number": 11,
      "verse_number": 102,
      "content": "وكذالك أخذ ربك اذا أخذ القرىا وهي ظالمه ان أخذه أليم شديد"
    },
    {
      "surah_number": 11,
      "verse_number": 103,
      "content": "ان في ذالك لأيه لمن خاف عذاب الأخره ذالك يوم مجموع له الناس وذالك يوم مشهود"
    },
    {
      "surah_number": 11,
      "verse_number": 104,
      "content": "وما نؤخره الا لأجل معدود"
    },
    {
      "surah_number": 11,
      "verse_number": 105,
      "content": "يوم يأت لا تكلم نفس الا باذنه فمنهم شقي وسعيد"
    },
    {
      "surah_number": 11,
      "verse_number": 106,
      "content": "فأما الذين شقوا ففي النار لهم فيها زفير وشهيق"
    },
    {
      "surah_number": 11,
      "verse_number": 107,
      "content": "خالدين فيها ما دامت السماوات والأرض الا ما شا ربك ان ربك فعال لما يريد"
    },
    {
      "surah_number": 11,
      "verse_number": 108,
      "content": "وأما الذين سعدوا ففي الجنه خالدين فيها ما دامت السماوات والأرض الا ما شا ربك عطا غير مجذوذ"
    },
    {
      "surah_number": 11,
      "verse_number": 109,
      "content": "فلا تك في مريه مما يعبد هاؤلا ما يعبدون الا كما يعبد اباؤهم من قبل وانا لموفوهم نصيبهم غير منقوص"
    },
    {
      "surah_number": 11,
      "verse_number": 110,
      "content": "ولقد اتينا موسى الكتاب فاختلف فيه ولولا كلمه سبقت من ربك لقضي بينهم وانهم لفي شك منه مريب"
    },
    {
      "surah_number": 11,
      "verse_number": 111,
      "content": "وان كلا لما ليوفينهم ربك أعمالهم انه بما يعملون خبير"
    },
    {
      "surah_number": 11,
      "verse_number": 112,
      "content": "فاستقم كما أمرت ومن تاب معك ولا تطغوا انه بما تعملون بصير"
    },
    {
      "surah_number": 11,
      "verse_number": 113,
      "content": "ولا تركنوا الى الذين ظلموا فتمسكم النار وما لكم من دون الله من أوليا ثم لا تنصرون"
    },
    {
      "surah_number": 11,
      "verse_number": 114,
      "content": "وأقم الصلواه طرفي النهار وزلفا من اليل ان الحسنات يذهبن السئات ذالك ذكرىا للذاكرين"
    },
    {
      "surah_number": 11,
      "verse_number": 115,
      "content": "واصبر فان الله لا يضيع أجر المحسنين"
    },
    {
      "surah_number": 11,
      "verse_number": 116,
      "content": "فلولا كان من القرون من قبلكم أولوا بقيه ينهون عن الفساد في الأرض الا قليلا ممن أنجينا منهم واتبع الذين ظلموا ما أترفوا فيه وكانوا مجرمين"
    },
    {
      "surah_number": 11,
      "verse_number": 117,
      "content": "وما كان ربك ليهلك القرىا بظلم وأهلها مصلحون"
    },
    {
      "surah_number": 11,
      "verse_number": 118,
      "content": "ولو شا ربك لجعل الناس أمه واحده ولا يزالون مختلفين"
    },
    {
      "surah_number": 11,
      "verse_number": 119,
      "content": "الا من رحم ربك ولذالك خلقهم وتمت كلمه ربك لأملأن جهنم من الجنه والناس أجمعين"
    },
    {
      "surah_number": 11,
      "verse_number": 120,
      "content": "وكلا نقص عليك من أنبا الرسل ما نثبت به فؤادك وجاك في هاذه الحق وموعظه وذكرىا للمؤمنين"
    },
    {
      "surah_number": 11,
      "verse_number": 121,
      "content": "وقل للذين لا يؤمنون اعملوا علىا مكانتكم انا عاملون"
    },
    {
      "surah_number": 11,
      "verse_number": 122,
      "content": "وانتظروا انا منتظرون"
    },
    {
      "surah_number": 11,
      "verse_number": 123,
      "content": "ولله غيب السماوات والأرض واليه يرجع الأمر كله فاعبده وتوكل عليه وما ربك بغافل عما تعملون"
    },
    {
      "surah_number": 12,
      "verse_number": 1,
      "content": "الر تلك ايات الكتاب المبين"
    },
    {
      "surah_number": 12,
      "verse_number": 2,
      "content": "انا أنزلناه قرانا عربيا لعلكم تعقلون"
    },
    {
      "surah_number": 12,
      "verse_number": 3,
      "content": "نحن نقص عليك أحسن القصص بما أوحينا اليك هاذا القران وان كنت من قبله لمن الغافلين"
    },
    {
      "surah_number": 12,
      "verse_number": 4,
      "content": "اذ قال يوسف لأبيه ياأبت اني رأيت أحد عشر كوكبا والشمس والقمر رأيتهم لي ساجدين"
    },
    {
      "surah_number": 12,
      "verse_number": 5,
      "content": "قال يابني لا تقصص رياك علىا اخوتك فيكيدوا لك كيدا ان الشيطان للانسان عدو مبين"
    },
    {
      "surah_number": 12,
      "verse_number": 6,
      "content": "وكذالك يجتبيك ربك ويعلمك من تأويل الأحاديث ويتم نعمته عليك وعلىا ال يعقوب كما أتمها علىا أبويك من قبل ابراهيم واسحاق ان ربك عليم حكيم"
    },
    {
      "surah_number": 12,
      "verse_number": 7,
      "content": "لقد كان في يوسف واخوته ايات للسائلين"
    },
    {
      "surah_number": 12,
      "verse_number": 8,
      "content": "اذ قالوا ليوسف وأخوه أحب الىا أبينا منا ونحن عصبه ان أبانا لفي ضلال مبين"
    },
    {
      "surah_number": 12,
      "verse_number": 9,
      "content": "اقتلوا يوسف أو اطرحوه أرضا يخل لكم وجه أبيكم وتكونوا من بعده قوما صالحين"
    },
    {
      "surah_number": 12,
      "verse_number": 10,
      "content": "قال قائل منهم لا تقتلوا يوسف وألقوه في غيابت الجب يلتقطه بعض السياره ان كنتم فاعلين"
    },
    {
      "surah_number": 12,
      "verse_number": 11,
      "content": "قالوا ياأبانا ما لك لا تأمنا علىا يوسف وانا له لناصحون"
    },
    {
      "surah_number": 12,
      "verse_number": 12,
      "content": "أرسله معنا غدا يرتع ويلعب وانا له لحافظون"
    },
    {
      "surah_number": 12,
      "verse_number": 13,
      "content": "قال اني ليحزنني أن تذهبوا به وأخاف أن يأكله الذئب وأنتم عنه غافلون"
    },
    {
      "surah_number": 12,
      "verse_number": 14,
      "content": "قالوا لئن أكله الذئب ونحن عصبه انا اذا لخاسرون"
    },
    {
      "surah_number": 12,
      "verse_number": 15,
      "content": "فلما ذهبوا به وأجمعوا أن يجعلوه في غيابت الجب وأوحينا اليه لتنبئنهم بأمرهم هاذا وهم لا يشعرون"
    },
    {
      "surah_number": 12,
      "verse_number": 16,
      "content": "وجاو أباهم عشا يبكون"
    },
    {
      "surah_number": 12,
      "verse_number": 17,
      "content": "قالوا ياأبانا انا ذهبنا نستبق وتركنا يوسف عند متاعنا فأكله الذئب وما أنت بمؤمن لنا ولو كنا صادقين"
    },
    {
      "surah_number": 12,
      "verse_number": 18,
      "content": "وجاو علىا قميصه بدم كذب قال بل سولت لكم أنفسكم أمرا فصبر جميل والله المستعان علىا ما تصفون"
    },
    {
      "surah_number": 12,
      "verse_number": 19,
      "content": "وجات سياره فأرسلوا واردهم فأدلىا دلوه قال يابشرىا هاذا غلام وأسروه بضاعه والله عليم بما يعملون"
    },
    {
      "surah_number": 12,
      "verse_number": 20,
      "content": "وشروه بثمن بخس دراهم معدوده وكانوا فيه من الزاهدين"
    },
    {
      "surah_number": 12,
      "verse_number": 21,
      "content": "وقال الذي اشترىاه من مصر لامرأته أكرمي مثوىاه عسىا أن ينفعنا أو نتخذه ولدا وكذالك مكنا ليوسف في الأرض ولنعلمه من تأويل الأحاديث والله غالب علىا أمره ولاكن أكثر الناس لا يعلمون"
    },
    {
      "surah_number": 12,
      "verse_number": 22,
      "content": "ولما بلغ أشده اتيناه حكما وعلما وكذالك نجزي المحسنين"
    },
    {
      "surah_number": 12,
      "verse_number": 23,
      "content": "وراودته التي هو في بيتها عن نفسه وغلقت الأبواب وقالت هيت لك قال معاذ الله انه ربي أحسن مثواي انه لا يفلح الظالمون"
    },
    {
      "surah_number": 12,
      "verse_number": 24,
      "content": "ولقد همت به وهم بها لولا أن را برهان ربه كذالك لنصرف عنه السو والفحشا انه من عبادنا المخلصين"
    },
    {
      "surah_number": 12,
      "verse_number": 25,
      "content": "واستبقا الباب وقدت قميصه من دبر وألفيا سيدها لدا الباب قالت ما جزا من أراد بأهلك سوا الا أن يسجن أو عذاب أليم"
    },
    {
      "surah_number": 12,
      "verse_number": 26,
      "content": "قال هي راودتني عن نفسي وشهد شاهد من أهلها ان كان قميصه قد من قبل فصدقت وهو من الكاذبين"
    },
    {
      "surah_number": 12,
      "verse_number": 27,
      "content": "وان كان قميصه قد من دبر فكذبت وهو من الصادقين"
    },
    {
      "surah_number": 12,
      "verse_number": 28,
      "content": "فلما را قميصه قد من دبر قال انه من كيدكن ان كيدكن عظيم"
    },
    {
      "surah_number": 12,
      "verse_number": 29,
      "content": "يوسف أعرض عن هاذا واستغفري لذنبك انك كنت من الخاطٔين"
    },
    {
      "surah_number": 12,
      "verse_number": 30,
      "content": "وقال نسوه في المدينه امرأت العزيز تراود فتىاها عن نفسه قد شغفها حبا انا لنرىاها في ضلال مبين"
    },
    {
      "surah_number": 12,
      "verse_number": 31,
      "content": "فلما سمعت بمكرهن أرسلت اليهن وأعتدت لهن متكٔا واتت كل واحده منهن سكينا وقالت اخرج عليهن فلما رأينه أكبرنه وقطعن أيديهن وقلن حاش لله ما هاذا بشرا ان هاذا الا ملك كريم"
    },
    {
      "surah_number": 12,
      "verse_number": 32,
      "content": "قالت فذالكن الذي لمتنني فيه ولقد راودته عن نفسه فاستعصم ولئن لم يفعل ما امره ليسجنن وليكونا من الصاغرين"
    },
    {
      "surah_number": 12,
      "verse_number": 33,
      "content": "قال رب السجن أحب الي مما يدعونني اليه والا تصرف عني كيدهن أصب اليهن وأكن من الجاهلين"
    },
    {
      "surah_number": 12,
      "verse_number": 34,
      "content": "فاستجاب له ربه فصرف عنه كيدهن انه هو السميع العليم"
    },
    {
      "surah_number": 12,
      "verse_number": 35,
      "content": "ثم بدا لهم من بعد ما رأوا الأيات ليسجننه حتىا حين"
    },
    {
      "surah_number": 12,
      "verse_number": 36,
      "content": "ودخل معه السجن فتيان قال أحدهما اني أرىاني أعصر خمرا وقال الأخر اني أرىاني أحمل فوق رأسي خبزا تأكل الطير منه نبئنا بتأويله انا نرىاك من المحسنين"
    },
    {
      "surah_number": 12,
      "verse_number": 37,
      "content": "قال لا يأتيكما طعام ترزقانه الا نبأتكما بتأويله قبل أن يأتيكما ذالكما مما علمني ربي اني تركت مله قوم لا يؤمنون بالله وهم بالأخره هم كافرون"
    },
    {
      "surah_number": 12,
      "verse_number": 38,
      "content": "واتبعت مله اباي ابراهيم واسحاق ويعقوب ما كان لنا أن نشرك بالله من شي ذالك من فضل الله علينا وعلى الناس ولاكن أكثر الناس لا يشكرون"
    },
    {
      "surah_number": 12,
      "verse_number": 39,
      "content": "ياصاحبي السجن ءأرباب متفرقون خير أم الله الواحد القهار"
    },
    {
      "surah_number": 12,
      "verse_number": 40,
      "content": "ما تعبدون من دونه الا أسما سميتموها أنتم واباؤكم ما أنزل الله بها من سلطان ان الحكم الا لله أمر ألا تعبدوا الا اياه ذالك الدين القيم ولاكن أكثر الناس لا يعلمون"
    },
    {
      "surah_number": 12,
      "verse_number": 41,
      "content": "ياصاحبي السجن أما أحدكما فيسقي ربه خمرا وأما الأخر فيصلب فتأكل الطير من رأسه قضي الأمر الذي فيه تستفتيان"
    },
    {
      "surah_number": 12,
      "verse_number": 42,
      "content": "وقال للذي ظن أنه ناج منهما اذكرني عند ربك فأنسىاه الشيطان ذكر ربه فلبث في السجن بضع سنين"
    },
    {
      "surah_number": 12,
      "verse_number": 43,
      "content": "وقال الملك اني أرىا سبع بقرات سمان يأكلهن سبع عجاف وسبع سنبلات خضر وأخر يابسات ياأيها الملأ أفتوني في رياي ان كنتم للريا تعبرون"
    },
    {
      "surah_number": 12,
      "verse_number": 44,
      "content": "قالوا أضغاث أحلام وما نحن بتأويل الأحلام بعالمين"
    },
    {
      "surah_number": 12,
      "verse_number": 45,
      "content": "وقال الذي نجا منهما وادكر بعد أمه أنا أنبئكم بتأويله فأرسلون"
    },
    {
      "surah_number": 12,
      "verse_number": 46,
      "content": "يوسف أيها الصديق أفتنا في سبع بقرات سمان يأكلهن سبع عجاف وسبع سنبلات خضر وأخر يابسات لعلي أرجع الى الناس لعلهم يعلمون"
    },
    {
      "surah_number": 12,
      "verse_number": 47,
      "content": "قال تزرعون سبع سنين دأبا فما حصدتم فذروه في سنبله الا قليلا مما تأكلون"
    },
    {
      "surah_number": 12,
      "verse_number": 48,
      "content": "ثم يأتي من بعد ذالك سبع شداد يأكلن ما قدمتم لهن الا قليلا مما تحصنون"
    },
    {
      "surah_number": 12,
      "verse_number": 49,
      "content": "ثم يأتي من بعد ذالك عام فيه يغاث الناس وفيه يعصرون"
    },
    {
      "surah_number": 12,
      "verse_number": 50,
      "content": "وقال الملك ائتوني به فلما جاه الرسول قال ارجع الىا ربك فسٔله ما بال النسوه الاتي قطعن أيديهن ان ربي بكيدهن عليم"
    },
    {
      "surah_number": 12,
      "verse_number": 51,
      "content": "قال ما خطبكن اذ راودتن يوسف عن نفسه قلن حاش لله ما علمنا عليه من سو قالت امرأت العزيز الٔان حصحص الحق أنا راودته عن نفسه وانه لمن الصادقين"
    },
    {
      "surah_number": 12,
      "verse_number": 52,
      "content": "ذالك ليعلم أني لم أخنه بالغيب وأن الله لا يهدي كيد الخائنين"
    },
    {
      "surah_number": 12,
      "verse_number": 53,
      "content": "وما أبرئ نفسي ان النفس لأماره بالسو الا ما رحم ربي ان ربي غفور رحيم"
    },
    {
      "surah_number": 12,
      "verse_number": 54,
      "content": "وقال الملك ائتوني به أستخلصه لنفسي فلما كلمه قال انك اليوم لدينا مكين أمين"
    },
    {
      "surah_number": 12,
      "verse_number": 55,
      "content": "قال اجعلني علىا خزائن الأرض اني حفيظ عليم"
    },
    {
      "surah_number": 12,
      "verse_number": 56,
      "content": "وكذالك مكنا ليوسف في الأرض يتبوأ منها حيث يشا نصيب برحمتنا من نشا ولا نضيع أجر المحسنين"
    },
    {
      "surah_number": 12,
      "verse_number": 57,
      "content": "ولأجر الأخره خير للذين امنوا وكانوا يتقون"
    },
    {
      "surah_number": 12,
      "verse_number": 58,
      "content": "وجا اخوه يوسف فدخلوا عليه فعرفهم وهم له منكرون"
    },
    {
      "surah_number": 12,
      "verse_number": 59,
      "content": "ولما جهزهم بجهازهم قال ائتوني بأخ لكم من أبيكم ألا ترون أني أوفي الكيل وأنا خير المنزلين"
    },
    {
      "surah_number": 12,
      "verse_number": 60,
      "content": "فان لم تأتوني به فلا كيل لكم عندي ولا تقربون"
    },
    {
      "surah_number": 12,
      "verse_number": 61,
      "content": "قالوا سنراود عنه أباه وانا لفاعلون"
    },
    {
      "surah_number": 12,
      "verse_number": 62,
      "content": "وقال لفتيانه اجعلوا بضاعتهم في رحالهم لعلهم يعرفونها اذا انقلبوا الىا أهلهم لعلهم يرجعون"
    },
    {
      "surah_number": 12,
      "verse_number": 63,
      "content": "فلما رجعوا الىا أبيهم قالوا ياأبانا منع منا الكيل فأرسل معنا أخانا نكتل وانا له لحافظون"
    },
    {
      "surah_number": 12,
      "verse_number": 64,
      "content": "قال هل امنكم عليه الا كما أمنتكم علىا أخيه من قبل فالله خير حافظا وهو أرحم الراحمين"
    },
    {
      "surah_number": 12,
      "verse_number": 65,
      "content": "ولما فتحوا متاعهم وجدوا بضاعتهم ردت اليهم قالوا ياأبانا ما نبغي هاذه بضاعتنا ردت الينا ونمير أهلنا ونحفظ أخانا ونزداد كيل بعير ذالك كيل يسير"
    },
    {
      "surah_number": 12,
      "verse_number": 66,
      "content": "قال لن أرسله معكم حتىا تؤتون موثقا من الله لتأتنني به الا أن يحاط بكم فلما اتوه موثقهم قال الله علىا ما نقول وكيل"
    },
    {
      "surah_number": 12,
      "verse_number": 67,
      "content": "وقال يابني لا تدخلوا من باب واحد وادخلوا من أبواب متفرقه وما أغني عنكم من الله من شي ان الحكم الا لله عليه توكلت وعليه فليتوكل المتوكلون"
    },
    {
      "surah_number": 12,
      "verse_number": 68,
      "content": "ولما دخلوا من حيث أمرهم أبوهم ما كان يغني عنهم من الله من شي الا حاجه في نفس يعقوب قضىاها وانه لذو علم لما علمناه ولاكن أكثر الناس لا يعلمون"
    },
    {
      "surah_number": 12,
      "verse_number": 69,
      "content": "ولما دخلوا علىا يوسف اوىا اليه أخاه قال اني أنا أخوك فلا تبتئس بما كانوا يعملون"
    },
    {
      "surah_number": 12,
      "verse_number": 70,
      "content": "فلما جهزهم بجهازهم جعل السقايه في رحل أخيه ثم أذن مؤذن أيتها العير انكم لسارقون"
    },
    {
      "surah_number": 12,
      "verse_number": 71,
      "content": "قالوا وأقبلوا عليهم ماذا تفقدون"
    },
    {
      "surah_number": 12,
      "verse_number": 72,
      "content": "قالوا نفقد صواع الملك ولمن جا به حمل بعير وأنا به زعيم"
    },
    {
      "surah_number": 12,
      "verse_number": 73,
      "content": "قالوا تالله لقد علمتم ما جئنا لنفسد في الأرض وما كنا سارقين"
    },
    {
      "surah_number": 12,
      "verse_number": 74,
      "content": "قالوا فما جزاؤه ان كنتم كاذبين"
    },
    {
      "surah_number": 12,
      "verse_number": 75,
      "content": "قالوا جزاؤه من وجد في رحله فهو جزاؤه كذالك نجزي الظالمين"
    },
    {
      "surah_number": 12,
      "verse_number": 76,
      "content": "فبدأ بأوعيتهم قبل وعا أخيه ثم استخرجها من وعا أخيه كذالك كدنا ليوسف ما كان ليأخذ أخاه في دين الملك الا أن يشا الله نرفع درجات من نشا وفوق كل ذي علم عليم"
    },
    {
      "surah_number": 12,
      "verse_number": 77,
      "content": "قالوا ان يسرق فقد سرق أخ له من قبل فأسرها يوسف في نفسه ولم يبدها لهم قال أنتم شر مكانا والله أعلم بما تصفون"
    },
    {
      "surah_number": 12,
      "verse_number": 78,
      "content": "قالوا ياأيها العزيز ان له أبا شيخا كبيرا فخذ أحدنا مكانه انا نرىاك من المحسنين"
    },
    {
      "surah_number": 12,
      "verse_number": 79,
      "content": "قال معاذ الله أن نأخذ الا من وجدنا متاعنا عنده انا اذا لظالمون"
    },
    {
      "surah_number": 12,
      "verse_number": 80,
      "content": "فلما استئسوا منه خلصوا نجيا قال كبيرهم ألم تعلموا أن أباكم قد أخذ عليكم موثقا من الله ومن قبل ما فرطتم في يوسف فلن أبرح الأرض حتىا يأذن لي أبي أو يحكم الله لي وهو خير الحاكمين"
    },
    {
      "surah_number": 12,
      "verse_number": 81,
      "content": "ارجعوا الىا أبيكم فقولوا ياأبانا ان ابنك سرق وما شهدنا الا بما علمنا وما كنا للغيب حافظين"
    },
    {
      "surah_number": 12,
      "verse_number": 82,
      "content": "وسٔل القريه التي كنا فيها والعير التي أقبلنا فيها وانا لصادقون"
    },
    {
      "surah_number": 12,
      "verse_number": 83,
      "content": "قال بل سولت لكم أنفسكم أمرا فصبر جميل عسى الله أن يأتيني بهم جميعا انه هو العليم الحكيم"
    },
    {
      "surah_number": 12,
      "verse_number": 84,
      "content": "وتولىا عنهم وقال ياأسفىا علىا يوسف وابيضت عيناه من الحزن فهو كظيم"
    },
    {
      "surah_number": 12,
      "verse_number": 85,
      "content": "قالوا تالله تفتؤا تذكر يوسف حتىا تكون حرضا أو تكون من الهالكين"
    },
    {
      "surah_number": 12,
      "verse_number": 86,
      "content": "قال انما أشكوا بثي وحزني الى الله وأعلم من الله ما لا تعلمون"
    },
    {
      "surah_number": 12,
      "verse_number": 87,
      "content": "يابني اذهبوا فتحسسوا من يوسف وأخيه ولا تائسوا من روح الله انه لا يائس من روح الله الا القوم الكافرون"
    },
    {
      "surah_number": 12,
      "verse_number": 88,
      "content": "فلما دخلوا عليه قالوا ياأيها العزيز مسنا وأهلنا الضر وجئنا ببضاعه مزجىاه فأوف لنا الكيل وتصدق علينا ان الله يجزي المتصدقين"
    },
    {
      "surah_number": 12,
      "verse_number": 89,
      "content": "قال هل علمتم ما فعلتم بيوسف وأخيه اذ أنتم جاهلون"
    },
    {
      "surah_number": 12,
      "verse_number": 90,
      "content": "قالوا أنك لأنت يوسف قال أنا يوسف وهاذا أخي قد من الله علينا انه من يتق ويصبر فان الله لا يضيع أجر المحسنين"
    },
    {
      "surah_number": 12,
      "verse_number": 91,
      "content": "قالوا تالله لقد اثرك الله علينا وان كنا لخاطٔين"
    },
    {
      "surah_number": 12,
      "verse_number": 92,
      "content": "قال لا تثريب عليكم اليوم يغفر الله لكم وهو أرحم الراحمين"
    },
    {
      "surah_number": 12,
      "verse_number": 93,
      "content": "اذهبوا بقميصي هاذا فألقوه علىا وجه أبي يأت بصيرا وأتوني بأهلكم أجمعين"
    },
    {
      "surah_number": 12,
      "verse_number": 94,
      "content": "ولما فصلت العير قال أبوهم اني لأجد ريح يوسف لولا أن تفندون"
    },
    {
      "surah_number": 12,
      "verse_number": 95,
      "content": "قالوا تالله انك لفي ضلالك القديم"
    },
    {
      "surah_number": 12,
      "verse_number": 96,
      "content": "فلما أن جا البشير ألقىاه علىا وجهه فارتد بصيرا قال ألم أقل لكم اني أعلم من الله ما لا تعلمون"
    },
    {
      "surah_number": 12,
      "verse_number": 97,
      "content": "قالوا ياأبانا استغفر لنا ذنوبنا انا كنا خاطٔين"
    },
    {
      "surah_number": 12,
      "verse_number": 98,
      "content": "قال سوف أستغفر لكم ربي انه هو الغفور الرحيم"
    },
    {
      "surah_number": 12,
      "verse_number": 99,
      "content": "فلما دخلوا علىا يوسف اوىا اليه أبويه وقال ادخلوا مصر ان شا الله امنين"
    },
    {
      "surah_number": 12,
      "verse_number": 100,
      "content": "ورفع أبويه على العرش وخروا له سجدا وقال ياأبت هاذا تأويل رياي من قبل قد جعلها ربي حقا وقد أحسن بي اذ أخرجني من السجن وجا بكم من البدو من بعد أن نزغ الشيطان بيني وبين اخوتي ان ربي لطيف لما يشا انه هو العليم الحكيم"
    },
    {
      "surah_number": 12,
      "verse_number": 101,
      "content": "رب قد اتيتني من الملك وعلمتني من تأويل الأحاديث فاطر السماوات والأرض أنت ولي في الدنيا والأخره توفني مسلما وألحقني بالصالحين"
    },
    {
      "surah_number": 12,
      "verse_number": 102,
      "content": "ذالك من أنبا الغيب نوحيه اليك وما كنت لديهم اذ أجمعوا أمرهم وهم يمكرون"
    },
    {
      "surah_number": 12,
      "verse_number": 103,
      "content": "وما أكثر الناس ولو حرصت بمؤمنين"
    },
    {
      "surah_number": 12,
      "verse_number": 104,
      "content": "وما تسٔلهم عليه من أجر ان هو الا ذكر للعالمين"
    },
    {
      "surah_number": 12,
      "verse_number": 105,
      "content": "وكأين من ايه في السماوات والأرض يمرون عليها وهم عنها معرضون"
    },
    {
      "surah_number": 12,
      "verse_number": 106,
      "content": "وما يؤمن أكثرهم بالله الا وهم مشركون"
    },
    {
      "surah_number": 12,
      "verse_number": 107,
      "content": "أفأمنوا أن تأتيهم غاشيه من عذاب الله أو تأتيهم الساعه بغته وهم لا يشعرون"
    },
    {
      "surah_number": 12,
      "verse_number": 108,
      "content": "قل هاذه سبيلي أدعوا الى الله علىا بصيره أنا ومن اتبعني وسبحان الله وما أنا من المشركين"
    },
    {
      "surah_number": 12,
      "verse_number": 109,
      "content": "وما أرسلنا من قبلك الا رجالا نوحي اليهم من أهل القرىا أفلم يسيروا في الأرض فينظروا كيف كان عاقبه الذين من قبلهم ولدار الأخره خير للذين اتقوا أفلا تعقلون"
    },
    {
      "surah_number": 12,
      "verse_number": 110,
      "content": "حتىا اذا استئس الرسل وظنوا أنهم قد كذبوا جاهم نصرنا فنجي من نشا ولا يرد بأسنا عن القوم المجرمين"
    },
    {
      "surah_number": 12,
      "verse_number": 111,
      "content": "لقد كان في قصصهم عبره لأولي الألباب ما كان حديثا يفترىا ولاكن تصديق الذي بين يديه وتفصيل كل شي وهدى ورحمه لقوم يؤمنون"
    },
    {
      "surah_number": 13,
      "verse_number": 1,
      "content": "المر تلك ايات الكتاب والذي أنزل اليك من ربك الحق ولاكن أكثر الناس لا يؤمنون"
    },
    {
      "surah_number": 13,
      "verse_number": 2,
      "content": "الله الذي رفع السماوات بغير عمد ترونها ثم استوىا على العرش وسخر الشمس والقمر كل يجري لأجل مسمى يدبر الأمر يفصل الأيات لعلكم بلقا ربكم توقنون"
    },
    {
      "surah_number": 13,
      "verse_number": 3,
      "content": "وهو الذي مد الأرض وجعل فيها رواسي وأنهارا ومن كل الثمرات جعل فيها زوجين اثنين يغشي اليل النهار ان في ذالك لأيات لقوم يتفكرون"
    },
    {
      "surah_number": 13,
      "verse_number": 4,
      "content": "وفي الأرض قطع متجاورات وجنات من أعناب وزرع ونخيل صنوان وغير صنوان يسقىا بما واحد ونفضل بعضها علىا بعض في الأكل ان في ذالك لأيات لقوم يعقلون"
    },
    {
      "surah_number": 13,
      "verse_number": 5,
      "content": "وان تعجب فعجب قولهم أذا كنا ترابا أنا لفي خلق جديد أولائك الذين كفروا بربهم وأولائك الأغلال في أعناقهم وأولائك أصحاب النار هم فيها خالدون"
    },
    {
      "surah_number": 13,
      "verse_number": 6,
      "content": "ويستعجلونك بالسيئه قبل الحسنه وقد خلت من قبلهم المثلات وان ربك لذو مغفره للناس علىا ظلمهم وان ربك لشديد العقاب"
    },
    {
      "surah_number": 13,
      "verse_number": 7,
      "content": "ويقول الذين كفروا لولا أنزل عليه ايه من ربه انما أنت منذر ولكل قوم هاد"
    },
    {
      "surah_number": 13,
      "verse_number": 8,
      "content": "الله يعلم ما تحمل كل أنثىا وما تغيض الأرحام وما تزداد وكل شي عنده بمقدار"
    },
    {
      "surah_number": 13,
      "verse_number": 9,
      "content": "عالم الغيب والشهاده الكبير المتعال"
    },
    {
      "surah_number": 13,
      "verse_number": 10,
      "content": "سوا منكم من أسر القول ومن جهر به ومن هو مستخف باليل وسارب بالنهار"
    },
    {
      "surah_number": 13,
      "verse_number": 11,
      "content": "له معقبات من بين يديه ومن خلفه يحفظونه من أمر الله ان الله لا يغير ما بقوم حتىا يغيروا ما بأنفسهم واذا أراد الله بقوم سوا فلا مرد له وما لهم من دونه من وال"
    },
    {
      "surah_number": 13,
      "verse_number": 12,
      "content": "هو الذي يريكم البرق خوفا وطمعا وينشئ السحاب الثقال"
    },
    {
      "surah_number": 13,
      "verse_number": 13,
      "content": "ويسبح الرعد بحمده والملائكه من خيفته ويرسل الصواعق فيصيب بها من يشا وهم يجادلون في الله وهو شديد المحال"
    },
    {
      "surah_number": 13,
      "verse_number": 14,
      "content": "له دعوه الحق والذين يدعون من دونه لا يستجيبون لهم بشي الا كباسط كفيه الى الما ليبلغ فاه وما هو ببالغه وما دعا الكافرين الا في ضلال"
    },
    {
      "surah_number": 13,
      "verse_number": 15,
      "content": "ولله يسجد من في السماوات والأرض طوعا وكرها وظلالهم بالغدو والأصال"
    },
    {
      "surah_number": 13,
      "verse_number": 16,
      "content": "قل من رب السماوات والأرض قل الله قل أفاتخذتم من دونه أوليا لا يملكون لأنفسهم نفعا ولا ضرا قل هل يستوي الأعمىا والبصير أم هل تستوي الظلمات والنور أم جعلوا لله شركا خلقوا كخلقه فتشابه الخلق عليهم قل الله خالق كل شي وهو الواحد القهار"
    },
    {
      "surah_number": 13,
      "verse_number": 17,
      "content": "أنزل من السما ما فسالت أوديه بقدرها فاحتمل السيل زبدا رابيا ومما يوقدون عليه في النار ابتغا حليه أو متاع زبد مثله كذالك يضرب الله الحق والباطل فأما الزبد فيذهب جفا وأما ما ينفع الناس فيمكث في الأرض كذالك يضرب الله الأمثال"
    },
    {
      "surah_number": 13,
      "verse_number": 18,
      "content": "للذين استجابوا لربهم الحسنىا والذين لم يستجيبوا له لو أن لهم ما في الأرض جميعا ومثله معه لافتدوا به أولائك لهم سو الحساب ومأوىاهم جهنم وبئس المهاد"
    },
    {
      "surah_number": 13,
      "verse_number": 19,
      "content": "أفمن يعلم أنما أنزل اليك من ربك الحق كمن هو أعمىا انما يتذكر أولوا الألباب"
    },
    {
      "surah_number": 13,
      "verse_number": 20,
      "content": "الذين يوفون بعهد الله ولا ينقضون الميثاق"
    },
    {
      "surah_number": 13,
      "verse_number": 21,
      "content": "والذين يصلون ما أمر الله به أن يوصل ويخشون ربهم ويخافون سو الحساب"
    },
    {
      "surah_number": 13,
      "verse_number": 22,
      "content": "والذين صبروا ابتغا وجه ربهم وأقاموا الصلواه وأنفقوا مما رزقناهم سرا وعلانيه ويدرون بالحسنه السيئه أولائك لهم عقبى الدار"
    },
    {
      "surah_number": 13,
      "verse_number": 23,
      "content": "جنات عدن يدخلونها ومن صلح من ابائهم وأزواجهم وذرياتهم والملائكه يدخلون عليهم من كل باب"
    },
    {
      "surah_number": 13,
      "verse_number": 24,
      "content": "سلام عليكم بما صبرتم فنعم عقبى الدار"
    },
    {
      "surah_number": 13,
      "verse_number": 25,
      "content": "والذين ينقضون عهد الله من بعد ميثاقه ويقطعون ما أمر الله به أن يوصل ويفسدون في الأرض أولائك لهم اللعنه ولهم سو الدار"
    },
    {
      "surah_number": 13,
      "verse_number": 26,
      "content": "الله يبسط الرزق لمن يشا ويقدر وفرحوا بالحيواه الدنيا وما الحيواه الدنيا في الأخره الا متاع"
    },
    {
      "surah_number": 13,
      "verse_number": 27,
      "content": "ويقول الذين كفروا لولا أنزل عليه ايه من ربه قل ان الله يضل من يشا ويهدي اليه من أناب"
    },
    {
      "surah_number": 13,
      "verse_number": 28,
      "content": "الذين امنوا وتطمئن قلوبهم بذكر الله ألا بذكر الله تطمئن القلوب"
    },
    {
      "surah_number": 13,
      "verse_number": 29,
      "content": "الذين امنوا وعملوا الصالحات طوبىا لهم وحسن مٔاب"
    },
    {
      "surah_number": 13,
      "verse_number": 30,
      "content": "كذالك أرسلناك في أمه قد خلت من قبلها أمم لتتلوا عليهم الذي أوحينا اليك وهم يكفرون بالرحمان قل هو ربي لا الاه الا هو عليه توكلت واليه متاب"
    },
    {
      "surah_number": 13,
      "verse_number": 31,
      "content": "ولو أن قرانا سيرت به الجبال أو قطعت به الأرض أو كلم به الموتىا بل لله الأمر جميعا أفلم يائس الذين امنوا أن لو يشا الله لهدى الناس جميعا ولا يزال الذين كفروا تصيبهم بما صنعوا قارعه أو تحل قريبا من دارهم حتىا يأتي وعد الله ان الله لا يخلف الميعاد"
    },
    {
      "surah_number": 13,
      "verse_number": 32,
      "content": "ولقد استهزئ برسل من قبلك فأمليت للذين كفروا ثم أخذتهم فكيف كان عقاب"
    },
    {
      "surah_number": 13,
      "verse_number": 33,
      "content": "أفمن هو قائم علىا كل نفس بما كسبت وجعلوا لله شركا قل سموهم أم تنبٔونه بما لا يعلم في الأرض أم بظاهر من القول بل زين للذين كفروا مكرهم وصدوا عن السبيل ومن يضلل الله فما له من هاد"
    },
    {
      "surah_number": 13,
      "verse_number": 34,
      "content": "لهم عذاب في الحيواه الدنيا ولعذاب الأخره أشق وما لهم من الله من واق"
    },
    {
      "surah_number": 13,
      "verse_number": 35,
      "content": "مثل الجنه التي وعد المتقون تجري من تحتها الأنهار أكلها دائم وظلها تلك عقبى الذين اتقوا وعقبى الكافرين النار"
    },
    {
      "surah_number": 13,
      "verse_number": 36,
      "content": "والذين اتيناهم الكتاب يفرحون بما أنزل اليك ومن الأحزاب من ينكر بعضه قل انما أمرت أن أعبد الله ولا أشرك به اليه أدعوا واليه مٔاب"
    },
    {
      "surah_number": 13,
      "verse_number": 37,
      "content": "وكذالك أنزلناه حكما عربيا ولئن اتبعت أهواهم بعد ما جاك من العلم ما لك من الله من ولي ولا واق"
    },
    {
      "surah_number": 13,
      "verse_number": 38,
      "content": "ولقد أرسلنا رسلا من قبلك وجعلنا لهم أزواجا وذريه وما كان لرسول أن يأتي بٔايه الا باذن الله لكل أجل كتاب"
    },
    {
      "surah_number": 13,
      "verse_number": 39,
      "content": "يمحوا الله ما يشا ويثبت وعنده أم الكتاب"
    },
    {
      "surah_number": 13,
      "verse_number": 40,
      "content": "وان ما نرينك بعض الذي نعدهم أو نتوفينك فانما عليك البلاغ وعلينا الحساب"
    },
    {
      "surah_number": 13,
      "verse_number": 41,
      "content": "أولم يروا أنا نأتي الأرض ننقصها من أطرافها والله يحكم لا معقب لحكمه وهو سريع الحساب"
    },
    {
      "surah_number": 13,
      "verse_number": 42,
      "content": "وقد مكر الذين من قبلهم فلله المكر جميعا يعلم ما تكسب كل نفس وسيعلم الكفار لمن عقبى الدار"
    },
    {
      "surah_number": 13,
      "verse_number": 43,
      "content": "ويقول الذين كفروا لست مرسلا قل كفىا بالله شهيدا بيني وبينكم ومن عنده علم الكتاب"
    },
    {
      "surah_number": 14,
      "verse_number": 1,
      "content": "الر كتاب أنزلناه اليك لتخرج الناس من الظلمات الى النور باذن ربهم الىا صراط العزيز الحميد"
    },
    {
      "surah_number": 14,
      "verse_number": 2,
      "content": "الله الذي له ما في السماوات وما في الأرض وويل للكافرين من عذاب شديد"
    },
    {
      "surah_number": 14,
      "verse_number": 3,
      "content": "الذين يستحبون الحيواه الدنيا على الأخره ويصدون عن سبيل الله ويبغونها عوجا أولائك في ضلال بعيد"
    },
    {
      "surah_number": 14,
      "verse_number": 4,
      "content": "وما أرسلنا من رسول الا بلسان قومه ليبين لهم فيضل الله من يشا ويهدي من يشا وهو العزيز الحكيم"
    },
    {
      "surah_number": 14,
      "verse_number": 5,
      "content": "ولقد أرسلنا موسىا بٔاياتنا أن أخرج قومك من الظلمات الى النور وذكرهم بأيىام الله ان في ذالك لأيات لكل صبار شكور"
    },
    {
      "surah_number": 14,
      "verse_number": 6,
      "content": "واذ قال موسىا لقومه اذكروا نعمه الله عليكم اذ أنجىاكم من ال فرعون يسومونكم سو العذاب ويذبحون أبناكم ويستحيون نساكم وفي ذالكم بلا من ربكم عظيم"
    },
    {
      "surah_number": 14,
      "verse_number": 7,
      "content": "واذ تأذن ربكم لئن شكرتم لأزيدنكم ولئن كفرتم ان عذابي لشديد"
    },
    {
      "surah_number": 14,
      "verse_number": 8,
      "content": "وقال موسىا ان تكفروا أنتم ومن في الأرض جميعا فان الله لغني حميد"
    },
    {
      "surah_number": 14,
      "verse_number": 9,
      "content": "ألم يأتكم نبؤا الذين من قبلكم قوم نوح وعاد وثمود والذين من بعدهم لا يعلمهم الا الله جاتهم رسلهم بالبينات فردوا أيديهم في أفواههم وقالوا انا كفرنا بما أرسلتم به وانا لفي شك مما تدعوننا اليه مريب"
    },
    {
      "surah_number": 14,
      "verse_number": 10,
      "content": "قالت رسلهم أفي الله شك فاطر السماوات والأرض يدعوكم ليغفر لكم من ذنوبكم ويؤخركم الىا أجل مسمى قالوا ان أنتم الا بشر مثلنا تريدون أن تصدونا عما كان يعبد اباؤنا فأتونا بسلطان مبين"
    },
    {
      "surah_number": 14,
      "verse_number": 11,
      "content": "قالت لهم رسلهم ان نحن الا بشر مثلكم ولاكن الله يمن علىا من يشا من عباده وما كان لنا أن نأتيكم بسلطان الا باذن الله وعلى الله فليتوكل المؤمنون"
    },
    {
      "surah_number": 14,
      "verse_number": 12,
      "content": "وما لنا ألا نتوكل على الله وقد هدىانا سبلنا ولنصبرن علىا ما اذيتمونا وعلى الله فليتوكل المتوكلون"
    },
    {
      "surah_number": 14,
      "verse_number": 13,
      "content": "وقال الذين كفروا لرسلهم لنخرجنكم من أرضنا أو لتعودن في ملتنا فأوحىا اليهم ربهم لنهلكن الظالمين"
    },
    {
      "surah_number": 14,
      "verse_number": 14,
      "content": "ولنسكننكم الأرض من بعدهم ذالك لمن خاف مقامي وخاف وعيد"
    },
    {
      "surah_number": 14,
      "verse_number": 15,
      "content": "واستفتحوا وخاب كل جبار عنيد"
    },
    {
      "surah_number": 14,
      "verse_number": 16,
      "content": "من ورائه جهنم ويسقىا من ما صديد"
    },
    {
      "surah_number": 14,
      "verse_number": 17,
      "content": "يتجرعه ولا يكاد يسيغه ويأتيه الموت من كل مكان وما هو بميت ومن ورائه عذاب غليظ"
    },
    {
      "surah_number": 14,
      "verse_number": 18,
      "content": "مثل الذين كفروا بربهم أعمالهم كرماد اشتدت به الريح في يوم عاصف لا يقدرون مما كسبوا علىا شي ذالك هو الضلال البعيد"
    },
    {
      "surah_number": 14,
      "verse_number": 19,
      "content": "ألم تر أن الله خلق السماوات والأرض بالحق ان يشأ يذهبكم ويأت بخلق جديد"
    },
    {
      "surah_number": 14,
      "verse_number": 20,
      "content": "وما ذالك على الله بعزيز"
    },
    {
      "surah_number": 14,
      "verse_number": 21,
      "content": "وبرزوا لله جميعا فقال الضعفاؤا للذين استكبروا انا كنا لكم تبعا فهل أنتم مغنون عنا من عذاب الله من شي قالوا لو هدىانا الله لهديناكم سوا علينا أجزعنا أم صبرنا ما لنا من محيص"
    },
    {
      "surah_number": 14,
      "verse_number": 22,
      "content": "وقال الشيطان لما قضي الأمر ان الله وعدكم وعد الحق ووعدتكم فأخلفتكم وما كان لي عليكم من سلطان الا أن دعوتكم فاستجبتم لي فلا تلوموني ولوموا أنفسكم ما أنا بمصرخكم وما أنتم بمصرخي اني كفرت بما أشركتمون من قبل ان الظالمين لهم عذاب أليم"
    },
    {
      "surah_number": 14,
      "verse_number": 23,
      "content": "وأدخل الذين امنوا وعملوا الصالحات جنات تجري من تحتها الأنهار خالدين فيها باذن ربهم تحيتهم فيها سلام"
    },
    {
      "surah_number": 14,
      "verse_number": 24,
      "content": "ألم تر كيف ضرب الله مثلا كلمه طيبه كشجره طيبه أصلها ثابت وفرعها في السما"
    },
    {
      "surah_number": 14,
      "verse_number": 25,
      "content": "تؤتي أكلها كل حين باذن ربها ويضرب الله الأمثال للناس لعلهم يتذكرون"
    },
    {
      "surah_number": 14,
      "verse_number": 26,
      "content": "ومثل كلمه خبيثه كشجره خبيثه اجتثت من فوق الأرض ما لها من قرار"
    },
    {
      "surah_number": 14,
      "verse_number": 27,
      "content": "يثبت الله الذين امنوا بالقول الثابت في الحيواه الدنيا وفي الأخره ويضل الله الظالمين ويفعل الله ما يشا"
    },
    {
      "surah_number": 14,
      "verse_number": 28,
      "content": "ألم تر الى الذين بدلوا نعمت الله كفرا وأحلوا قومهم دار البوار"
    },
    {
      "surah_number": 14,
      "verse_number": 29,
      "content": "جهنم يصلونها وبئس القرار"
    },
    {
      "surah_number": 14,
      "verse_number": 30,
      "content": "وجعلوا لله أندادا ليضلوا عن سبيله قل تمتعوا فان مصيركم الى النار"
    },
    {
      "surah_number": 14,
      "verse_number": 31,
      "content": "قل لعبادي الذين امنوا يقيموا الصلواه وينفقوا مما رزقناهم سرا وعلانيه من قبل أن يأتي يوم لا بيع فيه ولا خلال"
    },
    {
      "surah_number": 14,
      "verse_number": 32,
      "content": "الله الذي خلق السماوات والأرض وأنزل من السما ما فأخرج به من الثمرات رزقا لكم وسخر لكم الفلك لتجري في البحر بأمره وسخر لكم الأنهار"
    },
    {
      "surah_number": 14,
      "verse_number": 33,
      "content": "وسخر لكم الشمس والقمر دائبين وسخر لكم اليل والنهار"
    },
    {
      "surah_number": 14,
      "verse_number": 34,
      "content": "واتىاكم من كل ما سألتموه وان تعدوا نعمت الله لا تحصوها ان الانسان لظلوم كفار"
    },
    {
      "surah_number": 14,
      "verse_number": 35,
      "content": "واذ قال ابراهيم رب اجعل هاذا البلد امنا واجنبني وبني أن نعبد الأصنام"
    },
    {
      "surah_number": 14,
      "verse_number": 36,
      "content": "رب انهن أضللن كثيرا من الناس فمن تبعني فانه مني ومن عصاني فانك غفور رحيم"
    },
    {
      "surah_number": 14,
      "verse_number": 37,
      "content": "ربنا اني أسكنت من ذريتي بواد غير ذي زرع عند بيتك المحرم ربنا ليقيموا الصلواه فاجعل أفٔده من الناس تهوي اليهم وارزقهم من الثمرات لعلهم يشكرون"
    },
    {
      "surah_number": 14,
      "verse_number": 38,
      "content": "ربنا انك تعلم ما نخفي وما نعلن وما يخفىا على الله من شي في الأرض ولا في السما"
    },
    {
      "surah_number": 14,
      "verse_number": 39,
      "content": "الحمد لله الذي وهب لي على الكبر اسماعيل واسحاق ان ربي لسميع الدعا"
    },
    {
      "surah_number": 14,
      "verse_number": 40,
      "content": "رب اجعلني مقيم الصلواه ومن ذريتي ربنا وتقبل دعا"
    },
    {
      "surah_number": 14,
      "verse_number": 41,
      "content": "ربنا اغفر لي ولوالدي وللمؤمنين يوم يقوم الحساب"
    },
    {
      "surah_number": 14,
      "verse_number": 42,
      "content": "ولا تحسبن الله غافلا عما يعمل الظالمون انما يؤخرهم ليوم تشخص فيه الأبصار"
    },
    {
      "surah_number": 14,
      "verse_number": 43,
      "content": "مهطعين مقنعي روسهم لا يرتد اليهم طرفهم وأفٔدتهم هوا"
    },
    {
      "surah_number": 14,
      "verse_number": 44,
      "content": "وأنذر الناس يوم يأتيهم العذاب فيقول الذين ظلموا ربنا أخرنا الىا أجل قريب نجب دعوتك ونتبع الرسل أولم تكونوا أقسمتم من قبل ما لكم من زوال"
    },
    {
      "surah_number": 14,
      "verse_number": 45,
      "content": "وسكنتم في مساكن الذين ظلموا أنفسهم وتبين لكم كيف فعلنا بهم وضربنا لكم الأمثال"
    },
    {
      "surah_number": 14,
      "verse_number": 46,
      "content": "وقد مكروا مكرهم وعند الله مكرهم وان كان مكرهم لتزول منه الجبال"
    },
    {
      "surah_number": 14,
      "verse_number": 47,
      "content": "فلا تحسبن الله مخلف وعده رسله ان الله عزيز ذو انتقام"
    },
    {
      "surah_number": 14,
      "verse_number": 48,
      "content": "يوم تبدل الأرض غير الأرض والسماوات وبرزوا لله الواحد القهار"
    },
    {
      "surah_number": 14,
      "verse_number": 49,
      "content": "وترى المجرمين يومئذ مقرنين في الأصفاد"
    },
    {
      "surah_number": 14,
      "verse_number": 50,
      "content": "سرابيلهم من قطران وتغشىا وجوههم النار"
    },
    {
      "surah_number": 14,
      "verse_number": 51,
      "content": "ليجزي الله كل نفس ما كسبت ان الله سريع الحساب"
    },
    {
      "surah_number": 14,
      "verse_number": 52,
      "content": "هاذا بلاغ للناس ولينذروا به وليعلموا أنما هو الاه واحد وليذكر أولوا الألباب"
    },
    {
      "surah_number": 15,
      "verse_number": 1,
      "content": "الر تلك ايات الكتاب وقران مبين"
    },
    {
      "surah_number": 15,
      "verse_number": 2,
      "content": "ربما يود الذين كفروا لو كانوا مسلمين"
    },
    {
      "surah_number": 15,
      "verse_number": 3,
      "content": "ذرهم يأكلوا ويتمتعوا ويلههم الأمل فسوف يعلمون"
    },
    {
      "surah_number": 15,
      "verse_number": 4,
      "content": "وما أهلكنا من قريه الا ولها كتاب معلوم"
    },
    {
      "surah_number": 15,
      "verse_number": 5,
      "content": "ما تسبق من أمه أجلها وما يستٔخرون"
    },
    {
      "surah_number": 15,
      "verse_number": 6,
      "content": "وقالوا ياأيها الذي نزل عليه الذكر انك لمجنون"
    },
    {
      "surah_number": 15,
      "verse_number": 7,
      "content": "لوما تأتينا بالملائكه ان كنت من الصادقين"
    },
    {
      "surah_number": 15,
      "verse_number": 8,
      "content": "ما ننزل الملائكه الا بالحق وما كانوا اذا منظرين"
    },
    {
      "surah_number": 15,
      "verse_number": 9,
      "content": "انا نحن نزلنا الذكر وانا له لحافظون"
    },
    {
      "surah_number": 15,
      "verse_number": 10,
      "content": "ولقد أرسلنا من قبلك في شيع الأولين"
    },
    {
      "surah_number": 15,
      "verse_number": 11,
      "content": "وما يأتيهم من رسول الا كانوا به يستهزون"
    },
    {
      "surah_number": 15,
      "verse_number": 12,
      "content": "كذالك نسلكه في قلوب المجرمين"
    },
    {
      "surah_number": 15,
      "verse_number": 13,
      "content": "لا يؤمنون به وقد خلت سنه الأولين"
    },
    {
      "surah_number": 15,
      "verse_number": 14,
      "content": "ولو فتحنا عليهم بابا من السما فظلوا فيه يعرجون"
    },
    {
      "surah_number": 15,
      "verse_number": 15,
      "content": "لقالوا انما سكرت أبصارنا بل نحن قوم مسحورون"
    },
    {
      "surah_number": 15,
      "verse_number": 16,
      "content": "ولقد جعلنا في السما بروجا وزيناها للناظرين"
    },
    {
      "surah_number": 15,
      "verse_number": 17,
      "content": "وحفظناها من كل شيطان رجيم"
    },
    {
      "surah_number": 15,
      "verse_number": 18,
      "content": "الا من استرق السمع فأتبعه شهاب مبين"
    },
    {
      "surah_number": 15,
      "verse_number": 19,
      "content": "والأرض مددناها وألقينا فيها رواسي وأنبتنا فيها من كل شي موزون"
    },
    {
      "surah_number": 15,
      "verse_number": 20,
      "content": "وجعلنا لكم فيها معايش ومن لستم له برازقين"
    },
    {
      "surah_number": 15,
      "verse_number": 21,
      "content": "وان من شي الا عندنا خزائنه وما ننزله الا بقدر معلوم"
    },
    {
      "surah_number": 15,
      "verse_number": 22,
      "content": "وأرسلنا الرياح لواقح فأنزلنا من السما ما فأسقيناكموه وما أنتم له بخازنين"
    },
    {
      "surah_number": 15,
      "verse_number": 23,
      "content": "وانا لنحن نحي ونميت ونحن الوارثون"
    },
    {
      "surah_number": 15,
      "verse_number": 24,
      "content": "ولقد علمنا المستقدمين منكم ولقد علمنا المستٔخرين"
    },
    {
      "surah_number": 15,
      "verse_number": 25,
      "content": "وان ربك هو يحشرهم انه حكيم عليم"
    },
    {
      "surah_number": 15,
      "verse_number": 26,
      "content": "ولقد خلقنا الانسان من صلصال من حما مسنون"
    },
    {
      "surah_number": 15,
      "verse_number": 27,
      "content": "والجان خلقناه من قبل من نار السموم"
    },
    {
      "surah_number": 15,
      "verse_number": 28,
      "content": "واذ قال ربك للملائكه اني خالق بشرا من صلصال من حما مسنون"
    },
    {
      "surah_number": 15,
      "verse_number": 29,
      "content": "فاذا سويته ونفخت فيه من روحي فقعوا له ساجدين"
    },
    {
      "surah_number": 15,
      "verse_number": 30,
      "content": "فسجد الملائكه كلهم أجمعون"
    },
    {
      "surah_number": 15,
      "verse_number": 31,
      "content": "الا ابليس أبىا أن يكون مع الساجدين"
    },
    {
      "surah_number": 15,
      "verse_number": 32,
      "content": "قال ياابليس ما لك ألا تكون مع الساجدين"
    },
    {
      "surah_number": 15,
      "verse_number": 33,
      "content": "قال لم أكن لأسجد لبشر خلقته من صلصال من حما مسنون"
    },
    {
      "surah_number": 15,
      "verse_number": 34,
      "content": "قال فاخرج منها فانك رجيم"
    },
    {
      "surah_number": 15,
      "verse_number": 35,
      "content": "وان عليك اللعنه الىا يوم الدين"
    },
    {
      "surah_number": 15,
      "verse_number": 36,
      "content": "قال رب فأنظرني الىا يوم يبعثون"
    },
    {
      "surah_number": 15,
      "verse_number": 37,
      "content": "قال فانك من المنظرين"
    },
    {
      "surah_number": 15,
      "verse_number": 38,
      "content": "الىا يوم الوقت المعلوم"
    },
    {
      "surah_number": 15,
      "verse_number": 39,
      "content": "قال رب بما أغويتني لأزينن لهم في الأرض ولأغوينهم أجمعين"
    },
    {
      "surah_number": 15,
      "verse_number": 40,
      "content": "الا عبادك منهم المخلصين"
    },
    {
      "surah_number": 15,
      "verse_number": 41,
      "content": "قال هاذا صراط علي مستقيم"
    },
    {
      "surah_number": 15,
      "verse_number": 42,
      "content": "ان عبادي ليس لك عليهم سلطان الا من اتبعك من الغاوين"
    },
    {
      "surah_number": 15,
      "verse_number": 43,
      "content": "وان جهنم لموعدهم أجمعين"
    },
    {
      "surah_number": 15,
      "verse_number": 44,
      "content": "لها سبعه أبواب لكل باب منهم جز مقسوم"
    },
    {
      "surah_number": 15,
      "verse_number": 45,
      "content": "ان المتقين في جنات وعيون"
    },
    {
      "surah_number": 15,
      "verse_number": 46,
      "content": "ادخلوها بسلام امنين"
    },
    {
      "surah_number": 15,
      "verse_number": 47,
      "content": "ونزعنا ما في صدورهم من غل اخوانا علىا سرر متقابلين"
    },
    {
      "surah_number": 15,
      "verse_number": 48,
      "content": "لا يمسهم فيها نصب وما هم منها بمخرجين"
    },
    {
      "surah_number": 15,
      "verse_number": 49,
      "content": "نبئ عبادي أني أنا الغفور الرحيم"
    },
    {
      "surah_number": 15,
      "verse_number": 50,
      "content": "وأن عذابي هو العذاب الأليم"
    },
    {
      "surah_number": 15,
      "verse_number": 51,
      "content": "ونبئهم عن ضيف ابراهيم"
    },
    {
      "surah_number": 15,
      "verse_number": 52,
      "content": "اذ دخلوا عليه فقالوا سلاما قال انا منكم وجلون"
    },
    {
      "surah_number": 15,
      "verse_number": 53,
      "content": "قالوا لا توجل انا نبشرك بغلام عليم"
    },
    {
      "surah_number": 15,
      "verse_number": 54,
      "content": "قال أبشرتموني علىا أن مسني الكبر فبم تبشرون"
    },
    {
      "surah_number": 15,
      "verse_number": 55,
      "content": "قالوا بشرناك بالحق فلا تكن من القانطين"
    },
    {
      "surah_number": 15,
      "verse_number": 56,
      "content": "قال ومن يقنط من رحمه ربه الا الضالون"
    },
    {
      "surah_number": 15,
      "verse_number": 57,
      "content": "قال فما خطبكم أيها المرسلون"
    },
    {
      "surah_number": 15,
      "verse_number": 58,
      "content": "قالوا انا أرسلنا الىا قوم مجرمين"
    },
    {
      "surah_number": 15,
      "verse_number": 59,
      "content": "الا ال لوط انا لمنجوهم أجمعين"
    },
    {
      "surah_number": 15,
      "verse_number": 60,
      "content": "الا امرأته قدرنا انها لمن الغابرين"
    },
    {
      "surah_number": 15,
      "verse_number": 61,
      "content": "فلما جا ال لوط المرسلون"
    },
    {
      "surah_number": 15,
      "verse_number": 62,
      "content": "قال انكم قوم منكرون"
    },
    {
      "surah_number": 15,
      "verse_number": 63,
      "content": "قالوا بل جئناك بما كانوا فيه يمترون"
    },
    {
      "surah_number": 15,
      "verse_number": 64,
      "content": "وأتيناك بالحق وانا لصادقون"
    },
    {
      "surah_number": 15,
      "verse_number": 65,
      "content": "فأسر بأهلك بقطع من اليل واتبع أدبارهم ولا يلتفت منكم أحد وامضوا حيث تؤمرون"
    },
    {
      "surah_number": 15,
      "verse_number": 66,
      "content": "وقضينا اليه ذالك الأمر أن دابر هاؤلا مقطوع مصبحين"
    },
    {
      "surah_number": 15,
      "verse_number": 67,
      "content": "وجا أهل المدينه يستبشرون"
    },
    {
      "surah_number": 15,
      "verse_number": 68,
      "content": "قال ان هاؤلا ضيفي فلا تفضحون"
    },
    {
      "surah_number": 15,
      "verse_number": 69,
      "content": "واتقوا الله ولا تخزون"
    },
    {
      "surah_number": 15,
      "verse_number": 70,
      "content": "قالوا أولم ننهك عن العالمين"
    },
    {
      "surah_number": 15,
      "verse_number": 71,
      "content": "قال هاؤلا بناتي ان كنتم فاعلين"
    },
    {
      "surah_number": 15,
      "verse_number": 72,
      "content": "لعمرك انهم لفي سكرتهم يعمهون"
    },
    {
      "surah_number": 15,
      "verse_number": 73,
      "content": "فأخذتهم الصيحه مشرقين"
    },
    {
      "surah_number": 15,
      "verse_number": 74,
      "content": "فجعلنا عاليها سافلها وأمطرنا عليهم حجاره من سجيل"
    },
    {
      "surah_number": 15,
      "verse_number": 75,
      "content": "ان في ذالك لأيات للمتوسمين"
    },
    {
      "surah_number": 15,
      "verse_number": 76,
      "content": "وانها لبسبيل مقيم"
    },
    {
      "surah_number": 15,
      "verse_number": 77,
      "content": "ان في ذالك لأيه للمؤمنين"
    },
    {
      "surah_number": 15,
      "verse_number": 78,
      "content": "وان كان أصحاب الأيكه لظالمين"
    },
    {
      "surah_number": 15,
      "verse_number": 79,
      "content": "فانتقمنا منهم وانهما لبامام مبين"
    },
    {
      "surah_number": 15,
      "verse_number": 80,
      "content": "ولقد كذب أصحاب الحجر المرسلين"
    },
    {
      "surah_number": 15,
      "verse_number": 81,
      "content": "واتيناهم اياتنا فكانوا عنها معرضين"
    },
    {
      "surah_number": 15,
      "verse_number": 82,
      "content": "وكانوا ينحتون من الجبال بيوتا امنين"
    },
    {
      "surah_number": 15,
      "verse_number": 83,
      "content": "فأخذتهم الصيحه مصبحين"
    },
    {
      "surah_number": 15,
      "verse_number": 84,
      "content": "فما أغنىا عنهم ما كانوا يكسبون"
    },
    {
      "surah_number": 15,
      "verse_number": 85,
      "content": "وما خلقنا السماوات والأرض وما بينهما الا بالحق وان الساعه لأتيه فاصفح الصفح الجميل"
    },
    {
      "surah_number": 15,
      "verse_number": 86,
      "content": "ان ربك هو الخلاق العليم"
    },
    {
      "surah_number": 15,
      "verse_number": 87,
      "content": "ولقد اتيناك سبعا من المثاني والقران العظيم"
    },
    {
      "surah_number": 15,
      "verse_number": 88,
      "content": "لا تمدن عينيك الىا ما متعنا به أزواجا منهم ولا تحزن عليهم واخفض جناحك للمؤمنين"
    },
    {
      "surah_number": 15,
      "verse_number": 89,
      "content": "وقل اني أنا النذير المبين"
    },
    {
      "surah_number": 15,
      "verse_number": 90,
      "content": "كما أنزلنا على المقتسمين"
    },
    {
      "surah_number": 15,
      "verse_number": 91,
      "content": "الذين جعلوا القران عضين"
    },
    {
      "surah_number": 15,
      "verse_number": 92,
      "content": "فوربك لنسٔلنهم أجمعين"
    },
    {
      "surah_number": 15,
      "verse_number": 93,
      "content": "عما كانوا يعملون"
    },
    {
      "surah_number": 15,
      "verse_number": 94,
      "content": "فاصدع بما تؤمر وأعرض عن المشركين"
    },
    {
      "surah_number": 15,
      "verse_number": 95,
      "content": "انا كفيناك المستهزين"
    },
    {
      "surah_number": 15,
      "verse_number": 96,
      "content": "الذين يجعلون مع الله الاها اخر فسوف يعلمون"
    },
    {
      "surah_number": 15,
      "verse_number": 97,
      "content": "ولقد نعلم أنك يضيق صدرك بما يقولون"
    },
    {
      "surah_number": 15,
      "verse_number": 98,
      "content": "فسبح بحمد ربك وكن من الساجدين"
    },
    {
      "surah_number": 15,
      "verse_number": 99,
      "content": "واعبد ربك حتىا يأتيك اليقين"
    },
    {
      "surah_number": 16,
      "verse_number": 1,
      "content": "أتىا أمر الله فلا تستعجلوه سبحانه وتعالىا عما يشركون"
    },
    {
      "surah_number": 16,
      "verse_number": 2,
      "content": "ينزل الملائكه بالروح من أمره علىا من يشا من عباده أن أنذروا أنه لا الاه الا أنا فاتقون"
    },
    {
      "surah_number": 16,
      "verse_number": 3,
      "content": "خلق السماوات والأرض بالحق تعالىا عما يشركون"
    },
    {
      "surah_number": 16,
      "verse_number": 4,
      "content": "خلق الانسان من نطفه فاذا هو خصيم مبين"
    },
    {
      "surah_number": 16,
      "verse_number": 5,
      "content": "والأنعام خلقها لكم فيها دف ومنافع ومنها تأكلون"
    },
    {
      "surah_number": 16,
      "verse_number": 6,
      "content": "ولكم فيها جمال حين تريحون وحين تسرحون"
    },
    {
      "surah_number": 16,
      "verse_number": 7,
      "content": "وتحمل أثقالكم الىا بلد لم تكونوا بالغيه الا بشق الأنفس ان ربكم لروف رحيم"
    },
    {
      "surah_number": 16,
      "verse_number": 8,
      "content": "والخيل والبغال والحمير لتركبوها وزينه ويخلق ما لا تعلمون"
    },
    {
      "surah_number": 16,
      "verse_number": 9,
      "content": "وعلى الله قصد السبيل ومنها جائر ولو شا لهدىاكم أجمعين"
    },
    {
      "surah_number": 16,
      "verse_number": 10,
      "content": "هو الذي أنزل من السما ما لكم منه شراب ومنه شجر فيه تسيمون"
    },
    {
      "surah_number": 16,
      "verse_number": 11,
      "content": "ينبت لكم به الزرع والزيتون والنخيل والأعناب ومن كل الثمرات ان في ذالك لأيه لقوم يتفكرون"
    },
    {
      "surah_number": 16,
      "verse_number": 12,
      "content": "وسخر لكم اليل والنهار والشمس والقمر والنجوم مسخرات بأمره ان في ذالك لأيات لقوم يعقلون"
    },
    {
      "surah_number": 16,
      "verse_number": 13,
      "content": "وما ذرأ لكم في الأرض مختلفا ألوانه ان في ذالك لأيه لقوم يذكرون"
    },
    {
      "surah_number": 16,
      "verse_number": 14,
      "content": "وهو الذي سخر البحر لتأكلوا منه لحما طريا وتستخرجوا منه حليه تلبسونها وترى الفلك مواخر فيه ولتبتغوا من فضله ولعلكم تشكرون"
    },
    {
      "surah_number": 16,
      "verse_number": 15,
      "content": "وألقىا في الأرض رواسي أن تميد بكم وأنهارا وسبلا لعلكم تهتدون"
    },
    {
      "surah_number": 16,
      "verse_number": 16,
      "content": "وعلامات وبالنجم هم يهتدون"
    },
    {
      "surah_number": 16,
      "verse_number": 17,
      "content": "أفمن يخلق كمن لا يخلق أفلا تذكرون"
    },
    {
      "surah_number": 16,
      "verse_number": 18,
      "content": "وان تعدوا نعمه الله لا تحصوها ان الله لغفور رحيم"
    },
    {
      "surah_number": 16,
      "verse_number": 19,
      "content": "والله يعلم ما تسرون وما تعلنون"
    },
    {
      "surah_number": 16,
      "verse_number": 20,
      "content": "والذين يدعون من دون الله لا يخلقون شئا وهم يخلقون"
    },
    {
      "surah_number": 16,
      "verse_number": 21,
      "content": "أموات غير أحيا وما يشعرون أيان يبعثون"
    },
    {
      "surah_number": 16,
      "verse_number": 22,
      "content": "الاهكم الاه واحد فالذين لا يؤمنون بالأخره قلوبهم منكره وهم مستكبرون"
    },
    {
      "surah_number": 16,
      "verse_number": 23,
      "content": "لا جرم أن الله يعلم ما يسرون وما يعلنون انه لا يحب المستكبرين"
    },
    {
      "surah_number": 16,
      "verse_number": 24,
      "content": "واذا قيل لهم ماذا أنزل ربكم قالوا أساطير الأولين"
    },
    {
      "surah_number": 16,
      "verse_number": 25,
      "content": "ليحملوا أوزارهم كامله يوم القيامه ومن أوزار الذين يضلونهم بغير علم ألا سا ما يزرون"
    },
    {
      "surah_number": 16,
      "verse_number": 26,
      "content": "قد مكر الذين من قبلهم فأتى الله بنيانهم من القواعد فخر عليهم السقف من فوقهم وأتىاهم العذاب من حيث لا يشعرون"
    },
    {
      "surah_number": 16,
      "verse_number": 27,
      "content": "ثم يوم القيامه يخزيهم ويقول أين شركاي الذين كنتم تشاقون فيهم قال الذين أوتوا العلم ان الخزي اليوم والسو على الكافرين"
    },
    {
      "surah_number": 16,
      "verse_number": 28,
      "content": "الذين تتوفىاهم الملائكه ظالمي أنفسهم فألقوا السلم ما كنا نعمل من سو بلىا ان الله عليم بما كنتم تعملون"
    },
    {
      "surah_number": 16,
      "verse_number": 29,
      "content": "فادخلوا أبواب جهنم خالدين فيها فلبئس مثوى المتكبرين"
    },
    {
      "surah_number": 16,
      "verse_number": 30,
      "content": "وقيل للذين اتقوا ماذا أنزل ربكم قالوا خيرا للذين أحسنوا في هاذه الدنيا حسنه ولدار الأخره خير ولنعم دار المتقين"
    },
    {
      "surah_number": 16,
      "verse_number": 31,
      "content": "جنات عدن يدخلونها تجري من تحتها الأنهار لهم فيها ما يشاون كذالك يجزي الله المتقين"
    },
    {
      "surah_number": 16,
      "verse_number": 32,
      "content": "الذين تتوفىاهم الملائكه طيبين يقولون سلام عليكم ادخلوا الجنه بما كنتم تعملون"
    },
    {
      "surah_number": 16,
      "verse_number": 33,
      "content": "هل ينظرون الا أن تأتيهم الملائكه أو يأتي أمر ربك كذالك فعل الذين من قبلهم وما ظلمهم الله ولاكن كانوا أنفسهم يظلمون"
    },
    {
      "surah_number": 16,
      "verse_number": 34,
      "content": "فأصابهم سئات ما عملوا وحاق بهم ما كانوا به يستهزون"
    },
    {
      "surah_number": 16,
      "verse_number": 35,
      "content": "وقال الذين أشركوا لو شا الله ما عبدنا من دونه من شي نحن ولا اباؤنا ولا حرمنا من دونه من شي كذالك فعل الذين من قبلهم فهل على الرسل الا البلاغ المبين"
    },
    {
      "surah_number": 16,
      "verse_number": 36,
      "content": "ولقد بعثنا في كل أمه رسولا أن اعبدوا الله واجتنبوا الطاغوت فمنهم من هدى الله ومنهم من حقت عليه الضلاله فسيروا في الأرض فانظروا كيف كان عاقبه المكذبين"
    },
    {
      "surah_number": 16,
      "verse_number": 37,
      "content": "ان تحرص علىا هدىاهم فان الله لا يهدي من يضل وما لهم من ناصرين"
    },
    {
      "surah_number": 16,
      "verse_number": 38,
      "content": "وأقسموا بالله جهد أيمانهم لا يبعث الله من يموت بلىا وعدا عليه حقا ولاكن أكثر الناس لا يعلمون"
    },
    {
      "surah_number": 16,
      "verse_number": 39,
      "content": "ليبين لهم الذي يختلفون فيه وليعلم الذين كفروا أنهم كانوا كاذبين"
    },
    {
      "surah_number": 16,
      "verse_number": 40,
      "content": "انما قولنا لشي اذا أردناه أن نقول له كن فيكون"
    },
    {
      "surah_number": 16,
      "verse_number": 41,
      "content": "والذين هاجروا في الله من بعد ما ظلموا لنبوئنهم في الدنيا حسنه ولأجر الأخره أكبر لو كانوا يعلمون"
    },
    {
      "surah_number": 16,
      "verse_number": 42,
      "content": "الذين صبروا وعلىا ربهم يتوكلون"
    },
    {
      "surah_number": 16,
      "verse_number": 43,
      "content": "وما أرسلنا من قبلك الا رجالا نوحي اليهم فسٔلوا أهل الذكر ان كنتم لا تعلمون"
    },
    {
      "surah_number": 16,
      "verse_number": 44,
      "content": "بالبينات والزبر وأنزلنا اليك الذكر لتبين للناس ما نزل اليهم ولعلهم يتفكرون"
    },
    {
      "surah_number": 16,
      "verse_number": 45,
      "content": "أفأمن الذين مكروا السئات أن يخسف الله بهم الأرض أو يأتيهم العذاب من حيث لا يشعرون"
    },
    {
      "surah_number": 16,
      "verse_number": 46,
      "content": "أو يأخذهم في تقلبهم فما هم بمعجزين"
    },
    {
      "surah_number": 16,
      "verse_number": 47,
      "content": "أو يأخذهم علىا تخوف فان ربكم لروف رحيم"
    },
    {
      "surah_number": 16,
      "verse_number": 48,
      "content": "أولم يروا الىا ما خلق الله من شي يتفيؤا ظلاله عن اليمين والشمائل سجدا لله وهم داخرون"
    },
    {
      "surah_number": 16,
      "verse_number": 49,
      "content": "ولله يسجد ما في السماوات وما في الأرض من دابه والملائكه وهم لا يستكبرون"
    },
    {
      "surah_number": 16,
      "verse_number": 50,
      "content": "يخافون ربهم من فوقهم ويفعلون ما يؤمرون"
    },
    {
      "surah_number": 16,
      "verse_number": 51,
      "content": "وقال الله لا تتخذوا الاهين اثنين انما هو الاه واحد فاياي فارهبون"
    },
    {
      "surah_number": 16,
      "verse_number": 52,
      "content": "وله ما في السماوات والأرض وله الدين واصبا أفغير الله تتقون"
    },
    {
      "surah_number": 16,
      "verse_number": 53,
      "content": "وما بكم من نعمه فمن الله ثم اذا مسكم الضر فاليه تجٔرون"
    },
    {
      "surah_number": 16,
      "verse_number": 54,
      "content": "ثم اذا كشف الضر عنكم اذا فريق منكم بربهم يشركون"
    },
    {
      "surah_number": 16,
      "verse_number": 55,
      "content": "ليكفروا بما اتيناهم فتمتعوا فسوف تعلمون"
    },
    {
      "surah_number": 16,
      "verse_number": 56,
      "content": "ويجعلون لما لا يعلمون نصيبا مما رزقناهم تالله لتسٔلن عما كنتم تفترون"
    },
    {
      "surah_number": 16,
      "verse_number": 57,
      "content": "ويجعلون لله البنات سبحانه ولهم ما يشتهون"
    },
    {
      "surah_number": 16,
      "verse_number": 58,
      "content": "واذا بشر أحدهم بالأنثىا ظل وجهه مسودا وهو كظيم"
    },
    {
      "surah_number": 16,
      "verse_number": 59,
      "content": "يتوارىا من القوم من سو ما بشر به أيمسكه علىا هون أم يدسه في التراب ألا سا ما يحكمون"
    },
    {
      "surah_number": 16,
      "verse_number": 60,
      "content": "للذين لا يؤمنون بالأخره مثل السو ولله المثل الأعلىا وهو العزيز الحكيم"
    },
    {
      "surah_number": 16,
      "verse_number": 61,
      "content": "ولو يؤاخذ الله الناس بظلمهم ما ترك عليها من دابه ولاكن يؤخرهم الىا أجل مسمى فاذا جا أجلهم لا يستٔخرون ساعه ولا يستقدمون"
    },
    {
      "surah_number": 16,
      "verse_number": 62,
      "content": "ويجعلون لله ما يكرهون وتصف ألسنتهم الكذب أن لهم الحسنىا لا جرم أن لهم النار وأنهم مفرطون"
    },
    {
      "surah_number": 16,
      "verse_number": 63,
      "content": "تالله لقد أرسلنا الىا أمم من قبلك فزين لهم الشيطان أعمالهم فهو وليهم اليوم ولهم عذاب أليم"
    },
    {
      "surah_number": 16,
      "verse_number": 64,
      "content": "وما أنزلنا عليك الكتاب الا لتبين لهم الذي اختلفوا فيه وهدى ورحمه لقوم يؤمنون"
    },
    {
      "surah_number": 16,
      "verse_number": 65,
      "content": "والله أنزل من السما ما فأحيا به الأرض بعد موتها ان في ذالك لأيه لقوم يسمعون"
    },
    {
      "surah_number": 16,
      "verse_number": 66,
      "content": "وان لكم في الأنعام لعبره نسقيكم مما في بطونه من بين فرث ودم لبنا خالصا سائغا للشاربين"
    },
    {
      "surah_number": 16,
      "verse_number": 67,
      "content": "ومن ثمرات النخيل والأعناب تتخذون منه سكرا ورزقا حسنا ان في ذالك لأيه لقوم يعقلون"
    },
    {
      "surah_number": 16,
      "verse_number": 68,
      "content": "وأوحىا ربك الى النحل أن اتخذي من الجبال بيوتا ومن الشجر ومما يعرشون"
    },
    {
      "surah_number": 16,
      "verse_number": 69,
      "content": "ثم كلي من كل الثمرات فاسلكي سبل ربك ذللا يخرج من بطونها شراب مختلف ألوانه فيه شفا للناس ان في ذالك لأيه لقوم يتفكرون"
    },
    {
      "surah_number": 16,
      "verse_number": 70,
      "content": "والله خلقكم ثم يتوفىاكم ومنكم من يرد الىا أرذل العمر لكي لا يعلم بعد علم شئا ان الله عليم قدير"
    },
    {
      "surah_number": 16,
      "verse_number": 71,
      "content": "والله فضل بعضكم علىا بعض في الرزق فما الذين فضلوا برادي رزقهم علىا ما ملكت أيمانهم فهم فيه سوا أفبنعمه الله يجحدون"
    },
    {
      "surah_number": 16,
      "verse_number": 72,
      "content": "والله جعل لكم من أنفسكم أزواجا وجعل لكم من أزواجكم بنين وحفده ورزقكم من الطيبات أفبالباطل يؤمنون وبنعمت الله هم يكفرون"
    },
    {
      "surah_number": 16,
      "verse_number": 73,
      "content": "ويعبدون من دون الله ما لا يملك لهم رزقا من السماوات والأرض شئا ولا يستطيعون"
    },
    {
      "surah_number": 16,
      "verse_number": 74,
      "content": "فلا تضربوا لله الأمثال ان الله يعلم وأنتم لا تعلمون"
    },
    {
      "surah_number": 16,
      "verse_number": 75,
      "content": "ضرب الله مثلا عبدا مملوكا لا يقدر علىا شي ومن رزقناه منا رزقا حسنا فهو ينفق منه سرا وجهرا هل يستون الحمد لله بل أكثرهم لا يعلمون"
    },
    {
      "surah_number": 16,
      "verse_number": 76,
      "content": "وضرب الله مثلا رجلين أحدهما أبكم لا يقدر علىا شي وهو كل علىا مولىاه أينما يوجهه لا يأت بخير هل يستوي هو ومن يأمر بالعدل وهو علىا صراط مستقيم"
    },
    {
      "surah_number": 16,
      "verse_number": 77,
      "content": "ولله غيب السماوات والأرض وما أمر الساعه الا كلمح البصر أو هو أقرب ان الله علىا كل شي قدير"
    },
    {
      "surah_number": 16,
      "verse_number": 78,
      "content": "والله أخرجكم من بطون أمهاتكم لا تعلمون شئا وجعل لكم السمع والأبصار والأفٔده لعلكم تشكرون"
    },
    {
      "surah_number": 16,
      "verse_number": 79,
      "content": "ألم يروا الى الطير مسخرات في جو السما ما يمسكهن الا الله ان في ذالك لأيات لقوم يؤمنون"
    },
    {
      "surah_number": 16,
      "verse_number": 80,
      "content": "والله جعل لكم من بيوتكم سكنا وجعل لكم من جلود الأنعام بيوتا تستخفونها يوم ظعنكم ويوم اقامتكم ومن أصوافها وأوبارها وأشعارها أثاثا ومتاعا الىا حين"
    },
    {
      "surah_number": 16,
      "verse_number": 81,
      "content": "والله جعل لكم مما خلق ظلالا وجعل لكم من الجبال أكنانا وجعل لكم سرابيل تقيكم الحر وسرابيل تقيكم بأسكم كذالك يتم نعمته عليكم لعلكم تسلمون"
    },
    {
      "surah_number": 16,
      "verse_number": 82,
      "content": "فان تولوا فانما عليك البلاغ المبين"
    },
    {
      "surah_number": 16,
      "verse_number": 83,
      "content": "يعرفون نعمت الله ثم ينكرونها وأكثرهم الكافرون"
    },
    {
      "surah_number": 16,
      "verse_number": 84,
      "content": "ويوم نبعث من كل أمه شهيدا ثم لا يؤذن للذين كفروا ولا هم يستعتبون"
    },
    {
      "surah_number": 16,
      "verse_number": 85,
      "content": "واذا را الذين ظلموا العذاب فلا يخفف عنهم ولا هم ينظرون"
    },
    {
      "surah_number": 16,
      "verse_number": 86,
      "content": "واذا را الذين أشركوا شركاهم قالوا ربنا هاؤلا شركاؤنا الذين كنا ندعوا من دونك فألقوا اليهم القول انكم لكاذبون"
    },
    {
      "surah_number": 16,
      "verse_number": 87,
      "content": "وألقوا الى الله يومئذ السلم وضل عنهم ما كانوا يفترون"
    },
    {
      "surah_number": 16,
      "verse_number": 88,
      "content": "الذين كفروا وصدوا عن سبيل الله زدناهم عذابا فوق العذاب بما كانوا يفسدون"
    },
    {
      "surah_number": 16,
      "verse_number": 89,
      "content": "ويوم نبعث في كل أمه شهيدا عليهم من أنفسهم وجئنا بك شهيدا علىا هاؤلا ونزلنا عليك الكتاب تبيانا لكل شي وهدى ورحمه وبشرىا للمسلمين"
    },
    {
      "surah_number": 16,
      "verse_number": 90,
      "content": "ان الله يأمر بالعدل والاحسان وايتاي ذي القربىا وينهىا عن الفحشا والمنكر والبغي يعظكم لعلكم تذكرون"
    },
    {
      "surah_number": 16,
      "verse_number": 91,
      "content": "وأوفوا بعهد الله اذا عاهدتم ولا تنقضوا الأيمان بعد توكيدها وقد جعلتم الله عليكم كفيلا ان الله يعلم ما تفعلون"
    },
    {
      "surah_number": 16,
      "verse_number": 92,
      "content": "ولا تكونوا كالتي نقضت غزلها من بعد قوه أنكاثا تتخذون أيمانكم دخلا بينكم أن تكون أمه هي أربىا من أمه انما يبلوكم الله به وليبينن لكم يوم القيامه ما كنتم فيه تختلفون"
    },
    {
      "surah_number": 16,
      "verse_number": 93,
      "content": "ولو شا الله لجعلكم أمه واحده ولاكن يضل من يشا ويهدي من يشا ولتسٔلن عما كنتم تعملون"
    },
    {
      "surah_number": 16,
      "verse_number": 94,
      "content": "ولا تتخذوا أيمانكم دخلا بينكم فتزل قدم بعد ثبوتها وتذوقوا السو بما صددتم عن سبيل الله ولكم عذاب عظيم"
    },
    {
      "surah_number": 16,
      "verse_number": 95,
      "content": "ولا تشتروا بعهد الله ثمنا قليلا انما عند الله هو خير لكم ان كنتم تعلمون"
    },
    {
      "surah_number": 16,
      "verse_number": 96,
      "content": "ما عندكم ينفد وما عند الله باق ولنجزين الذين صبروا أجرهم بأحسن ما كانوا يعملون"
    },
    {
      "surah_number": 16,
      "verse_number": 97,
      "content": "من عمل صالحا من ذكر أو أنثىا وهو مؤمن فلنحيينه حيواه طيبه ولنجزينهم أجرهم بأحسن ما كانوا يعملون"
    },
    {
      "surah_number": 16,
      "verse_number": 98,
      "content": "فاذا قرأت القران فاستعذ بالله من الشيطان الرجيم"
    },
    {
      "surah_number": 16,
      "verse_number": 99,
      "content": "انه ليس له سلطان على الذين امنوا وعلىا ربهم يتوكلون"
    },
    {
      "surah_number": 16,
      "verse_number": 100,
      "content": "انما سلطانه على الذين يتولونه والذين هم به مشركون"
    },
    {
      "surah_number": 16,
      "verse_number": 101,
      "content": "واذا بدلنا ايه مكان ايه والله أعلم بما ينزل قالوا انما أنت مفتر بل أكثرهم لا يعلمون"
    },
    {
      "surah_number": 16,
      "verse_number": 102,
      "content": "قل نزله روح القدس من ربك بالحق ليثبت الذين امنوا وهدى وبشرىا للمسلمين"
    },
    {
      "surah_number": 16,
      "verse_number": 103,
      "content": "ولقد نعلم أنهم يقولون انما يعلمه بشر لسان الذي يلحدون اليه أعجمي وهاذا لسان عربي مبين"
    },
    {
      "surah_number": 16,
      "verse_number": 104,
      "content": "ان الذين لا يؤمنون بٔايات الله لا يهديهم الله ولهم عذاب أليم"
    },
    {
      "surah_number": 16,
      "verse_number": 105,
      "content": "انما يفتري الكذب الذين لا يؤمنون بٔايات الله وأولائك هم الكاذبون"
    },
    {
      "surah_number": 16,
      "verse_number": 106,
      "content": "من كفر بالله من بعد ايمانه الا من أكره وقلبه مطمئن بالايمان ولاكن من شرح بالكفر صدرا فعليهم غضب من الله ولهم عذاب عظيم"
    },
    {
      "surah_number": 16,
      "verse_number": 107,
      "content": "ذالك بأنهم استحبوا الحيواه الدنيا على الأخره وأن الله لا يهدي القوم الكافرين"
    },
    {
      "surah_number": 16,
      "verse_number": 108,
      "content": "أولائك الذين طبع الله علىا قلوبهم وسمعهم وأبصارهم وأولائك هم الغافلون"
    },
    {
      "surah_number": 16,
      "verse_number": 109,
      "content": "لا جرم أنهم في الأخره هم الخاسرون"
    },
    {
      "surah_number": 16,
      "verse_number": 110,
      "content": "ثم ان ربك للذين هاجروا من بعد ما فتنوا ثم جاهدوا وصبروا ان ربك من بعدها لغفور رحيم"
    },
    {
      "surah_number": 16,
      "verse_number": 111,
      "content": "يوم تأتي كل نفس تجادل عن نفسها وتوفىا كل نفس ما عملت وهم لا يظلمون"
    },
    {
      "surah_number": 16,
      "verse_number": 112,
      "content": "وضرب الله مثلا قريه كانت امنه مطمئنه يأتيها رزقها رغدا من كل مكان فكفرت بأنعم الله فأذاقها الله لباس الجوع والخوف بما كانوا يصنعون"
    },
    {
      "surah_number": 16,
      "verse_number": 113,
      "content": "ولقد جاهم رسول منهم فكذبوه فأخذهم العذاب وهم ظالمون"
    },
    {
      "surah_number": 16,
      "verse_number": 114,
      "content": "فكلوا مما رزقكم الله حلالا طيبا واشكروا نعمت الله ان كنتم اياه تعبدون"
    },
    {
      "surah_number": 16,
      "verse_number": 115,
      "content": "انما حرم عليكم الميته والدم ولحم الخنزير وما أهل لغير الله به فمن اضطر غير باغ ولا عاد فان الله غفور رحيم"
    },
    {
      "surah_number": 16,
      "verse_number": 116,
      "content": "ولا تقولوا لما تصف ألسنتكم الكذب هاذا حلال وهاذا حرام لتفتروا على الله الكذب ان الذين يفترون على الله الكذب لا يفلحون"
    },
    {
      "surah_number": 16,
      "verse_number": 117,
      "content": "متاع قليل ولهم عذاب أليم"
    },
    {
      "surah_number": 16,
      "verse_number": 118,
      "content": "وعلى الذين هادوا حرمنا ما قصصنا عليك من قبل وما ظلمناهم ولاكن كانوا أنفسهم يظلمون"
    },
    {
      "surah_number": 16,
      "verse_number": 119,
      "content": "ثم ان ربك للذين عملوا السو بجهاله ثم تابوا من بعد ذالك وأصلحوا ان ربك من بعدها لغفور رحيم"
    },
    {
      "surah_number": 16,
      "verse_number": 120,
      "content": "ان ابراهيم كان أمه قانتا لله حنيفا ولم يك من المشركين"
    },
    {
      "surah_number": 16,
      "verse_number": 121,
      "content": "شاكرا لأنعمه اجتبىاه وهدىاه الىا صراط مستقيم"
    },
    {
      "surah_number": 16,
      "verse_number": 122,
      "content": "واتيناه في الدنيا حسنه وانه في الأخره لمن الصالحين"
    },
    {
      "surah_number": 16,
      "verse_number": 123,
      "content": "ثم أوحينا اليك أن اتبع مله ابراهيم حنيفا وما كان من المشركين"
    },
    {
      "surah_number": 16,
      "verse_number": 124,
      "content": "انما جعل السبت على الذين اختلفوا فيه وان ربك ليحكم بينهم يوم القيامه فيما كانوا فيه يختلفون"
    },
    {
      "surah_number": 16,
      "verse_number": 125,
      "content": "ادع الىا سبيل ربك بالحكمه والموعظه الحسنه وجادلهم بالتي هي أحسن ان ربك هو أعلم بمن ضل عن سبيله وهو أعلم بالمهتدين"
    },
    {
      "surah_number": 16,
      "verse_number": 126,
      "content": "وان عاقبتم فعاقبوا بمثل ما عوقبتم به ولئن صبرتم لهو خير للصابرين"
    },
    {
      "surah_number": 16,
      "verse_number": 127,
      "content": "واصبر وما صبرك الا بالله ولا تحزن عليهم ولا تك في ضيق مما يمكرون"
    },
    {
      "surah_number": 16,
      "verse_number": 128,
      "content": "ان الله مع الذين اتقوا والذين هم محسنون"
    },
    {
      "surah_number": 17,
      "verse_number": 1,
      "content": "سبحان الذي أسرىا بعبده ليلا من المسجد الحرام الى المسجد الأقصا الذي باركنا حوله لنريه من اياتنا انه هو السميع البصير"
    },
    {
      "surah_number": 17,
      "verse_number": 2,
      "content": "واتينا موسى الكتاب وجعلناه هدى لبني اسرايل ألا تتخذوا من دوني وكيلا"
    },
    {
      "surah_number": 17,
      "verse_number": 3,
      "content": "ذريه من حملنا مع نوح انه كان عبدا شكورا"
    },
    {
      "surah_number": 17,
      "verse_number": 4,
      "content": "وقضينا الىا بني اسرايل في الكتاب لتفسدن في الأرض مرتين ولتعلن علوا كبيرا"
    },
    {
      "surah_number": 17,
      "verse_number": 5,
      "content": "فاذا جا وعد أولىاهما بعثنا عليكم عبادا لنا أولي بأس شديد فجاسوا خلال الديار وكان وعدا مفعولا"
    },
    {
      "surah_number": 17,
      "verse_number": 6,
      "content": "ثم رددنا لكم الكره عليهم وأمددناكم بأموال وبنين وجعلناكم أكثر نفيرا"
    },
    {
      "surah_number": 17,
      "verse_number": 7,
      "content": "ان أحسنتم أحسنتم لأنفسكم وان أسأتم فلها فاذا جا وعد الأخره ليسٔوا وجوهكم وليدخلوا المسجد كما دخلوه أول مره وليتبروا ما علوا تتبيرا"
    },
    {
      "surah_number": 17,
      "verse_number": 8,
      "content": "عسىا ربكم أن يرحمكم وان عدتم عدنا وجعلنا جهنم للكافرين حصيرا"
    },
    {
      "surah_number": 17,
      "verse_number": 9,
      "content": "ان هاذا القران يهدي للتي هي أقوم ويبشر المؤمنين الذين يعملون الصالحات أن لهم أجرا كبيرا"
    },
    {
      "surah_number": 17,
      "verse_number": 10,
      "content": "وأن الذين لا يؤمنون بالأخره أعتدنا لهم عذابا أليما"
    },
    {
      "surah_number": 17,
      "verse_number": 11,
      "content": "ويدع الانسان بالشر دعاه بالخير وكان الانسان عجولا"
    },
    {
      "surah_number": 17,
      "verse_number": 12,
      "content": "وجعلنا اليل والنهار ايتين فمحونا ايه اليل وجعلنا ايه النهار مبصره لتبتغوا فضلا من ربكم ولتعلموا عدد السنين والحساب وكل شي فصلناه تفصيلا"
    },
    {
      "surah_number": 17,
      "verse_number": 13,
      "content": "وكل انسان ألزمناه طائره في عنقه ونخرج له يوم القيامه كتابا يلقىاه منشورا"
    },
    {
      "surah_number": 17,
      "verse_number": 14,
      "content": "اقرأ كتابك كفىا بنفسك اليوم عليك حسيبا"
    },
    {
      "surah_number": 17,
      "verse_number": 15,
      "content": "من اهتدىا فانما يهتدي لنفسه ومن ضل فانما يضل عليها ولا تزر وازره وزر أخرىا وما كنا معذبين حتىا نبعث رسولا"
    },
    {
      "surah_number": 17,
      "verse_number": 16,
      "content": "واذا أردنا أن نهلك قريه أمرنا مترفيها ففسقوا فيها فحق عليها القول فدمرناها تدميرا"
    },
    {
      "surah_number": 17,
      "verse_number": 17,
      "content": "وكم أهلكنا من القرون من بعد نوح وكفىا بربك بذنوب عباده خبيرا بصيرا"
    },
    {
      "surah_number": 17,
      "verse_number": 18,
      "content": "من كان يريد العاجله عجلنا له فيها ما نشا لمن نريد ثم جعلنا له جهنم يصلىاها مذموما مدحورا"
    },
    {
      "surah_number": 17,
      "verse_number": 19,
      "content": "ومن أراد الأخره وسعىا لها سعيها وهو مؤمن فأولائك كان سعيهم مشكورا"
    },
    {
      "surah_number": 17,
      "verse_number": 20,
      "content": "كلا نمد هاؤلا وهاؤلا من عطا ربك وما كان عطا ربك محظورا"
    },
    {
      "surah_number": 17,
      "verse_number": 21,
      "content": "انظر كيف فضلنا بعضهم علىا بعض وللأخره أكبر درجات وأكبر تفضيلا"
    },
    {
      "surah_number": 17,
      "verse_number": 22,
      "content": "لا تجعل مع الله الاها اخر فتقعد مذموما مخذولا"
    },
    {
      "surah_number": 17,
      "verse_number": 23,
      "content": "وقضىا ربك ألا تعبدوا الا اياه وبالوالدين احسانا اما يبلغن عندك الكبر أحدهما أو كلاهما فلا تقل لهما أف ولا تنهرهما وقل لهما قولا كريما"
    },
    {
      "surah_number": 17,
      "verse_number": 24,
      "content": "واخفض لهما جناح الذل من الرحمه وقل رب ارحمهما كما ربياني صغيرا"
    },
    {
      "surah_number": 17,
      "verse_number": 25,
      "content": "ربكم أعلم بما في نفوسكم ان تكونوا صالحين فانه كان للأوابين غفورا"
    },
    {
      "surah_number": 17,
      "verse_number": 26,
      "content": "وات ذا القربىا حقه والمسكين وابن السبيل ولا تبذر تبذيرا"
    },
    {
      "surah_number": 17,
      "verse_number": 27,
      "content": "ان المبذرين كانوا اخوان الشياطين وكان الشيطان لربه كفورا"
    },
    {
      "surah_number": 17,
      "verse_number": 28,
      "content": "واما تعرضن عنهم ابتغا رحمه من ربك ترجوها فقل لهم قولا ميسورا"
    },
    {
      "surah_number": 17,
      "verse_number": 29,
      "content": "ولا تجعل يدك مغلوله الىا عنقك ولا تبسطها كل البسط فتقعد ملوما محسورا"
    },
    {
      "surah_number": 17,
      "verse_number": 30,
      "content": "ان ربك يبسط الرزق لمن يشا ويقدر انه كان بعباده خبيرا بصيرا"
    },
    {
      "surah_number": 17,
      "verse_number": 31,
      "content": "ولا تقتلوا أولادكم خشيه املاق نحن نرزقهم واياكم ان قتلهم كان خطٔا كبيرا"
    },
    {
      "surah_number": 17,
      "verse_number": 32,
      "content": "ولا تقربوا الزنىا انه كان فاحشه وسا سبيلا"
    },
    {
      "surah_number": 17,
      "verse_number": 33,
      "content": "ولا تقتلوا النفس التي حرم الله الا بالحق ومن قتل مظلوما فقد جعلنا لوليه سلطانا فلا يسرف في القتل انه كان منصورا"
    },
    {
      "surah_number": 17,
      "verse_number": 34,
      "content": "ولا تقربوا مال اليتيم الا بالتي هي أحسن حتىا يبلغ أشده وأوفوا بالعهد ان العهد كان مسٔولا"
    },
    {
      "surah_number": 17,
      "verse_number": 35,
      "content": "وأوفوا الكيل اذا كلتم وزنوا بالقسطاس المستقيم ذالك خير وأحسن تأويلا"
    },
    {
      "surah_number": 17,
      "verse_number": 36,
      "content": "ولا تقف ما ليس لك به علم ان السمع والبصر والفؤاد كل أولائك كان عنه مسٔولا"
    },
    {
      "surah_number": 17,
      "verse_number": 37,
      "content": "ولا تمش في الأرض مرحا انك لن تخرق الأرض ولن تبلغ الجبال طولا"
    },
    {
      "surah_number": 17,
      "verse_number": 38,
      "content": "كل ذالك كان سيئه عند ربك مكروها"
    },
    {
      "surah_number": 17,
      "verse_number": 39,
      "content": "ذالك مما أوحىا اليك ربك من الحكمه ولا تجعل مع الله الاها اخر فتلقىا في جهنم ملوما مدحورا"
    },
    {
      "surah_number": 17,
      "verse_number": 40,
      "content": "أفأصفىاكم ربكم بالبنين واتخذ من الملائكه اناثا انكم لتقولون قولا عظيما"
    },
    {
      "surah_number": 17,
      "verse_number": 41,
      "content": "ولقد صرفنا في هاذا القران ليذكروا وما يزيدهم الا نفورا"
    },
    {
      "surah_number": 17,
      "verse_number": 42,
      "content": "قل لو كان معه الهه كما يقولون اذا لابتغوا الىا ذي العرش سبيلا"
    },
    {
      "surah_number": 17,
      "verse_number": 43,
      "content": "سبحانه وتعالىا عما يقولون علوا كبيرا"
    },
    {
      "surah_number": 17,
      "verse_number": 44,
      "content": "تسبح له السماوات السبع والأرض ومن فيهن وان من شي الا يسبح بحمده ولاكن لا تفقهون تسبيحهم انه كان حليما غفورا"
    },
    {
      "surah_number": 17,
      "verse_number": 45,
      "content": "واذا قرأت القران جعلنا بينك وبين الذين لا يؤمنون بالأخره حجابا مستورا"
    },
    {
      "surah_number": 17,
      "verse_number": 46,
      "content": "وجعلنا علىا قلوبهم أكنه أن يفقهوه وفي اذانهم وقرا واذا ذكرت ربك في القران وحده ولوا علىا أدبارهم نفورا"
    },
    {
      "surah_number": 17,
      "verse_number": 47,
      "content": "نحن أعلم بما يستمعون به اذ يستمعون اليك واذ هم نجوىا اذ يقول الظالمون ان تتبعون الا رجلا مسحورا"
    },
    {
      "surah_number": 17,
      "verse_number": 48,
      "content": "انظر كيف ضربوا لك الأمثال فضلوا فلا يستطيعون سبيلا"
    },
    {
      "surah_number": 17,
      "verse_number": 49,
      "content": "وقالوا أذا كنا عظاما ورفاتا أنا لمبعوثون خلقا جديدا"
    },
    {
      "surah_number": 17,
      "verse_number": 50,
      "content": "قل كونوا حجاره أو حديدا"
    },
    {
      "surah_number": 17,
      "verse_number": 51,
      "content": "أو خلقا مما يكبر في صدوركم فسيقولون من يعيدنا قل الذي فطركم أول مره فسينغضون اليك روسهم ويقولون متىا هو قل عسىا أن يكون قريبا"
    },
    {
      "surah_number": 17,
      "verse_number": 52,
      "content": "يوم يدعوكم فتستجيبون بحمده وتظنون ان لبثتم الا قليلا"
    },
    {
      "surah_number": 17,
      "verse_number": 53,
      "content": "وقل لعبادي يقولوا التي هي أحسن ان الشيطان ينزغ بينهم ان الشيطان كان للانسان عدوا مبينا"
    },
    {
      "surah_number": 17,
      "verse_number": 54,
      "content": "ربكم أعلم بكم ان يشأ يرحمكم أو ان يشأ يعذبكم وما أرسلناك عليهم وكيلا"
    },
    {
      "surah_number": 17,
      "verse_number": 55,
      "content": "وربك أعلم بمن في السماوات والأرض ولقد فضلنا بعض النبين علىا بعض واتينا داود زبورا"
    },
    {
      "surah_number": 17,
      "verse_number": 56,
      "content": "قل ادعوا الذين زعمتم من دونه فلا يملكون كشف الضر عنكم ولا تحويلا"
    },
    {
      "surah_number": 17,
      "verse_number": 57,
      "content": "أولائك الذين يدعون يبتغون الىا ربهم الوسيله أيهم أقرب ويرجون رحمته ويخافون عذابه ان عذاب ربك كان محذورا"
    },
    {
      "surah_number": 17,
      "verse_number": 58,
      "content": "وان من قريه الا نحن مهلكوها قبل يوم القيامه أو معذبوها عذابا شديدا كان ذالك في الكتاب مسطورا"
    },
    {
      "surah_number": 17,
      "verse_number": 59,
      "content": "وما منعنا أن نرسل بالأيات الا أن كذب بها الأولون واتينا ثمود الناقه مبصره فظلموا بها وما نرسل بالأيات الا تخويفا"
    },
    {
      "surah_number": 17,
      "verse_number": 60,
      "content": "واذ قلنا لك ان ربك أحاط بالناس وما جعلنا الريا التي أريناك الا فتنه للناس والشجره الملعونه في القران ونخوفهم فما يزيدهم الا طغيانا كبيرا"
    },
    {
      "surah_number": 17,
      "verse_number": 61,
      "content": "واذ قلنا للملائكه اسجدوا لأدم فسجدوا الا ابليس قال ءأسجد لمن خلقت طينا"
    },
    {
      "surah_number": 17,
      "verse_number": 62,
      "content": "قال أريتك هاذا الذي كرمت علي لئن أخرتن الىا يوم القيامه لأحتنكن ذريته الا قليلا"
    },
    {
      "surah_number": 17,
      "verse_number": 63,
      "content": "قال اذهب فمن تبعك منهم فان جهنم جزاؤكم جزا موفورا"
    },
    {
      "surah_number": 17,
      "verse_number": 64,
      "content": "واستفزز من استطعت منهم بصوتك وأجلب عليهم بخيلك ورجلك وشاركهم في الأموال والأولاد وعدهم وما يعدهم الشيطان الا غرورا"
    },
    {
      "surah_number": 17,
      "verse_number": 65,
      "content": "ان عبادي ليس لك عليهم سلطان وكفىا بربك وكيلا"
    },
    {
      "surah_number": 17,
      "verse_number": 66,
      "content": "ربكم الذي يزجي لكم الفلك في البحر لتبتغوا من فضله انه كان بكم رحيما"
    },
    {
      "surah_number": 17,
      "verse_number": 67,
      "content": "واذا مسكم الضر في البحر ضل من تدعون الا اياه فلما نجىاكم الى البر أعرضتم وكان الانسان كفورا"
    },
    {
      "surah_number": 17,
      "verse_number": 68,
      "content": "أفأمنتم أن يخسف بكم جانب البر أو يرسل عليكم حاصبا ثم لا تجدوا لكم وكيلا"
    },
    {
      "surah_number": 17,
      "verse_number": 69,
      "content": "أم أمنتم أن يعيدكم فيه تاره أخرىا فيرسل عليكم قاصفا من الريح فيغرقكم بما كفرتم ثم لا تجدوا لكم علينا به تبيعا"
    },
    {
      "surah_number": 17,
      "verse_number": 70,
      "content": "ولقد كرمنا بني ادم وحملناهم في البر والبحر ورزقناهم من الطيبات وفضلناهم علىا كثير ممن خلقنا تفضيلا"
    },
    {
      "surah_number": 17,
      "verse_number": 71,
      "content": "يوم ندعوا كل أناس بامامهم فمن أوتي كتابه بيمينه فأولائك يقرون كتابهم ولا يظلمون فتيلا"
    },
    {
      "surah_number": 17,
      "verse_number": 72,
      "content": "ومن كان في هاذه أعمىا فهو في الأخره أعمىا وأضل سبيلا"
    },
    {
      "surah_number": 17,
      "verse_number": 73,
      "content": "وان كادوا ليفتنونك عن الذي أوحينا اليك لتفتري علينا غيره واذا لاتخذوك خليلا"
    },
    {
      "surah_number": 17,
      "verse_number": 74,
      "content": "ولولا أن ثبتناك لقد كدت تركن اليهم شئا قليلا"
    },
    {
      "surah_number": 17,
      "verse_number": 75,
      "content": "اذا لأذقناك ضعف الحيواه وضعف الممات ثم لا تجد لك علينا نصيرا"
    },
    {
      "surah_number": 17,
      "verse_number": 76,
      "content": "وان كادوا ليستفزونك من الأرض ليخرجوك منها واذا لا يلبثون خلافك الا قليلا"
    },
    {
      "surah_number": 17,
      "verse_number": 77,
      "content": "سنه من قد أرسلنا قبلك من رسلنا ولا تجد لسنتنا تحويلا"
    },
    {
      "surah_number": 17,
      "verse_number": 78,
      "content": "أقم الصلواه لدلوك الشمس الىا غسق اليل وقران الفجر ان قران الفجر كان مشهودا"
    },
    {
      "surah_number": 17,
      "verse_number": 79,
      "content": "ومن اليل فتهجد به نافله لك عسىا أن يبعثك ربك مقاما محمودا"
    },
    {
      "surah_number": 17,
      "verse_number": 80,
      "content": "وقل رب أدخلني مدخل صدق وأخرجني مخرج صدق واجعل لي من لدنك سلطانا نصيرا"
    },
    {
      "surah_number": 17,
      "verse_number": 81,
      "content": "وقل جا الحق وزهق الباطل ان الباطل كان زهوقا"
    },
    {
      "surah_number": 17,
      "verse_number": 82,
      "content": "وننزل من القران ما هو شفا ورحمه للمؤمنين ولا يزيد الظالمين الا خسارا"
    },
    {
      "surah_number": 17,
      "verse_number": 83,
      "content": "واذا أنعمنا على الانسان أعرض ونٔا بجانبه واذا مسه الشر كان ئوسا"
    },
    {
      "surah_number": 17,
      "verse_number": 84,
      "content": "قل كل يعمل علىا شاكلته فربكم أعلم بمن هو أهدىا سبيلا"
    },
    {
      "surah_number": 17,
      "verse_number": 85,
      "content": "ويسٔلونك عن الروح قل الروح من أمر ربي وما أوتيتم من العلم الا قليلا"
    },
    {
      "surah_number": 17,
      "verse_number": 86,
      "content": "ولئن شئنا لنذهبن بالذي أوحينا اليك ثم لا تجد لك به علينا وكيلا"
    },
    {
      "surah_number": 17,
      "verse_number": 87,
      "content": "الا رحمه من ربك ان فضله كان عليك كبيرا"
    },
    {
      "surah_number": 17,
      "verse_number": 88,
      "content": "قل لئن اجتمعت الانس والجن علىا أن يأتوا بمثل هاذا القران لا يأتون بمثله ولو كان بعضهم لبعض ظهيرا"
    },
    {
      "surah_number": 17,
      "verse_number": 89,
      "content": "ولقد صرفنا للناس في هاذا القران من كل مثل فأبىا أكثر الناس الا كفورا"
    },
    {
      "surah_number": 17,
      "verse_number": 90,
      "content": "وقالوا لن نؤمن لك حتىا تفجر لنا من الأرض ينبوعا"
    },
    {
      "surah_number": 17,
      "verse_number": 91,
      "content": "أو تكون لك جنه من نخيل وعنب فتفجر الأنهار خلالها تفجيرا"
    },
    {
      "surah_number": 17,
      "verse_number": 92,
      "content": "أو تسقط السما كما زعمت علينا كسفا أو تأتي بالله والملائكه قبيلا"
    },
    {
      "surah_number": 17,
      "verse_number": 93,
      "content": "أو يكون لك بيت من زخرف أو ترقىا في السما ولن نؤمن لرقيك حتىا تنزل علينا كتابا نقرؤه قل سبحان ربي هل كنت الا بشرا رسولا"
    },
    {
      "surah_number": 17,
      "verse_number": 94,
      "content": "وما منع الناس أن يؤمنوا اذ جاهم الهدىا الا أن قالوا أبعث الله بشرا رسولا"
    },
    {
      "surah_number": 17,
      "verse_number": 95,
      "content": "قل لو كان في الأرض ملائكه يمشون مطمئنين لنزلنا عليهم من السما ملكا رسولا"
    },
    {
      "surah_number": 17,
      "verse_number": 96,
      "content": "قل كفىا بالله شهيدا بيني وبينكم انه كان بعباده خبيرا بصيرا"
    },
    {
      "surah_number": 17,
      "verse_number": 97,
      "content": "ومن يهد الله فهو المهتد ومن يضلل فلن تجد لهم أوليا من دونه ونحشرهم يوم القيامه علىا وجوههم عميا وبكما وصما مأوىاهم جهنم كلما خبت زدناهم سعيرا"
    },
    {
      "surah_number": 17,
      "verse_number": 98,
      "content": "ذالك جزاؤهم بأنهم كفروا بٔاياتنا وقالوا أذا كنا عظاما ورفاتا أنا لمبعوثون خلقا جديدا"
    },
    {
      "surah_number": 17,
      "verse_number": 99,
      "content": "أولم يروا أن الله الذي خلق السماوات والأرض قادر علىا أن يخلق مثلهم وجعل لهم أجلا لا ريب فيه فأبى الظالمون الا كفورا"
    },
    {
      "surah_number": 17,
      "verse_number": 100,
      "content": "قل لو أنتم تملكون خزائن رحمه ربي اذا لأمسكتم خشيه الانفاق وكان الانسان قتورا"
    },
    {
      "surah_number": 17,
      "verse_number": 101,
      "content": "ولقد اتينا موسىا تسع ايات بينات فسٔل بني اسرايل اذ جاهم فقال له فرعون اني لأظنك ياموسىا مسحورا"
    },
    {
      "surah_number": 17,
      "verse_number": 102,
      "content": "قال لقد علمت ما أنزل هاؤلا الا رب السماوات والأرض بصائر واني لأظنك يافرعون مثبورا"
    },
    {
      "surah_number": 17,
      "verse_number": 103,
      "content": "فأراد أن يستفزهم من الأرض فأغرقناه ومن معه جميعا"
    },
    {
      "surah_number": 17,
      "verse_number": 104,
      "content": "وقلنا من بعده لبني اسرايل اسكنوا الأرض فاذا جا وعد الأخره جئنا بكم لفيفا"
    },
    {
      "surah_number": 17,
      "verse_number": 105,
      "content": "وبالحق أنزلناه وبالحق نزل وما أرسلناك الا مبشرا ونذيرا"
    },
    {
      "surah_number": 17,
      "verse_number": 106,
      "content": "وقرانا فرقناه لتقرأه على الناس علىا مكث ونزلناه تنزيلا"
    },
    {
      "surah_number": 17,
      "verse_number": 107,
      "content": "قل امنوا به أو لا تؤمنوا ان الذين أوتوا العلم من قبله اذا يتلىا عليهم يخرون للأذقان سجدا"
    },
    {
      "surah_number": 17,
      "verse_number": 108,
      "content": "ويقولون سبحان ربنا ان كان وعد ربنا لمفعولا"
    },
    {
      "surah_number": 17,
      "verse_number": 109,
      "content": "ويخرون للأذقان يبكون ويزيدهم خشوعا"
    },
    {
      "surah_number": 17,
      "verse_number": 110,
      "content": "قل ادعوا الله أو ادعوا الرحمان أيا ما تدعوا فله الأسما الحسنىا ولا تجهر بصلاتك ولا تخافت بها وابتغ بين ذالك سبيلا"
    },
    {
      "surah_number": 17,
      "verse_number": 111,
      "content": "وقل الحمد لله الذي لم يتخذ ولدا ولم يكن له شريك في الملك ولم يكن له ولي من الذل وكبره تكبيرا"
    },
    {
      "surah_number": 18,
      "verse_number": 1,
      "content": "الحمد لله الذي أنزل علىا عبده الكتاب ولم يجعل له عوجا"
    },
    {
      "surah_number": 18,
      "verse_number": 2,
      "content": "قيما لينذر بأسا شديدا من لدنه ويبشر المؤمنين الذين يعملون الصالحات أن لهم أجرا حسنا"
    },
    {
      "surah_number": 18,
      "verse_number": 3,
      "content": "ماكثين فيه أبدا"
    },
    {
      "surah_number": 18,
      "verse_number": 4,
      "content": "وينذر الذين قالوا اتخذ الله ولدا"
    },
    {
      "surah_number": 18,
      "verse_number": 5,
      "content": "ما لهم به من علم ولا لأبائهم كبرت كلمه تخرج من أفواههم ان يقولون الا كذبا"
    },
    {
      "surah_number": 18,
      "verse_number": 6,
      "content": "فلعلك باخع نفسك علىا اثارهم ان لم يؤمنوا بهاذا الحديث أسفا"
    },
    {
      "surah_number": 18,
      "verse_number": 7,
      "content": "انا جعلنا ما على الأرض زينه لها لنبلوهم أيهم أحسن عملا"
    },
    {
      "surah_number": 18,
      "verse_number": 8,
      "content": "وانا لجاعلون ما عليها صعيدا جرزا"
    },
    {
      "surah_number": 18,
      "verse_number": 9,
      "content": "أم حسبت أن أصحاب الكهف والرقيم كانوا من اياتنا عجبا"
    },
    {
      "surah_number": 18,
      "verse_number": 10,
      "content": "اذ أوى الفتيه الى الكهف فقالوا ربنا اتنا من لدنك رحمه وهيئ لنا من أمرنا رشدا"
    },
    {
      "surah_number": 18,
      "verse_number": 11,
      "content": "فضربنا علىا اذانهم في الكهف سنين عددا"
    },
    {
      "surah_number": 18,
      "verse_number": 12,
      "content": "ثم بعثناهم لنعلم أي الحزبين أحصىا لما لبثوا أمدا"
    },
    {
      "surah_number": 18,
      "verse_number": 13,
      "content": "نحن نقص عليك نبأهم بالحق انهم فتيه امنوا بربهم وزدناهم هدى"
    },
    {
      "surah_number": 18,
      "verse_number": 14,
      "content": "وربطنا علىا قلوبهم اذ قاموا فقالوا ربنا رب السماوات والأرض لن ندعوا من دونه الاها لقد قلنا اذا شططا"
    },
    {
      "surah_number": 18,
      "verse_number": 15,
      "content": "هاؤلا قومنا اتخذوا من دونه الهه لولا يأتون عليهم بسلطان بين فمن أظلم ممن افترىا على الله كذبا"
    },
    {
      "surah_number": 18,
      "verse_number": 16,
      "content": "واذ اعتزلتموهم وما يعبدون الا الله فأوا الى الكهف ينشر لكم ربكم من رحمته ويهيئ لكم من أمركم مرفقا"
    },
    {
      "surah_number": 18,
      "verse_number": 17,
      "content": "وترى الشمس اذا طلعت تزاور عن كهفهم ذات اليمين واذا غربت تقرضهم ذات الشمال وهم في فجوه منه ذالك من ايات الله من يهد الله فهو المهتد ومن يضلل فلن تجد له وليا مرشدا"
    },
    {
      "surah_number": 18,
      "verse_number": 18,
      "content": "وتحسبهم أيقاظا وهم رقود ونقلبهم ذات اليمين وذات الشمال وكلبهم باسط ذراعيه بالوصيد لو اطلعت عليهم لوليت منهم فرارا ولملئت منهم رعبا"
    },
    {
      "surah_number": 18,
      "verse_number": 19,
      "content": "وكذالك بعثناهم ليتسالوا بينهم قال قائل منهم كم لبثتم قالوا لبثنا يوما أو بعض يوم قالوا ربكم أعلم بما لبثتم فابعثوا أحدكم بورقكم هاذه الى المدينه فلينظر أيها أزكىا طعاما فليأتكم برزق منه وليتلطف ولا يشعرن بكم أحدا"
    },
    {
      "surah_number": 18,
      "verse_number": 20,
      "content": "انهم ان يظهروا عليكم يرجموكم أو يعيدوكم في ملتهم ولن تفلحوا اذا أبدا"
    },
    {
      "surah_number": 18,
      "verse_number": 21,
      "content": "وكذالك أعثرنا عليهم ليعلموا أن وعد الله حق وأن الساعه لا ريب فيها اذ يتنازعون بينهم أمرهم فقالوا ابنوا عليهم بنيانا ربهم أعلم بهم قال الذين غلبوا علىا أمرهم لنتخذن عليهم مسجدا"
    },
    {
      "surah_number": 18,
      "verse_number": 22,
      "content": "سيقولون ثلاثه رابعهم كلبهم ويقولون خمسه سادسهم كلبهم رجما بالغيب ويقولون سبعه وثامنهم كلبهم قل ربي أعلم بعدتهم ما يعلمهم الا قليل فلا تمار فيهم الا مرا ظاهرا ولا تستفت فيهم منهم أحدا"
    },
    {
      "surah_number": 18,
      "verse_number": 23,
      "content": "ولا تقولن لشاي اني فاعل ذالك غدا"
    },
    {
      "surah_number": 18,
      "verse_number": 24,
      "content": "الا أن يشا الله واذكر ربك اذا نسيت وقل عسىا أن يهدين ربي لأقرب من هاذا رشدا"
    },
    {
      "surah_number": 18,
      "verse_number": 25,
      "content": "ولبثوا في كهفهم ثلاث مائه سنين وازدادوا تسعا"
    },
    {
      "surah_number": 18,
      "verse_number": 26,
      "content": "قل الله أعلم بما لبثوا له غيب السماوات والأرض أبصر به وأسمع ما لهم من دونه من ولي ولا يشرك في حكمه أحدا"
    },
    {
      "surah_number": 18,
      "verse_number": 27,
      "content": "واتل ما أوحي اليك من كتاب ربك لا مبدل لكلماته ولن تجد من دونه ملتحدا"
    },
    {
      "surah_number": 18,
      "verse_number": 28,
      "content": "واصبر نفسك مع الذين يدعون ربهم بالغدواه والعشي يريدون وجهه ولا تعد عيناك عنهم تريد زينه الحيواه الدنيا ولا تطع من أغفلنا قلبه عن ذكرنا واتبع هوىاه وكان أمره فرطا"
    },
    {
      "surah_number": 18,
      "verse_number": 29,
      "content": "وقل الحق من ربكم فمن شا فليؤمن ومن شا فليكفر انا أعتدنا للظالمين نارا أحاط بهم سرادقها وان يستغيثوا يغاثوا بما كالمهل يشوي الوجوه بئس الشراب وسات مرتفقا"
    },
    {
      "surah_number": 18,
      "verse_number": 30,
      "content": "ان الذين امنوا وعملوا الصالحات انا لا نضيع أجر من أحسن عملا"
    },
    {
      "surah_number": 18,
      "verse_number": 31,
      "content": "أولائك لهم جنات عدن تجري من تحتهم الأنهار يحلون فيها من أساور من ذهب ويلبسون ثيابا خضرا من سندس واستبرق متكٔين فيها على الأرائك نعم الثواب وحسنت مرتفقا"
    },
    {
      "surah_number": 18,
      "verse_number": 32,
      "content": "واضرب لهم مثلا رجلين جعلنا لأحدهما جنتين من أعناب وحففناهما بنخل وجعلنا بينهما زرعا"
    },
    {
      "surah_number": 18,
      "verse_number": 33,
      "content": "كلتا الجنتين اتت أكلها ولم تظلم منه شئا وفجرنا خلالهما نهرا"
    },
    {
      "surah_number": 18,
      "verse_number": 34,
      "content": "وكان له ثمر فقال لصاحبه وهو يحاوره أنا أكثر منك مالا وأعز نفرا"
    },
    {
      "surah_number": 18,
      "verse_number": 35,
      "content": "ودخل جنته وهو ظالم لنفسه قال ما أظن أن تبيد هاذه أبدا"
    },
    {
      "surah_number": 18,
      "verse_number": 36,
      "content": "وما أظن الساعه قائمه ولئن رددت الىا ربي لأجدن خيرا منها منقلبا"
    },
    {
      "surah_number": 18,
      "verse_number": 37,
      "content": "قال له صاحبه وهو يحاوره أكفرت بالذي خلقك من تراب ثم من نطفه ثم سوىاك رجلا"
    },
    {
      "surah_number": 18,
      "verse_number": 38,
      "content": "لاكنا هو الله ربي ولا أشرك بربي أحدا"
    },
    {
      "surah_number": 18,
      "verse_number": 39,
      "content": "ولولا اذ دخلت جنتك قلت ما شا الله لا قوه الا بالله ان ترن أنا أقل منك مالا وولدا"
    },
    {
      "surah_number": 18,
      "verse_number": 40,
      "content": "فعسىا ربي أن يؤتين خيرا من جنتك ويرسل عليها حسبانا من السما فتصبح صعيدا زلقا"
    },
    {
      "surah_number": 18,
      "verse_number": 41,
      "content": "أو يصبح ماؤها غورا فلن تستطيع له طلبا"
    },
    {
      "surah_number": 18,
      "verse_number": 42,
      "content": "وأحيط بثمره فأصبح يقلب كفيه علىا ما أنفق فيها وهي خاويه علىا عروشها ويقول ياليتني لم أشرك بربي أحدا"
    },
    {
      "surah_number": 18,
      "verse_number": 43,
      "content": "ولم تكن له فئه ينصرونه من دون الله وما كان منتصرا"
    },
    {
      "surah_number": 18,
      "verse_number": 44,
      "content": "هنالك الولايه لله الحق هو خير ثوابا وخير عقبا"
    },
    {
      "surah_number": 18,
      "verse_number": 45,
      "content": "واضرب لهم مثل الحيواه الدنيا كما أنزلناه من السما فاختلط به نبات الأرض فأصبح هشيما تذروه الرياح وكان الله علىا كل شي مقتدرا"
    },
    {
      "surah_number": 18,
      "verse_number": 46,
      "content": "المال والبنون زينه الحيواه الدنيا والباقيات الصالحات خير عند ربك ثوابا وخير أملا"
    },
    {
      "surah_number": 18,
      "verse_number": 47,
      "content": "ويوم نسير الجبال وترى الأرض بارزه وحشرناهم فلم نغادر منهم أحدا"
    },
    {
      "surah_number": 18,
      "verse_number": 48,
      "content": "وعرضوا علىا ربك صفا لقد جئتمونا كما خلقناكم أول مره بل زعمتم ألن نجعل لكم موعدا"
    },
    {
      "surah_number": 18,
      "verse_number": 49,
      "content": "ووضع الكتاب فترى المجرمين مشفقين مما فيه ويقولون ياويلتنا مال هاذا الكتاب لا يغادر صغيره ولا كبيره الا أحصىاها ووجدوا ما عملوا حاضرا ولا يظلم ربك أحدا"
    },
    {
      "surah_number": 18,
      "verse_number": 50,
      "content": "واذ قلنا للملائكه اسجدوا لأدم فسجدوا الا ابليس كان من الجن ففسق عن أمر ربه أفتتخذونه وذريته أوليا من دوني وهم لكم عدو بئس للظالمين بدلا"
    },
    {
      "surah_number": 18,
      "verse_number": 51,
      "content": "ما أشهدتهم خلق السماوات والأرض ولا خلق أنفسهم وما كنت متخذ المضلين عضدا"
    },
    {
      "surah_number": 18,
      "verse_number": 52,
      "content": "ويوم يقول نادوا شركاي الذين زعمتم فدعوهم فلم يستجيبوا لهم وجعلنا بينهم موبقا"
    },
    {
      "surah_number": 18,
      "verse_number": 53,
      "content": "ورا المجرمون النار فظنوا أنهم مواقعوها ولم يجدوا عنها مصرفا"
    },
    {
      "surah_number": 18,
      "verse_number": 54,
      "content": "ولقد صرفنا في هاذا القران للناس من كل مثل وكان الانسان أكثر شي جدلا"
    },
    {
      "surah_number": 18,
      "verse_number": 55,
      "content": "وما منع الناس أن يؤمنوا اذ جاهم الهدىا ويستغفروا ربهم الا أن تأتيهم سنه الأولين أو يأتيهم العذاب قبلا"
    },
    {
      "surah_number": 18,
      "verse_number": 56,
      "content": "وما نرسل المرسلين الا مبشرين ومنذرين ويجادل الذين كفروا بالباطل ليدحضوا به الحق واتخذوا اياتي وما أنذروا هزوا"
    },
    {
      "surah_number": 18,
      "verse_number": 57,
      "content": "ومن أظلم ممن ذكر بٔايات ربه فأعرض عنها ونسي ما قدمت يداه انا جعلنا علىا قلوبهم أكنه أن يفقهوه وفي اذانهم وقرا وان تدعهم الى الهدىا فلن يهتدوا اذا أبدا"
    },
    {
      "surah_number": 18,
      "verse_number": 58,
      "content": "وربك الغفور ذو الرحمه لو يؤاخذهم بما كسبوا لعجل لهم العذاب بل لهم موعد لن يجدوا من دونه موئلا"
    },
    {
      "surah_number": 18,
      "verse_number": 59,
      "content": "وتلك القرىا أهلكناهم لما ظلموا وجعلنا لمهلكهم موعدا"
    },
    {
      "surah_number": 18,
      "verse_number": 60,
      "content": "واذ قال موسىا لفتىاه لا أبرح حتىا أبلغ مجمع البحرين أو أمضي حقبا"
    },
    {
      "surah_number": 18,
      "verse_number": 61,
      "content": "فلما بلغا مجمع بينهما نسيا حوتهما فاتخذ سبيله في البحر سربا"
    },
    {
      "surah_number": 18,
      "verse_number": 62,
      "content": "فلما جاوزا قال لفتىاه اتنا غدانا لقد لقينا من سفرنا هاذا نصبا"
    },
    {
      "surah_number": 18,
      "verse_number": 63,
      "content": "قال أريت اذ أوينا الى الصخره فاني نسيت الحوت وما أنسىانيه الا الشيطان أن أذكره واتخذ سبيله في البحر عجبا"
    },
    {
      "surah_number": 18,
      "verse_number": 64,
      "content": "قال ذالك ما كنا نبغ فارتدا علىا اثارهما قصصا"
    },
    {
      "surah_number": 18,
      "verse_number": 65,
      "content": "فوجدا عبدا من عبادنا اتيناه رحمه من عندنا وعلمناه من لدنا علما"
    },
    {
      "surah_number": 18,
      "verse_number": 66,
      "content": "قال له موسىا هل أتبعك علىا أن تعلمن مما علمت رشدا"
    },
    {
      "surah_number": 18,
      "verse_number": 67,
      "content": "قال انك لن تستطيع معي صبرا"
    },
    {
      "surah_number": 18,
      "verse_number": 68,
      "content": "وكيف تصبر علىا ما لم تحط به خبرا"
    },
    {
      "surah_number": 18,
      "verse_number": 69,
      "content": "قال ستجدني ان شا الله صابرا ولا أعصي لك أمرا"
    },
    {
      "surah_number": 18,
      "verse_number": 70,
      "content": "قال فان اتبعتني فلا تسٔلني عن شي حتىا أحدث لك منه ذكرا"
    },
    {
      "surah_number": 18,
      "verse_number": 71,
      "content": "فانطلقا حتىا اذا ركبا في السفينه خرقها قال أخرقتها لتغرق أهلها لقد جئت شئا امرا"
    },
    {
      "surah_number": 18,
      "verse_number": 72,
      "content": "قال ألم أقل انك لن تستطيع معي صبرا"
    },
    {
      "surah_number": 18,
      "verse_number": 73,
      "content": "قال لا تؤاخذني بما نسيت ولا ترهقني من أمري عسرا"
    },
    {
      "surah_number": 18,
      "verse_number": 74,
      "content": "فانطلقا حتىا اذا لقيا غلاما فقتله قال أقتلت نفسا زكيه بغير نفس لقد جئت شئا نكرا"
    },
    {
      "surah_number": 18,
      "verse_number": 75,
      "content": "قال ألم أقل لك انك لن تستطيع معي صبرا"
    },
    {
      "surah_number": 18,
      "verse_number": 76,
      "content": "قال ان سألتك عن شي بعدها فلا تصاحبني قد بلغت من لدني عذرا"
    },
    {
      "surah_number": 18,
      "verse_number": 77,
      "content": "فانطلقا حتىا اذا أتيا أهل قريه استطعما أهلها فأبوا أن يضيفوهما فوجدا فيها جدارا يريد أن ينقض فأقامه قال لو شئت لتخذت عليه أجرا"
    },
    {
      "surah_number": 18,
      "verse_number": 78,
      "content": "قال هاذا فراق بيني وبينك سأنبئك بتأويل ما لم تستطع عليه صبرا"
    },
    {
      "surah_number": 18,
      "verse_number": 79,
      "content": "أما السفينه فكانت لمساكين يعملون في البحر فأردت أن أعيبها وكان وراهم ملك يأخذ كل سفينه غصبا"
    },
    {
      "surah_number": 18,
      "verse_number": 80,
      "content": "وأما الغلام فكان أبواه مؤمنين فخشينا أن يرهقهما طغيانا وكفرا"
    },
    {
      "surah_number": 18,
      "verse_number": 81,
      "content": "فأردنا أن يبدلهما ربهما خيرا منه زكواه وأقرب رحما"
    },
    {
      "surah_number": 18,
      "verse_number": 82,
      "content": "وأما الجدار فكان لغلامين يتيمين في المدينه وكان تحته كنز لهما وكان أبوهما صالحا فأراد ربك أن يبلغا أشدهما ويستخرجا كنزهما رحمه من ربك وما فعلته عن أمري ذالك تأويل ما لم تسطع عليه صبرا"
    },
    {
      "surah_number": 18,
      "verse_number": 83,
      "content": "ويسٔلونك عن ذي القرنين قل سأتلوا عليكم منه ذكرا"
    },
    {
      "surah_number": 18,
      "verse_number": 84,
      "content": "انا مكنا له في الأرض واتيناه من كل شي سببا"
    },
    {
      "surah_number": 18,
      "verse_number": 85,
      "content": "فأتبع سببا"
    },
    {
      "surah_number": 18,
      "verse_number": 86,
      "content": "حتىا اذا بلغ مغرب الشمس وجدها تغرب في عين حمئه ووجد عندها قوما قلنا ياذا القرنين اما أن تعذب واما أن تتخذ فيهم حسنا"
    },
    {
      "surah_number": 18,
      "verse_number": 87,
      "content": "قال أما من ظلم فسوف نعذبه ثم يرد الىا ربه فيعذبه عذابا نكرا"
    },
    {
      "surah_number": 18,
      "verse_number": 88,
      "content": "وأما من امن وعمل صالحا فله جزا الحسنىا وسنقول له من أمرنا يسرا"
    },
    {
      "surah_number": 18,
      "verse_number": 89,
      "content": "ثم أتبع سببا"
    },
    {
      "surah_number": 18,
      "verse_number": 90,
      "content": "حتىا اذا بلغ مطلع الشمس وجدها تطلع علىا قوم لم نجعل لهم من دونها سترا"
    },
    {
      "surah_number": 18,
      "verse_number": 91,
      "content": "كذالك وقد أحطنا بما لديه خبرا"
    },
    {
      "surah_number": 18,
      "verse_number": 92,
      "content": "ثم أتبع سببا"
    },
    {
      "surah_number": 18,
      "verse_number": 93,
      "content": "حتىا اذا بلغ بين السدين وجد من دونهما قوما لا يكادون يفقهون قولا"
    },
    {
      "surah_number": 18,
      "verse_number": 94,
      "content": "قالوا ياذا القرنين ان يأجوج ومأجوج مفسدون في الأرض فهل نجعل لك خرجا علىا أن تجعل بيننا وبينهم سدا"
    },
    {
      "surah_number": 18,
      "verse_number": 95,
      "content": "قال ما مكني فيه ربي خير فأعينوني بقوه أجعل بينكم وبينهم ردما"
    },
    {
      "surah_number": 18,
      "verse_number": 96,
      "content": "اتوني زبر الحديد حتىا اذا ساوىا بين الصدفين قال انفخوا حتىا اذا جعله نارا قال اتوني أفرغ عليه قطرا"
    },
    {
      "surah_number": 18,
      "verse_number": 97,
      "content": "فما اسطاعوا أن يظهروه وما استطاعوا له نقبا"
    },
    {
      "surah_number": 18,
      "verse_number": 98,
      "content": "قال هاذا رحمه من ربي فاذا جا وعد ربي جعله دكا وكان وعد ربي حقا"
    },
    {
      "surah_number": 18,
      "verse_number": 99,
      "content": "وتركنا بعضهم يومئذ يموج في بعض ونفخ في الصور فجمعناهم جمعا"
    },
    {
      "surah_number": 18,
      "verse_number": 100,
      "content": "وعرضنا جهنم يومئذ للكافرين عرضا"
    },
    {
      "surah_number": 18,
      "verse_number": 101,
      "content": "الذين كانت أعينهم في غطا عن ذكري وكانوا لا يستطيعون سمعا"
    },
    {
      "surah_number": 18,
      "verse_number": 102,
      "content": "أفحسب الذين كفروا أن يتخذوا عبادي من دوني أوليا انا أعتدنا جهنم للكافرين نزلا"
    },
    {
      "surah_number": 18,
      "verse_number": 103,
      "content": "قل هل ننبئكم بالأخسرين أعمالا"
    },
    {
      "surah_number": 18,
      "verse_number": 104,
      "content": "الذين ضل سعيهم في الحيواه الدنيا وهم يحسبون أنهم يحسنون صنعا"
    },
    {
      "surah_number": 18,
      "verse_number": 105,
      "content": "أولائك الذين كفروا بٔايات ربهم ولقائه فحبطت أعمالهم فلا نقيم لهم يوم القيامه وزنا"
    },
    {
      "surah_number": 18,
      "verse_number": 106,
      "content": "ذالك جزاؤهم جهنم بما كفروا واتخذوا اياتي ورسلي هزوا"
    },
    {
      "surah_number": 18,
      "verse_number": 107,
      "content": "ان الذين امنوا وعملوا الصالحات كانت لهم جنات الفردوس نزلا"
    },
    {
      "surah_number": 18,
      "verse_number": 108,
      "content": "خالدين فيها لا يبغون عنها حولا"
    },
    {
      "surah_number": 18,
      "verse_number": 109,
      "content": "قل لو كان البحر مدادا لكلمات ربي لنفد البحر قبل أن تنفد كلمات ربي ولو جئنا بمثله مددا"
    },
    {
      "surah_number": 18,
      "verse_number": 110,
      "content": "قل انما أنا بشر مثلكم يوحىا الي أنما الاهكم الاه واحد فمن كان يرجوا لقا ربه فليعمل عملا صالحا ولا يشرك بعباده ربه أحدا"
    },
    {
      "surah_number": 19,
      "verse_number": 1,
      "content": "كهيعص"
    },
    {
      "surah_number": 19,
      "verse_number": 2,
      "content": "ذكر رحمت ربك عبده زكريا"
    },
    {
      "surah_number": 19,
      "verse_number": 3,
      "content": "اذ نادىا ربه ندا خفيا"
    },
    {
      "surah_number": 19,
      "verse_number": 4,
      "content": "قال رب اني وهن العظم مني واشتعل الرأس شيبا ولم أكن بدعائك رب شقيا"
    },
    {
      "surah_number": 19,
      "verse_number": 5,
      "content": "واني خفت الموالي من وراي وكانت امرأتي عاقرا فهب لي من لدنك وليا"
    },
    {
      "surah_number": 19,
      "verse_number": 6,
      "content": "يرثني ويرث من ال يعقوب واجعله رب رضيا"
    },
    {
      "surah_number": 19,
      "verse_number": 7,
      "content": "يازكريا انا نبشرك بغلام اسمه يحيىا لم نجعل له من قبل سميا"
    },
    {
      "surah_number": 19,
      "verse_number": 8,
      "content": "قال رب أنىا يكون لي غلام وكانت امرأتي عاقرا وقد بلغت من الكبر عتيا"
    },
    {
      "surah_number": 19,
      "verse_number": 9,
      "content": "قال كذالك قال ربك هو علي هين وقد خلقتك من قبل ولم تك شئا"
    },
    {
      "surah_number": 19,
      "verse_number": 10,
      "content": "قال رب اجعل لي ايه قال ايتك ألا تكلم الناس ثلاث ليال سويا"
    },
    {
      "surah_number": 19,
      "verse_number": 11,
      "content": "فخرج علىا قومه من المحراب فأوحىا اليهم أن سبحوا بكره وعشيا"
    },
    {
      "surah_number": 19,
      "verse_number": 12,
      "content": "يايحيىا خذ الكتاب بقوه واتيناه الحكم صبيا"
    },
    {
      "surah_number": 19,
      "verse_number": 13,
      "content": "وحنانا من لدنا وزكواه وكان تقيا"
    },
    {
      "surah_number": 19,
      "verse_number": 14,
      "content": "وبرا بوالديه ولم يكن جبارا عصيا"
    },
    {
      "surah_number": 19,
      "verse_number": 15,
      "content": "وسلام عليه يوم ولد ويوم يموت ويوم يبعث حيا"
    },
    {
      "surah_number": 19,
      "verse_number": 16,
      "content": "واذكر في الكتاب مريم اذ انتبذت من أهلها مكانا شرقيا"
    },
    {
      "surah_number": 19,
      "verse_number": 17,
      "content": "فاتخذت من دونهم حجابا فأرسلنا اليها روحنا فتمثل لها بشرا سويا"
    },
    {
      "surah_number": 19,
      "verse_number": 18,
      "content": "قالت اني أعوذ بالرحمان منك ان كنت تقيا"
    },
    {
      "surah_number": 19,
      "verse_number": 19,
      "content": "قال انما أنا رسول ربك لأهب لك غلاما زكيا"
    },
    {
      "surah_number": 19,
      "verse_number": 20,
      "content": "قالت أنىا يكون لي غلام ولم يمسسني بشر ولم أك بغيا"
    },
    {
      "surah_number": 19,
      "verse_number": 21,
      "content": "قال كذالك قال ربك هو علي هين ولنجعله ايه للناس ورحمه منا وكان أمرا مقضيا"
    },
    {
      "surah_number": 19,
      "verse_number": 22,
      "content": "فحملته فانتبذت به مكانا قصيا"
    },
    {
      "surah_number": 19,
      "verse_number": 23,
      "content": "فأجاها المخاض الىا جذع النخله قالت ياليتني مت قبل هاذا وكنت نسيا منسيا"
    },
    {
      "surah_number": 19,
      "verse_number": 24,
      "content": "فنادىاها من تحتها ألا تحزني قد جعل ربك تحتك سريا"
    },
    {
      "surah_number": 19,
      "verse_number": 25,
      "content": "وهزي اليك بجذع النخله تساقط عليك رطبا جنيا"
    },
    {
      "surah_number": 19,
      "verse_number": 26,
      "content": "فكلي واشربي وقري عينا فاما ترين من البشر أحدا فقولي اني نذرت للرحمان صوما فلن أكلم اليوم انسيا"
    },
    {
      "surah_number": 19,
      "verse_number": 27,
      "content": "فأتت به قومها تحمله قالوا يامريم لقد جئت شئا فريا"
    },
    {
      "surah_number": 19,
      "verse_number": 28,
      "content": "ياأخت هارون ما كان أبوك امرأ سو وما كانت أمك بغيا"
    },
    {
      "surah_number": 19,
      "verse_number": 29,
      "content": "فأشارت اليه قالوا كيف نكلم من كان في المهد صبيا"
    },
    {
      "surah_number": 19,
      "verse_number": 30,
      "content": "قال اني عبد الله اتىاني الكتاب وجعلني نبيا"
    },
    {
      "surah_number": 19,
      "verse_number": 31,
      "content": "وجعلني مباركا أين ما كنت وأوصاني بالصلواه والزكواه ما دمت حيا"
    },
    {
      "surah_number": 19,
      "verse_number": 32,
      "content": "وبرا بوالدتي ولم يجعلني جبارا شقيا"
    },
    {
      "surah_number": 19,
      "verse_number": 33,
      "content": "والسلام علي يوم ولدت ويوم أموت ويوم أبعث حيا"
    },
    {
      "surah_number": 19,
      "verse_number": 34,
      "content": "ذالك عيسى ابن مريم قول الحق الذي فيه يمترون"
    },
    {
      "surah_number": 19,
      "verse_number": 35,
      "content": "ما كان لله أن يتخذ من ولد سبحانه اذا قضىا أمرا فانما يقول له كن فيكون"
    },
    {
      "surah_number": 19,
      "verse_number": 36,
      "content": "وان الله ربي وربكم فاعبدوه هاذا صراط مستقيم"
    },
    {
      "surah_number": 19,
      "verse_number": 37,
      "content": "فاختلف الأحزاب من بينهم فويل للذين كفروا من مشهد يوم عظيم"
    },
    {
      "surah_number": 19,
      "verse_number": 38,
      "content": "أسمع بهم وأبصر يوم يأتوننا لاكن الظالمون اليوم في ضلال مبين"
    },
    {
      "surah_number": 19,
      "verse_number": 39,
      "content": "وأنذرهم يوم الحسره اذ قضي الأمر وهم في غفله وهم لا يؤمنون"
    },
    {
      "surah_number": 19,
      "verse_number": 40,
      "content": "انا نحن نرث الأرض ومن عليها والينا يرجعون"
    },
    {
      "surah_number": 19,
      "verse_number": 41,
      "content": "واذكر في الكتاب ابراهيم انه كان صديقا نبيا"
    },
    {
      "surah_number": 19,
      "verse_number": 42,
      "content": "اذ قال لأبيه ياأبت لم تعبد ما لا يسمع ولا يبصر ولا يغني عنك شئا"
    },
    {
      "surah_number": 19,
      "verse_number": 43,
      "content": "ياأبت اني قد جاني من العلم ما لم يأتك فاتبعني أهدك صراطا سويا"
    },
    {
      "surah_number": 19,
      "verse_number": 44,
      "content": "ياأبت لا تعبد الشيطان ان الشيطان كان للرحمان عصيا"
    },
    {
      "surah_number": 19,
      "verse_number": 45,
      "content": "ياأبت اني أخاف أن يمسك عذاب من الرحمان فتكون للشيطان وليا"
    },
    {
      "surah_number": 19,
      "verse_number": 46,
      "content": "قال أراغب أنت عن الهتي ياابراهيم لئن لم تنته لأرجمنك واهجرني مليا"
    },
    {
      "surah_number": 19,
      "verse_number": 47,
      "content": "قال سلام عليك سأستغفر لك ربي انه كان بي حفيا"
    },
    {
      "surah_number": 19,
      "verse_number": 48,
      "content": "وأعتزلكم وما تدعون من دون الله وأدعوا ربي عسىا ألا أكون بدعا ربي شقيا"
    },
    {
      "surah_number": 19,
      "verse_number": 49,
      "content": "فلما اعتزلهم وما يعبدون من دون الله وهبنا له اسحاق ويعقوب وكلا جعلنا نبيا"
    },
    {
      "surah_number": 19,
      "verse_number": 50,
      "content": "ووهبنا لهم من رحمتنا وجعلنا لهم لسان صدق عليا"
    },
    {
      "surah_number": 19,
      "verse_number": 51,
      "content": "واذكر في الكتاب موسىا انه كان مخلصا وكان رسولا نبيا"
    },
    {
      "surah_number": 19,
      "verse_number": 52,
      "content": "وناديناه من جانب الطور الأيمن وقربناه نجيا"
    },
    {
      "surah_number": 19,
      "verse_number": 53,
      "content": "ووهبنا له من رحمتنا أخاه هارون نبيا"
    },
    {
      "surah_number": 19,
      "verse_number": 54,
      "content": "واذكر في الكتاب اسماعيل انه كان صادق الوعد وكان رسولا نبيا"
    },
    {
      "surah_number": 19,
      "verse_number": 55,
      "content": "وكان يأمر أهله بالصلواه والزكواه وكان عند ربه مرضيا"
    },
    {
      "surah_number": 19,
      "verse_number": 56,
      "content": "واذكر في الكتاب ادريس انه كان صديقا نبيا"
    },
    {
      "surah_number": 19,
      "verse_number": 57,
      "content": "ورفعناه مكانا عليا"
    },
    {
      "surah_number": 19,
      "verse_number": 58,
      "content": "أولائك الذين أنعم الله عليهم من النبين من ذريه ادم وممن حملنا مع نوح ومن ذريه ابراهيم واسرايل وممن هدينا واجتبينا اذا تتلىا عليهم ايات الرحمان خروا سجدا وبكيا"
    },
    {
      "surah_number": 19,
      "verse_number": 59,
      "content": "فخلف من بعدهم خلف أضاعوا الصلواه واتبعوا الشهوات فسوف يلقون غيا"
    },
    {
      "surah_number": 19,
      "verse_number": 60,
      "content": "الا من تاب وامن وعمل صالحا فأولائك يدخلون الجنه ولا يظلمون شئا"
    },
    {
      "surah_number": 19,
      "verse_number": 61,
      "content": "جنات عدن التي وعد الرحمان عباده بالغيب انه كان وعده مأتيا"
    },
    {
      "surah_number": 19,
      "verse_number": 62,
      "content": "لا يسمعون فيها لغوا الا سلاما ولهم رزقهم فيها بكره وعشيا"
    },
    {
      "surah_number": 19,
      "verse_number": 63,
      "content": "تلك الجنه التي نورث من عبادنا من كان تقيا"
    },
    {
      "surah_number": 19,
      "verse_number": 64,
      "content": "وما نتنزل الا بأمر ربك له ما بين أيدينا وما خلفنا وما بين ذالك وما كان ربك نسيا"
    },
    {
      "surah_number": 19,
      "verse_number": 65,
      "content": "رب السماوات والأرض وما بينهما فاعبده واصطبر لعبادته هل تعلم له سميا"
    },
    {
      "surah_number": 19,
      "verse_number": 66,
      "content": "ويقول الانسان أذا ما مت لسوف أخرج حيا"
    },
    {
      "surah_number": 19,
      "verse_number": 67,
      "content": "أولا يذكر الانسان أنا خلقناه من قبل ولم يك شئا"
    },
    {
      "surah_number": 19,
      "verse_number": 68,
      "content": "فوربك لنحشرنهم والشياطين ثم لنحضرنهم حول جهنم جثيا"
    },
    {
      "surah_number": 19,
      "verse_number": 69,
      "content": "ثم لننزعن من كل شيعه أيهم أشد على الرحمان عتيا"
    },
    {
      "surah_number": 19,
      "verse_number": 70,
      "content": "ثم لنحن أعلم بالذين هم أولىا بها صليا"
    },
    {
      "surah_number": 19,
      "verse_number": 71,
      "content": "وان منكم الا واردها كان علىا ربك حتما مقضيا"
    },
    {
      "surah_number": 19,
      "verse_number": 72,
      "content": "ثم ننجي الذين اتقوا ونذر الظالمين فيها جثيا"
    },
    {
      "surah_number": 19,
      "verse_number": 73,
      "content": "واذا تتلىا عليهم اياتنا بينات قال الذين كفروا للذين امنوا أي الفريقين خير مقاما وأحسن نديا"
    },
    {
      "surah_number": 19,
      "verse_number": 74,
      "content": "وكم أهلكنا قبلهم من قرن هم أحسن أثاثا وريا"
    },
    {
      "surah_number": 19,
      "verse_number": 75,
      "content": "قل من كان في الضلاله فليمدد له الرحمان مدا حتىا اذا رأوا ما يوعدون اما العذاب واما الساعه فسيعلمون من هو شر مكانا وأضعف جندا"
    },
    {
      "surah_number": 19,
      "verse_number": 76,
      "content": "ويزيد الله الذين اهتدوا هدى والباقيات الصالحات خير عند ربك ثوابا وخير مردا"
    },
    {
      "surah_number": 19,
      "verse_number": 77,
      "content": "أفريت الذي كفر بٔاياتنا وقال لأوتين مالا وولدا"
    },
    {
      "surah_number": 19,
      "verse_number": 78,
      "content": "أطلع الغيب أم اتخذ عند الرحمان عهدا"
    },
    {
      "surah_number": 19,
      "verse_number": 79,
      "content": "كلا سنكتب ما يقول ونمد له من العذاب مدا"
    },
    {
      "surah_number": 19,
      "verse_number": 80,
      "content": "ونرثه ما يقول ويأتينا فردا"
    },
    {
      "surah_number": 19,
      "verse_number": 81,
      "content": "واتخذوا من دون الله الهه ليكونوا لهم عزا"
    },
    {
      "surah_number": 19,
      "verse_number": 82,
      "content": "كلا سيكفرون بعبادتهم ويكونون عليهم ضدا"
    },
    {
      "surah_number": 19,
      "verse_number": 83,
      "content": "ألم تر أنا أرسلنا الشياطين على الكافرين تؤزهم أزا"
    },
    {
      "surah_number": 19,
      "verse_number": 84,
      "content": "فلا تعجل عليهم انما نعد لهم عدا"
    },
    {
      "surah_number": 19,
      "verse_number": 85,
      "content": "يوم نحشر المتقين الى الرحمان وفدا"
    },
    {
      "surah_number": 19,
      "verse_number": 86,
      "content": "ونسوق المجرمين الىا جهنم وردا"
    },
    {
      "surah_number": 19,
      "verse_number": 87,
      "content": "لا يملكون الشفاعه الا من اتخذ عند الرحمان عهدا"
    },
    {
      "surah_number": 19,
      "verse_number": 88,
      "content": "وقالوا اتخذ الرحمان ولدا"
    },
    {
      "surah_number": 19,
      "verse_number": 89,
      "content": "لقد جئتم شئا ادا"
    },
    {
      "surah_number": 19,
      "verse_number": 90,
      "content": "تكاد السماوات يتفطرن منه وتنشق الأرض وتخر الجبال هدا"
    },
    {
      "surah_number": 19,
      "verse_number": 91,
      "content": "أن دعوا للرحمان ولدا"
    },
    {
      "surah_number": 19,
      "verse_number": 92,
      "content": "وما ينبغي للرحمان أن يتخذ ولدا"
    },
    {
      "surah_number": 19,
      "verse_number": 93,
      "content": "ان كل من في السماوات والأرض الا اتي الرحمان عبدا"
    },
    {
      "surah_number": 19,
      "verse_number": 94,
      "content": "لقد أحصىاهم وعدهم عدا"
    },
    {
      "surah_number": 19,
      "verse_number": 95,
      "content": "وكلهم اتيه يوم القيامه فردا"
    },
    {
      "surah_number": 19,
      "verse_number": 96,
      "content": "ان الذين امنوا وعملوا الصالحات سيجعل لهم الرحمان ودا"
    },
    {
      "surah_number": 19,
      "verse_number": 97,
      "content": "فانما يسرناه بلسانك لتبشر به المتقين وتنذر به قوما لدا"
    },
    {
      "surah_number": 19,
      "verse_number": 98,
      "content": "وكم أهلكنا قبلهم من قرن هل تحس منهم من أحد أو تسمع لهم ركزا"
    },
    {
      "surah_number": 20,
      "verse_number": 1,
      "content": "طه"
    },
    {
      "surah_number": 20,
      "verse_number": 2,
      "content": "ما أنزلنا عليك القران لتشقىا"
    },
    {
      "surah_number": 20,
      "verse_number": 3,
      "content": "الا تذكره لمن يخشىا"
    },
    {
      "surah_number": 20,
      "verse_number": 4,
      "content": "تنزيلا ممن خلق الأرض والسماوات العلى"
    },
    {
      "surah_number": 20,
      "verse_number": 5,
      "content": "الرحمان على العرش استوىا"
    },
    {
      "surah_number": 20,
      "verse_number": 6,
      "content": "له ما في السماوات وما في الأرض وما بينهما وما تحت الثرىا"
    },
    {
      "surah_number": 20,
      "verse_number": 7,
      "content": "وان تجهر بالقول فانه يعلم السر وأخفى"
    },
    {
      "surah_number": 20,
      "verse_number": 8,
      "content": "الله لا الاه الا هو له الأسما الحسنىا"
    },
    {
      "surah_number": 20,
      "verse_number": 9,
      "content": "وهل أتىاك حديث موسىا"
    },
    {
      "surah_number": 20,
      "verse_number": 10,
      "content": "اذ را نارا فقال لأهله امكثوا اني انست نارا لعلي اتيكم منها بقبس أو أجد على النار هدى"
    },
    {
      "surah_number": 20,
      "verse_number": 11,
      "content": "فلما أتىاها نودي ياموسىا"
    },
    {
      "surah_number": 20,
      "verse_number": 12,
      "content": "اني أنا ربك فاخلع نعليك انك بالواد المقدس طوى"
    },
    {
      "surah_number": 20,
      "verse_number": 13,
      "content": "وأنا اخترتك فاستمع لما يوحىا"
    },
    {
      "surah_number": 20,
      "verse_number": 14,
      "content": "انني أنا الله لا الاه الا أنا فاعبدني وأقم الصلواه لذكري"
    },
    {
      "surah_number": 20,
      "verse_number": 15,
      "content": "ان الساعه اتيه أكاد أخفيها لتجزىا كل نفس بما تسعىا"
    },
    {
      "surah_number": 20,
      "verse_number": 16,
      "content": "فلا يصدنك عنها من لا يؤمن بها واتبع هوىاه فتردىا"
    },
    {
      "surah_number": 20,
      "verse_number": 17,
      "content": "وما تلك بيمينك ياموسىا"
    },
    {
      "surah_number": 20,
      "verse_number": 18,
      "content": "قال هي عصاي أتوكؤا عليها وأهش بها علىا غنمي ولي فيها مٔارب أخرىا"
    },
    {
      "surah_number": 20,
      "verse_number": 19,
      "content": "قال ألقها ياموسىا"
    },
    {
      "surah_number": 20,
      "verse_number": 20,
      "content": "فألقىاها فاذا هي حيه تسعىا"
    },
    {
      "surah_number": 20,
      "verse_number": 21,
      "content": "قال خذها ولا تخف سنعيدها سيرتها الأولىا"
    },
    {
      "surah_number": 20,
      "verse_number": 22,
      "content": "واضمم يدك الىا جناحك تخرج بيضا من غير سو ايه أخرىا"
    },
    {
      "surah_number": 20,
      "verse_number": 23,
      "content": "لنريك من اياتنا الكبرى"
    },
    {
      "surah_number": 20,
      "verse_number": 24,
      "content": "اذهب الىا فرعون انه طغىا"
    },
    {
      "surah_number": 20,
      "verse_number": 25,
      "content": "قال رب اشرح لي صدري"
    },
    {
      "surah_number": 20,
      "verse_number": 26,
      "content": "ويسر لي أمري"
    },
    {
      "surah_number": 20,
      "verse_number": 27,
      "content": "واحلل عقده من لساني"
    },
    {
      "surah_number": 20,
      "verse_number": 28,
      "content": "يفقهوا قولي"
    },
    {
      "surah_number": 20,
      "verse_number": 29,
      "content": "واجعل لي وزيرا من أهلي"
    },
    {
      "surah_number": 20,
      "verse_number": 30,
      "content": "هارون أخي"
    },
    {
      "surah_number": 20,
      "verse_number": 31,
      "content": "اشدد به أزري"
    },
    {
      "surah_number": 20,
      "verse_number": 32,
      "content": "وأشركه في أمري"
    },
    {
      "surah_number": 20,
      "verse_number": 33,
      "content": "كي نسبحك كثيرا"
    },
    {
      "surah_number": 20,
      "verse_number": 34,
      "content": "ونذكرك كثيرا"
    },
    {
      "surah_number": 20,
      "verse_number": 35,
      "content": "انك كنت بنا بصيرا"
    },
    {
      "surah_number": 20,
      "verse_number": 36,
      "content": "قال قد أوتيت سؤلك ياموسىا"
    },
    {
      "surah_number": 20,
      "verse_number": 37,
      "content": "ولقد مننا عليك مره أخرىا"
    },
    {
      "surah_number": 20,
      "verse_number": 38,
      "content": "اذ أوحينا الىا أمك ما يوحىا"
    },
    {
      "surah_number": 20,
      "verse_number": 39,
      "content": "أن اقذفيه في التابوت فاقذفيه في اليم فليلقه اليم بالساحل يأخذه عدو لي وعدو له وألقيت عليك محبه مني ولتصنع علىا عيني"
    },
    {
      "surah_number": 20,
      "verse_number": 40,
      "content": "اذ تمشي أختك فتقول هل أدلكم علىا من يكفله فرجعناك الىا أمك كي تقر عينها ولا تحزن وقتلت نفسا فنجيناك من الغم وفتناك فتونا فلبثت سنين في أهل مدين ثم جئت علىا قدر ياموسىا"
    },
    {
      "surah_number": 20,
      "verse_number": 41,
      "content": "واصطنعتك لنفسي"
    },
    {
      "surah_number": 20,
      "verse_number": 42,
      "content": "اذهب أنت وأخوك بٔاياتي ولا تنيا في ذكري"
    },
    {
      "surah_number": 20,
      "verse_number": 43,
      "content": "اذهبا الىا فرعون انه طغىا"
    },
    {
      "surah_number": 20,
      "verse_number": 44,
      "content": "فقولا له قولا لينا لعله يتذكر أو يخشىا"
    },
    {
      "surah_number": 20,
      "verse_number": 45,
      "content": "قالا ربنا اننا نخاف أن يفرط علينا أو أن يطغىا"
    },
    {
      "surah_number": 20,
      "verse_number": 46,
      "content": "قال لا تخافا انني معكما أسمع وأرىا"
    },
    {
      "surah_number": 20,
      "verse_number": 47,
      "content": "فأتياه فقولا انا رسولا ربك فأرسل معنا بني اسرايل ولا تعذبهم قد جئناك بٔايه من ربك والسلام علىا من اتبع الهدىا"
    },
    {
      "surah_number": 20,
      "verse_number": 48,
      "content": "انا قد أوحي الينا أن العذاب علىا من كذب وتولىا"
    },
    {
      "surah_number": 20,
      "verse_number": 49,
      "content": "قال فمن ربكما ياموسىا"
    },
    {
      "surah_number": 20,
      "verse_number": 50,
      "content": "قال ربنا الذي أعطىا كل شي خلقه ثم هدىا"
    },
    {
      "surah_number": 20,
      "verse_number": 51,
      "content": "قال فما بال القرون الأولىا"
    },
    {
      "surah_number": 20,
      "verse_number": 52,
      "content": "قال علمها عند ربي في كتاب لا يضل ربي ولا ينسى"
    },
    {
      "surah_number": 20,
      "verse_number": 53,
      "content": "الذي جعل لكم الأرض مهدا وسلك لكم فيها سبلا وأنزل من السما ما فأخرجنا به أزواجا من نبات شتىا"
    },
    {
      "surah_number": 20,
      "verse_number": 54,
      "content": "كلوا وارعوا أنعامكم ان في ذالك لأيات لأولي النهىا"
    },
    {
      "surah_number": 20,
      "verse_number": 55,
      "content": "منها خلقناكم وفيها نعيدكم ومنها نخرجكم تاره أخرىا"
    },
    {
      "surah_number": 20,
      "verse_number": 56,
      "content": "ولقد أريناه اياتنا كلها فكذب وأبىا"
    },
    {
      "surah_number": 20,
      "verse_number": 57,
      "content": "قال أجئتنا لتخرجنا من أرضنا بسحرك ياموسىا"
    },
    {
      "surah_number": 20,
      "verse_number": 58,
      "content": "فلنأتينك بسحر مثله فاجعل بيننا وبينك موعدا لا نخلفه نحن ولا أنت مكانا سوى"
    },
    {
      "surah_number": 20,
      "verse_number": 59,
      "content": "قال موعدكم يوم الزينه وأن يحشر الناس ضحى"
    },
    {
      "surah_number": 20,
      "verse_number": 60,
      "content": "فتولىا فرعون فجمع كيده ثم أتىا"
    },
    {
      "surah_number": 20,
      "verse_number": 61,
      "content": "قال لهم موسىا ويلكم لا تفتروا على الله كذبا فيسحتكم بعذاب وقد خاب من افترىا"
    },
    {
      "surah_number": 20,
      "verse_number": 62,
      "content": "فتنازعوا أمرهم بينهم وأسروا النجوىا"
    },
    {
      "surah_number": 20,
      "verse_number": 63,
      "content": "قالوا ان هاذان لساحران يريدان أن يخرجاكم من أرضكم بسحرهما ويذهبا بطريقتكم المثلىا"
    },
    {
      "surah_number": 20,
      "verse_number": 64,
      "content": "فأجمعوا كيدكم ثم ائتوا صفا وقد أفلح اليوم من استعلىا"
    },
    {
      "surah_number": 20,
      "verse_number": 65,
      "content": "قالوا ياموسىا اما أن تلقي واما أن نكون أول من ألقىا"
    },
    {
      "surah_number": 20,
      "verse_number": 66,
      "content": "قال بل ألقوا فاذا حبالهم وعصيهم يخيل اليه من سحرهم أنها تسعىا"
    },
    {
      "surah_number": 20,
      "verse_number": 67,
      "content": "فأوجس في نفسه خيفه موسىا"
    },
    {
      "surah_number": 20,
      "verse_number": 68,
      "content": "قلنا لا تخف انك أنت الأعلىا"
    },
    {
      "surah_number": 20,
      "verse_number": 69,
      "content": "وألق ما في يمينك تلقف ما صنعوا انما صنعوا كيد ساحر ولا يفلح الساحر حيث أتىا"
    },
    {
      "surah_number": 20,
      "verse_number": 70,
      "content": "فألقي السحره سجدا قالوا امنا برب هارون وموسىا"
    },
    {
      "surah_number": 20,
      "verse_number": 71,
      "content": "قال امنتم له قبل أن اذن لكم انه لكبيركم الذي علمكم السحر فلأقطعن أيديكم وأرجلكم من خلاف ولأصلبنكم في جذوع النخل ولتعلمن أينا أشد عذابا وأبقىا"
    },
    {
      "surah_number": 20,
      "verse_number": 72,
      "content": "قالوا لن نؤثرك علىا ما جانا من البينات والذي فطرنا فاقض ما أنت قاض انما تقضي هاذه الحيواه الدنيا"
    },
    {
      "surah_number": 20,
      "verse_number": 73,
      "content": "انا امنا بربنا ليغفر لنا خطايانا وما أكرهتنا عليه من السحر والله خير وأبقىا"
    },
    {
      "surah_number": 20,
      "verse_number": 74,
      "content": "انه من يأت ربه مجرما فان له جهنم لا يموت فيها ولا يحيىا"
    },
    {
      "surah_number": 20,
      "verse_number": 75,
      "content": "ومن يأته مؤمنا قد عمل الصالحات فأولائك لهم الدرجات العلىا"
    },
    {
      "surah_number": 20,
      "verse_number": 76,
      "content": "جنات عدن تجري من تحتها الأنهار خالدين فيها وذالك جزا من تزكىا"
    },
    {
      "surah_number": 20,
      "verse_number": 77,
      "content": "ولقد أوحينا الىا موسىا أن أسر بعبادي فاضرب لهم طريقا في البحر يبسا لا تخاف دركا ولا تخشىا"
    },
    {
      "surah_number": 20,
      "verse_number": 78,
      "content": "فأتبعهم فرعون بجنوده فغشيهم من اليم ما غشيهم"
    },
    {
      "surah_number": 20,
      "verse_number": 79,
      "content": "وأضل فرعون قومه وما هدىا"
    },
    {
      "surah_number": 20,
      "verse_number": 80,
      "content": "يابني اسرايل قد أنجيناكم من عدوكم وواعدناكم جانب الطور الأيمن ونزلنا عليكم المن والسلوىا"
    },
    {
      "surah_number": 20,
      "verse_number": 81,
      "content": "كلوا من طيبات ما رزقناكم ولا تطغوا فيه فيحل عليكم غضبي ومن يحلل عليه غضبي فقد هوىا"
    },
    {
      "surah_number": 20,
      "verse_number": 82,
      "content": "واني لغفار لمن تاب وامن وعمل صالحا ثم اهتدىا"
    },
    {
      "surah_number": 20,
      "verse_number": 83,
      "content": "وما أعجلك عن قومك ياموسىا"
    },
    {
      "surah_number": 20,
      "verse_number": 84,
      "content": "قال هم أولا علىا أثري وعجلت اليك رب لترضىا"
    },
    {
      "surah_number": 20,
      "verse_number": 85,
      "content": "قال فانا قد فتنا قومك من بعدك وأضلهم السامري"
    },
    {
      "surah_number": 20,
      "verse_number": 86,
      "content": "فرجع موسىا الىا قومه غضبان أسفا قال ياقوم ألم يعدكم ربكم وعدا حسنا أفطال عليكم العهد أم أردتم أن يحل عليكم غضب من ربكم فأخلفتم موعدي"
    },
    {
      "surah_number": 20,
      "verse_number": 87,
      "content": "قالوا ما أخلفنا موعدك بملكنا ولاكنا حملنا أوزارا من زينه القوم فقذفناها فكذالك ألقى السامري"
    },
    {
      "surah_number": 20,
      "verse_number": 88,
      "content": "فأخرج لهم عجلا جسدا له خوار فقالوا هاذا الاهكم والاه موسىا فنسي"
    },
    {
      "surah_number": 20,
      "verse_number": 89,
      "content": "أفلا يرون ألا يرجع اليهم قولا ولا يملك لهم ضرا ولا نفعا"
    },
    {
      "surah_number": 20,
      "verse_number": 90,
      "content": "ولقد قال لهم هارون من قبل ياقوم انما فتنتم به وان ربكم الرحمان فاتبعوني وأطيعوا أمري"
    },
    {
      "surah_number": 20,
      "verse_number": 91,
      "content": "قالوا لن نبرح عليه عاكفين حتىا يرجع الينا موسىا"
    },
    {
      "surah_number": 20,
      "verse_number": 92,
      "content": "قال ياهارون ما منعك اذ رأيتهم ضلوا"
    },
    {
      "surah_number": 20,
      "verse_number": 93,
      "content": "ألا تتبعن أفعصيت أمري"
    },
    {
      "surah_number": 20,
      "verse_number": 94,
      "content": "قال يبنؤم لا تأخذ بلحيتي ولا برأسي اني خشيت أن تقول فرقت بين بني اسرايل ولم ترقب قولي"
    },
    {
      "surah_number": 20,
      "verse_number": 95,
      "content": "قال فما خطبك ياسامري"
    },
    {
      "surah_number": 20,
      "verse_number": 96,
      "content": "قال بصرت بما لم يبصروا به فقبضت قبضه من أثر الرسول فنبذتها وكذالك سولت لي نفسي"
    },
    {
      "surah_number": 20,
      "verse_number": 97,
      "content": "قال فاذهب فان لك في الحيواه أن تقول لا مساس وان لك موعدا لن تخلفه وانظر الىا الاهك الذي ظلت عليه عاكفا لنحرقنه ثم لننسفنه في اليم نسفا"
    },
    {
      "surah_number": 20,
      "verse_number": 98,
      "content": "انما الاهكم الله الذي لا الاه الا هو وسع كل شي علما"
    },
    {
      "surah_number": 20,
      "verse_number": 99,
      "content": "كذالك نقص عليك من أنبا ما قد سبق وقد اتيناك من لدنا ذكرا"
    },
    {
      "surah_number": 20,
      "verse_number": 100,
      "content": "من أعرض عنه فانه يحمل يوم القيامه وزرا"
    },
    {
      "surah_number": 20,
      "verse_number": 101,
      "content": "خالدين فيه وسا لهم يوم القيامه حملا"
    },
    {
      "surah_number": 20,
      "verse_number": 102,
      "content": "يوم ينفخ في الصور ونحشر المجرمين يومئذ زرقا"
    },
    {
      "surah_number": 20,
      "verse_number": 103,
      "content": "يتخافتون بينهم ان لبثتم الا عشرا"
    },
    {
      "surah_number": 20,
      "verse_number": 104,
      "content": "نحن أعلم بما يقولون اذ يقول أمثلهم طريقه ان لبثتم الا يوما"
    },
    {
      "surah_number": 20,
      "verse_number": 105,
      "content": "ويسٔلونك عن الجبال فقل ينسفها ربي نسفا"
    },
    {
      "surah_number": 20,
      "verse_number": 106,
      "content": "فيذرها قاعا صفصفا"
    },
    {
      "surah_number": 20,
      "verse_number": 107,
      "content": "لا ترىا فيها عوجا ولا أمتا"
    },
    {
      "surah_number": 20,
      "verse_number": 108,
      "content": "يومئذ يتبعون الداعي لا عوج له وخشعت الأصوات للرحمان فلا تسمع الا همسا"
    },
    {
      "surah_number": 20,
      "verse_number": 109,
      "content": "يومئذ لا تنفع الشفاعه الا من أذن له الرحمان ورضي له قولا"
    },
    {
      "surah_number": 20,
      "verse_number": 110,
      "content": "يعلم ما بين أيديهم وما خلفهم ولا يحيطون به علما"
    },
    {
      "surah_number": 20,
      "verse_number": 111,
      "content": "وعنت الوجوه للحي القيوم وقد خاب من حمل ظلما"
    },
    {
      "surah_number": 20,
      "verse_number": 112,
      "content": "ومن يعمل من الصالحات وهو مؤمن فلا يخاف ظلما ولا هضما"
    },
    {
      "surah_number": 20,
      "verse_number": 113,
      "content": "وكذالك أنزلناه قرانا عربيا وصرفنا فيه من الوعيد لعلهم يتقون أو يحدث لهم ذكرا"
    },
    {
      "surah_number": 20,
      "verse_number": 114,
      "content": "فتعالى الله الملك الحق ولا تعجل بالقران من قبل أن يقضىا اليك وحيه وقل رب زدني علما"
    },
    {
      "surah_number": 20,
      "verse_number": 115,
      "content": "ولقد عهدنا الىا ادم من قبل فنسي ولم نجد له عزما"
    },
    {
      "surah_number": 20,
      "verse_number": 116,
      "content": "واذ قلنا للملائكه اسجدوا لأدم فسجدوا الا ابليس أبىا"
    },
    {
      "surah_number": 20,
      "verse_number": 117,
      "content": "فقلنا يأادم ان هاذا عدو لك ولزوجك فلا يخرجنكما من الجنه فتشقىا"
    },
    {
      "surah_number": 20,
      "verse_number": 118,
      "content": "ان لك ألا تجوع فيها ولا تعرىا"
    },
    {
      "surah_number": 20,
      "verse_number": 119,
      "content": "وأنك لا تظمؤا فيها ولا تضحىا"
    },
    {
      "surah_number": 20,
      "verse_number": 120,
      "content": "فوسوس اليه الشيطان قال يأادم هل أدلك علىا شجره الخلد وملك لا يبلىا"
    },
    {
      "surah_number": 20,
      "verse_number": 121,
      "content": "فأكلا منها فبدت لهما سواتهما وطفقا يخصفان عليهما من ورق الجنه وعصىا ادم ربه فغوىا"
    },
    {
      "surah_number": 20,
      "verse_number": 122,
      "content": "ثم اجتباه ربه فتاب عليه وهدىا"
    },
    {
      "surah_number": 20,
      "verse_number": 123,
      "content": "قال اهبطا منها جميعا بعضكم لبعض عدو فاما يأتينكم مني هدى فمن اتبع هداي فلا يضل ولا يشقىا"
    },
    {
      "surah_number": 20,
      "verse_number": 124,
      "content": "ومن أعرض عن ذكري فان له معيشه ضنكا ونحشره يوم القيامه أعمىا"
    },
    {
      "surah_number": 20,
      "verse_number": 125,
      "content": "قال رب لم حشرتني أعمىا وقد كنت بصيرا"
    },
    {
      "surah_number": 20,
      "verse_number": 126,
      "content": "قال كذالك أتتك اياتنا فنسيتها وكذالك اليوم تنسىا"
    },
    {
      "surah_number": 20,
      "verse_number": 127,
      "content": "وكذالك نجزي من أسرف ولم يؤمن بٔايات ربه ولعذاب الأخره أشد وأبقىا"
    },
    {
      "surah_number": 20,
      "verse_number": 128,
      "content": "أفلم يهد لهم كم أهلكنا قبلهم من القرون يمشون في مساكنهم ان في ذالك لأيات لأولي النهىا"
    },
    {
      "surah_number": 20,
      "verse_number": 129,
      "content": "ولولا كلمه سبقت من ربك لكان لزاما وأجل مسمى"
    },
    {
      "surah_number": 20,
      "verse_number": 130,
      "content": "فاصبر علىا ما يقولون وسبح بحمد ربك قبل طلوع الشمس وقبل غروبها ومن اناي اليل فسبح وأطراف النهار لعلك ترضىا"
    },
    {
      "surah_number": 20,
      "verse_number": 131,
      "content": "ولا تمدن عينيك الىا ما متعنا به أزواجا منهم زهره الحيواه الدنيا لنفتنهم فيه ورزق ربك خير وأبقىا"
    },
    {
      "surah_number": 20,
      "verse_number": 132,
      "content": "وأمر أهلك بالصلواه واصطبر عليها لا نسٔلك رزقا نحن نرزقك والعاقبه للتقوىا"
    },
    {
      "surah_number": 20,
      "verse_number": 133,
      "content": "وقالوا لولا يأتينا بٔايه من ربه أولم تأتهم بينه ما في الصحف الأولىا"
    },
    {
      "surah_number": 20,
      "verse_number": 134,
      "content": "ولو أنا أهلكناهم بعذاب من قبله لقالوا ربنا لولا أرسلت الينا رسولا فنتبع اياتك من قبل أن نذل ونخزىا"
    },
    {
      "surah_number": 20,
      "verse_number": 135,
      "content": "قل كل متربص فتربصوا فستعلمون من أصحاب الصراط السوي ومن اهتدىا"
    },
    {
      "surah_number": 21,
      "verse_number": 1,
      "content": "اقترب للناس حسابهم وهم في غفله معرضون"
    },
    {
      "surah_number": 21,
      "verse_number": 2,
      "content": "ما يأتيهم من ذكر من ربهم محدث الا استمعوه وهم يلعبون"
    },
    {
      "surah_number": 21,
      "verse_number": 3,
      "content": "لاهيه قلوبهم وأسروا النجوى الذين ظلموا هل هاذا الا بشر مثلكم أفتأتون السحر وأنتم تبصرون"
    },
    {
      "surah_number": 21,
      "verse_number": 4,
      "content": "قال ربي يعلم القول في السما والأرض وهو السميع العليم"
    },
    {
      "surah_number": 21,
      "verse_number": 5,
      "content": "بل قالوا أضغاث أحلام بل افترىاه بل هو شاعر فليأتنا بٔايه كما أرسل الأولون"
    },
    {
      "surah_number": 21,
      "verse_number": 6,
      "content": "ما امنت قبلهم من قريه أهلكناها أفهم يؤمنون"
    },
    {
      "surah_number": 21,
      "verse_number": 7,
      "content": "وما أرسلنا قبلك الا رجالا نوحي اليهم فسٔلوا أهل الذكر ان كنتم لا تعلمون"
    },
    {
      "surah_number": 21,
      "verse_number": 8,
      "content": "وما جعلناهم جسدا لا يأكلون الطعام وما كانوا خالدين"
    },
    {
      "surah_number": 21,
      "verse_number": 9,
      "content": "ثم صدقناهم الوعد فأنجيناهم ومن نشا وأهلكنا المسرفين"
    },
    {
      "surah_number": 21,
      "verse_number": 10,
      "content": "لقد أنزلنا اليكم كتابا فيه ذكركم أفلا تعقلون"
    },
    {
      "surah_number": 21,
      "verse_number": 11,
      "content": "وكم قصمنا من قريه كانت ظالمه وأنشأنا بعدها قوما اخرين"
    },
    {
      "surah_number": 21,
      "verse_number": 12,
      "content": "فلما أحسوا بأسنا اذا هم منها يركضون"
    },
    {
      "surah_number": 21,
      "verse_number": 13,
      "content": "لا تركضوا وارجعوا الىا ما أترفتم فيه ومساكنكم لعلكم تسٔلون"
    },
    {
      "surah_number": 21,
      "verse_number": 14,
      "content": "قالوا ياويلنا انا كنا ظالمين"
    },
    {
      "surah_number": 21,
      "verse_number": 15,
      "content": "فما زالت تلك دعوىاهم حتىا جعلناهم حصيدا خامدين"
    },
    {
      "surah_number": 21,
      "verse_number": 16,
      "content": "وما خلقنا السما والأرض وما بينهما لاعبين"
    },
    {
      "surah_number": 21,
      "verse_number": 17,
      "content": "لو أردنا أن نتخذ لهوا لاتخذناه من لدنا ان كنا فاعلين"
    },
    {
      "surah_number": 21,
      "verse_number": 18,
      "content": "بل نقذف بالحق على الباطل فيدمغه فاذا هو زاهق ولكم الويل مما تصفون"
    },
    {
      "surah_number": 21,
      "verse_number": 19,
      "content": "وله من في السماوات والأرض ومن عنده لا يستكبرون عن عبادته ولا يستحسرون"
    },
    {
      "surah_number": 21,
      "verse_number": 20,
      "content": "يسبحون اليل والنهار لا يفترون"
    },
    {
      "surah_number": 21,
      "verse_number": 21,
      "content": "أم اتخذوا الهه من الأرض هم ينشرون"
    },
    {
      "surah_number": 21,
      "verse_number": 22,
      "content": "لو كان فيهما الهه الا الله لفسدتا فسبحان الله رب العرش عما يصفون"
    },
    {
      "surah_number": 21,
      "verse_number": 23,
      "content": "لا يسٔل عما يفعل وهم يسٔلون"
    },
    {
      "surah_number": 21,
      "verse_number": 24,
      "content": "أم اتخذوا من دونه الهه قل هاتوا برهانكم هاذا ذكر من معي وذكر من قبلي بل أكثرهم لا يعلمون الحق فهم معرضون"
    },
    {
      "surah_number": 21,
      "verse_number": 25,
      "content": "وما أرسلنا من قبلك من رسول الا نوحي اليه أنه لا الاه الا أنا فاعبدون"
    },
    {
      "surah_number": 21,
      "verse_number": 26,
      "content": "وقالوا اتخذ الرحمان ولدا سبحانه بل عباد مكرمون"
    },
    {
      "surah_number": 21,
      "verse_number": 27,
      "content": "لا يسبقونه بالقول وهم بأمره يعملون"
    },
    {
      "surah_number": 21,
      "verse_number": 28,
      "content": "يعلم ما بين أيديهم وما خلفهم ولا يشفعون الا لمن ارتضىا وهم من خشيته مشفقون"
    },
    {
      "surah_number": 21,
      "verse_number": 29,
      "content": "ومن يقل منهم اني الاه من دونه فذالك نجزيه جهنم كذالك نجزي الظالمين"
    },
    {
      "surah_number": 21,
      "verse_number": 30,
      "content": "أولم ير الذين كفروا أن السماوات والأرض كانتا رتقا ففتقناهما وجعلنا من الما كل شي حي أفلا يؤمنون"
    },
    {
      "surah_number": 21,
      "verse_number": 31,
      "content": "وجعلنا في الأرض رواسي أن تميد بهم وجعلنا فيها فجاجا سبلا لعلهم يهتدون"
    },
    {
      "surah_number": 21,
      "verse_number": 32,
      "content": "وجعلنا السما سقفا محفوظا وهم عن اياتها معرضون"
    },
    {
      "surah_number": 21,
      "verse_number": 33,
      "content": "وهو الذي خلق اليل والنهار والشمس والقمر كل في فلك يسبحون"
    },
    {
      "surah_number": 21,
      "verse_number": 34,
      "content": "وما جعلنا لبشر من قبلك الخلد أفاين مت فهم الخالدون"
    },
    {
      "surah_number": 21,
      "verse_number": 35,
      "content": "كل نفس ذائقه الموت ونبلوكم بالشر والخير فتنه والينا ترجعون"
    },
    {
      "surah_number": 21,
      "verse_number": 36,
      "content": "واذا راك الذين كفروا ان يتخذونك الا هزوا أهاذا الذي يذكر الهتكم وهم بذكر الرحمان هم كافرون"
    },
    {
      "surah_number": 21,
      "verse_number": 37,
      "content": "خلق الانسان من عجل سأوريكم اياتي فلا تستعجلون"
    },
    {
      "surah_number": 21,
      "verse_number": 38,
      "content": "ويقولون متىا هاذا الوعد ان كنتم صادقين"
    },
    {
      "surah_number": 21,
      "verse_number": 39,
      "content": "لو يعلم الذين كفروا حين لا يكفون عن وجوههم النار ولا عن ظهورهم ولا هم ينصرون"
    },
    {
      "surah_number": 21,
      "verse_number": 40,
      "content": "بل تأتيهم بغته فتبهتهم فلا يستطيعون ردها ولا هم ينظرون"
    },
    {
      "surah_number": 21,
      "verse_number": 41,
      "content": "ولقد استهزئ برسل من قبلك فحاق بالذين سخروا منهم ما كانوا به يستهزون"
    },
    {
      "surah_number": 21,
      "verse_number": 42,
      "content": "قل من يكلؤكم باليل والنهار من الرحمان بل هم عن ذكر ربهم معرضون"
    },
    {
      "surah_number": 21,
      "verse_number": 43,
      "content": "أم لهم الهه تمنعهم من دوننا لا يستطيعون نصر أنفسهم ولا هم منا يصحبون"
    },
    {
      "surah_number": 21,
      "verse_number": 44,
      "content": "بل متعنا هاؤلا واباهم حتىا طال عليهم العمر أفلا يرون أنا نأتي الأرض ننقصها من أطرافها أفهم الغالبون"
    },
    {
      "surah_number": 21,
      "verse_number": 45,
      "content": "قل انما أنذركم بالوحي ولا يسمع الصم الدعا اذا ما ينذرون"
    },
    {
      "surah_number": 21,
      "verse_number": 46,
      "content": "ولئن مستهم نفحه من عذاب ربك ليقولن ياويلنا انا كنا ظالمين"
    },
    {
      "surah_number": 21,
      "verse_number": 47,
      "content": "ونضع الموازين القسط ليوم القيامه فلا تظلم نفس شئا وان كان مثقال حبه من خردل أتينا بها وكفىا بنا حاسبين"
    },
    {
      "surah_number": 21,
      "verse_number": 48,
      "content": "ولقد اتينا موسىا وهارون الفرقان وضيا وذكرا للمتقين"
    },
    {
      "surah_number": 21,
      "verse_number": 49,
      "content": "الذين يخشون ربهم بالغيب وهم من الساعه مشفقون"
    },
    {
      "surah_number": 21,
      "verse_number": 50,
      "content": "وهاذا ذكر مبارك أنزلناه أفأنتم له منكرون"
    },
    {
      "surah_number": 21,
      "verse_number": 51,
      "content": "ولقد اتينا ابراهيم رشده من قبل وكنا به عالمين"
    },
    {
      "surah_number": 21,
      "verse_number": 52,
      "content": "اذ قال لأبيه وقومه ما هاذه التماثيل التي أنتم لها عاكفون"
    },
    {
      "surah_number": 21,
      "verse_number": 53,
      "content": "قالوا وجدنا ابانا لها عابدين"
    },
    {
      "surah_number": 21,
      "verse_number": 54,
      "content": "قال لقد كنتم أنتم واباؤكم في ضلال مبين"
    },
    {
      "surah_number": 21,
      "verse_number": 55,
      "content": "قالوا أجئتنا بالحق أم أنت من اللاعبين"
    },
    {
      "surah_number": 21,
      "verse_number": 56,
      "content": "قال بل ربكم رب السماوات والأرض الذي فطرهن وأنا علىا ذالكم من الشاهدين"
    },
    {
      "surah_number": 21,
      "verse_number": 57,
      "content": "وتالله لأكيدن أصنامكم بعد أن تولوا مدبرين"
    },
    {
      "surah_number": 21,
      "verse_number": 58,
      "content": "فجعلهم جذاذا الا كبيرا لهم لعلهم اليه يرجعون"
    },
    {
      "surah_number": 21,
      "verse_number": 59,
      "content": "قالوا من فعل هاذا بٔالهتنا انه لمن الظالمين"
    },
    {
      "surah_number": 21,
      "verse_number": 60,
      "content": "قالوا سمعنا فتى يذكرهم يقال له ابراهيم"
    },
    {
      "surah_number": 21,
      "verse_number": 61,
      "content": "قالوا فأتوا به علىا أعين الناس لعلهم يشهدون"
    },
    {
      "surah_number": 21,
      "verse_number": 62,
      "content": "قالوا ءأنت فعلت هاذا بٔالهتنا ياابراهيم"
    },
    {
      "surah_number": 21,
      "verse_number": 63,
      "content": "قال بل فعله كبيرهم هاذا فسٔلوهم ان كانوا ينطقون"
    },
    {
      "surah_number": 21,
      "verse_number": 64,
      "content": "فرجعوا الىا أنفسهم فقالوا انكم أنتم الظالمون"
    },
    {
      "surah_number": 21,
      "verse_number": 65,
      "content": "ثم نكسوا علىا روسهم لقد علمت ما هاؤلا ينطقون"
    },
    {
      "surah_number": 21,
      "verse_number": 66,
      "content": "قال أفتعبدون من دون الله ما لا ينفعكم شئا ولا يضركم"
    },
    {
      "surah_number": 21,
      "verse_number": 67,
      "content": "أف لكم ولما تعبدون من دون الله أفلا تعقلون"
    },
    {
      "surah_number": 21,
      "verse_number": 68,
      "content": "قالوا حرقوه وانصروا الهتكم ان كنتم فاعلين"
    },
    {
      "surah_number": 21,
      "verse_number": 69,
      "content": "قلنا يانار كوني بردا وسلاما علىا ابراهيم"
    },
    {
      "surah_number": 21,
      "verse_number": 70,
      "content": "وأرادوا به كيدا فجعلناهم الأخسرين"
    },
    {
      "surah_number": 21,
      "verse_number": 71,
      "content": "ونجيناه ولوطا الى الأرض التي باركنا فيها للعالمين"
    },
    {
      "surah_number": 21,
      "verse_number": 72,
      "content": "ووهبنا له اسحاق ويعقوب نافله وكلا جعلنا صالحين"
    },
    {
      "surah_number": 21,
      "verse_number": 73,
      "content": "وجعلناهم أئمه يهدون بأمرنا وأوحينا اليهم فعل الخيرات واقام الصلواه وايتا الزكواه وكانوا لنا عابدين"
    },
    {
      "surah_number": 21,
      "verse_number": 74,
      "content": "ولوطا اتيناه حكما وعلما ونجيناه من القريه التي كانت تعمل الخبائث انهم كانوا قوم سو فاسقين"
    },
    {
      "surah_number": 21,
      "verse_number": 75,
      "content": "وأدخلناه في رحمتنا انه من الصالحين"
    },
    {
      "surah_number": 21,
      "verse_number": 76,
      "content": "ونوحا اذ نادىا من قبل فاستجبنا له فنجيناه وأهله من الكرب العظيم"
    },
    {
      "surah_number": 21,
      "verse_number": 77,
      "content": "ونصرناه من القوم الذين كذبوا بٔاياتنا انهم كانوا قوم سو فأغرقناهم أجمعين"
    },
    {
      "surah_number": 21,
      "verse_number": 78,
      "content": "وداود وسليمان اذ يحكمان في الحرث اذ نفشت فيه غنم القوم وكنا لحكمهم شاهدين"
    },
    {
      "surah_number": 21,
      "verse_number": 79,
      "content": "ففهمناها سليمان وكلا اتينا حكما وعلما وسخرنا مع داود الجبال يسبحن والطير وكنا فاعلين"
    },
    {
      "surah_number": 21,
      "verse_number": 80,
      "content": "وعلمناه صنعه لبوس لكم لتحصنكم من بأسكم فهل أنتم شاكرون"
    },
    {
      "surah_number": 21,
      "verse_number": 81,
      "content": "ولسليمان الريح عاصفه تجري بأمره الى الأرض التي باركنا فيها وكنا بكل شي عالمين"
    },
    {
      "surah_number": 21,
      "verse_number": 82,
      "content": "ومن الشياطين من يغوصون له ويعملون عملا دون ذالك وكنا لهم حافظين"
    },
    {
      "surah_number": 21,
      "verse_number": 83,
      "content": "وأيوب اذ نادىا ربه أني مسني الضر وأنت أرحم الراحمين"
    },
    {
      "surah_number": 21,
      "verse_number": 84,
      "content": "فاستجبنا له فكشفنا ما به من ضر واتيناه أهله ومثلهم معهم رحمه من عندنا وذكرىا للعابدين"
    },
    {
      "surah_number": 21,
      "verse_number": 85,
      "content": "واسماعيل وادريس وذا الكفل كل من الصابرين"
    },
    {
      "surah_number": 21,
      "verse_number": 86,
      "content": "وأدخلناهم في رحمتنا انهم من الصالحين"
    },
    {
      "surah_number": 21,
      "verse_number": 87,
      "content": "وذا النون اذ ذهب مغاضبا فظن أن لن نقدر عليه فنادىا في الظلمات أن لا الاه الا أنت سبحانك اني كنت من الظالمين"
    },
    {
      "surah_number": 21,
      "verse_number": 88,
      "content": "فاستجبنا له ونجيناه من الغم وكذالك نجي المؤمنين"
    },
    {
      "surah_number": 21,
      "verse_number": 89,
      "content": "وزكريا اذ نادىا ربه رب لا تذرني فردا وأنت خير الوارثين"
    },
    {
      "surah_number": 21,
      "verse_number": 90,
      "content": "فاستجبنا له ووهبنا له يحيىا وأصلحنا له زوجه انهم كانوا يسارعون في الخيرات ويدعوننا رغبا ورهبا وكانوا لنا خاشعين"
    },
    {
      "surah_number": 21,
      "verse_number": 91,
      "content": "والتي أحصنت فرجها فنفخنا فيها من روحنا وجعلناها وابنها ايه للعالمين"
    },
    {
      "surah_number": 21,
      "verse_number": 92,
      "content": "ان هاذه أمتكم أمه واحده وأنا ربكم فاعبدون"
    },
    {
      "surah_number": 21,
      "verse_number": 93,
      "content": "وتقطعوا أمرهم بينهم كل الينا راجعون"
    },
    {
      "surah_number": 21,
      "verse_number": 94,
      "content": "فمن يعمل من الصالحات وهو مؤمن فلا كفران لسعيه وانا له كاتبون"
    },
    {
      "surah_number": 21,
      "verse_number": 95,
      "content": "وحرام علىا قريه أهلكناها أنهم لا يرجعون"
    },
    {
      "surah_number": 21,
      "verse_number": 96,
      "content": "حتىا اذا فتحت يأجوج ومأجوج وهم من كل حدب ينسلون"
    },
    {
      "surah_number": 21,
      "verse_number": 97,
      "content": "واقترب الوعد الحق فاذا هي شاخصه أبصار الذين كفروا ياويلنا قد كنا في غفله من هاذا بل كنا ظالمين"
    },
    {
      "surah_number": 21,
      "verse_number": 98,
      "content": "انكم وما تعبدون من دون الله حصب جهنم أنتم لها واردون"
    },
    {
      "surah_number": 21,
      "verse_number": 99,
      "content": "لو كان هاؤلا الهه ما وردوها وكل فيها خالدون"
    },
    {
      "surah_number": 21,
      "verse_number": 100,
      "content": "لهم فيها زفير وهم فيها لا يسمعون"
    },
    {
      "surah_number": 21,
      "verse_number": 101,
      "content": "ان الذين سبقت لهم منا الحسنىا أولائك عنها مبعدون"
    },
    {
      "surah_number": 21,
      "verse_number": 102,
      "content": "لا يسمعون حسيسها وهم في ما اشتهت أنفسهم خالدون"
    },
    {
      "surah_number": 21,
      "verse_number": 103,
      "content": "لا يحزنهم الفزع الأكبر وتتلقىاهم الملائكه هاذا يومكم الذي كنتم توعدون"
    },
    {
      "surah_number": 21,
      "verse_number": 104,
      "content": "يوم نطوي السما كطي السجل للكتب كما بدأنا أول خلق نعيده وعدا علينا انا كنا فاعلين"
    },
    {
      "surah_number": 21,
      "verse_number": 105,
      "content": "ولقد كتبنا في الزبور من بعد الذكر أن الأرض يرثها عبادي الصالحون"
    },
    {
      "surah_number": 21,
      "verse_number": 106,
      "content": "ان في هاذا لبلاغا لقوم عابدين"
    },
    {
      "surah_number": 21,
      "verse_number": 107,
      "content": "وما أرسلناك الا رحمه للعالمين"
    },
    {
      "surah_number": 21,
      "verse_number": 108,
      "content": "قل انما يوحىا الي أنما الاهكم الاه واحد فهل أنتم مسلمون"
    },
    {
      "surah_number": 21,
      "verse_number": 109,
      "content": "فان تولوا فقل اذنتكم علىا سوا وان أدري أقريب أم بعيد ما توعدون"
    },
    {
      "surah_number": 21,
      "verse_number": 110,
      "content": "انه يعلم الجهر من القول ويعلم ما تكتمون"
    },
    {
      "surah_number": 21,
      "verse_number": 111,
      "content": "وان أدري لعله فتنه لكم ومتاع الىا حين"
    },
    {
      "surah_number": 21,
      "verse_number": 112,
      "content": "قال رب احكم بالحق وربنا الرحمان المستعان علىا ما تصفون"
    },
    {
      "surah_number": 22,
      "verse_number": 1,
      "content": "ياأيها الناس اتقوا ربكم ان زلزله الساعه شي عظيم"
    },
    {
      "surah_number": 22,
      "verse_number": 2,
      "content": "يوم ترونها تذهل كل مرضعه عما أرضعت وتضع كل ذات حمل حملها وترى الناس سكارىا وما هم بسكارىا ولاكن عذاب الله شديد"
    },
    {
      "surah_number": 22,
      "verse_number": 3,
      "content": "ومن الناس من يجادل في الله بغير علم ويتبع كل شيطان مريد"
    },
    {
      "surah_number": 22,
      "verse_number": 4,
      "content": "كتب عليه أنه من تولاه فأنه يضله ويهديه الىا عذاب السعير"
    },
    {
      "surah_number": 22,
      "verse_number": 5,
      "content": "ياأيها الناس ان كنتم في ريب من البعث فانا خلقناكم من تراب ثم من نطفه ثم من علقه ثم من مضغه مخلقه وغير مخلقه لنبين لكم ونقر في الأرحام ما نشا الىا أجل مسمى ثم نخرجكم طفلا ثم لتبلغوا أشدكم ومنكم من يتوفىا ومنكم من يرد الىا أرذل العمر لكيلا يعلم من بعد علم شئا وترى الأرض هامده فاذا أنزلنا عليها الما اهتزت وربت وأنبتت من كل زوج بهيج"
    },
    {
      "surah_number": 22,
      "verse_number": 6,
      "content": "ذالك بأن الله هو الحق وأنه يحي الموتىا وأنه علىا كل شي قدير"
    },
    {
      "surah_number": 22,
      "verse_number": 7,
      "content": "وأن الساعه اتيه لا ريب فيها وأن الله يبعث من في القبور"
    },
    {
      "surah_number": 22,
      "verse_number": 8,
      "content": "ومن الناس من يجادل في الله بغير علم ولا هدى ولا كتاب منير"
    },
    {
      "surah_number": 22,
      "verse_number": 9,
      "content": "ثاني عطفه ليضل عن سبيل الله له في الدنيا خزي ونذيقه يوم القيامه عذاب الحريق"
    },
    {
      "surah_number": 22,
      "verse_number": 10,
      "content": "ذالك بما قدمت يداك وأن الله ليس بظلام للعبيد"
    },
    {
      "surah_number": 22,
      "verse_number": 11,
      "content": "ومن الناس من يعبد الله علىا حرف فان أصابه خير اطمأن به وان أصابته فتنه انقلب علىا وجهه خسر الدنيا والأخره ذالك هو الخسران المبين"
    },
    {
      "surah_number": 22,
      "verse_number": 12,
      "content": "يدعوا من دون الله ما لا يضره وما لا ينفعه ذالك هو الضلال البعيد"
    },
    {
      "surah_number": 22,
      "verse_number": 13,
      "content": "يدعوا لمن ضره أقرب من نفعه لبئس المولىا ولبئس العشير"
    },
    {
      "surah_number": 22,
      "verse_number": 14,
      "content": "ان الله يدخل الذين امنوا وعملوا الصالحات جنات تجري من تحتها الأنهار ان الله يفعل ما يريد"
    },
    {
      "surah_number": 22,
      "verse_number": 15,
      "content": "من كان يظن أن لن ينصره الله في الدنيا والأخره فليمدد بسبب الى السما ثم ليقطع فلينظر هل يذهبن كيده ما يغيظ"
    },
    {
      "surah_number": 22,
      "verse_number": 16,
      "content": "وكذالك أنزلناه ايات بينات وأن الله يهدي من يريد"
    },
    {
      "surah_number": 22,
      "verse_number": 17,
      "content": "ان الذين امنوا والذين هادوا والصابٔين والنصارىا والمجوس والذين أشركوا ان الله يفصل بينهم يوم القيامه ان الله علىا كل شي شهيد"
    },
    {
      "surah_number": 22,
      "verse_number": 18,
      "content": "ألم تر أن الله يسجد له من في السماوات ومن في الأرض والشمس والقمر والنجوم والجبال والشجر والدواب وكثير من الناس وكثير حق عليه العذاب ومن يهن الله فما له من مكرم ان الله يفعل ما يشا"
    },
    {
      "surah_number": 22,
      "verse_number": 19,
      "content": "هاذان خصمان اختصموا في ربهم فالذين كفروا قطعت لهم ثياب من نار يصب من فوق روسهم الحميم"
    },
    {
      "surah_number": 22,
      "verse_number": 20,
      "content": "يصهر به ما في بطونهم والجلود"
    },
    {
      "surah_number": 22,
      "verse_number": 21,
      "content": "ولهم مقامع من حديد"
    },
    {
      "surah_number": 22,
      "verse_number": 22,
      "content": "كلما أرادوا أن يخرجوا منها من غم أعيدوا فيها وذوقوا عذاب الحريق"
    },
    {
      "surah_number": 22,
      "verse_number": 23,
      "content": "ان الله يدخل الذين امنوا وعملوا الصالحات جنات تجري من تحتها الأنهار يحلون فيها من أساور من ذهب ولؤلؤا ولباسهم فيها حرير"
    },
    {
      "surah_number": 22,
      "verse_number": 24,
      "content": "وهدوا الى الطيب من القول وهدوا الىا صراط الحميد"
    },
    {
      "surah_number": 22,
      "verse_number": 25,
      "content": "ان الذين كفروا ويصدون عن سبيل الله والمسجد الحرام الذي جعلناه للناس سوا العاكف فيه والباد ومن يرد فيه بالحاد بظلم نذقه من عذاب أليم"
    },
    {
      "surah_number": 22,
      "verse_number": 26,
      "content": "واذ بوأنا لابراهيم مكان البيت أن لا تشرك بي شئا وطهر بيتي للطائفين والقائمين والركع السجود"
    },
    {
      "surah_number": 22,
      "verse_number": 27,
      "content": "وأذن في الناس بالحج يأتوك رجالا وعلىا كل ضامر يأتين من كل فج عميق"
    },
    {
      "surah_number": 22,
      "verse_number": 28,
      "content": "ليشهدوا منافع لهم ويذكروا اسم الله في أيام معلومات علىا ما رزقهم من بهيمه الأنعام فكلوا منها وأطعموا البائس الفقير"
    },
    {
      "surah_number": 22,
      "verse_number": 29,
      "content": "ثم ليقضوا تفثهم وليوفوا نذورهم وليطوفوا بالبيت العتيق"
    },
    {
      "surah_number": 22,
      "verse_number": 30,
      "content": "ذالك ومن يعظم حرمات الله فهو خير له عند ربه وأحلت لكم الأنعام الا ما يتلىا عليكم فاجتنبوا الرجس من الأوثان واجتنبوا قول الزور"
    },
    {
      "surah_number": 22,
      "verse_number": 31,
      "content": "حنفا لله غير مشركين به ومن يشرك بالله فكأنما خر من السما فتخطفه الطير أو تهوي به الريح في مكان سحيق"
    },
    {
      "surah_number": 22,
      "verse_number": 32,
      "content": "ذالك ومن يعظم شعائر الله فانها من تقوى القلوب"
    },
    {
      "surah_number": 22,
      "verse_number": 33,
      "content": "لكم فيها منافع الىا أجل مسمى ثم محلها الى البيت العتيق"
    },
    {
      "surah_number": 22,
      "verse_number": 34,
      "content": "ولكل أمه جعلنا منسكا ليذكروا اسم الله علىا ما رزقهم من بهيمه الأنعام فالاهكم الاه واحد فله أسلموا وبشر المخبتين"
    },
    {
      "surah_number": 22,
      "verse_number": 35,
      "content": "الذين اذا ذكر الله وجلت قلوبهم والصابرين علىا ما أصابهم والمقيمي الصلواه ومما رزقناهم ينفقون"
    },
    {
      "surah_number": 22,
      "verse_number": 36,
      "content": "والبدن جعلناها لكم من شعائر الله لكم فيها خير فاذكروا اسم الله عليها صواف فاذا وجبت جنوبها فكلوا منها وأطعموا القانع والمعتر كذالك سخرناها لكم لعلكم تشكرون"
    },
    {
      "surah_number": 22,
      "verse_number": 37,
      "content": "لن ينال الله لحومها ولا دماؤها ولاكن يناله التقوىا منكم كذالك سخرها لكم لتكبروا الله علىا ما هدىاكم وبشر المحسنين"
    },
    {
      "surah_number": 22,
      "verse_number": 38,
      "content": "ان الله يدافع عن الذين امنوا ان الله لا يحب كل خوان كفور"
    },
    {
      "surah_number": 22,
      "verse_number": 39,
      "content": "أذن للذين يقاتلون بأنهم ظلموا وان الله علىا نصرهم لقدير"
    },
    {
      "surah_number": 22,
      "verse_number": 40,
      "content": "الذين أخرجوا من ديارهم بغير حق الا أن يقولوا ربنا الله ولولا دفع الله الناس بعضهم ببعض لهدمت صوامع وبيع وصلوات ومساجد يذكر فيها اسم الله كثيرا ولينصرن الله من ينصره ان الله لقوي عزيز"
    },
    {
      "surah_number": 22,
      "verse_number": 41,
      "content": "الذين ان مكناهم في الأرض أقاموا الصلواه واتوا الزكواه وأمروا بالمعروف ونهوا عن المنكر ولله عاقبه الأمور"
    },
    {
      "surah_number": 22,
      "verse_number": 42,
      "content": "وان يكذبوك فقد كذبت قبلهم قوم نوح وعاد وثمود"
    },
    {
      "surah_number": 22,
      "verse_number": 43,
      "content": "وقوم ابراهيم وقوم لوط"
    },
    {
      "surah_number": 22,
      "verse_number": 44,
      "content": "وأصحاب مدين وكذب موسىا فأمليت للكافرين ثم أخذتهم فكيف كان نكير"
    },
    {
      "surah_number": 22,
      "verse_number": 45,
      "content": "فكأين من قريه أهلكناها وهي ظالمه فهي خاويه علىا عروشها وبئر معطله وقصر مشيد"
    },
    {
      "surah_number": 22,
      "verse_number": 46,
      "content": "أفلم يسيروا في الأرض فتكون لهم قلوب يعقلون بها أو اذان يسمعون بها فانها لا تعمى الأبصار ولاكن تعمى القلوب التي في الصدور"
    },
    {
      "surah_number": 22,
      "verse_number": 47,
      "content": "ويستعجلونك بالعذاب ولن يخلف الله وعده وان يوما عند ربك كألف سنه مما تعدون"
    },
    {
      "surah_number": 22,
      "verse_number": 48,
      "content": "وكأين من قريه أمليت لها وهي ظالمه ثم أخذتها والي المصير"
    },
    {
      "surah_number": 22,
      "verse_number": 49,
      "content": "قل ياأيها الناس انما أنا لكم نذير مبين"
    },
    {
      "surah_number": 22,
      "verse_number": 50,
      "content": "فالذين امنوا وعملوا الصالحات لهم مغفره ورزق كريم"
    },
    {
      "surah_number": 22,
      "verse_number": 51,
      "content": "والذين سعوا في اياتنا معاجزين أولائك أصحاب الجحيم"
    },
    {
      "surah_number": 22,
      "verse_number": 52,
      "content": "وما أرسلنا من قبلك من رسول ولا نبي الا اذا تمنىا ألقى الشيطان في أمنيته فينسخ الله ما يلقي الشيطان ثم يحكم الله اياته والله عليم حكيم"
    },
    {
      "surah_number": 22,
      "verse_number": 53,
      "content": "ليجعل ما يلقي الشيطان فتنه للذين في قلوبهم مرض والقاسيه قلوبهم وان الظالمين لفي شقاق بعيد"
    },
    {
      "surah_number": 22,
      "verse_number": 54,
      "content": "وليعلم الذين أوتوا العلم أنه الحق من ربك فيؤمنوا به فتخبت له قلوبهم وان الله لهاد الذين امنوا الىا صراط مستقيم"
    },
    {
      "surah_number": 22,
      "verse_number": 55,
      "content": "ولا يزال الذين كفروا في مريه منه حتىا تأتيهم الساعه بغته أو يأتيهم عذاب يوم عقيم"
    },
    {
      "surah_number": 22,
      "verse_number": 56,
      "content": "الملك يومئذ لله يحكم بينهم فالذين امنوا وعملوا الصالحات في جنات النعيم"
    },
    {
      "surah_number": 22,
      "verse_number": 57,
      "content": "والذين كفروا وكذبوا بٔاياتنا فأولائك لهم عذاب مهين"
    },
    {
      "surah_number": 22,
      "verse_number": 58,
      "content": "والذين هاجروا في سبيل الله ثم قتلوا أو ماتوا ليرزقنهم الله رزقا حسنا وان الله لهو خير الرازقين"
    },
    {
      "surah_number": 22,
      "verse_number": 59,
      "content": "ليدخلنهم مدخلا يرضونه وان الله لعليم حليم"
    },
    {
      "surah_number": 22,
      "verse_number": 60,
      "content": "ذالك ومن عاقب بمثل ما عوقب به ثم بغي عليه لينصرنه الله ان الله لعفو غفور"
    },
    {
      "surah_number": 22,
      "verse_number": 61,
      "content": "ذالك بأن الله يولج اليل في النهار ويولج النهار في اليل وأن الله سميع بصير"
    },
    {
      "surah_number": 22,
      "verse_number": 62,
      "content": "ذالك بأن الله هو الحق وأن ما يدعون من دونه هو الباطل وأن الله هو العلي الكبير"
    },
    {
      "surah_number": 22,
      "verse_number": 63,
      "content": "ألم تر أن الله أنزل من السما ما فتصبح الأرض مخضره ان الله لطيف خبير"
    },
    {
      "surah_number": 22,
      "verse_number": 64,
      "content": "له ما في السماوات وما في الأرض وان الله لهو الغني الحميد"
    },
    {
      "surah_number": 22,
      "verse_number": 65,
      "content": "ألم تر أن الله سخر لكم ما في الأرض والفلك تجري في البحر بأمره ويمسك السما أن تقع على الأرض الا باذنه ان الله بالناس لروف رحيم"
    },
    {
      "surah_number": 22,
      "verse_number": 66,
      "content": "وهو الذي أحياكم ثم يميتكم ثم يحييكم ان الانسان لكفور"
    },
    {
      "surah_number": 22,
      "verse_number": 67,
      "content": "لكل أمه جعلنا منسكا هم ناسكوه فلا ينازعنك في الأمر وادع الىا ربك انك لعلىا هدى مستقيم"
    },
    {
      "surah_number": 22,
      "verse_number": 68,
      "content": "وان جادلوك فقل الله أعلم بما تعملون"
    },
    {
      "surah_number": 22,
      "verse_number": 69,
      "content": "الله يحكم بينكم يوم القيامه فيما كنتم فيه تختلفون"
    },
    {
      "surah_number": 22,
      "verse_number": 70,
      "content": "ألم تعلم أن الله يعلم ما في السما والأرض ان ذالك في كتاب ان ذالك على الله يسير"
    },
    {
      "surah_number": 22,
      "verse_number": 71,
      "content": "ويعبدون من دون الله ما لم ينزل به سلطانا وما ليس لهم به علم وما للظالمين من نصير"
    },
    {
      "surah_number": 22,
      "verse_number": 72,
      "content": "واذا تتلىا عليهم اياتنا بينات تعرف في وجوه الذين كفروا المنكر يكادون يسطون بالذين يتلون عليهم اياتنا قل أفأنبئكم بشر من ذالكم النار وعدها الله الذين كفروا وبئس المصير"
    },
    {
      "surah_number": 22,
      "verse_number": 73,
      "content": "ياأيها الناس ضرب مثل فاستمعوا له ان الذين تدعون من دون الله لن يخلقوا ذبابا ولو اجتمعوا له وان يسلبهم الذباب شئا لا يستنقذوه منه ضعف الطالب والمطلوب"
    },
    {
      "surah_number": 22,
      "verse_number": 74,
      "content": "ما قدروا الله حق قدره ان الله لقوي عزيز"
    },
    {
      "surah_number": 22,
      "verse_number": 75,
      "content": "الله يصطفي من الملائكه رسلا ومن الناس ان الله سميع بصير"
    },
    {
      "surah_number": 22,
      "verse_number": 76,
      "content": "يعلم ما بين أيديهم وما خلفهم والى الله ترجع الأمور"
    },
    {
      "surah_number": 22,
      "verse_number": 77,
      "content": "ياأيها الذين امنوا اركعوا واسجدوا واعبدوا ربكم وافعلوا الخير لعلكم تفلحون"
    },
    {
      "surah_number": 22,
      "verse_number": 78,
      "content": "وجاهدوا في الله حق جهاده هو اجتبىاكم وما جعل عليكم في الدين من حرج مله أبيكم ابراهيم هو سمىاكم المسلمين من قبل وفي هاذا ليكون الرسول شهيدا عليكم وتكونوا شهدا على الناس فأقيموا الصلواه واتوا الزكواه واعتصموا بالله هو مولىاكم فنعم المولىا ونعم النصير"
    },
    {
      "surah_number": 23,
      "verse_number": 1,
      "content": "قد أفلح المؤمنون"
    },
    {
      "surah_number": 23,
      "verse_number": 2,
      "content": "الذين هم في صلاتهم خاشعون"
    },
    {
      "surah_number": 23,
      "verse_number": 3,
      "content": "والذين هم عن اللغو معرضون"
    },
    {
      "surah_number": 23,
      "verse_number": 4,
      "content": "والذين هم للزكواه فاعلون"
    },
    {
      "surah_number": 23,
      "verse_number": 5,
      "content": "والذين هم لفروجهم حافظون"
    },
    {
      "surah_number": 23,
      "verse_number": 6,
      "content": "الا علىا أزواجهم أو ما ملكت أيمانهم فانهم غير ملومين"
    },
    {
      "surah_number": 23,
      "verse_number": 7,
      "content": "فمن ابتغىا ورا ذالك فأولائك هم العادون"
    },
    {
      "surah_number": 23,
      "verse_number": 8,
      "content": "والذين هم لأماناتهم وعهدهم راعون"
    },
    {
      "surah_number": 23,
      "verse_number": 9,
      "content": "والذين هم علىا صلواتهم يحافظون"
    },
    {
      "surah_number": 23,
      "verse_number": 10,
      "content": "أولائك هم الوارثون"
    },
    {
      "surah_number": 23,
      "verse_number": 11,
      "content": "الذين يرثون الفردوس هم فيها خالدون"
    },
    {
      "surah_number": 23,
      "verse_number": 12,
      "content": "ولقد خلقنا الانسان من سلاله من طين"
    },
    {
      "surah_number": 23,
      "verse_number": 13,
      "content": "ثم جعلناه نطفه في قرار مكين"
    },
    {
      "surah_number": 23,
      "verse_number": 14,
      "content": "ثم خلقنا النطفه علقه فخلقنا العلقه مضغه فخلقنا المضغه عظاما فكسونا العظام لحما ثم أنشأناه خلقا اخر فتبارك الله أحسن الخالقين"
    },
    {
      "surah_number": 23,
      "verse_number": 15,
      "content": "ثم انكم بعد ذالك لميتون"
    },
    {
      "surah_number": 23,
      "verse_number": 16,
      "content": "ثم انكم يوم القيامه تبعثون"
    },
    {
      "surah_number": 23,
      "verse_number": 17,
      "content": "ولقد خلقنا فوقكم سبع طرائق وما كنا عن الخلق غافلين"
    },
    {
      "surah_number": 23,
      "verse_number": 18,
      "content": "وأنزلنا من السما ما بقدر فأسكناه في الأرض وانا علىا ذهاب به لقادرون"
    },
    {
      "surah_number": 23,
      "verse_number": 19,
      "content": "فأنشأنا لكم به جنات من نخيل وأعناب لكم فيها فواكه كثيره ومنها تأكلون"
    },
    {
      "surah_number": 23,
      "verse_number": 20,
      "content": "وشجره تخرج من طور سينا تنبت بالدهن وصبغ للأكلين"
    },
    {
      "surah_number": 23,
      "verse_number": 21,
      "content": "وان لكم في الأنعام لعبره نسقيكم مما في بطونها ولكم فيها منافع كثيره ومنها تأكلون"
    },
    {
      "surah_number": 23,
      "verse_number": 22,
      "content": "وعليها وعلى الفلك تحملون"
    },
    {
      "surah_number": 23,
      "verse_number": 23,
      "content": "ولقد أرسلنا نوحا الىا قومه فقال ياقوم اعبدوا الله ما لكم من الاه غيره أفلا تتقون"
    },
    {
      "surah_number": 23,
      "verse_number": 24,
      "content": "فقال الملؤا الذين كفروا من قومه ما هاذا الا بشر مثلكم يريد أن يتفضل عليكم ولو شا الله لأنزل ملائكه ما سمعنا بهاذا في ابائنا الأولين"
    },
    {
      "surah_number": 23,
      "verse_number": 25,
      "content": "ان هو الا رجل به جنه فتربصوا به حتىا حين"
    },
    {
      "surah_number": 23,
      "verse_number": 26,
      "content": "قال رب انصرني بما كذبون"
    },
    {
      "surah_number": 23,
      "verse_number": 27,
      "content": "فأوحينا اليه أن اصنع الفلك بأعيننا ووحينا فاذا جا أمرنا وفار التنور فاسلك فيها من كل زوجين اثنين وأهلك الا من سبق عليه القول منهم ولا تخاطبني في الذين ظلموا انهم مغرقون"
    },
    {
      "surah_number": 23,
      "verse_number": 28,
      "content": "فاذا استويت أنت ومن معك على الفلك فقل الحمد لله الذي نجىانا من القوم الظالمين"
    },
    {
      "surah_number": 23,
      "verse_number": 29,
      "content": "وقل رب أنزلني منزلا مباركا وأنت خير المنزلين"
    },
    {
      "surah_number": 23,
      "verse_number": 30,
      "content": "ان في ذالك لأيات وان كنا لمبتلين"
    },
    {
      "surah_number": 23,
      "verse_number": 31,
      "content": "ثم أنشأنا من بعدهم قرنا اخرين"
    },
    {
      "surah_number": 23,
      "verse_number": 32,
      "content": "فأرسلنا فيهم رسولا منهم أن اعبدوا الله ما لكم من الاه غيره أفلا تتقون"
    },
    {
      "surah_number": 23,
      "verse_number": 33,
      "content": "وقال الملأ من قومه الذين كفروا وكذبوا بلقا الأخره وأترفناهم في الحيواه الدنيا ما هاذا الا بشر مثلكم يأكل مما تأكلون منه ويشرب مما تشربون"
    },
    {
      "surah_number": 23,
      "verse_number": 34,
      "content": "ولئن أطعتم بشرا مثلكم انكم اذا لخاسرون"
    },
    {
      "surah_number": 23,
      "verse_number": 35,
      "content": "أيعدكم أنكم اذا متم وكنتم ترابا وعظاما أنكم مخرجون"
    },
    {
      "surah_number": 23,
      "verse_number": 36,
      "content": "هيهات هيهات لما توعدون"
    },
    {
      "surah_number": 23,
      "verse_number": 37,
      "content": "ان هي الا حياتنا الدنيا نموت ونحيا وما نحن بمبعوثين"
    },
    {
      "surah_number": 23,
      "verse_number": 38,
      "content": "ان هو الا رجل افترىا على الله كذبا وما نحن له بمؤمنين"
    },
    {
      "surah_number": 23,
      "verse_number": 39,
      "content": "قال رب انصرني بما كذبون"
    },
    {
      "surah_number": 23,
      "verse_number": 40,
      "content": "قال عما قليل ليصبحن نادمين"
    },
    {
      "surah_number": 23,
      "verse_number": 41,
      "content": "فأخذتهم الصيحه بالحق فجعلناهم غثا فبعدا للقوم الظالمين"
    },
    {
      "surah_number": 23,
      "verse_number": 42,
      "content": "ثم أنشأنا من بعدهم قرونا اخرين"
    },
    {
      "surah_number": 23,
      "verse_number": 43,
      "content": "ما تسبق من أمه أجلها وما يستٔخرون"
    },
    {
      "surah_number": 23,
      "verse_number": 44,
      "content": "ثم أرسلنا رسلنا تترا كل ما جا أمه رسولها كذبوه فأتبعنا بعضهم بعضا وجعلناهم أحاديث فبعدا لقوم لا يؤمنون"
    },
    {
      "surah_number": 23,
      "verse_number": 45,
      "content": "ثم أرسلنا موسىا وأخاه هارون بٔاياتنا وسلطان مبين"
    },
    {
      "surah_number": 23,
      "verse_number": 46,
      "content": "الىا فرعون وملايه فاستكبروا وكانوا قوما عالين"
    },
    {
      "surah_number": 23,
      "verse_number": 47,
      "content": "فقالوا أنؤمن لبشرين مثلنا وقومهما لنا عابدون"
    },
    {
      "surah_number": 23,
      "verse_number": 48,
      "content": "فكذبوهما فكانوا من المهلكين"
    },
    {
      "surah_number": 23,
      "verse_number": 49,
      "content": "ولقد اتينا موسى الكتاب لعلهم يهتدون"
    },
    {
      "surah_number": 23,
      "verse_number": 50,
      "content": "وجعلنا ابن مريم وأمه ايه واويناهما الىا ربوه ذات قرار ومعين"
    },
    {
      "surah_number": 23,
      "verse_number": 51,
      "content": "ياأيها الرسل كلوا من الطيبات واعملوا صالحا اني بما تعملون عليم"
    },
    {
      "surah_number": 23,
      "verse_number": 52,
      "content": "وان هاذه أمتكم أمه واحده وأنا ربكم فاتقون"
    },
    {
      "surah_number": 23,
      "verse_number": 53,
      "content": "فتقطعوا أمرهم بينهم زبرا كل حزب بما لديهم فرحون"
    },
    {
      "surah_number": 23,
      "verse_number": 54,
      "content": "فذرهم في غمرتهم حتىا حين"
    },
    {
      "surah_number": 23,
      "verse_number": 55,
      "content": "أيحسبون أنما نمدهم به من مال وبنين"
    },
    {
      "surah_number": 23,
      "verse_number": 56,
      "content": "نسارع لهم في الخيرات بل لا يشعرون"
    },
    {
      "surah_number": 23,
      "verse_number": 57,
      "content": "ان الذين هم من خشيه ربهم مشفقون"
    },
    {
      "surah_number": 23,
      "verse_number": 58,
      "content": "والذين هم بٔايات ربهم يؤمنون"
    },
    {
      "surah_number": 23,
      "verse_number": 59,
      "content": "والذين هم بربهم لا يشركون"
    },
    {
      "surah_number": 23,
      "verse_number": 60,
      "content": "والذين يؤتون ما اتوا وقلوبهم وجله أنهم الىا ربهم راجعون"
    },
    {
      "surah_number": 23,
      "verse_number": 61,
      "content": "أولائك يسارعون في الخيرات وهم لها سابقون"
    },
    {
      "surah_number": 23,
      "verse_number": 62,
      "content": "ولا نكلف نفسا الا وسعها ولدينا كتاب ينطق بالحق وهم لا يظلمون"
    },
    {
      "surah_number": 23,
      "verse_number": 63,
      "content": "بل قلوبهم في غمره من هاذا ولهم أعمال من دون ذالك هم لها عاملون"
    },
    {
      "surah_number": 23,
      "verse_number": 64,
      "content": "حتىا اذا أخذنا مترفيهم بالعذاب اذا هم يجٔرون"
    },
    {
      "surah_number": 23,
      "verse_number": 65,
      "content": "لا تجٔروا اليوم انكم منا لا تنصرون"
    },
    {
      "surah_number": 23,
      "verse_number": 66,
      "content": "قد كانت اياتي تتلىا عليكم فكنتم علىا أعقابكم تنكصون"
    },
    {
      "surah_number": 23,
      "verse_number": 67,
      "content": "مستكبرين به سامرا تهجرون"
    },
    {
      "surah_number": 23,
      "verse_number": 68,
      "content": "أفلم يدبروا القول أم جاهم ما لم يأت اباهم الأولين"
    },
    {
      "surah_number": 23,
      "verse_number": 69,
      "content": "أم لم يعرفوا رسولهم فهم له منكرون"
    },
    {
      "surah_number": 23,
      "verse_number": 70,
      "content": "أم يقولون به جنه بل جاهم بالحق وأكثرهم للحق كارهون"
    },
    {
      "surah_number": 23,
      "verse_number": 71,
      "content": "ولو اتبع الحق أهواهم لفسدت السماوات والأرض ومن فيهن بل أتيناهم بذكرهم فهم عن ذكرهم معرضون"
    },
    {
      "surah_number": 23,
      "verse_number": 72,
      "content": "أم تسٔلهم خرجا فخراج ربك خير وهو خير الرازقين"
    },
    {
      "surah_number": 23,
      "verse_number": 73,
      "content": "وانك لتدعوهم الىا صراط مستقيم"
    },
    {
      "surah_number": 23,
      "verse_number": 74,
      "content": "وان الذين لا يؤمنون بالأخره عن الصراط لناكبون"
    },
    {
      "surah_number": 23,
      "verse_number": 75,
      "content": "ولو رحمناهم وكشفنا ما بهم من ضر للجوا في طغيانهم يعمهون"
    },
    {
      "surah_number": 23,
      "verse_number": 76,
      "content": "ولقد أخذناهم بالعذاب فما استكانوا لربهم وما يتضرعون"
    },
    {
      "surah_number": 23,
      "verse_number": 77,
      "content": "حتىا اذا فتحنا عليهم بابا ذا عذاب شديد اذا هم فيه مبلسون"
    },
    {
      "surah_number": 23,
      "verse_number": 78,
      "content": "وهو الذي أنشأ لكم السمع والأبصار والأفٔده قليلا ما تشكرون"
    },
    {
      "surah_number": 23,
      "verse_number": 79,
      "content": "وهو الذي ذرأكم في الأرض واليه تحشرون"
    },
    {
      "surah_number": 23,
      "verse_number": 80,
      "content": "وهو الذي يحي ويميت وله اختلاف اليل والنهار أفلا تعقلون"
    },
    {
      "surah_number": 23,
      "verse_number": 81,
      "content": "بل قالوا مثل ما قال الأولون"
    },
    {
      "surah_number": 23,
      "verse_number": 82,
      "content": "قالوا أذا متنا وكنا ترابا وعظاما أنا لمبعوثون"
    },
    {
      "surah_number": 23,
      "verse_number": 83,
      "content": "لقد وعدنا نحن واباؤنا هاذا من قبل ان هاذا الا أساطير الأولين"
    },
    {
      "surah_number": 23,
      "verse_number": 84,
      "content": "قل لمن الأرض ومن فيها ان كنتم تعلمون"
    },
    {
      "surah_number": 23,
      "verse_number": 85,
      "content": "سيقولون لله قل أفلا تذكرون"
    },
    {
      "surah_number": 23,
      "verse_number": 86,
      "content": "قل من رب السماوات السبع ورب العرش العظيم"
    },
    {
      "surah_number": 23,
      "verse_number": 87,
      "content": "سيقولون لله قل أفلا تتقون"
    },
    {
      "surah_number": 23,
      "verse_number": 88,
      "content": "قل من بيده ملكوت كل شي وهو يجير ولا يجار عليه ان كنتم تعلمون"
    },
    {
      "surah_number": 23,
      "verse_number": 89,
      "content": "سيقولون لله قل فأنىا تسحرون"
    },
    {
      "surah_number": 23,
      "verse_number": 90,
      "content": "بل أتيناهم بالحق وانهم لكاذبون"
    },
    {
      "surah_number": 23,
      "verse_number": 91,
      "content": "ما اتخذ الله من ولد وما كان معه من الاه اذا لذهب كل الاه بما خلق ولعلا بعضهم علىا بعض سبحان الله عما يصفون"
    },
    {
      "surah_number": 23,
      "verse_number": 92,
      "content": "عالم الغيب والشهاده فتعالىا عما يشركون"
    },
    {
      "surah_number": 23,
      "verse_number": 93,
      "content": "قل رب اما تريني ما يوعدون"
    },
    {
      "surah_number": 23,
      "verse_number": 94,
      "content": "رب فلا تجعلني في القوم الظالمين"
    },
    {
      "surah_number": 23,
      "verse_number": 95,
      "content": "وانا علىا أن نريك ما نعدهم لقادرون"
    },
    {
      "surah_number": 23,
      "verse_number": 96,
      "content": "ادفع بالتي هي أحسن السيئه نحن أعلم بما يصفون"
    },
    {
      "surah_number": 23,
      "verse_number": 97,
      "content": "وقل رب أعوذ بك من همزات الشياطين"
    },
    {
      "surah_number": 23,
      "verse_number": 98,
      "content": "وأعوذ بك رب أن يحضرون"
    },
    {
      "surah_number": 23,
      "verse_number": 99,
      "content": "حتىا اذا جا أحدهم الموت قال رب ارجعون"
    },
    {
      "surah_number": 23,
      "verse_number": 100,
      "content": "لعلي أعمل صالحا فيما تركت كلا انها كلمه هو قائلها ومن ورائهم برزخ الىا يوم يبعثون"
    },
    {
      "surah_number": 23,
      "verse_number": 101,
      "content": "فاذا نفخ في الصور فلا أنساب بينهم يومئذ ولا يتسالون"
    },
    {
      "surah_number": 23,
      "verse_number": 102,
      "content": "فمن ثقلت موازينه فأولائك هم المفلحون"
    },
    {
      "surah_number": 23,
      "verse_number": 103,
      "content": "ومن خفت موازينه فأولائك الذين خسروا أنفسهم في جهنم خالدون"
    },
    {
      "surah_number": 23,
      "verse_number": 104,
      "content": "تلفح وجوههم النار وهم فيها كالحون"
    },
    {
      "surah_number": 23,
      "verse_number": 105,
      "content": "ألم تكن اياتي تتلىا عليكم فكنتم بها تكذبون"
    },
    {
      "surah_number": 23,
      "verse_number": 106,
      "content": "قالوا ربنا غلبت علينا شقوتنا وكنا قوما ضالين"
    },
    {
      "surah_number": 23,
      "verse_number": 107,
      "content": "ربنا أخرجنا منها فان عدنا فانا ظالمون"
    },
    {
      "surah_number": 23,
      "verse_number": 108,
      "content": "قال اخسٔوا فيها ولا تكلمون"
    },
    {
      "surah_number": 23,
      "verse_number": 109,
      "content": "انه كان فريق من عبادي يقولون ربنا امنا فاغفر لنا وارحمنا وأنت خير الراحمين"
    },
    {
      "surah_number": 23,
      "verse_number": 110,
      "content": "فاتخذتموهم سخريا حتىا أنسوكم ذكري وكنتم منهم تضحكون"
    },
    {
      "surah_number": 23,
      "verse_number": 111,
      "content": "اني جزيتهم اليوم بما صبروا أنهم هم الفائزون"
    },
    {
      "surah_number": 23,
      "verse_number": 112,
      "content": "قال كم لبثتم في الأرض عدد سنين"
    },
    {
      "surah_number": 23,
      "verse_number": 113,
      "content": "قالوا لبثنا يوما أو بعض يوم فسٔل العادين"
    },
    {
      "surah_number": 23,
      "verse_number": 114,
      "content": "قال ان لبثتم الا قليلا لو أنكم كنتم تعلمون"
    },
    {
      "surah_number": 23,
      "verse_number": 115,
      "content": "أفحسبتم أنما خلقناكم عبثا وأنكم الينا لا ترجعون"
    },
    {
      "surah_number": 23,
      "verse_number": 116,
      "content": "فتعالى الله الملك الحق لا الاه الا هو رب العرش الكريم"
    },
    {
      "surah_number": 23,
      "verse_number": 117,
      "content": "ومن يدع مع الله الاها اخر لا برهان له به فانما حسابه عند ربه انه لا يفلح الكافرون"
    },
    {
      "surah_number": 23,
      "verse_number": 118,
      "content": "وقل رب اغفر وارحم وأنت خير الراحمين"
    },
    {
      "surah_number": 24,
      "verse_number": 1,
      "content": "سوره أنزلناها وفرضناها وأنزلنا فيها ايات بينات لعلكم تذكرون"
    },
    {
      "surah_number": 24,
      "verse_number": 2,
      "content": "الزانيه والزاني فاجلدوا كل واحد منهما مائه جلده ولا تأخذكم بهما رأفه في دين الله ان كنتم تؤمنون بالله واليوم الأخر وليشهد عذابهما طائفه من المؤمنين"
    },
    {
      "surah_number": 24,
      "verse_number": 3,
      "content": "الزاني لا ينكح الا زانيه أو مشركه والزانيه لا ينكحها الا زان أو مشرك وحرم ذالك على المؤمنين"
    },
    {
      "surah_number": 24,
      "verse_number": 4,
      "content": "والذين يرمون المحصنات ثم لم يأتوا بأربعه شهدا فاجلدوهم ثمانين جلده ولا تقبلوا لهم شهاده أبدا وأولائك هم الفاسقون"
    },
    {
      "surah_number": 24,
      "verse_number": 5,
      "content": "الا الذين تابوا من بعد ذالك وأصلحوا فان الله غفور رحيم"
    },
    {
      "surah_number": 24,
      "verse_number": 6,
      "content": "والذين يرمون أزواجهم ولم يكن لهم شهدا الا أنفسهم فشهاده أحدهم أربع شهادات بالله انه لمن الصادقين"
    },
    {
      "surah_number": 24,
      "verse_number": 7,
      "content": "والخامسه أن لعنت الله عليه ان كان من الكاذبين"
    },
    {
      "surah_number": 24,
      "verse_number": 8,
      "content": "ويدرؤا عنها العذاب أن تشهد أربع شهادات بالله انه لمن الكاذبين"
    },
    {
      "surah_number": 24,
      "verse_number": 9,
      "content": "والخامسه أن غضب الله عليها ان كان من الصادقين"
    },
    {
      "surah_number": 24,
      "verse_number": 10,
      "content": "ولولا فضل الله عليكم ورحمته وأن الله تواب حكيم"
    },
    {
      "surah_number": 24,
      "verse_number": 11,
      "content": "ان الذين جاو بالافك عصبه منكم لا تحسبوه شرا لكم بل هو خير لكم لكل امري منهم ما اكتسب من الاثم والذي تولىا كبره منهم له عذاب عظيم"
    },
    {
      "surah_number": 24,
      "verse_number": 12,
      "content": "لولا اذ سمعتموه ظن المؤمنون والمؤمنات بأنفسهم خيرا وقالوا هاذا افك مبين"
    },
    {
      "surah_number": 24,
      "verse_number": 13,
      "content": "لولا جاو عليه بأربعه شهدا فاذ لم يأتوا بالشهدا فأولائك عند الله هم الكاذبون"
    },
    {
      "surah_number": 24,
      "verse_number": 14,
      "content": "ولولا فضل الله عليكم ورحمته في الدنيا والأخره لمسكم في ما أفضتم فيه عذاب عظيم"
    },
    {
      "surah_number": 24,
      "verse_number": 15,
      "content": "اذ تلقونه بألسنتكم وتقولون بأفواهكم ما ليس لكم به علم وتحسبونه هينا وهو عند الله عظيم"
    },
    {
      "surah_number": 24,
      "verse_number": 16,
      "content": "ولولا اذ سمعتموه قلتم ما يكون لنا أن نتكلم بهاذا سبحانك هاذا بهتان عظيم"
    },
    {
      "surah_number": 24,
      "verse_number": 17,
      "content": "يعظكم الله أن تعودوا لمثله أبدا ان كنتم مؤمنين"
    },
    {
      "surah_number": 24,
      "verse_number": 18,
      "content": "ويبين الله لكم الأيات والله عليم حكيم"
    },
    {
      "surah_number": 24,
      "verse_number": 19,
      "content": "ان الذين يحبون أن تشيع الفاحشه في الذين امنوا لهم عذاب أليم في الدنيا والأخره والله يعلم وأنتم لا تعلمون"
    },
    {
      "surah_number": 24,
      "verse_number": 20,
      "content": "ولولا فضل الله عليكم ورحمته وأن الله روف رحيم"
    },
    {
      "surah_number": 24,
      "verse_number": 21,
      "content": "ياأيها الذين امنوا لا تتبعوا خطوات الشيطان ومن يتبع خطوات الشيطان فانه يأمر بالفحشا والمنكر ولولا فضل الله عليكم ورحمته ما زكىا منكم من أحد أبدا ولاكن الله يزكي من يشا والله سميع عليم"
    },
    {
      "surah_number": 24,
      "verse_number": 22,
      "content": "ولا يأتل أولوا الفضل منكم والسعه أن يؤتوا أولي القربىا والمساكين والمهاجرين في سبيل الله وليعفوا وليصفحوا ألا تحبون أن يغفر الله لكم والله غفور رحيم"
    },
    {
      "surah_number": 24,
      "verse_number": 23,
      "content": "ان الذين يرمون المحصنات الغافلات المؤمنات لعنوا في الدنيا والأخره ولهم عذاب عظيم"
    },
    {
      "surah_number": 24,
      "verse_number": 24,
      "content": "يوم تشهد عليهم ألسنتهم وأيديهم وأرجلهم بما كانوا يعملون"
    },
    {
      "surah_number": 24,
      "verse_number": 25,
      "content": "يومئذ يوفيهم الله دينهم الحق ويعلمون أن الله هو الحق المبين"
    },
    {
      "surah_number": 24,
      "verse_number": 26,
      "content": "الخبيثات للخبيثين والخبيثون للخبيثات والطيبات للطيبين والطيبون للطيبات أولائك مبرون مما يقولون لهم مغفره ورزق كريم"
    },
    {
      "surah_number": 24,
      "verse_number": 27,
      "content": "ياأيها الذين امنوا لا تدخلوا بيوتا غير بيوتكم حتىا تستأنسوا وتسلموا علىا أهلها ذالكم خير لكم لعلكم تذكرون"
    },
    {
      "surah_number": 24,
      "verse_number": 28,
      "content": "فان لم تجدوا فيها أحدا فلا تدخلوها حتىا يؤذن لكم وان قيل لكم ارجعوا فارجعوا هو أزكىا لكم والله بما تعملون عليم"
    },
    {
      "surah_number": 24,
      "verse_number": 29,
      "content": "ليس عليكم جناح أن تدخلوا بيوتا غير مسكونه فيها متاع لكم والله يعلم ما تبدون وما تكتمون"
    },
    {
      "surah_number": 24,
      "verse_number": 30,
      "content": "قل للمؤمنين يغضوا من أبصارهم ويحفظوا فروجهم ذالك أزكىا لهم ان الله خبير بما يصنعون"
    },
    {
      "surah_number": 24,
      "verse_number": 31,
      "content": "وقل للمؤمنات يغضضن من أبصارهن ويحفظن فروجهن ولا يبدين زينتهن الا ما ظهر منها وليضربن بخمرهن علىا جيوبهن ولا يبدين زينتهن الا لبعولتهن أو ابائهن أو ابا بعولتهن أو أبنائهن أو أبنا بعولتهن أو اخوانهن أو بني اخوانهن أو بني أخواتهن أو نسائهن أو ما ملكت أيمانهن أو التابعين غير أولي الاربه من الرجال أو الطفل الذين لم يظهروا علىا عورات النسا ولا يضربن بأرجلهن ليعلم ما يخفين من زينتهن وتوبوا الى الله جميعا أيه المؤمنون لعلكم تفلحون"
    },
    {
      "surah_number": 24,
      "verse_number": 32,
      "content": "وأنكحوا الأيامىا منكم والصالحين من عبادكم وامائكم ان يكونوا فقرا يغنهم الله من فضله والله واسع عليم"
    },
    {
      "surah_number": 24,
      "verse_number": 33,
      "content": "وليستعفف الذين لا يجدون نكاحا حتىا يغنيهم الله من فضله والذين يبتغون الكتاب مما ملكت أيمانكم فكاتبوهم ان علمتم فيهم خيرا واتوهم من مال الله الذي اتىاكم ولا تكرهوا فتياتكم على البغا ان أردن تحصنا لتبتغوا عرض الحيواه الدنيا ومن يكرههن فان الله من بعد اكراههن غفور رحيم"
    },
    {
      "surah_number": 24,
      "verse_number": 34,
      "content": "ولقد أنزلنا اليكم ايات مبينات ومثلا من الذين خلوا من قبلكم وموعظه للمتقين"
    },
    {
      "surah_number": 24,
      "verse_number": 35,
      "content": "الله نور السماوات والأرض مثل نوره كمشكواه فيها مصباح المصباح في زجاجه الزجاجه كأنها كوكب دري يوقد من شجره مباركه زيتونه لا شرقيه ولا غربيه يكاد زيتها يضي ولو لم تمسسه نار نور علىا نور يهدي الله لنوره من يشا ويضرب الله الأمثال للناس والله بكل شي عليم"
    },
    {
      "surah_number": 24,
      "verse_number": 36,
      "content": "في بيوت أذن الله أن ترفع ويذكر فيها اسمه يسبح له فيها بالغدو والأصال"
    },
    {
      "surah_number": 24,
      "verse_number": 37,
      "content": "رجال لا تلهيهم تجاره ولا بيع عن ذكر الله واقام الصلواه وايتا الزكواه يخافون يوما تتقلب فيه القلوب والأبصار"
    },
    {
      "surah_number": 24,
      "verse_number": 38,
      "content": "ليجزيهم الله أحسن ما عملوا ويزيدهم من فضله والله يرزق من يشا بغير حساب"
    },
    {
      "surah_number": 24,
      "verse_number": 39,
      "content": "والذين كفروا أعمالهم كسراب بقيعه يحسبه الظمٔان ما حتىا اذا جاه لم يجده شئا ووجد الله عنده فوفىاه حسابه والله سريع الحساب"
    },
    {
      "surah_number": 24,
      "verse_number": 40,
      "content": "أو كظلمات في بحر لجي يغشىاه موج من فوقه موج من فوقه سحاب ظلمات بعضها فوق بعض اذا أخرج يده لم يكد يرىاها ومن لم يجعل الله له نورا فما له من نور"
    },
    {
      "surah_number": 24,
      "verse_number": 41,
      "content": "ألم تر أن الله يسبح له من في السماوات والأرض والطير صافات كل قد علم صلاته وتسبيحه والله عليم بما يفعلون"
    },
    {
      "surah_number": 24,
      "verse_number": 42,
      "content": "ولله ملك السماوات والأرض والى الله المصير"
    },
    {
      "surah_number": 24,
      "verse_number": 43,
      "content": "ألم تر أن الله يزجي سحابا ثم يؤلف بينه ثم يجعله ركاما فترى الودق يخرج من خلاله وينزل من السما من جبال فيها من برد فيصيب به من يشا ويصرفه عن من يشا يكاد سنا برقه يذهب بالأبصار"
    },
    {
      "surah_number": 24,
      "verse_number": 44,
      "content": "يقلب الله اليل والنهار ان في ذالك لعبره لأولي الأبصار"
    },
    {
      "surah_number": 24,
      "verse_number": 45,
      "content": "والله خلق كل دابه من ما فمنهم من يمشي علىا بطنه ومنهم من يمشي علىا رجلين ومنهم من يمشي علىا أربع يخلق الله ما يشا ان الله علىا كل شي قدير"
    },
    {
      "surah_number": 24,
      "verse_number": 46,
      "content": "لقد أنزلنا ايات مبينات والله يهدي من يشا الىا صراط مستقيم"
    },
    {
      "surah_number": 24,
      "verse_number": 47,
      "content": "ويقولون امنا بالله وبالرسول وأطعنا ثم يتولىا فريق منهم من بعد ذالك وما أولائك بالمؤمنين"
    },
    {
      "surah_number": 24,
      "verse_number": 48,
      "content": "واذا دعوا الى الله ورسوله ليحكم بينهم اذا فريق منهم معرضون"
    },
    {
      "surah_number": 24,
      "verse_number": 49,
      "content": "وان يكن لهم الحق يأتوا اليه مذعنين"
    },
    {
      "surah_number": 24,
      "verse_number": 50,
      "content": "أفي قلوبهم مرض أم ارتابوا أم يخافون أن يحيف الله عليهم ورسوله بل أولائك هم الظالمون"
    },
    {
      "surah_number": 24,
      "verse_number": 51,
      "content": "انما كان قول المؤمنين اذا دعوا الى الله ورسوله ليحكم بينهم أن يقولوا سمعنا وأطعنا وأولائك هم المفلحون"
    },
    {
      "surah_number": 24,
      "verse_number": 52,
      "content": "ومن يطع الله ورسوله ويخش الله ويتقه فأولائك هم الفائزون"
    },
    {
      "surah_number": 24,
      "verse_number": 53,
      "content": "وأقسموا بالله جهد أيمانهم لئن أمرتهم ليخرجن قل لا تقسموا طاعه معروفه ان الله خبير بما تعملون"
    },
    {
      "surah_number": 24,
      "verse_number": 54,
      "content": "قل أطيعوا الله وأطيعوا الرسول فان تولوا فانما عليه ما حمل وعليكم ما حملتم وان تطيعوه تهتدوا وما على الرسول الا البلاغ المبين"
    },
    {
      "surah_number": 24,
      "verse_number": 55,
      "content": "وعد الله الذين امنوا منكم وعملوا الصالحات ليستخلفنهم في الأرض كما استخلف الذين من قبلهم وليمكنن لهم دينهم الذي ارتضىا لهم وليبدلنهم من بعد خوفهم أمنا يعبدونني لا يشركون بي شئا ومن كفر بعد ذالك فأولائك هم الفاسقون"
    },
    {
      "surah_number": 24,
      "verse_number": 56,
      "content": "وأقيموا الصلواه واتوا الزكواه وأطيعوا الرسول لعلكم ترحمون"
    },
    {
      "surah_number": 24,
      "verse_number": 57,
      "content": "لا تحسبن الذين كفروا معجزين في الأرض ومأوىاهم النار ولبئس المصير"
    },
    {
      "surah_number": 24,
      "verse_number": 58,
      "content": "ياأيها الذين امنوا ليستٔذنكم الذين ملكت أيمانكم والذين لم يبلغوا الحلم منكم ثلاث مرات من قبل صلواه الفجر وحين تضعون ثيابكم من الظهيره ومن بعد صلواه العشا ثلاث عورات لكم ليس عليكم ولا عليهم جناح بعدهن طوافون عليكم بعضكم علىا بعض كذالك يبين الله لكم الأيات والله عليم حكيم"
    },
    {
      "surah_number": 24,
      "verse_number": 59,
      "content": "واذا بلغ الأطفال منكم الحلم فليستٔذنوا كما استٔذن الذين من قبلهم كذالك يبين الله لكم اياته والله عليم حكيم"
    },
    {
      "surah_number": 24,
      "verse_number": 60,
      "content": "والقواعد من النسا الاتي لا يرجون نكاحا فليس عليهن جناح أن يضعن ثيابهن غير متبرجات بزينه وأن يستعففن خير لهن والله سميع عليم"
    },
    {
      "surah_number": 24,
      "verse_number": 61,
      "content": "ليس على الأعمىا حرج ولا على الأعرج حرج ولا على المريض حرج ولا علىا أنفسكم أن تأكلوا من بيوتكم أو بيوت ابائكم أو بيوت أمهاتكم أو بيوت اخوانكم أو بيوت أخواتكم أو بيوت أعمامكم أو بيوت عماتكم أو بيوت أخوالكم أو بيوت خالاتكم أو ما ملكتم مفاتحه أو صديقكم ليس عليكم جناح أن تأكلوا جميعا أو أشتاتا فاذا دخلتم بيوتا فسلموا علىا أنفسكم تحيه من عند الله مباركه طيبه كذالك يبين الله لكم الأيات لعلكم تعقلون"
    },
    {
      "surah_number": 24,
      "verse_number": 62,
      "content": "انما المؤمنون الذين امنوا بالله ورسوله واذا كانوا معه علىا أمر جامع لم يذهبوا حتىا يستٔذنوه ان الذين يستٔذنونك أولائك الذين يؤمنون بالله ورسوله فاذا استٔذنوك لبعض شأنهم فأذن لمن شئت منهم واستغفر لهم الله ان الله غفور رحيم"
    },
    {
      "surah_number": 24,
      "verse_number": 63,
      "content": "لا تجعلوا دعا الرسول بينكم كدعا بعضكم بعضا قد يعلم الله الذين يتسللون منكم لواذا فليحذر الذين يخالفون عن أمره أن تصيبهم فتنه أو يصيبهم عذاب أليم"
    },
    {
      "surah_number": 24,
      "verse_number": 64,
      "content": "ألا ان لله ما في السماوات والأرض قد يعلم ما أنتم عليه ويوم يرجعون اليه فينبئهم بما عملوا والله بكل شي عليم"
    },
    {
      "surah_number": 25,
      "verse_number": 1,
      "content": "تبارك الذي نزل الفرقان علىا عبده ليكون للعالمين نذيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 2,
      "content": "الذي له ملك السماوات والأرض ولم يتخذ ولدا ولم يكن له شريك في الملك وخلق كل شي فقدره تقديرا"
    },
    {
      "surah_number": 25,
      "verse_number": 3,
      "content": "واتخذوا من دونه الهه لا يخلقون شئا وهم يخلقون ولا يملكون لأنفسهم ضرا ولا نفعا ولا يملكون موتا ولا حيواه ولا نشورا"
    },
    {
      "surah_number": 25,
      "verse_number": 4,
      "content": "وقال الذين كفروا ان هاذا الا افك افترىاه وأعانه عليه قوم اخرون فقد جاو ظلما وزورا"
    },
    {
      "surah_number": 25,
      "verse_number": 5,
      "content": "وقالوا أساطير الأولين اكتتبها فهي تملىا عليه بكره وأصيلا"
    },
    {
      "surah_number": 25,
      "verse_number": 6,
      "content": "قل أنزله الذي يعلم السر في السماوات والأرض انه كان غفورا رحيما"
    },
    {
      "surah_number": 25,
      "verse_number": 7,
      "content": "وقالوا مال هاذا الرسول يأكل الطعام ويمشي في الأسواق لولا أنزل اليه ملك فيكون معه نذيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 8,
      "content": "أو يلقىا اليه كنز أو تكون له جنه يأكل منها وقال الظالمون ان تتبعون الا رجلا مسحورا"
    },
    {
      "surah_number": 25,
      "verse_number": 9,
      "content": "انظر كيف ضربوا لك الأمثال فضلوا فلا يستطيعون سبيلا"
    },
    {
      "surah_number": 25,
      "verse_number": 10,
      "content": "تبارك الذي ان شا جعل لك خيرا من ذالك جنات تجري من تحتها الأنهار ويجعل لك قصورا"
    },
    {
      "surah_number": 25,
      "verse_number": 11,
      "content": "بل كذبوا بالساعه وأعتدنا لمن كذب بالساعه سعيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 12,
      "content": "اذا رأتهم من مكان بعيد سمعوا لها تغيظا وزفيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 13,
      "content": "واذا ألقوا منها مكانا ضيقا مقرنين دعوا هنالك ثبورا"
    },
    {
      "surah_number": 25,
      "verse_number": 14,
      "content": "لا تدعوا اليوم ثبورا واحدا وادعوا ثبورا كثيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 15,
      "content": "قل أذالك خير أم جنه الخلد التي وعد المتقون كانت لهم جزا ومصيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 16,
      "content": "لهم فيها ما يشاون خالدين كان علىا ربك وعدا مسٔولا"
    },
    {
      "surah_number": 25,
      "verse_number": 17,
      "content": "ويوم يحشرهم وما يعبدون من دون الله فيقول ءأنتم أضللتم عبادي هاؤلا أم هم ضلوا السبيل"
    },
    {
      "surah_number": 25,
      "verse_number": 18,
      "content": "قالوا سبحانك ما كان ينبغي لنا أن نتخذ من دونك من أوليا ولاكن متعتهم واباهم حتىا نسوا الذكر وكانوا قوما بورا"
    },
    {
      "surah_number": 25,
      "verse_number": 19,
      "content": "فقد كذبوكم بما تقولون فما تستطيعون صرفا ولا نصرا ومن يظلم منكم نذقه عذابا كبيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 20,
      "content": "وما أرسلنا قبلك من المرسلين الا انهم ليأكلون الطعام ويمشون في الأسواق وجعلنا بعضكم لبعض فتنه أتصبرون وكان ربك بصيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 21,
      "content": "وقال الذين لا يرجون لقانا لولا أنزل علينا الملائكه أو نرىا ربنا لقد استكبروا في أنفسهم وعتو عتوا كبيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 22,
      "content": "يوم يرون الملائكه لا بشرىا يومئذ للمجرمين ويقولون حجرا محجورا"
    },
    {
      "surah_number": 25,
      "verse_number": 23,
      "content": "وقدمنا الىا ما عملوا من عمل فجعلناه هبا منثورا"
    },
    {
      "surah_number": 25,
      "verse_number": 24,
      "content": "أصحاب الجنه يومئذ خير مستقرا وأحسن مقيلا"
    },
    {
      "surah_number": 25,
      "verse_number": 25,
      "content": "ويوم تشقق السما بالغمام ونزل الملائكه تنزيلا"
    },
    {
      "surah_number": 25,
      "verse_number": 26,
      "content": "الملك يومئذ الحق للرحمان وكان يوما على الكافرين عسيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 27,
      "content": "ويوم يعض الظالم علىا يديه يقول ياليتني اتخذت مع الرسول سبيلا"
    },
    {
      "surah_number": 25,
      "verse_number": 28,
      "content": "ياويلتىا ليتني لم أتخذ فلانا خليلا"
    },
    {
      "surah_number": 25,
      "verse_number": 29,
      "content": "لقد أضلني عن الذكر بعد اذ جاني وكان الشيطان للانسان خذولا"
    },
    {
      "surah_number": 25,
      "verse_number": 30,
      "content": "وقال الرسول يارب ان قومي اتخذوا هاذا القران مهجورا"
    },
    {
      "surah_number": 25,
      "verse_number": 31,
      "content": "وكذالك جعلنا لكل نبي عدوا من المجرمين وكفىا بربك هاديا ونصيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 32,
      "content": "وقال الذين كفروا لولا نزل عليه القران جمله واحده كذالك لنثبت به فؤادك ورتلناه ترتيلا"
    },
    {
      "surah_number": 25,
      "verse_number": 33,
      "content": "ولا يأتونك بمثل الا جئناك بالحق وأحسن تفسيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 34,
      "content": "الذين يحشرون علىا وجوههم الىا جهنم أولائك شر مكانا وأضل سبيلا"
    },
    {
      "surah_number": 25,
      "verse_number": 35,
      "content": "ولقد اتينا موسى الكتاب وجعلنا معه أخاه هارون وزيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 36,
      "content": "فقلنا اذهبا الى القوم الذين كذبوا بٔاياتنا فدمرناهم تدميرا"
    },
    {
      "surah_number": 25,
      "verse_number": 37,
      "content": "وقوم نوح لما كذبوا الرسل أغرقناهم وجعلناهم للناس ايه وأعتدنا للظالمين عذابا أليما"
    },
    {
      "surah_number": 25,
      "verse_number": 38,
      "content": "وعادا وثمودا وأصحاب الرس وقرونا بين ذالك كثيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 39,
      "content": "وكلا ضربنا له الأمثال وكلا تبرنا تتبيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 40,
      "content": "ولقد أتوا على القريه التي أمطرت مطر السو أفلم يكونوا يرونها بل كانوا لا يرجون نشورا"
    },
    {
      "surah_number": 25,
      "verse_number": 41,
      "content": "واذا رأوك ان يتخذونك الا هزوا أهاذا الذي بعث الله رسولا"
    },
    {
      "surah_number": 25,
      "verse_number": 42,
      "content": "ان كاد ليضلنا عن الهتنا لولا أن صبرنا عليها وسوف يعلمون حين يرون العذاب من أضل سبيلا"
    },
    {
      "surah_number": 25,
      "verse_number": 43,
      "content": "أريت من اتخذ الاهه هوىاه أفأنت تكون عليه وكيلا"
    },
    {
      "surah_number": 25,
      "verse_number": 44,
      "content": "أم تحسب أن أكثرهم يسمعون أو يعقلون ان هم الا كالأنعام بل هم أضل سبيلا"
    },
    {
      "surah_number": 25,
      "verse_number": 45,
      "content": "ألم تر الىا ربك كيف مد الظل ولو شا لجعله ساكنا ثم جعلنا الشمس عليه دليلا"
    },
    {
      "surah_number": 25,
      "verse_number": 46,
      "content": "ثم قبضناه الينا قبضا يسيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 47,
      "content": "وهو الذي جعل لكم اليل لباسا والنوم سباتا وجعل النهار نشورا"
    },
    {
      "surah_number": 25,
      "verse_number": 48,
      "content": "وهو الذي أرسل الرياح بشرا بين يدي رحمته وأنزلنا من السما ما طهورا"
    },
    {
      "surah_number": 25,
      "verse_number": 49,
      "content": "لنحي به بلده ميتا ونسقيه مما خلقنا أنعاما وأناسي كثيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 50,
      "content": "ولقد صرفناه بينهم ليذكروا فأبىا أكثر الناس الا كفورا"
    },
    {
      "surah_number": 25,
      "verse_number": 51,
      "content": "ولو شئنا لبعثنا في كل قريه نذيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 52,
      "content": "فلا تطع الكافرين وجاهدهم به جهادا كبيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 53,
      "content": "وهو الذي مرج البحرين هاذا عذب فرات وهاذا ملح أجاج وجعل بينهما برزخا وحجرا محجورا"
    },
    {
      "surah_number": 25,
      "verse_number": 54,
      "content": "وهو الذي خلق من الما بشرا فجعله نسبا وصهرا وكان ربك قديرا"
    },
    {
      "surah_number": 25,
      "verse_number": 55,
      "content": "ويعبدون من دون الله ما لا ينفعهم ولا يضرهم وكان الكافر علىا ربه ظهيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 56,
      "content": "وما أرسلناك الا مبشرا ونذيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 57,
      "content": "قل ما أسٔلكم عليه من أجر الا من شا أن يتخذ الىا ربه سبيلا"
    },
    {
      "surah_number": 25,
      "verse_number": 58,
      "content": "وتوكل على الحي الذي لا يموت وسبح بحمده وكفىا به بذنوب عباده خبيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 59,
      "content": "الذي خلق السماوات والأرض وما بينهما في سته أيام ثم استوىا على العرش الرحمان فسٔل به خبيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 60,
      "content": "واذا قيل لهم اسجدوا للرحمان قالوا وما الرحمان أنسجد لما تأمرنا وزادهم نفورا"
    },
    {
      "surah_number": 25,
      "verse_number": 61,
      "content": "تبارك الذي جعل في السما بروجا وجعل فيها سراجا وقمرا منيرا"
    },
    {
      "surah_number": 25,
      "verse_number": 62,
      "content": "وهو الذي جعل اليل والنهار خلفه لمن أراد أن يذكر أو أراد شكورا"
    },
    {
      "surah_number": 25,
      "verse_number": 63,
      "content": "وعباد الرحمان الذين يمشون على الأرض هونا واذا خاطبهم الجاهلون قالوا سلاما"
    },
    {
      "surah_number": 25,
      "verse_number": 64,
      "content": "والذين يبيتون لربهم سجدا وقياما"
    },
    {
      "surah_number": 25,
      "verse_number": 65,
      "content": "والذين يقولون ربنا اصرف عنا عذاب جهنم ان عذابها كان غراما"
    },
    {
      "surah_number": 25,
      "verse_number": 66,
      "content": "انها سات مستقرا ومقاما"
    },
    {
      "surah_number": 25,
      "verse_number": 67,
      "content": "والذين اذا أنفقوا لم يسرفوا ولم يقتروا وكان بين ذالك قواما"
    },
    {
      "surah_number": 25,
      "verse_number": 68,
      "content": "والذين لا يدعون مع الله الاها اخر ولا يقتلون النفس التي حرم الله الا بالحق ولا يزنون ومن يفعل ذالك يلق أثاما"
    },
    {
      "surah_number": 25,
      "verse_number": 69,
      "content": "يضاعف له العذاب يوم القيامه ويخلد فيه مهانا"
    },
    {
      "surah_number": 25,
      "verse_number": 70,
      "content": "الا من تاب وامن وعمل عملا صالحا فأولائك يبدل الله سئاتهم حسنات وكان الله غفورا رحيما"
    },
    {
      "surah_number": 25,
      "verse_number": 71,
      "content": "ومن تاب وعمل صالحا فانه يتوب الى الله متابا"
    },
    {
      "surah_number": 25,
      "verse_number": 72,
      "content": "والذين لا يشهدون الزور واذا مروا باللغو مروا كراما"
    },
    {
      "surah_number": 25,
      "verse_number": 73,
      "content": "والذين اذا ذكروا بٔايات ربهم لم يخروا عليها صما وعميانا"
    },
    {
      "surah_number": 25,
      "verse_number": 74,
      "content": "والذين يقولون ربنا هب لنا من أزواجنا وذرياتنا قره أعين واجعلنا للمتقين اماما"
    },
    {
      "surah_number": 25,
      "verse_number": 75,
      "content": "أولائك يجزون الغرفه بما صبروا ويلقون فيها تحيه وسلاما"
    },
    {
      "surah_number": 25,
      "verse_number": 76,
      "content": "خالدين فيها حسنت مستقرا ومقاما"
    },
    {
      "surah_number": 25,
      "verse_number": 77,
      "content": "قل ما يعبؤا بكم ربي لولا دعاؤكم فقد كذبتم فسوف يكون لزاما"
    },
    {
      "surah_number": 26,
      "verse_number": 1,
      "content": "طسم"
    },
    {
      "surah_number": 26,
      "verse_number": 2,
      "content": "تلك ايات الكتاب المبين"
    },
    {
      "surah_number": 26,
      "verse_number": 3,
      "content": "لعلك باخع نفسك ألا يكونوا مؤمنين"
    },
    {
      "surah_number": 26,
      "verse_number": 4,
      "content": "ان نشأ ننزل عليهم من السما ايه فظلت أعناقهم لها خاضعين"
    },
    {
      "surah_number": 26,
      "verse_number": 5,
      "content": "وما يأتيهم من ذكر من الرحمان محدث الا كانوا عنه معرضين"
    },
    {
      "surah_number": 26,
      "verse_number": 6,
      "content": "فقد كذبوا فسيأتيهم أنباؤا ما كانوا به يستهزون"
    },
    {
      "surah_number": 26,
      "verse_number": 7,
      "content": "أولم يروا الى الأرض كم أنبتنا فيها من كل زوج كريم"
    },
    {
      "surah_number": 26,
      "verse_number": 8,
      "content": "ان في ذالك لأيه وما كان أكثرهم مؤمنين"
    },
    {
      "surah_number": 26,
      "verse_number": 9,
      "content": "وان ربك لهو العزيز الرحيم"
    },
    {
      "surah_number": 26,
      "verse_number": 10,
      "content": "واذ نادىا ربك موسىا أن ائت القوم الظالمين"
    },
    {
      "surah_number": 26,
      "verse_number": 11,
      "content": "قوم فرعون ألا يتقون"
    },
    {
      "surah_number": 26,
      "verse_number": 12,
      "content": "قال رب اني أخاف أن يكذبون"
    },
    {
      "surah_number": 26,
      "verse_number": 13,
      "content": "ويضيق صدري ولا ينطلق لساني فأرسل الىا هارون"
    },
    {
      "surah_number": 26,
      "verse_number": 14,
      "content": "ولهم علي ذنب فأخاف أن يقتلون"
    },
    {
      "surah_number": 26,
      "verse_number": 15,
      "content": "قال كلا فاذهبا بٔاياتنا انا معكم مستمعون"
    },
    {
      "surah_number": 26,
      "verse_number": 16,
      "content": "فأتيا فرعون فقولا انا رسول رب العالمين"
    },
    {
      "surah_number": 26,
      "verse_number": 17,
      "content": "أن أرسل معنا بني اسرايل"
    },
    {
      "surah_number": 26,
      "verse_number": 18,
      "content": "قال ألم نربك فينا وليدا ولبثت فينا من عمرك سنين"
    },
    {
      "surah_number": 26,
      "verse_number": 19,
      "content": "وفعلت فعلتك التي فعلت وأنت من الكافرين"
    },
    {
      "surah_number": 26,
      "verse_number": 20,
      "content": "قال فعلتها اذا وأنا من الضالين"
    },
    {
      "surah_number": 26,
      "verse_number": 21,
      "content": "ففررت منكم لما خفتكم فوهب لي ربي حكما وجعلني من المرسلين"
    },
    {
      "surah_number": 26,
      "verse_number": 22,
      "content": "وتلك نعمه تمنها علي أن عبدت بني اسرايل"
    },
    {
      "surah_number": 26,
      "verse_number": 23,
      "content": "قال فرعون وما رب العالمين"
    },
    {
      "surah_number": 26,
      "verse_number": 24,
      "content": "قال رب السماوات والأرض وما بينهما ان كنتم موقنين"
    },
    {
      "surah_number": 26,
      "verse_number": 25,
      "content": "قال لمن حوله ألا تستمعون"
    },
    {
      "surah_number": 26,
      "verse_number": 26,
      "content": "قال ربكم ورب ابائكم الأولين"
    },
    {
      "surah_number": 26,
      "verse_number": 27,
      "content": "قال ان رسولكم الذي أرسل اليكم لمجنون"
    },
    {
      "surah_number": 26,
      "verse_number": 28,
      "content": "قال رب المشرق والمغرب وما بينهما ان كنتم تعقلون"
    },
    {
      "surah_number": 26,
      "verse_number": 29,
      "content": "قال لئن اتخذت الاها غيري لأجعلنك من المسجونين"
    },
    {
      "surah_number": 26,
      "verse_number": 30,
      "content": "قال أولو جئتك بشي مبين"
    },
    {
      "surah_number": 26,
      "verse_number": 31,
      "content": "قال فأت به ان كنت من الصادقين"
    },
    {
      "surah_number": 26,
      "verse_number": 32,
      "content": "فألقىا عصاه فاذا هي ثعبان مبين"
    },
    {
      "surah_number": 26,
      "verse_number": 33,
      "content": "ونزع يده فاذا هي بيضا للناظرين"
    },
    {
      "surah_number": 26,
      "verse_number": 34,
      "content": "قال للملا حوله ان هاذا لساحر عليم"
    },
    {
      "surah_number": 26,
      "verse_number": 35,
      "content": "يريد أن يخرجكم من أرضكم بسحره فماذا تأمرون"
    },
    {
      "surah_number": 26,
      "verse_number": 36,
      "content": "قالوا أرجه وأخاه وابعث في المدائن حاشرين"
    },
    {
      "surah_number": 26,
      "verse_number": 37,
      "content": "يأتوك بكل سحار عليم"
    },
    {
      "surah_number": 26,
      "verse_number": 38,
      "content": "فجمع السحره لميقات يوم معلوم"
    },
    {
      "surah_number": 26,
      "verse_number": 39,
      "content": "وقيل للناس هل أنتم مجتمعون"
    },
    {
      "surah_number": 26,
      "verse_number": 40,
      "content": "لعلنا نتبع السحره ان كانوا هم الغالبين"
    },
    {
      "surah_number": 26,
      "verse_number": 41,
      "content": "فلما جا السحره قالوا لفرعون أئن لنا لأجرا ان كنا نحن الغالبين"
    },
    {
      "surah_number": 26,
      "verse_number": 42,
      "content": "قال نعم وانكم اذا لمن المقربين"
    },
    {
      "surah_number": 26,
      "verse_number": 43,
      "content": "قال لهم موسىا ألقوا ما أنتم ملقون"
    },
    {
      "surah_number": 26,
      "verse_number": 44,
      "content": "فألقوا حبالهم وعصيهم وقالوا بعزه فرعون انا لنحن الغالبون"
    },
    {
      "surah_number": 26,
      "verse_number": 45,
      "content": "فألقىا موسىا عصاه فاذا هي تلقف ما يأفكون"
    },
    {
      "surah_number": 26,
      "verse_number": 46,
      "content": "فألقي السحره ساجدين"
    },
    {
      "surah_number": 26,
      "verse_number": 47,
      "content": "قالوا امنا برب العالمين"
    },
    {
      "surah_number": 26,
      "verse_number": 48,
      "content": "رب موسىا وهارون"
    },
    {
      "surah_number": 26,
      "verse_number": 49,
      "content": "قال امنتم له قبل أن اذن لكم انه لكبيركم الذي علمكم السحر فلسوف تعلمون لأقطعن أيديكم وأرجلكم من خلاف ولأصلبنكم أجمعين"
    },
    {
      "surah_number": 26,
      "verse_number": 50,
      "content": "قالوا لا ضير انا الىا ربنا منقلبون"
    },
    {
      "surah_number": 26,
      "verse_number": 51,
      "content": "انا نطمع أن يغفر لنا ربنا خطايانا أن كنا أول المؤمنين"
    },
    {
      "surah_number": 26,
      "verse_number": 52,
      "content": "وأوحينا الىا موسىا أن أسر بعبادي انكم متبعون"
    },
    {
      "surah_number": 26,
      "verse_number": 53,
      "content": "فأرسل فرعون في المدائن حاشرين"
    },
    {
      "surah_number": 26,
      "verse_number": 54,
      "content": "ان هاؤلا لشرذمه قليلون"
    },
    {
      "surah_number": 26,
      "verse_number": 55,
      "content": "وانهم لنا لغائظون"
    },
    {
      "surah_number": 26,
      "verse_number": 56,
      "content": "وانا لجميع حاذرون"
    },
    {
      "surah_number": 26,
      "verse_number": 57,
      "content": "فأخرجناهم من جنات وعيون"
    },
    {
      "surah_number": 26,
      "verse_number": 58,
      "content": "وكنوز ومقام كريم"
    },
    {
      "surah_number": 26,
      "verse_number": 59,
      "content": "كذالك وأورثناها بني اسرايل"
    },
    {
      "surah_number": 26,
      "verse_number": 60,
      "content": "فأتبعوهم مشرقين"
    },
    {
      "surah_number": 26,
      "verse_number": 61,
      "content": "فلما تراا الجمعان قال أصحاب موسىا انا لمدركون"
    },
    {
      "surah_number": 26,
      "verse_number": 62,
      "content": "قال كلا ان معي ربي سيهدين"
    },
    {
      "surah_number": 26,
      "verse_number": 63,
      "content": "فأوحينا الىا موسىا أن اضرب بعصاك البحر فانفلق فكان كل فرق كالطود العظيم"
    },
    {
      "surah_number": 26,
      "verse_number": 64,
      "content": "وأزلفنا ثم الأخرين"
    },
    {
      "surah_number": 26,
      "verse_number": 65,
      "content": "وأنجينا موسىا ومن معه أجمعين"
    },
    {
      "surah_number": 26,
      "verse_number": 66,
      "content": "ثم أغرقنا الأخرين"
    },
    {
      "surah_number": 26,
      "verse_number": 67,
      "content": "ان في ذالك لأيه وما كان أكثرهم مؤمنين"
    },
    {
      "surah_number": 26,
      "verse_number": 68,
      "content": "وان ربك لهو العزيز الرحيم"
    },
    {
      "surah_number": 26,
      "verse_number": 69,
      "content": "واتل عليهم نبأ ابراهيم"
    },
    {
      "surah_number": 26,
      "verse_number": 70,
      "content": "اذ قال لأبيه وقومه ما تعبدون"
    },
    {
      "surah_number": 26,
      "verse_number": 71,
      "content": "قالوا نعبد أصناما فنظل لها عاكفين"
    },
    {
      "surah_number": 26,
      "verse_number": 72,
      "content": "قال هل يسمعونكم اذ تدعون"
    },
    {
      "surah_number": 26,
      "verse_number": 73,
      "content": "أو ينفعونكم أو يضرون"
    },
    {
      "surah_number": 26,
      "verse_number": 74,
      "content": "قالوا بل وجدنا ابانا كذالك يفعلون"
    },
    {
      "surah_number": 26,
      "verse_number": 75,
      "content": "قال أفريتم ما كنتم تعبدون"
    },
    {
      "surah_number": 26,
      "verse_number": 76,
      "content": "أنتم واباؤكم الأقدمون"
    },
    {
      "surah_number": 26,
      "verse_number": 77,
      "content": "فانهم عدو لي الا رب العالمين"
    },
    {
      "surah_number": 26,
      "verse_number": 78,
      "content": "الذي خلقني فهو يهدين"
    },
    {
      "surah_number": 26,
      "verse_number": 79,
      "content": "والذي هو يطعمني ويسقين"
    },
    {
      "surah_number": 26,
      "verse_number": 80,
      "content": "واذا مرضت فهو يشفين"
    },
    {
      "surah_number": 26,
      "verse_number": 81,
      "content": "والذي يميتني ثم يحيين"
    },
    {
      "surah_number": 26,
      "verse_number": 82,
      "content": "والذي أطمع أن يغفر لي خطئتي يوم الدين"
    },
    {
      "surah_number": 26,
      "verse_number": 83,
      "content": "رب هب لي حكما وألحقني بالصالحين"
    },
    {
      "surah_number": 26,
      "verse_number": 84,
      "content": "واجعل لي لسان صدق في الأخرين"
    },
    {
      "surah_number": 26,
      "verse_number": 85,
      "content": "واجعلني من ورثه جنه النعيم"
    },
    {
      "surah_number": 26,
      "verse_number": 86,
      "content": "واغفر لأبي انه كان من الضالين"
    },
    {
      "surah_number": 26,
      "verse_number": 87,
      "content": "ولا تخزني يوم يبعثون"
    },
    {
      "surah_number": 26,
      "verse_number": 88,
      "content": "يوم لا ينفع مال ولا بنون"
    },
    {
      "surah_number": 26,
      "verse_number": 89,
      "content": "الا من أتى الله بقلب سليم"
    },
    {
      "surah_number": 26,
      "verse_number": 90,
      "content": "وأزلفت الجنه للمتقين"
    },
    {
      "surah_number": 26,
      "verse_number": 91,
      "content": "وبرزت الجحيم للغاوين"
    },
    {
      "surah_number": 26,
      "verse_number": 92,
      "content": "وقيل لهم أين ما كنتم تعبدون"
    },
    {
      "surah_number": 26,
      "verse_number": 93,
      "content": "من دون الله هل ينصرونكم أو ينتصرون"
    },
    {
      "surah_number": 26,
      "verse_number": 94,
      "content": "فكبكبوا فيها هم والغاون"
    },
    {
      "surah_number": 26,
      "verse_number": 95,
      "content": "وجنود ابليس أجمعون"
    },
    {
      "surah_number": 26,
      "verse_number": 96,
      "content": "قالوا وهم فيها يختصمون"
    },
    {
      "surah_number": 26,
      "verse_number": 97,
      "content": "تالله ان كنا لفي ضلال مبين"
    },
    {
      "surah_number": 26,
      "verse_number": 98,
      "content": "اذ نسويكم برب العالمين"
    },
    {
      "surah_number": 26,
      "verse_number": 99,
      "content": "وما أضلنا الا المجرمون"
    },
    {
      "surah_number": 26,
      "verse_number": 100,
      "content": "فما لنا من شافعين"
    },
    {
      "surah_number": 26,
      "verse_number": 101,
      "content": "ولا صديق حميم"
    },
    {
      "surah_number": 26,
      "verse_number": 102,
      "content": "فلو أن لنا كره فنكون من المؤمنين"
    },
    {
      "surah_number": 26,
      "verse_number": 103,
      "content": "ان في ذالك لأيه وما كان أكثرهم مؤمنين"
    },
    {
      "surah_number": 26,
      "verse_number": 104,
      "content": "وان ربك لهو العزيز الرحيم"
    },
    {
      "surah_number": 26,
      "verse_number": 105,
      "content": "كذبت قوم نوح المرسلين"
    },
    {
      "surah_number": 26,
      "verse_number": 106,
      "content": "اذ قال لهم أخوهم نوح ألا تتقون"
    },
    {
      "surah_number": 26,
      "verse_number": 107,
      "content": "اني لكم رسول أمين"
    },
    {
      "surah_number": 26,
      "verse_number": 108,
      "content": "فاتقوا الله وأطيعون"
    },
    {
      "surah_number": 26,
      "verse_number": 109,
      "content": "وما أسٔلكم عليه من أجر ان أجري الا علىا رب العالمين"
    },
    {
      "surah_number": 26,
      "verse_number": 110,
      "content": "فاتقوا الله وأطيعون"
    },
    {
      "surah_number": 26,
      "verse_number": 111,
      "content": "قالوا أنؤمن لك واتبعك الأرذلون"
    },
    {
      "surah_number": 26,
      "verse_number": 112,
      "content": "قال وما علمي بما كانوا يعملون"
    },
    {
      "surah_number": 26,
      "verse_number": 113,
      "content": "ان حسابهم الا علىا ربي لو تشعرون"
    },
    {
      "surah_number": 26,
      "verse_number": 114,
      "content": "وما أنا بطارد المؤمنين"
    },
    {
      "surah_number": 26,
      "verse_number": 115,
      "content": "ان أنا الا نذير مبين"
    },
    {
      "surah_number": 26,
      "verse_number": 116,
      "content": "قالوا لئن لم تنته يانوح لتكونن من المرجومين"
    },
    {
      "surah_number": 26,
      "verse_number": 117,
      "content": "قال رب ان قومي كذبون"
    },
    {
      "surah_number": 26,
      "verse_number": 118,
      "content": "فافتح بيني وبينهم فتحا ونجني ومن معي من المؤمنين"
    },
    {
      "surah_number": 26,
      "verse_number": 119,
      "content": "فأنجيناه ومن معه في الفلك المشحون"
    },
    {
      "surah_number": 26,
      "verse_number": 120,
      "content": "ثم أغرقنا بعد الباقين"
    },
    {
      "surah_number": 26,
      "verse_number": 121,
      "content": "ان في ذالك لأيه وما كان أكثرهم مؤمنين"
    },
    {
      "surah_number": 26,
      "verse_number": 122,
      "content": "وان ربك لهو العزيز الرحيم"
    },
    {
      "surah_number": 26,
      "verse_number": 123,
      "content": "كذبت عاد المرسلين"
    },
    {
      "surah_number": 26,
      "verse_number": 124,
      "content": "اذ قال لهم أخوهم هود ألا تتقون"
    },
    {
      "surah_number": 26,
      "verse_number": 125,
      "content": "اني لكم رسول أمين"
    },
    {
      "surah_number": 26,
      "verse_number": 126,
      "content": "فاتقوا الله وأطيعون"
    },
    {
      "surah_number": 26,
      "verse_number": 127,
      "content": "وما أسٔلكم عليه من أجر ان أجري الا علىا رب العالمين"
    },
    {
      "surah_number": 26,
      "verse_number": 128,
      "content": "أتبنون بكل ريع ايه تعبثون"
    },
    {
      "surah_number": 26,
      "verse_number": 129,
      "content": "وتتخذون مصانع لعلكم تخلدون"
    },
    {
      "surah_number": 26,
      "verse_number": 130,
      "content": "واذا بطشتم بطشتم جبارين"
    },
    {
      "surah_number": 26,
      "verse_number": 131,
      "content": "فاتقوا الله وأطيعون"
    },
    {
      "surah_number": 26,
      "verse_number": 132,
      "content": "واتقوا الذي أمدكم بما تعلمون"
    },
    {
      "surah_number": 26,
      "verse_number": 133,
      "content": "أمدكم بأنعام وبنين"
    },
    {
      "surah_number": 26,
      "verse_number": 134,
      "content": "وجنات وعيون"
    },
    {
      "surah_number": 26,
      "verse_number": 135,
      "content": "اني أخاف عليكم عذاب يوم عظيم"
    },
    {
      "surah_number": 26,
      "verse_number": 136,
      "content": "قالوا سوا علينا أوعظت أم لم تكن من الواعظين"
    },
    {
      "surah_number": 26,
      "verse_number": 137,
      "content": "ان هاذا الا خلق الأولين"
    },
    {
      "surah_number": 26,
      "verse_number": 138,
      "content": "وما نحن بمعذبين"
    },
    {
      "surah_number": 26,
      "verse_number": 139,
      "content": "فكذبوه فأهلكناهم ان في ذالك لأيه وما كان أكثرهم مؤمنين"
    },
    {
      "surah_number": 26,
      "verse_number": 140,
      "content": "وان ربك لهو العزيز الرحيم"
    },
    {
      "surah_number": 26,
      "verse_number": 141,
      "content": "كذبت ثمود المرسلين"
    },
    {
      "surah_number": 26,
      "verse_number": 142,
      "content": "اذ قال لهم أخوهم صالح ألا تتقون"
    },
    {
      "surah_number": 26,
      "verse_number": 143,
      "content": "اني لكم رسول أمين"
    },
    {
      "surah_number": 26,
      "verse_number": 144,
      "content": "فاتقوا الله وأطيعون"
    },
    {
      "surah_number": 26,
      "verse_number": 145,
      "content": "وما أسٔلكم عليه من أجر ان أجري الا علىا رب العالمين"
    },
    {
      "surah_number": 26,
      "verse_number": 146,
      "content": "أتتركون في ما هاهنا امنين"
    },
    {
      "surah_number": 26,
      "verse_number": 147,
      "content": "في جنات وعيون"
    },
    {
      "surah_number": 26,
      "verse_number": 148,
      "content": "وزروع ونخل طلعها هضيم"
    },
    {
      "surah_number": 26,
      "verse_number": 149,
      "content": "وتنحتون من الجبال بيوتا فارهين"
    },
    {
      "surah_number": 26,
      "verse_number": 150,
      "content": "فاتقوا الله وأطيعون"
    },
    {
      "surah_number": 26,
      "verse_number": 151,
      "content": "ولا تطيعوا أمر المسرفين"
    },
    {
      "surah_number": 26,
      "verse_number": 152,
      "content": "الذين يفسدون في الأرض ولا يصلحون"
    },
    {
      "surah_number": 26,
      "verse_number": 153,
      "content": "قالوا انما أنت من المسحرين"
    },
    {
      "surah_number": 26,
      "verse_number": 154,
      "content": "ما أنت الا بشر مثلنا فأت بٔايه ان كنت من الصادقين"
    },
    {
      "surah_number": 26,
      "verse_number": 155,
      "content": "قال هاذه ناقه لها شرب ولكم شرب يوم معلوم"
    },
    {
      "surah_number": 26,
      "verse_number": 156,
      "content": "ولا تمسوها بسو فيأخذكم عذاب يوم عظيم"
    },
    {
      "surah_number": 26,
      "verse_number": 157,
      "content": "فعقروها فأصبحوا نادمين"
    },
    {
      "surah_number": 26,
      "verse_number": 158,
      "content": "فأخذهم العذاب ان في ذالك لأيه وما كان أكثرهم مؤمنين"
    },
    {
      "surah_number": 26,
      "verse_number": 159,
      "content": "وان ربك لهو العزيز الرحيم"
    },
    {
      "surah_number": 26,
      "verse_number": 160,
      "content": "كذبت قوم لوط المرسلين"
    },
    {
      "surah_number": 26,
      "verse_number": 161,
      "content": "اذ قال لهم أخوهم لوط ألا تتقون"
    },
    {
      "surah_number": 26,
      "verse_number": 162,
      "content": "اني لكم رسول أمين"
    },
    {
      "surah_number": 26,
      "verse_number": 163,
      "content": "فاتقوا الله وأطيعون"
    },
    {
      "surah_number": 26,
      "verse_number": 164,
      "content": "وما أسٔلكم عليه من أجر ان أجري الا علىا رب العالمين"
    },
    {
      "surah_number": 26,
      "verse_number": 165,
      "content": "أتأتون الذكران من العالمين"
    },
    {
      "surah_number": 26,
      "verse_number": 166,
      "content": "وتذرون ما خلق لكم ربكم من أزواجكم بل أنتم قوم عادون"
    },
    {
      "surah_number": 26,
      "verse_number": 167,
      "content": "قالوا لئن لم تنته يالوط لتكونن من المخرجين"
    },
    {
      "surah_number": 26,
      "verse_number": 168,
      "content": "قال اني لعملكم من القالين"
    },
    {
      "surah_number": 26,
      "verse_number": 169,
      "content": "رب نجني وأهلي مما يعملون"
    },
    {
      "surah_number": 26,
      "verse_number": 170,
      "content": "فنجيناه وأهله أجمعين"
    },
    {
      "surah_number": 26,
      "verse_number": 171,
      "content": "الا عجوزا في الغابرين"
    },
    {
      "surah_number": 26,
      "verse_number": 172,
      "content": "ثم دمرنا الأخرين"
    },
    {
      "surah_number": 26,
      "verse_number": 173,
      "content": "وأمطرنا عليهم مطرا فسا مطر المنذرين"
    },
    {
      "surah_number": 26,
      "verse_number": 174,
      "content": "ان في ذالك لأيه وما كان أكثرهم مؤمنين"
    },
    {
      "surah_number": 26,
      "verse_number": 175,
      "content": "وان ربك لهو العزيز الرحيم"
    },
    {
      "surah_number": 26,
      "verse_number": 176,
      "content": "كذب أصحاب لٔيكه المرسلين"
    },
    {
      "surah_number": 26,
      "verse_number": 177,
      "content": "اذ قال لهم شعيب ألا تتقون"
    },
    {
      "surah_number": 26,
      "verse_number": 178,
      "content": "اني لكم رسول أمين"
    },
    {
      "surah_number": 26,
      "verse_number": 179,
      "content": "فاتقوا الله وأطيعون"
    },
    {
      "surah_number": 26,
      "verse_number": 180,
      "content": "وما أسٔلكم عليه من أجر ان أجري الا علىا رب العالمين"
    },
    {
      "surah_number": 26,
      "verse_number": 181,
      "content": "أوفوا الكيل ولا تكونوا من المخسرين"
    },
    {
      "surah_number": 26,
      "verse_number": 182,
      "content": "وزنوا بالقسطاس المستقيم"
    },
    {
      "surah_number": 26,
      "verse_number": 183,
      "content": "ولا تبخسوا الناس أشياهم ولا تعثوا في الأرض مفسدين"
    },
    {
      "surah_number": 26,
      "verse_number": 184,
      "content": "واتقوا الذي خلقكم والجبله الأولين"
    },
    {
      "surah_number": 26,
      "verse_number": 185,
      "content": "قالوا انما أنت من المسحرين"
    },
    {
      "surah_number": 26,
      "verse_number": 186,
      "content": "وما أنت الا بشر مثلنا وان نظنك لمن الكاذبين"
    },
    {
      "surah_number": 26,
      "verse_number": 187,
      "content": "فأسقط علينا كسفا من السما ان كنت من الصادقين"
    },
    {
      "surah_number": 26,
      "verse_number": 188,
      "content": "قال ربي أعلم بما تعملون"
    },
    {
      "surah_number": 26,
      "verse_number": 189,
      "content": "فكذبوه فأخذهم عذاب يوم الظله انه كان عذاب يوم عظيم"
    },
    {
      "surah_number": 26,
      "verse_number": 190,
      "content": "ان في ذالك لأيه وما كان أكثرهم مؤمنين"
    },
    {
      "surah_number": 26,
      "verse_number": 191,
      "content": "وان ربك لهو العزيز الرحيم"
    },
    {
      "surah_number": 26,
      "verse_number": 192,
      "content": "وانه لتنزيل رب العالمين"
    },
    {
      "surah_number": 26,
      "verse_number": 193,
      "content": "نزل به الروح الأمين"
    },
    {
      "surah_number": 26,
      "verse_number": 194,
      "content": "علىا قلبك لتكون من المنذرين"
    },
    {
      "surah_number": 26,
      "verse_number": 195,
      "content": "بلسان عربي مبين"
    },
    {
      "surah_number": 26,
      "verse_number": 196,
      "content": "وانه لفي زبر الأولين"
    },
    {
      "surah_number": 26,
      "verse_number": 197,
      "content": "أولم يكن لهم ايه أن يعلمه علماؤا بني اسرايل"
    },
    {
      "surah_number": 26,
      "verse_number": 198,
      "content": "ولو نزلناه علىا بعض الأعجمين"
    },
    {
      "surah_number": 26,
      "verse_number": 199,
      "content": "فقرأه عليهم ما كانوا به مؤمنين"
    },
    {
      "surah_number": 26,
      "verse_number": 200,
      "content": "كذالك سلكناه في قلوب المجرمين"
    },
    {
      "surah_number": 26,
      "verse_number": 201,
      "content": "لا يؤمنون به حتىا يروا العذاب الأليم"
    },
    {
      "surah_number": 26,
      "verse_number": 202,
      "content": "فيأتيهم بغته وهم لا يشعرون"
    },
    {
      "surah_number": 26,
      "verse_number": 203,
      "content": "فيقولوا هل نحن منظرون"
    },
    {
      "surah_number": 26,
      "verse_number": 204,
      "content": "أفبعذابنا يستعجلون"
    },
    {
      "surah_number": 26,
      "verse_number": 205,
      "content": "أفريت ان متعناهم سنين"
    },
    {
      "surah_number": 26,
      "verse_number": 206,
      "content": "ثم جاهم ما كانوا يوعدون"
    },
    {
      "surah_number": 26,
      "verse_number": 207,
      "content": "ما أغنىا عنهم ما كانوا يمتعون"
    },
    {
      "surah_number": 26,
      "verse_number": 208,
      "content": "وما أهلكنا من قريه الا لها منذرون"
    },
    {
      "surah_number": 26,
      "verse_number": 209,
      "content": "ذكرىا وما كنا ظالمين"
    },
    {
      "surah_number": 26,
      "verse_number": 210,
      "content": "وما تنزلت به الشياطين"
    },
    {
      "surah_number": 26,
      "verse_number": 211,
      "content": "وما ينبغي لهم وما يستطيعون"
    },
    {
      "surah_number": 26,
      "verse_number": 212,
      "content": "انهم عن السمع لمعزولون"
    },
    {
      "surah_number": 26,
      "verse_number": 213,
      "content": "فلا تدع مع الله الاها اخر فتكون من المعذبين"
    },
    {
      "surah_number": 26,
      "verse_number": 214,
      "content": "وأنذر عشيرتك الأقربين"
    },
    {
      "surah_number": 26,
      "verse_number": 215,
      "content": "واخفض جناحك لمن اتبعك من المؤمنين"
    },
    {
      "surah_number": 26,
      "verse_number": 216,
      "content": "فان عصوك فقل اني بري مما تعملون"
    },
    {
      "surah_number": 26,
      "verse_number": 217,
      "content": "وتوكل على العزيز الرحيم"
    },
    {
      "surah_number": 26,
      "verse_number": 218,
      "content": "الذي يرىاك حين تقوم"
    },
    {
      "surah_number": 26,
      "verse_number": 219,
      "content": "وتقلبك في الساجدين"
    },
    {
      "surah_number": 26,
      "verse_number": 220,
      "content": "انه هو السميع العليم"
    },
    {
      "surah_number": 26,
      "verse_number": 221,
      "content": "هل أنبئكم علىا من تنزل الشياطين"
    },
    {
      "surah_number": 26,
      "verse_number": 222,
      "content": "تنزل علىا كل أفاك أثيم"
    },
    {
      "surah_number": 26,
      "verse_number": 223,
      "content": "يلقون السمع وأكثرهم كاذبون"
    },
    {
      "surah_number": 26,
      "verse_number": 224,
      "content": "والشعرا يتبعهم الغاون"
    },
    {
      "surah_number": 26,
      "verse_number": 225,
      "content": "ألم تر أنهم في كل واد يهيمون"
    },
    {
      "surah_number": 26,
      "verse_number": 226,
      "content": "وأنهم يقولون ما لا يفعلون"
    },
    {
      "surah_number": 26,
      "verse_number": 227,
      "content": "الا الذين امنوا وعملوا الصالحات وذكروا الله كثيرا وانتصروا من بعد ما ظلموا وسيعلم الذين ظلموا أي منقلب ينقلبون"
    },
    {
      "surah_number": 27,
      "verse_number": 1,
      "content": "طس تلك ايات القران وكتاب مبين"
    },
    {
      "surah_number": 27,
      "verse_number": 2,
      "content": "هدى وبشرىا للمؤمنين"
    },
    {
      "surah_number": 27,
      "verse_number": 3,
      "content": "الذين يقيمون الصلواه ويؤتون الزكواه وهم بالأخره هم يوقنون"
    },
    {
      "surah_number": 27,
      "verse_number": 4,
      "content": "ان الذين لا يؤمنون بالأخره زينا لهم أعمالهم فهم يعمهون"
    },
    {
      "surah_number": 27,
      "verse_number": 5,
      "content": "أولائك الذين لهم سو العذاب وهم في الأخره هم الأخسرون"
    },
    {
      "surah_number": 27,
      "verse_number": 6,
      "content": "وانك لتلقى القران من لدن حكيم عليم"
    },
    {
      "surah_number": 27,
      "verse_number": 7,
      "content": "اذ قال موسىا لأهله اني انست نارا سٔاتيكم منها بخبر أو اتيكم بشهاب قبس لعلكم تصطلون"
    },
    {
      "surah_number": 27,
      "verse_number": 8,
      "content": "فلما جاها نودي أن بورك من في النار ومن حولها وسبحان الله رب العالمين"
    },
    {
      "surah_number": 27,
      "verse_number": 9,
      "content": "ياموسىا انه أنا الله العزيز الحكيم"
    },
    {
      "surah_number": 27,
      "verse_number": 10,
      "content": "وألق عصاك فلما راها تهتز كأنها جان ولىا مدبرا ولم يعقب ياموسىا لا تخف اني لا يخاف لدي المرسلون"
    },
    {
      "surah_number": 27,
      "verse_number": 11,
      "content": "الا من ظلم ثم بدل حسنا بعد سو فاني غفور رحيم"
    },
    {
      "surah_number": 27,
      "verse_number": 12,
      "content": "وأدخل يدك في جيبك تخرج بيضا من غير سو في تسع ايات الىا فرعون وقومه انهم كانوا قوما فاسقين"
    },
    {
      "surah_number": 27,
      "verse_number": 13,
      "content": "فلما جاتهم اياتنا مبصره قالوا هاذا سحر مبين"
    },
    {
      "surah_number": 27,
      "verse_number": 14,
      "content": "وجحدوا بها واستيقنتها أنفسهم ظلما وعلوا فانظر كيف كان عاقبه المفسدين"
    },
    {
      "surah_number": 27,
      "verse_number": 15,
      "content": "ولقد اتينا داود وسليمان علما وقالا الحمد لله الذي فضلنا علىا كثير من عباده المؤمنين"
    },
    {
      "surah_number": 27,
      "verse_number": 16,
      "content": "وورث سليمان داود وقال ياأيها الناس علمنا منطق الطير وأوتينا من كل شي ان هاذا لهو الفضل المبين"
    },
    {
      "surah_number": 27,
      "verse_number": 17,
      "content": "وحشر لسليمان جنوده من الجن والانس والطير فهم يوزعون"
    },
    {
      "surah_number": 27,
      "verse_number": 18,
      "content": "حتىا اذا أتوا علىا واد النمل قالت نمله ياأيها النمل ادخلوا مساكنكم لا يحطمنكم سليمان وجنوده وهم لا يشعرون"
    },
    {
      "surah_number": 27,
      "verse_number": 19,
      "content": "فتبسم ضاحكا من قولها وقال رب أوزعني أن أشكر نعمتك التي أنعمت علي وعلىا والدي وأن أعمل صالحا ترضىاه وأدخلني برحمتك في عبادك الصالحين"
    },
    {
      "surah_number": 27,
      "verse_number": 20,
      "content": "وتفقد الطير فقال مالي لا أرى الهدهد أم كان من الغائبين"
    },
    {
      "surah_number": 27,
      "verse_number": 21,
      "content": "لأعذبنه عذابا شديدا أو لأاذبحنه أو ليأتيني بسلطان مبين"
    },
    {
      "surah_number": 27,
      "verse_number": 22,
      "content": "فمكث غير بعيد فقال أحطت بما لم تحط به وجئتك من سبا بنبا يقين"
    },
    {
      "surah_number": 27,
      "verse_number": 23,
      "content": "اني وجدت امرأه تملكهم وأوتيت من كل شي ولها عرش عظيم"
    },
    {
      "surah_number": 27,
      "verse_number": 24,
      "content": "وجدتها وقومها يسجدون للشمس من دون الله وزين لهم الشيطان أعمالهم فصدهم عن السبيل فهم لا يهتدون"
    },
    {
      "surah_number": 27,
      "verse_number": 25,
      "content": "ألا يسجدوا لله الذي يخرج الخب في السماوات والأرض ويعلم ما تخفون وما تعلنون"
    },
    {
      "surah_number": 27,
      "verse_number": 26,
      "content": "الله لا الاه الا هو رب العرش العظيم"
    },
    {
      "surah_number": 27,
      "verse_number": 27,
      "content": "قال سننظر أصدقت أم كنت من الكاذبين"
    },
    {
      "surah_number": 27,
      "verse_number": 28,
      "content": "اذهب بكتابي هاذا فألقه اليهم ثم تول عنهم فانظر ماذا يرجعون"
    },
    {
      "surah_number": 27,
      "verse_number": 29,
      "content": "قالت ياأيها الملؤا اني ألقي الي كتاب كريم"
    },
    {
      "surah_number": 27,
      "verse_number": 30,
      "content": "انه من سليمان وانه بسم الله الرحمان الرحيم"
    },
    {
      "surah_number": 27,
      "verse_number": 31,
      "content": "ألا تعلوا علي وأتوني مسلمين"
    },
    {
      "surah_number": 27,
      "verse_number": 32,
      "content": "قالت ياأيها الملؤا أفتوني في أمري ما كنت قاطعه أمرا حتىا تشهدون"
    },
    {
      "surah_number": 27,
      "verse_number": 33,
      "content": "قالوا نحن أولوا قوه وأولوا بأس شديد والأمر اليك فانظري ماذا تأمرين"
    },
    {
      "surah_number": 27,
      "verse_number": 34,
      "content": "قالت ان الملوك اذا دخلوا قريه أفسدوها وجعلوا أعزه أهلها أذله وكذالك يفعلون"
    },
    {
      "surah_number": 27,
      "verse_number": 35,
      "content": "واني مرسله اليهم بهديه فناظره بم يرجع المرسلون"
    },
    {
      "surah_number": 27,
      "verse_number": 36,
      "content": "فلما جا سليمان قال أتمدونن بمال فما اتىان الله خير مما اتىاكم بل أنتم بهديتكم تفرحون"
    },
    {
      "surah_number": 27,
      "verse_number": 37,
      "content": "ارجع اليهم فلنأتينهم بجنود لا قبل لهم بها ولنخرجنهم منها أذله وهم صاغرون"
    },
    {
      "surah_number": 27,
      "verse_number": 38,
      "content": "قال ياأيها الملؤا أيكم يأتيني بعرشها قبل أن يأتوني مسلمين"
    },
    {
      "surah_number": 27,
      "verse_number": 39,
      "content": "قال عفريت من الجن أنا اتيك به قبل أن تقوم من مقامك واني عليه لقوي أمين"
    },
    {
      "surah_number": 27,
      "verse_number": 40,
      "content": "قال الذي عنده علم من الكتاب أنا اتيك به قبل أن يرتد اليك طرفك فلما راه مستقرا عنده قال هاذا من فضل ربي ليبلوني ءأشكر أم أكفر ومن شكر فانما يشكر لنفسه ومن كفر فان ربي غني كريم"
    },
    {
      "surah_number": 27,
      "verse_number": 41,
      "content": "قال نكروا لها عرشها ننظر أتهتدي أم تكون من الذين لا يهتدون"
    },
    {
      "surah_number": 27,
      "verse_number": 42,
      "content": "فلما جات قيل أهاكذا عرشك قالت كأنه هو وأوتينا العلم من قبلها وكنا مسلمين"
    },
    {
      "surah_number": 27,
      "verse_number": 43,
      "content": "وصدها ما كانت تعبد من دون الله انها كانت من قوم كافرين"
    },
    {
      "surah_number": 27,
      "verse_number": 44,
      "content": "قيل لها ادخلي الصرح فلما رأته حسبته لجه وكشفت عن ساقيها قال انه صرح ممرد من قوارير قالت رب اني ظلمت نفسي وأسلمت مع سليمان لله رب العالمين"
    },
    {
      "surah_number": 27,
      "verse_number": 45,
      "content": "ولقد أرسلنا الىا ثمود أخاهم صالحا أن اعبدوا الله فاذا هم فريقان يختصمون"
    },
    {
      "surah_number": 27,
      "verse_number": 46,
      "content": "قال ياقوم لم تستعجلون بالسيئه قبل الحسنه لولا تستغفرون الله لعلكم ترحمون"
    },
    {
      "surah_number": 27,
      "verse_number": 47,
      "content": "قالوا اطيرنا بك وبمن معك قال طائركم عند الله بل أنتم قوم تفتنون"
    },
    {
      "surah_number": 27,
      "verse_number": 48,
      "content": "وكان في المدينه تسعه رهط يفسدون في الأرض ولا يصلحون"
    },
    {
      "surah_number": 27,
      "verse_number": 49,
      "content": "قالوا تقاسموا بالله لنبيتنه وأهله ثم لنقولن لوليه ما شهدنا مهلك أهله وانا لصادقون"
    },
    {
      "surah_number": 27,
      "verse_number": 50,
      "content": "ومكروا مكرا ومكرنا مكرا وهم لا يشعرون"
    },
    {
      "surah_number": 27,
      "verse_number": 51,
      "content": "فانظر كيف كان عاقبه مكرهم أنا دمرناهم وقومهم أجمعين"
    },
    {
      "surah_number": 27,
      "verse_number": 52,
      "content": "فتلك بيوتهم خاويه بما ظلموا ان في ذالك لأيه لقوم يعلمون"
    },
    {
      "surah_number": 27,
      "verse_number": 53,
      "content": "وأنجينا الذين امنوا وكانوا يتقون"
    },
    {
      "surah_number": 27,
      "verse_number": 54,
      "content": "ولوطا اذ قال لقومه أتأتون الفاحشه وأنتم تبصرون"
    },
    {
      "surah_number": 27,
      "verse_number": 55,
      "content": "أئنكم لتأتون الرجال شهوه من دون النسا بل أنتم قوم تجهلون"
    },
    {
      "surah_number": 27,
      "verse_number": 56,
      "content": "فما كان جواب قومه الا أن قالوا أخرجوا ال لوط من قريتكم انهم أناس يتطهرون"
    },
    {
      "surah_number": 27,
      "verse_number": 57,
      "content": "فأنجيناه وأهله الا امرأته قدرناها من الغابرين"
    },
    {
      "surah_number": 27,
      "verse_number": 58,
      "content": "وأمطرنا عليهم مطرا فسا مطر المنذرين"
    },
    {
      "surah_number": 27,
      "verse_number": 59,
      "content": "قل الحمد لله وسلام علىا عباده الذين اصطفىا الله خير أما يشركون"
    },
    {
      "surah_number": 27,
      "verse_number": 60,
      "content": "أمن خلق السماوات والأرض وأنزل لكم من السما ما فأنبتنا به حدائق ذات بهجه ما كان لكم أن تنبتوا شجرها ألاه مع الله بل هم قوم يعدلون"
    },
    {
      "surah_number": 27,
      "verse_number": 61,
      "content": "أمن جعل الأرض قرارا وجعل خلالها أنهارا وجعل لها رواسي وجعل بين البحرين حاجزا ألاه مع الله بل أكثرهم لا يعلمون"
    },
    {
      "surah_number": 27,
      "verse_number": 62,
      "content": "أمن يجيب المضطر اذا دعاه ويكشف السو ويجعلكم خلفا الأرض ألاه مع الله قليلا ما تذكرون"
    },
    {
      "surah_number": 27,
      "verse_number": 63,
      "content": "أمن يهديكم في ظلمات البر والبحر ومن يرسل الرياح بشرا بين يدي رحمته ألاه مع الله تعالى الله عما يشركون"
    },
    {
      "surah_number": 27,
      "verse_number": 64,
      "content": "أمن يبدؤا الخلق ثم يعيده ومن يرزقكم من السما والأرض ألاه مع الله قل هاتوا برهانكم ان كنتم صادقين"
    },
    {
      "surah_number": 27,
      "verse_number": 65,
      "content": "قل لا يعلم من في السماوات والأرض الغيب الا الله وما يشعرون أيان يبعثون"
    },
    {
      "surah_number": 27,
      "verse_number": 66,
      "content": "بل ادارك علمهم في الأخره بل هم في شك منها بل هم منها عمون"
    },
    {
      "surah_number": 27,
      "verse_number": 67,
      "content": "وقال الذين كفروا أذا كنا ترابا واباؤنا أئنا لمخرجون"
    },
    {
      "surah_number": 27,
      "verse_number": 68,
      "content": "لقد وعدنا هاذا نحن واباؤنا من قبل ان هاذا الا أساطير الأولين"
    },
    {
      "surah_number": 27,
      "verse_number": 69,
      "content": "قل سيروا في الأرض فانظروا كيف كان عاقبه المجرمين"
    },
    {
      "surah_number": 27,
      "verse_number": 70,
      "content": "ولا تحزن عليهم ولا تكن في ضيق مما يمكرون"
    },
    {
      "surah_number": 27,
      "verse_number": 71,
      "content": "ويقولون متىا هاذا الوعد ان كنتم صادقين"
    },
    {
      "surah_number": 27,
      "verse_number": 72,
      "content": "قل عسىا أن يكون ردف لكم بعض الذي تستعجلون"
    },
    {
      "surah_number": 27,
      "verse_number": 73,
      "content": "وان ربك لذو فضل على الناس ولاكن أكثرهم لا يشكرون"
    },
    {
      "surah_number": 27,
      "verse_number": 74,
      "content": "وان ربك ليعلم ما تكن صدورهم وما يعلنون"
    },
    {
      "surah_number": 27,
      "verse_number": 75,
      "content": "وما من غائبه في السما والأرض الا في كتاب مبين"
    },
    {
      "surah_number": 27,
      "verse_number": 76,
      "content": "ان هاذا القران يقص علىا بني اسرايل أكثر الذي هم فيه يختلفون"
    },
    {
      "surah_number": 27,
      "verse_number": 77,
      "content": "وانه لهدى ورحمه للمؤمنين"
    },
    {
      "surah_number": 27,
      "verse_number": 78,
      "content": "ان ربك يقضي بينهم بحكمه وهو العزيز العليم"
    },
    {
      "surah_number": 27,
      "verse_number": 79,
      "content": "فتوكل على الله انك على الحق المبين"
    },
    {
      "surah_number": 27,
      "verse_number": 80,
      "content": "انك لا تسمع الموتىا ولا تسمع الصم الدعا اذا ولوا مدبرين"
    },
    {
      "surah_number": 27,
      "verse_number": 81,
      "content": "وما أنت بهادي العمي عن ضلالتهم ان تسمع الا من يؤمن بٔاياتنا فهم مسلمون"
    },
    {
      "surah_number": 27,
      "verse_number": 82,
      "content": "واذا وقع القول عليهم أخرجنا لهم دابه من الأرض تكلمهم أن الناس كانوا بٔاياتنا لا يوقنون"
    },
    {
      "surah_number": 27,
      "verse_number": 83,
      "content": "ويوم نحشر من كل أمه فوجا ممن يكذب بٔاياتنا فهم يوزعون"
    },
    {
      "surah_number": 27,
      "verse_number": 84,
      "content": "حتىا اذا جاو قال أكذبتم بٔاياتي ولم تحيطوا بها علما أماذا كنتم تعملون"
    },
    {
      "surah_number": 27,
      "verse_number": 85,
      "content": "ووقع القول عليهم بما ظلموا فهم لا ينطقون"
    },
    {
      "surah_number": 27,
      "verse_number": 86,
      "content": "ألم يروا أنا جعلنا اليل ليسكنوا فيه والنهار مبصرا ان في ذالك لأيات لقوم يؤمنون"
    },
    {
      "surah_number": 27,
      "verse_number": 87,
      "content": "ويوم ينفخ في الصور ففزع من في السماوات ومن في الأرض الا من شا الله وكل أتوه داخرين"
    },
    {
      "surah_number": 27,
      "verse_number": 88,
      "content": "وترى الجبال تحسبها جامده وهي تمر مر السحاب صنع الله الذي أتقن كل شي انه خبير بما تفعلون"
    },
    {
      "surah_number": 27,
      "verse_number": 89,
      "content": "من جا بالحسنه فله خير منها وهم من فزع يومئذ امنون"
    },
    {
      "surah_number": 27,
      "verse_number": 90,
      "content": "ومن جا بالسيئه فكبت وجوههم في النار هل تجزون الا ما كنتم تعملون"
    },
    {
      "surah_number": 27,
      "verse_number": 91,
      "content": "انما أمرت أن أعبد رب هاذه البلده الذي حرمها وله كل شي وأمرت أن أكون من المسلمين"
    },
    {
      "surah_number": 27,
      "verse_number": 92,
      "content": "وأن أتلوا القران فمن اهتدىا فانما يهتدي لنفسه ومن ضل فقل انما أنا من المنذرين"
    },
    {
      "surah_number": 27,
      "verse_number": 93,
      "content": "وقل الحمد لله سيريكم اياته فتعرفونها وما ربك بغافل عما تعملون"
    },
    {
      "surah_number": 28,
      "verse_number": 1,
      "content": "طسم"
    },
    {
      "surah_number": 28,
      "verse_number": 2,
      "content": "تلك ايات الكتاب المبين"
    },
    {
      "surah_number": 28,
      "verse_number": 3,
      "content": "نتلوا عليك من نبا موسىا وفرعون بالحق لقوم يؤمنون"
    },
    {
      "surah_number": 28,
      "verse_number": 4,
      "content": "ان فرعون علا في الأرض وجعل أهلها شيعا يستضعف طائفه منهم يذبح أبناهم ويستحي نساهم انه كان من المفسدين"
    },
    {
      "surah_number": 28,
      "verse_number": 5,
      "content": "ونريد أن نمن على الذين استضعفوا في الأرض ونجعلهم أئمه ونجعلهم الوارثين"
    },
    {
      "surah_number": 28,
      "verse_number": 6,
      "content": "ونمكن لهم في الأرض ونري فرعون وهامان وجنودهما منهم ما كانوا يحذرون"
    },
    {
      "surah_number": 28,
      "verse_number": 7,
      "content": "وأوحينا الىا أم موسىا أن أرضعيه فاذا خفت عليه فألقيه في اليم ولا تخافي ولا تحزني انا رادوه اليك وجاعلوه من المرسلين"
    },
    {
      "surah_number": 28,
      "verse_number": 8,
      "content": "فالتقطه ال فرعون ليكون لهم عدوا وحزنا ان فرعون وهامان وجنودهما كانوا خاطٔين"
    },
    {
      "surah_number": 28,
      "verse_number": 9,
      "content": "وقالت امرأت فرعون قرت عين لي ولك لا تقتلوه عسىا أن ينفعنا أو نتخذه ولدا وهم لا يشعرون"
    },
    {
      "surah_number": 28,
      "verse_number": 10,
      "content": "وأصبح فؤاد أم موسىا فارغا ان كادت لتبدي به لولا أن ربطنا علىا قلبها لتكون من المؤمنين"
    },
    {
      "surah_number": 28,
      "verse_number": 11,
      "content": "وقالت لأخته قصيه فبصرت به عن جنب وهم لا يشعرون"
    },
    {
      "surah_number": 28,
      "verse_number": 12,
      "content": "وحرمنا عليه المراضع من قبل فقالت هل أدلكم علىا أهل بيت يكفلونه لكم وهم له ناصحون"
    },
    {
      "surah_number": 28,
      "verse_number": 13,
      "content": "فرددناه الىا أمه كي تقر عينها ولا تحزن ولتعلم أن وعد الله حق ولاكن أكثرهم لا يعلمون"
    },
    {
      "surah_number": 28,
      "verse_number": 14,
      "content": "ولما بلغ أشده واستوىا اتيناه حكما وعلما وكذالك نجزي المحسنين"
    },
    {
      "surah_number": 28,
      "verse_number": 15,
      "content": "ودخل المدينه علىا حين غفله من أهلها فوجد فيها رجلين يقتتلان هاذا من شيعته وهاذا من عدوه فاستغاثه الذي من شيعته على الذي من عدوه فوكزه موسىا فقضىا عليه قال هاذا من عمل الشيطان انه عدو مضل مبين"
    },
    {
      "surah_number": 28,
      "verse_number": 16,
      "content": "قال رب اني ظلمت نفسي فاغفر لي فغفر له انه هو الغفور الرحيم"
    },
    {
      "surah_number": 28,
      "verse_number": 17,
      "content": "قال رب بما أنعمت علي فلن أكون ظهيرا للمجرمين"
    },
    {
      "surah_number": 28,
      "verse_number": 18,
      "content": "فأصبح في المدينه خائفا يترقب فاذا الذي استنصره بالأمس يستصرخه قال له موسىا انك لغوي مبين"
    },
    {
      "surah_number": 28,
      "verse_number": 19,
      "content": "فلما أن أراد أن يبطش بالذي هو عدو لهما قال ياموسىا أتريد أن تقتلني كما قتلت نفسا بالأمس ان تريد الا أن تكون جبارا في الأرض وما تريد أن تكون من المصلحين"
    },
    {
      "surah_number": 28,
      "verse_number": 20,
      "content": "وجا رجل من أقصا المدينه يسعىا قال ياموسىا ان الملأ يأتمرون بك ليقتلوك فاخرج اني لك من الناصحين"
    },
    {
      "surah_number": 28,
      "verse_number": 21,
      "content": "فخرج منها خائفا يترقب قال رب نجني من القوم الظالمين"
    },
    {
      "surah_number": 28,
      "verse_number": 22,
      "content": "ولما توجه تلقا مدين قال عسىا ربي أن يهديني سوا السبيل"
    },
    {
      "surah_number": 28,
      "verse_number": 23,
      "content": "ولما ورد ما مدين وجد عليه أمه من الناس يسقون ووجد من دونهم امرأتين تذودان قال ما خطبكما قالتا لا نسقي حتىا يصدر الرعا وأبونا شيخ كبير"
    },
    {
      "surah_number": 28,
      "verse_number": 24,
      "content": "فسقىا لهما ثم تولىا الى الظل فقال رب اني لما أنزلت الي من خير فقير"
    },
    {
      "surah_number": 28,
      "verse_number": 25,
      "content": "فجاته احدىاهما تمشي على استحيا قالت ان أبي يدعوك ليجزيك أجر ما سقيت لنا فلما جاه وقص عليه القصص قال لا تخف نجوت من القوم الظالمين"
    },
    {
      "surah_number": 28,
      "verse_number": 26,
      "content": "قالت احدىاهما ياأبت استٔجره ان خير من استٔجرت القوي الأمين"
    },
    {
      "surah_number": 28,
      "verse_number": 27,
      "content": "قال اني أريد أن أنكحك احدى ابنتي هاتين علىا أن تأجرني ثماني حجج فان أتممت عشرا فمن عندك وما أريد أن أشق عليك ستجدني ان شا الله من الصالحين"
    },
    {
      "surah_number": 28,
      "verse_number": 28,
      "content": "قال ذالك بيني وبينك أيما الأجلين قضيت فلا عدوان علي والله علىا ما نقول وكيل"
    },
    {
      "surah_number": 28,
      "verse_number": 29,
      "content": "فلما قضىا موسى الأجل وسار بأهله انس من جانب الطور نارا قال لأهله امكثوا اني انست نارا لعلي اتيكم منها بخبر أو جذوه من النار لعلكم تصطلون"
    },
    {
      "surah_number": 28,
      "verse_number": 30,
      "content": "فلما أتىاها نودي من شاطي الواد الأيمن في البقعه المباركه من الشجره أن ياموسىا اني أنا الله رب العالمين"
    },
    {
      "surah_number": 28,
      "verse_number": 31,
      "content": "وأن ألق عصاك فلما راها تهتز كأنها جان ولىا مدبرا ولم يعقب ياموسىا أقبل ولا تخف انك من الأمنين"
    },
    {
      "surah_number": 28,
      "verse_number": 32,
      "content": "اسلك يدك في جيبك تخرج بيضا من غير سو واضمم اليك جناحك من الرهب فذانك برهانان من ربك الىا فرعون وملايه انهم كانوا قوما فاسقين"
    },
    {
      "surah_number": 28,
      "verse_number": 33,
      "content": "قال رب اني قتلت منهم نفسا فأخاف أن يقتلون"
    },
    {
      "surah_number": 28,
      "verse_number": 34,
      "content": "وأخي هارون هو أفصح مني لسانا فأرسله معي ردا يصدقني اني أخاف أن يكذبون"
    },
    {
      "surah_number": 28,
      "verse_number": 35,
      "content": "قال سنشد عضدك بأخيك ونجعل لكما سلطانا فلا يصلون اليكما بٔاياتنا أنتما ومن اتبعكما الغالبون"
    },
    {
      "surah_number": 28,
      "verse_number": 36,
      "content": "فلما جاهم موسىا بٔاياتنا بينات قالوا ما هاذا الا سحر مفترى وما سمعنا بهاذا في ابائنا الأولين"
    },
    {
      "surah_number": 28,
      "verse_number": 37,
      "content": "وقال موسىا ربي أعلم بمن جا بالهدىا من عنده ومن تكون له عاقبه الدار انه لا يفلح الظالمون"
    },
    {
      "surah_number": 28,
      "verse_number": 38,
      "content": "وقال فرعون ياأيها الملأ ما علمت لكم من الاه غيري فأوقد لي ياهامان على الطين فاجعل لي صرحا لعلي أطلع الىا الاه موسىا واني لأظنه من الكاذبين"
    },
    {
      "surah_number": 28,
      "verse_number": 39,
      "content": "واستكبر هو وجنوده في الأرض بغير الحق وظنوا أنهم الينا لا يرجعون"
    },
    {
      "surah_number": 28,
      "verse_number": 40,
      "content": "فأخذناه وجنوده فنبذناهم في اليم فانظر كيف كان عاقبه الظالمين"
    },
    {
      "surah_number": 28,
      "verse_number": 41,
      "content": "وجعلناهم أئمه يدعون الى النار ويوم القيامه لا ينصرون"
    },
    {
      "surah_number": 28,
      "verse_number": 42,
      "content": "وأتبعناهم في هاذه الدنيا لعنه ويوم القيامه هم من المقبوحين"
    },
    {
      "surah_number": 28,
      "verse_number": 43,
      "content": "ولقد اتينا موسى الكتاب من بعد ما أهلكنا القرون الأولىا بصائر للناس وهدى ورحمه لعلهم يتذكرون"
    },
    {
      "surah_number": 28,
      "verse_number": 44,
      "content": "وما كنت بجانب الغربي اذ قضينا الىا موسى الأمر وما كنت من الشاهدين"
    },
    {
      "surah_number": 28,
      "verse_number": 45,
      "content": "ولاكنا أنشأنا قرونا فتطاول عليهم العمر وما كنت ثاويا في أهل مدين تتلوا عليهم اياتنا ولاكنا كنا مرسلين"
    },
    {
      "surah_number": 28,
      "verse_number": 46,
      "content": "وما كنت بجانب الطور اذ نادينا ولاكن رحمه من ربك لتنذر قوما ما أتىاهم من نذير من قبلك لعلهم يتذكرون"
    },
    {
      "surah_number": 28,
      "verse_number": 47,
      "content": "ولولا أن تصيبهم مصيبه بما قدمت أيديهم فيقولوا ربنا لولا أرسلت الينا رسولا فنتبع اياتك ونكون من المؤمنين"
    },
    {
      "surah_number": 28,
      "verse_number": 48,
      "content": "فلما جاهم الحق من عندنا قالوا لولا أوتي مثل ما أوتي موسىا أولم يكفروا بما أوتي موسىا من قبل قالوا سحران تظاهرا وقالوا انا بكل كافرون"
    },
    {
      "surah_number": 28,
      "verse_number": 49,
      "content": "قل فأتوا بكتاب من عند الله هو أهدىا منهما أتبعه ان كنتم صادقين"
    },
    {
      "surah_number": 28,
      "verse_number": 50,
      "content": "فان لم يستجيبوا لك فاعلم أنما يتبعون أهواهم ومن أضل ممن اتبع هوىاه بغير هدى من الله ان الله لا يهدي القوم الظالمين"
    },
    {
      "surah_number": 28,
      "verse_number": 51,
      "content": "ولقد وصلنا لهم القول لعلهم يتذكرون"
    },
    {
      "surah_number": 28,
      "verse_number": 52,
      "content": "الذين اتيناهم الكتاب من قبله هم به يؤمنون"
    },
    {
      "surah_number": 28,
      "verse_number": 53,
      "content": "واذا يتلىا عليهم قالوا امنا به انه الحق من ربنا انا كنا من قبله مسلمين"
    },
    {
      "surah_number": 28,
      "verse_number": 54,
      "content": "أولائك يؤتون أجرهم مرتين بما صبروا ويدرون بالحسنه السيئه ومما رزقناهم ينفقون"
    },
    {
      "surah_number": 28,
      "verse_number": 55,
      "content": "واذا سمعوا اللغو أعرضوا عنه وقالوا لنا أعمالنا ولكم أعمالكم سلام عليكم لا نبتغي الجاهلين"
    },
    {
      "surah_number": 28,
      "verse_number": 56,
      "content": "انك لا تهدي من أحببت ولاكن الله يهدي من يشا وهو أعلم بالمهتدين"
    },
    {
      "surah_number": 28,
      "verse_number": 57,
      "content": "وقالوا ان نتبع الهدىا معك نتخطف من أرضنا أولم نمكن لهم حرما امنا يجبىا اليه ثمرات كل شي رزقا من لدنا ولاكن أكثرهم لا يعلمون"
    },
    {
      "surah_number": 28,
      "verse_number": 58,
      "content": "وكم أهلكنا من قريه بطرت معيشتها فتلك مساكنهم لم تسكن من بعدهم الا قليلا وكنا نحن الوارثين"
    },
    {
      "surah_number": 28,
      "verse_number": 59,
      "content": "وما كان ربك مهلك القرىا حتىا يبعث في أمها رسولا يتلوا عليهم اياتنا وما كنا مهلكي القرىا الا وأهلها ظالمون"
    },
    {
      "surah_number": 28,
      "verse_number": 60,
      "content": "وما أوتيتم من شي فمتاع الحيواه الدنيا وزينتها وما عند الله خير وأبقىا أفلا تعقلون"
    },
    {
      "surah_number": 28,
      "verse_number": 61,
      "content": "أفمن وعدناه وعدا حسنا فهو لاقيه كمن متعناه متاع الحيواه الدنيا ثم هو يوم القيامه من المحضرين"
    },
    {
      "surah_number": 28,
      "verse_number": 62,
      "content": "ويوم يناديهم فيقول أين شركاي الذين كنتم تزعمون"
    },
    {
      "surah_number": 28,
      "verse_number": 63,
      "content": "قال الذين حق عليهم القول ربنا هاؤلا الذين أغوينا أغويناهم كما غوينا تبرأنا اليك ما كانوا ايانا يعبدون"
    },
    {
      "surah_number": 28,
      "verse_number": 64,
      "content": "وقيل ادعوا شركاكم فدعوهم فلم يستجيبوا لهم ورأوا العذاب لو أنهم كانوا يهتدون"
    },
    {
      "surah_number": 28,
      "verse_number": 65,
      "content": "ويوم يناديهم فيقول ماذا أجبتم المرسلين"
    },
    {
      "surah_number": 28,
      "verse_number": 66,
      "content": "فعميت عليهم الأنبا يومئذ فهم لا يتسالون"
    },
    {
      "surah_number": 28,
      "verse_number": 67,
      "content": "فأما من تاب وامن وعمل صالحا فعسىا أن يكون من المفلحين"
    },
    {
      "surah_number": 28,
      "verse_number": 68,
      "content": "وربك يخلق ما يشا ويختار ما كان لهم الخيره سبحان الله وتعالىا عما يشركون"
    },
    {
      "surah_number": 28,
      "verse_number": 69,
      "content": "وربك يعلم ما تكن صدورهم وما يعلنون"
    },
    {
      "surah_number": 28,
      "verse_number": 70,
      "content": "وهو الله لا الاه الا هو له الحمد في الأولىا والأخره وله الحكم واليه ترجعون"
    },
    {
      "surah_number": 28,
      "verse_number": 71,
      "content": "قل أريتم ان جعل الله عليكم اليل سرمدا الىا يوم القيامه من الاه غير الله يأتيكم بضيا أفلا تسمعون"
    },
    {
      "surah_number": 28,
      "verse_number": 72,
      "content": "قل أريتم ان جعل الله عليكم النهار سرمدا الىا يوم القيامه من الاه غير الله يأتيكم بليل تسكنون فيه أفلا تبصرون"
    },
    {
      "surah_number": 28,
      "verse_number": 73,
      "content": "ومن رحمته جعل لكم اليل والنهار لتسكنوا فيه ولتبتغوا من فضله ولعلكم تشكرون"
    },
    {
      "surah_number": 28,
      "verse_number": 74,
      "content": "ويوم يناديهم فيقول أين شركاي الذين كنتم تزعمون"
    },
    {
      "surah_number": 28,
      "verse_number": 75,
      "content": "ونزعنا من كل أمه شهيدا فقلنا هاتوا برهانكم فعلموا أن الحق لله وضل عنهم ما كانوا يفترون"
    },
    {
      "surah_number": 28,
      "verse_number": 76,
      "content": "ان قارون كان من قوم موسىا فبغىا عليهم واتيناه من الكنوز ما ان مفاتحه لتنوأ بالعصبه أولي القوه اذ قال له قومه لا تفرح ان الله لا يحب الفرحين"
    },
    {
      "surah_number": 28,
      "verse_number": 77,
      "content": "وابتغ فيما اتىاك الله الدار الأخره ولا تنس نصيبك من الدنيا وأحسن كما أحسن الله اليك ولا تبغ الفساد في الأرض ان الله لا يحب المفسدين"
    },
    {
      "surah_number": 28,
      "verse_number": 78,
      "content": "قال انما أوتيته علىا علم عندي أولم يعلم أن الله قد أهلك من قبله من القرون من هو أشد منه قوه وأكثر جمعا ولا يسٔل عن ذنوبهم المجرمون"
    },
    {
      "surah_number": 28,
      "verse_number": 79,
      "content": "فخرج علىا قومه في زينته قال الذين يريدون الحيواه الدنيا ياليت لنا مثل ما أوتي قارون انه لذو حظ عظيم"
    },
    {
      "surah_number": 28,
      "verse_number": 80,
      "content": "وقال الذين أوتوا العلم ويلكم ثواب الله خير لمن امن وعمل صالحا ولا يلقىاها الا الصابرون"
    },
    {
      "surah_number": 28,
      "verse_number": 81,
      "content": "فخسفنا به وبداره الأرض فما كان له من فئه ينصرونه من دون الله وما كان من المنتصرين"
    },
    {
      "surah_number": 28,
      "verse_number": 82,
      "content": "وأصبح الذين تمنوا مكانه بالأمس يقولون ويكأن الله يبسط الرزق لمن يشا من عباده ويقدر لولا أن من الله علينا لخسف بنا ويكأنه لا يفلح الكافرون"
    },
    {
      "surah_number": 28,
      "verse_number": 83,
      "content": "تلك الدار الأخره نجعلها للذين لا يريدون علوا في الأرض ولا فسادا والعاقبه للمتقين"
    },
    {
      "surah_number": 28,
      "verse_number": 84,
      "content": "من جا بالحسنه فله خير منها ومن جا بالسيئه فلا يجزى الذين عملوا السئات الا ما كانوا يعملون"
    },
    {
      "surah_number": 28,
      "verse_number": 85,
      "content": "ان الذي فرض عليك القران لرادك الىا معاد قل ربي أعلم من جا بالهدىا ومن هو في ضلال مبين"
    },
    {
      "surah_number": 28,
      "verse_number": 86,
      "content": "وما كنت ترجوا أن يلقىا اليك الكتاب الا رحمه من ربك فلا تكونن ظهيرا للكافرين"
    },
    {
      "surah_number": 28,
      "verse_number": 87,
      "content": "ولا يصدنك عن ايات الله بعد اذ أنزلت اليك وادع الىا ربك ولا تكونن من المشركين"
    },
    {
      "surah_number": 28,
      "verse_number": 88,
      "content": "ولا تدع مع الله الاها اخر لا الاه الا هو كل شي هالك الا وجهه له الحكم واليه ترجعون"
    },
    {
      "surah_number": 29,
      "verse_number": 1,
      "content": "الم"
    },
    {
      "surah_number": 29,
      "verse_number": 2,
      "content": "أحسب الناس أن يتركوا أن يقولوا امنا وهم لا يفتنون"
    },
    {
      "surah_number": 29,
      "verse_number": 3,
      "content": "ولقد فتنا الذين من قبلهم فليعلمن الله الذين صدقوا وليعلمن الكاذبين"
    },
    {
      "surah_number": 29,
      "verse_number": 4,
      "content": "أم حسب الذين يعملون السئات أن يسبقونا سا ما يحكمون"
    },
    {
      "surah_number": 29,
      "verse_number": 5,
      "content": "من كان يرجوا لقا الله فان أجل الله لأت وهو السميع العليم"
    },
    {
      "surah_number": 29,
      "verse_number": 6,
      "content": "ومن جاهد فانما يجاهد لنفسه ان الله لغني عن العالمين"
    },
    {
      "surah_number": 29,
      "verse_number": 7,
      "content": "والذين امنوا وعملوا الصالحات لنكفرن عنهم سئاتهم ولنجزينهم أحسن الذي كانوا يعملون"
    },
    {
      "surah_number": 29,
      "verse_number": 8,
      "content": "ووصينا الانسان بوالديه حسنا وان جاهداك لتشرك بي ما ليس لك به علم فلا تطعهما الي مرجعكم فأنبئكم بما كنتم تعملون"
    },
    {
      "surah_number": 29,
      "verse_number": 9,
      "content": "والذين امنوا وعملوا الصالحات لندخلنهم في الصالحين"
    },
    {
      "surah_number": 29,
      "verse_number": 10,
      "content": "ومن الناس من يقول امنا بالله فاذا أوذي في الله جعل فتنه الناس كعذاب الله ولئن جا نصر من ربك ليقولن انا كنا معكم أوليس الله بأعلم بما في صدور العالمين"
    },
    {
      "surah_number": 29,
      "verse_number": 11,
      "content": "وليعلمن الله الذين امنوا وليعلمن المنافقين"
    },
    {
      "surah_number": 29,
      "verse_number": 12,
      "content": "وقال الذين كفروا للذين امنوا اتبعوا سبيلنا ولنحمل خطاياكم وما هم بحاملين من خطاياهم من شي انهم لكاذبون"
    },
    {
      "surah_number": 29,
      "verse_number": 13,
      "content": "وليحملن أثقالهم وأثقالا مع أثقالهم وليسٔلن يوم القيامه عما كانوا يفترون"
    },
    {
      "surah_number": 29,
      "verse_number": 14,
      "content": "ولقد أرسلنا نوحا الىا قومه فلبث فيهم ألف سنه الا خمسين عاما فأخذهم الطوفان وهم ظالمون"
    },
    {
      "surah_number": 29,
      "verse_number": 15,
      "content": "فأنجيناه وأصحاب السفينه وجعلناها ايه للعالمين"
    },
    {
      "surah_number": 29,
      "verse_number": 16,
      "content": "وابراهيم اذ قال لقومه اعبدوا الله واتقوه ذالكم خير لكم ان كنتم تعلمون"
    },
    {
      "surah_number": 29,
      "verse_number": 17,
      "content": "انما تعبدون من دون الله أوثانا وتخلقون افكا ان الذين تعبدون من دون الله لا يملكون لكم رزقا فابتغوا عند الله الرزق واعبدوه واشكروا له اليه ترجعون"
    },
    {
      "surah_number": 29,
      "verse_number": 18,
      "content": "وان تكذبوا فقد كذب أمم من قبلكم وما على الرسول الا البلاغ المبين"
    },
    {
      "surah_number": 29,
      "verse_number": 19,
      "content": "أولم يروا كيف يبدئ الله الخلق ثم يعيده ان ذالك على الله يسير"
    },
    {
      "surah_number": 29,
      "verse_number": 20,
      "content": "قل سيروا في الأرض فانظروا كيف بدأ الخلق ثم الله ينشئ النشأه الأخره ان الله علىا كل شي قدير"
    },
    {
      "surah_number": 29,
      "verse_number": 21,
      "content": "يعذب من يشا ويرحم من يشا واليه تقلبون"
    },
    {
      "surah_number": 29,
      "verse_number": 22,
      "content": "وما أنتم بمعجزين في الأرض ولا في السما وما لكم من دون الله من ولي ولا نصير"
    },
    {
      "surah_number": 29,
      "verse_number": 23,
      "content": "والذين كفروا بٔايات الله ولقائه أولائك يئسوا من رحمتي وأولائك لهم عذاب أليم"
    },
    {
      "surah_number": 29,
      "verse_number": 24,
      "content": "فما كان جواب قومه الا أن قالوا اقتلوه أو حرقوه فأنجىاه الله من النار ان في ذالك لأيات لقوم يؤمنون"
    },
    {
      "surah_number": 29,
      "verse_number": 25,
      "content": "وقال انما اتخذتم من دون الله أوثانا موده بينكم في الحيواه الدنيا ثم يوم القيامه يكفر بعضكم ببعض ويلعن بعضكم بعضا ومأوىاكم النار وما لكم من ناصرين"
    },
    {
      "surah_number": 29,
      "verse_number": 26,
      "content": "فٔامن له لوط وقال اني مهاجر الىا ربي انه هو العزيز الحكيم"
    },
    {
      "surah_number": 29,
      "verse_number": 27,
      "content": "ووهبنا له اسحاق ويعقوب وجعلنا في ذريته النبوه والكتاب واتيناه أجره في الدنيا وانه في الأخره لمن الصالحين"
    },
    {
      "surah_number": 29,
      "verse_number": 28,
      "content": "ولوطا اذ قال لقومه انكم لتأتون الفاحشه ما سبقكم بها من أحد من العالمين"
    },
    {
      "surah_number": 29,
      "verse_number": 29,
      "content": "أئنكم لتأتون الرجال وتقطعون السبيل وتأتون في ناديكم المنكر فما كان جواب قومه الا أن قالوا ائتنا بعذاب الله ان كنت من الصادقين"
    },
    {
      "surah_number": 29,
      "verse_number": 30,
      "content": "قال رب انصرني على القوم المفسدين"
    },
    {
      "surah_number": 29,
      "verse_number": 31,
      "content": "ولما جات رسلنا ابراهيم بالبشرىا قالوا انا مهلكوا أهل هاذه القريه ان أهلها كانوا ظالمين"
    },
    {
      "surah_number": 29,
      "verse_number": 32,
      "content": "قال ان فيها لوطا قالوا نحن أعلم بمن فيها لننجينه وأهله الا امرأته كانت من الغابرين"
    },
    {
      "surah_number": 29,
      "verse_number": 33,
      "content": "ولما أن جات رسلنا لوطا سي بهم وضاق بهم ذرعا وقالوا لا تخف ولا تحزن انا منجوك وأهلك الا امرأتك كانت من الغابرين"
    },
    {
      "surah_number": 29,
      "verse_number": 34,
      "content": "انا منزلون علىا أهل هاذه القريه رجزا من السما بما كانوا يفسقون"
    },
    {
      "surah_number": 29,
      "verse_number": 35,
      "content": "ولقد تركنا منها ايه بينه لقوم يعقلون"
    },
    {
      "surah_number": 29,
      "verse_number": 36,
      "content": "والىا مدين أخاهم شعيبا فقال ياقوم اعبدوا الله وارجوا اليوم الأخر ولا تعثوا في الأرض مفسدين"
    },
    {
      "surah_number": 29,
      "verse_number": 37,
      "content": "فكذبوه فأخذتهم الرجفه فأصبحوا في دارهم جاثمين"
    },
    {
      "surah_number": 29,
      "verse_number": 38,
      "content": "وعادا وثمودا وقد تبين لكم من مساكنهم وزين لهم الشيطان أعمالهم فصدهم عن السبيل وكانوا مستبصرين"
    },
    {
      "surah_number": 29,
      "verse_number": 39,
      "content": "وقارون وفرعون وهامان ولقد جاهم موسىا بالبينات فاستكبروا في الأرض وما كانوا سابقين"
    },
    {
      "surah_number": 29,
      "verse_number": 40,
      "content": "فكلا أخذنا بذنبه فمنهم من أرسلنا عليه حاصبا ومنهم من أخذته الصيحه ومنهم من خسفنا به الأرض ومنهم من أغرقنا وما كان الله ليظلمهم ولاكن كانوا أنفسهم يظلمون"
    },
    {
      "surah_number": 29,
      "verse_number": 41,
      "content": "مثل الذين اتخذوا من دون الله أوليا كمثل العنكبوت اتخذت بيتا وان أوهن البيوت لبيت العنكبوت لو كانوا يعلمون"
    },
    {
      "surah_number": 29,
      "verse_number": 42,
      "content": "ان الله يعلم ما يدعون من دونه من شي وهو العزيز الحكيم"
    },
    {
      "surah_number": 29,
      "verse_number": 43,
      "content": "وتلك الأمثال نضربها للناس وما يعقلها الا العالمون"
    },
    {
      "surah_number": 29,
      "verse_number": 44,
      "content": "خلق الله السماوات والأرض بالحق ان في ذالك لأيه للمؤمنين"
    },
    {
      "surah_number": 29,
      "verse_number": 45,
      "content": "اتل ما أوحي اليك من الكتاب وأقم الصلواه ان الصلواه تنهىا عن الفحشا والمنكر ولذكر الله أكبر والله يعلم ما تصنعون"
    },
    {
      "surah_number": 29,
      "verse_number": 46,
      "content": "ولا تجادلوا أهل الكتاب الا بالتي هي أحسن الا الذين ظلموا منهم وقولوا امنا بالذي أنزل الينا وأنزل اليكم والاهنا والاهكم واحد ونحن له مسلمون"
    },
    {
      "surah_number": 29,
      "verse_number": 47,
      "content": "وكذالك أنزلنا اليك الكتاب فالذين اتيناهم الكتاب يؤمنون به ومن هاؤلا من يؤمن به وما يجحد بٔاياتنا الا الكافرون"
    },
    {
      "surah_number": 29,
      "verse_number": 48,
      "content": "وما كنت تتلوا من قبله من كتاب ولا تخطه بيمينك اذا لارتاب المبطلون"
    },
    {
      "surah_number": 29,
      "verse_number": 49,
      "content": "بل هو ايات بينات في صدور الذين أوتوا العلم وما يجحد بٔاياتنا الا الظالمون"
    },
    {
      "surah_number": 29,
      "verse_number": 50,
      "content": "وقالوا لولا أنزل عليه ايات من ربه قل انما الأيات عند الله وانما أنا نذير مبين"
    },
    {
      "surah_number": 29,
      "verse_number": 51,
      "content": "أولم يكفهم أنا أنزلنا عليك الكتاب يتلىا عليهم ان في ذالك لرحمه وذكرىا لقوم يؤمنون"
    },
    {
      "surah_number": 29,
      "verse_number": 52,
      "content": "قل كفىا بالله بيني وبينكم شهيدا يعلم ما في السماوات والأرض والذين امنوا بالباطل وكفروا بالله أولائك هم الخاسرون"
    },
    {
      "surah_number": 29,
      "verse_number": 53,
      "content": "ويستعجلونك بالعذاب ولولا أجل مسمى لجاهم العذاب وليأتينهم بغته وهم لا يشعرون"
    },
    {
      "surah_number": 29,
      "verse_number": 54,
      "content": "يستعجلونك بالعذاب وان جهنم لمحيطه بالكافرين"
    },
    {
      "surah_number": 29,
      "verse_number": 55,
      "content": "يوم يغشىاهم العذاب من فوقهم ومن تحت أرجلهم ويقول ذوقوا ما كنتم تعملون"
    },
    {
      "surah_number": 29,
      "verse_number": 56,
      "content": "ياعبادي الذين امنوا ان أرضي واسعه فاياي فاعبدون"
    },
    {
      "surah_number": 29,
      "verse_number": 57,
      "content": "كل نفس ذائقه الموت ثم الينا ترجعون"
    },
    {
      "surah_number": 29,
      "verse_number": 58,
      "content": "والذين امنوا وعملوا الصالحات لنبوئنهم من الجنه غرفا تجري من تحتها الأنهار خالدين فيها نعم أجر العاملين"
    },
    {
      "surah_number": 29,
      "verse_number": 59,
      "content": "الذين صبروا وعلىا ربهم يتوكلون"
    },
    {
      "surah_number": 29,
      "verse_number": 60,
      "content": "وكأين من دابه لا تحمل رزقها الله يرزقها واياكم وهو السميع العليم"
    },
    {
      "surah_number": 29,
      "verse_number": 61,
      "content": "ولئن سألتهم من خلق السماوات والأرض وسخر الشمس والقمر ليقولن الله فأنىا يؤفكون"
    },
    {
      "surah_number": 29,
      "verse_number": 62,
      "content": "الله يبسط الرزق لمن يشا من عباده ويقدر له ان الله بكل شي عليم"
    },
    {
      "surah_number": 29,
      "verse_number": 63,
      "content": "ولئن سألتهم من نزل من السما ما فأحيا به الأرض من بعد موتها ليقولن الله قل الحمد لله بل أكثرهم لا يعقلون"
    },
    {
      "surah_number": 29,
      "verse_number": 64,
      "content": "وما هاذه الحيواه الدنيا الا لهو ولعب وان الدار الأخره لهي الحيوان لو كانوا يعلمون"
    },
    {
      "surah_number": 29,
      "verse_number": 65,
      "content": "فاذا ركبوا في الفلك دعوا الله مخلصين له الدين فلما نجىاهم الى البر اذا هم يشركون"
    },
    {
      "surah_number": 29,
      "verse_number": 66,
      "content": "ليكفروا بما اتيناهم وليتمتعوا فسوف يعلمون"
    },
    {
      "surah_number": 29,
      "verse_number": 67,
      "content": "أولم يروا أنا جعلنا حرما امنا ويتخطف الناس من حولهم أفبالباطل يؤمنون وبنعمه الله يكفرون"
    },
    {
      "surah_number": 29,
      "verse_number": 68,
      "content": "ومن أظلم ممن افترىا على الله كذبا أو كذب بالحق لما جاه أليس في جهنم مثوى للكافرين"
    },
    {
      "surah_number": 29,
      "verse_number": 69,
      "content": "والذين جاهدوا فينا لنهدينهم سبلنا وان الله لمع المحسنين"
    },
    {
      "surah_number": 30,
      "verse_number": 1,
      "content": "الم"
    },
    {
      "surah_number": 30,
      "verse_number": 2,
      "content": "غلبت الروم"
    },
    {
      "surah_number": 30,
      "verse_number": 3,
      "content": "في أدنى الأرض وهم من بعد غلبهم سيغلبون"
    },
    {
      "surah_number": 30,
      "verse_number": 4,
      "content": "في بضع سنين لله الأمر من قبل ومن بعد ويومئذ يفرح المؤمنون"
    },
    {
      "surah_number": 30,
      "verse_number": 5,
      "content": "بنصر الله ينصر من يشا وهو العزيز الرحيم"
    },
    {
      "surah_number": 30,
      "verse_number": 6,
      "content": "وعد الله لا يخلف الله وعده ولاكن أكثر الناس لا يعلمون"
    },
    {
      "surah_number": 30,
      "verse_number": 7,
      "content": "يعلمون ظاهرا من الحيواه الدنيا وهم عن الأخره هم غافلون"
    },
    {
      "surah_number": 30,
      "verse_number": 8,
      "content": "أولم يتفكروا في أنفسهم ما خلق الله السماوات والأرض وما بينهما الا بالحق وأجل مسمى وان كثيرا من الناس بلقاي ربهم لكافرون"
    },
    {
      "surah_number": 30,
      "verse_number": 9,
      "content": "أولم يسيروا في الأرض فينظروا كيف كان عاقبه الذين من قبلهم كانوا أشد منهم قوه وأثاروا الأرض وعمروها أكثر مما عمروها وجاتهم رسلهم بالبينات فما كان الله ليظلمهم ولاكن كانوا أنفسهم يظلمون"
    },
    {
      "surah_number": 30,
      "verse_number": 10,
      "content": "ثم كان عاقبه الذين أسأوا السوأىا أن كذبوا بٔايات الله وكانوا بها يستهزون"
    },
    {
      "surah_number": 30,
      "verse_number": 11,
      "content": "الله يبدؤا الخلق ثم يعيده ثم اليه ترجعون"
    },
    {
      "surah_number": 30,
      "verse_number": 12,
      "content": "ويوم تقوم الساعه يبلس المجرمون"
    },
    {
      "surah_number": 30,
      "verse_number": 13,
      "content": "ولم يكن لهم من شركائهم شفعاؤا وكانوا بشركائهم كافرين"
    },
    {
      "surah_number": 30,
      "verse_number": 14,
      "content": "ويوم تقوم الساعه يومئذ يتفرقون"
    },
    {
      "surah_number": 30,
      "verse_number": 15,
      "content": "فأما الذين امنوا وعملوا الصالحات فهم في روضه يحبرون"
    },
    {
      "surah_number": 30,
      "verse_number": 16,
      "content": "وأما الذين كفروا وكذبوا بٔاياتنا ولقاي الأخره فأولائك في العذاب محضرون"
    },
    {
      "surah_number": 30,
      "verse_number": 17,
      "content": "فسبحان الله حين تمسون وحين تصبحون"
    },
    {
      "surah_number": 30,
      "verse_number": 18,
      "content": "وله الحمد في السماوات والأرض وعشيا وحين تظهرون"
    },
    {
      "surah_number": 30,
      "verse_number": 19,
      "content": "يخرج الحي من الميت ويخرج الميت من الحي ويحي الأرض بعد موتها وكذالك تخرجون"
    },
    {
      "surah_number": 30,
      "verse_number": 20,
      "content": "ومن اياته أن خلقكم من تراب ثم اذا أنتم بشر تنتشرون"
    },
    {
      "surah_number": 30,
      "verse_number": 21,
      "content": "ومن اياته أن خلق لكم من أنفسكم أزواجا لتسكنوا اليها وجعل بينكم موده ورحمه ان في ذالك لأيات لقوم يتفكرون"
    },
    {
      "surah_number": 30,
      "verse_number": 22,
      "content": "ومن اياته خلق السماوات والأرض واختلاف ألسنتكم وألوانكم ان في ذالك لأيات للعالمين"
    },
    {
      "surah_number": 30,
      "verse_number": 23,
      "content": "ومن اياته منامكم باليل والنهار وابتغاؤكم من فضله ان في ذالك لأيات لقوم يسمعون"
    },
    {
      "surah_number": 30,
      "verse_number": 24,
      "content": "ومن اياته يريكم البرق خوفا وطمعا وينزل من السما ما فيحي به الأرض بعد موتها ان في ذالك لأيات لقوم يعقلون"
    },
    {
      "surah_number": 30,
      "verse_number": 25,
      "content": "ومن اياته أن تقوم السما والأرض بأمره ثم اذا دعاكم دعوه من الأرض اذا أنتم تخرجون"
    },
    {
      "surah_number": 30,
      "verse_number": 26,
      "content": "وله من في السماوات والأرض كل له قانتون"
    },
    {
      "surah_number": 30,
      "verse_number": 27,
      "content": "وهو الذي يبدؤا الخلق ثم يعيده وهو أهون عليه وله المثل الأعلىا في السماوات والأرض وهو العزيز الحكيم"
    },
    {
      "surah_number": 30,
      "verse_number": 28,
      "content": "ضرب لكم مثلا من أنفسكم هل لكم من ما ملكت أيمانكم من شركا في ما رزقناكم فأنتم فيه سوا تخافونهم كخيفتكم أنفسكم كذالك نفصل الأيات لقوم يعقلون"
    },
    {
      "surah_number": 30,
      "verse_number": 29,
      "content": "بل اتبع الذين ظلموا أهواهم بغير علم فمن يهدي من أضل الله وما لهم من ناصرين"
    },
    {
      "surah_number": 30,
      "verse_number": 30,
      "content": "فأقم وجهك للدين حنيفا فطرت الله التي فطر الناس عليها لا تبديل لخلق الله ذالك الدين القيم ولاكن أكثر الناس لا يعلمون"
    },
    {
      "surah_number": 30,
      "verse_number": 31,
      "content": "منيبين اليه واتقوه وأقيموا الصلواه ولا تكونوا من المشركين"
    },
    {
      "surah_number": 30,
      "verse_number": 32,
      "content": "من الذين فرقوا دينهم وكانوا شيعا كل حزب بما لديهم فرحون"
    },
    {
      "surah_number": 30,
      "verse_number": 33,
      "content": "واذا مس الناس ضر دعوا ربهم منيبين اليه ثم اذا أذاقهم منه رحمه اذا فريق منهم بربهم يشركون"
    },
    {
      "surah_number": 30,
      "verse_number": 34,
      "content": "ليكفروا بما اتيناهم فتمتعوا فسوف تعلمون"
    },
    {
      "surah_number": 30,
      "verse_number": 35,
      "content": "أم أنزلنا عليهم سلطانا فهو يتكلم بما كانوا به يشركون"
    },
    {
      "surah_number": 30,
      "verse_number": 36,
      "content": "واذا أذقنا الناس رحمه فرحوا بها وان تصبهم سيئه بما قدمت أيديهم اذا هم يقنطون"
    },
    {
      "surah_number": 30,
      "verse_number": 37,
      "content": "أولم يروا أن الله يبسط الرزق لمن يشا ويقدر ان في ذالك لأيات لقوم يؤمنون"
    },
    {
      "surah_number": 30,
      "verse_number": 38,
      "content": "فٔات ذا القربىا حقه والمسكين وابن السبيل ذالك خير للذين يريدون وجه الله وأولائك هم المفلحون"
    },
    {
      "surah_number": 30,
      "verse_number": 39,
      "content": "وما اتيتم من ربا ليربوا في أموال الناس فلا يربوا عند الله وما اتيتم من زكواه تريدون وجه الله فأولائك هم المضعفون"
    },
    {
      "surah_number": 30,
      "verse_number": 40,
      "content": "الله الذي خلقكم ثم رزقكم ثم يميتكم ثم يحييكم هل من شركائكم من يفعل من ذالكم من شي سبحانه وتعالىا عما يشركون"
    },
    {
      "surah_number": 30,
      "verse_number": 41,
      "content": "ظهر الفساد في البر والبحر بما كسبت أيدي الناس ليذيقهم بعض الذي عملوا لعلهم يرجعون"
    },
    {
      "surah_number": 30,
      "verse_number": 42,
      "content": "قل سيروا في الأرض فانظروا كيف كان عاقبه الذين من قبل كان أكثرهم مشركين"
    },
    {
      "surah_number": 30,
      "verse_number": 43,
      "content": "فأقم وجهك للدين القيم من قبل أن يأتي يوم لا مرد له من الله يومئذ يصدعون"
    },
    {
      "surah_number": 30,
      "verse_number": 44,
      "content": "من كفر فعليه كفره ومن عمل صالحا فلأنفسهم يمهدون"
    },
    {
      "surah_number": 30,
      "verse_number": 45,
      "content": "ليجزي الذين امنوا وعملوا الصالحات من فضله انه لا يحب الكافرين"
    },
    {
      "surah_number": 30,
      "verse_number": 46,
      "content": "ومن اياته أن يرسل الرياح مبشرات وليذيقكم من رحمته ولتجري الفلك بأمره ولتبتغوا من فضله ولعلكم تشكرون"
    },
    {
      "surah_number": 30,
      "verse_number": 47,
      "content": "ولقد أرسلنا من قبلك رسلا الىا قومهم فجاوهم بالبينات فانتقمنا من الذين أجرموا وكان حقا علينا نصر المؤمنين"
    },
    {
      "surah_number": 30,
      "verse_number": 48,
      "content": "الله الذي يرسل الرياح فتثير سحابا فيبسطه في السما كيف يشا ويجعله كسفا فترى الودق يخرج من خلاله فاذا أصاب به من يشا من عباده اذا هم يستبشرون"
    },
    {
      "surah_number": 30,
      "verse_number": 49,
      "content": "وان كانوا من قبل أن ينزل عليهم من قبله لمبلسين"
    },
    {
      "surah_number": 30,
      "verse_number": 50,
      "content": "فانظر الىا اثار رحمت الله كيف يحي الأرض بعد موتها ان ذالك لمحي الموتىا وهو علىا كل شي قدير"
    },
    {
      "surah_number": 30,
      "verse_number": 51,
      "content": "ولئن أرسلنا ريحا فرأوه مصفرا لظلوا من بعده يكفرون"
    },
    {
      "surah_number": 30,
      "verse_number": 52,
      "content": "فانك لا تسمع الموتىا ولا تسمع الصم الدعا اذا ولوا مدبرين"
    },
    {
      "surah_number": 30,
      "verse_number": 53,
      "content": "وما أنت بهاد العمي عن ضلالتهم ان تسمع الا من يؤمن بٔاياتنا فهم مسلمون"
    },
    {
      "surah_number": 30,
      "verse_number": 54,
      "content": "الله الذي خلقكم من ضعف ثم جعل من بعد ضعف قوه ثم جعل من بعد قوه ضعفا وشيبه يخلق ما يشا وهو العليم القدير"
    },
    {
      "surah_number": 30,
      "verse_number": 55,
      "content": "ويوم تقوم الساعه يقسم المجرمون ما لبثوا غير ساعه كذالك كانوا يؤفكون"
    },
    {
      "surah_number": 30,
      "verse_number": 56,
      "content": "وقال الذين أوتوا العلم والايمان لقد لبثتم في كتاب الله الىا يوم البعث فهاذا يوم البعث ولاكنكم كنتم لا تعلمون"
    },
    {
      "surah_number": 30,
      "verse_number": 57,
      "content": "فيومئذ لا ينفع الذين ظلموا معذرتهم ولا هم يستعتبون"
    },
    {
      "surah_number": 30,
      "verse_number": 58,
      "content": "ولقد ضربنا للناس في هاذا القران من كل مثل ولئن جئتهم بٔايه ليقولن الذين كفروا ان أنتم الا مبطلون"
    },
    {
      "surah_number": 30,
      "verse_number": 59,
      "content": "كذالك يطبع الله علىا قلوب الذين لا يعلمون"
    },
    {
      "surah_number": 30,
      "verse_number": 60,
      "content": "فاصبر ان وعد الله حق ولا يستخفنك الذين لا يوقنون"
    },
    {
      "surah_number": 31,
      "verse_number": 1,
      "content": "الم"
    },
    {
      "surah_number": 31,
      "verse_number": 2,
      "content": "تلك ايات الكتاب الحكيم"
    },
    {
      "surah_number": 31,
      "verse_number": 3,
      "content": "هدى ورحمه للمحسنين"
    },
    {
      "surah_number": 31,
      "verse_number": 4,
      "content": "الذين يقيمون الصلواه ويؤتون الزكواه وهم بالأخره هم يوقنون"
    },
    {
      "surah_number": 31,
      "verse_number": 5,
      "content": "أولائك علىا هدى من ربهم وأولائك هم المفلحون"
    },
    {
      "surah_number": 31,
      "verse_number": 6,
      "content": "ومن الناس من يشتري لهو الحديث ليضل عن سبيل الله بغير علم ويتخذها هزوا أولائك لهم عذاب مهين"
    },
    {
      "surah_number": 31,
      "verse_number": 7,
      "content": "واذا تتلىا عليه اياتنا ولىا مستكبرا كأن لم يسمعها كأن في أذنيه وقرا فبشره بعذاب أليم"
    },
    {
      "surah_number": 31,
      "verse_number": 8,
      "content": "ان الذين امنوا وعملوا الصالحات لهم جنات النعيم"
    },
    {
      "surah_number": 31,
      "verse_number": 9,
      "content": "خالدين فيها وعد الله حقا وهو العزيز الحكيم"
    },
    {
      "surah_number": 31,
      "verse_number": 10,
      "content": "خلق السماوات بغير عمد ترونها وألقىا في الأرض رواسي أن تميد بكم وبث فيها من كل دابه وأنزلنا من السما ما فأنبتنا فيها من كل زوج كريم"
    },
    {
      "surah_number": 31,
      "verse_number": 11,
      "content": "هاذا خلق الله فأروني ماذا خلق الذين من دونه بل الظالمون في ضلال مبين"
    },
    {
      "surah_number": 31,
      "verse_number": 12,
      "content": "ولقد اتينا لقمان الحكمه أن اشكر لله ومن يشكر فانما يشكر لنفسه ومن كفر فان الله غني حميد"
    },
    {
      "surah_number": 31,
      "verse_number": 13,
      "content": "واذ قال لقمان لابنه وهو يعظه يابني لا تشرك بالله ان الشرك لظلم عظيم"
    },
    {
      "surah_number": 31,
      "verse_number": 14,
      "content": "ووصينا الانسان بوالديه حملته أمه وهنا علىا وهن وفصاله في عامين أن اشكر لي ولوالديك الي المصير"
    },
    {
      "surah_number": 31,
      "verse_number": 15,
      "content": "وان جاهداك علىا أن تشرك بي ما ليس لك به علم فلا تطعهما وصاحبهما في الدنيا معروفا واتبع سبيل من أناب الي ثم الي مرجعكم فأنبئكم بما كنتم تعملون"
    },
    {
      "surah_number": 31,
      "verse_number": 16,
      "content": "يابني انها ان تك مثقال حبه من خردل فتكن في صخره أو في السماوات أو في الأرض يأت بها الله ان الله لطيف خبير"
    },
    {
      "surah_number": 31,
      "verse_number": 17,
      "content": "يابني أقم الصلواه وأمر بالمعروف وانه عن المنكر واصبر علىا ما أصابك ان ذالك من عزم الأمور"
    },
    {
      "surah_number": 31,
      "verse_number": 18,
      "content": "ولا تصعر خدك للناس ولا تمش في الأرض مرحا ان الله لا يحب كل مختال فخور"
    },
    {
      "surah_number": 31,
      "verse_number": 19,
      "content": "واقصد في مشيك واغضض من صوتك ان أنكر الأصوات لصوت الحمير"
    },
    {
      "surah_number": 31,
      "verse_number": 20,
      "content": "ألم تروا أن الله سخر لكم ما في السماوات وما في الأرض وأسبغ عليكم نعمه ظاهره وباطنه ومن الناس من يجادل في الله بغير علم ولا هدى ولا كتاب منير"
    },
    {
      "surah_number": 31,
      "verse_number": 21,
      "content": "واذا قيل لهم اتبعوا ما أنزل الله قالوا بل نتبع ما وجدنا عليه ابانا أولو كان الشيطان يدعوهم الىا عذاب السعير"
    },
    {
      "surah_number": 31,
      "verse_number": 22,
      "content": "ومن يسلم وجهه الى الله وهو محسن فقد استمسك بالعروه الوثقىا والى الله عاقبه الأمور"
    },
    {
      "surah_number": 31,
      "verse_number": 23,
      "content": "ومن كفر فلا يحزنك كفره الينا مرجعهم فننبئهم بما عملوا ان الله عليم بذات الصدور"
    },
    {
      "surah_number": 31,
      "verse_number": 24,
      "content": "نمتعهم قليلا ثم نضطرهم الىا عذاب غليظ"
    },
    {
      "surah_number": 31,
      "verse_number": 25,
      "content": "ولئن سألتهم من خلق السماوات والأرض ليقولن الله قل الحمد لله بل أكثرهم لا يعلمون"
    },
    {
      "surah_number": 31,
      "verse_number": 26,
      "content": "لله ما في السماوات والأرض ان الله هو الغني الحميد"
    },
    {
      "surah_number": 31,
      "verse_number": 27,
      "content": "ولو أنما في الأرض من شجره أقلام والبحر يمده من بعده سبعه أبحر ما نفدت كلمات الله ان الله عزيز حكيم"
    },
    {
      "surah_number": 31,
      "verse_number": 28,
      "content": "ما خلقكم ولا بعثكم الا كنفس واحده ان الله سميع بصير"
    },
    {
      "surah_number": 31,
      "verse_number": 29,
      "content": "ألم تر أن الله يولج اليل في النهار ويولج النهار في اليل وسخر الشمس والقمر كل يجري الىا أجل مسمى وأن الله بما تعملون خبير"
    },
    {
      "surah_number": 31,
      "verse_number": 30,
      "content": "ذالك بأن الله هو الحق وأن ما يدعون من دونه الباطل وأن الله هو العلي الكبير"
    },
    {
      "surah_number": 31,
      "verse_number": 31,
      "content": "ألم تر أن الفلك تجري في البحر بنعمت الله ليريكم من اياته ان في ذالك لأيات لكل صبار شكور"
    },
    {
      "surah_number": 31,
      "verse_number": 32,
      "content": "واذا غشيهم موج كالظلل دعوا الله مخلصين له الدين فلما نجىاهم الى البر فمنهم مقتصد وما يجحد بٔاياتنا الا كل ختار كفور"
    },
    {
      "surah_number": 31,
      "verse_number": 33,
      "content": "ياأيها الناس اتقوا ربكم واخشوا يوما لا يجزي والد عن ولده ولا مولود هو جاز عن والده شئا ان وعد الله حق فلا تغرنكم الحيواه الدنيا ولا يغرنكم بالله الغرور"
    },
    {
      "surah_number": 31,
      "verse_number": 34,
      "content": "ان الله عنده علم الساعه وينزل الغيث ويعلم ما في الأرحام وما تدري نفس ماذا تكسب غدا وما تدري نفس بأي أرض تموت ان الله عليم خبير"
    },
    {
      "surah_number": 32,
      "verse_number": 1,
      "content": "الم"
    },
    {
      "surah_number": 32,
      "verse_number": 2,
      "content": "تنزيل الكتاب لا ريب فيه من رب العالمين"
    },
    {
      "surah_number": 32,
      "verse_number": 3,
      "content": "أم يقولون افترىاه بل هو الحق من ربك لتنذر قوما ما أتىاهم من نذير من قبلك لعلهم يهتدون"
    },
    {
      "surah_number": 32,
      "verse_number": 4,
      "content": "الله الذي خلق السماوات والأرض وما بينهما في سته أيام ثم استوىا على العرش ما لكم من دونه من ولي ولا شفيع أفلا تتذكرون"
    },
    {
      "surah_number": 32,
      "verse_number": 5,
      "content": "يدبر الأمر من السما الى الأرض ثم يعرج اليه في يوم كان مقداره ألف سنه مما تعدون"
    },
    {
      "surah_number": 32,
      "verse_number": 6,
      "content": "ذالك عالم الغيب والشهاده العزيز الرحيم"
    },
    {
      "surah_number": 32,
      "verse_number": 7,
      "content": "الذي أحسن كل شي خلقه وبدأ خلق الانسان من طين"
    },
    {
      "surah_number": 32,
      "verse_number": 8,
      "content": "ثم جعل نسله من سلاله من ما مهين"
    },
    {
      "surah_number": 32,
      "verse_number": 9,
      "content": "ثم سوىاه ونفخ فيه من روحه وجعل لكم السمع والأبصار والأفٔده قليلا ما تشكرون"
    },
    {
      "surah_number": 32,
      "verse_number": 10,
      "content": "وقالوا أذا ضللنا في الأرض أنا لفي خلق جديد بل هم بلقا ربهم كافرون"
    },
    {
      "surah_number": 32,
      "verse_number": 11,
      "content": "قل يتوفىاكم ملك الموت الذي وكل بكم ثم الىا ربكم ترجعون"
    },
    {
      "surah_number": 32,
      "verse_number": 12,
      "content": "ولو ترىا اذ المجرمون ناكسوا روسهم عند ربهم ربنا أبصرنا وسمعنا فارجعنا نعمل صالحا انا موقنون"
    },
    {
      "surah_number": 32,
      "verse_number": 13,
      "content": "ولو شئنا لأتينا كل نفس هدىاها ولاكن حق القول مني لأملأن جهنم من الجنه والناس أجمعين"
    },
    {
      "surah_number": 32,
      "verse_number": 14,
      "content": "فذوقوا بما نسيتم لقا يومكم هاذا انا نسيناكم وذوقوا عذاب الخلد بما كنتم تعملون"
    },
    {
      "surah_number": 32,
      "verse_number": 15,
      "content": "انما يؤمن بٔاياتنا الذين اذا ذكروا بها خروا سجدا وسبحوا بحمد ربهم وهم لا يستكبرون"
    },
    {
      "surah_number": 32,
      "verse_number": 16,
      "content": "تتجافىا جنوبهم عن المضاجع يدعون ربهم خوفا وطمعا ومما رزقناهم ينفقون"
    },
    {
      "surah_number": 32,
      "verse_number": 17,
      "content": "فلا تعلم نفس ما أخفي لهم من قره أعين جزا بما كانوا يعملون"
    },
    {
      "surah_number": 32,
      "verse_number": 18,
      "content": "أفمن كان مؤمنا كمن كان فاسقا لا يستون"
    },
    {
      "surah_number": 32,
      "verse_number": 19,
      "content": "أما الذين امنوا وعملوا الصالحات فلهم جنات المأوىا نزلا بما كانوا يعملون"
    },
    {
      "surah_number": 32,
      "verse_number": 20,
      "content": "وأما الذين فسقوا فمأوىاهم النار كلما أرادوا أن يخرجوا منها أعيدوا فيها وقيل لهم ذوقوا عذاب النار الذي كنتم به تكذبون"
    },
    {
      "surah_number": 32,
      "verse_number": 21,
      "content": "ولنذيقنهم من العذاب الأدنىا دون العذاب الأكبر لعلهم يرجعون"
    },
    {
      "surah_number": 32,
      "verse_number": 22,
      "content": "ومن أظلم ممن ذكر بٔايات ربه ثم أعرض عنها انا من المجرمين منتقمون"
    },
    {
      "surah_number": 32,
      "verse_number": 23,
      "content": "ولقد اتينا موسى الكتاب فلا تكن في مريه من لقائه وجعلناه هدى لبني اسرايل"
    },
    {
      "surah_number": 32,
      "verse_number": 24,
      "content": "وجعلنا منهم أئمه يهدون بأمرنا لما صبروا وكانوا بٔاياتنا يوقنون"
    },
    {
      "surah_number": 32,
      "verse_number": 25,
      "content": "ان ربك هو يفصل بينهم يوم القيامه فيما كانوا فيه يختلفون"
    },
    {
      "surah_number": 32,
      "verse_number": 26,
      "content": "أولم يهد لهم كم أهلكنا من قبلهم من القرون يمشون في مساكنهم ان في ذالك لأيات أفلا يسمعون"
    },
    {
      "surah_number": 32,
      "verse_number": 27,
      "content": "أولم يروا أنا نسوق الما الى الأرض الجرز فنخرج به زرعا تأكل منه أنعامهم وأنفسهم أفلا يبصرون"
    },
    {
      "surah_number": 32,
      "verse_number": 28,
      "content": "ويقولون متىا هاذا الفتح ان كنتم صادقين"
    },
    {
      "surah_number": 32,
      "verse_number": 29,
      "content": "قل يوم الفتح لا ينفع الذين كفروا ايمانهم ولا هم ينظرون"
    },
    {
      "surah_number": 32,
      "verse_number": 30,
      "content": "فأعرض عنهم وانتظر انهم منتظرون"
    },
    {
      "surah_number": 33,
      "verse_number": 1,
      "content": "ياأيها النبي اتق الله ولا تطع الكافرين والمنافقين ان الله كان عليما حكيما"
    },
    {
      "surah_number": 33,
      "verse_number": 2,
      "content": "واتبع ما يوحىا اليك من ربك ان الله كان بما تعملون خبيرا"
    },
    {
      "surah_number": 33,
      "verse_number": 3,
      "content": "وتوكل على الله وكفىا بالله وكيلا"
    },
    {
      "surah_number": 33,
      "verse_number": 4,
      "content": "ما جعل الله لرجل من قلبين في جوفه وما جعل أزواجكم الأي تظاهرون منهن أمهاتكم وما جعل أدعياكم أبناكم ذالكم قولكم بأفواهكم والله يقول الحق وهو يهدي السبيل"
    },
    {
      "surah_number": 33,
      "verse_number": 5,
      "content": "ادعوهم لأبائهم هو أقسط عند الله فان لم تعلموا اباهم فاخوانكم في الدين ومواليكم وليس عليكم جناح فيما أخطأتم به ولاكن ما تعمدت قلوبكم وكان الله غفورا رحيما"
    },
    {
      "surah_number": 33,
      "verse_number": 6,
      "content": "النبي أولىا بالمؤمنين من أنفسهم وأزواجه أمهاتهم وأولوا الأرحام بعضهم أولىا ببعض في كتاب الله من المؤمنين والمهاجرين الا أن تفعلوا الىا أوليائكم معروفا كان ذالك في الكتاب مسطورا"
    },
    {
      "surah_number": 33,
      "verse_number": 7,
      "content": "واذ أخذنا من النبين ميثاقهم ومنك ومن نوح وابراهيم وموسىا وعيسى ابن مريم وأخذنا منهم ميثاقا غليظا"
    },
    {
      "surah_number": 33,
      "verse_number": 8,
      "content": "ليسٔل الصادقين عن صدقهم وأعد للكافرين عذابا أليما"
    },
    {
      "surah_number": 33,
      "verse_number": 9,
      "content": "ياأيها الذين امنوا اذكروا نعمه الله عليكم اذ جاتكم جنود فأرسلنا عليهم ريحا وجنودا لم تروها وكان الله بما تعملون بصيرا"
    },
    {
      "surah_number": 33,
      "verse_number": 10,
      "content": "اذ جاوكم من فوقكم ومن أسفل منكم واذ زاغت الأبصار وبلغت القلوب الحناجر وتظنون بالله الظنونا"
    },
    {
      "surah_number": 33,
      "verse_number": 11,
      "content": "هنالك ابتلي المؤمنون وزلزلوا زلزالا شديدا"
    },
    {
      "surah_number": 33,
      "verse_number": 12,
      "content": "واذ يقول المنافقون والذين في قلوبهم مرض ما وعدنا الله ورسوله الا غرورا"
    },
    {
      "surah_number": 33,
      "verse_number": 13,
      "content": "واذ قالت طائفه منهم ياأهل يثرب لا مقام لكم فارجعوا ويستٔذن فريق منهم النبي يقولون ان بيوتنا عوره وما هي بعوره ان يريدون الا فرارا"
    },
    {
      "surah_number": 33,
      "verse_number": 14,
      "content": "ولو دخلت عليهم من أقطارها ثم سئلوا الفتنه لأتوها وما تلبثوا بها الا يسيرا"
    },
    {
      "surah_number": 33,
      "verse_number": 15,
      "content": "ولقد كانوا عاهدوا الله من قبل لا يولون الأدبار وكان عهد الله مسٔولا"
    },
    {
      "surah_number": 33,
      "verse_number": 16,
      "content": "قل لن ينفعكم الفرار ان فررتم من الموت أو القتل واذا لا تمتعون الا قليلا"
    },
    {
      "surah_number": 33,
      "verse_number": 17,
      "content": "قل من ذا الذي يعصمكم من الله ان أراد بكم سوا أو أراد بكم رحمه ولا يجدون لهم من دون الله وليا ولا نصيرا"
    },
    {
      "surah_number": 33,
      "verse_number": 18,
      "content": "قد يعلم الله المعوقين منكم والقائلين لاخوانهم هلم الينا ولا يأتون البأس الا قليلا"
    },
    {
      "surah_number": 33,
      "verse_number": 19,
      "content": "أشحه عليكم فاذا جا الخوف رأيتهم ينظرون اليك تدور أعينهم كالذي يغشىا عليه من الموت فاذا ذهب الخوف سلقوكم بألسنه حداد أشحه على الخير أولائك لم يؤمنوا فأحبط الله أعمالهم وكان ذالك على الله يسيرا"
    },
    {
      "surah_number": 33,
      "verse_number": 20,
      "content": "يحسبون الأحزاب لم يذهبوا وان يأت الأحزاب يودوا لو أنهم بادون في الأعراب يسٔلون عن أنبائكم ولو كانوا فيكم ما قاتلوا الا قليلا"
    },
    {
      "surah_number": 33,
      "verse_number": 21,
      "content": "لقد كان لكم في رسول الله أسوه حسنه لمن كان يرجوا الله واليوم الأخر وذكر الله كثيرا"
    },
    {
      "surah_number": 33,
      "verse_number": 22,
      "content": "ولما را المؤمنون الأحزاب قالوا هاذا ما وعدنا الله ورسوله وصدق الله ورسوله وما زادهم الا ايمانا وتسليما"
    },
    {
      "surah_number": 33,
      "verse_number": 23,
      "content": "من المؤمنين رجال صدقوا ما عاهدوا الله عليه فمنهم من قضىا نحبه ومنهم من ينتظر وما بدلوا تبديلا"
    },
    {
      "surah_number": 33,
      "verse_number": 24,
      "content": "ليجزي الله الصادقين بصدقهم ويعذب المنافقين ان شا أو يتوب عليهم ان الله كان غفورا رحيما"
    },
    {
      "surah_number": 33,
      "verse_number": 25,
      "content": "ورد الله الذين كفروا بغيظهم لم ينالوا خيرا وكفى الله المؤمنين القتال وكان الله قويا عزيزا"
    },
    {
      "surah_number": 33,
      "verse_number": 26,
      "content": "وأنزل الذين ظاهروهم من أهل الكتاب من صياصيهم وقذف في قلوبهم الرعب فريقا تقتلون وتأسرون فريقا"
    },
    {
      "surah_number": 33,
      "verse_number": 27,
      "content": "وأورثكم أرضهم وديارهم وأموالهم وأرضا لم تطٔوها وكان الله علىا كل شي قديرا"
    },
    {
      "surah_number": 33,
      "verse_number": 28,
      "content": "ياأيها النبي قل لأزواجك ان كنتن تردن الحيواه الدنيا وزينتها فتعالين أمتعكن وأسرحكن سراحا جميلا"
    },
    {
      "surah_number": 33,
      "verse_number": 29,
      "content": "وان كنتن تردن الله ورسوله والدار الأخره فان الله أعد للمحسنات منكن أجرا عظيما"
    },
    {
      "surah_number": 33,
      "verse_number": 30,
      "content": "يانسا النبي من يأت منكن بفاحشه مبينه يضاعف لها العذاب ضعفين وكان ذالك على الله يسيرا"
    },
    {
      "surah_number": 33,
      "verse_number": 31,
      "content": "ومن يقنت منكن لله ورسوله وتعمل صالحا نؤتها أجرها مرتين وأعتدنا لها رزقا كريما"
    },
    {
      "surah_number": 33,
      "verse_number": 32,
      "content": "يانسا النبي لستن كأحد من النسا ان اتقيتن فلا تخضعن بالقول فيطمع الذي في قلبه مرض وقلن قولا معروفا"
    },
    {
      "surah_number": 33,
      "verse_number": 33,
      "content": "وقرن في بيوتكن ولا تبرجن تبرج الجاهليه الأولىا وأقمن الصلواه واتين الزكواه وأطعن الله ورسوله انما يريد الله ليذهب عنكم الرجس أهل البيت ويطهركم تطهيرا"
    },
    {
      "surah_number": 33,
      "verse_number": 34,
      "content": "واذكرن ما يتلىا في بيوتكن من ايات الله والحكمه ان الله كان لطيفا خبيرا"
    },
    {
      "surah_number": 33,
      "verse_number": 35,
      "content": "ان المسلمين والمسلمات والمؤمنين والمؤمنات والقانتين والقانتات والصادقين والصادقات والصابرين والصابرات والخاشعين والخاشعات والمتصدقين والمتصدقات والصائمين والصائمات والحافظين فروجهم والحافظات والذاكرين الله كثيرا والذاكرات أعد الله لهم مغفره وأجرا عظيما"
    },
    {
      "surah_number": 33,
      "verse_number": 36,
      "content": "وما كان لمؤمن ولا مؤمنه اذا قضى الله ورسوله أمرا أن يكون لهم الخيره من أمرهم ومن يعص الله ورسوله فقد ضل ضلالا مبينا"
    },
    {
      "surah_number": 33,
      "verse_number": 37,
      "content": "واذ تقول للذي أنعم الله عليه وأنعمت عليه أمسك عليك زوجك واتق الله وتخفي في نفسك ما الله مبديه وتخشى الناس والله أحق أن تخشىاه فلما قضىا زيد منها وطرا زوجناكها لكي لا يكون على المؤمنين حرج في أزواج أدعيائهم اذا قضوا منهن وطرا وكان أمر الله مفعولا"
    },
    {
      "surah_number": 33,
      "verse_number": 38,
      "content": "ما كان على النبي من حرج فيما فرض الله له سنه الله في الذين خلوا من قبل وكان أمر الله قدرا مقدورا"
    },
    {
      "surah_number": 33,
      "verse_number": 39,
      "content": "الذين يبلغون رسالات الله ويخشونه ولا يخشون أحدا الا الله وكفىا بالله حسيبا"
    },
    {
      "surah_number": 33,
      "verse_number": 40,
      "content": "ما كان محمد أبا أحد من رجالكم ولاكن رسول الله وخاتم النبين وكان الله بكل شي عليما"
    },
    {
      "surah_number": 33,
      "verse_number": 41,
      "content": "ياأيها الذين امنوا اذكروا الله ذكرا كثيرا"
    },
    {
      "surah_number": 33,
      "verse_number": 42,
      "content": "وسبحوه بكره وأصيلا"
    },
    {
      "surah_number": 33,
      "verse_number": 43,
      "content": "هو الذي يصلي عليكم وملائكته ليخرجكم من الظلمات الى النور وكان بالمؤمنين رحيما"
    },
    {
      "surah_number": 33,
      "verse_number": 44,
      "content": "تحيتهم يوم يلقونه سلام وأعد لهم أجرا كريما"
    },
    {
      "surah_number": 33,
      "verse_number": 45,
      "content": "ياأيها النبي انا أرسلناك شاهدا ومبشرا ونذيرا"
    },
    {
      "surah_number": 33,
      "verse_number": 46,
      "content": "وداعيا الى الله باذنه وسراجا منيرا"
    },
    {
      "surah_number": 33,
      "verse_number": 47,
      "content": "وبشر المؤمنين بأن لهم من الله فضلا كبيرا"
    },
    {
      "surah_number": 33,
      "verse_number": 48,
      "content": "ولا تطع الكافرين والمنافقين ودع أذىاهم وتوكل على الله وكفىا بالله وكيلا"
    },
    {
      "surah_number": 33,
      "verse_number": 49,
      "content": "ياأيها الذين امنوا اذا نكحتم المؤمنات ثم طلقتموهن من قبل أن تمسوهن فما لكم عليهن من عده تعتدونها فمتعوهن وسرحوهن سراحا جميلا"
    },
    {
      "surah_number": 33,
      "verse_number": 50,
      "content": "ياأيها النبي انا أحللنا لك أزواجك الاتي اتيت أجورهن وما ملكت يمينك مما أفا الله عليك وبنات عمك وبنات عماتك وبنات خالك وبنات خالاتك الاتي هاجرن معك وامرأه مؤمنه ان وهبت نفسها للنبي ان أراد النبي أن يستنكحها خالصه لك من دون المؤمنين قد علمنا ما فرضنا عليهم في أزواجهم وما ملكت أيمانهم لكيلا يكون عليك حرج وكان الله غفورا رحيما"
    },
    {
      "surah_number": 33,
      "verse_number": 51,
      "content": "ترجي من تشا منهن وتٔوي اليك من تشا ومن ابتغيت ممن عزلت فلا جناح عليك ذالك أدنىا أن تقر أعينهن ولا يحزن ويرضين بما اتيتهن كلهن والله يعلم ما في قلوبكم وكان الله عليما حليما"
    },
    {
      "surah_number": 33,
      "verse_number": 52,
      "content": "لا يحل لك النسا من بعد ولا أن تبدل بهن من أزواج ولو أعجبك حسنهن الا ما ملكت يمينك وكان الله علىا كل شي رقيبا"
    },
    {
      "surah_number": 33,
      "verse_number": 53,
      "content": "ياأيها الذين امنوا لا تدخلوا بيوت النبي الا أن يؤذن لكم الىا طعام غير ناظرين انىاه ولاكن اذا دعيتم فادخلوا فاذا طعمتم فانتشروا ولا مستٔنسين لحديث ان ذالكم كان يؤذي النبي فيستحي منكم والله لا يستحي من الحق واذا سألتموهن متاعا فسٔلوهن من ورا حجاب ذالكم أطهر لقلوبكم وقلوبهن وما كان لكم أن تؤذوا رسول الله ولا أن تنكحوا أزواجه من بعده أبدا ان ذالكم كان عند الله عظيما"
    },
    {
      "surah_number": 33,
      "verse_number": 54,
      "content": "ان تبدوا شئا أو تخفوه فان الله كان بكل شي عليما"
    },
    {
      "surah_number": 33,
      "verse_number": 55,
      "content": "لا جناح عليهن في ابائهن ولا أبنائهن ولا اخوانهن ولا أبنا اخوانهن ولا أبنا أخواتهن ولا نسائهن ولا ما ملكت أيمانهن واتقين الله ان الله كان علىا كل شي شهيدا"
    },
    {
      "surah_number": 33,
      "verse_number": 56,
      "content": "ان الله وملائكته يصلون على النبي ياأيها الذين امنوا صلوا عليه وسلموا تسليما"
    },
    {
      "surah_number": 33,
      "verse_number": 57,
      "content": "ان الذين يؤذون الله ورسوله لعنهم الله في الدنيا والأخره وأعد لهم عذابا مهينا"
    },
    {
      "surah_number": 33,
      "verse_number": 58,
      "content": "والذين يؤذون المؤمنين والمؤمنات بغير ما اكتسبوا فقد احتملوا بهتانا واثما مبينا"
    },
    {
      "surah_number": 33,
      "verse_number": 59,
      "content": "ياأيها النبي قل لأزواجك وبناتك ونسا المؤمنين يدنين عليهن من جلابيبهن ذالك أدنىا أن يعرفن فلا يؤذين وكان الله غفورا رحيما"
    },
    {
      "surah_number": 33,
      "verse_number": 60,
      "content": "لئن لم ينته المنافقون والذين في قلوبهم مرض والمرجفون في المدينه لنغرينك بهم ثم لا يجاورونك فيها الا قليلا"
    },
    {
      "surah_number": 33,
      "verse_number": 61,
      "content": "ملعونين أينما ثقفوا أخذوا وقتلوا تقتيلا"
    },
    {
      "surah_number": 33,
      "verse_number": 62,
      "content": "سنه الله في الذين خلوا من قبل ولن تجد لسنه الله تبديلا"
    },
    {
      "surah_number": 33,
      "verse_number": 63,
      "content": "يسٔلك الناس عن الساعه قل انما علمها عند الله وما يدريك لعل الساعه تكون قريبا"
    },
    {
      "surah_number": 33,
      "verse_number": 64,
      "content": "ان الله لعن الكافرين وأعد لهم سعيرا"
    },
    {
      "surah_number": 33,
      "verse_number": 65,
      "content": "خالدين فيها أبدا لا يجدون وليا ولا نصيرا"
    },
    {
      "surah_number": 33,
      "verse_number": 66,
      "content": "يوم تقلب وجوههم في النار يقولون ياليتنا أطعنا الله وأطعنا الرسولا"
    },
    {
      "surah_number": 33,
      "verse_number": 67,
      "content": "وقالوا ربنا انا أطعنا سادتنا وكبرانا فأضلونا السبيلا"
    },
    {
      "surah_number": 33,
      "verse_number": 68,
      "content": "ربنا اتهم ضعفين من العذاب والعنهم لعنا كبيرا"
    },
    {
      "surah_number": 33,
      "verse_number": 69,
      "content": "ياأيها الذين امنوا لا تكونوا كالذين اذوا موسىا فبرأه الله مما قالوا وكان عند الله وجيها"
    },
    {
      "surah_number": 33,
      "verse_number": 70,
      "content": "ياأيها الذين امنوا اتقوا الله وقولوا قولا سديدا"
    },
    {
      "surah_number": 33,
      "verse_number": 71,
      "content": "يصلح لكم أعمالكم ويغفر لكم ذنوبكم ومن يطع الله ورسوله فقد فاز فوزا عظيما"
    },
    {
      "surah_number": 33,
      "verse_number": 72,
      "content": "انا عرضنا الأمانه على السماوات والأرض والجبال فأبين أن يحملنها وأشفقن منها وحملها الانسان انه كان ظلوما جهولا"
    },
    {
      "surah_number": 33,
      "verse_number": 73,
      "content": "ليعذب الله المنافقين والمنافقات والمشركين والمشركات ويتوب الله على المؤمنين والمؤمنات وكان الله غفورا رحيما"
    },
    {
      "surah_number": 34,
      "verse_number": 1,
      "content": "الحمد لله الذي له ما في السماوات وما في الأرض وله الحمد في الأخره وهو الحكيم الخبير"
    },
    {
      "surah_number": 34,
      "verse_number": 2,
      "content": "يعلم ما يلج في الأرض وما يخرج منها وما ينزل من السما وما يعرج فيها وهو الرحيم الغفور"
    },
    {
      "surah_number": 34,
      "verse_number": 3,
      "content": "وقال الذين كفروا لا تأتينا الساعه قل بلىا وربي لتأتينكم عالم الغيب لا يعزب عنه مثقال ذره في السماوات ولا في الأرض ولا أصغر من ذالك ولا أكبر الا في كتاب مبين"
    },
    {
      "surah_number": 34,
      "verse_number": 4,
      "content": "ليجزي الذين امنوا وعملوا الصالحات أولائك لهم مغفره ورزق كريم"
    },
    {
      "surah_number": 34,
      "verse_number": 5,
      "content": "والذين سعو في اياتنا معاجزين أولائك لهم عذاب من رجز أليم"
    },
    {
      "surah_number": 34,
      "verse_number": 6,
      "content": "ويرى الذين أوتوا العلم الذي أنزل اليك من ربك هو الحق ويهدي الىا صراط العزيز الحميد"
    },
    {
      "surah_number": 34,
      "verse_number": 7,
      "content": "وقال الذين كفروا هل ندلكم علىا رجل ينبئكم اذا مزقتم كل ممزق انكم لفي خلق جديد"
    },
    {
      "surah_number": 34,
      "verse_number": 8,
      "content": "أفترىا على الله كذبا أم به جنه بل الذين لا يؤمنون بالأخره في العذاب والضلال البعيد"
    },
    {
      "surah_number": 34,
      "verse_number": 9,
      "content": "أفلم يروا الىا ما بين أيديهم وما خلفهم من السما والأرض ان نشأ نخسف بهم الأرض أو نسقط عليهم كسفا من السما ان في ذالك لأيه لكل عبد منيب"
    },
    {
      "surah_number": 34,
      "verse_number": 10,
      "content": "ولقد اتينا داود منا فضلا ياجبال أوبي معه والطير وألنا له الحديد"
    },
    {
      "surah_number": 34,
      "verse_number": 11,
      "content": "أن اعمل سابغات وقدر في السرد واعملوا صالحا اني بما تعملون بصير"
    },
    {
      "surah_number": 34,
      "verse_number": 12,
      "content": "ولسليمان الريح غدوها شهر ورواحها شهر وأسلنا له عين القطر ومن الجن من يعمل بين يديه باذن ربه ومن يزغ منهم عن أمرنا نذقه من عذاب السعير"
    },
    {
      "surah_number": 34,
      "verse_number": 13,
      "content": "يعملون له ما يشا من محاريب وتماثيل وجفان كالجواب وقدور راسيات اعملوا ال داود شكرا وقليل من عبادي الشكور"
    },
    {
      "surah_number": 34,
      "verse_number": 14,
      "content": "فلما قضينا عليه الموت ما دلهم علىا موته الا دابه الأرض تأكل منسأته فلما خر تبينت الجن أن لو كانوا يعلمون الغيب ما لبثوا في العذاب المهين"
    },
    {
      "surah_number": 34,
      "verse_number": 15,
      "content": "لقد كان لسبا في مسكنهم ايه جنتان عن يمين وشمال كلوا من رزق ربكم واشكروا له بلده طيبه ورب غفور"
    },
    {
      "surah_number": 34,
      "verse_number": 16,
      "content": "فأعرضوا فأرسلنا عليهم سيل العرم وبدلناهم بجنتيهم جنتين ذواتي أكل خمط وأثل وشي من سدر قليل"
    },
    {
      "surah_number": 34,
      "verse_number": 17,
      "content": "ذالك جزيناهم بما كفروا وهل نجازي الا الكفور"
    },
    {
      "surah_number": 34,
      "verse_number": 18,
      "content": "وجعلنا بينهم وبين القرى التي باركنا فيها قرى ظاهره وقدرنا فيها السير سيروا فيها ليالي وأياما امنين"
    },
    {
      "surah_number": 34,
      "verse_number": 19,
      "content": "فقالوا ربنا باعد بين أسفارنا وظلموا أنفسهم فجعلناهم أحاديث ومزقناهم كل ممزق ان في ذالك لأيات لكل صبار شكور"
    },
    {
      "surah_number": 34,
      "verse_number": 20,
      "content": "ولقد صدق عليهم ابليس ظنه فاتبعوه الا فريقا من المؤمنين"
    },
    {
      "surah_number": 34,
      "verse_number": 21,
      "content": "وما كان له عليهم من سلطان الا لنعلم من يؤمن بالأخره ممن هو منها في شك وربك علىا كل شي حفيظ"
    },
    {
      "surah_number": 34,
      "verse_number": 22,
      "content": "قل ادعوا الذين زعمتم من دون الله لا يملكون مثقال ذره في السماوات ولا في الأرض وما لهم فيهما من شرك وما له منهم من ظهير"
    },
    {
      "surah_number": 34,
      "verse_number": 23,
      "content": "ولا تنفع الشفاعه عنده الا لمن أذن له حتىا اذا فزع عن قلوبهم قالوا ماذا قال ربكم قالوا الحق وهو العلي الكبير"
    },
    {
      "surah_number": 34,
      "verse_number": 24,
      "content": "قل من يرزقكم من السماوات والأرض قل الله وانا أو اياكم لعلىا هدى أو في ضلال مبين"
    },
    {
      "surah_number": 34,
      "verse_number": 25,
      "content": "قل لا تسٔلون عما أجرمنا ولا نسٔل عما تعملون"
    },
    {
      "surah_number": 34,
      "verse_number": 26,
      "content": "قل يجمع بيننا ربنا ثم يفتح بيننا بالحق وهو الفتاح العليم"
    },
    {
      "surah_number": 34,
      "verse_number": 27,
      "content": "قل أروني الذين ألحقتم به شركا كلا بل هو الله العزيز الحكيم"
    },
    {
      "surah_number": 34,
      "verse_number": 28,
      "content": "وما أرسلناك الا كافه للناس بشيرا ونذيرا ولاكن أكثر الناس لا يعلمون"
    },
    {
      "surah_number": 34,
      "verse_number": 29,
      "content": "ويقولون متىا هاذا الوعد ان كنتم صادقين"
    },
    {
      "surah_number": 34,
      "verse_number": 30,
      "content": "قل لكم ميعاد يوم لا تستٔخرون عنه ساعه ولا تستقدمون"
    },
    {
      "surah_number": 34,
      "verse_number": 31,
      "content": "وقال الذين كفروا لن نؤمن بهاذا القران ولا بالذي بين يديه ولو ترىا اذ الظالمون موقوفون عند ربهم يرجع بعضهم الىا بعض القول يقول الذين استضعفوا للذين استكبروا لولا أنتم لكنا مؤمنين"
    },
    {
      "surah_number": 34,
      "verse_number": 32,
      "content": "قال الذين استكبروا للذين استضعفوا أنحن صددناكم عن الهدىا بعد اذ جاكم بل كنتم مجرمين"
    },
    {
      "surah_number": 34,
      "verse_number": 33,
      "content": "وقال الذين استضعفوا للذين استكبروا بل مكر اليل والنهار اذ تأمروننا أن نكفر بالله ونجعل له أندادا وأسروا الندامه لما رأوا العذاب وجعلنا الأغلال في أعناق الذين كفروا هل يجزون الا ما كانوا يعملون"
    },
    {
      "surah_number": 34,
      "verse_number": 34,
      "content": "وما أرسلنا في قريه من نذير الا قال مترفوها انا بما أرسلتم به كافرون"
    },
    {
      "surah_number": 34,
      "verse_number": 35,
      "content": "وقالوا نحن أكثر أموالا وأولادا وما نحن بمعذبين"
    },
    {
      "surah_number": 34,
      "verse_number": 36,
      "content": "قل ان ربي يبسط الرزق لمن يشا ويقدر ولاكن أكثر الناس لا يعلمون"
    },
    {
      "surah_number": 34,
      "verse_number": 37,
      "content": "وما أموالكم ولا أولادكم بالتي تقربكم عندنا زلفىا الا من امن وعمل صالحا فأولائك لهم جزا الضعف بما عملوا وهم في الغرفات امنون"
    },
    {
      "surah_number": 34,
      "verse_number": 38,
      "content": "والذين يسعون في اياتنا معاجزين أولائك في العذاب محضرون"
    },
    {
      "surah_number": 34,
      "verse_number": 39,
      "content": "قل ان ربي يبسط الرزق لمن يشا من عباده ويقدر له وما أنفقتم من شي فهو يخلفه وهو خير الرازقين"
    },
    {
      "surah_number": 34,
      "verse_number": 40,
      "content": "ويوم يحشرهم جميعا ثم يقول للملائكه أهاؤلا اياكم كانوا يعبدون"
    },
    {
      "surah_number": 34,
      "verse_number": 41,
      "content": "قالوا سبحانك أنت ولينا من دونهم بل كانوا يعبدون الجن أكثرهم بهم مؤمنون"
    },
    {
      "surah_number": 34,
      "verse_number": 42,
      "content": "فاليوم لا يملك بعضكم لبعض نفعا ولا ضرا ونقول للذين ظلموا ذوقوا عذاب النار التي كنتم بها تكذبون"
    },
    {
      "surah_number": 34,
      "verse_number": 43,
      "content": "واذا تتلىا عليهم اياتنا بينات قالوا ما هاذا الا رجل يريد أن يصدكم عما كان يعبد اباؤكم وقالوا ما هاذا الا افك مفترى وقال الذين كفروا للحق لما جاهم ان هاذا الا سحر مبين"
    },
    {
      "surah_number": 34,
      "verse_number": 44,
      "content": "وما اتيناهم من كتب يدرسونها وما أرسلنا اليهم قبلك من نذير"
    },
    {
      "surah_number": 34,
      "verse_number": 45,
      "content": "وكذب الذين من قبلهم وما بلغوا معشار ما اتيناهم فكذبوا رسلي فكيف كان نكير"
    },
    {
      "surah_number": 34,
      "verse_number": 46,
      "content": "قل انما أعظكم بواحده أن تقوموا لله مثنىا وفرادىا ثم تتفكروا ما بصاحبكم من جنه ان هو الا نذير لكم بين يدي عذاب شديد"
    },
    {
      "surah_number": 34,
      "verse_number": 47,
      "content": "قل ما سألتكم من أجر فهو لكم ان أجري الا على الله وهو علىا كل شي شهيد"
    },
    {
      "surah_number": 34,
      "verse_number": 48,
      "content": "قل ان ربي يقذف بالحق علام الغيوب"
    },
    {
      "surah_number": 34,
      "verse_number": 49,
      "content": "قل جا الحق وما يبدئ الباطل وما يعيد"
    },
    {
      "surah_number": 34,
      "verse_number": 50,
      "content": "قل ان ضللت فانما أضل علىا نفسي وان اهتديت فبما يوحي الي ربي انه سميع قريب"
    },
    {
      "surah_number": 34,
      "verse_number": 51,
      "content": "ولو ترىا اذ فزعوا فلا فوت وأخذوا من مكان قريب"
    },
    {
      "surah_number": 34,
      "verse_number": 52,
      "content": "وقالوا امنا به وأنىا لهم التناوش من مكان بعيد"
    },
    {
      "surah_number": 34,
      "verse_number": 53,
      "content": "وقد كفروا به من قبل ويقذفون بالغيب من مكان بعيد"
    },
    {
      "surah_number": 34,
      "verse_number": 54,
      "content": "وحيل بينهم وبين ما يشتهون كما فعل بأشياعهم من قبل انهم كانوا في شك مريب"
    },
    {
      "surah_number": 35,
      "verse_number": 1,
      "content": "الحمد لله فاطر السماوات والأرض جاعل الملائكه رسلا أولي أجنحه مثنىا وثلاث ورباع يزيد في الخلق ما يشا ان الله علىا كل شي قدير"
    },
    {
      "surah_number": 35,
      "verse_number": 2,
      "content": "ما يفتح الله للناس من رحمه فلا ممسك لها وما يمسك فلا مرسل له من بعده وهو العزيز الحكيم"
    },
    {
      "surah_number": 35,
      "verse_number": 3,
      "content": "ياأيها الناس اذكروا نعمت الله عليكم هل من خالق غير الله يرزقكم من السما والأرض لا الاه الا هو فأنىا تؤفكون"
    },
    {
      "surah_number": 35,
      "verse_number": 4,
      "content": "وان يكذبوك فقد كذبت رسل من قبلك والى الله ترجع الأمور"
    },
    {
      "surah_number": 35,
      "verse_number": 5,
      "content": "ياأيها الناس ان وعد الله حق فلا تغرنكم الحيواه الدنيا ولا يغرنكم بالله الغرور"
    },
    {
      "surah_number": 35,
      "verse_number": 6,
      "content": "ان الشيطان لكم عدو فاتخذوه عدوا انما يدعوا حزبه ليكونوا من أصحاب السعير"
    },
    {
      "surah_number": 35,
      "verse_number": 7,
      "content": "الذين كفروا لهم عذاب شديد والذين امنوا وعملوا الصالحات لهم مغفره وأجر كبير"
    },
    {
      "surah_number": 35,
      "verse_number": 8,
      "content": "أفمن زين له سو عمله فراه حسنا فان الله يضل من يشا ويهدي من يشا فلا تذهب نفسك عليهم حسرات ان الله عليم بما يصنعون"
    },
    {
      "surah_number": 35,
      "verse_number": 9,
      "content": "والله الذي أرسل الرياح فتثير سحابا فسقناه الىا بلد ميت فأحيينا به الأرض بعد موتها كذالك النشور"
    },
    {
      "surah_number": 35,
      "verse_number": 10,
      "content": "من كان يريد العزه فلله العزه جميعا اليه يصعد الكلم الطيب والعمل الصالح يرفعه والذين يمكرون السئات لهم عذاب شديد ومكر أولائك هو يبور"
    },
    {
      "surah_number": 35,
      "verse_number": 11,
      "content": "والله خلقكم من تراب ثم من نطفه ثم جعلكم أزواجا وما تحمل من أنثىا ولا تضع الا بعلمه وما يعمر من معمر ولا ينقص من عمره الا في كتاب ان ذالك على الله يسير"
    },
    {
      "surah_number": 35,
      "verse_number": 12,
      "content": "وما يستوي البحران هاذا عذب فرات سائغ شرابه وهاذا ملح أجاج ومن كل تأكلون لحما طريا وتستخرجون حليه تلبسونها وترى الفلك فيه مواخر لتبتغوا من فضله ولعلكم تشكرون"
    },
    {
      "surah_number": 35,
      "verse_number": 13,
      "content": "يولج اليل في النهار ويولج النهار في اليل وسخر الشمس والقمر كل يجري لأجل مسمى ذالكم الله ربكم له الملك والذين تدعون من دونه ما يملكون من قطمير"
    },
    {
      "surah_number": 35,
      "verse_number": 14,
      "content": "ان تدعوهم لا يسمعوا دعاكم ولو سمعوا ما استجابوا لكم ويوم القيامه يكفرون بشرككم ولا ينبئك مثل خبير"
    },
    {
      "surah_number": 35,
      "verse_number": 15,
      "content": "ياأيها الناس أنتم الفقرا الى الله والله هو الغني الحميد"
    },
    {
      "surah_number": 35,
      "verse_number": 16,
      "content": "ان يشأ يذهبكم ويأت بخلق جديد"
    },
    {
      "surah_number": 35,
      "verse_number": 17,
      "content": "وما ذالك على الله بعزيز"
    },
    {
      "surah_number": 35,
      "verse_number": 18,
      "content": "ولا تزر وازره وزر أخرىا وان تدع مثقله الىا حملها لا يحمل منه شي ولو كان ذا قربىا انما تنذر الذين يخشون ربهم بالغيب وأقاموا الصلواه ومن تزكىا فانما يتزكىا لنفسه والى الله المصير"
    },
    {
      "surah_number": 35,
      "verse_number": 19,
      "content": "وما يستوي الأعمىا والبصير"
    },
    {
      "surah_number": 35,
      "verse_number": 20,
      "content": "ولا الظلمات ولا النور"
    },
    {
      "surah_number": 35,
      "verse_number": 21,
      "content": "ولا الظل ولا الحرور"
    },
    {
      "surah_number": 35,
      "verse_number": 22,
      "content": "وما يستوي الأحيا ولا الأموات ان الله يسمع من يشا وما أنت بمسمع من في القبور"
    },
    {
      "surah_number": 35,
      "verse_number": 23,
      "content": "ان أنت الا نذير"
    },
    {
      "surah_number": 35,
      "verse_number": 24,
      "content": "انا أرسلناك بالحق بشيرا ونذيرا وان من أمه الا خلا فيها نذير"
    },
    {
      "surah_number": 35,
      "verse_number": 25,
      "content": "وان يكذبوك فقد كذب الذين من قبلهم جاتهم رسلهم بالبينات وبالزبر وبالكتاب المنير"
    },
    {
      "surah_number": 35,
      "verse_number": 26,
      "content": "ثم أخذت الذين كفروا فكيف كان نكير"
    },
    {
      "surah_number": 35,
      "verse_number": 27,
      "content": "ألم تر أن الله أنزل من السما ما فأخرجنا به ثمرات مختلفا ألوانها ومن الجبال جدد بيض وحمر مختلف ألوانها وغرابيب سود"
    },
    {
      "surah_number": 35,
      "verse_number": 28,
      "content": "ومن الناس والدواب والأنعام مختلف ألوانه كذالك انما يخشى الله من عباده العلماؤا ان الله عزيز غفور"
    },
    {
      "surah_number": 35,
      "verse_number": 29,
      "content": "ان الذين يتلون كتاب الله وأقاموا الصلواه وأنفقوا مما رزقناهم سرا وعلانيه يرجون تجاره لن تبور"
    },
    {
      "surah_number": 35,
      "verse_number": 30,
      "content": "ليوفيهم أجورهم ويزيدهم من فضله انه غفور شكور"
    },
    {
      "surah_number": 35,
      "verse_number": 31,
      "content": "والذي أوحينا اليك من الكتاب هو الحق مصدقا لما بين يديه ان الله بعباده لخبير بصير"
    },
    {
      "surah_number": 35,
      "verse_number": 32,
      "content": "ثم أورثنا الكتاب الذين اصطفينا من عبادنا فمنهم ظالم لنفسه ومنهم مقتصد ومنهم سابق بالخيرات باذن الله ذالك هو الفضل الكبير"
    },
    {
      "surah_number": 35,
      "verse_number": 33,
      "content": "جنات عدن يدخلونها يحلون فيها من أساور من ذهب ولؤلؤا ولباسهم فيها حرير"
    },
    {
      "surah_number": 35,
      "verse_number": 34,
      "content": "وقالوا الحمد لله الذي أذهب عنا الحزن ان ربنا لغفور شكور"
    },
    {
      "surah_number": 35,
      "verse_number": 35,
      "content": "الذي أحلنا دار المقامه من فضله لا يمسنا فيها نصب ولا يمسنا فيها لغوب"
    },
    {
      "surah_number": 35,
      "verse_number": 36,
      "content": "والذين كفروا لهم نار جهنم لا يقضىا عليهم فيموتوا ولا يخفف عنهم من عذابها كذالك نجزي كل كفور"
    },
    {
      "surah_number": 35,
      "verse_number": 37,
      "content": "وهم يصطرخون فيها ربنا أخرجنا نعمل صالحا غير الذي كنا نعمل أولم نعمركم ما يتذكر فيه من تذكر وجاكم النذير فذوقوا فما للظالمين من نصير"
    },
    {
      "surah_number": 35,
      "verse_number": 38,
      "content": "ان الله عالم غيب السماوات والأرض انه عليم بذات الصدور"
    },
    {
      "surah_number": 35,
      "verse_number": 39,
      "content": "هو الذي جعلكم خلائف في الأرض فمن كفر فعليه كفره ولا يزيد الكافرين كفرهم عند ربهم الا مقتا ولا يزيد الكافرين كفرهم الا خسارا"
    },
    {
      "surah_number": 35,
      "verse_number": 40,
      "content": "قل أريتم شركاكم الذين تدعون من دون الله أروني ماذا خلقوا من الأرض أم لهم شرك في السماوات أم اتيناهم كتابا فهم علىا بينت منه بل ان يعد الظالمون بعضهم بعضا الا غرورا"
    },
    {
      "surah_number": 35,
      "verse_number": 41,
      "content": "ان الله يمسك السماوات والأرض أن تزولا ولئن زالتا ان أمسكهما من أحد من بعده انه كان حليما غفورا"
    },
    {
      "surah_number": 35,
      "verse_number": 42,
      "content": "وأقسموا بالله جهد أيمانهم لئن جاهم نذير ليكونن أهدىا من احدى الأمم فلما جاهم نذير ما زادهم الا نفورا"
    },
    {
      "surah_number": 35,
      "verse_number": 43,
      "content": "استكبارا في الأرض ومكر السيي ولا يحيق المكر السيئ الا بأهله فهل ينظرون الا سنت الأولين فلن تجد لسنت الله تبديلا ولن تجد لسنت الله تحويلا"
    },
    {
      "surah_number": 35,
      "verse_number": 44,
      "content": "أولم يسيروا في الأرض فينظروا كيف كان عاقبه الذين من قبلهم وكانوا أشد منهم قوه وما كان الله ليعجزه من شي في السماوات ولا في الأرض انه كان عليما قديرا"
    },
    {
      "surah_number": 35,
      "verse_number": 45,
      "content": "ولو يؤاخذ الله الناس بما كسبوا ما ترك علىا ظهرها من دابه ولاكن يؤخرهم الىا أجل مسمى فاذا جا أجلهم فان الله كان بعباده بصيرا"
    },
    {
      "surah_number": 36,
      "verse_number": 1,
      "content": "يس"
    },
    {
      "surah_number": 36,
      "verse_number": 2,
      "content": "والقران الحكيم"
    },
    {
      "surah_number": 36,
      "verse_number": 3,
      "content": "انك لمن المرسلين"
    },
    {
      "surah_number": 36,
      "verse_number": 4,
      "content": "علىا صراط مستقيم"
    },
    {
      "surah_number": 36,
      "verse_number": 5,
      "content": "تنزيل العزيز الرحيم"
    },
    {
      "surah_number": 36,
      "verse_number": 6,
      "content": "لتنذر قوما ما أنذر اباؤهم فهم غافلون"
    },
    {
      "surah_number": 36,
      "verse_number": 7,
      "content": "لقد حق القول علىا أكثرهم فهم لا يؤمنون"
    },
    {
      "surah_number": 36,
      "verse_number": 8,
      "content": "انا جعلنا في أعناقهم أغلالا فهي الى الأذقان فهم مقمحون"
    },
    {
      "surah_number": 36,
      "verse_number": 9,
      "content": "وجعلنا من بين أيديهم سدا ومن خلفهم سدا فأغشيناهم فهم لا يبصرون"
    },
    {
      "surah_number": 36,
      "verse_number": 10,
      "content": "وسوا عليهم ءأنذرتهم أم لم تنذرهم لا يؤمنون"
    },
    {
      "surah_number": 36,
      "verse_number": 11,
      "content": "انما تنذر من اتبع الذكر وخشي الرحمان بالغيب فبشره بمغفره وأجر كريم"
    },
    {
      "surah_number": 36,
      "verse_number": 12,
      "content": "انا نحن نحي الموتىا ونكتب ما قدموا واثارهم وكل شي أحصيناه في امام مبين"
    },
    {
      "surah_number": 36,
      "verse_number": 13,
      "content": "واضرب لهم مثلا أصحاب القريه اذ جاها المرسلون"
    },
    {
      "surah_number": 36,
      "verse_number": 14,
      "content": "اذ أرسلنا اليهم اثنين فكذبوهما فعززنا بثالث فقالوا انا اليكم مرسلون"
    },
    {
      "surah_number": 36,
      "verse_number": 15,
      "content": "قالوا ما أنتم الا بشر مثلنا وما أنزل الرحمان من شي ان أنتم الا تكذبون"
    },
    {
      "surah_number": 36,
      "verse_number": 16,
      "content": "قالوا ربنا يعلم انا اليكم لمرسلون"
    },
    {
      "surah_number": 36,
      "verse_number": 17,
      "content": "وما علينا الا البلاغ المبين"
    },
    {
      "surah_number": 36,
      "verse_number": 18,
      "content": "قالوا انا تطيرنا بكم لئن لم تنتهوا لنرجمنكم وليمسنكم منا عذاب أليم"
    },
    {
      "surah_number": 36,
      "verse_number": 19,
      "content": "قالوا طائركم معكم أئن ذكرتم بل أنتم قوم مسرفون"
    },
    {
      "surah_number": 36,
      "verse_number": 20,
      "content": "وجا من أقصا المدينه رجل يسعىا قال ياقوم اتبعوا المرسلين"
    },
    {
      "surah_number": 36,
      "verse_number": 21,
      "content": "اتبعوا من لا يسٔلكم أجرا وهم مهتدون"
    },
    {
      "surah_number": 36,
      "verse_number": 22,
      "content": "ومالي لا أعبد الذي فطرني واليه ترجعون"
    },
    {
      "surah_number": 36,
      "verse_number": 23,
      "content": "ءأتخذ من دونه الهه ان يردن الرحمان بضر لا تغن عني شفاعتهم شئا ولا ينقذون"
    },
    {
      "surah_number": 36,
      "verse_number": 24,
      "content": "اني اذا لفي ضلال مبين"
    },
    {
      "surah_number": 36,
      "verse_number": 25,
      "content": "اني امنت بربكم فاسمعون"
    },
    {
      "surah_number": 36,
      "verse_number": 26,
      "content": "قيل ادخل الجنه قال ياليت قومي يعلمون"
    },
    {
      "surah_number": 36,
      "verse_number": 27,
      "content": "بما غفر لي ربي وجعلني من المكرمين"
    },
    {
      "surah_number": 36,
      "verse_number": 28,
      "content": "وما أنزلنا علىا قومه من بعده من جند من السما وما كنا منزلين"
    },
    {
      "surah_number": 36,
      "verse_number": 29,
      "content": "ان كانت الا صيحه واحده فاذا هم خامدون"
    },
    {
      "surah_number": 36,
      "verse_number": 30,
      "content": "ياحسره على العباد ما يأتيهم من رسول الا كانوا به يستهزون"
    },
    {
      "surah_number": 36,
      "verse_number": 31,
      "content": "ألم يروا كم أهلكنا قبلهم من القرون أنهم اليهم لا يرجعون"
    },
    {
      "surah_number": 36,
      "verse_number": 32,
      "content": "وان كل لما جميع لدينا محضرون"
    },
    {
      "surah_number": 36,
      "verse_number": 33,
      "content": "وايه لهم الأرض الميته أحييناها وأخرجنا منها حبا فمنه يأكلون"
    },
    {
      "surah_number": 36,
      "verse_number": 34,
      "content": "وجعلنا فيها جنات من نخيل وأعناب وفجرنا فيها من العيون"
    },
    {
      "surah_number": 36,
      "verse_number": 35,
      "content": "ليأكلوا من ثمره وما عملته أيديهم أفلا يشكرون"
    },
    {
      "surah_number": 36,
      "verse_number": 36,
      "content": "سبحان الذي خلق الأزواج كلها مما تنبت الأرض ومن أنفسهم ومما لا يعلمون"
    },
    {
      "surah_number": 36,
      "verse_number": 37,
      "content": "وايه لهم اليل نسلخ منه النهار فاذا هم مظلمون"
    },
    {
      "surah_number": 36,
      "verse_number": 38,
      "content": "والشمس تجري لمستقر لها ذالك تقدير العزيز العليم"
    },
    {
      "surah_number": 36,
      "verse_number": 39,
      "content": "والقمر قدرناه منازل حتىا عاد كالعرجون القديم"
    },
    {
      "surah_number": 36,
      "verse_number": 40,
      "content": "لا الشمس ينبغي لها أن تدرك القمر ولا اليل سابق النهار وكل في فلك يسبحون"
    },
    {
      "surah_number": 36,
      "verse_number": 41,
      "content": "وايه لهم أنا حملنا ذريتهم في الفلك المشحون"
    },
    {
      "surah_number": 36,
      "verse_number": 42,
      "content": "وخلقنا لهم من مثله ما يركبون"
    },
    {
      "surah_number": 36,
      "verse_number": 43,
      "content": "وان نشأ نغرقهم فلا صريخ لهم ولا هم ينقذون"
    },
    {
      "surah_number": 36,
      "verse_number": 44,
      "content": "الا رحمه منا ومتاعا الىا حين"
    },
    {
      "surah_number": 36,
      "verse_number": 45,
      "content": "واذا قيل لهم اتقوا ما بين أيديكم وما خلفكم لعلكم ترحمون"
    },
    {
      "surah_number": 36,
      "verse_number": 46,
      "content": "وما تأتيهم من ايه من ايات ربهم الا كانوا عنها معرضين"
    },
    {
      "surah_number": 36,
      "verse_number": 47,
      "content": "واذا قيل لهم أنفقوا مما رزقكم الله قال الذين كفروا للذين امنوا أنطعم من لو يشا الله أطعمه ان أنتم الا في ضلال مبين"
    },
    {
      "surah_number": 36,
      "verse_number": 48,
      "content": "ويقولون متىا هاذا الوعد ان كنتم صادقين"
    },
    {
      "surah_number": 36,
      "verse_number": 49,
      "content": "ما ينظرون الا صيحه واحده تأخذهم وهم يخصمون"
    },
    {
      "surah_number": 36,
      "verse_number": 50,
      "content": "فلا يستطيعون توصيه ولا الىا أهلهم يرجعون"
    },
    {
      "surah_number": 36,
      "verse_number": 51,
      "content": "ونفخ في الصور فاذا هم من الأجداث الىا ربهم ينسلون"
    },
    {
      "surah_number": 36,
      "verse_number": 52,
      "content": "قالوا ياويلنا من بعثنا من مرقدنا هاذا ما وعد الرحمان وصدق المرسلون"
    },
    {
      "surah_number": 36,
      "verse_number": 53,
      "content": "ان كانت الا صيحه واحده فاذا هم جميع لدينا محضرون"
    },
    {
      "surah_number": 36,
      "verse_number": 54,
      "content": "فاليوم لا تظلم نفس شئا ولا تجزون الا ما كنتم تعملون"
    },
    {
      "surah_number": 36,
      "verse_number": 55,
      "content": "ان أصحاب الجنه اليوم في شغل فاكهون"
    },
    {
      "surah_number": 36,
      "verse_number": 56,
      "content": "هم وأزواجهم في ظلال على الأرائك متكٔون"
    },
    {
      "surah_number": 36,
      "verse_number": 57,
      "content": "لهم فيها فاكهه ولهم ما يدعون"
    },
    {
      "surah_number": 36,
      "verse_number": 58,
      "content": "سلام قولا من رب رحيم"
    },
    {
      "surah_number": 36,
      "verse_number": 59,
      "content": "وامتازوا اليوم أيها المجرمون"
    },
    {
      "surah_number": 36,
      "verse_number": 60,
      "content": "ألم أعهد اليكم يابني ادم أن لا تعبدوا الشيطان انه لكم عدو مبين"
    },
    {
      "surah_number": 36,
      "verse_number": 61,
      "content": "وأن اعبدوني هاذا صراط مستقيم"
    },
    {
      "surah_number": 36,
      "verse_number": 62,
      "content": "ولقد أضل منكم جبلا كثيرا أفلم تكونوا تعقلون"
    },
    {
      "surah_number": 36,
      "verse_number": 63,
      "content": "هاذه جهنم التي كنتم توعدون"
    },
    {
      "surah_number": 36,
      "verse_number": 64,
      "content": "اصلوها اليوم بما كنتم تكفرون"
    },
    {
      "surah_number": 36,
      "verse_number": 65,
      "content": "اليوم نختم علىا أفواههم وتكلمنا أيديهم وتشهد أرجلهم بما كانوا يكسبون"
    },
    {
      "surah_number": 36,
      "verse_number": 66,
      "content": "ولو نشا لطمسنا علىا أعينهم فاستبقوا الصراط فأنىا يبصرون"
    },
    {
      "surah_number": 36,
      "verse_number": 67,
      "content": "ولو نشا لمسخناهم علىا مكانتهم فما استطاعوا مضيا ولا يرجعون"
    },
    {
      "surah_number": 36,
      "verse_number": 68,
      "content": "ومن نعمره ننكسه في الخلق أفلا يعقلون"
    },
    {
      "surah_number": 36,
      "verse_number": 69,
      "content": "وما علمناه الشعر وما ينبغي له ان هو الا ذكر وقران مبين"
    },
    {
      "surah_number": 36,
      "verse_number": 70,
      "content": "لينذر من كان حيا ويحق القول على الكافرين"
    },
    {
      "surah_number": 36,
      "verse_number": 71,
      "content": "أولم يروا أنا خلقنا لهم مما عملت أيدينا أنعاما فهم لها مالكون"
    },
    {
      "surah_number": 36,
      "verse_number": 72,
      "content": "وذللناها لهم فمنها ركوبهم ومنها يأكلون"
    },
    {
      "surah_number": 36,
      "verse_number": 73,
      "content": "ولهم فيها منافع ومشارب أفلا يشكرون"
    },
    {
      "surah_number": 36,
      "verse_number": 74,
      "content": "واتخذوا من دون الله الهه لعلهم ينصرون"
    },
    {
      "surah_number": 36,
      "verse_number": 75,
      "content": "لا يستطيعون نصرهم وهم لهم جند محضرون"
    },
    {
      "surah_number": 36,
      "verse_number": 76,
      "content": "فلا يحزنك قولهم انا نعلم ما يسرون وما يعلنون"
    },
    {
      "surah_number": 36,
      "verse_number": 77,
      "content": "أولم ير الانسان أنا خلقناه من نطفه فاذا هو خصيم مبين"
    },
    {
      "surah_number": 36,
      "verse_number": 78,
      "content": "وضرب لنا مثلا ونسي خلقه قال من يحي العظام وهي رميم"
    },
    {
      "surah_number": 36,
      "verse_number": 79,
      "content": "قل يحييها الذي أنشأها أول مره وهو بكل خلق عليم"
    },
    {
      "surah_number": 36,
      "verse_number": 80,
      "content": "الذي جعل لكم من الشجر الأخضر نارا فاذا أنتم منه توقدون"
    },
    {
      "surah_number": 36,
      "verse_number": 81,
      "content": "أوليس الذي خلق السماوات والأرض بقادر علىا أن يخلق مثلهم بلىا وهو الخلاق العليم"
    },
    {
      "surah_number": 36,
      "verse_number": 82,
      "content": "انما أمره اذا أراد شئا أن يقول له كن فيكون"
    },
    {
      "surah_number": 36,
      "verse_number": 83,
      "content": "فسبحان الذي بيده ملكوت كل شي واليه ترجعون"
    },
    {
      "surah_number": 37,
      "verse_number": 1,
      "content": "والصافات صفا"
    },
    {
      "surah_number": 37,
      "verse_number": 2,
      "content": "فالزاجرات زجرا"
    },
    {
      "surah_number": 37,
      "verse_number": 3,
      "content": "فالتاليات ذكرا"
    },
    {
      "surah_number": 37,
      "verse_number": 4,
      "content": "ان الاهكم لواحد"
    },
    {
      "surah_number": 37,
      "verse_number": 5,
      "content": "رب السماوات والأرض وما بينهما ورب المشارق"
    },
    {
      "surah_number": 37,
      "verse_number": 6,
      "content": "انا زينا السما الدنيا بزينه الكواكب"
    },
    {
      "surah_number": 37,
      "verse_number": 7,
      "content": "وحفظا من كل شيطان مارد"
    },
    {
      "surah_number": 37,
      "verse_number": 8,
      "content": "لا يسمعون الى الملا الأعلىا ويقذفون من كل جانب"
    },
    {
      "surah_number": 37,
      "verse_number": 9,
      "content": "دحورا ولهم عذاب واصب"
    },
    {
      "surah_number": 37,
      "verse_number": 10,
      "content": "الا من خطف الخطفه فأتبعه شهاب ثاقب"
    },
    {
      "surah_number": 37,
      "verse_number": 11,
      "content": "فاستفتهم أهم أشد خلقا أم من خلقنا انا خلقناهم من طين لازب"
    },
    {
      "surah_number": 37,
      "verse_number": 12,
      "content": "بل عجبت ويسخرون"
    },
    {
      "surah_number": 37,
      "verse_number": 13,
      "content": "واذا ذكروا لا يذكرون"
    },
    {
      "surah_number": 37,
      "verse_number": 14,
      "content": "واذا رأوا ايه يستسخرون"
    },
    {
      "surah_number": 37,
      "verse_number": 15,
      "content": "وقالوا ان هاذا الا سحر مبين"
    },
    {
      "surah_number": 37,
      "verse_number": 16,
      "content": "أذا متنا وكنا ترابا وعظاما أنا لمبعوثون"
    },
    {
      "surah_number": 37,
      "verse_number": 17,
      "content": "أواباؤنا الأولون"
    },
    {
      "surah_number": 37,
      "verse_number": 18,
      "content": "قل نعم وأنتم داخرون"
    },
    {
      "surah_number": 37,
      "verse_number": 19,
      "content": "فانما هي زجره واحده فاذا هم ينظرون"
    },
    {
      "surah_number": 37,
      "verse_number": 20,
      "content": "وقالوا ياويلنا هاذا يوم الدين"
    },
    {
      "surah_number": 37,
      "verse_number": 21,
      "content": "هاذا يوم الفصل الذي كنتم به تكذبون"
    },
    {
      "surah_number": 37,
      "verse_number": 22,
      "content": "احشروا الذين ظلموا وأزواجهم وما كانوا يعبدون"
    },
    {
      "surah_number": 37,
      "verse_number": 23,
      "content": "من دون الله فاهدوهم الىا صراط الجحيم"
    },
    {
      "surah_number": 37,
      "verse_number": 24,
      "content": "وقفوهم انهم مسٔولون"
    },
    {
      "surah_number": 37,
      "verse_number": 25,
      "content": "ما لكم لا تناصرون"
    },
    {
      "surah_number": 37,
      "verse_number": 26,
      "content": "بل هم اليوم مستسلمون"
    },
    {
      "surah_number": 37,
      "verse_number": 27,
      "content": "وأقبل بعضهم علىا بعض يتسالون"
    },
    {
      "surah_number": 37,
      "verse_number": 28,
      "content": "قالوا انكم كنتم تأتوننا عن اليمين"
    },
    {
      "surah_number": 37,
      "verse_number": 29,
      "content": "قالوا بل لم تكونوا مؤمنين"
    },
    {
      "surah_number": 37,
      "verse_number": 30,
      "content": "وما كان لنا عليكم من سلطان بل كنتم قوما طاغين"
    },
    {
      "surah_number": 37,
      "verse_number": 31,
      "content": "فحق علينا قول ربنا انا لذائقون"
    },
    {
      "surah_number": 37,
      "verse_number": 32,
      "content": "فأغويناكم انا كنا غاوين"
    },
    {
      "surah_number": 37,
      "verse_number": 33,
      "content": "فانهم يومئذ في العذاب مشتركون"
    },
    {
      "surah_number": 37,
      "verse_number": 34,
      "content": "انا كذالك نفعل بالمجرمين"
    },
    {
      "surah_number": 37,
      "verse_number": 35,
      "content": "انهم كانوا اذا قيل لهم لا الاه الا الله يستكبرون"
    },
    {
      "surah_number": 37,
      "verse_number": 36,
      "content": "ويقولون أئنا لتاركوا الهتنا لشاعر مجنون"
    },
    {
      "surah_number": 37,
      "verse_number": 37,
      "content": "بل جا بالحق وصدق المرسلين"
    },
    {
      "surah_number": 37,
      "verse_number": 38,
      "content": "انكم لذائقوا العذاب الأليم"
    },
    {
      "surah_number": 37,
      "verse_number": 39,
      "content": "وما تجزون الا ما كنتم تعملون"
    },
    {
      "surah_number": 37,
      "verse_number": 40,
      "content": "الا عباد الله المخلصين"
    },
    {
      "surah_number": 37,
      "verse_number": 41,
      "content": "أولائك لهم رزق معلوم"
    },
    {
      "surah_number": 37,
      "verse_number": 42,
      "content": "فواكه وهم مكرمون"
    },
    {
      "surah_number": 37,
      "verse_number": 43,
      "content": "في جنات النعيم"
    },
    {
      "surah_number": 37,
      "verse_number": 44,
      "content": "علىا سرر متقابلين"
    },
    {
      "surah_number": 37,
      "verse_number": 45,
      "content": "يطاف عليهم بكأس من معين"
    },
    {
      "surah_number": 37,
      "verse_number": 46,
      "content": "بيضا لذه للشاربين"
    },
    {
      "surah_number": 37,
      "verse_number": 47,
      "content": "لا فيها غول ولا هم عنها ينزفون"
    },
    {
      "surah_number": 37,
      "verse_number": 48,
      "content": "وعندهم قاصرات الطرف عين"
    },
    {
      "surah_number": 37,
      "verse_number": 49,
      "content": "كأنهن بيض مكنون"
    },
    {
      "surah_number": 37,
      "verse_number": 50,
      "content": "فأقبل بعضهم علىا بعض يتسالون"
    },
    {
      "surah_number": 37,
      "verse_number": 51,
      "content": "قال قائل منهم اني كان لي قرين"
    },
    {
      "surah_number": 37,
      "verse_number": 52,
      "content": "يقول أنك لمن المصدقين"
    },
    {
      "surah_number": 37,
      "verse_number": 53,
      "content": "أذا متنا وكنا ترابا وعظاما أنا لمدينون"
    },
    {
      "surah_number": 37,
      "verse_number": 54,
      "content": "قال هل أنتم مطلعون"
    },
    {
      "surah_number": 37,
      "verse_number": 55,
      "content": "فاطلع فراه في سوا الجحيم"
    },
    {
      "surah_number": 37,
      "verse_number": 56,
      "content": "قال تالله ان كدت لتردين"
    },
    {
      "surah_number": 37,
      "verse_number": 57,
      "content": "ولولا نعمه ربي لكنت من المحضرين"
    },
    {
      "surah_number": 37,
      "verse_number": 58,
      "content": "أفما نحن بميتين"
    },
    {
      "surah_number": 37,
      "verse_number": 59,
      "content": "الا موتتنا الأولىا وما نحن بمعذبين"
    },
    {
      "surah_number": 37,
      "verse_number": 60,
      "content": "ان هاذا لهو الفوز العظيم"
    },
    {
      "surah_number": 37,
      "verse_number": 61,
      "content": "لمثل هاذا فليعمل العاملون"
    },
    {
      "surah_number": 37,
      "verse_number": 62,
      "content": "أذالك خير نزلا أم شجره الزقوم"
    },
    {
      "surah_number": 37,
      "verse_number": 63,
      "content": "انا جعلناها فتنه للظالمين"
    },
    {
      "surah_number": 37,
      "verse_number": 64,
      "content": "انها شجره تخرج في أصل الجحيم"
    },
    {
      "surah_number": 37,
      "verse_number": 65,
      "content": "طلعها كأنه روس الشياطين"
    },
    {
      "surah_number": 37,
      "verse_number": 66,
      "content": "فانهم لأكلون منها فمالٔون منها البطون"
    },
    {
      "surah_number": 37,
      "verse_number": 67,
      "content": "ثم ان لهم عليها لشوبا من حميم"
    },
    {
      "surah_number": 37,
      "verse_number": 68,
      "content": "ثم ان مرجعهم لالى الجحيم"
    },
    {
      "surah_number": 37,
      "verse_number": 69,
      "content": "انهم ألفوا اباهم ضالين"
    },
    {
      "surah_number": 37,
      "verse_number": 70,
      "content": "فهم علىا اثارهم يهرعون"
    },
    {
      "surah_number": 37,
      "verse_number": 71,
      "content": "ولقد ضل قبلهم أكثر الأولين"
    },
    {
      "surah_number": 37,
      "verse_number": 72,
      "content": "ولقد أرسلنا فيهم منذرين"
    },
    {
      "surah_number": 37,
      "verse_number": 73,
      "content": "فانظر كيف كان عاقبه المنذرين"
    },
    {
      "surah_number": 37,
      "verse_number": 74,
      "content": "الا عباد الله المخلصين"
    },
    {
      "surah_number": 37,
      "verse_number": 75,
      "content": "ولقد نادىانا نوح فلنعم المجيبون"
    },
    {
      "surah_number": 37,
      "verse_number": 76,
      "content": "ونجيناه وأهله من الكرب العظيم"
    },
    {
      "surah_number": 37,
      "verse_number": 77,
      "content": "وجعلنا ذريته هم الباقين"
    },
    {
      "surah_number": 37,
      "verse_number": 78,
      "content": "وتركنا عليه في الأخرين"
    },
    {
      "surah_number": 37,
      "verse_number": 79,
      "content": "سلام علىا نوح في العالمين"
    },
    {
      "surah_number": 37,
      "verse_number": 80,
      "content": "انا كذالك نجزي المحسنين"
    },
    {
      "surah_number": 37,
      "verse_number": 81,
      "content": "انه من عبادنا المؤمنين"
    },
    {
      "surah_number": 37,
      "verse_number": 82,
      "content": "ثم أغرقنا الأخرين"
    },
    {
      "surah_number": 37,
      "verse_number": 83,
      "content": "وان من شيعته لابراهيم"
    },
    {
      "surah_number": 37,
      "verse_number": 84,
      "content": "اذ جا ربه بقلب سليم"
    },
    {
      "surah_number": 37,
      "verse_number": 85,
      "content": "اذ قال لأبيه وقومه ماذا تعبدون"
    },
    {
      "surah_number": 37,
      "verse_number": 86,
      "content": "أئفكا الهه دون الله تريدون"
    },
    {
      "surah_number": 37,
      "verse_number": 87,
      "content": "فما ظنكم برب العالمين"
    },
    {
      "surah_number": 37,
      "verse_number": 88,
      "content": "فنظر نظره في النجوم"
    },
    {
      "surah_number": 37,
      "verse_number": 89,
      "content": "فقال اني سقيم"
    },
    {
      "surah_number": 37,
      "verse_number": 90,
      "content": "فتولوا عنه مدبرين"
    },
    {
      "surah_number": 37,
      "verse_number": 91,
      "content": "فراغ الىا الهتهم فقال ألا تأكلون"
    },
    {
      "surah_number": 37,
      "verse_number": 92,
      "content": "ما لكم لا تنطقون"
    },
    {
      "surah_number": 37,
      "verse_number": 93,
      "content": "فراغ عليهم ضربا باليمين"
    },
    {
      "surah_number": 37,
      "verse_number": 94,
      "content": "فأقبلوا اليه يزفون"
    },
    {
      "surah_number": 37,
      "verse_number": 95,
      "content": "قال أتعبدون ما تنحتون"
    },
    {
      "surah_number": 37,
      "verse_number": 96,
      "content": "والله خلقكم وما تعملون"
    },
    {
      "surah_number": 37,
      "verse_number": 97,
      "content": "قالوا ابنوا له بنيانا فألقوه في الجحيم"
    },
    {
      "surah_number": 37,
      "verse_number": 98,
      "content": "فأرادوا به كيدا فجعلناهم الأسفلين"
    },
    {
      "surah_number": 37,
      "verse_number": 99,
      "content": "وقال اني ذاهب الىا ربي سيهدين"
    },
    {
      "surah_number": 37,
      "verse_number": 100,
      "content": "رب هب لي من الصالحين"
    },
    {
      "surah_number": 37,
      "verse_number": 101,
      "content": "فبشرناه بغلام حليم"
    },
    {
      "surah_number": 37,
      "verse_number": 102,
      "content": "فلما بلغ معه السعي قال يابني اني أرىا في المنام أني أذبحك فانظر ماذا ترىا قال ياأبت افعل ما تؤمر ستجدني ان شا الله من الصابرين"
    },
    {
      "surah_number": 37,
      "verse_number": 103,
      "content": "فلما أسلما وتله للجبين"
    },
    {
      "surah_number": 37,
      "verse_number": 104,
      "content": "وناديناه أن ياابراهيم"
    },
    {
      "surah_number": 37,
      "verse_number": 105,
      "content": "قد صدقت الريا انا كذالك نجزي المحسنين"
    },
    {
      "surah_number": 37,
      "verse_number": 106,
      "content": "ان هاذا لهو البلاؤا المبين"
    },
    {
      "surah_number": 37,
      "verse_number": 107,
      "content": "وفديناه بذبح عظيم"
    },
    {
      "surah_number": 37,
      "verse_number": 108,
      "content": "وتركنا عليه في الأخرين"
    },
    {
      "surah_number": 37,
      "verse_number": 109,
      "content": "سلام علىا ابراهيم"
    },
    {
      "surah_number": 37,
      "verse_number": 110,
      "content": "كذالك نجزي المحسنين"
    },
    {
      "surah_number": 37,
      "verse_number": 111,
      "content": "انه من عبادنا المؤمنين"
    },
    {
      "surah_number": 37,
      "verse_number": 112,
      "content": "وبشرناه باسحاق نبيا من الصالحين"
    },
    {
      "surah_number": 37,
      "verse_number": 113,
      "content": "وباركنا عليه وعلىا اسحاق ومن ذريتهما محسن وظالم لنفسه مبين"
    },
    {
      "surah_number": 37,
      "verse_number": 114,
      "content": "ولقد مننا علىا موسىا وهارون"
    },
    {
      "surah_number": 37,
      "verse_number": 115,
      "content": "ونجيناهما وقومهما من الكرب العظيم"
    },
    {
      "surah_number": 37,
      "verse_number": 116,
      "content": "ونصرناهم فكانوا هم الغالبين"
    },
    {
      "surah_number": 37,
      "verse_number": 117,
      "content": "واتيناهما الكتاب المستبين"
    },
    {
      "surah_number": 37,
      "verse_number": 118,
      "content": "وهديناهما الصراط المستقيم"
    },
    {
      "surah_number": 37,
      "verse_number": 119,
      "content": "وتركنا عليهما في الأخرين"
    },
    {
      "surah_number": 37,
      "verse_number": 120,
      "content": "سلام علىا موسىا وهارون"
    },
    {
      "surah_number": 37,
      "verse_number": 121,
      "content": "انا كذالك نجزي المحسنين"
    },
    {
      "surah_number": 37,
      "verse_number": 122,
      "content": "انهما من عبادنا المؤمنين"
    },
    {
      "surah_number": 37,
      "verse_number": 123,
      "content": "وان الياس لمن المرسلين"
    },
    {
      "surah_number": 37,
      "verse_number": 124,
      "content": "اذ قال لقومه ألا تتقون"
    },
    {
      "surah_number": 37,
      "verse_number": 125,
      "content": "أتدعون بعلا وتذرون أحسن الخالقين"
    },
    {
      "surah_number": 37,
      "verse_number": 126,
      "content": "الله ربكم ورب ابائكم الأولين"
    },
    {
      "surah_number": 37,
      "verse_number": 127,
      "content": "فكذبوه فانهم لمحضرون"
    },
    {
      "surah_number": 37,
      "verse_number": 128,
      "content": "الا عباد الله المخلصين"
    },
    {
      "surah_number": 37,
      "verse_number": 129,
      "content": "وتركنا عليه في الأخرين"
    },
    {
      "surah_number": 37,
      "verse_number": 130,
      "content": "سلام علىا ال ياسين"
    },
    {
      "surah_number": 37,
      "verse_number": 131,
      "content": "انا كذالك نجزي المحسنين"
    },
    {
      "surah_number": 37,
      "verse_number": 132,
      "content": "انه من عبادنا المؤمنين"
    },
    {
      "surah_number": 37,
      "verse_number": 133,
      "content": "وان لوطا لمن المرسلين"
    },
    {
      "surah_number": 37,
      "verse_number": 134,
      "content": "اذ نجيناه وأهله أجمعين"
    },
    {
      "surah_number": 37,
      "verse_number": 135,
      "content": "الا عجوزا في الغابرين"
    },
    {
      "surah_number": 37,
      "verse_number": 136,
      "content": "ثم دمرنا الأخرين"
    },
    {
      "surah_number": 37,
      "verse_number": 137,
      "content": "وانكم لتمرون عليهم مصبحين"
    },
    {
      "surah_number": 37,
      "verse_number": 138,
      "content": "وباليل أفلا تعقلون"
    },
    {
      "surah_number": 37,
      "verse_number": 139,
      "content": "وان يونس لمن المرسلين"
    },
    {
      "surah_number": 37,
      "verse_number": 140,
      "content": "اذ أبق الى الفلك المشحون"
    },
    {
      "surah_number": 37,
      "verse_number": 141,
      "content": "فساهم فكان من المدحضين"
    },
    {
      "surah_number": 37,
      "verse_number": 142,
      "content": "فالتقمه الحوت وهو مليم"
    },
    {
      "surah_number": 37,
      "verse_number": 143,
      "content": "فلولا أنه كان من المسبحين"
    },
    {
      "surah_number": 37,
      "verse_number": 144,
      "content": "للبث في بطنه الىا يوم يبعثون"
    },
    {
      "surah_number": 37,
      "verse_number": 145,
      "content": "فنبذناه بالعرا وهو سقيم"
    },
    {
      "surah_number": 37,
      "verse_number": 146,
      "content": "وأنبتنا عليه شجره من يقطين"
    },
    {
      "surah_number": 37,
      "verse_number": 147,
      "content": "وأرسلناه الىا مائه ألف أو يزيدون"
    },
    {
      "surah_number": 37,
      "verse_number": 148,
      "content": "فٔامنوا فمتعناهم الىا حين"
    },
    {
      "surah_number": 37,
      "verse_number": 149,
      "content": "فاستفتهم ألربك البنات ولهم البنون"
    },
    {
      "surah_number": 37,
      "verse_number": 150,
      "content": "أم خلقنا الملائكه اناثا وهم شاهدون"
    },
    {
      "surah_number": 37,
      "verse_number": 151,
      "content": "ألا انهم من افكهم ليقولون"
    },
    {
      "surah_number": 37,
      "verse_number": 152,
      "content": "ولد الله وانهم لكاذبون"
    },
    {
      "surah_number": 37,
      "verse_number": 153,
      "content": "أصطفى البنات على البنين"
    },
    {
      "surah_number": 37,
      "verse_number": 154,
      "content": "ما لكم كيف تحكمون"
    },
    {
      "surah_number": 37,
      "verse_number": 155,
      "content": "أفلا تذكرون"
    },
    {
      "surah_number": 37,
      "verse_number": 156,
      "content": "أم لكم سلطان مبين"
    },
    {
      "surah_number": 37,
      "verse_number": 157,
      "content": "فأتوا بكتابكم ان كنتم صادقين"
    },
    {
      "surah_number": 37,
      "verse_number": 158,
      "content": "وجعلوا بينه وبين الجنه نسبا ولقد علمت الجنه انهم لمحضرون"
    },
    {
      "surah_number": 37,
      "verse_number": 159,
      "content": "سبحان الله عما يصفون"
    },
    {
      "surah_number": 37,
      "verse_number": 160,
      "content": "الا عباد الله المخلصين"
    },
    {
      "surah_number": 37,
      "verse_number": 161,
      "content": "فانكم وما تعبدون"
    },
    {
      "surah_number": 37,
      "verse_number": 162,
      "content": "ما أنتم عليه بفاتنين"
    },
    {
      "surah_number": 37,
      "verse_number": 163,
      "content": "الا من هو صال الجحيم"
    },
    {
      "surah_number": 37,
      "verse_number": 164,
      "content": "ومامنا الا له مقام معلوم"
    },
    {
      "surah_number": 37,
      "verse_number": 165,
      "content": "وانا لنحن الصافون"
    },
    {
      "surah_number": 37,
      "verse_number": 166,
      "content": "وانا لنحن المسبحون"
    },
    {
      "surah_number": 37,
      "verse_number": 167,
      "content": "وان كانوا ليقولون"
    },
    {
      "surah_number": 37,
      "verse_number": 168,
      "content": "لو أن عندنا ذكرا من الأولين"
    },
    {
      "surah_number": 37,
      "verse_number": 169,
      "content": "لكنا عباد الله المخلصين"
    },
    {
      "surah_number": 37,
      "verse_number": 170,
      "content": "فكفروا به فسوف يعلمون"
    },
    {
      "surah_number": 37,
      "verse_number": 171,
      "content": "ولقد سبقت كلمتنا لعبادنا المرسلين"
    },
    {
      "surah_number": 37,
      "verse_number": 172,
      "content": "انهم لهم المنصورون"
    },
    {
      "surah_number": 37,
      "verse_number": 173,
      "content": "وان جندنا لهم الغالبون"
    },
    {
      "surah_number": 37,
      "verse_number": 174,
      "content": "فتول عنهم حتىا حين"
    },
    {
      "surah_number": 37,
      "verse_number": 175,
      "content": "وأبصرهم فسوف يبصرون"
    },
    {
      "surah_number": 37,
      "verse_number": 176,
      "content": "أفبعذابنا يستعجلون"
    },
    {
      "surah_number": 37,
      "verse_number": 177,
      "content": "فاذا نزل بساحتهم فسا صباح المنذرين"
    },
    {
      "surah_number": 37,
      "verse_number": 178,
      "content": "وتول عنهم حتىا حين"
    },
    {
      "surah_number": 37,
      "verse_number": 179,
      "content": "وأبصر فسوف يبصرون"
    },
    {
      "surah_number": 37,
      "verse_number": 180,
      "content": "سبحان ربك رب العزه عما يصفون"
    },
    {
      "surah_number": 37,
      "verse_number": 181,
      "content": "وسلام على المرسلين"
    },
    {
      "surah_number": 37,
      "verse_number": 182,
      "content": "والحمد لله رب العالمين"
    },
    {
      "surah_number": 38,
      "verse_number": 1,
      "content": "ص والقران ذي الذكر"
    },
    {
      "surah_number": 38,
      "verse_number": 2,
      "content": "بل الذين كفروا في عزه وشقاق"
    },
    {
      "surah_number": 38,
      "verse_number": 3,
      "content": "كم أهلكنا من قبلهم من قرن فنادوا ولات حين مناص"
    },
    {
      "surah_number": 38,
      "verse_number": 4,
      "content": "وعجبوا أن جاهم منذر منهم وقال الكافرون هاذا ساحر كذاب"
    },
    {
      "surah_number": 38,
      "verse_number": 5,
      "content": "أجعل الألهه الاها واحدا ان هاذا لشي عجاب"
    },
    {
      "surah_number": 38,
      "verse_number": 6,
      "content": "وانطلق الملأ منهم أن امشوا واصبروا علىا الهتكم ان هاذا لشي يراد"
    },
    {
      "surah_number": 38,
      "verse_number": 7,
      "content": "ما سمعنا بهاذا في المله الأخره ان هاذا الا اختلاق"
    },
    {
      "surah_number": 38,
      "verse_number": 8,
      "content": "أنزل عليه الذكر من بيننا بل هم في شك من ذكري بل لما يذوقوا عذاب"
    },
    {
      "surah_number": 38,
      "verse_number": 9,
      "content": "أم عندهم خزائن رحمه ربك العزيز الوهاب"
    },
    {
      "surah_number": 38,
      "verse_number": 10,
      "content": "أم لهم ملك السماوات والأرض وما بينهما فليرتقوا في الأسباب"
    },
    {
      "surah_number": 38,
      "verse_number": 11,
      "content": "جند ما هنالك مهزوم من الأحزاب"
    },
    {
      "surah_number": 38,
      "verse_number": 12,
      "content": "كذبت قبلهم قوم نوح وعاد وفرعون ذو الأوتاد"
    },
    {
      "surah_number": 38,
      "verse_number": 13,
      "content": "وثمود وقوم لوط وأصحاب لٔيكه أولائك الأحزاب"
    },
    {
      "surah_number": 38,
      "verse_number": 14,
      "content": "ان كل الا كذب الرسل فحق عقاب"
    },
    {
      "surah_number": 38,
      "verse_number": 15,
      "content": "وما ينظر هاؤلا الا صيحه واحده ما لها من فواق"
    },
    {
      "surah_number": 38,
      "verse_number": 16,
      "content": "وقالوا ربنا عجل لنا قطنا قبل يوم الحساب"
    },
    {
      "surah_number": 38,
      "verse_number": 17,
      "content": "اصبر علىا ما يقولون واذكر عبدنا داود ذا الأيد انه أواب"
    },
    {
      "surah_number": 38,
      "verse_number": 18,
      "content": "انا سخرنا الجبال معه يسبحن بالعشي والاشراق"
    },
    {
      "surah_number": 38,
      "verse_number": 19,
      "content": "والطير محشوره كل له أواب"
    },
    {
      "surah_number": 38,
      "verse_number": 20,
      "content": "وشددنا ملكه واتيناه الحكمه وفصل الخطاب"
    },
    {
      "surah_number": 38,
      "verse_number": 21,
      "content": "وهل أتىاك نبؤا الخصم اذ تسوروا المحراب"
    },
    {
      "surah_number": 38,
      "verse_number": 22,
      "content": "اذ دخلوا علىا داود ففزع منهم قالوا لا تخف خصمان بغىا بعضنا علىا بعض فاحكم بيننا بالحق ولا تشطط واهدنا الىا سوا الصراط"
    },
    {
      "surah_number": 38,
      "verse_number": 23,
      "content": "ان هاذا أخي له تسع وتسعون نعجه ولي نعجه واحده فقال أكفلنيها وعزني في الخطاب"
    },
    {
      "surah_number": 38,
      "verse_number": 24,
      "content": "قال لقد ظلمك بسؤال نعجتك الىا نعاجه وان كثيرا من الخلطا ليبغي بعضهم علىا بعض الا الذين امنوا وعملوا الصالحات وقليل ما هم وظن داود أنما فتناه فاستغفر ربه وخر راكعا وأناب"
    },
    {
      "surah_number": 38,
      "verse_number": 25,
      "content": "فغفرنا له ذالك وان له عندنا لزلفىا وحسن مٔاب"
    },
    {
      "surah_number": 38,
      "verse_number": 26,
      "content": "ياداود انا جعلناك خليفه في الأرض فاحكم بين الناس بالحق ولا تتبع الهوىا فيضلك عن سبيل الله ان الذين يضلون عن سبيل الله لهم عذاب شديد بما نسوا يوم الحساب"
    },
    {
      "surah_number": 38,
      "verse_number": 27,
      "content": "وما خلقنا السما والأرض وما بينهما باطلا ذالك ظن الذين كفروا فويل للذين كفروا من النار"
    },
    {
      "surah_number": 38,
      "verse_number": 28,
      "content": "أم نجعل الذين امنوا وعملوا الصالحات كالمفسدين في الأرض أم نجعل المتقين كالفجار"
    },
    {
      "surah_number": 38,
      "verse_number": 29,
      "content": "كتاب أنزلناه اليك مبارك ليدبروا اياته وليتذكر أولوا الألباب"
    },
    {
      "surah_number": 38,
      "verse_number": 30,
      "content": "ووهبنا لداود سليمان نعم العبد انه أواب"
    },
    {
      "surah_number": 38,
      "verse_number": 31,
      "content": "اذ عرض عليه بالعشي الصافنات الجياد"
    },
    {
      "surah_number": 38,
      "verse_number": 32,
      "content": "فقال اني أحببت حب الخير عن ذكر ربي حتىا توارت بالحجاب"
    },
    {
      "surah_number": 38,
      "verse_number": 33,
      "content": "ردوها علي فطفق مسحا بالسوق والأعناق"
    },
    {
      "surah_number": 38,
      "verse_number": 34,
      "content": "ولقد فتنا سليمان وألقينا علىا كرسيه جسدا ثم أناب"
    },
    {
      "surah_number": 38,
      "verse_number": 35,
      "content": "قال رب اغفر لي وهب لي ملكا لا ينبغي لأحد من بعدي انك أنت الوهاب"
    },
    {
      "surah_number": 38,
      "verse_number": 36,
      "content": "فسخرنا له الريح تجري بأمره رخا حيث أصاب"
    },
    {
      "surah_number": 38,
      "verse_number": 37,
      "content": "والشياطين كل بنا وغواص"
    },
    {
      "surah_number": 38,
      "verse_number": 38,
      "content": "واخرين مقرنين في الأصفاد"
    },
    {
      "surah_number": 38,
      "verse_number": 39,
      "content": "هاذا عطاؤنا فامنن أو أمسك بغير حساب"
    },
    {
      "surah_number": 38,
      "verse_number": 40,
      "content": "وان له عندنا لزلفىا وحسن مٔاب"
    },
    {
      "surah_number": 38,
      "verse_number": 41,
      "content": "واذكر عبدنا أيوب اذ نادىا ربه أني مسني الشيطان بنصب وعذاب"
    },
    {
      "surah_number": 38,
      "verse_number": 42,
      "content": "اركض برجلك هاذا مغتسل بارد وشراب"
    },
    {
      "surah_number": 38,
      "verse_number": 43,
      "content": "ووهبنا له أهله ومثلهم معهم رحمه منا وذكرىا لأولي الألباب"
    },
    {
      "surah_number": 38,
      "verse_number": 44,
      "content": "وخذ بيدك ضغثا فاضرب به ولا تحنث انا وجدناه صابرا نعم العبد انه أواب"
    },
    {
      "surah_number": 38,
      "verse_number": 45,
      "content": "واذكر عبادنا ابراهيم واسحاق ويعقوب أولي الأيدي والأبصار"
    },
    {
      "surah_number": 38,
      "verse_number": 46,
      "content": "انا أخلصناهم بخالصه ذكرى الدار"
    },
    {
      "surah_number": 38,
      "verse_number": 47,
      "content": "وانهم عندنا لمن المصطفين الأخيار"
    },
    {
      "surah_number": 38,
      "verse_number": 48,
      "content": "واذكر اسماعيل واليسع وذا الكفل وكل من الأخيار"
    },
    {
      "surah_number": 38,
      "verse_number": 49,
      "content": "هاذا ذكر وان للمتقين لحسن مٔاب"
    },
    {
      "surah_number": 38,
      "verse_number": 50,
      "content": "جنات عدن مفتحه لهم الأبواب"
    },
    {
      "surah_number": 38,
      "verse_number": 51,
      "content": "متكٔين فيها يدعون فيها بفاكهه كثيره وشراب"
    },
    {
      "surah_number": 38,
      "verse_number": 52,
      "content": "وعندهم قاصرات الطرف أتراب"
    },
    {
      "surah_number": 38,
      "verse_number": 53,
      "content": "هاذا ما توعدون ليوم الحساب"
    },
    {
      "surah_number": 38,
      "verse_number": 54,
      "content": "ان هاذا لرزقنا ما له من نفاد"
    },
    {
      "surah_number": 38,
      "verse_number": 55,
      "content": "هاذا وان للطاغين لشر مٔاب"
    },
    {
      "surah_number": 38,
      "verse_number": 56,
      "content": "جهنم يصلونها فبئس المهاد"
    },
    {
      "surah_number": 38,
      "verse_number": 57,
      "content": "هاذا فليذوقوه حميم وغساق"
    },
    {
      "surah_number": 38,
      "verse_number": 58,
      "content": "واخر من شكله أزواج"
    },
    {
      "surah_number": 38,
      "verse_number": 59,
      "content": "هاذا فوج مقتحم معكم لا مرحبا بهم انهم صالوا النار"
    },
    {
      "surah_number": 38,
      "verse_number": 60,
      "content": "قالوا بل أنتم لا مرحبا بكم أنتم قدمتموه لنا فبئس القرار"
    },
    {
      "surah_number": 38,
      "verse_number": 61,
      "content": "قالوا ربنا من قدم لنا هاذا فزده عذابا ضعفا في النار"
    },
    {
      "surah_number": 38,
      "verse_number": 62,
      "content": "وقالوا ما لنا لا نرىا رجالا كنا نعدهم من الأشرار"
    },
    {
      "surah_number": 38,
      "verse_number": 63,
      "content": "أتخذناهم سخريا أم زاغت عنهم الأبصار"
    },
    {
      "surah_number": 38,
      "verse_number": 64,
      "content": "ان ذالك لحق تخاصم أهل النار"
    },
    {
      "surah_number": 38,
      "verse_number": 65,
      "content": "قل انما أنا منذر وما من الاه الا الله الواحد القهار"
    },
    {
      "surah_number": 38,
      "verse_number": 66,
      "content": "رب السماوات والأرض وما بينهما العزيز الغفار"
    },
    {
      "surah_number": 38,
      "verse_number": 67,
      "content": "قل هو نبؤا عظيم"
    },
    {
      "surah_number": 38,
      "verse_number": 68,
      "content": "أنتم عنه معرضون"
    },
    {
      "surah_number": 38,
      "verse_number": 69,
      "content": "ما كان لي من علم بالملا الأعلىا اذ يختصمون"
    },
    {
      "surah_number": 38,
      "verse_number": 70,
      "content": "ان يوحىا الي الا أنما أنا نذير مبين"
    },
    {
      "surah_number": 38,
      "verse_number": 71,
      "content": "اذ قال ربك للملائكه اني خالق بشرا من طين"
    },
    {
      "surah_number": 38,
      "verse_number": 72,
      "content": "فاذا سويته ونفخت فيه من روحي فقعوا له ساجدين"
    },
    {
      "surah_number": 38,
      "verse_number": 73,
      "content": "فسجد الملائكه كلهم أجمعون"
    },
    {
      "surah_number": 38,
      "verse_number": 74,
      "content": "الا ابليس استكبر وكان من الكافرين"
    },
    {
      "surah_number": 38,
      "verse_number": 75,
      "content": "قال ياابليس ما منعك أن تسجد لما خلقت بيدي أستكبرت أم كنت من العالين"
    },
    {
      "surah_number": 38,
      "verse_number": 76,
      "content": "قال أنا خير منه خلقتني من نار وخلقته من طين"
    },
    {
      "surah_number": 38,
      "verse_number": 77,
      "content": "قال فاخرج منها فانك رجيم"
    },
    {
      "surah_number": 38,
      "verse_number": 78,
      "content": "وان عليك لعنتي الىا يوم الدين"
    },
    {
      "surah_number": 38,
      "verse_number": 79,
      "content": "قال رب فأنظرني الىا يوم يبعثون"
    },
    {
      "surah_number": 38,
      "verse_number": 80,
      "content": "قال فانك من المنظرين"
    },
    {
      "surah_number": 38,
      "verse_number": 81,
      "content": "الىا يوم الوقت المعلوم"
    },
    {
      "surah_number": 38,
      "verse_number": 82,
      "content": "قال فبعزتك لأغوينهم أجمعين"
    },
    {
      "surah_number": 38,
      "verse_number": 83,
      "content": "الا عبادك منهم المخلصين"
    },
    {
      "surah_number": 38,
      "verse_number": 84,
      "content": "قال فالحق والحق أقول"
    },
    {
      "surah_number": 38,
      "verse_number": 85,
      "content": "لأملأن جهنم منك وممن تبعك منهم أجمعين"
    },
    {
      "surah_number": 38,
      "verse_number": 86,
      "content": "قل ما أسٔلكم عليه من أجر وما أنا من المتكلفين"
    },
    {
      "surah_number": 38,
      "verse_number": 87,
      "content": "ان هو الا ذكر للعالمين"
    },
    {
      "surah_number": 38,
      "verse_number": 88,
      "content": "ولتعلمن نبأه بعد حين"
    },
    {
      "surah_number": 39,
      "verse_number": 1,
      "content": "تنزيل الكتاب من الله العزيز الحكيم"
    },
    {
      "surah_number": 39,
      "verse_number": 2,
      "content": "انا أنزلنا اليك الكتاب بالحق فاعبد الله مخلصا له الدين"
    },
    {
      "surah_number": 39,
      "verse_number": 3,
      "content": "ألا لله الدين الخالص والذين اتخذوا من دونه أوليا ما نعبدهم الا ليقربونا الى الله زلفىا ان الله يحكم بينهم في ما هم فيه يختلفون ان الله لا يهدي من هو كاذب كفار"
    },
    {
      "surah_number": 39,
      "verse_number": 4,
      "content": "لو أراد الله أن يتخذ ولدا لاصطفىا مما يخلق ما يشا سبحانه هو الله الواحد القهار"
    },
    {
      "surah_number": 39,
      "verse_number": 5,
      "content": "خلق السماوات والأرض بالحق يكور اليل على النهار ويكور النهار على اليل وسخر الشمس والقمر كل يجري لأجل مسمى ألا هو العزيز الغفار"
    },
    {
      "surah_number": 39,
      "verse_number": 6,
      "content": "خلقكم من نفس واحده ثم جعل منها زوجها وأنزل لكم من الأنعام ثمانيه أزواج يخلقكم في بطون أمهاتكم خلقا من بعد خلق في ظلمات ثلاث ذالكم الله ربكم له الملك لا الاه الا هو فأنىا تصرفون"
    },
    {
      "surah_number": 39,
      "verse_number": 7,
      "content": "ان تكفروا فان الله غني عنكم ولا يرضىا لعباده الكفر وان تشكروا يرضه لكم ولا تزر وازره وزر أخرىا ثم الىا ربكم مرجعكم فينبئكم بما كنتم تعملون انه عليم بذات الصدور"
    },
    {
      "surah_number": 39,
      "verse_number": 8,
      "content": "واذا مس الانسان ضر دعا ربه منيبا اليه ثم اذا خوله نعمه منه نسي ما كان يدعوا اليه من قبل وجعل لله أندادا ليضل عن سبيله قل تمتع بكفرك قليلا انك من أصحاب النار"
    },
    {
      "surah_number": 39,
      "verse_number": 9,
      "content": "أمن هو قانت انا اليل ساجدا وقائما يحذر الأخره ويرجوا رحمه ربه قل هل يستوي الذين يعلمون والذين لا يعلمون انما يتذكر أولوا الألباب"
    },
    {
      "surah_number": 39,
      "verse_number": 10,
      "content": "قل ياعباد الذين امنوا اتقوا ربكم للذين أحسنوا في هاذه الدنيا حسنه وأرض الله واسعه انما يوفى الصابرون أجرهم بغير حساب"
    },
    {
      "surah_number": 39,
      "verse_number": 11,
      "content": "قل اني أمرت أن أعبد الله مخلصا له الدين"
    },
    {
      "surah_number": 39,
      "verse_number": 12,
      "content": "وأمرت لأن أكون أول المسلمين"
    },
    {
      "surah_number": 39,
      "verse_number": 13,
      "content": "قل اني أخاف ان عصيت ربي عذاب يوم عظيم"
    },
    {
      "surah_number": 39,
      "verse_number": 14,
      "content": "قل الله أعبد مخلصا له ديني"
    },
    {
      "surah_number": 39,
      "verse_number": 15,
      "content": "فاعبدوا ما شئتم من دونه قل ان الخاسرين الذين خسروا أنفسهم وأهليهم يوم القيامه ألا ذالك هو الخسران المبين"
    },
    {
      "surah_number": 39,
      "verse_number": 16,
      "content": "لهم من فوقهم ظلل من النار ومن تحتهم ظلل ذالك يخوف الله به عباده ياعباد فاتقون"
    },
    {
      "surah_number": 39,
      "verse_number": 17,
      "content": "والذين اجتنبوا الطاغوت أن يعبدوها وأنابوا الى الله لهم البشرىا فبشر عباد"
    },
    {
      "surah_number": 39,
      "verse_number": 18,
      "content": "الذين يستمعون القول فيتبعون أحسنه أولائك الذين هدىاهم الله وأولائك هم أولوا الألباب"
    },
    {
      "surah_number": 39,
      "verse_number": 19,
      "content": "أفمن حق عليه كلمه العذاب أفأنت تنقذ من في النار"
    },
    {
      "surah_number": 39,
      "verse_number": 20,
      "content": "لاكن الذين اتقوا ربهم لهم غرف من فوقها غرف مبنيه تجري من تحتها الأنهار وعد الله لا يخلف الله الميعاد"
    },
    {
      "surah_number": 39,
      "verse_number": 21,
      "content": "ألم تر أن الله أنزل من السما ما فسلكه ينابيع في الأرض ثم يخرج به زرعا مختلفا ألوانه ثم يهيج فترىاه مصفرا ثم يجعله حطاما ان في ذالك لذكرىا لأولي الألباب"
    },
    {
      "surah_number": 39,
      "verse_number": 22,
      "content": "أفمن شرح الله صدره للاسلام فهو علىا نور من ربه فويل للقاسيه قلوبهم من ذكر الله أولائك في ضلال مبين"
    },
    {
      "surah_number": 39,
      "verse_number": 23,
      "content": "الله نزل أحسن الحديث كتابا متشابها مثاني تقشعر منه جلود الذين يخشون ربهم ثم تلين جلودهم وقلوبهم الىا ذكر الله ذالك هدى الله يهدي به من يشا ومن يضلل الله فما له من هاد"
    },
    {
      "surah_number": 39,
      "verse_number": 24,
      "content": "أفمن يتقي بوجهه سو العذاب يوم القيامه وقيل للظالمين ذوقوا ما كنتم تكسبون"
    },
    {
      "surah_number": 39,
      "verse_number": 25,
      "content": "كذب الذين من قبلهم فأتىاهم العذاب من حيث لا يشعرون"
    },
    {
      "surah_number": 39,
      "verse_number": 26,
      "content": "فأذاقهم الله الخزي في الحيواه الدنيا ولعذاب الأخره أكبر لو كانوا يعلمون"
    },
    {
      "surah_number": 39,
      "verse_number": 27,
      "content": "ولقد ضربنا للناس في هاذا القران من كل مثل لعلهم يتذكرون"
    },
    {
      "surah_number": 39,
      "verse_number": 28,
      "content": "قرانا عربيا غير ذي عوج لعلهم يتقون"
    },
    {
      "surah_number": 39,
      "verse_number": 29,
      "content": "ضرب الله مثلا رجلا فيه شركا متشاكسون ورجلا سلما لرجل هل يستويان مثلا الحمد لله بل أكثرهم لا يعلمون"
    },
    {
      "surah_number": 39,
      "verse_number": 30,
      "content": "انك ميت وانهم ميتون"
    },
    {
      "surah_number": 39,
      "verse_number": 31,
      "content": "ثم انكم يوم القيامه عند ربكم تختصمون"
    },
    {
      "surah_number": 39,
      "verse_number": 32,
      "content": "فمن أظلم ممن كذب على الله وكذب بالصدق اذ جاه أليس في جهنم مثوى للكافرين"
    },
    {
      "surah_number": 39,
      "verse_number": 33,
      "content": "والذي جا بالصدق وصدق به أولائك هم المتقون"
    },
    {
      "surah_number": 39,
      "verse_number": 34,
      "content": "لهم ما يشاون عند ربهم ذالك جزا المحسنين"
    },
    {
      "surah_number": 39,
      "verse_number": 35,
      "content": "ليكفر الله عنهم أسوأ الذي عملوا ويجزيهم أجرهم بأحسن الذي كانوا يعملون"
    },
    {
      "surah_number": 39,
      "verse_number": 36,
      "content": "أليس الله بكاف عبده ويخوفونك بالذين من دونه ومن يضلل الله فما له من هاد"
    },
    {
      "surah_number": 39,
      "verse_number": 37,
      "content": "ومن يهد الله فما له من مضل أليس الله بعزيز ذي انتقام"
    },
    {
      "surah_number": 39,
      "verse_number": 38,
      "content": "ولئن سألتهم من خلق السماوات والأرض ليقولن الله قل أفريتم ما تدعون من دون الله ان أرادني الله بضر هل هن كاشفات ضره أو أرادني برحمه هل هن ممسكات رحمته قل حسبي الله عليه يتوكل المتوكلون"
    },
    {
      "surah_number": 39,
      "verse_number": 39,
      "content": "قل ياقوم اعملوا علىا مكانتكم اني عامل فسوف تعلمون"
    },
    {
      "surah_number": 39,
      "verse_number": 40,
      "content": "من يأتيه عذاب يخزيه ويحل عليه عذاب مقيم"
    },
    {
      "surah_number": 39,
      "verse_number": 41,
      "content": "انا أنزلنا عليك الكتاب للناس بالحق فمن اهتدىا فلنفسه ومن ضل فانما يضل عليها وما أنت عليهم بوكيل"
    },
    {
      "surah_number": 39,
      "verse_number": 42,
      "content": "الله يتوفى الأنفس حين موتها والتي لم تمت في منامها فيمسك التي قضىا عليها الموت ويرسل الأخرىا الىا أجل مسمى ان في ذالك لأيات لقوم يتفكرون"
    },
    {
      "surah_number": 39,
      "verse_number": 43,
      "content": "أم اتخذوا من دون الله شفعا قل أولو كانوا لا يملكون شئا ولا يعقلون"
    },
    {
      "surah_number": 39,
      "verse_number": 44,
      "content": "قل لله الشفاعه جميعا له ملك السماوات والأرض ثم اليه ترجعون"
    },
    {
      "surah_number": 39,
      "verse_number": 45,
      "content": "واذا ذكر الله وحده اشمأزت قلوب الذين لا يؤمنون بالأخره واذا ذكر الذين من دونه اذا هم يستبشرون"
    },
    {
      "surah_number": 39,
      "verse_number": 46,
      "content": "قل اللهم فاطر السماوات والأرض عالم الغيب والشهاده أنت تحكم بين عبادك في ما كانوا فيه يختلفون"
    },
    {
      "surah_number": 39,
      "verse_number": 47,
      "content": "ولو أن للذين ظلموا ما في الأرض جميعا ومثله معه لافتدوا به من سو العذاب يوم القيامه وبدا لهم من الله ما لم يكونوا يحتسبون"
    },
    {
      "surah_number": 39,
      "verse_number": 48,
      "content": "وبدا لهم سئات ما كسبوا وحاق بهم ما كانوا به يستهزون"
    },
    {
      "surah_number": 39,
      "verse_number": 49,
      "content": "فاذا مس الانسان ضر دعانا ثم اذا خولناه نعمه منا قال انما أوتيته علىا علم بل هي فتنه ولاكن أكثرهم لا يعلمون"
    },
    {
      "surah_number": 39,
      "verse_number": 50,
      "content": "قد قالها الذين من قبلهم فما أغنىا عنهم ما كانوا يكسبون"
    },
    {
      "surah_number": 39,
      "verse_number": 51,
      "content": "فأصابهم سئات ما كسبوا والذين ظلموا من هاؤلا سيصيبهم سئات ما كسبوا وما هم بمعجزين"
    },
    {
      "surah_number": 39,
      "verse_number": 52,
      "content": "أولم يعلموا أن الله يبسط الرزق لمن يشا ويقدر ان في ذالك لأيات لقوم يؤمنون"
    },
    {
      "surah_number": 39,
      "verse_number": 53,
      "content": "قل ياعبادي الذين أسرفوا علىا أنفسهم لا تقنطوا من رحمه الله ان الله يغفر الذنوب جميعا انه هو الغفور الرحيم"
    },
    {
      "surah_number": 39,
      "verse_number": 54,
      "content": "وأنيبوا الىا ربكم وأسلموا له من قبل أن يأتيكم العذاب ثم لا تنصرون"
    },
    {
      "surah_number": 39,
      "verse_number": 55,
      "content": "واتبعوا أحسن ما أنزل اليكم من ربكم من قبل أن يأتيكم العذاب بغته وأنتم لا تشعرون"
    },
    {
      "surah_number": 39,
      "verse_number": 56,
      "content": "أن تقول نفس ياحسرتىا علىا ما فرطت في جنب الله وان كنت لمن الساخرين"
    },
    {
      "surah_number": 39,
      "verse_number": 57,
      "content": "أو تقول لو أن الله هدىاني لكنت من المتقين"
    },
    {
      "surah_number": 39,
      "verse_number": 58,
      "content": "أو تقول حين ترى العذاب لو أن لي كره فأكون من المحسنين"
    },
    {
      "surah_number": 39,
      "verse_number": 59,
      "content": "بلىا قد جاتك اياتي فكذبت بها واستكبرت وكنت من الكافرين"
    },
    {
      "surah_number": 39,
      "verse_number": 60,
      "content": "ويوم القيامه ترى الذين كذبوا على الله وجوههم مسوده أليس في جهنم مثوى للمتكبرين"
    },
    {
      "surah_number": 39,
      "verse_number": 61,
      "content": "وينجي الله الذين اتقوا بمفازتهم لا يمسهم السو ولا هم يحزنون"
    },
    {
      "surah_number": 39,
      "verse_number": 62,
      "content": "الله خالق كل شي وهو علىا كل شي وكيل"
    },
    {
      "surah_number": 39,
      "verse_number": 63,
      "content": "له مقاليد السماوات والأرض والذين كفروا بٔايات الله أولائك هم الخاسرون"
    },
    {
      "surah_number": 39,
      "verse_number": 64,
      "content": "قل أفغير الله تأمروني أعبد أيها الجاهلون"
    },
    {
      "surah_number": 39,
      "verse_number": 65,
      "content": "ولقد أوحي اليك والى الذين من قبلك لئن أشركت ليحبطن عملك ولتكونن من الخاسرين"
    },
    {
      "surah_number": 39,
      "verse_number": 66,
      "content": "بل الله فاعبد وكن من الشاكرين"
    },
    {
      "surah_number": 39,
      "verse_number": 67,
      "content": "وما قدروا الله حق قدره والأرض جميعا قبضته يوم القيامه والسماوات مطويات بيمينه سبحانه وتعالىا عما يشركون"
    },
    {
      "surah_number": 39,
      "verse_number": 68,
      "content": "ونفخ في الصور فصعق من في السماوات ومن في الأرض الا من شا الله ثم نفخ فيه أخرىا فاذا هم قيام ينظرون"
    },
    {
      "surah_number": 39,
      "verse_number": 69,
      "content": "وأشرقت الأرض بنور ربها ووضع الكتاب وجاي بالنبين والشهدا وقضي بينهم بالحق وهم لا يظلمون"
    },
    {
      "surah_number": 39,
      "verse_number": 70,
      "content": "ووفيت كل نفس ما عملت وهو أعلم بما يفعلون"
    },
    {
      "surah_number": 39,
      "verse_number": 71,
      "content": "وسيق الذين كفروا الىا جهنم زمرا حتىا اذا جاوها فتحت أبوابها وقال لهم خزنتها ألم يأتكم رسل منكم يتلون عليكم ايات ربكم وينذرونكم لقا يومكم هاذا قالوا بلىا ولاكن حقت كلمه العذاب على الكافرين"
    },
    {
      "surah_number": 39,
      "verse_number": 72,
      "content": "قيل ادخلوا أبواب جهنم خالدين فيها فبئس مثوى المتكبرين"
    },
    {
      "surah_number": 39,
      "verse_number": 73,
      "content": "وسيق الذين اتقوا ربهم الى الجنه زمرا حتىا اذا جاوها وفتحت أبوابها وقال لهم خزنتها سلام عليكم طبتم فادخلوها خالدين"
    },
    {
      "surah_number": 39,
      "verse_number": 74,
      "content": "وقالوا الحمد لله الذي صدقنا وعده وأورثنا الأرض نتبوأ من الجنه حيث نشا فنعم أجر العاملين"
    },
    {
      "surah_number": 39,
      "verse_number": 75,
      "content": "وترى الملائكه حافين من حول العرش يسبحون بحمد ربهم وقضي بينهم بالحق وقيل الحمد لله رب العالمين"
    },
    {
      "surah_number": 40,
      "verse_number": 1,
      "content": "حم"
    },
    {
      "surah_number": 40,
      "verse_number": 2,
      "content": "تنزيل الكتاب من الله العزيز العليم"
    },
    {
      "surah_number": 40,
      "verse_number": 3,
      "content": "غافر الذنب وقابل التوب شديد العقاب ذي الطول لا الاه الا هو اليه المصير"
    },
    {
      "surah_number": 40,
      "verse_number": 4,
      "content": "ما يجادل في ايات الله الا الذين كفروا فلا يغررك تقلبهم في البلاد"
    },
    {
      "surah_number": 40,
      "verse_number": 5,
      "content": "كذبت قبلهم قوم نوح والأحزاب من بعدهم وهمت كل أمه برسولهم ليأخذوه وجادلوا بالباطل ليدحضوا به الحق فأخذتهم فكيف كان عقاب"
    },
    {
      "surah_number": 40,
      "verse_number": 6,
      "content": "وكذالك حقت كلمت ربك على الذين كفروا أنهم أصحاب النار"
    },
    {
      "surah_number": 40,
      "verse_number": 7,
      "content": "الذين يحملون العرش ومن حوله يسبحون بحمد ربهم ويؤمنون به ويستغفرون للذين امنوا ربنا وسعت كل شي رحمه وعلما فاغفر للذين تابوا واتبعوا سبيلك وقهم عذاب الجحيم"
    },
    {
      "surah_number": 40,
      "verse_number": 8,
      "content": "ربنا وأدخلهم جنات عدن التي وعدتهم ومن صلح من ابائهم وأزواجهم وذرياتهم انك أنت العزيز الحكيم"
    },
    {
      "surah_number": 40,
      "verse_number": 9,
      "content": "وقهم السئات ومن تق السئات يومئذ فقد رحمته وذالك هو الفوز العظيم"
    },
    {
      "surah_number": 40,
      "verse_number": 10,
      "content": "ان الذين كفروا ينادون لمقت الله أكبر من مقتكم أنفسكم اذ تدعون الى الايمان فتكفرون"
    },
    {
      "surah_number": 40,
      "verse_number": 11,
      "content": "قالوا ربنا أمتنا اثنتين وأحييتنا اثنتين فاعترفنا بذنوبنا فهل الىا خروج من سبيل"
    },
    {
      "surah_number": 40,
      "verse_number": 12,
      "content": "ذالكم بأنه اذا دعي الله وحده كفرتم وان يشرك به تؤمنوا فالحكم لله العلي الكبير"
    },
    {
      "surah_number": 40,
      "verse_number": 13,
      "content": "هو الذي يريكم اياته وينزل لكم من السما رزقا وما يتذكر الا من ينيب"
    },
    {
      "surah_number": 40,
      "verse_number": 14,
      "content": "فادعوا الله مخلصين له الدين ولو كره الكافرون"
    },
    {
      "surah_number": 40,
      "verse_number": 15,
      "content": "رفيع الدرجات ذو العرش يلقي الروح من أمره علىا من يشا من عباده لينذر يوم التلاق"
    },
    {
      "surah_number": 40,
      "verse_number": 16,
      "content": "يوم هم بارزون لا يخفىا على الله منهم شي لمن الملك اليوم لله الواحد القهار"
    },
    {
      "surah_number": 40,
      "verse_number": 17,
      "content": "اليوم تجزىا كل نفس بما كسبت لا ظلم اليوم ان الله سريع الحساب"
    },
    {
      "surah_number": 40,
      "verse_number": 18,
      "content": "وأنذرهم يوم الأزفه اذ القلوب لدى الحناجر كاظمين ما للظالمين من حميم ولا شفيع يطاع"
    },
    {
      "surah_number": 40,
      "verse_number": 19,
      "content": "يعلم خائنه الأعين وما تخفي الصدور"
    },
    {
      "surah_number": 40,
      "verse_number": 20,
      "content": "والله يقضي بالحق والذين يدعون من دونه لا يقضون بشي ان الله هو السميع البصير"
    },
    {
      "surah_number": 40,
      "verse_number": 21,
      "content": "أولم يسيروا في الأرض فينظروا كيف كان عاقبه الذين كانوا من قبلهم كانوا هم أشد منهم قوه واثارا في الأرض فأخذهم الله بذنوبهم وما كان لهم من الله من واق"
    },
    {
      "surah_number": 40,
      "verse_number": 22,
      "content": "ذالك بأنهم كانت تأتيهم رسلهم بالبينات فكفروا فأخذهم الله انه قوي شديد العقاب"
    },
    {
      "surah_number": 40,
      "verse_number": 23,
      "content": "ولقد أرسلنا موسىا بٔاياتنا وسلطان مبين"
    },
    {
      "surah_number": 40,
      "verse_number": 24,
      "content": "الىا فرعون وهامان وقارون فقالوا ساحر كذاب"
    },
    {
      "surah_number": 40,
      "verse_number": 25,
      "content": "فلما جاهم بالحق من عندنا قالوا اقتلوا أبنا الذين امنوا معه واستحيوا نساهم وما كيد الكافرين الا في ضلال"
    },
    {
      "surah_number": 40,
      "verse_number": 26,
      "content": "وقال فرعون ذروني أقتل موسىا وليدع ربه اني أخاف أن يبدل دينكم أو أن يظهر في الأرض الفساد"
    },
    {
      "surah_number": 40,
      "verse_number": 27,
      "content": "وقال موسىا اني عذت بربي وربكم من كل متكبر لا يؤمن بيوم الحساب"
    },
    {
      "surah_number": 40,
      "verse_number": 28,
      "content": "وقال رجل مؤمن من ال فرعون يكتم ايمانه أتقتلون رجلا أن يقول ربي الله وقد جاكم بالبينات من ربكم وان يك كاذبا فعليه كذبه وان يك صادقا يصبكم بعض الذي يعدكم ان الله لا يهدي من هو مسرف كذاب"
    },
    {
      "surah_number": 40,
      "verse_number": 29,
      "content": "ياقوم لكم الملك اليوم ظاهرين في الأرض فمن ينصرنا من بأس الله ان جانا قال فرعون ما أريكم الا ما أرىا وما أهديكم الا سبيل الرشاد"
    },
    {
      "surah_number": 40,
      "verse_number": 30,
      "content": "وقال الذي امن ياقوم اني أخاف عليكم مثل يوم الأحزاب"
    },
    {
      "surah_number": 40,
      "verse_number": 31,
      "content": "مثل دأب قوم نوح وعاد وثمود والذين من بعدهم وما الله يريد ظلما للعباد"
    },
    {
      "surah_number": 40,
      "verse_number": 32,
      "content": "وياقوم اني أخاف عليكم يوم التناد"
    },
    {
      "surah_number": 40,
      "verse_number": 33,
      "content": "يوم تولون مدبرين ما لكم من الله من عاصم ومن يضلل الله فما له من هاد"
    },
    {
      "surah_number": 40,
      "verse_number": 34,
      "content": "ولقد جاكم يوسف من قبل بالبينات فما زلتم في شك مما جاكم به حتىا اذا هلك قلتم لن يبعث الله من بعده رسولا كذالك يضل الله من هو مسرف مرتاب"
    },
    {
      "surah_number": 40,
      "verse_number": 35,
      "content": "الذين يجادلون في ايات الله بغير سلطان أتىاهم كبر مقتا عند الله وعند الذين امنوا كذالك يطبع الله علىا كل قلب متكبر جبار"
    },
    {
      "surah_number": 40,
      "verse_number": 36,
      "content": "وقال فرعون ياهامان ابن لي صرحا لعلي أبلغ الأسباب"
    },
    {
      "surah_number": 40,
      "verse_number": 37,
      "content": "أسباب السماوات فأطلع الىا الاه موسىا واني لأظنه كاذبا وكذالك زين لفرعون سو عمله وصد عن السبيل وما كيد فرعون الا في تباب"
    },
    {
      "surah_number": 40,
      "verse_number": 38,
      "content": "وقال الذي امن ياقوم اتبعون أهدكم سبيل الرشاد"
    },
    {
      "surah_number": 40,
      "verse_number": 39,
      "content": "ياقوم انما هاذه الحيواه الدنيا متاع وان الأخره هي دار القرار"
    },
    {
      "surah_number": 40,
      "verse_number": 40,
      "content": "من عمل سيئه فلا يجزىا الا مثلها ومن عمل صالحا من ذكر أو أنثىا وهو مؤمن فأولائك يدخلون الجنه يرزقون فيها بغير حساب"
    },
    {
      "surah_number": 40,
      "verse_number": 41,
      "content": "وياقوم ما لي أدعوكم الى النجواه وتدعونني الى النار"
    },
    {
      "surah_number": 40,
      "verse_number": 42,
      "content": "تدعونني لأكفر بالله وأشرك به ما ليس لي به علم وأنا أدعوكم الى العزيز الغفار"
    },
    {
      "surah_number": 40,
      "verse_number": 43,
      "content": "لا جرم أنما تدعونني اليه ليس له دعوه في الدنيا ولا في الأخره وأن مردنا الى الله وأن المسرفين هم أصحاب النار"
    },
    {
      "surah_number": 40,
      "verse_number": 44,
      "content": "فستذكرون ما أقول لكم وأفوض أمري الى الله ان الله بصير بالعباد"
    },
    {
      "surah_number": 40,
      "verse_number": 45,
      "content": "فوقىاه الله سئات ما مكروا وحاق بٔال فرعون سو العذاب"
    },
    {
      "surah_number": 40,
      "verse_number": 46,
      "content": "النار يعرضون عليها غدوا وعشيا ويوم تقوم الساعه أدخلوا ال فرعون أشد العذاب"
    },
    {
      "surah_number": 40,
      "verse_number": 47,
      "content": "واذ يتحاجون في النار فيقول الضعفاؤا للذين استكبروا انا كنا لكم تبعا فهل أنتم مغنون عنا نصيبا من النار"
    },
    {
      "surah_number": 40,
      "verse_number": 48,
      "content": "قال الذين استكبروا انا كل فيها ان الله قد حكم بين العباد"
    },
    {
      "surah_number": 40,
      "verse_number": 49,
      "content": "وقال الذين في النار لخزنه جهنم ادعوا ربكم يخفف عنا يوما من العذاب"
    },
    {
      "surah_number": 40,
      "verse_number": 50,
      "content": "قالوا أولم تك تأتيكم رسلكم بالبينات قالوا بلىا قالوا فادعوا وما دعاؤا الكافرين الا في ضلال"
    },
    {
      "surah_number": 40,
      "verse_number": 51,
      "content": "انا لننصر رسلنا والذين امنوا في الحيواه الدنيا ويوم يقوم الأشهاد"
    },
    {
      "surah_number": 40,
      "verse_number": 52,
      "content": "يوم لا ينفع الظالمين معذرتهم ولهم اللعنه ولهم سو الدار"
    },
    {
      "surah_number": 40,
      "verse_number": 53,
      "content": "ولقد اتينا موسى الهدىا وأورثنا بني اسرايل الكتاب"
    },
    {
      "surah_number": 40,
      "verse_number": 54,
      "content": "هدى وذكرىا لأولي الألباب"
    },
    {
      "surah_number": 40,
      "verse_number": 55,
      "content": "فاصبر ان وعد الله حق واستغفر لذنبك وسبح بحمد ربك بالعشي والابكار"
    },
    {
      "surah_number": 40,
      "verse_number": 56,
      "content": "ان الذين يجادلون في ايات الله بغير سلطان أتىاهم ان في صدورهم الا كبر ما هم ببالغيه فاستعذ بالله انه هو السميع البصير"
    },
    {
      "surah_number": 40,
      "verse_number": 57,
      "content": "لخلق السماوات والأرض أكبر من خلق الناس ولاكن أكثر الناس لا يعلمون"
    },
    {
      "surah_number": 40,
      "verse_number": 58,
      "content": "وما يستوي الأعمىا والبصير والذين امنوا وعملوا الصالحات ولا المسي قليلا ما تتذكرون"
    },
    {
      "surah_number": 40,
      "verse_number": 59,
      "content": "ان الساعه لأتيه لا ريب فيها ولاكن أكثر الناس لا يؤمنون"
    },
    {
      "surah_number": 40,
      "verse_number": 60,
      "content": "وقال ربكم ادعوني أستجب لكم ان الذين يستكبرون عن عبادتي سيدخلون جهنم داخرين"
    },
    {
      "surah_number": 40,
      "verse_number": 61,
      "content": "الله الذي جعل لكم اليل لتسكنوا فيه والنهار مبصرا ان الله لذو فضل على الناس ولاكن أكثر الناس لا يشكرون"
    },
    {
      "surah_number": 40,
      "verse_number": 62,
      "content": "ذالكم الله ربكم خالق كل شي لا الاه الا هو فأنىا تؤفكون"
    },
    {
      "surah_number": 40,
      "verse_number": 63,
      "content": "كذالك يؤفك الذين كانوا بٔايات الله يجحدون"
    },
    {
      "surah_number": 40,
      "verse_number": 64,
      "content": "الله الذي جعل لكم الأرض قرارا والسما بنا وصوركم فأحسن صوركم ورزقكم من الطيبات ذالكم الله ربكم فتبارك الله رب العالمين"
    },
    {
      "surah_number": 40,
      "verse_number": 65,
      "content": "هو الحي لا الاه الا هو فادعوه مخلصين له الدين الحمد لله رب العالمين"
    },
    {
      "surah_number": 40,
      "verse_number": 66,
      "content": "قل اني نهيت أن أعبد الذين تدعون من دون الله لما جاني البينات من ربي وأمرت أن أسلم لرب العالمين"
    },
    {
      "surah_number": 40,
      "verse_number": 67,
      "content": "هو الذي خلقكم من تراب ثم من نطفه ثم من علقه ثم يخرجكم طفلا ثم لتبلغوا أشدكم ثم لتكونوا شيوخا ومنكم من يتوفىا من قبل ولتبلغوا أجلا مسمى ولعلكم تعقلون"
    },
    {
      "surah_number": 40,
      "verse_number": 68,
      "content": "هو الذي يحي ويميت فاذا قضىا أمرا فانما يقول له كن فيكون"
    },
    {
      "surah_number": 40,
      "verse_number": 69,
      "content": "ألم تر الى الذين يجادلون في ايات الله أنىا يصرفون"
    },
    {
      "surah_number": 40,
      "verse_number": 70,
      "content": "الذين كذبوا بالكتاب وبما أرسلنا به رسلنا فسوف يعلمون"
    },
    {
      "surah_number": 40,
      "verse_number": 71,
      "content": "اذ الأغلال في أعناقهم والسلاسل يسحبون"
    },
    {
      "surah_number": 40,
      "verse_number": 72,
      "content": "في الحميم ثم في النار يسجرون"
    },
    {
      "surah_number": 40,
      "verse_number": 73,
      "content": "ثم قيل لهم أين ما كنتم تشركون"
    },
    {
      "surah_number": 40,
      "verse_number": 74,
      "content": "من دون الله قالوا ضلوا عنا بل لم نكن ندعوا من قبل شئا كذالك يضل الله الكافرين"
    },
    {
      "surah_number": 40,
      "verse_number": 75,
      "content": "ذالكم بما كنتم تفرحون في الأرض بغير الحق وبما كنتم تمرحون"
    },
    {
      "surah_number": 40,
      "verse_number": 76,
      "content": "ادخلوا أبواب جهنم خالدين فيها فبئس مثوى المتكبرين"
    },
    {
      "surah_number": 40,
      "verse_number": 77,
      "content": "فاصبر ان وعد الله حق فاما نرينك بعض الذي نعدهم أو نتوفينك فالينا يرجعون"
    },
    {
      "surah_number": 40,
      "verse_number": 78,
      "content": "ولقد أرسلنا رسلا من قبلك منهم من قصصنا عليك ومنهم من لم نقصص عليك وما كان لرسول أن يأتي بٔايه الا باذن الله فاذا جا أمر الله قضي بالحق وخسر هنالك المبطلون"
    },
    {
      "surah_number": 40,
      "verse_number": 79,
      "content": "الله الذي جعل لكم الأنعام لتركبوا منها ومنها تأكلون"
    },
    {
      "surah_number": 40,
      "verse_number": 80,
      "content": "ولكم فيها منافع ولتبلغوا عليها حاجه في صدوركم وعليها وعلى الفلك تحملون"
    },
    {
      "surah_number": 40,
      "verse_number": 81,
      "content": "ويريكم اياته فأي ايات الله تنكرون"
    },
    {
      "surah_number": 40,
      "verse_number": 82,
      "content": "أفلم يسيروا في الأرض فينظروا كيف كان عاقبه الذين من قبلهم كانوا أكثر منهم وأشد قوه واثارا في الأرض فما أغنىا عنهم ما كانوا يكسبون"
    },
    {
      "surah_number": 40,
      "verse_number": 83,
      "content": "فلما جاتهم رسلهم بالبينات فرحوا بما عندهم من العلم وحاق بهم ما كانوا به يستهزون"
    },
    {
      "surah_number": 40,
      "verse_number": 84,
      "content": "فلما رأوا بأسنا قالوا امنا بالله وحده وكفرنا بما كنا به مشركين"
    },
    {
      "surah_number": 40,
      "verse_number": 85,
      "content": "فلم يك ينفعهم ايمانهم لما رأوا بأسنا سنت الله التي قد خلت في عباده وخسر هنالك الكافرون"
    },
    {
      "surah_number": 41,
      "verse_number": 1,
      "content": "حم"
    },
    {
      "surah_number": 41,
      "verse_number": 2,
      "content": "تنزيل من الرحمان الرحيم"
    },
    {
      "surah_number": 41,
      "verse_number": 3,
      "content": "كتاب فصلت اياته قرانا عربيا لقوم يعلمون"
    },
    {
      "surah_number": 41,
      "verse_number": 4,
      "content": "بشيرا ونذيرا فأعرض أكثرهم فهم لا يسمعون"
    },
    {
      "surah_number": 41,
      "verse_number": 5,
      "content": "وقالوا قلوبنا في أكنه مما تدعونا اليه وفي اذاننا وقر ومن بيننا وبينك حجاب فاعمل اننا عاملون"
    },
    {
      "surah_number": 41,
      "verse_number": 6,
      "content": "قل انما أنا بشر مثلكم يوحىا الي أنما الاهكم الاه واحد فاستقيموا اليه واستغفروه وويل للمشركين"
    },
    {
      "surah_number": 41,
      "verse_number": 7,
      "content": "الذين لا يؤتون الزكواه وهم بالأخره هم كافرون"
    },
    {
      "surah_number": 41,
      "verse_number": 8,
      "content": "ان الذين امنوا وعملوا الصالحات لهم أجر غير ممنون"
    },
    {
      "surah_number": 41,
      "verse_number": 9,
      "content": "قل أئنكم لتكفرون بالذي خلق الأرض في يومين وتجعلون له أندادا ذالك رب العالمين"
    },
    {
      "surah_number": 41,
      "verse_number": 10,
      "content": "وجعل فيها رواسي من فوقها وبارك فيها وقدر فيها أقواتها في أربعه أيام سوا للسائلين"
    },
    {
      "surah_number": 41,
      "verse_number": 11,
      "content": "ثم استوىا الى السما وهي دخان فقال لها وللأرض ائتيا طوعا أو كرها قالتا أتينا طائعين"
    },
    {
      "surah_number": 41,
      "verse_number": 12,
      "content": "فقضىاهن سبع سماوات في يومين وأوحىا في كل سما أمرها وزينا السما الدنيا بمصابيح وحفظا ذالك تقدير العزيز العليم"
    },
    {
      "surah_number": 41,
      "verse_number": 13,
      "content": "فان أعرضوا فقل أنذرتكم صاعقه مثل صاعقه عاد وثمود"
    },
    {
      "surah_number": 41,
      "verse_number": 14,
      "content": "اذ جاتهم الرسل من بين أيديهم ومن خلفهم ألا تعبدوا الا الله قالوا لو شا ربنا لأنزل ملائكه فانا بما أرسلتم به كافرون"
    },
    {
      "surah_number": 41,
      "verse_number": 15,
      "content": "فأما عاد فاستكبروا في الأرض بغير الحق وقالوا من أشد منا قوه أولم يروا أن الله الذي خلقهم هو أشد منهم قوه وكانوا بٔاياتنا يجحدون"
    },
    {
      "surah_number": 41,
      "verse_number": 16,
      "content": "فأرسلنا عليهم ريحا صرصرا في أيام نحسات لنذيقهم عذاب الخزي في الحيواه الدنيا ولعذاب الأخره أخزىا وهم لا ينصرون"
    },
    {
      "surah_number": 41,
      "verse_number": 17,
      "content": "وأما ثمود فهديناهم فاستحبوا العمىا على الهدىا فأخذتهم صاعقه العذاب الهون بما كانوا يكسبون"
    },
    {
      "surah_number": 41,
      "verse_number": 18,
      "content": "ونجينا الذين امنوا وكانوا يتقون"
    },
    {
      "surah_number": 41,
      "verse_number": 19,
      "content": "ويوم يحشر أعدا الله الى النار فهم يوزعون"
    },
    {
      "surah_number": 41,
      "verse_number": 20,
      "content": "حتىا اذا ما جاوها شهد عليهم سمعهم وأبصارهم وجلودهم بما كانوا يعملون"
    },
    {
      "surah_number": 41,
      "verse_number": 21,
      "content": "وقالوا لجلودهم لم شهدتم علينا قالوا أنطقنا الله الذي أنطق كل شي وهو خلقكم أول مره واليه ترجعون"
    },
    {
      "surah_number": 41,
      "verse_number": 22,
      "content": "وما كنتم تستترون أن يشهد عليكم سمعكم ولا أبصاركم ولا جلودكم ولاكن ظننتم أن الله لا يعلم كثيرا مما تعملون"
    },
    {
      "surah_number": 41,
      "verse_number": 23,
      "content": "وذالكم ظنكم الذي ظننتم بربكم أردىاكم فأصبحتم من الخاسرين"
    },
    {
      "surah_number": 41,
      "verse_number": 24,
      "content": "فان يصبروا فالنار مثوى لهم وان يستعتبوا فما هم من المعتبين"
    },
    {
      "surah_number": 41,
      "verse_number": 25,
      "content": "وقيضنا لهم قرنا فزينوا لهم ما بين أيديهم وما خلفهم وحق عليهم القول في أمم قد خلت من قبلهم من الجن والانس انهم كانوا خاسرين"
    },
    {
      "surah_number": 41,
      "verse_number": 26,
      "content": "وقال الذين كفروا لا تسمعوا لهاذا القران والغوا فيه لعلكم تغلبون"
    },
    {
      "surah_number": 41,
      "verse_number": 27,
      "content": "فلنذيقن الذين كفروا عذابا شديدا ولنجزينهم أسوأ الذي كانوا يعملون"
    },
    {
      "surah_number": 41,
      "verse_number": 28,
      "content": "ذالك جزا أعدا الله النار لهم فيها دار الخلد جزا بما كانوا بٔاياتنا يجحدون"
    },
    {
      "surah_number": 41,
      "verse_number": 29,
      "content": "وقال الذين كفروا ربنا أرنا الذين أضلانا من الجن والانس نجعلهما تحت أقدامنا ليكونا من الأسفلين"
    },
    {
      "surah_number": 41,
      "verse_number": 30,
      "content": "ان الذين قالوا ربنا الله ثم استقاموا تتنزل عليهم الملائكه ألا تخافوا ولا تحزنوا وأبشروا بالجنه التي كنتم توعدون"
    },
    {
      "surah_number": 41,
      "verse_number": 31,
      "content": "نحن أولياؤكم في الحيواه الدنيا وفي الأخره ولكم فيها ما تشتهي أنفسكم ولكم فيها ما تدعون"
    },
    {
      "surah_number": 41,
      "verse_number": 32,
      "content": "نزلا من غفور رحيم"
    },
    {
      "surah_number": 41,
      "verse_number": 33,
      "content": "ومن أحسن قولا ممن دعا الى الله وعمل صالحا وقال انني من المسلمين"
    },
    {
      "surah_number": 41,
      "verse_number": 34,
      "content": "ولا تستوي الحسنه ولا السيئه ادفع بالتي هي أحسن فاذا الذي بينك وبينه عداوه كأنه ولي حميم"
    },
    {
      "surah_number": 41,
      "verse_number": 35,
      "content": "وما يلقىاها الا الذين صبروا وما يلقىاها الا ذو حظ عظيم"
    },
    {
      "surah_number": 41,
      "verse_number": 36,
      "content": "واما ينزغنك من الشيطان نزغ فاستعذ بالله انه هو السميع العليم"
    },
    {
      "surah_number": 41,
      "verse_number": 37,
      "content": "ومن اياته اليل والنهار والشمس والقمر لا تسجدوا للشمس ولا للقمر واسجدوا لله الذي خلقهن ان كنتم اياه تعبدون"
    },
    {
      "surah_number": 41,
      "verse_number": 38,
      "content": "فان استكبروا فالذين عند ربك يسبحون له باليل والنهار وهم لا يسٔمون"
    },
    {
      "surah_number": 41,
      "verse_number": 39,
      "content": "ومن اياته أنك ترى الأرض خاشعه فاذا أنزلنا عليها الما اهتزت وربت ان الذي أحياها لمحي الموتىا انه علىا كل شي قدير"
    },
    {
      "surah_number": 41,
      "verse_number": 40,
      "content": "ان الذين يلحدون في اياتنا لا يخفون علينا أفمن يلقىا في النار خير أم من يأتي امنا يوم القيامه اعملوا ما شئتم انه بما تعملون بصير"
    },
    {
      "surah_number": 41,
      "verse_number": 41,
      "content": "ان الذين كفروا بالذكر لما جاهم وانه لكتاب عزيز"
    },
    {
      "surah_number": 41,
      "verse_number": 42,
      "content": "لا يأتيه الباطل من بين يديه ولا من خلفه تنزيل من حكيم حميد"
    },
    {
      "surah_number": 41,
      "verse_number": 43,
      "content": "ما يقال لك الا ما قد قيل للرسل من قبلك ان ربك لذو مغفره وذو عقاب أليم"
    },
    {
      "surah_number": 41,
      "verse_number": 44,
      "content": "ولو جعلناه قرانا أعجميا لقالوا لولا فصلت اياته اعجمي وعربي قل هو للذين امنوا هدى وشفا والذين لا يؤمنون في اذانهم وقر وهو عليهم عمى أولائك ينادون من مكان بعيد"
    },
    {
      "surah_number": 41,
      "verse_number": 45,
      "content": "ولقد اتينا موسى الكتاب فاختلف فيه ولولا كلمه سبقت من ربك لقضي بينهم وانهم لفي شك منه مريب"
    },
    {
      "surah_number": 41,
      "verse_number": 46,
      "content": "من عمل صالحا فلنفسه ومن أسا فعليها وما ربك بظلام للعبيد"
    },
    {
      "surah_number": 41,
      "verse_number": 47,
      "content": "اليه يرد علم الساعه وما تخرج من ثمرات من أكمامها وما تحمل من أنثىا ولا تضع الا بعلمه ويوم يناديهم أين شركاي قالوا اذناك مامنا من شهيد"
    },
    {
      "surah_number": 41,
      "verse_number": 48,
      "content": "وضل عنهم ما كانوا يدعون من قبل وظنوا ما لهم من محيص"
    },
    {
      "surah_number": 41,
      "verse_number": 49,
      "content": "لا يسٔم الانسان من دعا الخير وان مسه الشر فئوس قنوط"
    },
    {
      "surah_number": 41,
      "verse_number": 50,
      "content": "ولئن أذقناه رحمه منا من بعد ضرا مسته ليقولن هاذا لي وما أظن الساعه قائمه ولئن رجعت الىا ربي ان لي عنده للحسنىا فلننبئن الذين كفروا بما عملوا ولنذيقنهم من عذاب غليظ"
    },
    {
      "surah_number": 41,
      "verse_number": 51,
      "content": "واذا أنعمنا على الانسان أعرض ونٔا بجانبه واذا مسه الشر فذو دعا عريض"
    },
    {
      "surah_number": 41,
      "verse_number": 52,
      "content": "قل أريتم ان كان من عند الله ثم كفرتم به من أضل ممن هو في شقاق بعيد"
    },
    {
      "surah_number": 41,
      "verse_number": 53,
      "content": "سنريهم اياتنا في الأفاق وفي أنفسهم حتىا يتبين لهم أنه الحق أولم يكف بربك أنه علىا كل شي شهيد"
    },
    {
      "surah_number": 41,
      "verse_number": 54,
      "content": "ألا انهم في مريه من لقا ربهم ألا انه بكل شي محيط"
    },
    {
      "surah_number": 42,
      "verse_number": 1,
      "content": "حم"
    },
    {
      "surah_number": 42,
      "verse_number": 2,
      "content": "عسق"
    },
    {
      "surah_number": 42,
      "verse_number": 3,
      "content": "كذالك يوحي اليك والى الذين من قبلك الله العزيز الحكيم"
    },
    {
      "surah_number": 42,
      "verse_number": 4,
      "content": "له ما في السماوات وما في الأرض وهو العلي العظيم"
    },
    {
      "surah_number": 42,
      "verse_number": 5,
      "content": "تكاد السماوات يتفطرن من فوقهن والملائكه يسبحون بحمد ربهم ويستغفرون لمن في الأرض ألا ان الله هو الغفور الرحيم"
    },
    {
      "surah_number": 42,
      "verse_number": 6,
      "content": "والذين اتخذوا من دونه أوليا الله حفيظ عليهم وما أنت عليهم بوكيل"
    },
    {
      "surah_number": 42,
      "verse_number": 7,
      "content": "وكذالك أوحينا اليك قرانا عربيا لتنذر أم القرىا ومن حولها وتنذر يوم الجمع لا ريب فيه فريق في الجنه وفريق في السعير"
    },
    {
      "surah_number": 42,
      "verse_number": 8,
      "content": "ولو شا الله لجعلهم أمه واحده ولاكن يدخل من يشا في رحمته والظالمون ما لهم من ولي ولا نصير"
    },
    {
      "surah_number": 42,
      "verse_number": 9,
      "content": "أم اتخذوا من دونه أوليا فالله هو الولي وهو يحي الموتىا وهو علىا كل شي قدير"
    },
    {
      "surah_number": 42,
      "verse_number": 10,
      "content": "وما اختلفتم فيه من شي فحكمه الى الله ذالكم الله ربي عليه توكلت واليه أنيب"
    },
    {
      "surah_number": 42,
      "verse_number": 11,
      "content": "فاطر السماوات والأرض جعل لكم من أنفسكم أزواجا ومن الأنعام أزواجا يذرؤكم فيه ليس كمثله شي وهو السميع البصير"
    },
    {
      "surah_number": 42,
      "verse_number": 12,
      "content": "له مقاليد السماوات والأرض يبسط الرزق لمن يشا ويقدر انه بكل شي عليم"
    },
    {
      "surah_number": 42,
      "verse_number": 13,
      "content": "شرع لكم من الدين ما وصىا به نوحا والذي أوحينا اليك وما وصينا به ابراهيم وموسىا وعيسىا أن أقيموا الدين ولا تتفرقوا فيه كبر على المشركين ما تدعوهم اليه الله يجتبي اليه من يشا ويهدي اليه من ينيب"
    },
    {
      "surah_number": 42,
      "verse_number": 14,
      "content": "وما تفرقوا الا من بعد ما جاهم العلم بغيا بينهم ولولا كلمه سبقت من ربك الىا أجل مسمى لقضي بينهم وان الذين أورثوا الكتاب من بعدهم لفي شك منه مريب"
    },
    {
      "surah_number": 42,
      "verse_number": 15,
      "content": "فلذالك فادع واستقم كما أمرت ولا تتبع أهواهم وقل امنت بما أنزل الله من كتاب وأمرت لأعدل بينكم الله ربنا وربكم لنا أعمالنا ولكم أعمالكم لا حجه بيننا وبينكم الله يجمع بيننا واليه المصير"
    },
    {
      "surah_number": 42,
      "verse_number": 16,
      "content": "والذين يحاجون في الله من بعد ما استجيب له حجتهم داحضه عند ربهم وعليهم غضب ولهم عذاب شديد"
    },
    {
      "surah_number": 42,
      "verse_number": 17,
      "content": "الله الذي أنزل الكتاب بالحق والميزان وما يدريك لعل الساعه قريب"
    },
    {
      "surah_number": 42,
      "verse_number": 18,
      "content": "يستعجل بها الذين لا يؤمنون بها والذين امنوا مشفقون منها ويعلمون أنها الحق ألا ان الذين يمارون في الساعه لفي ضلال بعيد"
    },
    {
      "surah_number": 42,
      "verse_number": 19,
      "content": "الله لطيف بعباده يرزق من يشا وهو القوي العزيز"
    },
    {
      "surah_number": 42,
      "verse_number": 20,
      "content": "من كان يريد حرث الأخره نزد له في حرثه ومن كان يريد حرث الدنيا نؤته منها وما له في الأخره من نصيب"
    },
    {
      "surah_number": 42,
      "verse_number": 21,
      "content": "أم لهم شركاؤا شرعوا لهم من الدين ما لم يأذن به الله ولولا كلمه الفصل لقضي بينهم وان الظالمين لهم عذاب أليم"
    },
    {
      "surah_number": 42,
      "verse_number": 22,
      "content": "ترى الظالمين مشفقين مما كسبوا وهو واقع بهم والذين امنوا وعملوا الصالحات في روضات الجنات لهم ما يشاون عند ربهم ذالك هو الفضل الكبير"
    },
    {
      "surah_number": 42,
      "verse_number": 23,
      "content": "ذالك الذي يبشر الله عباده الذين امنوا وعملوا الصالحات قل لا أسٔلكم عليه أجرا الا الموده في القربىا ومن يقترف حسنه نزد له فيها حسنا ان الله غفور شكور"
    },
    {
      "surah_number": 42,
      "verse_number": 24,
      "content": "أم يقولون افترىا على الله كذبا فان يشا الله يختم علىا قلبك ويمح الله الباطل ويحق الحق بكلماته انه عليم بذات الصدور"
    },
    {
      "surah_number": 42,
      "verse_number": 25,
      "content": "وهو الذي يقبل التوبه عن عباده ويعفوا عن السئات ويعلم ما تفعلون"
    },
    {
      "surah_number": 42,
      "verse_number": 26,
      "content": "ويستجيب الذين امنوا وعملوا الصالحات ويزيدهم من فضله والكافرون لهم عذاب شديد"
    },
    {
      "surah_number": 42,
      "verse_number": 27,
      "content": "ولو بسط الله الرزق لعباده لبغوا في الأرض ولاكن ينزل بقدر ما يشا انه بعباده خبير بصير"
    },
    {
      "surah_number": 42,
      "verse_number": 28,
      "content": "وهو الذي ينزل الغيث من بعد ما قنطوا وينشر رحمته وهو الولي الحميد"
    },
    {
      "surah_number": 42,
      "verse_number": 29,
      "content": "ومن اياته خلق السماوات والأرض وما بث فيهما من دابه وهو علىا جمعهم اذا يشا قدير"
    },
    {
      "surah_number": 42,
      "verse_number": 30,
      "content": "وما أصابكم من مصيبه فبما كسبت أيديكم ويعفوا عن كثير"
    },
    {
      "surah_number": 42,
      "verse_number": 31,
      "content": "وما أنتم بمعجزين في الأرض وما لكم من دون الله من ولي ولا نصير"
    },
    {
      "surah_number": 42,
      "verse_number": 32,
      "content": "ومن اياته الجوار في البحر كالأعلام"
    },
    {
      "surah_number": 42,
      "verse_number": 33,
      "content": "ان يشأ يسكن الريح فيظللن رواكد علىا ظهره ان في ذالك لأيات لكل صبار شكور"
    },
    {
      "surah_number": 42,
      "verse_number": 34,
      "content": "أو يوبقهن بما كسبوا ويعف عن كثير"
    },
    {
      "surah_number": 42,
      "verse_number": 35,
      "content": "ويعلم الذين يجادلون في اياتنا ما لهم من محيص"
    },
    {
      "surah_number": 42,
      "verse_number": 36,
      "content": "فما أوتيتم من شي فمتاع الحيواه الدنيا وما عند الله خير وأبقىا للذين امنوا وعلىا ربهم يتوكلون"
    },
    {
      "surah_number": 42,
      "verse_number": 37,
      "content": "والذين يجتنبون كبائر الاثم والفواحش واذا ما غضبوا هم يغفرون"
    },
    {
      "surah_number": 42,
      "verse_number": 38,
      "content": "والذين استجابوا لربهم وأقاموا الصلواه وأمرهم شورىا بينهم ومما رزقناهم ينفقون"
    },
    {
      "surah_number": 42,
      "verse_number": 39,
      "content": "والذين اذا أصابهم البغي هم ينتصرون"
    },
    {
      "surah_number": 42,
      "verse_number": 40,
      "content": "وجزاؤا سيئه سيئه مثلها فمن عفا وأصلح فأجره على الله انه لا يحب الظالمين"
    },
    {
      "surah_number": 42,
      "verse_number": 41,
      "content": "ولمن انتصر بعد ظلمه فأولائك ما عليهم من سبيل"
    },
    {
      "surah_number": 42,
      "verse_number": 42,
      "content": "انما السبيل على الذين يظلمون الناس ويبغون في الأرض بغير الحق أولائك لهم عذاب أليم"
    },
    {
      "surah_number": 42,
      "verse_number": 43,
      "content": "ولمن صبر وغفر ان ذالك لمن عزم الأمور"
    },
    {
      "surah_number": 42,
      "verse_number": 44,
      "content": "ومن يضلل الله فما له من ولي من بعده وترى الظالمين لما رأوا العذاب يقولون هل الىا مرد من سبيل"
    },
    {
      "surah_number": 42,
      "verse_number": 45,
      "content": "وترىاهم يعرضون عليها خاشعين من الذل ينظرون من طرف خفي وقال الذين امنوا ان الخاسرين الذين خسروا أنفسهم وأهليهم يوم القيامه ألا ان الظالمين في عذاب مقيم"
    },
    {
      "surah_number": 42,
      "verse_number": 46,
      "content": "وما كان لهم من أوليا ينصرونهم من دون الله ومن يضلل الله فما له من سبيل"
    },
    {
      "surah_number": 42,
      "verse_number": 47,
      "content": "استجيبوا لربكم من قبل أن يأتي يوم لا مرد له من الله ما لكم من ملجا يومئذ وما لكم من نكير"
    },
    {
      "surah_number": 42,
      "verse_number": 48,
      "content": "فان أعرضوا فما أرسلناك عليهم حفيظا ان عليك الا البلاغ وانا اذا أذقنا الانسان منا رحمه فرح بها وان تصبهم سيئه بما قدمت أيديهم فان الانسان كفور"
    },
    {
      "surah_number": 42,
      "verse_number": 49,
      "content": "لله ملك السماوات والأرض يخلق ما يشا يهب لمن يشا اناثا ويهب لمن يشا الذكور"
    },
    {
      "surah_number": 42,
      "verse_number": 50,
      "content": "أو يزوجهم ذكرانا واناثا ويجعل من يشا عقيما انه عليم قدير"
    },
    {
      "surah_number": 42,
      "verse_number": 51,
      "content": "وما كان لبشر أن يكلمه الله الا وحيا أو من وراي حجاب أو يرسل رسولا فيوحي باذنه ما يشا انه علي حكيم"
    },
    {
      "surah_number": 42,
      "verse_number": 52,
      "content": "وكذالك أوحينا اليك روحا من أمرنا ما كنت تدري ما الكتاب ولا الايمان ولاكن جعلناه نورا نهدي به من نشا من عبادنا وانك لتهدي الىا صراط مستقيم"
    },
    {
      "surah_number": 42,
      "verse_number": 53,
      "content": "صراط الله الذي له ما في السماوات وما في الأرض ألا الى الله تصير الأمور"
    },
    {
      "surah_number": 43,
      "verse_number": 1,
      "content": "حم"
    },
    {
      "surah_number": 43,
      "verse_number": 2,
      "content": "والكتاب المبين"
    },
    {
      "surah_number": 43,
      "verse_number": 3,
      "content": "انا جعلناه قرانا عربيا لعلكم تعقلون"
    },
    {
      "surah_number": 43,
      "verse_number": 4,
      "content": "وانه في أم الكتاب لدينا لعلي حكيم"
    },
    {
      "surah_number": 43,
      "verse_number": 5,
      "content": "أفنضرب عنكم الذكر صفحا أن كنتم قوما مسرفين"
    },
    {
      "surah_number": 43,
      "verse_number": 6,
      "content": "وكم أرسلنا من نبي في الأولين"
    },
    {
      "surah_number": 43,
      "verse_number": 7,
      "content": "وما يأتيهم من نبي الا كانوا به يستهزون"
    },
    {
      "surah_number": 43,
      "verse_number": 8,
      "content": "فأهلكنا أشد منهم بطشا ومضىا مثل الأولين"
    },
    {
      "surah_number": 43,
      "verse_number": 9,
      "content": "ولئن سألتهم من خلق السماوات والأرض ليقولن خلقهن العزيز العليم"
    },
    {
      "surah_number": 43,
      "verse_number": 10,
      "content": "الذي جعل لكم الأرض مهدا وجعل لكم فيها سبلا لعلكم تهتدون"
    },
    {
      "surah_number": 43,
      "verse_number": 11,
      "content": "والذي نزل من السما ما بقدر فأنشرنا به بلده ميتا كذالك تخرجون"
    },
    {
      "surah_number": 43,
      "verse_number": 12,
      "content": "والذي خلق الأزواج كلها وجعل لكم من الفلك والأنعام ما تركبون"
    },
    {
      "surah_number": 43,
      "verse_number": 13,
      "content": "لتستوا علىا ظهوره ثم تذكروا نعمه ربكم اذا استويتم عليه وتقولوا سبحان الذي سخر لنا هاذا وما كنا له مقرنين"
    },
    {
      "surah_number": 43,
      "verse_number": 14,
      "content": "وانا الىا ربنا لمنقلبون"
    },
    {
      "surah_number": 43,
      "verse_number": 15,
      "content": "وجعلوا له من عباده جزا ان الانسان لكفور مبين"
    },
    {
      "surah_number": 43,
      "verse_number": 16,
      "content": "أم اتخذ مما يخلق بنات وأصفىاكم بالبنين"
    },
    {
      "surah_number": 43,
      "verse_number": 17,
      "content": "واذا بشر أحدهم بما ضرب للرحمان مثلا ظل وجهه مسودا وهو كظيم"
    },
    {
      "surah_number": 43,
      "verse_number": 18,
      "content": "أومن ينشؤا في الحليه وهو في الخصام غير مبين"
    },
    {
      "surah_number": 43,
      "verse_number": 19,
      "content": "وجعلوا الملائكه الذين هم عباد الرحمان اناثا أشهدوا خلقهم ستكتب شهادتهم ويسٔلون"
    },
    {
      "surah_number": 43,
      "verse_number": 20,
      "content": "وقالوا لو شا الرحمان ما عبدناهم ما لهم بذالك من علم ان هم الا يخرصون"
    },
    {
      "surah_number": 43,
      "verse_number": 21,
      "content": "أم اتيناهم كتابا من قبله فهم به مستمسكون"
    },
    {
      "surah_number": 43,
      "verse_number": 22,
      "content": "بل قالوا انا وجدنا ابانا علىا أمه وانا علىا اثارهم مهتدون"
    },
    {
      "surah_number": 43,
      "verse_number": 23,
      "content": "وكذالك ما أرسلنا من قبلك في قريه من نذير الا قال مترفوها انا وجدنا ابانا علىا أمه وانا علىا اثارهم مقتدون"
    },
    {
      "surah_number": 43,
      "verse_number": 24,
      "content": "قال أولو جئتكم بأهدىا مما وجدتم عليه اباكم قالوا انا بما أرسلتم به كافرون"
    },
    {
      "surah_number": 43,
      "verse_number": 25,
      "content": "فانتقمنا منهم فانظر كيف كان عاقبه المكذبين"
    },
    {
      "surah_number": 43,
      "verse_number": 26,
      "content": "واذ قال ابراهيم لأبيه وقومه انني برا مما تعبدون"
    },
    {
      "surah_number": 43,
      "verse_number": 27,
      "content": "الا الذي فطرني فانه سيهدين"
    },
    {
      "surah_number": 43,
      "verse_number": 28,
      "content": "وجعلها كلمه باقيه في عقبه لعلهم يرجعون"
    },
    {
      "surah_number": 43,
      "verse_number": 29,
      "content": "بل متعت هاؤلا واباهم حتىا جاهم الحق ورسول مبين"
    },
    {
      "surah_number": 43,
      "verse_number": 30,
      "content": "ولما جاهم الحق قالوا هاذا سحر وانا به كافرون"
    },
    {
      "surah_number": 43,
      "verse_number": 31,
      "content": "وقالوا لولا نزل هاذا القران علىا رجل من القريتين عظيم"
    },
    {
      "surah_number": 43,
      "verse_number": 32,
      "content": "أهم يقسمون رحمت ربك نحن قسمنا بينهم معيشتهم في الحيواه الدنيا ورفعنا بعضهم فوق بعض درجات ليتخذ بعضهم بعضا سخريا ورحمت ربك خير مما يجمعون"
    },
    {
      "surah_number": 43,
      "verse_number": 33,
      "content": "ولولا أن يكون الناس أمه واحده لجعلنا لمن يكفر بالرحمان لبيوتهم سقفا من فضه ومعارج عليها يظهرون"
    },
    {
      "surah_number": 43,
      "verse_number": 34,
      "content": "ولبيوتهم أبوابا وسررا عليها يتكٔون"
    },
    {
      "surah_number": 43,
      "verse_number": 35,
      "content": "وزخرفا وان كل ذالك لما متاع الحيواه الدنيا والأخره عند ربك للمتقين"
    },
    {
      "surah_number": 43,
      "verse_number": 36,
      "content": "ومن يعش عن ذكر الرحمان نقيض له شيطانا فهو له قرين"
    },
    {
      "surah_number": 43,
      "verse_number": 37,
      "content": "وانهم ليصدونهم عن السبيل ويحسبون أنهم مهتدون"
    },
    {
      "surah_number": 43,
      "verse_number": 38,
      "content": "حتىا اذا جانا قال ياليت بيني وبينك بعد المشرقين فبئس القرين"
    },
    {
      "surah_number": 43,
      "verse_number": 39,
      "content": "ولن ينفعكم اليوم اذ ظلمتم أنكم في العذاب مشتركون"
    },
    {
      "surah_number": 43,
      "verse_number": 40,
      "content": "أفأنت تسمع الصم أو تهدي العمي ومن كان في ضلال مبين"
    },
    {
      "surah_number": 43,
      "verse_number": 41,
      "content": "فاما نذهبن بك فانا منهم منتقمون"
    },
    {
      "surah_number": 43,
      "verse_number": 42,
      "content": "أو نرينك الذي وعدناهم فانا عليهم مقتدرون"
    },
    {
      "surah_number": 43,
      "verse_number": 43,
      "content": "فاستمسك بالذي أوحي اليك انك علىا صراط مستقيم"
    },
    {
      "surah_number": 43,
      "verse_number": 44,
      "content": "وانه لذكر لك ولقومك وسوف تسٔلون"
    },
    {
      "surah_number": 43,
      "verse_number": 45,
      "content": "وسٔل من أرسلنا من قبلك من رسلنا أجعلنا من دون الرحمان الهه يعبدون"
    },
    {
      "surah_number": 43,
      "verse_number": 46,
      "content": "ولقد أرسلنا موسىا بٔاياتنا الىا فرعون وملايه فقال اني رسول رب العالمين"
    },
    {
      "surah_number": 43,
      "verse_number": 47,
      "content": "فلما جاهم بٔاياتنا اذا هم منها يضحكون"
    },
    {
      "surah_number": 43,
      "verse_number": 48,
      "content": "وما نريهم من ايه الا هي أكبر من أختها وأخذناهم بالعذاب لعلهم يرجعون"
    },
    {
      "surah_number": 43,
      "verse_number": 49,
      "content": "وقالوا ياأيه الساحر ادع لنا ربك بما عهد عندك اننا لمهتدون"
    },
    {
      "surah_number": 43,
      "verse_number": 50,
      "content": "فلما كشفنا عنهم العذاب اذا هم ينكثون"
    },
    {
      "surah_number": 43,
      "verse_number": 51,
      "content": "ونادىا فرعون في قومه قال ياقوم أليس لي ملك مصر وهاذه الأنهار تجري من تحتي أفلا تبصرون"
    },
    {
      "surah_number": 43,
      "verse_number": 52,
      "content": "أم أنا خير من هاذا الذي هو مهين ولا يكاد يبين"
    },
    {
      "surah_number": 43,
      "verse_number": 53,
      "content": "فلولا ألقي عليه أسوره من ذهب أو جا معه الملائكه مقترنين"
    },
    {
      "surah_number": 43,
      "verse_number": 54,
      "content": "فاستخف قومه فأطاعوه انهم كانوا قوما فاسقين"
    },
    {
      "surah_number": 43,
      "verse_number": 55,
      "content": "فلما اسفونا انتقمنا منهم فأغرقناهم أجمعين"
    },
    {
      "surah_number": 43,
      "verse_number": 56,
      "content": "فجعلناهم سلفا ومثلا للأخرين"
    },
    {
      "surah_number": 43,
      "verse_number": 57,
      "content": "ولما ضرب ابن مريم مثلا اذا قومك منه يصدون"
    },
    {
      "surah_number": 43,
      "verse_number": 58,
      "content": "وقالوا ءأالهتنا خير أم هو ما ضربوه لك الا جدلا بل هم قوم خصمون"
    },
    {
      "surah_number": 43,
      "verse_number": 59,
      "content": "ان هو الا عبد أنعمنا عليه وجعلناه مثلا لبني اسرايل"
    },
    {
      "surah_number": 43,
      "verse_number": 60,
      "content": "ولو نشا لجعلنا منكم ملائكه في الأرض يخلفون"
    },
    {
      "surah_number": 43,
      "verse_number": 61,
      "content": "وانه لعلم للساعه فلا تمترن بها واتبعون هاذا صراط مستقيم"
    },
    {
      "surah_number": 43,
      "verse_number": 62,
      "content": "ولا يصدنكم الشيطان انه لكم عدو مبين"
    },
    {
      "surah_number": 43,
      "verse_number": 63,
      "content": "ولما جا عيسىا بالبينات قال قد جئتكم بالحكمه ولأبين لكم بعض الذي تختلفون فيه فاتقوا الله وأطيعون"
    },
    {
      "surah_number": 43,
      "verse_number": 64,
      "content": "ان الله هو ربي وربكم فاعبدوه هاذا صراط مستقيم"
    },
    {
      "surah_number": 43,
      "verse_number": 65,
      "content": "فاختلف الأحزاب من بينهم فويل للذين ظلموا من عذاب يوم أليم"
    },
    {
      "surah_number": 43,
      "verse_number": 66,
      "content": "هل ينظرون الا الساعه أن تأتيهم بغته وهم لا يشعرون"
    },
    {
      "surah_number": 43,
      "verse_number": 67,
      "content": "الأخلا يومئذ بعضهم لبعض عدو الا المتقين"
    },
    {
      "surah_number": 43,
      "verse_number": 68,
      "content": "ياعباد لا خوف عليكم اليوم ولا أنتم تحزنون"
    },
    {
      "surah_number": 43,
      "verse_number": 69,
      "content": "الذين امنوا بٔاياتنا وكانوا مسلمين"
    },
    {
      "surah_number": 43,
      "verse_number": 70,
      "content": "ادخلوا الجنه أنتم وأزواجكم تحبرون"
    },
    {
      "surah_number": 43,
      "verse_number": 71,
      "content": "يطاف عليهم بصحاف من ذهب وأكواب وفيها ما تشتهيه الأنفس وتلذ الأعين وأنتم فيها خالدون"
    },
    {
      "surah_number": 43,
      "verse_number": 72,
      "content": "وتلك الجنه التي أورثتموها بما كنتم تعملون"
    },
    {
      "surah_number": 43,
      "verse_number": 73,
      "content": "لكم فيها فاكهه كثيره منها تأكلون"
    },
    {
      "surah_number": 43,
      "verse_number": 74,
      "content": "ان المجرمين في عذاب جهنم خالدون"
    },
    {
      "surah_number": 43,
      "verse_number": 75,
      "content": "لا يفتر عنهم وهم فيه مبلسون"
    },
    {
      "surah_number": 43,
      "verse_number": 76,
      "content": "وما ظلمناهم ولاكن كانوا هم الظالمين"
    },
    {
      "surah_number": 43,
      "verse_number": 77,
      "content": "ونادوا يامالك ليقض علينا ربك قال انكم ماكثون"
    },
    {
      "surah_number": 43,
      "verse_number": 78,
      "content": "لقد جئناكم بالحق ولاكن أكثركم للحق كارهون"
    },
    {
      "surah_number": 43,
      "verse_number": 79,
      "content": "أم أبرموا أمرا فانا مبرمون"
    },
    {
      "surah_number": 43,
      "verse_number": 80,
      "content": "أم يحسبون أنا لا نسمع سرهم ونجوىاهم بلىا ورسلنا لديهم يكتبون"
    },
    {
      "surah_number": 43,
      "verse_number": 81,
      "content": "قل ان كان للرحمان ولد فأنا أول العابدين"
    },
    {
      "surah_number": 43,
      "verse_number": 82,
      "content": "سبحان رب السماوات والأرض رب العرش عما يصفون"
    },
    {
      "surah_number": 43,
      "verse_number": 83,
      "content": "فذرهم يخوضوا ويلعبوا حتىا يلاقوا يومهم الذي يوعدون"
    },
    {
      "surah_number": 43,
      "verse_number": 84,
      "content": "وهو الذي في السما الاه وفي الأرض الاه وهو الحكيم العليم"
    },
    {
      "surah_number": 43,
      "verse_number": 85,
      "content": "وتبارك الذي له ملك السماوات والأرض وما بينهما وعنده علم الساعه واليه ترجعون"
    },
    {
      "surah_number": 43,
      "verse_number": 86,
      "content": "ولا يملك الذين يدعون من دونه الشفاعه الا من شهد بالحق وهم يعلمون"
    },
    {
      "surah_number": 43,
      "verse_number": 87,
      "content": "ولئن سألتهم من خلقهم ليقولن الله فأنىا يؤفكون"
    },
    {
      "surah_number": 43,
      "verse_number": 88,
      "content": "وقيله يارب ان هاؤلا قوم لا يؤمنون"
    },
    {
      "surah_number": 43,
      "verse_number": 89,
      "content": "فاصفح عنهم وقل سلام فسوف يعلمون"
    },
    {
      "surah_number": 44,
      "verse_number": 1,
      "content": "حم"
    },
    {
      "surah_number": 44,
      "verse_number": 2,
      "content": "والكتاب المبين"
    },
    {
      "surah_number": 44,
      "verse_number": 3,
      "content": "انا أنزلناه في ليله مباركه انا كنا منذرين"
    },
    {
      "surah_number": 44,
      "verse_number": 4,
      "content": "فيها يفرق كل أمر حكيم"
    },
    {
      "surah_number": 44,
      "verse_number": 5,
      "content": "أمرا من عندنا انا كنا مرسلين"
    },
    {
      "surah_number": 44,
      "verse_number": 6,
      "content": "رحمه من ربك انه هو السميع العليم"
    },
    {
      "surah_number": 44,
      "verse_number": 7,
      "content": "رب السماوات والأرض وما بينهما ان كنتم موقنين"
    },
    {
      "surah_number": 44,
      "verse_number": 8,
      "content": "لا الاه الا هو يحي ويميت ربكم ورب ابائكم الأولين"
    },
    {
      "surah_number": 44,
      "verse_number": 9,
      "content": "بل هم في شك يلعبون"
    },
    {
      "surah_number": 44,
      "verse_number": 10,
      "content": "فارتقب يوم تأتي السما بدخان مبين"
    },
    {
      "surah_number": 44,
      "verse_number": 11,
      "content": "يغشى الناس هاذا عذاب أليم"
    },
    {
      "surah_number": 44,
      "verse_number": 12,
      "content": "ربنا اكشف عنا العذاب انا مؤمنون"
    },
    {
      "surah_number": 44,
      "verse_number": 13,
      "content": "أنىا لهم الذكرىا وقد جاهم رسول مبين"
    },
    {
      "surah_number": 44,
      "verse_number": 14,
      "content": "ثم تولوا عنه وقالوا معلم مجنون"
    },
    {
      "surah_number": 44,
      "verse_number": 15,
      "content": "انا كاشفوا العذاب قليلا انكم عائدون"
    },
    {
      "surah_number": 44,
      "verse_number": 16,
      "content": "يوم نبطش البطشه الكبرىا انا منتقمون"
    },
    {
      "surah_number": 44,
      "verse_number": 17,
      "content": "ولقد فتنا قبلهم قوم فرعون وجاهم رسول كريم"
    },
    {
      "surah_number": 44,
      "verse_number": 18,
      "content": "أن أدوا الي عباد الله اني لكم رسول أمين"
    },
    {
      "surah_number": 44,
      "verse_number": 19,
      "content": "وأن لا تعلوا على الله اني اتيكم بسلطان مبين"
    },
    {
      "surah_number": 44,
      "verse_number": 20,
      "content": "واني عذت بربي وربكم أن ترجمون"
    },
    {
      "surah_number": 44,
      "verse_number": 21,
      "content": "وان لم تؤمنوا لي فاعتزلون"
    },
    {
      "surah_number": 44,
      "verse_number": 22,
      "content": "فدعا ربه أن هاؤلا قوم مجرمون"
    },
    {
      "surah_number": 44,
      "verse_number": 23,
      "content": "فأسر بعبادي ليلا انكم متبعون"
    },
    {
      "surah_number": 44,
      "verse_number": 24,
      "content": "واترك البحر رهوا انهم جند مغرقون"
    },
    {
      "surah_number": 44,
      "verse_number": 25,
      "content": "كم تركوا من جنات وعيون"
    },
    {
      "surah_number": 44,
      "verse_number": 26,
      "content": "وزروع ومقام كريم"
    },
    {
      "surah_number": 44,
      "verse_number": 27,
      "content": "ونعمه كانوا فيها فاكهين"
    },
    {
      "surah_number": 44,
      "verse_number": 28,
      "content": "كذالك وأورثناها قوما اخرين"
    },
    {
      "surah_number": 44,
      "verse_number": 29,
      "content": "فما بكت عليهم السما والأرض وما كانوا منظرين"
    },
    {
      "surah_number": 44,
      "verse_number": 30,
      "content": "ولقد نجينا بني اسرايل من العذاب المهين"
    },
    {
      "surah_number": 44,
      "verse_number": 31,
      "content": "من فرعون انه كان عاليا من المسرفين"
    },
    {
      "surah_number": 44,
      "verse_number": 32,
      "content": "ولقد اخترناهم علىا علم على العالمين"
    },
    {
      "surah_number": 44,
      "verse_number": 33,
      "content": "واتيناهم من الأيات ما فيه بلاؤا مبين"
    },
    {
      "surah_number": 44,
      "verse_number": 34,
      "content": "ان هاؤلا ليقولون"
    },
    {
      "surah_number": 44,
      "verse_number": 35,
      "content": "ان هي الا موتتنا الأولىا وما نحن بمنشرين"
    },
    {
      "surah_number": 44,
      "verse_number": 36,
      "content": "فأتوا بٔابائنا ان كنتم صادقين"
    },
    {
      "surah_number": 44,
      "verse_number": 37,
      "content": "أهم خير أم قوم تبع والذين من قبلهم أهلكناهم انهم كانوا مجرمين"
    },
    {
      "surah_number": 44,
      "verse_number": 38,
      "content": "وما خلقنا السماوات والأرض وما بينهما لاعبين"
    },
    {
      "surah_number": 44,
      "verse_number": 39,
      "content": "ما خلقناهما الا بالحق ولاكن أكثرهم لا يعلمون"
    },
    {
      "surah_number": 44,
      "verse_number": 40,
      "content": "ان يوم الفصل ميقاتهم أجمعين"
    },
    {
      "surah_number": 44,
      "verse_number": 41,
      "content": "يوم لا يغني مولى عن مولى شئا ولا هم ينصرون"
    },
    {
      "surah_number": 44,
      "verse_number": 42,
      "content": "الا من رحم الله انه هو العزيز الرحيم"
    },
    {
      "surah_number": 44,
      "verse_number": 43,
      "content": "ان شجرت الزقوم"
    },
    {
      "surah_number": 44,
      "verse_number": 44,
      "content": "طعام الأثيم"
    },
    {
      "surah_number": 44,
      "verse_number": 45,
      "content": "كالمهل يغلي في البطون"
    },
    {
      "surah_number": 44,
      "verse_number": 46,
      "content": "كغلي الحميم"
    },
    {
      "surah_number": 44,
      "verse_number": 47,
      "content": "خذوه فاعتلوه الىا سوا الجحيم"
    },
    {
      "surah_number": 44,
      "verse_number": 48,
      "content": "ثم صبوا فوق رأسه من عذاب الحميم"
    },
    {
      "surah_number": 44,
      "verse_number": 49,
      "content": "ذق انك أنت العزيز الكريم"
    },
    {
      "surah_number": 44,
      "verse_number": 50,
      "content": "ان هاذا ما كنتم به تمترون"
    },
    {
      "surah_number": 44,
      "verse_number": 51,
      "content": "ان المتقين في مقام أمين"
    },
    {
      "surah_number": 44,
      "verse_number": 52,
      "content": "في جنات وعيون"
    },
    {
      "surah_number": 44,
      "verse_number": 53,
      "content": "يلبسون من سندس واستبرق متقابلين"
    },
    {
      "surah_number": 44,
      "verse_number": 54,
      "content": "كذالك وزوجناهم بحور عين"
    },
    {
      "surah_number": 44,
      "verse_number": 55,
      "content": "يدعون فيها بكل فاكهه امنين"
    },
    {
      "surah_number": 44,
      "verse_number": 56,
      "content": "لا يذوقون فيها الموت الا الموته الأولىا ووقىاهم عذاب الجحيم"
    },
    {
      "surah_number": 44,
      "verse_number": 57,
      "content": "فضلا من ربك ذالك هو الفوز العظيم"
    },
    {
      "surah_number": 44,
      "verse_number": 58,
      "content": "فانما يسرناه بلسانك لعلهم يتذكرون"
    },
    {
      "surah_number": 44,
      "verse_number": 59,
      "content": "فارتقب انهم مرتقبون"
    },
    {
      "surah_number": 45,
      "verse_number": 1,
      "content": "حم"
    },
    {
      "surah_number": 45,
      "verse_number": 2,
      "content": "تنزيل الكتاب من الله العزيز الحكيم"
    },
    {
      "surah_number": 45,
      "verse_number": 3,
      "content": "ان في السماوات والأرض لأيات للمؤمنين"
    },
    {
      "surah_number": 45,
      "verse_number": 4,
      "content": "وفي خلقكم وما يبث من دابه ايات لقوم يوقنون"
    },
    {
      "surah_number": 45,
      "verse_number": 5,
      "content": "واختلاف اليل والنهار وما أنزل الله من السما من رزق فأحيا به الأرض بعد موتها وتصريف الرياح ايات لقوم يعقلون"
    },
    {
      "surah_number": 45,
      "verse_number": 6,
      "content": "تلك ايات الله نتلوها عليك بالحق فبأي حديث بعد الله واياته يؤمنون"
    },
    {
      "surah_number": 45,
      "verse_number": 7,
      "content": "ويل لكل أفاك أثيم"
    },
    {
      "surah_number": 45,
      "verse_number": 8,
      "content": "يسمع ايات الله تتلىا عليه ثم يصر مستكبرا كأن لم يسمعها فبشره بعذاب أليم"
    },
    {
      "surah_number": 45,
      "verse_number": 9,
      "content": "واذا علم من اياتنا شئا اتخذها هزوا أولائك لهم عذاب مهين"
    },
    {
      "surah_number": 45,
      "verse_number": 10,
      "content": "من ورائهم جهنم ولا يغني عنهم ما كسبوا شئا ولا ما اتخذوا من دون الله أوليا ولهم عذاب عظيم"
    },
    {
      "surah_number": 45,
      "verse_number": 11,
      "content": "هاذا هدى والذين كفروا بٔايات ربهم لهم عذاب من رجز أليم"
    },
    {
      "surah_number": 45,
      "verse_number": 12,
      "content": "الله الذي سخر لكم البحر لتجري الفلك فيه بأمره ولتبتغوا من فضله ولعلكم تشكرون"
    },
    {
      "surah_number": 45,
      "verse_number": 13,
      "content": "وسخر لكم ما في السماوات وما في الأرض جميعا منه ان في ذالك لأيات لقوم يتفكرون"
    },
    {
      "surah_number": 45,
      "verse_number": 14,
      "content": "قل للذين امنوا يغفروا للذين لا يرجون أيام الله ليجزي قوما بما كانوا يكسبون"
    },
    {
      "surah_number": 45,
      "verse_number": 15,
      "content": "من عمل صالحا فلنفسه ومن أسا فعليها ثم الىا ربكم ترجعون"
    },
    {
      "surah_number": 45,
      "verse_number": 16,
      "content": "ولقد اتينا بني اسرايل الكتاب والحكم والنبوه ورزقناهم من الطيبات وفضلناهم على العالمين"
    },
    {
      "surah_number": 45,
      "verse_number": 17,
      "content": "واتيناهم بينات من الأمر فما اختلفوا الا من بعد ما جاهم العلم بغيا بينهم ان ربك يقضي بينهم يوم القيامه فيما كانوا فيه يختلفون"
    },
    {
      "surah_number": 45,
      "verse_number": 18,
      "content": "ثم جعلناك علىا شريعه من الأمر فاتبعها ولا تتبع أهوا الذين لا يعلمون"
    },
    {
      "surah_number": 45,
      "verse_number": 19,
      "content": "انهم لن يغنوا عنك من الله شئا وان الظالمين بعضهم أوليا بعض والله ولي المتقين"
    },
    {
      "surah_number": 45,
      "verse_number": 20,
      "content": "هاذا بصائر للناس وهدى ورحمه لقوم يوقنون"
    },
    {
      "surah_number": 45,
      "verse_number": 21,
      "content": "أم حسب الذين اجترحوا السئات أن نجعلهم كالذين امنوا وعملوا الصالحات سوا محياهم ومماتهم سا ما يحكمون"
    },
    {
      "surah_number": 45,
      "verse_number": 22,
      "content": "وخلق الله السماوات والأرض بالحق ولتجزىا كل نفس بما كسبت وهم لا يظلمون"
    },
    {
      "surah_number": 45,
      "verse_number": 23,
      "content": "أفريت من اتخذ الاهه هوىاه وأضله الله علىا علم وختم علىا سمعه وقلبه وجعل علىا بصره غشاوه فمن يهديه من بعد الله أفلا تذكرون"
    },
    {
      "surah_number": 45,
      "verse_number": 24,
      "content": "وقالوا ما هي الا حياتنا الدنيا نموت ونحيا وما يهلكنا الا الدهر وما لهم بذالك من علم ان هم الا يظنون"
    },
    {
      "surah_number": 45,
      "verse_number": 25,
      "content": "واذا تتلىا عليهم اياتنا بينات ما كان حجتهم الا أن قالوا ائتوا بٔابائنا ان كنتم صادقين"
    },
    {
      "surah_number": 45,
      "verse_number": 26,
      "content": "قل الله يحييكم ثم يميتكم ثم يجمعكم الىا يوم القيامه لا ريب فيه ولاكن أكثر الناس لا يعلمون"
    },
    {
      "surah_number": 45,
      "verse_number": 27,
      "content": "ولله ملك السماوات والأرض ويوم تقوم الساعه يومئذ يخسر المبطلون"
    },
    {
      "surah_number": 45,
      "verse_number": 28,
      "content": "وترىا كل أمه جاثيه كل أمه تدعىا الىا كتابها اليوم تجزون ما كنتم تعملون"
    },
    {
      "surah_number": 45,
      "verse_number": 29,
      "content": "هاذا كتابنا ينطق عليكم بالحق انا كنا نستنسخ ما كنتم تعملون"
    },
    {
      "surah_number": 45,
      "verse_number": 30,
      "content": "فأما الذين امنوا وعملوا الصالحات فيدخلهم ربهم في رحمته ذالك هو الفوز المبين"
    },
    {
      "surah_number": 45,
      "verse_number": 31,
      "content": "وأما الذين كفروا أفلم تكن اياتي تتلىا عليكم فاستكبرتم وكنتم قوما مجرمين"
    },
    {
      "surah_number": 45,
      "verse_number": 32,
      "content": "واذا قيل ان وعد الله حق والساعه لا ريب فيها قلتم ما ندري ما الساعه ان نظن الا ظنا وما نحن بمستيقنين"
    },
    {
      "surah_number": 45,
      "verse_number": 33,
      "content": "وبدا لهم سئات ما عملوا وحاق بهم ما كانوا به يستهزون"
    },
    {
      "surah_number": 45,
      "verse_number": 34,
      "content": "وقيل اليوم ننسىاكم كما نسيتم لقا يومكم هاذا ومأوىاكم النار وما لكم من ناصرين"
    },
    {
      "surah_number": 45,
      "verse_number": 35,
      "content": "ذالكم بأنكم اتخذتم ايات الله هزوا وغرتكم الحيواه الدنيا فاليوم لا يخرجون منها ولا هم يستعتبون"
    },
    {
      "surah_number": 45,
      "verse_number": 36,
      "content": "فلله الحمد رب السماوات ورب الأرض رب العالمين"
    },
    {
      "surah_number": 45,
      "verse_number": 37,
      "content": "وله الكبريا في السماوات والأرض وهو العزيز الحكيم"
    },
    {
      "surah_number": 46,
      "verse_number": 1,
      "content": "حم"
    },
    {
      "surah_number": 46,
      "verse_number": 2,
      "content": "تنزيل الكتاب من الله العزيز الحكيم"
    },
    {
      "surah_number": 46,
      "verse_number": 3,
      "content": "ما خلقنا السماوات والأرض وما بينهما الا بالحق وأجل مسمى والذين كفروا عما أنذروا معرضون"
    },
    {
      "surah_number": 46,
      "verse_number": 4,
      "content": "قل أريتم ما تدعون من دون الله أروني ماذا خلقوا من الأرض أم لهم شرك في السماوات ائتوني بكتاب من قبل هاذا أو أثاره من علم ان كنتم صادقين"
    },
    {
      "surah_number": 46,
      "verse_number": 5,
      "content": "ومن أضل ممن يدعوا من دون الله من لا يستجيب له الىا يوم القيامه وهم عن دعائهم غافلون"
    },
    {
      "surah_number": 46,
      "verse_number": 6,
      "content": "واذا حشر الناس كانوا لهم أعدا وكانوا بعبادتهم كافرين"
    },
    {
      "surah_number": 46,
      "verse_number": 7,
      "content": "واذا تتلىا عليهم اياتنا بينات قال الذين كفروا للحق لما جاهم هاذا سحر مبين"
    },
    {
      "surah_number": 46,
      "verse_number": 8,
      "content": "أم يقولون افترىاه قل ان افتريته فلا تملكون لي من الله شئا هو أعلم بما تفيضون فيه كفىا به شهيدا بيني وبينكم وهو الغفور الرحيم"
    },
    {
      "surah_number": 46,
      "verse_number": 9,
      "content": "قل ما كنت بدعا من الرسل وما أدري ما يفعل بي ولا بكم ان أتبع الا ما يوحىا الي وما أنا الا نذير مبين"
    },
    {
      "surah_number": 46,
      "verse_number": 10,
      "content": "قل أريتم ان كان من عند الله وكفرتم به وشهد شاهد من بني اسرايل علىا مثله فٔامن واستكبرتم ان الله لا يهدي القوم الظالمين"
    },
    {
      "surah_number": 46,
      "verse_number": 11,
      "content": "وقال الذين كفروا للذين امنوا لو كان خيرا ما سبقونا اليه واذ لم يهتدوا به فسيقولون هاذا افك قديم"
    },
    {
      "surah_number": 46,
      "verse_number": 12,
      "content": "ومن قبله كتاب موسىا اماما ورحمه وهاذا كتاب مصدق لسانا عربيا لينذر الذين ظلموا وبشرىا للمحسنين"
    },
    {
      "surah_number": 46,
      "verse_number": 13,
      "content": "ان الذين قالوا ربنا الله ثم استقاموا فلا خوف عليهم ولا هم يحزنون"
    },
    {
      "surah_number": 46,
      "verse_number": 14,
      "content": "أولائك أصحاب الجنه خالدين فيها جزا بما كانوا يعملون"
    },
    {
      "surah_number": 46,
      "verse_number": 15,
      "content": "ووصينا الانسان بوالديه احسانا حملته أمه كرها ووضعته كرها وحمله وفصاله ثلاثون شهرا حتىا اذا بلغ أشده وبلغ أربعين سنه قال رب أوزعني أن أشكر نعمتك التي أنعمت علي وعلىا والدي وأن أعمل صالحا ترضىاه وأصلح لي في ذريتي اني تبت اليك واني من المسلمين"
    },
    {
      "surah_number": 46,
      "verse_number": 16,
      "content": "أولائك الذين نتقبل عنهم أحسن ما عملوا ونتجاوز عن سئاتهم في أصحاب الجنه وعد الصدق الذي كانوا يوعدون"
    },
    {
      "surah_number": 46,
      "verse_number": 17,
      "content": "والذي قال لوالديه أف لكما أتعدانني أن أخرج وقد خلت القرون من قبلي وهما يستغيثان الله ويلك امن ان وعد الله حق فيقول ما هاذا الا أساطير الأولين"
    },
    {
      "surah_number": 46,
      "verse_number": 18,
      "content": "أولائك الذين حق عليهم القول في أمم قد خلت من قبلهم من الجن والانس انهم كانوا خاسرين"
    },
    {
      "surah_number": 46,
      "verse_number": 19,
      "content": "ولكل درجات مما عملوا وليوفيهم أعمالهم وهم لا يظلمون"
    },
    {
      "surah_number": 46,
      "verse_number": 20,
      "content": "ويوم يعرض الذين كفروا على النار أذهبتم طيباتكم في حياتكم الدنيا واستمتعتم بها فاليوم تجزون عذاب الهون بما كنتم تستكبرون في الأرض بغير الحق وبما كنتم تفسقون"
    },
    {
      "surah_number": 46,
      "verse_number": 21,
      "content": "واذكر أخا عاد اذ أنذر قومه بالأحقاف وقد خلت النذر من بين يديه ومن خلفه ألا تعبدوا الا الله اني أخاف عليكم عذاب يوم عظيم"
    },
    {
      "surah_number": 46,
      "verse_number": 22,
      "content": "قالوا أجئتنا لتأفكنا عن الهتنا فأتنا بما تعدنا ان كنت من الصادقين"
    },
    {
      "surah_number": 46,
      "verse_number": 23,
      "content": "قال انما العلم عند الله وأبلغكم ما أرسلت به ولاكني أرىاكم قوما تجهلون"
    },
    {
      "surah_number": 46,
      "verse_number": 24,
      "content": "فلما رأوه عارضا مستقبل أوديتهم قالوا هاذا عارض ممطرنا بل هو ما استعجلتم به ريح فيها عذاب أليم"
    },
    {
      "surah_number": 46,
      "verse_number": 25,
      "content": "تدمر كل شي بأمر ربها فأصبحوا لا يرىا الا مساكنهم كذالك نجزي القوم المجرمين"
    },
    {
      "surah_number": 46,
      "verse_number": 26,
      "content": "ولقد مكناهم فيما ان مكناكم فيه وجعلنا لهم سمعا وأبصارا وأفٔده فما أغنىا عنهم سمعهم ولا أبصارهم ولا أفٔدتهم من شي اذ كانوا يجحدون بٔايات الله وحاق بهم ما كانوا به يستهزون"
    },
    {
      "surah_number": 46,
      "verse_number": 27,
      "content": "ولقد أهلكنا ما حولكم من القرىا وصرفنا الأيات لعلهم يرجعون"
    },
    {
      "surah_number": 46,
      "verse_number": 28,
      "content": "فلولا نصرهم الذين اتخذوا من دون الله قربانا الهه بل ضلوا عنهم وذالك افكهم وما كانوا يفترون"
    },
    {
      "surah_number": 46,
      "verse_number": 29,
      "content": "واذ صرفنا اليك نفرا من الجن يستمعون القران فلما حضروه قالوا أنصتوا فلما قضي ولوا الىا قومهم منذرين"
    },
    {
      "surah_number": 46,
      "verse_number": 30,
      "content": "قالوا ياقومنا انا سمعنا كتابا أنزل من بعد موسىا مصدقا لما بين يديه يهدي الى الحق والىا طريق مستقيم"
    },
    {
      "surah_number": 46,
      "verse_number": 31,
      "content": "ياقومنا أجيبوا داعي الله وامنوا به يغفر لكم من ذنوبكم ويجركم من عذاب أليم"
    },
    {
      "surah_number": 46,
      "verse_number": 32,
      "content": "ومن لا يجب داعي الله فليس بمعجز في الأرض وليس له من دونه أوليا أولائك في ضلال مبين"
    },
    {
      "surah_number": 46,
      "verse_number": 33,
      "content": "أولم يروا أن الله الذي خلق السماوات والأرض ولم يعي بخلقهن بقادر علىا أن يحي الموتىا بلىا انه علىا كل شي قدير"
    },
    {
      "surah_number": 46,
      "verse_number": 34,
      "content": "ويوم يعرض الذين كفروا على النار أليس هاذا بالحق قالوا بلىا وربنا قال فذوقوا العذاب بما كنتم تكفرون"
    },
    {
      "surah_number": 46,
      "verse_number": 35,
      "content": "فاصبر كما صبر أولوا العزم من الرسل ولا تستعجل لهم كأنهم يوم يرون ما يوعدون لم يلبثوا الا ساعه من نهار بلاغ فهل يهلك الا القوم الفاسقون"
    },
    {
      "surah_number": 47,
      "verse_number": 1,
      "content": "الذين كفروا وصدوا عن سبيل الله أضل أعمالهم"
    },
    {
      "surah_number": 47,
      "verse_number": 2,
      "content": "والذين امنوا وعملوا الصالحات وامنوا بما نزل علىا محمد وهو الحق من ربهم كفر عنهم سئاتهم وأصلح بالهم"
    },
    {
      "surah_number": 47,
      "verse_number": 3,
      "content": "ذالك بأن الذين كفروا اتبعوا الباطل وأن الذين امنوا اتبعوا الحق من ربهم كذالك يضرب الله للناس أمثالهم"
    },
    {
      "surah_number": 47,
      "verse_number": 4,
      "content": "فاذا لقيتم الذين كفروا فضرب الرقاب حتىا اذا أثخنتموهم فشدوا الوثاق فاما منا بعد واما فدا حتىا تضع الحرب أوزارها ذالك ولو يشا الله لانتصر منهم ولاكن ليبلوا بعضكم ببعض والذين قتلوا في سبيل الله فلن يضل أعمالهم"
    },
    {
      "surah_number": 47,
      "verse_number": 5,
      "content": "سيهديهم ويصلح بالهم"
    },
    {
      "surah_number": 47,
      "verse_number": 6,
      "content": "ويدخلهم الجنه عرفها لهم"
    },
    {
      "surah_number": 47,
      "verse_number": 7,
      "content": "ياأيها الذين امنوا ان تنصروا الله ينصركم ويثبت أقدامكم"
    },
    {
      "surah_number": 47,
      "verse_number": 8,
      "content": "والذين كفروا فتعسا لهم وأضل أعمالهم"
    },
    {
      "surah_number": 47,
      "verse_number": 9,
      "content": "ذالك بأنهم كرهوا ما أنزل الله فأحبط أعمالهم"
    },
    {
      "surah_number": 47,
      "verse_number": 10,
      "content": "أفلم يسيروا في الأرض فينظروا كيف كان عاقبه الذين من قبلهم دمر الله عليهم وللكافرين أمثالها"
    },
    {
      "surah_number": 47,
      "verse_number": 11,
      "content": "ذالك بأن الله مولى الذين امنوا وأن الكافرين لا مولىا لهم"
    },
    {
      "surah_number": 47,
      "verse_number": 12,
      "content": "ان الله يدخل الذين امنوا وعملوا الصالحات جنات تجري من تحتها الأنهار والذين كفروا يتمتعون ويأكلون كما تأكل الأنعام والنار مثوى لهم"
    },
    {
      "surah_number": 47,
      "verse_number": 13,
      "content": "وكأين من قريه هي أشد قوه من قريتك التي أخرجتك أهلكناهم فلا ناصر لهم"
    },
    {
      "surah_number": 47,
      "verse_number": 14,
      "content": "أفمن كان علىا بينه من ربه كمن زين له سو عمله واتبعوا أهواهم"
    },
    {
      "surah_number": 47,
      "verse_number": 15,
      "content": "مثل الجنه التي وعد المتقون فيها أنهار من ما غير اسن وأنهار من لبن لم يتغير طعمه وأنهار من خمر لذه للشاربين وأنهار من عسل مصفى ولهم فيها من كل الثمرات ومغفره من ربهم كمن هو خالد في النار وسقوا ما حميما فقطع أمعاهم"
    },
    {
      "surah_number": 47,
      "verse_number": 16,
      "content": "ومنهم من يستمع اليك حتىا اذا خرجوا من عندك قالوا للذين أوتوا العلم ماذا قال انفا أولائك الذين طبع الله علىا قلوبهم واتبعوا أهواهم"
    },
    {
      "surah_number": 47,
      "verse_number": 17,
      "content": "والذين اهتدوا زادهم هدى واتىاهم تقوىاهم"
    },
    {
      "surah_number": 47,
      "verse_number": 18,
      "content": "فهل ينظرون الا الساعه أن تأتيهم بغته فقد جا أشراطها فأنىا لهم اذا جاتهم ذكرىاهم"
    },
    {
      "surah_number": 47,
      "verse_number": 19,
      "content": "فاعلم أنه لا الاه الا الله واستغفر لذنبك وللمؤمنين والمؤمنات والله يعلم متقلبكم ومثوىاكم"
    },
    {
      "surah_number": 47,
      "verse_number": 20,
      "content": "ويقول الذين امنوا لولا نزلت سوره فاذا أنزلت سوره محكمه وذكر فيها القتال رأيت الذين في قلوبهم مرض ينظرون اليك نظر المغشي عليه من الموت فأولىا لهم"
    },
    {
      "surah_number": 47,
      "verse_number": 21,
      "content": "طاعه وقول معروف فاذا عزم الأمر فلو صدقوا الله لكان خيرا لهم"
    },
    {
      "surah_number": 47,
      "verse_number": 22,
      "content": "فهل عسيتم ان توليتم أن تفسدوا في الأرض وتقطعوا أرحامكم"
    },
    {
      "surah_number": 47,
      "verse_number": 23,
      "content": "أولائك الذين لعنهم الله فأصمهم وأعمىا أبصارهم"
    },
    {
      "surah_number": 47,
      "verse_number": 24,
      "content": "أفلا يتدبرون القران أم علىا قلوب أقفالها"
    },
    {
      "surah_number": 47,
      "verse_number": 25,
      "content": "ان الذين ارتدوا علىا أدبارهم من بعد ما تبين لهم الهدى الشيطان سول لهم وأملىا لهم"
    },
    {
      "surah_number": 47,
      "verse_number": 26,
      "content": "ذالك بأنهم قالوا للذين كرهوا ما نزل الله سنطيعكم في بعض الأمر والله يعلم اسرارهم"
    },
    {
      "surah_number": 47,
      "verse_number": 27,
      "content": "فكيف اذا توفتهم الملائكه يضربون وجوههم وأدبارهم"
    },
    {
      "surah_number": 47,
      "verse_number": 28,
      "content": "ذالك بأنهم اتبعوا ما أسخط الله وكرهوا رضوانه فأحبط أعمالهم"
    },
    {
      "surah_number": 47,
      "verse_number": 29,
      "content": "أم حسب الذين في قلوبهم مرض أن لن يخرج الله أضغانهم"
    },
    {
      "surah_number": 47,
      "verse_number": 30,
      "content": "ولو نشا لأريناكهم فلعرفتهم بسيماهم ولتعرفنهم في لحن القول والله يعلم أعمالكم"
    },
    {
      "surah_number": 47,
      "verse_number": 31,
      "content": "ولنبلونكم حتىا نعلم المجاهدين منكم والصابرين ونبلوا أخباركم"
    },
    {
      "surah_number": 47,
      "verse_number": 32,
      "content": "ان الذين كفروا وصدوا عن سبيل الله وشاقوا الرسول من بعد ما تبين لهم الهدىا لن يضروا الله شئا وسيحبط أعمالهم"
    },
    {
      "surah_number": 47,
      "verse_number": 33,
      "content": "ياأيها الذين امنوا أطيعوا الله وأطيعوا الرسول ولا تبطلوا أعمالكم"
    },
    {
      "surah_number": 47,
      "verse_number": 34,
      "content": "ان الذين كفروا وصدوا عن سبيل الله ثم ماتوا وهم كفار فلن يغفر الله لهم"
    },
    {
      "surah_number": 47,
      "verse_number": 35,
      "content": "فلا تهنوا وتدعوا الى السلم وأنتم الأعلون والله معكم ولن يتركم أعمالكم"
    },
    {
      "surah_number": 47,
      "verse_number": 36,
      "content": "انما الحيواه الدنيا لعب ولهو وان تؤمنوا وتتقوا يؤتكم أجوركم ولا يسٔلكم أموالكم"
    },
    {
      "surah_number": 47,
      "verse_number": 37,
      "content": "ان يسٔلكموها فيحفكم تبخلوا ويخرج أضغانكم"
    },
    {
      "surah_number": 47,
      "verse_number": 38,
      "content": "هاأنتم هاؤلا تدعون لتنفقوا في سبيل الله فمنكم من يبخل ومن يبخل فانما يبخل عن نفسه والله الغني وأنتم الفقرا وان تتولوا يستبدل قوما غيركم ثم لا يكونوا أمثالكم"
    },
    {
      "surah_number": 48,
      "verse_number": 1,
      "content": "انا فتحنا لك فتحا مبينا"
    },
    {
      "surah_number": 48,
      "verse_number": 2,
      "content": "ليغفر لك الله ما تقدم من ذنبك وما تأخر ويتم نعمته عليك ويهديك صراطا مستقيما"
    },
    {
      "surah_number": 48,
      "verse_number": 3,
      "content": "وينصرك الله نصرا عزيزا"
    },
    {
      "surah_number": 48,
      "verse_number": 4,
      "content": "هو الذي أنزل السكينه في قلوب المؤمنين ليزدادوا ايمانا مع ايمانهم ولله جنود السماوات والأرض وكان الله عليما حكيما"
    },
    {
      "surah_number": 48,
      "verse_number": 5,
      "content": "ليدخل المؤمنين والمؤمنات جنات تجري من تحتها الأنهار خالدين فيها ويكفر عنهم سئاتهم وكان ذالك عند الله فوزا عظيما"
    },
    {
      "surah_number": 48,
      "verse_number": 6,
      "content": "ويعذب المنافقين والمنافقات والمشركين والمشركات الظانين بالله ظن السو عليهم دائره السو وغضب الله عليهم ولعنهم وأعد لهم جهنم وسات مصيرا"
    },
    {
      "surah_number": 48,
      "verse_number": 7,
      "content": "ولله جنود السماوات والأرض وكان الله عزيزا حكيما"
    },
    {
      "surah_number": 48,
      "verse_number": 8,
      "content": "انا أرسلناك شاهدا ومبشرا ونذيرا"
    },
    {
      "surah_number": 48,
      "verse_number": 9,
      "content": "لتؤمنوا بالله ورسوله وتعزروه وتوقروه وتسبحوه بكره وأصيلا"
    },
    {
      "surah_number": 48,
      "verse_number": 10,
      "content": "ان الذين يبايعونك انما يبايعون الله يد الله فوق أيديهم فمن نكث فانما ينكث علىا نفسه ومن أوفىا بما عاهد عليه الله فسيؤتيه أجرا عظيما"
    },
    {
      "surah_number": 48,
      "verse_number": 11,
      "content": "سيقول لك المخلفون من الأعراب شغلتنا أموالنا وأهلونا فاستغفر لنا يقولون بألسنتهم ما ليس في قلوبهم قل فمن يملك لكم من الله شئا ان أراد بكم ضرا أو أراد بكم نفعا بل كان الله بما تعملون خبيرا"
    },
    {
      "surah_number": 48,
      "verse_number": 12,
      "content": "بل ظننتم أن لن ينقلب الرسول والمؤمنون الىا أهليهم أبدا وزين ذالك في قلوبكم وظننتم ظن السو وكنتم قوما بورا"
    },
    {
      "surah_number": 48,
      "verse_number": 13,
      "content": "ومن لم يؤمن بالله ورسوله فانا أعتدنا للكافرين سعيرا"
    },
    {
      "surah_number": 48,
      "verse_number": 14,
      "content": "ولله ملك السماوات والأرض يغفر لمن يشا ويعذب من يشا وكان الله غفورا رحيما"
    },
    {
      "surah_number": 48,
      "verse_number": 15,
      "content": "سيقول المخلفون اذا انطلقتم الىا مغانم لتأخذوها ذرونا نتبعكم يريدون أن يبدلوا كلام الله قل لن تتبعونا كذالكم قال الله من قبل فسيقولون بل تحسدوننا بل كانوا لا يفقهون الا قليلا"
    },
    {
      "surah_number": 48,
      "verse_number": 16,
      "content": "قل للمخلفين من الأعراب ستدعون الىا قوم أولي بأس شديد تقاتلونهم أو يسلمون فان تطيعوا يؤتكم الله أجرا حسنا وان تتولوا كما توليتم من قبل يعذبكم عذابا أليما"
    },
    {
      "surah_number": 48,
      "verse_number": 17,
      "content": "ليس على الأعمىا حرج ولا على الأعرج حرج ولا على المريض حرج ومن يطع الله ورسوله يدخله جنات تجري من تحتها الأنهار ومن يتول يعذبه عذابا أليما"
    },
    {
      "surah_number": 48,
      "verse_number": 18,
      "content": "لقد رضي الله عن المؤمنين اذ يبايعونك تحت الشجره فعلم ما في قلوبهم فأنزل السكينه عليهم وأثابهم فتحا قريبا"
    },
    {
      "surah_number": 48,
      "verse_number": 19,
      "content": "ومغانم كثيره يأخذونها وكان الله عزيزا حكيما"
    },
    {
      "surah_number": 48,
      "verse_number": 20,
      "content": "وعدكم الله مغانم كثيره تأخذونها فعجل لكم هاذه وكف أيدي الناس عنكم ولتكون ايه للمؤمنين ويهديكم صراطا مستقيما"
    },
    {
      "surah_number": 48,
      "verse_number": 21,
      "content": "وأخرىا لم تقدروا عليها قد أحاط الله بها وكان الله علىا كل شي قديرا"
    },
    {
      "surah_number": 48,
      "verse_number": 22,
      "content": "ولو قاتلكم الذين كفروا لولوا الأدبار ثم لا يجدون وليا ولا نصيرا"
    },
    {
      "surah_number": 48,
      "verse_number": 23,
      "content": "سنه الله التي قد خلت من قبل ولن تجد لسنه الله تبديلا"
    },
    {
      "surah_number": 48,
      "verse_number": 24,
      "content": "وهو الذي كف أيديهم عنكم وأيديكم عنهم ببطن مكه من بعد أن أظفركم عليهم وكان الله بما تعملون بصيرا"
    },
    {
      "surah_number": 48,
      "verse_number": 25,
      "content": "هم الذين كفروا وصدوكم عن المسجد الحرام والهدي معكوفا أن يبلغ محله ولولا رجال مؤمنون ونسا مؤمنات لم تعلموهم أن تطٔوهم فتصيبكم منهم معره بغير علم ليدخل الله في رحمته من يشا لو تزيلوا لعذبنا الذين كفروا منهم عذابا أليما"
    },
    {
      "surah_number": 48,
      "verse_number": 26,
      "content": "اذ جعل الذين كفروا في قلوبهم الحميه حميه الجاهليه فأنزل الله سكينته علىا رسوله وعلى المؤمنين وألزمهم كلمه التقوىا وكانوا أحق بها وأهلها وكان الله بكل شي عليما"
    },
    {
      "surah_number": 48,
      "verse_number": 27,
      "content": "لقد صدق الله رسوله الريا بالحق لتدخلن المسجد الحرام ان شا الله امنين محلقين روسكم ومقصرين لا تخافون فعلم ما لم تعلموا فجعل من دون ذالك فتحا قريبا"
    },
    {
      "surah_number": 48,
      "verse_number": 28,
      "content": "هو الذي أرسل رسوله بالهدىا ودين الحق ليظهره على الدين كله وكفىا بالله شهيدا"
    },
    {
      "surah_number": 48,
      "verse_number": 29,
      "content": "محمد رسول الله والذين معه أشدا على الكفار رحما بينهم ترىاهم ركعا سجدا يبتغون فضلا من الله ورضوانا سيماهم في وجوههم من أثر السجود ذالك مثلهم في التورىاه ومثلهم في الانجيل كزرع أخرج شطٔه فٔازره فاستغلظ فاستوىا علىا سوقه يعجب الزراع ليغيظ بهم الكفار وعد الله الذين امنوا وعملوا الصالحات منهم مغفره وأجرا عظيما"
    },
    {
      "surah_number": 49,
      "verse_number": 1,
      "content": "ياأيها الذين امنوا لا تقدموا بين يدي الله ورسوله واتقوا الله ان الله سميع عليم"
    },
    {
      "surah_number": 49,
      "verse_number": 2,
      "content": "ياأيها الذين امنوا لا ترفعوا أصواتكم فوق صوت النبي ولا تجهروا له بالقول كجهر بعضكم لبعض أن تحبط أعمالكم وأنتم لا تشعرون"
    },
    {
      "surah_number": 49,
      "verse_number": 3,
      "content": "ان الذين يغضون أصواتهم عند رسول الله أولائك الذين امتحن الله قلوبهم للتقوىا لهم مغفره وأجر عظيم"
    },
    {
      "surah_number": 49,
      "verse_number": 4,
      "content": "ان الذين ينادونك من ورا الحجرات أكثرهم لا يعقلون"
    },
    {
      "surah_number": 49,
      "verse_number": 5,
      "content": "ولو أنهم صبروا حتىا تخرج اليهم لكان خيرا لهم والله غفور رحيم"
    },
    {
      "surah_number": 49,
      "verse_number": 6,
      "content": "ياأيها الذين امنوا ان جاكم فاسق بنبا فتبينوا أن تصيبوا قوما بجهاله فتصبحوا علىا ما فعلتم نادمين"
    },
    {
      "surah_number": 49,
      "verse_number": 7,
      "content": "واعلموا أن فيكم رسول الله لو يطيعكم في كثير من الأمر لعنتم ولاكن الله حبب اليكم الايمان وزينه في قلوبكم وكره اليكم الكفر والفسوق والعصيان أولائك هم الراشدون"
    },
    {
      "surah_number": 49,
      "verse_number": 8,
      "content": "فضلا من الله ونعمه والله عليم حكيم"
    },
    {
      "surah_number": 49,
      "verse_number": 9,
      "content": "وان طائفتان من المؤمنين اقتتلوا فأصلحوا بينهما فان بغت احدىاهما على الأخرىا فقاتلوا التي تبغي حتىا تفي الىا أمر الله فان فات فأصلحوا بينهما بالعدل وأقسطوا ان الله يحب المقسطين"
    },
    {
      "surah_number": 49,
      "verse_number": 10,
      "content": "انما المؤمنون اخوه فأصلحوا بين أخويكم واتقوا الله لعلكم ترحمون"
    },
    {
      "surah_number": 49,
      "verse_number": 11,
      "content": "ياأيها الذين امنوا لا يسخر قوم من قوم عسىا أن يكونوا خيرا منهم ولا نسا من نسا عسىا أن يكن خيرا منهن ولا تلمزوا أنفسكم ولا تنابزوا بالألقاب بئس الاسم الفسوق بعد الايمان ومن لم يتب فأولائك هم الظالمون"
    },
    {
      "surah_number": 49,
      "verse_number": 12,
      "content": "ياأيها الذين امنوا اجتنبوا كثيرا من الظن ان بعض الظن اثم ولا تجسسوا ولا يغتب بعضكم بعضا أيحب أحدكم أن يأكل لحم أخيه ميتا فكرهتموه واتقوا الله ان الله تواب رحيم"
    },
    {
      "surah_number": 49,
      "verse_number": 13,
      "content": "ياأيها الناس انا خلقناكم من ذكر وأنثىا وجعلناكم شعوبا وقبائل لتعارفوا ان أكرمكم عند الله أتقىاكم ان الله عليم خبير"
    },
    {
      "surah_number": 49,
      "verse_number": 14,
      "content": "قالت الأعراب امنا قل لم تؤمنوا ولاكن قولوا أسلمنا ولما يدخل الايمان في قلوبكم وان تطيعوا الله ورسوله لا يلتكم من أعمالكم شئا ان الله غفور رحيم"
    },
    {
      "surah_number": 49,
      "verse_number": 15,
      "content": "انما المؤمنون الذين امنوا بالله ورسوله ثم لم يرتابوا وجاهدوا بأموالهم وأنفسهم في سبيل الله أولائك هم الصادقون"
    },
    {
      "surah_number": 49,
      "verse_number": 16,
      "content": "قل أتعلمون الله بدينكم والله يعلم ما في السماوات وما في الأرض والله بكل شي عليم"
    },
    {
      "surah_number": 49,
      "verse_number": 17,
      "content": "يمنون عليك أن أسلموا قل لا تمنوا علي اسلامكم بل الله يمن عليكم أن هدىاكم للايمان ان كنتم صادقين"
    },
    {
      "surah_number": 49,
      "verse_number": 18,
      "content": "ان الله يعلم غيب السماوات والأرض والله بصير بما تعملون"
    },
    {
      "surah_number": 50,
      "verse_number": 1,
      "content": "ق والقران المجيد"
    },
    {
      "surah_number": 50,
      "verse_number": 2,
      "content": "بل عجبوا أن جاهم منذر منهم فقال الكافرون هاذا شي عجيب"
    },
    {
      "surah_number": 50,
      "verse_number": 3,
      "content": "أذا متنا وكنا ترابا ذالك رجع بعيد"
    },
    {
      "surah_number": 50,
      "verse_number": 4,
      "content": "قد علمنا ما تنقص الأرض منهم وعندنا كتاب حفيظ"
    },
    {
      "surah_number": 50,
      "verse_number": 5,
      "content": "بل كذبوا بالحق لما جاهم فهم في أمر مريج"
    },
    {
      "surah_number": 50,
      "verse_number": 6,
      "content": "أفلم ينظروا الى السما فوقهم كيف بنيناها وزيناها وما لها من فروج"
    },
    {
      "surah_number": 50,
      "verse_number": 7,
      "content": "والأرض مددناها وألقينا فيها رواسي وأنبتنا فيها من كل زوج بهيج"
    },
    {
      "surah_number": 50,
      "verse_number": 8,
      "content": "تبصره وذكرىا لكل عبد منيب"
    },
    {
      "surah_number": 50,
      "verse_number": 9,
      "content": "ونزلنا من السما ما مباركا فأنبتنا به جنات وحب الحصيد"
    },
    {
      "surah_number": 50,
      "verse_number": 10,
      "content": "والنخل باسقات لها طلع نضيد"
    },
    {
      "surah_number": 50,
      "verse_number": 11,
      "content": "رزقا للعباد وأحيينا به بلده ميتا كذالك الخروج"
    },
    {
      "surah_number": 50,
      "verse_number": 12,
      "content": "كذبت قبلهم قوم نوح وأصحاب الرس وثمود"
    },
    {
      "surah_number": 50,
      "verse_number": 13,
      "content": "وعاد وفرعون واخوان لوط"
    },
    {
      "surah_number": 50,
      "verse_number": 14,
      "content": "وأصحاب الأيكه وقوم تبع كل كذب الرسل فحق وعيد"
    },
    {
      "surah_number": 50,
      "verse_number": 15,
      "content": "أفعيينا بالخلق الأول بل هم في لبس من خلق جديد"
    },
    {
      "surah_number": 50,
      "verse_number": 16,
      "content": "ولقد خلقنا الانسان ونعلم ما توسوس به نفسه ونحن أقرب اليه من حبل الوريد"
    },
    {
      "surah_number": 50,
      "verse_number": 17,
      "content": "اذ يتلقى المتلقيان عن اليمين وعن الشمال قعيد"
    },
    {
      "surah_number": 50,
      "verse_number": 18,
      "content": "ما يلفظ من قول الا لديه رقيب عتيد"
    },
    {
      "surah_number": 50,
      "verse_number": 19,
      "content": "وجات سكره الموت بالحق ذالك ما كنت منه تحيد"
    },
    {
      "surah_number": 50,
      "verse_number": 20,
      "content": "ونفخ في الصور ذالك يوم الوعيد"
    },
    {
      "surah_number": 50,
      "verse_number": 21,
      "content": "وجات كل نفس معها سائق وشهيد"
    },
    {
      "surah_number": 50,
      "verse_number": 22,
      "content": "لقد كنت في غفله من هاذا فكشفنا عنك غطاك فبصرك اليوم حديد"
    },
    {
      "surah_number": 50,
      "verse_number": 23,
      "content": "وقال قرينه هاذا ما لدي عتيد"
    },
    {
      "surah_number": 50,
      "verse_number": 24,
      "content": "ألقيا في جهنم كل كفار عنيد"
    },
    {
      "surah_number": 50,
      "verse_number": 25,
      "content": "مناع للخير معتد مريب"
    },
    {
      "surah_number": 50,
      "verse_number": 26,
      "content": "الذي جعل مع الله الاها اخر فألقياه في العذاب الشديد"
    },
    {
      "surah_number": 50,
      "verse_number": 27,
      "content": "قال قرينه ربنا ما أطغيته ولاكن كان في ضلال بعيد"
    },
    {
      "surah_number": 50,
      "verse_number": 28,
      "content": "قال لا تختصموا لدي وقد قدمت اليكم بالوعيد"
    },
    {
      "surah_number": 50,
      "verse_number": 29,
      "content": "ما يبدل القول لدي وما أنا بظلام للعبيد"
    },
    {
      "surah_number": 50,
      "verse_number": 30,
      "content": "يوم نقول لجهنم هل امتلأت وتقول هل من مزيد"
    },
    {
      "surah_number": 50,
      "verse_number": 31,
      "content": "وأزلفت الجنه للمتقين غير بعيد"
    },
    {
      "surah_number": 50,
      "verse_number": 32,
      "content": "هاذا ما توعدون لكل أواب حفيظ"
    },
    {
      "surah_number": 50,
      "verse_number": 33,
      "content": "من خشي الرحمان بالغيب وجا بقلب منيب"
    },
    {
      "surah_number": 50,
      "verse_number": 34,
      "content": "ادخلوها بسلام ذالك يوم الخلود"
    },
    {
      "surah_number": 50,
      "verse_number": 35,
      "content": "لهم ما يشاون فيها ولدينا مزيد"
    },
    {
      "surah_number": 50,
      "verse_number": 36,
      "content": "وكم أهلكنا قبلهم من قرن هم أشد منهم بطشا فنقبوا في البلاد هل من محيص"
    },
    {
      "surah_number": 50,
      "verse_number": 37,
      "content": "ان في ذالك لذكرىا لمن كان له قلب أو ألقى السمع وهو شهيد"
    },
    {
      "surah_number": 50,
      "verse_number": 38,
      "content": "ولقد خلقنا السماوات والأرض وما بينهما في سته أيام وما مسنا من لغوب"
    },
    {
      "surah_number": 50,
      "verse_number": 39,
      "content": "فاصبر علىا ما يقولون وسبح بحمد ربك قبل طلوع الشمس وقبل الغروب"
    },
    {
      "surah_number": 50,
      "verse_number": 40,
      "content": "ومن اليل فسبحه وأدبار السجود"
    },
    {
      "surah_number": 50,
      "verse_number": 41,
      "content": "واستمع يوم يناد المناد من مكان قريب"
    },
    {
      "surah_number": 50,
      "verse_number": 42,
      "content": "يوم يسمعون الصيحه بالحق ذالك يوم الخروج"
    },
    {
      "surah_number": 50,
      "verse_number": 43,
      "content": "انا نحن نحي ونميت والينا المصير"
    },
    {
      "surah_number": 50,
      "verse_number": 44,
      "content": "يوم تشقق الأرض عنهم سراعا ذالك حشر علينا يسير"
    },
    {
      "surah_number": 50,
      "verse_number": 45,
      "content": "نحن أعلم بما يقولون وما أنت عليهم بجبار فذكر بالقران من يخاف وعيد"
    },
    {
      "surah_number": 51,
      "verse_number": 1,
      "content": "والذاريات ذروا"
    },
    {
      "surah_number": 51,
      "verse_number": 2,
      "content": "فالحاملات وقرا"
    },
    {
      "surah_number": 51,
      "verse_number": 3,
      "content": "فالجاريات يسرا"
    },
    {
      "surah_number": 51,
      "verse_number": 4,
      "content": "فالمقسمات أمرا"
    },
    {
      "surah_number": 51,
      "verse_number": 5,
      "content": "انما توعدون لصادق"
    },
    {
      "surah_number": 51,
      "verse_number": 6,
      "content": "وان الدين لواقع"
    },
    {
      "surah_number": 51,
      "verse_number": 7,
      "content": "والسما ذات الحبك"
    },
    {
      "surah_number": 51,
      "verse_number": 8,
      "content": "انكم لفي قول مختلف"
    },
    {
      "surah_number": 51,
      "verse_number": 9,
      "content": "يؤفك عنه من أفك"
    },
    {
      "surah_number": 51,
      "verse_number": 10,
      "content": "قتل الخراصون"
    },
    {
      "surah_number": 51,
      "verse_number": 11,
      "content": "الذين هم في غمره ساهون"
    },
    {
      "surah_number": 51,
      "verse_number": 12,
      "content": "يسٔلون أيان يوم الدين"
    },
    {
      "surah_number": 51,
      "verse_number": 13,
      "content": "يوم هم على النار يفتنون"
    },
    {
      "surah_number": 51,
      "verse_number": 14,
      "content": "ذوقوا فتنتكم هاذا الذي كنتم به تستعجلون"
    },
    {
      "surah_number": 51,
      "verse_number": 15,
      "content": "ان المتقين في جنات وعيون"
    },
    {
      "surah_number": 51,
      "verse_number": 16,
      "content": "اخذين ما اتىاهم ربهم انهم كانوا قبل ذالك محسنين"
    },
    {
      "surah_number": 51,
      "verse_number": 17,
      "content": "كانوا قليلا من اليل ما يهجعون"
    },
    {
      "surah_number": 51,
      "verse_number": 18,
      "content": "وبالأسحار هم يستغفرون"
    },
    {
      "surah_number": 51,
      "verse_number": 19,
      "content": "وفي أموالهم حق للسائل والمحروم"
    },
    {
      "surah_number": 51,
      "verse_number": 20,
      "content": "وفي الأرض ايات للموقنين"
    },
    {
      "surah_number": 51,
      "verse_number": 21,
      "content": "وفي أنفسكم أفلا تبصرون"
    },
    {
      "surah_number": 51,
      "verse_number": 22,
      "content": "وفي السما رزقكم وما توعدون"
    },
    {
      "surah_number": 51,
      "verse_number": 23,
      "content": "فورب السما والأرض انه لحق مثل ما أنكم تنطقون"
    },
    {
      "surah_number": 51,
      "verse_number": 24,
      "content": "هل أتىاك حديث ضيف ابراهيم المكرمين"
    },
    {
      "surah_number": 51,
      "verse_number": 25,
      "content": "اذ دخلوا عليه فقالوا سلاما قال سلام قوم منكرون"
    },
    {
      "surah_number": 51,
      "verse_number": 26,
      "content": "فراغ الىا أهله فجا بعجل سمين"
    },
    {
      "surah_number": 51,
      "verse_number": 27,
      "content": "فقربه اليهم قال ألا تأكلون"
    },
    {
      "surah_number": 51,
      "verse_number": 28,
      "content": "فأوجس منهم خيفه قالوا لا تخف وبشروه بغلام عليم"
    },
    {
      "surah_number": 51,
      "verse_number": 29,
      "content": "فأقبلت امرأته في صره فصكت وجهها وقالت عجوز عقيم"
    },
    {
      "surah_number": 51,
      "verse_number": 30,
      "content": "قالوا كذالك قال ربك انه هو الحكيم العليم"
    },
    {
      "surah_number": 51,
      "verse_number": 31,
      "content": "قال فما خطبكم أيها المرسلون"
    },
    {
      "surah_number": 51,
      "verse_number": 32,
      "content": "قالوا انا أرسلنا الىا قوم مجرمين"
    },
    {
      "surah_number": 51,
      "verse_number": 33,
      "content": "لنرسل عليهم حجاره من طين"
    },
    {
      "surah_number": 51,
      "verse_number": 34,
      "content": "مسومه عند ربك للمسرفين"
    },
    {
      "surah_number": 51,
      "verse_number": 35,
      "content": "فأخرجنا من كان فيها من المؤمنين"
    },
    {
      "surah_number": 51,
      "verse_number": 36,
      "content": "فما وجدنا فيها غير بيت من المسلمين"
    },
    {
      "surah_number": 51,
      "verse_number": 37,
      "content": "وتركنا فيها ايه للذين يخافون العذاب الأليم"
    },
    {
      "surah_number": 51,
      "verse_number": 38,
      "content": "وفي موسىا اذ أرسلناه الىا فرعون بسلطان مبين"
    },
    {
      "surah_number": 51,
      "verse_number": 39,
      "content": "فتولىا بركنه وقال ساحر أو مجنون"
    },
    {
      "surah_number": 51,
      "verse_number": 40,
      "content": "فأخذناه وجنوده فنبذناهم في اليم وهو مليم"
    },
    {
      "surah_number": 51,
      "verse_number": 41,
      "content": "وفي عاد اذ أرسلنا عليهم الريح العقيم"
    },
    {
      "surah_number": 51,
      "verse_number": 42,
      "content": "ما تذر من شي أتت عليه الا جعلته كالرميم"
    },
    {
      "surah_number": 51,
      "verse_number": 43,
      "content": "وفي ثمود اذ قيل لهم تمتعوا حتىا حين"
    },
    {
      "surah_number": 51,
      "verse_number": 44,
      "content": "فعتوا عن أمر ربهم فأخذتهم الصاعقه وهم ينظرون"
    },
    {
      "surah_number": 51,
      "verse_number": 45,
      "content": "فما استطاعوا من قيام وما كانوا منتصرين"
    },
    {
      "surah_number": 51,
      "verse_number": 46,
      "content": "وقوم نوح من قبل انهم كانوا قوما فاسقين"
    },
    {
      "surah_number": 51,
      "verse_number": 47,
      "content": "والسما بنيناها بأييد وانا لموسعون"
    },
    {
      "surah_number": 51,
      "verse_number": 48,
      "content": "والأرض فرشناها فنعم الماهدون"
    },
    {
      "surah_number": 51,
      "verse_number": 49,
      "content": "ومن كل شي خلقنا زوجين لعلكم تذكرون"
    },
    {
      "surah_number": 51,
      "verse_number": 50,
      "content": "ففروا الى الله اني لكم منه نذير مبين"
    },
    {
      "surah_number": 51,
      "verse_number": 51,
      "content": "ولا تجعلوا مع الله الاها اخر اني لكم منه نذير مبين"
    },
    {
      "surah_number": 51,
      "verse_number": 52,
      "content": "كذالك ما أتى الذين من قبلهم من رسول الا قالوا ساحر أو مجنون"
    },
    {
      "surah_number": 51,
      "verse_number": 53,
      "content": "أتواصوا به بل هم قوم طاغون"
    },
    {
      "surah_number": 51,
      "verse_number": 54,
      "content": "فتول عنهم فما أنت بملوم"
    },
    {
      "surah_number": 51,
      "verse_number": 55,
      "content": "وذكر فان الذكرىا تنفع المؤمنين"
    },
    {
      "surah_number": 51,
      "verse_number": 56,
      "content": "وما خلقت الجن والانس الا ليعبدون"
    },
    {
      "surah_number": 51,
      "verse_number": 57,
      "content": "ما أريد منهم من رزق وما أريد أن يطعمون"
    },
    {
      "surah_number": 51,
      "verse_number": 58,
      "content": "ان الله هو الرزاق ذو القوه المتين"
    },
    {
      "surah_number": 51,
      "verse_number": 59,
      "content": "فان للذين ظلموا ذنوبا مثل ذنوب أصحابهم فلا يستعجلون"
    },
    {
      "surah_number": 51,
      "verse_number": 60,
      "content": "فويل للذين كفروا من يومهم الذي يوعدون"
    },
    {
      "surah_number": 52,
      "verse_number": 1,
      "content": "والطور"
    },
    {
      "surah_number": 52,
      "verse_number": 2,
      "content": "وكتاب مسطور"
    },
    {
      "surah_number": 52,
      "verse_number": 3,
      "content": "في رق منشور"
    },
    {
      "surah_number": 52,
      "verse_number": 4,
      "content": "والبيت المعمور"
    },
    {
      "surah_number": 52,
      "verse_number": 5,
      "content": "والسقف المرفوع"
    },
    {
      "surah_number": 52,
      "verse_number": 6,
      "content": "والبحر المسجور"
    },
    {
      "surah_number": 52,
      "verse_number": 7,
      "content": "ان عذاب ربك لواقع"
    },
    {
      "surah_number": 52,
      "verse_number": 8,
      "content": "ما له من دافع"
    },
    {
      "surah_number": 52,
      "verse_number": 9,
      "content": "يوم تمور السما مورا"
    },
    {
      "surah_number": 52,
      "verse_number": 10,
      "content": "وتسير الجبال سيرا"
    },
    {
      "surah_number": 52,
      "verse_number": 11,
      "content": "فويل يومئذ للمكذبين"
    },
    {
      "surah_number": 52,
      "verse_number": 12,
      "content": "الذين هم في خوض يلعبون"
    },
    {
      "surah_number": 52,
      "verse_number": 13,
      "content": "يوم يدعون الىا نار جهنم دعا"
    },
    {
      "surah_number": 52,
      "verse_number": 14,
      "content": "هاذه النار التي كنتم بها تكذبون"
    },
    {
      "surah_number": 52,
      "verse_number": 15,
      "content": "أفسحر هاذا أم أنتم لا تبصرون"
    },
    {
      "surah_number": 52,
      "verse_number": 16,
      "content": "اصلوها فاصبروا أو لا تصبروا سوا عليكم انما تجزون ما كنتم تعملون"
    },
    {
      "surah_number": 52,
      "verse_number": 17,
      "content": "ان المتقين في جنات ونعيم"
    },
    {
      "surah_number": 52,
      "verse_number": 18,
      "content": "فاكهين بما اتىاهم ربهم ووقىاهم ربهم عذاب الجحيم"
    },
    {
      "surah_number": 52,
      "verse_number": 19,
      "content": "كلوا واشربوا هنئا بما كنتم تعملون"
    },
    {
      "surah_number": 52,
      "verse_number": 20,
      "content": "متكٔين علىا سرر مصفوفه وزوجناهم بحور عين"
    },
    {
      "surah_number": 52,
      "verse_number": 21,
      "content": "والذين امنوا واتبعتهم ذريتهم بايمان ألحقنا بهم ذريتهم وما ألتناهم من عملهم من شي كل امري بما كسب رهين"
    },
    {
      "surah_number": 52,
      "verse_number": 22,
      "content": "وأمددناهم بفاكهه ولحم مما يشتهون"
    },
    {
      "surah_number": 52,
      "verse_number": 23,
      "content": "يتنازعون فيها كأسا لا لغو فيها ولا تأثيم"
    },
    {
      "surah_number": 52,
      "verse_number": 24,
      "content": "ويطوف عليهم غلمان لهم كأنهم لؤلؤ مكنون"
    },
    {
      "surah_number": 52,
      "verse_number": 25,
      "content": "وأقبل بعضهم علىا بعض يتسالون"
    },
    {
      "surah_number": 52,
      "verse_number": 26,
      "content": "قالوا انا كنا قبل في أهلنا مشفقين"
    },
    {
      "surah_number": 52,
      "verse_number": 27,
      "content": "فمن الله علينا ووقىانا عذاب السموم"
    },
    {
      "surah_number": 52,
      "verse_number": 28,
      "content": "انا كنا من قبل ندعوه انه هو البر الرحيم"
    },
    {
      "surah_number": 52,
      "verse_number": 29,
      "content": "فذكر فما أنت بنعمت ربك بكاهن ولا مجنون"
    },
    {
      "surah_number": 52,
      "verse_number": 30,
      "content": "أم يقولون شاعر نتربص به ريب المنون"
    },
    {
      "surah_number": 52,
      "verse_number": 31,
      "content": "قل تربصوا فاني معكم من المتربصين"
    },
    {
      "surah_number": 52,
      "verse_number": 32,
      "content": "أم تأمرهم أحلامهم بهاذا أم هم قوم طاغون"
    },
    {
      "surah_number": 52,
      "verse_number": 33,
      "content": "أم يقولون تقوله بل لا يؤمنون"
    },
    {
      "surah_number": 52,
      "verse_number": 34,
      "content": "فليأتوا بحديث مثله ان كانوا صادقين"
    },
    {
      "surah_number": 52,
      "verse_number": 35,
      "content": "أم خلقوا من غير شي أم هم الخالقون"
    },
    {
      "surah_number": 52,
      "verse_number": 36,
      "content": "أم خلقوا السماوات والأرض بل لا يوقنون"
    },
    {
      "surah_number": 52,
      "verse_number": 37,
      "content": "أم عندهم خزائن ربك أم هم المصيطرون"
    },
    {
      "surah_number": 52,
      "verse_number": 38,
      "content": "أم لهم سلم يستمعون فيه فليأت مستمعهم بسلطان مبين"
    },
    {
      "surah_number": 52,
      "verse_number": 39,
      "content": "أم له البنات ولكم البنون"
    },
    {
      "surah_number": 52,
      "verse_number": 40,
      "content": "أم تسٔلهم أجرا فهم من مغرم مثقلون"
    },
    {
      "surah_number": 52,
      "verse_number": 41,
      "content": "أم عندهم الغيب فهم يكتبون"
    },
    {
      "surah_number": 52,
      "verse_number": 42,
      "content": "أم يريدون كيدا فالذين كفروا هم المكيدون"
    },
    {
      "surah_number": 52,
      "verse_number": 43,
      "content": "أم لهم الاه غير الله سبحان الله عما يشركون"
    },
    {
      "surah_number": 52,
      "verse_number": 44,
      "content": "وان يروا كسفا من السما ساقطا يقولوا سحاب مركوم"
    },
    {
      "surah_number": 52,
      "verse_number": 45,
      "content": "فذرهم حتىا يلاقوا يومهم الذي فيه يصعقون"
    },
    {
      "surah_number": 52,
      "verse_number": 46,
      "content": "يوم لا يغني عنهم كيدهم شئا ولا هم ينصرون"
    },
    {
      "surah_number": 52,
      "verse_number": 47,
      "content": "وان للذين ظلموا عذابا دون ذالك ولاكن أكثرهم لا يعلمون"
    },
    {
      "surah_number": 52,
      "verse_number": 48,
      "content": "واصبر لحكم ربك فانك بأعيننا وسبح بحمد ربك حين تقوم"
    },
    {
      "surah_number": 52,
      "verse_number": 49,
      "content": "ومن اليل فسبحه وادبار النجوم"
    },
    {
      "surah_number": 53,
      "verse_number": 1,
      "content": "والنجم اذا هوىا"
    },
    {
      "surah_number": 53,
      "verse_number": 2,
      "content": "ما ضل صاحبكم وما غوىا"
    },
    {
      "surah_number": 53,
      "verse_number": 3,
      "content": "وما ينطق عن الهوىا"
    },
    {
      "surah_number": 53,
      "verse_number": 4,
      "content": "ان هو الا وحي يوحىا"
    },
    {
      "surah_number": 53,
      "verse_number": 5,
      "content": "علمه شديد القوىا"
    },
    {
      "surah_number": 53,
      "verse_number": 6,
      "content": "ذو مره فاستوىا"
    },
    {
      "surah_number": 53,
      "verse_number": 7,
      "content": "وهو بالأفق الأعلىا"
    },
    {
      "surah_number": 53,
      "verse_number": 8,
      "content": "ثم دنا فتدلىا"
    },
    {
      "surah_number": 53,
      "verse_number": 9,
      "content": "فكان قاب قوسين أو أدنىا"
    },
    {
      "surah_number": 53,
      "verse_number": 10,
      "content": "فأوحىا الىا عبده ما أوحىا"
    },
    {
      "surah_number": 53,
      "verse_number": 11,
      "content": "ما كذب الفؤاد ما رأىا"
    },
    {
      "surah_number": 53,
      "verse_number": 12,
      "content": "أفتمارونه علىا ما يرىا"
    },
    {
      "surah_number": 53,
      "verse_number": 13,
      "content": "ولقد راه نزله أخرىا"
    },
    {
      "surah_number": 53,
      "verse_number": 14,
      "content": "عند سدره المنتهىا"
    },
    {
      "surah_number": 53,
      "verse_number": 15,
      "content": "عندها جنه المأوىا"
    },
    {
      "surah_number": 53,
      "verse_number": 16,
      "content": "اذ يغشى السدره ما يغشىا"
    },
    {
      "surah_number": 53,
      "verse_number": 17,
      "content": "ما زاغ البصر وما طغىا"
    },
    {
      "surah_number": 53,
      "verse_number": 18,
      "content": "لقد رأىا من ايات ربه الكبرىا"
    },
    {
      "surah_number": 53,
      "verse_number": 19,
      "content": "أفريتم اللات والعزىا"
    },
    {
      "surah_number": 53,
      "verse_number": 20,
      "content": "ومنواه الثالثه الأخرىا"
    },
    {
      "surah_number": 53,
      "verse_number": 21,
      "content": "ألكم الذكر وله الأنثىا"
    },
    {
      "surah_number": 53,
      "verse_number": 22,
      "content": "تلك اذا قسمه ضيزىا"
    },
    {
      "surah_number": 53,
      "verse_number": 23,
      "content": "ان هي الا أسما سميتموها أنتم واباؤكم ما أنزل الله بها من سلطان ان يتبعون الا الظن وما تهوى الأنفس ولقد جاهم من ربهم الهدىا"
    },
    {
      "surah_number": 53,
      "verse_number": 24,
      "content": "أم للانسان ما تمنىا"
    },
    {
      "surah_number": 53,
      "verse_number": 25,
      "content": "فلله الأخره والأولىا"
    },
    {
      "surah_number": 53,
      "verse_number": 26,
      "content": "وكم من ملك في السماوات لا تغني شفاعتهم شئا الا من بعد أن يأذن الله لمن يشا ويرضىا"
    },
    {
      "surah_number": 53,
      "verse_number": 27,
      "content": "ان الذين لا يؤمنون بالأخره ليسمون الملائكه تسميه الأنثىا"
    },
    {
      "surah_number": 53,
      "verse_number": 28,
      "content": "وما لهم به من علم ان يتبعون الا الظن وان الظن لا يغني من الحق شئا"
    },
    {
      "surah_number": 53,
      "verse_number": 29,
      "content": "فأعرض عن من تولىا عن ذكرنا ولم يرد الا الحيواه الدنيا"
    },
    {
      "surah_number": 53,
      "verse_number": 30,
      "content": "ذالك مبلغهم من العلم ان ربك هو أعلم بمن ضل عن سبيله وهو أعلم بمن اهتدىا"
    },
    {
      "surah_number": 53,
      "verse_number": 31,
      "content": "ولله ما في السماوات وما في الأرض ليجزي الذين أسأوا بما عملوا ويجزي الذين أحسنوا بالحسنى"
    },
    {
      "surah_number": 53,
      "verse_number": 32,
      "content": "الذين يجتنبون كبائر الاثم والفواحش الا اللمم ان ربك واسع المغفره هو أعلم بكم اذ أنشأكم من الأرض واذ أنتم أجنه في بطون أمهاتكم فلا تزكوا أنفسكم هو أعلم بمن اتقىا"
    },
    {
      "surah_number": 53,
      "verse_number": 33,
      "content": "أفريت الذي تولىا"
    },
    {
      "surah_number": 53,
      "verse_number": 34,
      "content": "وأعطىا قليلا وأكدىا"
    },
    {
      "surah_number": 53,
      "verse_number": 35,
      "content": "أعنده علم الغيب فهو يرىا"
    },
    {
      "surah_number": 53,
      "verse_number": 36,
      "content": "أم لم ينبأ بما في صحف موسىا"
    },
    {
      "surah_number": 53,
      "verse_number": 37,
      "content": "وابراهيم الذي وفىا"
    },
    {
      "surah_number": 53,
      "verse_number": 38,
      "content": "ألا تزر وازره وزر أخرىا"
    },
    {
      "surah_number": 53,
      "verse_number": 39,
      "content": "وأن ليس للانسان الا ما سعىا"
    },
    {
      "surah_number": 53,
      "verse_number": 40,
      "content": "وأن سعيه سوف يرىا"
    },
    {
      "surah_number": 53,
      "verse_number": 41,
      "content": "ثم يجزىاه الجزا الأوفىا"
    },
    {
      "surah_number": 53,
      "verse_number": 42,
      "content": "وأن الىا ربك المنتهىا"
    },
    {
      "surah_number": 53,
      "verse_number": 43,
      "content": "وأنه هو أضحك وأبكىا"
    },
    {
      "surah_number": 53,
      "verse_number": 44,
      "content": "وأنه هو أمات وأحيا"
    },
    {
      "surah_number": 53,
      "verse_number": 45,
      "content": "وأنه خلق الزوجين الذكر والأنثىا"
    },
    {
      "surah_number": 53,
      "verse_number": 46,
      "content": "من نطفه اذا تمنىا"
    },
    {
      "surah_number": 53,
      "verse_number": 47,
      "content": "وأن عليه النشأه الأخرىا"
    },
    {
      "surah_number": 53,
      "verse_number": 48,
      "content": "وأنه هو أغنىا وأقنىا"
    },
    {
      "surah_number": 53,
      "verse_number": 49,
      "content": "وأنه هو رب الشعرىا"
    },
    {
      "surah_number": 53,
      "verse_number": 50,
      "content": "وأنه أهلك عادا الأولىا"
    },
    {
      "surah_number": 53,
      "verse_number": 51,
      "content": "وثمودا فما أبقىا"
    },
    {
      "surah_number": 53,
      "verse_number": 52,
      "content": "وقوم نوح من قبل انهم كانوا هم أظلم وأطغىا"
    },
    {
      "surah_number": 53,
      "verse_number": 53,
      "content": "والمؤتفكه أهوىا"
    },
    {
      "surah_number": 53,
      "verse_number": 54,
      "content": "فغشىاها ما غشىا"
    },
    {
      "surah_number": 53,
      "verse_number": 55,
      "content": "فبأي الا ربك تتمارىا"
    },
    {
      "surah_number": 53,
      "verse_number": 56,
      "content": "هاذا نذير من النذر الأولىا"
    },
    {
      "surah_number": 53,
      "verse_number": 57,
      "content": "أزفت الأزفه"
    },
    {
      "surah_number": 53,
      "verse_number": 58,
      "content": "ليس لها من دون الله كاشفه"
    },
    {
      "surah_number": 53,
      "verse_number": 59,
      "content": "أفمن هاذا الحديث تعجبون"
    },
    {
      "surah_number": 53,
      "verse_number": 60,
      "content": "وتضحكون ولا تبكون"
    },
    {
      "surah_number": 53,
      "verse_number": 61,
      "content": "وأنتم سامدون"
    },
    {
      "surah_number": 53,
      "verse_number": 62,
      "content": "فاسجدوا لله واعبدوا"
    },
    {
      "surah_number": 54,
      "verse_number": 1,
      "content": "اقتربت الساعه وانشق القمر"
    },
    {
      "surah_number": 54,
      "verse_number": 2,
      "content": "وان يروا ايه يعرضوا ويقولوا سحر مستمر"
    },
    {
      "surah_number": 54,
      "verse_number": 3,
      "content": "وكذبوا واتبعوا أهواهم وكل أمر مستقر"
    },
    {
      "surah_number": 54,
      "verse_number": 4,
      "content": "ولقد جاهم من الأنبا ما فيه مزدجر"
    },
    {
      "surah_number": 54,
      "verse_number": 5,
      "content": "حكمه بالغه فما تغن النذر"
    },
    {
      "surah_number": 54,
      "verse_number": 6,
      "content": "فتول عنهم يوم يدع الداع الىا شي نكر"
    },
    {
      "surah_number": 54,
      "verse_number": 7,
      "content": "خشعا أبصارهم يخرجون من الأجداث كأنهم جراد منتشر"
    },
    {
      "surah_number": 54,
      "verse_number": 8,
      "content": "مهطعين الى الداع يقول الكافرون هاذا يوم عسر"
    },
    {
      "surah_number": 54,
      "verse_number": 9,
      "content": "كذبت قبلهم قوم نوح فكذبوا عبدنا وقالوا مجنون وازدجر"
    },
    {
      "surah_number": 54,
      "verse_number": 10,
      "content": "فدعا ربه أني مغلوب فانتصر"
    },
    {
      "surah_number": 54,
      "verse_number": 11,
      "content": "ففتحنا أبواب السما بما منهمر"
    },
    {
      "surah_number": 54,
      "verse_number": 12,
      "content": "وفجرنا الأرض عيونا فالتقى الما علىا أمر قد قدر"
    },
    {
      "surah_number": 54,
      "verse_number": 13,
      "content": "وحملناه علىا ذات ألواح ودسر"
    },
    {
      "surah_number": 54,
      "verse_number": 14,
      "content": "تجري بأعيننا جزا لمن كان كفر"
    },
    {
      "surah_number": 54,
      "verse_number": 15,
      "content": "ولقد تركناها ايه فهل من مدكر"
    },
    {
      "surah_number": 54,
      "verse_number": 16,
      "content": "فكيف كان عذابي ونذر"
    },
    {
      "surah_number": 54,
      "verse_number": 17,
      "content": "ولقد يسرنا القران للذكر فهل من مدكر"
    },
    {
      "surah_number": 54,
      "verse_number": 18,
      "content": "كذبت عاد فكيف كان عذابي ونذر"
    },
    {
      "surah_number": 54,
      "verse_number": 19,
      "content": "انا أرسلنا عليهم ريحا صرصرا في يوم نحس مستمر"
    },
    {
      "surah_number": 54,
      "verse_number": 20,
      "content": "تنزع الناس كأنهم أعجاز نخل منقعر"
    },
    {
      "surah_number": 54,
      "verse_number": 21,
      "content": "فكيف كان عذابي ونذر"
    },
    {
      "surah_number": 54,
      "verse_number": 22,
      "content": "ولقد يسرنا القران للذكر فهل من مدكر"
    },
    {
      "surah_number": 54,
      "verse_number": 23,
      "content": "كذبت ثمود بالنذر"
    },
    {
      "surah_number": 54,
      "verse_number": 24,
      "content": "فقالوا أبشرا منا واحدا نتبعه انا اذا لفي ضلال وسعر"
    },
    {
      "surah_number": 54,
      "verse_number": 25,
      "content": "ألقي الذكر عليه من بيننا بل هو كذاب أشر"
    },
    {
      "surah_number": 54,
      "verse_number": 26,
      "content": "سيعلمون غدا من الكذاب الأشر"
    },
    {
      "surah_number": 54,
      "verse_number": 27,
      "content": "انا مرسلوا الناقه فتنه لهم فارتقبهم واصطبر"
    },
    {
      "surah_number": 54,
      "verse_number": 28,
      "content": "ونبئهم أن الما قسمه بينهم كل شرب محتضر"
    },
    {
      "surah_number": 54,
      "verse_number": 29,
      "content": "فنادوا صاحبهم فتعاطىا فعقر"
    },
    {
      "surah_number": 54,
      "verse_number": 30,
      "content": "فكيف كان عذابي ونذر"
    },
    {
      "surah_number": 54,
      "verse_number": 31,
      "content": "انا أرسلنا عليهم صيحه واحده فكانوا كهشيم المحتظر"
    },
    {
      "surah_number": 54,
      "verse_number": 32,
      "content": "ولقد يسرنا القران للذكر فهل من مدكر"
    },
    {
      "surah_number": 54,
      "verse_number": 33,
      "content": "كذبت قوم لوط بالنذر"
    },
    {
      "surah_number": 54,
      "verse_number": 34,
      "content": "انا أرسلنا عليهم حاصبا الا ال لوط نجيناهم بسحر"
    },
    {
      "surah_number": 54,
      "verse_number": 35,
      "content": "نعمه من عندنا كذالك نجزي من شكر"
    },
    {
      "surah_number": 54,
      "verse_number": 36,
      "content": "ولقد أنذرهم بطشتنا فتماروا بالنذر"
    },
    {
      "surah_number": 54,
      "verse_number": 37,
      "content": "ولقد راودوه عن ضيفه فطمسنا أعينهم فذوقوا عذابي ونذر"
    },
    {
      "surah_number": 54,
      "verse_number": 38,
      "content": "ولقد صبحهم بكره عذاب مستقر"
    },
    {
      "surah_number": 54,
      "verse_number": 39,
      "content": "فذوقوا عذابي ونذر"
    },
    {
      "surah_number": 54,
      "verse_number": 40,
      "content": "ولقد يسرنا القران للذكر فهل من مدكر"
    },
    {
      "surah_number": 54,
      "verse_number": 41,
      "content": "ولقد جا ال فرعون النذر"
    },
    {
      "surah_number": 54,
      "verse_number": 42,
      "content": "كذبوا بٔاياتنا كلها فأخذناهم أخذ عزيز مقتدر"
    },
    {
      "surah_number": 54,
      "verse_number": 43,
      "content": "أكفاركم خير من أولائكم أم لكم براه في الزبر"
    },
    {
      "surah_number": 54,
      "verse_number": 44,
      "content": "أم يقولون نحن جميع منتصر"
    },
    {
      "surah_number": 54,
      "verse_number": 45,
      "content": "سيهزم الجمع ويولون الدبر"
    },
    {
      "surah_number": 54,
      "verse_number": 46,
      "content": "بل الساعه موعدهم والساعه أدهىا وأمر"
    },
    {
      "surah_number": 54,
      "verse_number": 47,
      "content": "ان المجرمين في ضلال وسعر"
    },
    {
      "surah_number": 54,
      "verse_number": 48,
      "content": "يوم يسحبون في النار علىا وجوههم ذوقوا مس سقر"
    },
    {
      "surah_number": 54,
      "verse_number": 49,
      "content": "انا كل شي خلقناه بقدر"
    },
    {
      "surah_number": 54,
      "verse_number": 50,
      "content": "وما أمرنا الا واحده كلمح بالبصر"
    },
    {
      "surah_number": 54,
      "verse_number": 51,
      "content": "ولقد أهلكنا أشياعكم فهل من مدكر"
    },
    {
      "surah_number": 54,
      "verse_number": 52,
      "content": "وكل شي فعلوه في الزبر"
    },
    {
      "surah_number": 54,
      "verse_number": 53,
      "content": "وكل صغير وكبير مستطر"
    },
    {
      "surah_number": 54,
      "verse_number": 54,
      "content": "ان المتقين في جنات ونهر"
    },
    {
      "surah_number": 54,
      "verse_number": 55,
      "content": "في مقعد صدق عند مليك مقتدر"
    },
    {
      "surah_number": 55,
      "verse_number": 1,
      "content": "الرحمان"
    },
    {
      "surah_number": 55,
      "verse_number": 2,
      "content": "علم القران"
    },
    {
      "surah_number": 55,
      "verse_number": 3,
      "content": "خلق الانسان"
    },
    {
      "surah_number": 55,
      "verse_number": 4,
      "content": "علمه البيان"
    },
    {
      "surah_number": 55,
      "verse_number": 5,
      "content": "الشمس والقمر بحسبان"
    },
    {
      "surah_number": 55,
      "verse_number": 6,
      "content": "والنجم والشجر يسجدان"
    },
    {
      "surah_number": 55,
      "verse_number": 7,
      "content": "والسما رفعها ووضع الميزان"
    },
    {
      "surah_number": 55,
      "verse_number": 8,
      "content": "ألا تطغوا في الميزان"
    },
    {
      "surah_number": 55,
      "verse_number": 9,
      "content": "وأقيموا الوزن بالقسط ولا تخسروا الميزان"
    },
    {
      "surah_number": 55,
      "verse_number": 10,
      "content": "والأرض وضعها للأنام"
    },
    {
      "surah_number": 55,
      "verse_number": 11,
      "content": "فيها فاكهه والنخل ذات الأكمام"
    },
    {
      "surah_number": 55,
      "verse_number": 12,
      "content": "والحب ذو العصف والريحان"
    },
    {
      "surah_number": 55,
      "verse_number": 13,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 14,
      "content": "خلق الانسان من صلصال كالفخار"
    },
    {
      "surah_number": 55,
      "verse_number": 15,
      "content": "وخلق الجان من مارج من نار"
    },
    {
      "surah_number": 55,
      "verse_number": 16,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 17,
      "content": "رب المشرقين ورب المغربين"
    },
    {
      "surah_number": 55,
      "verse_number": 18,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 19,
      "content": "مرج البحرين يلتقيان"
    },
    {
      "surah_number": 55,
      "verse_number": 20,
      "content": "بينهما برزخ لا يبغيان"
    },
    {
      "surah_number": 55,
      "verse_number": 21,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 22,
      "content": "يخرج منهما اللؤلؤ والمرجان"
    },
    {
      "surah_number": 55,
      "verse_number": 23,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 24,
      "content": "وله الجوار المنشٔات في البحر كالأعلام"
    },
    {
      "surah_number": 55,
      "verse_number": 25,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 26,
      "content": "كل من عليها فان"
    },
    {
      "surah_number": 55,
      "verse_number": 27,
      "content": "ويبقىا وجه ربك ذو الجلال والاكرام"
    },
    {
      "surah_number": 55,
      "verse_number": 28,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 29,
      "content": "يسٔله من في السماوات والأرض كل يوم هو في شأن"
    },
    {
      "surah_number": 55,
      "verse_number": 30,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 31,
      "content": "سنفرغ لكم أيه الثقلان"
    },
    {
      "surah_number": 55,
      "verse_number": 32,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 33,
      "content": "يامعشر الجن والانس ان استطعتم أن تنفذوا من أقطار السماوات والأرض فانفذوا لا تنفذون الا بسلطان"
    },
    {
      "surah_number": 55,
      "verse_number": 34,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 35,
      "content": "يرسل عليكما شواظ من نار ونحاس فلا تنتصران"
    },
    {
      "surah_number": 55,
      "verse_number": 36,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 37,
      "content": "فاذا انشقت السما فكانت ورده كالدهان"
    },
    {
      "surah_number": 55,
      "verse_number": 38,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 39,
      "content": "فيومئذ لا يسٔل عن ذنبه انس ولا جان"
    },
    {
      "surah_number": 55,
      "verse_number": 40,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 41,
      "content": "يعرف المجرمون بسيماهم فيؤخذ بالنواصي والأقدام"
    },
    {
      "surah_number": 55,
      "verse_number": 42,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 43,
      "content": "هاذه جهنم التي يكذب بها المجرمون"
    },
    {
      "surah_number": 55,
      "verse_number": 44,
      "content": "يطوفون بينها وبين حميم ان"
    },
    {
      "surah_number": 55,
      "verse_number": 45,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 46,
      "content": "ولمن خاف مقام ربه جنتان"
    },
    {
      "surah_number": 55,
      "verse_number": 47,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 48,
      "content": "ذواتا أفنان"
    },
    {
      "surah_number": 55,
      "verse_number": 49,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 50,
      "content": "فيهما عينان تجريان"
    },
    {
      "surah_number": 55,
      "verse_number": 51,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 52,
      "content": "فيهما من كل فاكهه زوجان"
    },
    {
      "surah_number": 55,
      "verse_number": 53,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 54,
      "content": "متكٔين علىا فرش بطائنها من استبرق وجنى الجنتين دان"
    },
    {
      "surah_number": 55,
      "verse_number": 55,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 56,
      "content": "فيهن قاصرات الطرف لم يطمثهن انس قبلهم ولا جان"
    },
    {
      "surah_number": 55,
      "verse_number": 57,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 58,
      "content": "كأنهن الياقوت والمرجان"
    },
    {
      "surah_number": 55,
      "verse_number": 59,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 60,
      "content": "هل جزا الاحسان الا الاحسان"
    },
    {
      "surah_number": 55,
      "verse_number": 61,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 62,
      "content": "ومن دونهما جنتان"
    },
    {
      "surah_number": 55,
      "verse_number": 63,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 64,
      "content": "مدهامتان"
    },
    {
      "surah_number": 55,
      "verse_number": 65,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 66,
      "content": "فيهما عينان نضاختان"
    },
    {
      "surah_number": 55,
      "verse_number": 67,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 68,
      "content": "فيهما فاكهه ونخل ورمان"
    },
    {
      "surah_number": 55,
      "verse_number": 69,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 70,
      "content": "فيهن خيرات حسان"
    },
    {
      "surah_number": 55,
      "verse_number": 71,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 72,
      "content": "حور مقصورات في الخيام"
    },
    {
      "surah_number": 55,
      "verse_number": 73,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 74,
      "content": "لم يطمثهن انس قبلهم ولا جان"
    },
    {
      "surah_number": 55,
      "verse_number": 75,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 76,
      "content": "متكٔين علىا رفرف خضر وعبقري حسان"
    },
    {
      "surah_number": 55,
      "verse_number": 77,
      "content": "فبأي الا ربكما تكذبان"
    },
    {
      "surah_number": 55,
      "verse_number": 78,
      "content": "تبارك اسم ربك ذي الجلال والاكرام"
    },
    {
      "surah_number": 56,
      "verse_number": 1,
      "content": "اذا وقعت الواقعه"
    },
    {
      "surah_number": 56,
      "verse_number": 2,
      "content": "ليس لوقعتها كاذبه"
    },
    {
      "surah_number": 56,
      "verse_number": 3,
      "content": "خافضه رافعه"
    },
    {
      "surah_number": 56,
      "verse_number": 4,
      "content": "اذا رجت الأرض رجا"
    },
    {
      "surah_number": 56,
      "verse_number": 5,
      "content": "وبست الجبال بسا"
    },
    {
      "surah_number": 56,
      "verse_number": 6,
      "content": "فكانت هبا منبثا"
    },
    {
      "surah_number": 56,
      "verse_number": 7,
      "content": "وكنتم أزواجا ثلاثه"
    },
    {
      "surah_number": 56,
      "verse_number": 8,
      "content": "فأصحاب الميمنه ما أصحاب الميمنه"
    },
    {
      "surah_number": 56,
      "verse_number": 9,
      "content": "وأصحاب المشٔمه ما أصحاب المشٔمه"
    },
    {
      "surah_number": 56,
      "verse_number": 10,
      "content": "والسابقون السابقون"
    },
    {
      "surah_number": 56,
      "verse_number": 11,
      "content": "أولائك المقربون"
    },
    {
      "surah_number": 56,
      "verse_number": 12,
      "content": "في جنات النعيم"
    },
    {
      "surah_number": 56,
      "verse_number": 13,
      "content": "ثله من الأولين"
    },
    {
      "surah_number": 56,
      "verse_number": 14,
      "content": "وقليل من الأخرين"
    },
    {
      "surah_number": 56,
      "verse_number": 15,
      "content": "علىا سرر موضونه"
    },
    {
      "surah_number": 56,
      "verse_number": 16,
      "content": "متكٔين عليها متقابلين"
    },
    {
      "surah_number": 56,
      "verse_number": 17,
      "content": "يطوف عليهم ولدان مخلدون"
    },
    {
      "surah_number": 56,
      "verse_number": 18,
      "content": "بأكواب وأباريق وكأس من معين"
    },
    {
      "surah_number": 56,
      "verse_number": 19,
      "content": "لا يصدعون عنها ولا ينزفون"
    },
    {
      "surah_number": 56,
      "verse_number": 20,
      "content": "وفاكهه مما يتخيرون"
    },
    {
      "surah_number": 56,
      "verse_number": 21,
      "content": "ولحم طير مما يشتهون"
    },
    {
      "surah_number": 56,
      "verse_number": 22,
      "content": "وحور عين"
    },
    {
      "surah_number": 56,
      "verse_number": 23,
      "content": "كأمثال اللؤلو المكنون"
    },
    {
      "surah_number": 56,
      "verse_number": 24,
      "content": "جزا بما كانوا يعملون"
    },
    {
      "surah_number": 56,
      "verse_number": 25,
      "content": "لا يسمعون فيها لغوا ولا تأثيما"
    },
    {
      "surah_number": 56,
      "verse_number": 26,
      "content": "الا قيلا سلاما سلاما"
    },
    {
      "surah_number": 56,
      "verse_number": 27,
      "content": "وأصحاب اليمين ما أصحاب اليمين"
    },
    {
      "surah_number": 56,
      "verse_number": 28,
      "content": "في سدر مخضود"
    },
    {
      "surah_number": 56,
      "verse_number": 29,
      "content": "وطلح منضود"
    },
    {
      "surah_number": 56,
      "verse_number": 30,
      "content": "وظل ممدود"
    },
    {
      "surah_number": 56,
      "verse_number": 31,
      "content": "وما مسكوب"
    },
    {
      "surah_number": 56,
      "verse_number": 32,
      "content": "وفاكهه كثيره"
    },
    {
      "surah_number": 56,
      "verse_number": 33,
      "content": "لا مقطوعه ولا ممنوعه"
    },
    {
      "surah_number": 56,
      "verse_number": 34,
      "content": "وفرش مرفوعه"
    },
    {
      "surah_number": 56,
      "verse_number": 35,
      "content": "انا أنشأناهن انشا"
    },
    {
      "surah_number": 56,
      "verse_number": 36,
      "content": "فجعلناهن أبكارا"
    },
    {
      "surah_number": 56,
      "verse_number": 37,
      "content": "عربا أترابا"
    },
    {
      "surah_number": 56,
      "verse_number": 38,
      "content": "لأصحاب اليمين"
    },
    {
      "surah_number": 56,
      "verse_number": 39,
      "content": "ثله من الأولين"
    },
    {
      "surah_number": 56,
      "verse_number": 40,
      "content": "وثله من الأخرين"
    },
    {
      "surah_number": 56,
      "verse_number": 41,
      "content": "وأصحاب الشمال ما أصحاب الشمال"
    },
    {
      "surah_number": 56,
      "verse_number": 42,
      "content": "في سموم وحميم"
    },
    {
      "surah_number": 56,
      "verse_number": 43,
      "content": "وظل من يحموم"
    },
    {
      "surah_number": 56,
      "verse_number": 44,
      "content": "لا بارد ولا كريم"
    },
    {
      "surah_number": 56,
      "verse_number": 45,
      "content": "انهم كانوا قبل ذالك مترفين"
    },
    {
      "surah_number": 56,
      "verse_number": 46,
      "content": "وكانوا يصرون على الحنث العظيم"
    },
    {
      "surah_number": 56,
      "verse_number": 47,
      "content": "وكانوا يقولون أئذا متنا وكنا ترابا وعظاما أنا لمبعوثون"
    },
    {
      "surah_number": 56,
      "verse_number": 48,
      "content": "أواباؤنا الأولون"
    },
    {
      "surah_number": 56,
      "verse_number": 49,
      "content": "قل ان الأولين والأخرين"
    },
    {
      "surah_number": 56,
      "verse_number": 50,
      "content": "لمجموعون الىا ميقات يوم معلوم"
    },
    {
      "surah_number": 56,
      "verse_number": 51,
      "content": "ثم انكم أيها الضالون المكذبون"
    },
    {
      "surah_number": 56,
      "verse_number": 52,
      "content": "لأكلون من شجر من زقوم"
    },
    {
      "surah_number": 56,
      "verse_number": 53,
      "content": "فمالٔون منها البطون"
    },
    {
      "surah_number": 56,
      "verse_number": 54,
      "content": "فشاربون عليه من الحميم"
    },
    {
      "surah_number": 56,
      "verse_number": 55,
      "content": "فشاربون شرب الهيم"
    },
    {
      "surah_number": 56,
      "verse_number": 56,
      "content": "هاذا نزلهم يوم الدين"
    },
    {
      "surah_number": 56,
      "verse_number": 57,
      "content": "نحن خلقناكم فلولا تصدقون"
    },
    {
      "surah_number": 56,
      "verse_number": 58,
      "content": "أفريتم ما تمنون"
    },
    {
      "surah_number": 56,
      "verse_number": 59,
      "content": "ءأنتم تخلقونه أم نحن الخالقون"
    },
    {
      "surah_number": 56,
      "verse_number": 60,
      "content": "نحن قدرنا بينكم الموت وما نحن بمسبوقين"
    },
    {
      "surah_number": 56,
      "verse_number": 61,
      "content": "علىا أن نبدل أمثالكم وننشئكم في ما لا تعلمون"
    },
    {
      "surah_number": 56,
      "verse_number": 62,
      "content": "ولقد علمتم النشأه الأولىا فلولا تذكرون"
    },
    {
      "surah_number": 56,
      "verse_number": 63,
      "content": "أفريتم ما تحرثون"
    },
    {
      "surah_number": 56,
      "verse_number": 64,
      "content": "ءأنتم تزرعونه أم نحن الزارعون"
    },
    {
      "surah_number": 56,
      "verse_number": 65,
      "content": "لو نشا لجعلناه حطاما فظلتم تفكهون"
    },
    {
      "surah_number": 56,
      "verse_number": 66,
      "content": "انا لمغرمون"
    },
    {
      "surah_number": 56,
      "verse_number": 67,
      "content": "بل نحن محرومون"
    },
    {
      "surah_number": 56,
      "verse_number": 68,
      "content": "أفريتم الما الذي تشربون"
    },
    {
      "surah_number": 56,
      "verse_number": 69,
      "content": "ءأنتم أنزلتموه من المزن أم نحن المنزلون"
    },
    {
      "surah_number": 56,
      "verse_number": 70,
      "content": "لو نشا جعلناه أجاجا فلولا تشكرون"
    },
    {
      "surah_number": 56,
      "verse_number": 71,
      "content": "أفريتم النار التي تورون"
    },
    {
      "surah_number": 56,
      "verse_number": 72,
      "content": "ءأنتم أنشأتم شجرتها أم نحن المنشٔون"
    },
    {
      "surah_number": 56,
      "verse_number": 73,
      "content": "نحن جعلناها تذكره ومتاعا للمقوين"
    },
    {
      "surah_number": 56,
      "verse_number": 74,
      "content": "فسبح باسم ربك العظيم"
    },
    {
      "surah_number": 56,
      "verse_number": 75,
      "content": "فلا أقسم بمواقع النجوم"
    },
    {
      "surah_number": 56,
      "verse_number": 76,
      "content": "وانه لقسم لو تعلمون عظيم"
    },
    {
      "surah_number": 56,
      "verse_number": 77,
      "content": "انه لقران كريم"
    },
    {
      "surah_number": 56,
      "verse_number": 78,
      "content": "في كتاب مكنون"
    },
    {
      "surah_number": 56,
      "verse_number": 79,
      "content": "لا يمسه الا المطهرون"
    },
    {
      "surah_number": 56,
      "verse_number": 80,
      "content": "تنزيل من رب العالمين"
    },
    {
      "surah_number": 56,
      "verse_number": 81,
      "content": "أفبهاذا الحديث أنتم مدهنون"
    },
    {
      "surah_number": 56,
      "verse_number": 82,
      "content": "وتجعلون رزقكم أنكم تكذبون"
    },
    {
      "surah_number": 56,
      "verse_number": 83,
      "content": "فلولا اذا بلغت الحلقوم"
    },
    {
      "surah_number": 56,
      "verse_number": 84,
      "content": "وأنتم حينئذ تنظرون"
    },
    {
      "surah_number": 56,
      "verse_number": 85,
      "content": "ونحن أقرب اليه منكم ولاكن لا تبصرون"
    },
    {
      "surah_number": 56,
      "verse_number": 86,
      "content": "فلولا ان كنتم غير مدينين"
    },
    {
      "surah_number": 56,
      "verse_number": 87,
      "content": "ترجعونها ان كنتم صادقين"
    },
    {
      "surah_number": 56,
      "verse_number": 88,
      "content": "فأما ان كان من المقربين"
    },
    {
      "surah_number": 56,
      "verse_number": 89,
      "content": "فروح وريحان وجنت نعيم"
    },
    {
      "surah_number": 56,
      "verse_number": 90,
      "content": "وأما ان كان من أصحاب اليمين"
    },
    {
      "surah_number": 56,
      "verse_number": 91,
      "content": "فسلام لك من أصحاب اليمين"
    },
    {
      "surah_number": 56,
      "verse_number": 92,
      "content": "وأما ان كان من المكذبين الضالين"
    },
    {
      "surah_number": 56,
      "verse_number": 93,
      "content": "فنزل من حميم"
    },
    {
      "surah_number": 56,
      "verse_number": 94,
      "content": "وتصليه جحيم"
    },
    {
      "surah_number": 56,
      "verse_number": 95,
      "content": "ان هاذا لهو حق اليقين"
    },
    {
      "surah_number": 56,
      "verse_number": 96,
      "content": "فسبح باسم ربك العظيم"
    },
    {
      "surah_number": 57,
      "verse_number": 1,
      "content": "سبح لله ما في السماوات والأرض وهو العزيز الحكيم"
    },
    {
      "surah_number": 57,
      "verse_number": 2,
      "content": "له ملك السماوات والأرض يحي ويميت وهو علىا كل شي قدير"
    },
    {
      "surah_number": 57,
      "verse_number": 3,
      "content": "هو الأول والأخر والظاهر والباطن وهو بكل شي عليم"
    },
    {
      "surah_number": 57,
      "verse_number": 4,
      "content": "هو الذي خلق السماوات والأرض في سته أيام ثم استوىا على العرش يعلم ما يلج في الأرض وما يخرج منها وما ينزل من السما وما يعرج فيها وهو معكم أين ما كنتم والله بما تعملون بصير"
    },
    {
      "surah_number": 57,
      "verse_number": 5,
      "content": "له ملك السماوات والأرض والى الله ترجع الأمور"
    },
    {
      "surah_number": 57,
      "verse_number": 6,
      "content": "يولج اليل في النهار ويولج النهار في اليل وهو عليم بذات الصدور"
    },
    {
      "surah_number": 57,
      "verse_number": 7,
      "content": "امنوا بالله ورسوله وأنفقوا مما جعلكم مستخلفين فيه فالذين امنوا منكم وأنفقوا لهم أجر كبير"
    },
    {
      "surah_number": 57,
      "verse_number": 8,
      "content": "وما لكم لا تؤمنون بالله والرسول يدعوكم لتؤمنوا بربكم وقد أخذ ميثاقكم ان كنتم مؤمنين"
    },
    {
      "surah_number": 57,
      "verse_number": 9,
      "content": "هو الذي ينزل علىا عبده ايات بينات ليخرجكم من الظلمات الى النور وان الله بكم لروف رحيم"
    },
    {
      "surah_number": 57,
      "verse_number": 10,
      "content": "وما لكم ألا تنفقوا في سبيل الله ولله ميراث السماوات والأرض لا يستوي منكم من أنفق من قبل الفتح وقاتل أولائك أعظم درجه من الذين أنفقوا من بعد وقاتلوا وكلا وعد الله الحسنىا والله بما تعملون خبير"
    },
    {
      "surah_number": 57,
      "verse_number": 11,
      "content": "من ذا الذي يقرض الله قرضا حسنا فيضاعفه له وله أجر كريم"
    },
    {
      "surah_number": 57,
      "verse_number": 12,
      "content": "يوم ترى المؤمنين والمؤمنات يسعىا نورهم بين أيديهم وبأيمانهم بشرىاكم اليوم جنات تجري من تحتها الأنهار خالدين فيها ذالك هو الفوز العظيم"
    },
    {
      "surah_number": 57,
      "verse_number": 13,
      "content": "يوم يقول المنافقون والمنافقات للذين امنوا انظرونا نقتبس من نوركم قيل ارجعوا وراكم فالتمسوا نورا فضرب بينهم بسور له باب باطنه فيه الرحمه وظاهره من قبله العذاب"
    },
    {
      "surah_number": 57,
      "verse_number": 14,
      "content": "ينادونهم ألم نكن معكم قالوا بلىا ولاكنكم فتنتم أنفسكم وتربصتم وارتبتم وغرتكم الأماني حتىا جا أمر الله وغركم بالله الغرور"
    },
    {
      "surah_number": 57,
      "verse_number": 15,
      "content": "فاليوم لا يؤخذ منكم فديه ولا من الذين كفروا مأوىاكم النار هي مولىاكم وبئس المصير"
    },
    {
      "surah_number": 57,
      "verse_number": 16,
      "content": "ألم يأن للذين امنوا أن تخشع قلوبهم لذكر الله وما نزل من الحق ولا يكونوا كالذين أوتوا الكتاب من قبل فطال عليهم الأمد فقست قلوبهم وكثير منهم فاسقون"
    },
    {
      "surah_number": 57,
      "verse_number": 17,
      "content": "اعلموا أن الله يحي الأرض بعد موتها قد بينا لكم الأيات لعلكم تعقلون"
    },
    {
      "surah_number": 57,
      "verse_number": 18,
      "content": "ان المصدقين والمصدقات وأقرضوا الله قرضا حسنا يضاعف لهم ولهم أجر كريم"
    },
    {
      "surah_number": 57,
      "verse_number": 19,
      "content": "والذين امنوا بالله ورسله أولائك هم الصديقون والشهدا عند ربهم لهم أجرهم ونورهم والذين كفروا وكذبوا بٔاياتنا أولائك أصحاب الجحيم"
    },
    {
      "surah_number": 57,
      "verse_number": 20,
      "content": "اعلموا أنما الحيواه الدنيا لعب ولهو وزينه وتفاخر بينكم وتكاثر في الأموال والأولاد كمثل غيث أعجب الكفار نباته ثم يهيج فترىاه مصفرا ثم يكون حطاما وفي الأخره عذاب شديد ومغفره من الله ورضوان وما الحيواه الدنيا الا متاع الغرور"
    },
    {
      "surah_number": 57,
      "verse_number": 21,
      "content": "سابقوا الىا مغفره من ربكم وجنه عرضها كعرض السما والأرض أعدت للذين امنوا بالله ورسله ذالك فضل الله يؤتيه من يشا والله ذو الفضل العظيم"
    },
    {
      "surah_number": 57,
      "verse_number": 22,
      "content": "ما أصاب من مصيبه في الأرض ولا في أنفسكم الا في كتاب من قبل أن نبرأها ان ذالك على الله يسير"
    },
    {
      "surah_number": 57,
      "verse_number": 23,
      "content": "لكيلا تأسوا علىا ما فاتكم ولا تفرحوا بما اتىاكم والله لا يحب كل مختال فخور"
    },
    {
      "surah_number": 57,
      "verse_number": 24,
      "content": "الذين يبخلون ويأمرون الناس بالبخل ومن يتول فان الله هو الغني الحميد"
    },
    {
      "surah_number": 57,
      "verse_number": 25,
      "content": "لقد أرسلنا رسلنا بالبينات وأنزلنا معهم الكتاب والميزان ليقوم الناس بالقسط وأنزلنا الحديد فيه بأس شديد ومنافع للناس وليعلم الله من ينصره ورسله بالغيب ان الله قوي عزيز"
    },
    {
      "surah_number": 57,
      "verse_number": 26,
      "content": "ولقد أرسلنا نوحا وابراهيم وجعلنا في ذريتهما النبوه والكتاب فمنهم مهتد وكثير منهم فاسقون"
    },
    {
      "surah_number": 57,
      "verse_number": 27,
      "content": "ثم قفينا علىا اثارهم برسلنا وقفينا بعيسى ابن مريم واتيناه الانجيل وجعلنا في قلوب الذين اتبعوه رأفه ورحمه ورهبانيه ابتدعوها ما كتبناها عليهم الا ابتغا رضوان الله فما رعوها حق رعايتها فٔاتينا الذين امنوا منهم أجرهم وكثير منهم فاسقون"
    },
    {
      "surah_number": 57,
      "verse_number": 28,
      "content": "ياأيها الذين امنوا اتقوا الله وامنوا برسوله يؤتكم كفلين من رحمته ويجعل لكم نورا تمشون به ويغفر لكم والله غفور رحيم"
    },
    {
      "surah_number": 57,
      "verse_number": 29,
      "content": "لئلا يعلم أهل الكتاب ألا يقدرون علىا شي من فضل الله وأن الفضل بيد الله يؤتيه من يشا والله ذو الفضل العظيم"
    },
    {
      "surah_number": 58,
      "verse_number": 1,
      "content": "قد سمع الله قول التي تجادلك في زوجها وتشتكي الى الله والله يسمع تحاوركما ان الله سميع بصير"
    },
    {
      "surah_number": 58,
      "verse_number": 2,
      "content": "الذين يظاهرون منكم من نسائهم ما هن أمهاتهم ان أمهاتهم الا الأي ولدنهم وانهم ليقولون منكرا من القول وزورا وان الله لعفو غفور"
    },
    {
      "surah_number": 58,
      "verse_number": 3,
      "content": "والذين يظاهرون من نسائهم ثم يعودون لما قالوا فتحرير رقبه من قبل أن يتماسا ذالكم توعظون به والله بما تعملون خبير"
    },
    {
      "surah_number": 58,
      "verse_number": 4,
      "content": "فمن لم يجد فصيام شهرين متتابعين من قبل أن يتماسا فمن لم يستطع فاطعام ستين مسكينا ذالك لتؤمنوا بالله ورسوله وتلك حدود الله وللكافرين عذاب أليم"
    },
    {
      "surah_number": 58,
      "verse_number": 5,
      "content": "ان الذين يحادون الله ورسوله كبتوا كما كبت الذين من قبلهم وقد أنزلنا ايات بينات وللكافرين عذاب مهين"
    },
    {
      "surah_number": 58,
      "verse_number": 6,
      "content": "يوم يبعثهم الله جميعا فينبئهم بما عملوا أحصىاه الله ونسوه والله علىا كل شي شهيد"
    },
    {
      "surah_number": 58,
      "verse_number": 7,
      "content": "ألم تر أن الله يعلم ما في السماوات وما في الأرض ما يكون من نجوىا ثلاثه الا هو رابعهم ولا خمسه الا هو سادسهم ولا أدنىا من ذالك ولا أكثر الا هو معهم أين ما كانوا ثم ينبئهم بما عملوا يوم القيامه ان الله بكل شي عليم"
    },
    {
      "surah_number": 58,
      "verse_number": 8,
      "content": "ألم تر الى الذين نهوا عن النجوىا ثم يعودون لما نهوا عنه ويتناجون بالاثم والعدوان ومعصيت الرسول واذا جاوك حيوك بما لم يحيك به الله ويقولون في أنفسهم لولا يعذبنا الله بما نقول حسبهم جهنم يصلونها فبئس المصير"
    },
    {
      "surah_number": 58,
      "verse_number": 9,
      "content": "ياأيها الذين امنوا اذا تناجيتم فلا تتناجوا بالاثم والعدوان ومعصيت الرسول وتناجوا بالبر والتقوىا واتقوا الله الذي اليه تحشرون"
    },
    {
      "surah_number": 58,
      "verse_number": 10,
      "content": "انما النجوىا من الشيطان ليحزن الذين امنوا وليس بضارهم شئا الا باذن الله وعلى الله فليتوكل المؤمنون"
    },
    {
      "surah_number": 58,
      "verse_number": 11,
      "content": "ياأيها الذين امنوا اذا قيل لكم تفسحوا في المجالس فافسحوا يفسح الله لكم واذا قيل انشزوا فانشزوا يرفع الله الذين امنوا منكم والذين أوتوا العلم درجات والله بما تعملون خبير"
    },
    {
      "surah_number": 58,
      "verse_number": 12,
      "content": "ياأيها الذين امنوا اذا ناجيتم الرسول فقدموا بين يدي نجوىاكم صدقه ذالك خير لكم وأطهر فان لم تجدوا فان الله غفور رحيم"
    },
    {
      "surah_number": 58,
      "verse_number": 13,
      "content": "ءأشفقتم أن تقدموا بين يدي نجوىاكم صدقات فاذ لم تفعلوا وتاب الله عليكم فأقيموا الصلواه واتوا الزكواه وأطيعوا الله ورسوله والله خبير بما تعملون"
    },
    {
      "surah_number": 58,
      "verse_number": 14,
      "content": "ألم تر الى الذين تولوا قوما غضب الله عليهم ما هم منكم ولا منهم ويحلفون على الكذب وهم يعلمون"
    },
    {
      "surah_number": 58,
      "verse_number": 15,
      "content": "أعد الله لهم عذابا شديدا انهم سا ما كانوا يعملون"
    },
    {
      "surah_number": 58,
      "verse_number": 16,
      "content": "اتخذوا أيمانهم جنه فصدوا عن سبيل الله فلهم عذاب مهين"
    },
    {
      "surah_number": 58,
      "verse_number": 17,
      "content": "لن تغني عنهم أموالهم ولا أولادهم من الله شئا أولائك أصحاب النار هم فيها خالدون"
    },
    {
      "surah_number": 58,
      "verse_number": 18,
      "content": "يوم يبعثهم الله جميعا فيحلفون له كما يحلفون لكم ويحسبون أنهم علىا شي ألا انهم هم الكاذبون"
    },
    {
      "surah_number": 58,
      "verse_number": 19,
      "content": "استحوذ عليهم الشيطان فأنسىاهم ذكر الله أولائك حزب الشيطان ألا ان حزب الشيطان هم الخاسرون"
    },
    {
      "surah_number": 58,
      "verse_number": 20,
      "content": "ان الذين يحادون الله ورسوله أولائك في الأذلين"
    },
    {
      "surah_number": 58,
      "verse_number": 21,
      "content": "كتب الله لأغلبن أنا ورسلي ان الله قوي عزيز"
    },
    {
      "surah_number": 58,
      "verse_number": 22,
      "content": "لا تجد قوما يؤمنون بالله واليوم الأخر يوادون من حاد الله ورسوله ولو كانوا اباهم أو أبناهم أو اخوانهم أو عشيرتهم أولائك كتب في قلوبهم الايمان وأيدهم بروح منه ويدخلهم جنات تجري من تحتها الأنهار خالدين فيها رضي الله عنهم ورضوا عنه أولائك حزب الله ألا ان حزب الله هم المفلحون"
    },
    {
      "surah_number": 59,
      "verse_number": 1,
      "content": "سبح لله ما في السماوات وما في الأرض وهو العزيز الحكيم"
    },
    {
      "surah_number": 59,
      "verse_number": 2,
      "content": "هو الذي أخرج الذين كفروا من أهل الكتاب من ديارهم لأول الحشر ما ظننتم أن يخرجوا وظنوا أنهم مانعتهم حصونهم من الله فأتىاهم الله من حيث لم يحتسبوا وقذف في قلوبهم الرعب يخربون بيوتهم بأيديهم وأيدي المؤمنين فاعتبروا ياأولي الأبصار"
    },
    {
      "surah_number": 59,
      "verse_number": 3,
      "content": "ولولا أن كتب الله عليهم الجلا لعذبهم في الدنيا ولهم في الأخره عذاب النار"
    },
    {
      "surah_number": 59,
      "verse_number": 4,
      "content": "ذالك بأنهم شاقوا الله ورسوله ومن يشاق الله فان الله شديد العقاب"
    },
    {
      "surah_number": 59,
      "verse_number": 5,
      "content": "ما قطعتم من لينه أو تركتموها قائمه علىا أصولها فباذن الله وليخزي الفاسقين"
    },
    {
      "surah_number": 59,
      "verse_number": 6,
      "content": "وما أفا الله علىا رسوله منهم فما أوجفتم عليه من خيل ولا ركاب ولاكن الله يسلط رسله علىا من يشا والله علىا كل شي قدير"
    },
    {
      "surah_number": 59,
      "verse_number": 7,
      "content": "ما أفا الله علىا رسوله من أهل القرىا فلله وللرسول ولذي القربىا واليتامىا والمساكين وابن السبيل كي لا يكون دوله بين الأغنيا منكم وما اتىاكم الرسول فخذوه وما نهىاكم عنه فانتهوا واتقوا الله ان الله شديد العقاب"
    },
    {
      "surah_number": 59,
      "verse_number": 8,
      "content": "للفقرا المهاجرين الذين أخرجوا من ديارهم وأموالهم يبتغون فضلا من الله ورضوانا وينصرون الله ورسوله أولائك هم الصادقون"
    },
    {
      "surah_number": 59,
      "verse_number": 9,
      "content": "والذين تبوو الدار والايمان من قبلهم يحبون من هاجر اليهم ولا يجدون في صدورهم حاجه مما أوتوا ويؤثرون علىا أنفسهم ولو كان بهم خصاصه ومن يوق شح نفسه فأولائك هم المفلحون"
    },
    {
      "surah_number": 59,
      "verse_number": 10,
      "content": "والذين جاو من بعدهم يقولون ربنا اغفر لنا ولاخواننا الذين سبقونا بالايمان ولا تجعل في قلوبنا غلا للذين امنوا ربنا انك روف رحيم"
    },
    {
      "surah_number": 59,
      "verse_number": 11,
      "content": "ألم تر الى الذين نافقوا يقولون لاخوانهم الذين كفروا من أهل الكتاب لئن أخرجتم لنخرجن معكم ولا نطيع فيكم أحدا أبدا وان قوتلتم لننصرنكم والله يشهد انهم لكاذبون"
    },
    {
      "surah_number": 59,
      "verse_number": 12,
      "content": "لئن أخرجوا لا يخرجون معهم ولئن قوتلوا لا ينصرونهم ولئن نصروهم ليولن الأدبار ثم لا ينصرون"
    },
    {
      "surah_number": 59,
      "verse_number": 13,
      "content": "لأنتم أشد رهبه في صدورهم من الله ذالك بأنهم قوم لا يفقهون"
    },
    {
      "surah_number": 59,
      "verse_number": 14,
      "content": "لا يقاتلونكم جميعا الا في قرى محصنه أو من ورا جدر بأسهم بينهم شديد تحسبهم جميعا وقلوبهم شتىا ذالك بأنهم قوم لا يعقلون"
    },
    {
      "surah_number": 59,
      "verse_number": 15,
      "content": "كمثل الذين من قبلهم قريبا ذاقوا وبال أمرهم ولهم عذاب أليم"
    },
    {
      "surah_number": 59,
      "verse_number": 16,
      "content": "كمثل الشيطان اذ قال للانسان اكفر فلما كفر قال اني بري منك اني أخاف الله رب العالمين"
    },
    {
      "surah_number": 59,
      "verse_number": 17,
      "content": "فكان عاقبتهما أنهما في النار خالدين فيها وذالك جزاؤا الظالمين"
    },
    {
      "surah_number": 59,
      "verse_number": 18,
      "content": "ياأيها الذين امنوا اتقوا الله ولتنظر نفس ما قدمت لغد واتقوا الله ان الله خبير بما تعملون"
    },
    {
      "surah_number": 59,
      "verse_number": 19,
      "content": "ولا تكونوا كالذين نسوا الله فأنسىاهم أنفسهم أولائك هم الفاسقون"
    },
    {
      "surah_number": 59,
      "verse_number": 20,
      "content": "لا يستوي أصحاب النار وأصحاب الجنه أصحاب الجنه هم الفائزون"
    },
    {
      "surah_number": 59,
      "verse_number": 21,
      "content": "لو أنزلنا هاذا القران علىا جبل لرأيته خاشعا متصدعا من خشيه الله وتلك الأمثال نضربها للناس لعلهم يتفكرون"
    },
    {
      "surah_number": 59,
      "verse_number": 22,
      "content": "هو الله الذي لا الاه الا هو عالم الغيب والشهاده هو الرحمان الرحيم"
    },
    {
      "surah_number": 59,
      "verse_number": 23,
      "content": "هو الله الذي لا الاه الا هو الملك القدوس السلام المؤمن المهيمن العزيز الجبار المتكبر سبحان الله عما يشركون"
    },
    {
      "surah_number": 59,
      "verse_number": 24,
      "content": "هو الله الخالق البارئ المصور له الأسما الحسنىا يسبح له ما في السماوات والأرض وهو العزيز الحكيم"
    },
    {
      "surah_number": 60,
      "verse_number": 1,
      "content": "ياأيها الذين امنوا لا تتخذوا عدوي وعدوكم أوليا تلقون اليهم بالموده وقد كفروا بما جاكم من الحق يخرجون الرسول واياكم أن تؤمنوا بالله ربكم ان كنتم خرجتم جهادا في سبيلي وابتغا مرضاتي تسرون اليهم بالموده وأنا أعلم بما أخفيتم وما أعلنتم ومن يفعله منكم فقد ضل سوا السبيل"
    },
    {
      "surah_number": 60,
      "verse_number": 2,
      "content": "ان يثقفوكم يكونوا لكم أعدا ويبسطوا اليكم أيديهم وألسنتهم بالسو وودوا لو تكفرون"
    },
    {
      "surah_number": 60,
      "verse_number": 3,
      "content": "لن تنفعكم أرحامكم ولا أولادكم يوم القيامه يفصل بينكم والله بما تعملون بصير"
    },
    {
      "surah_number": 60,
      "verse_number": 4,
      "content": "قد كانت لكم أسوه حسنه في ابراهيم والذين معه اذ قالوا لقومهم انا براؤا منكم ومما تعبدون من دون الله كفرنا بكم وبدا بيننا وبينكم العداوه والبغضا أبدا حتىا تؤمنوا بالله وحده الا قول ابراهيم لأبيه لأستغفرن لك وما أملك لك من الله من شي ربنا عليك توكلنا واليك أنبنا واليك المصير"
    },
    {
      "surah_number": 60,
      "verse_number": 5,
      "content": "ربنا لا تجعلنا فتنه للذين كفروا واغفر لنا ربنا انك أنت العزيز الحكيم"
    },
    {
      "surah_number": 60,
      "verse_number": 6,
      "content": "لقد كان لكم فيهم أسوه حسنه لمن كان يرجوا الله واليوم الأخر ومن يتول فان الله هو الغني الحميد"
    },
    {
      "surah_number": 60,
      "verse_number": 7,
      "content": "عسى الله أن يجعل بينكم وبين الذين عاديتم منهم موده والله قدير والله غفور رحيم"
    },
    {
      "surah_number": 60,
      "verse_number": 8,
      "content": "لا ينهىاكم الله عن الذين لم يقاتلوكم في الدين ولم يخرجوكم من دياركم أن تبروهم وتقسطوا اليهم ان الله يحب المقسطين"
    },
    {
      "surah_number": 60,
      "verse_number": 9,
      "content": "انما ينهىاكم الله عن الذين قاتلوكم في الدين وأخرجوكم من دياركم وظاهروا علىا اخراجكم أن تولوهم ومن يتولهم فأولائك هم الظالمون"
    },
    {
      "surah_number": 60,
      "verse_number": 10,
      "content": "ياأيها الذين امنوا اذا جاكم المؤمنات مهاجرات فامتحنوهن الله أعلم بايمانهن فان علمتموهن مؤمنات فلا ترجعوهن الى الكفار لا هن حل لهم ولا هم يحلون لهن واتوهم ما أنفقوا ولا جناح عليكم أن تنكحوهن اذا اتيتموهن أجورهن ولا تمسكوا بعصم الكوافر وسٔلوا ما أنفقتم وليسٔلوا ما أنفقوا ذالكم حكم الله يحكم بينكم والله عليم حكيم"
    },
    {
      "surah_number": 60,
      "verse_number": 11,
      "content": "وان فاتكم شي من أزواجكم الى الكفار فعاقبتم فٔاتوا الذين ذهبت أزواجهم مثل ما أنفقوا واتقوا الله الذي أنتم به مؤمنون"
    },
    {
      "surah_number": 60,
      "verse_number": 12,
      "content": "ياأيها النبي اذا جاك المؤمنات يبايعنك علىا أن لا يشركن بالله شئا ولا يسرقن ولا يزنين ولا يقتلن أولادهن ولا يأتين ببهتان يفترينه بين أيديهن وأرجلهن ولا يعصينك في معروف فبايعهن واستغفر لهن الله ان الله غفور رحيم"
    },
    {
      "surah_number": 60,
      "verse_number": 13,
      "content": "ياأيها الذين امنوا لا تتولوا قوما غضب الله عليهم قد يئسوا من الأخره كما يئس الكفار من أصحاب القبور"
    },
    {
      "surah_number": 61,
      "verse_number": 1,
      "content": "سبح لله ما في السماوات وما في الأرض وهو العزيز الحكيم"
    },
    {
      "surah_number": 61,
      "verse_number": 2,
      "content": "ياأيها الذين امنوا لم تقولون ما لا تفعلون"
    },
    {
      "surah_number": 61,
      "verse_number": 3,
      "content": "كبر مقتا عند الله أن تقولوا ما لا تفعلون"
    },
    {
      "surah_number": 61,
      "verse_number": 4,
      "content": "ان الله يحب الذين يقاتلون في سبيله صفا كأنهم بنيان مرصوص"
    },
    {
      "surah_number": 61,
      "verse_number": 5,
      "content": "واذ قال موسىا لقومه ياقوم لم تؤذونني وقد تعلمون أني رسول الله اليكم فلما زاغوا أزاغ الله قلوبهم والله لا يهدي القوم الفاسقين"
    },
    {
      "surah_number": 61,
      "verse_number": 6,
      "content": "واذ قال عيسى ابن مريم يابني اسرايل اني رسول الله اليكم مصدقا لما بين يدي من التورىاه ومبشرا برسول يأتي من بعدي اسمه أحمد فلما جاهم بالبينات قالوا هاذا سحر مبين"
    },
    {
      "surah_number": 61,
      "verse_number": 7,
      "content": "ومن أظلم ممن افترىا على الله الكذب وهو يدعىا الى الاسلام والله لا يهدي القوم الظالمين"
    },
    {
      "surah_number": 61,
      "verse_number": 8,
      "content": "يريدون ليطفٔوا نور الله بأفواههم والله متم نوره ولو كره الكافرون"
    },
    {
      "surah_number": 61,
      "verse_number": 9,
      "content": "هو الذي أرسل رسوله بالهدىا ودين الحق ليظهره على الدين كله ولو كره المشركون"
    },
    {
      "surah_number": 61,
      "verse_number": 10,
      "content": "ياأيها الذين امنوا هل أدلكم علىا تجاره تنجيكم من عذاب أليم"
    },
    {
      "surah_number": 61,
      "verse_number": 11,
      "content": "تؤمنون بالله ورسوله وتجاهدون في سبيل الله بأموالكم وأنفسكم ذالكم خير لكم ان كنتم تعلمون"
    },
    {
      "surah_number": 61,
      "verse_number": 12,
      "content": "يغفر لكم ذنوبكم ويدخلكم جنات تجري من تحتها الأنهار ومساكن طيبه في جنات عدن ذالك الفوز العظيم"
    },
    {
      "surah_number": 61,
      "verse_number": 13,
      "content": "وأخرىا تحبونها نصر من الله وفتح قريب وبشر المؤمنين"
    },
    {
      "surah_number": 61,
      "verse_number": 14,
      "content": "ياأيها الذين امنوا كونوا أنصار الله كما قال عيسى ابن مريم للحوارين من أنصاري الى الله قال الحواريون نحن أنصار الله فٔامنت طائفه من بني اسرايل وكفرت طائفه فأيدنا الذين امنوا علىا عدوهم فأصبحوا ظاهرين"
    },
    {
      "surah_number": 62,
      "verse_number": 1,
      "content": "يسبح لله ما في السماوات وما في الأرض الملك القدوس العزيز الحكيم"
    },
    {
      "surah_number": 62,
      "verse_number": 2,
      "content": "هو الذي بعث في الأمين رسولا منهم يتلوا عليهم اياته ويزكيهم ويعلمهم الكتاب والحكمه وان كانوا من قبل لفي ضلال مبين"
    },
    {
      "surah_number": 62,
      "verse_number": 3,
      "content": "واخرين منهم لما يلحقوا بهم وهو العزيز الحكيم"
    },
    {
      "surah_number": 62,
      "verse_number": 4,
      "content": "ذالك فضل الله يؤتيه من يشا والله ذو الفضل العظيم"
    },
    {
      "surah_number": 62,
      "verse_number": 5,
      "content": "مثل الذين حملوا التورىاه ثم لم يحملوها كمثل الحمار يحمل أسفارا بئس مثل القوم الذين كذبوا بٔايات الله والله لا يهدي القوم الظالمين"
    },
    {
      "surah_number": 62,
      "verse_number": 6,
      "content": "قل ياأيها الذين هادوا ان زعمتم أنكم أوليا لله من دون الناس فتمنوا الموت ان كنتم صادقين"
    },
    {
      "surah_number": 62,
      "verse_number": 7,
      "content": "ولا يتمنونه أبدا بما قدمت أيديهم والله عليم بالظالمين"
    },
    {
      "surah_number": 62,
      "verse_number": 8,
      "content": "قل ان الموت الذي تفرون منه فانه ملاقيكم ثم تردون الىا عالم الغيب والشهاده فينبئكم بما كنتم تعملون"
    },
    {
      "surah_number": 62,
      "verse_number": 9,
      "content": "ياأيها الذين امنوا اذا نودي للصلواه من يوم الجمعه فاسعوا الىا ذكر الله وذروا البيع ذالكم خير لكم ان كنتم تعلمون"
    },
    {
      "surah_number": 62,
      "verse_number": 10,
      "content": "فاذا قضيت الصلواه فانتشروا في الأرض وابتغوا من فضل الله واذكروا الله كثيرا لعلكم تفلحون"
    },
    {
      "surah_number": 62,
      "verse_number": 11,
      "content": "واذا رأوا تجاره أو لهوا انفضوا اليها وتركوك قائما قل ما عند الله خير من اللهو ومن التجاره والله خير الرازقين"
    },
    {
      "surah_number": 63,
      "verse_number": 1,
      "content": "اذا جاك المنافقون قالوا نشهد انك لرسول الله والله يعلم انك لرسوله والله يشهد ان المنافقين لكاذبون"
    },
    {
      "surah_number": 63,
      "verse_number": 2,
      "content": "اتخذوا أيمانهم جنه فصدوا عن سبيل الله انهم سا ما كانوا يعملون"
    },
    {
      "surah_number": 63,
      "verse_number": 3,
      "content": "ذالك بأنهم امنوا ثم كفروا فطبع علىا قلوبهم فهم لا يفقهون"
    },
    {
      "surah_number": 63,
      "verse_number": 4,
      "content": "واذا رأيتهم تعجبك أجسامهم وان يقولوا تسمع لقولهم كأنهم خشب مسنده يحسبون كل صيحه عليهم هم العدو فاحذرهم قاتلهم الله أنىا يؤفكون"
    },
    {
      "surah_number": 63,
      "verse_number": 5,
      "content": "واذا قيل لهم تعالوا يستغفر لكم رسول الله لووا روسهم ورأيتهم يصدون وهم مستكبرون"
    },
    {
      "surah_number": 63,
      "verse_number": 6,
      "content": "سوا عليهم أستغفرت لهم أم لم تستغفر لهم لن يغفر الله لهم ان الله لا يهدي القوم الفاسقين"
    },
    {
      "surah_number": 63,
      "verse_number": 7,
      "content": "هم الذين يقولون لا تنفقوا علىا من عند رسول الله حتىا ينفضوا ولله خزائن السماوات والأرض ولاكن المنافقين لا يفقهون"
    },
    {
      "surah_number": 63,
      "verse_number": 8,
      "content": "يقولون لئن رجعنا الى المدينه ليخرجن الأعز منها الأذل ولله العزه ولرسوله وللمؤمنين ولاكن المنافقين لا يعلمون"
    },
    {
      "surah_number": 63,
      "verse_number": 9,
      "content": "ياأيها الذين امنوا لا تلهكم أموالكم ولا أولادكم عن ذكر الله ومن يفعل ذالك فأولائك هم الخاسرون"
    },
    {
      "surah_number": 63,
      "verse_number": 10,
      "content": "وأنفقوا من ما رزقناكم من قبل أن يأتي أحدكم الموت فيقول رب لولا أخرتني الىا أجل قريب فأصدق وأكن من الصالحين"
    },
    {
      "surah_number": 63,
      "verse_number": 11,
      "content": "ولن يؤخر الله نفسا اذا جا أجلها والله خبير بما تعملون"
    },
    {
      "surah_number": 64,
      "verse_number": 1,
      "content": "يسبح لله ما في السماوات وما في الأرض له الملك وله الحمد وهو علىا كل شي قدير"
    },
    {
      "surah_number": 64,
      "verse_number": 2,
      "content": "هو الذي خلقكم فمنكم كافر ومنكم مؤمن والله بما تعملون بصير"
    },
    {
      "surah_number": 64,
      "verse_number": 3,
      "content": "خلق السماوات والأرض بالحق وصوركم فأحسن صوركم واليه المصير"
    },
    {
      "surah_number": 64,
      "verse_number": 4,
      "content": "يعلم ما في السماوات والأرض ويعلم ما تسرون وما تعلنون والله عليم بذات الصدور"
    },
    {
      "surah_number": 64,
      "verse_number": 5,
      "content": "ألم يأتكم نبؤا الذين كفروا من قبل فذاقوا وبال أمرهم ولهم عذاب أليم"
    },
    {
      "surah_number": 64,
      "verse_number": 6,
      "content": "ذالك بأنه كانت تأتيهم رسلهم بالبينات فقالوا أبشر يهدوننا فكفروا وتولوا واستغنى الله والله غني حميد"
    },
    {
      "surah_number": 64,
      "verse_number": 7,
      "content": "زعم الذين كفروا أن لن يبعثوا قل بلىا وربي لتبعثن ثم لتنبؤن بما عملتم وذالك على الله يسير"
    },
    {
      "surah_number": 64,
      "verse_number": 8,
      "content": "فٔامنوا بالله ورسوله والنور الذي أنزلنا والله بما تعملون خبير"
    },
    {
      "surah_number": 64,
      "verse_number": 9,
      "content": "يوم يجمعكم ليوم الجمع ذالك يوم التغابن ومن يؤمن بالله ويعمل صالحا يكفر عنه سئاته ويدخله جنات تجري من تحتها الأنهار خالدين فيها أبدا ذالك الفوز العظيم"
    },
    {
      "surah_number": 64,
      "verse_number": 10,
      "content": "والذين كفروا وكذبوا بٔاياتنا أولائك أصحاب النار خالدين فيها وبئس المصير"
    },
    {
      "surah_number": 64,
      "verse_number": 11,
      "content": "ما أصاب من مصيبه الا باذن الله ومن يؤمن بالله يهد قلبه والله بكل شي عليم"
    },
    {
      "surah_number": 64,
      "verse_number": 12,
      "content": "وأطيعوا الله وأطيعوا الرسول فان توليتم فانما علىا رسولنا البلاغ المبين"
    },
    {
      "surah_number": 64,
      "verse_number": 13,
      "content": "الله لا الاه الا هو وعلى الله فليتوكل المؤمنون"
    },
    {
      "surah_number": 64,
      "verse_number": 14,
      "content": "ياأيها الذين امنوا ان من أزواجكم وأولادكم عدوا لكم فاحذروهم وان تعفوا وتصفحوا وتغفروا فان الله غفور رحيم"
    },
    {
      "surah_number": 64,
      "verse_number": 15,
      "content": "انما أموالكم وأولادكم فتنه والله عنده أجر عظيم"
    },
    {
      "surah_number": 64,
      "verse_number": 16,
      "content": "فاتقوا الله ما استطعتم واسمعوا وأطيعوا وأنفقوا خيرا لأنفسكم ومن يوق شح نفسه فأولائك هم المفلحون"
    },
    {
      "surah_number": 64,
      "verse_number": 17,
      "content": "ان تقرضوا الله قرضا حسنا يضاعفه لكم ويغفر لكم والله شكور حليم"
    },
    {
      "surah_number": 64,
      "verse_number": 18,
      "content": "عالم الغيب والشهاده العزيز الحكيم"
    },
    {
      "surah_number": 65,
      "verse_number": 1,
      "content": "ياأيها النبي اذا طلقتم النسا فطلقوهن لعدتهن وأحصوا العده واتقوا الله ربكم لا تخرجوهن من بيوتهن ولا يخرجن الا أن يأتين بفاحشه مبينه وتلك حدود الله ومن يتعد حدود الله فقد ظلم نفسه لا تدري لعل الله يحدث بعد ذالك أمرا"
    },
    {
      "surah_number": 65,
      "verse_number": 2,
      "content": "فاذا بلغن أجلهن فأمسكوهن بمعروف أو فارقوهن بمعروف وأشهدوا ذوي عدل منكم وأقيموا الشهاده لله ذالكم يوعظ به من كان يؤمن بالله واليوم الأخر ومن يتق الله يجعل له مخرجا"
    },
    {
      "surah_number": 65,
      "verse_number": 3,
      "content": "ويرزقه من حيث لا يحتسب ومن يتوكل على الله فهو حسبه ان الله بالغ أمره قد جعل الله لكل شي قدرا"
    },
    {
      "surah_number": 65,
      "verse_number": 4,
      "content": "والأي يئسن من المحيض من نسائكم ان ارتبتم فعدتهن ثلاثه أشهر والأي لم يحضن وأولات الأحمال أجلهن أن يضعن حملهن ومن يتق الله يجعل له من أمره يسرا"
    },
    {
      "surah_number": 65,
      "verse_number": 5,
      "content": "ذالك أمر الله أنزله اليكم ومن يتق الله يكفر عنه سئاته ويعظم له أجرا"
    },
    {
      "surah_number": 65,
      "verse_number": 6,
      "content": "أسكنوهن من حيث سكنتم من وجدكم ولا تضاروهن لتضيقوا عليهن وان كن أولات حمل فأنفقوا عليهن حتىا يضعن حملهن فان أرضعن لكم فٔاتوهن أجورهن وأتمروا بينكم بمعروف وان تعاسرتم فسترضع له أخرىا"
    },
    {
      "surah_number": 65,
      "verse_number": 7,
      "content": "لينفق ذو سعه من سعته ومن قدر عليه رزقه فلينفق مما اتىاه الله لا يكلف الله نفسا الا ما اتىاها سيجعل الله بعد عسر يسرا"
    },
    {
      "surah_number": 65,
      "verse_number": 8,
      "content": "وكأين من قريه عتت عن أمر ربها ورسله فحاسبناها حسابا شديدا وعذبناها عذابا نكرا"
    },
    {
      "surah_number": 65,
      "verse_number": 9,
      "content": "فذاقت وبال أمرها وكان عاقبه أمرها خسرا"
    },
    {
      "surah_number": 65,
      "verse_number": 10,
      "content": "أعد الله لهم عذابا شديدا فاتقوا الله ياأولي الألباب الذين امنوا قد أنزل الله اليكم ذكرا"
    },
    {
      "surah_number": 65,
      "verse_number": 11,
      "content": "رسولا يتلوا عليكم ايات الله مبينات ليخرج الذين امنوا وعملوا الصالحات من الظلمات الى النور ومن يؤمن بالله ويعمل صالحا يدخله جنات تجري من تحتها الأنهار خالدين فيها أبدا قد أحسن الله له رزقا"
    },
    {
      "surah_number": 65,
      "verse_number": 12,
      "content": "الله الذي خلق سبع سماوات ومن الأرض مثلهن يتنزل الأمر بينهن لتعلموا أن الله علىا كل شي قدير وأن الله قد أحاط بكل شي علما"
    },
    {
      "surah_number": 66,
      "verse_number": 1,
      "content": "ياأيها النبي لم تحرم ما أحل الله لك تبتغي مرضات أزواجك والله غفور رحيم"
    },
    {
      "surah_number": 66,
      "verse_number": 2,
      "content": "قد فرض الله لكم تحله أيمانكم والله مولىاكم وهو العليم الحكيم"
    },
    {
      "surah_number": 66,
      "verse_number": 3,
      "content": "واذ أسر النبي الىا بعض أزواجه حديثا فلما نبأت به وأظهره الله عليه عرف بعضه وأعرض عن بعض فلما نبأها به قالت من أنبأك هاذا قال نبأني العليم الخبير"
    },
    {
      "surah_number": 66,
      "verse_number": 4,
      "content": "ان تتوبا الى الله فقد صغت قلوبكما وان تظاهرا عليه فان الله هو مولىاه وجبريل وصالح المؤمنين والملائكه بعد ذالك ظهير"
    },
    {
      "surah_number": 66,
      "verse_number": 5,
      "content": "عسىا ربه ان طلقكن أن يبدله أزواجا خيرا منكن مسلمات مؤمنات قانتات تائبات عابدات سائحات ثيبات وأبكارا"
    },
    {
      "surah_number": 66,
      "verse_number": 6,
      "content": "ياأيها الذين امنوا قوا أنفسكم وأهليكم نارا وقودها الناس والحجاره عليها ملائكه غلاظ شداد لا يعصون الله ما أمرهم ويفعلون ما يؤمرون"
    },
    {
      "surah_number": 66,
      "verse_number": 7,
      "content": "ياأيها الذين كفروا لا تعتذروا اليوم انما تجزون ما كنتم تعملون"
    },
    {
      "surah_number": 66,
      "verse_number": 8,
      "content": "ياأيها الذين امنوا توبوا الى الله توبه نصوحا عسىا ربكم أن يكفر عنكم سئاتكم ويدخلكم جنات تجري من تحتها الأنهار يوم لا يخزي الله النبي والذين امنوا معه نورهم يسعىا بين أيديهم وبأيمانهم يقولون ربنا أتمم لنا نورنا واغفر لنا انك علىا كل شي قدير"
    },
    {
      "surah_number": 66,
      "verse_number": 9,
      "content": "ياأيها النبي جاهد الكفار والمنافقين واغلظ عليهم ومأوىاهم جهنم وبئس المصير"
    },
    {
      "surah_number": 66,
      "verse_number": 10,
      "content": "ضرب الله مثلا للذين كفروا امرأت نوح وامرأت لوط كانتا تحت عبدين من عبادنا صالحين فخانتاهما فلم يغنيا عنهما من الله شئا وقيل ادخلا النار مع الداخلين"
    },
    {
      "surah_number": 66,
      "verse_number": 11,
      "content": "وضرب الله مثلا للذين امنوا امرأت فرعون اذ قالت رب ابن لي عندك بيتا في الجنه ونجني من فرعون وعمله ونجني من القوم الظالمين"
    },
    {
      "surah_number": 66,
      "verse_number": 12,
      "content": "ومريم ابنت عمران التي أحصنت فرجها فنفخنا فيه من روحنا وصدقت بكلمات ربها وكتبه وكانت من القانتين"
    },
    {
      "surah_number": 67,
      "verse_number": 1,
      "content": "تبارك الذي بيده الملك وهو علىا كل شي قدير"
    },
    {
      "surah_number": 67,
      "verse_number": 2,
      "content": "الذي خلق الموت والحيواه ليبلوكم أيكم أحسن عملا وهو العزيز الغفور"
    },
    {
      "surah_number": 67,
      "verse_number": 3,
      "content": "الذي خلق سبع سماوات طباقا ما ترىا في خلق الرحمان من تفاوت فارجع البصر هل ترىا من فطور"
    },
    {
      "surah_number": 67,
      "verse_number": 4,
      "content": "ثم ارجع البصر كرتين ينقلب اليك البصر خاسئا وهو حسير"
    },
    {
      "surah_number": 67,
      "verse_number": 5,
      "content": "ولقد زينا السما الدنيا بمصابيح وجعلناها رجوما للشياطين وأعتدنا لهم عذاب السعير"
    },
    {
      "surah_number": 67,
      "verse_number": 6,
      "content": "وللذين كفروا بربهم عذاب جهنم وبئس المصير"
    },
    {
      "surah_number": 67,
      "verse_number": 7,
      "content": "اذا ألقوا فيها سمعوا لها شهيقا وهي تفور"
    },
    {
      "surah_number": 67,
      "verse_number": 8,
      "content": "تكاد تميز من الغيظ كلما ألقي فيها فوج سألهم خزنتها ألم يأتكم نذير"
    },
    {
      "surah_number": 67,
      "verse_number": 9,
      "content": "قالوا بلىا قد جانا نذير فكذبنا وقلنا ما نزل الله من شي ان أنتم الا في ضلال كبير"
    },
    {
      "surah_number": 67,
      "verse_number": 10,
      "content": "وقالوا لو كنا نسمع أو نعقل ما كنا في أصحاب السعير"
    },
    {
      "surah_number": 67,
      "verse_number": 11,
      "content": "فاعترفوا بذنبهم فسحقا لأصحاب السعير"
    },
    {
      "surah_number": 67,
      "verse_number": 12,
      "content": "ان الذين يخشون ربهم بالغيب لهم مغفره وأجر كبير"
    },
    {
      "surah_number": 67,
      "verse_number": 13,
      "content": "وأسروا قولكم أو اجهروا به انه عليم بذات الصدور"
    },
    {
      "surah_number": 67,
      "verse_number": 14,
      "content": "ألا يعلم من خلق وهو اللطيف الخبير"
    },
    {
      "surah_number": 67,
      "verse_number": 15,
      "content": "هو الذي جعل لكم الأرض ذلولا فامشوا في مناكبها وكلوا من رزقه واليه النشور"
    },
    {
      "surah_number": 67,
      "verse_number": 16,
      "content": "ءأمنتم من في السما أن يخسف بكم الأرض فاذا هي تمور"
    },
    {
      "surah_number": 67,
      "verse_number": 17,
      "content": "أم أمنتم من في السما أن يرسل عليكم حاصبا فستعلمون كيف نذير"
    },
    {
      "surah_number": 67,
      "verse_number": 18,
      "content": "ولقد كذب الذين من قبلهم فكيف كان نكير"
    },
    {
      "surah_number": 67,
      "verse_number": 19,
      "content": "أولم يروا الى الطير فوقهم صافات ويقبضن ما يمسكهن الا الرحمان انه بكل شي بصير"
    },
    {
      "surah_number": 67,
      "verse_number": 20,
      "content": "أمن هاذا الذي هو جند لكم ينصركم من دون الرحمان ان الكافرون الا في غرور"
    },
    {
      "surah_number": 67,
      "verse_number": 21,
      "content": "أمن هاذا الذي يرزقكم ان أمسك رزقه بل لجوا في عتو ونفور"
    },
    {
      "surah_number": 67,
      "verse_number": 22,
      "content": "أفمن يمشي مكبا علىا وجهه أهدىا أمن يمشي سويا علىا صراط مستقيم"
    },
    {
      "surah_number": 67,
      "verse_number": 23,
      "content": "قل هو الذي أنشأكم وجعل لكم السمع والأبصار والأفٔده قليلا ما تشكرون"
    },
    {
      "surah_number": 67,
      "verse_number": 24,
      "content": "قل هو الذي ذرأكم في الأرض واليه تحشرون"
    },
    {
      "surah_number": 67,
      "verse_number": 25,
      "content": "ويقولون متىا هاذا الوعد ان كنتم صادقين"
    },
    {
      "surah_number": 67,
      "verse_number": 26,
      "content": "قل انما العلم عند الله وانما أنا نذير مبين"
    },
    {
      "surah_number": 67,
      "verse_number": 27,
      "content": "فلما رأوه زلفه سئت وجوه الذين كفروا وقيل هاذا الذي كنتم به تدعون"
    },
    {
      "surah_number": 67,
      "verse_number": 28,
      "content": "قل أريتم ان أهلكني الله ومن معي أو رحمنا فمن يجير الكافرين من عذاب أليم"
    },
    {
      "surah_number": 67,
      "verse_number": 29,
      "content": "قل هو الرحمان امنا به وعليه توكلنا فستعلمون من هو في ضلال مبين"
    },
    {
      "surah_number": 67,
      "verse_number": 30,
      "content": "قل أريتم ان أصبح ماؤكم غورا فمن يأتيكم بما معين"
    },
    {
      "surah_number": 68,
      "verse_number": 1,
      "content": "ن والقلم وما يسطرون"
    },
    {
      "surah_number": 68,
      "verse_number": 2,
      "content": "ما أنت بنعمه ربك بمجنون"
    },
    {
      "surah_number": 68,
      "verse_number": 3,
      "content": "وان لك لأجرا غير ممنون"
    },
    {
      "surah_number": 68,
      "verse_number": 4,
      "content": "وانك لعلىا خلق عظيم"
    },
    {
      "surah_number": 68,
      "verse_number": 5,
      "content": "فستبصر ويبصرون"
    },
    {
      "surah_number": 68,
      "verse_number": 6,
      "content": "بأييكم المفتون"
    },
    {
      "surah_number": 68,
      "verse_number": 7,
      "content": "ان ربك هو أعلم بمن ضل عن سبيله وهو أعلم بالمهتدين"
    },
    {
      "surah_number": 68,
      "verse_number": 8,
      "content": "فلا تطع المكذبين"
    },
    {
      "surah_number": 68,
      "verse_number": 9,
      "content": "ودوا لو تدهن فيدهنون"
    },
    {
      "surah_number": 68,
      "verse_number": 10,
      "content": "ولا تطع كل حلاف مهين"
    },
    {
      "surah_number": 68,
      "verse_number": 11,
      "content": "هماز مشا بنميم"
    },
    {
      "surah_number": 68,
      "verse_number": 12,
      "content": "مناع للخير معتد أثيم"
    },
    {
      "surah_number": 68,
      "verse_number": 13,
      "content": "عتل بعد ذالك زنيم"
    },
    {
      "surah_number": 68,
      "verse_number": 14,
      "content": "أن كان ذا مال وبنين"
    },
    {
      "surah_number": 68,
      "verse_number": 15,
      "content": "اذا تتلىا عليه اياتنا قال أساطير الأولين"
    },
    {
      "surah_number": 68,
      "verse_number": 16,
      "content": "سنسمه على الخرطوم"
    },
    {
      "surah_number": 68,
      "verse_number": 17,
      "content": "انا بلوناهم كما بلونا أصحاب الجنه اذ أقسموا ليصرمنها مصبحين"
    },
    {
      "surah_number": 68,
      "verse_number": 18,
      "content": "ولا يستثنون"
    },
    {
      "surah_number": 68,
      "verse_number": 19,
      "content": "فطاف عليها طائف من ربك وهم نائمون"
    },
    {
      "surah_number": 68,
      "verse_number": 20,
      "content": "فأصبحت كالصريم"
    },
    {
      "surah_number": 68,
      "verse_number": 21,
      "content": "فتنادوا مصبحين"
    },
    {
      "surah_number": 68,
      "verse_number": 22,
      "content": "أن اغدوا علىا حرثكم ان كنتم صارمين"
    },
    {
      "surah_number": 68,
      "verse_number": 23,
      "content": "فانطلقوا وهم يتخافتون"
    },
    {
      "surah_number": 68,
      "verse_number": 24,
      "content": "أن لا يدخلنها اليوم عليكم مسكين"
    },
    {
      "surah_number": 68,
      "verse_number": 25,
      "content": "وغدوا علىا حرد قادرين"
    },
    {
      "surah_number": 68,
      "verse_number": 26,
      "content": "فلما رأوها قالوا انا لضالون"
    },
    {
      "surah_number": 68,
      "verse_number": 27,
      "content": "بل نحن محرومون"
    },
    {
      "surah_number": 68,
      "verse_number": 28,
      "content": "قال أوسطهم ألم أقل لكم لولا تسبحون"
    },
    {
      "surah_number": 68,
      "verse_number": 29,
      "content": "قالوا سبحان ربنا انا كنا ظالمين"
    },
    {
      "surah_number": 68,
      "verse_number": 30,
      "content": "فأقبل بعضهم علىا بعض يتلاومون"
    },
    {
      "surah_number": 68,
      "verse_number": 31,
      "content": "قالوا ياويلنا انا كنا طاغين"
    },
    {
      "surah_number": 68,
      "verse_number": 32,
      "content": "عسىا ربنا أن يبدلنا خيرا منها انا الىا ربنا راغبون"
    },
    {
      "surah_number": 68,
      "verse_number": 33,
      "content": "كذالك العذاب ولعذاب الأخره أكبر لو كانوا يعلمون"
    },
    {
      "surah_number": 68,
      "verse_number": 34,
      "content": "ان للمتقين عند ربهم جنات النعيم"
    },
    {
      "surah_number": 68,
      "verse_number": 35,
      "content": "أفنجعل المسلمين كالمجرمين"
    },
    {
      "surah_number": 68,
      "verse_number": 36,
      "content": "ما لكم كيف تحكمون"
    },
    {
      "surah_number": 68,
      "verse_number": 37,
      "content": "أم لكم كتاب فيه تدرسون"
    },
    {
      "surah_number": 68,
      "verse_number": 38,
      "content": "ان لكم فيه لما تخيرون"
    },
    {
      "surah_number": 68,
      "verse_number": 39,
      "content": "أم لكم أيمان علينا بالغه الىا يوم القيامه ان لكم لما تحكمون"
    },
    {
      "surah_number": 68,
      "verse_number": 40,
      "content": "سلهم أيهم بذالك زعيم"
    },
    {
      "surah_number": 68,
      "verse_number": 41,
      "content": "أم لهم شركا فليأتوا بشركائهم ان كانوا صادقين"
    },
    {
      "surah_number": 68,
      "verse_number": 42,
      "content": "يوم يكشف عن ساق ويدعون الى السجود فلا يستطيعون"
    },
    {
      "surah_number": 68,
      "verse_number": 43,
      "content": "خاشعه أبصارهم ترهقهم ذله وقد كانوا يدعون الى السجود وهم سالمون"
    },
    {
      "surah_number": 68,
      "verse_number": 44,
      "content": "فذرني ومن يكذب بهاذا الحديث سنستدرجهم من حيث لا يعلمون"
    },
    {
      "surah_number": 68,
      "verse_number": 45,
      "content": "وأملي لهم ان كيدي متين"
    },
    {
      "surah_number": 68,
      "verse_number": 46,
      "content": "أم تسٔلهم أجرا فهم من مغرم مثقلون"
    },
    {
      "surah_number": 68,
      "verse_number": 47,
      "content": "أم عندهم الغيب فهم يكتبون"
    },
    {
      "surah_number": 68,
      "verse_number": 48,
      "content": "فاصبر لحكم ربك ولا تكن كصاحب الحوت اذ نادىا وهو مكظوم"
    },
    {
      "surah_number": 68,
      "verse_number": 49,
      "content": "لولا أن تداركه نعمه من ربه لنبذ بالعرا وهو مذموم"
    },
    {
      "surah_number": 68,
      "verse_number": 50,
      "content": "فاجتباه ربه فجعله من الصالحين"
    },
    {
      "surah_number": 68,
      "verse_number": 51,
      "content": "وان يكاد الذين كفروا ليزلقونك بأبصارهم لما سمعوا الذكر ويقولون انه لمجنون"
    },
    {
      "surah_number": 68,
      "verse_number": 52,
      "content": "وما هو الا ذكر للعالمين"
    },
    {
      "surah_number": 69,
      "verse_number": 1,
      "content": "الحاقه"
    },
    {
      "surah_number": 69,
      "verse_number": 2,
      "content": "ما الحاقه"
    },
    {
      "surah_number": 69,
      "verse_number": 3,
      "content": "وما أدرىاك ما الحاقه"
    },
    {
      "surah_number": 69,
      "verse_number": 4,
      "content": "كذبت ثمود وعاد بالقارعه"
    },
    {
      "surah_number": 69,
      "verse_number": 5,
      "content": "فأما ثمود فأهلكوا بالطاغيه"
    },
    {
      "surah_number": 69,
      "verse_number": 6,
      "content": "وأما عاد فأهلكوا بريح صرصر عاتيه"
    },
    {
      "surah_number": 69,
      "verse_number": 7,
      "content": "سخرها عليهم سبع ليال وثمانيه أيام حسوما فترى القوم فيها صرعىا كأنهم أعجاز نخل خاويه"
    },
    {
      "surah_number": 69,
      "verse_number": 8,
      "content": "فهل ترىا لهم من باقيه"
    },
    {
      "surah_number": 69,
      "verse_number": 9,
      "content": "وجا فرعون ومن قبله والمؤتفكات بالخاطئه"
    },
    {
      "surah_number": 69,
      "verse_number": 10,
      "content": "فعصوا رسول ربهم فأخذهم أخذه رابيه"
    },
    {
      "surah_number": 69,
      "verse_number": 11,
      "content": "انا لما طغا الما حملناكم في الجاريه"
    },
    {
      "surah_number": 69,
      "verse_number": 12,
      "content": "لنجعلها لكم تذكره وتعيها أذن واعيه"
    },
    {
      "surah_number": 69,
      "verse_number": 13,
      "content": "فاذا نفخ في الصور نفخه واحده"
    },
    {
      "surah_number": 69,
      "verse_number": 14,
      "content": "وحملت الأرض والجبال فدكتا دكه واحده"
    },
    {
      "surah_number": 69,
      "verse_number": 15,
      "content": "فيومئذ وقعت الواقعه"
    },
    {
      "surah_number": 69,
      "verse_number": 16,
      "content": "وانشقت السما فهي يومئذ واهيه"
    },
    {
      "surah_number": 69,
      "verse_number": 17,
      "content": "والملك علىا أرجائها ويحمل عرش ربك فوقهم يومئذ ثمانيه"
    },
    {
      "surah_number": 69,
      "verse_number": 18,
      "content": "يومئذ تعرضون لا تخفىا منكم خافيه"
    },
    {
      "surah_number": 69,
      "verse_number": 19,
      "content": "فأما من أوتي كتابه بيمينه فيقول هاؤم اقروا كتابيه"
    },
    {
      "surah_number": 69,
      "verse_number": 20,
      "content": "اني ظننت أني ملاق حسابيه"
    },
    {
      "surah_number": 69,
      "verse_number": 21,
      "content": "فهو في عيشه راضيه"
    },
    {
      "surah_number": 69,
      "verse_number": 22,
      "content": "في جنه عاليه"
    },
    {
      "surah_number": 69,
      "verse_number": 23,
      "content": "قطوفها دانيه"
    },
    {
      "surah_number": 69,
      "verse_number": 24,
      "content": "كلوا واشربوا هنئا بما أسلفتم في الأيام الخاليه"
    },
    {
      "surah_number": 69,
      "verse_number": 25,
      "content": "وأما من أوتي كتابه بشماله فيقول ياليتني لم أوت كتابيه"
    },
    {
      "surah_number": 69,
      "verse_number": 26,
      "content": "ولم أدر ما حسابيه"
    },
    {
      "surah_number": 69,
      "verse_number": 27,
      "content": "ياليتها كانت القاضيه"
    },
    {
      "surah_number": 69,
      "verse_number": 28,
      "content": "ما أغنىا عني ماليه"
    },
    {
      "surah_number": 69,
      "verse_number": 29,
      "content": "هلك عني سلطانيه"
    },
    {
      "surah_number": 69,
      "verse_number": 30,
      "content": "خذوه فغلوه"
    },
    {
      "surah_number": 69,
      "verse_number": 31,
      "content": "ثم الجحيم صلوه"
    },
    {
      "surah_number": 69,
      "verse_number": 32,
      "content": "ثم في سلسله ذرعها سبعون ذراعا فاسلكوه"
    },
    {
      "surah_number": 69,
      "verse_number": 33,
      "content": "انه كان لا يؤمن بالله العظيم"
    },
    {
      "surah_number": 69,
      "verse_number": 34,
      "content": "ولا يحض علىا طعام المسكين"
    },
    {
      "surah_number": 69,
      "verse_number": 35,
      "content": "فليس له اليوم هاهنا حميم"
    },
    {
      "surah_number": 69,
      "verse_number": 36,
      "content": "ولا طعام الا من غسلين"
    },
    {
      "surah_number": 69,
      "verse_number": 37,
      "content": "لا يأكله الا الخاطٔون"
    },
    {
      "surah_number": 69,
      "verse_number": 38,
      "content": "فلا أقسم بما تبصرون"
    },
    {
      "surah_number": 69,
      "verse_number": 39,
      "content": "وما لا تبصرون"
    },
    {
      "surah_number": 69,
      "verse_number": 40,
      "content": "انه لقول رسول كريم"
    },
    {
      "surah_number": 69,
      "verse_number": 41,
      "content": "وما هو بقول شاعر قليلا ما تؤمنون"
    },
    {
      "surah_number": 69,
      "verse_number": 42,
      "content": "ولا بقول كاهن قليلا ما تذكرون"
    },
    {
      "surah_number": 69,
      "verse_number": 43,
      "content": "تنزيل من رب العالمين"
    },
    {
      "surah_number": 69,
      "verse_number": 44,
      "content": "ولو تقول علينا بعض الأقاويل"
    },
    {
      "surah_number": 69,
      "verse_number": 45,
      "content": "لأخذنا منه باليمين"
    },
    {
      "surah_number": 69,
      "verse_number": 46,
      "content": "ثم لقطعنا منه الوتين"
    },
    {
      "surah_number": 69,
      "verse_number": 47,
      "content": "فما منكم من أحد عنه حاجزين"
    },
    {
      "surah_number": 69,
      "verse_number": 48,
      "content": "وانه لتذكره للمتقين"
    },
    {
      "surah_number": 69,
      "verse_number": 49,
      "content": "وانا لنعلم أن منكم مكذبين"
    },
    {
      "surah_number": 69,
      "verse_number": 50,
      "content": "وانه لحسره على الكافرين"
    },
    {
      "surah_number": 69,
      "verse_number": 51,
      "content": "وانه لحق اليقين"
    },
    {
      "surah_number": 69,
      "verse_number": 52,
      "content": "فسبح باسم ربك العظيم"
    },
    {
      "surah_number": 70,
      "verse_number": 1,
      "content": "سأل سائل بعذاب واقع"
    },
    {
      "surah_number": 70,
      "verse_number": 2,
      "content": "للكافرين ليس له دافع"
    },
    {
      "surah_number": 70,
      "verse_number": 3,
      "content": "من الله ذي المعارج"
    },
    {
      "surah_number": 70,
      "verse_number": 4,
      "content": "تعرج الملائكه والروح اليه في يوم كان مقداره خمسين ألف سنه"
    },
    {
      "surah_number": 70,
      "verse_number": 5,
      "content": "فاصبر صبرا جميلا"
    },
    {
      "surah_number": 70,
      "verse_number": 6,
      "content": "انهم يرونه بعيدا"
    },
    {
      "surah_number": 70,
      "verse_number": 7,
      "content": "ونرىاه قريبا"
    },
    {
      "surah_number": 70,
      "verse_number": 8,
      "content": "يوم تكون السما كالمهل"
    },
    {
      "surah_number": 70,
      "verse_number": 9,
      "content": "وتكون الجبال كالعهن"
    },
    {
      "surah_number": 70,
      "verse_number": 10,
      "content": "ولا يسٔل حميم حميما"
    },
    {
      "surah_number": 70,
      "verse_number": 11,
      "content": "يبصرونهم يود المجرم لو يفتدي من عذاب يومئذ ببنيه"
    },
    {
      "surah_number": 70,
      "verse_number": 12,
      "content": "وصاحبته وأخيه"
    },
    {
      "surah_number": 70,
      "verse_number": 13,
      "content": "وفصيلته التي تٔويه"
    },
    {
      "surah_number": 70,
      "verse_number": 14,
      "content": "ومن في الأرض جميعا ثم ينجيه"
    },
    {
      "surah_number": 70,
      "verse_number": 15,
      "content": "كلا انها لظىا"
    },
    {
      "surah_number": 70,
      "verse_number": 16,
      "content": "نزاعه للشوىا"
    },
    {
      "surah_number": 70,
      "verse_number": 17,
      "content": "تدعوا من أدبر وتولىا"
    },
    {
      "surah_number": 70,
      "verse_number": 18,
      "content": "وجمع فأوعىا"
    },
    {
      "surah_number": 70,
      "verse_number": 19,
      "content": "ان الانسان خلق هلوعا"
    },
    {
      "surah_number": 70,
      "verse_number": 20,
      "content": "اذا مسه الشر جزوعا"
    },
    {
      "surah_number": 70,
      "verse_number": 21,
      "content": "واذا مسه الخير منوعا"
    },
    {
      "surah_number": 70,
      "verse_number": 22,
      "content": "الا المصلين"
    },
    {
      "surah_number": 70,
      "verse_number": 23,
      "content": "الذين هم علىا صلاتهم دائمون"
    },
    {
      "surah_number": 70,
      "verse_number": 24,
      "content": "والذين في أموالهم حق معلوم"
    },
    {
      "surah_number": 70,
      "verse_number": 25,
      "content": "للسائل والمحروم"
    },
    {
      "surah_number": 70,
      "verse_number": 26,
      "content": "والذين يصدقون بيوم الدين"
    },
    {
      "surah_number": 70,
      "verse_number": 27,
      "content": "والذين هم من عذاب ربهم مشفقون"
    },
    {
      "surah_number": 70,
      "verse_number": 28,
      "content": "ان عذاب ربهم غير مأمون"
    },
    {
      "surah_number": 70,
      "verse_number": 29,
      "content": "والذين هم لفروجهم حافظون"
    },
    {
      "surah_number": 70,
      "verse_number": 30,
      "content": "الا علىا أزواجهم أو ما ملكت أيمانهم فانهم غير ملومين"
    },
    {
      "surah_number": 70,
      "verse_number": 31,
      "content": "فمن ابتغىا ورا ذالك فأولائك هم العادون"
    },
    {
      "surah_number": 70,
      "verse_number": 32,
      "content": "والذين هم لأماناتهم وعهدهم راعون"
    },
    {
      "surah_number": 70,
      "verse_number": 33,
      "content": "والذين هم بشهاداتهم قائمون"
    },
    {
      "surah_number": 70,
      "verse_number": 34,
      "content": "والذين هم علىا صلاتهم يحافظون"
    },
    {
      "surah_number": 70,
      "verse_number": 35,
      "content": "أولائك في جنات مكرمون"
    },
    {
      "surah_number": 70,
      "verse_number": 36,
      "content": "فمال الذين كفروا قبلك مهطعين"
    },
    {
      "surah_number": 70,
      "verse_number": 37,
      "content": "عن اليمين وعن الشمال عزين"
    },
    {
      "surah_number": 70,
      "verse_number": 38,
      "content": "أيطمع كل امري منهم أن يدخل جنه نعيم"
    },
    {
      "surah_number": 70,
      "verse_number": 39,
      "content": "كلا انا خلقناهم مما يعلمون"
    },
    {
      "surah_number": 70,
      "verse_number": 40,
      "content": "فلا أقسم برب المشارق والمغارب انا لقادرون"
    },
    {
      "surah_number": 70,
      "verse_number": 41,
      "content": "علىا أن نبدل خيرا منهم وما نحن بمسبوقين"
    },
    {
      "surah_number": 70,
      "verse_number": 42,
      "content": "فذرهم يخوضوا ويلعبوا حتىا يلاقوا يومهم الذي يوعدون"
    },
    {
      "surah_number": 70,
      "verse_number": 43,
      "content": "يوم يخرجون من الأجداث سراعا كأنهم الىا نصب يوفضون"
    },
    {
      "surah_number": 70,
      "verse_number": 44,
      "content": "خاشعه أبصارهم ترهقهم ذله ذالك اليوم الذي كانوا يوعدون"
    },
    {
      "surah_number": 71,
      "verse_number": 1,
      "content": "انا أرسلنا نوحا الىا قومه أن أنذر قومك من قبل أن يأتيهم عذاب أليم"
    },
    {
      "surah_number": 71,
      "verse_number": 2,
      "content": "قال ياقوم اني لكم نذير مبين"
    },
    {
      "surah_number": 71,
      "verse_number": 3,
      "content": "أن اعبدوا الله واتقوه وأطيعون"
    },
    {
      "surah_number": 71,
      "verse_number": 4,
      "content": "يغفر لكم من ذنوبكم ويؤخركم الىا أجل مسمى ان أجل الله اذا جا لا يؤخر لو كنتم تعلمون"
    },
    {
      "surah_number": 71,
      "verse_number": 5,
      "content": "قال رب اني دعوت قومي ليلا ونهارا"
    },
    {
      "surah_number": 71,
      "verse_number": 6,
      "content": "فلم يزدهم دعاي الا فرارا"
    },
    {
      "surah_number": 71,
      "verse_number": 7,
      "content": "واني كلما دعوتهم لتغفر لهم جعلوا أصابعهم في اذانهم واستغشوا ثيابهم وأصروا واستكبروا استكبارا"
    },
    {
      "surah_number": 71,
      "verse_number": 8,
      "content": "ثم اني دعوتهم جهارا"
    },
    {
      "surah_number": 71,
      "verse_number": 9,
      "content": "ثم اني أعلنت لهم وأسررت لهم اسرارا"
    },
    {
      "surah_number": 71,
      "verse_number": 10,
      "content": "فقلت استغفروا ربكم انه كان غفارا"
    },
    {
      "surah_number": 71,
      "verse_number": 11,
      "content": "يرسل السما عليكم مدرارا"
    },
    {
      "surah_number": 71,
      "verse_number": 12,
      "content": "ويمددكم بأموال وبنين ويجعل لكم جنات ويجعل لكم أنهارا"
    },
    {
      "surah_number": 71,
      "verse_number": 13,
      "content": "ما لكم لا ترجون لله وقارا"
    },
    {
      "surah_number": 71,
      "verse_number": 14,
      "content": "وقد خلقكم أطوارا"
    },
    {
      "surah_number": 71,
      "verse_number": 15,
      "content": "ألم تروا كيف خلق الله سبع سماوات طباقا"
    },
    {
      "surah_number": 71,
      "verse_number": 16,
      "content": "وجعل القمر فيهن نورا وجعل الشمس سراجا"
    },
    {
      "surah_number": 71,
      "verse_number": 17,
      "content": "والله أنبتكم من الأرض نباتا"
    },
    {
      "surah_number": 71,
      "verse_number": 18,
      "content": "ثم يعيدكم فيها ويخرجكم اخراجا"
    },
    {
      "surah_number": 71,
      "verse_number": 19,
      "content": "والله جعل لكم الأرض بساطا"
    },
    {
      "surah_number": 71,
      "verse_number": 20,
      "content": "لتسلكوا منها سبلا فجاجا"
    },
    {
      "surah_number": 71,
      "verse_number": 21,
      "content": "قال نوح رب انهم عصوني واتبعوا من لم يزده ماله وولده الا خسارا"
    },
    {
      "surah_number": 71,
      "verse_number": 22,
      "content": "ومكروا مكرا كبارا"
    },
    {
      "surah_number": 71,
      "verse_number": 23,
      "content": "وقالوا لا تذرن الهتكم ولا تذرن ودا ولا سواعا ولا يغوث ويعوق ونسرا"
    },
    {
      "surah_number": 71,
      "verse_number": 24,
      "content": "وقد أضلوا كثيرا ولا تزد الظالمين الا ضلالا"
    },
    {
      "surah_number": 71,
      "verse_number": 25,
      "content": "مما خطئاتهم أغرقوا فأدخلوا نارا فلم يجدوا لهم من دون الله أنصارا"
    },
    {
      "surah_number": 71,
      "verse_number": 26,
      "content": "وقال نوح رب لا تذر على الأرض من الكافرين ديارا"
    },
    {
      "surah_number": 71,
      "verse_number": 27,
      "content": "انك ان تذرهم يضلوا عبادك ولا يلدوا الا فاجرا كفارا"
    },
    {
      "surah_number": 71,
      "verse_number": 28,
      "content": "رب اغفر لي ولوالدي ولمن دخل بيتي مؤمنا وللمؤمنين والمؤمنات ولا تزد الظالمين الا تبارا"
    },
    {
      "surah_number": 72,
      "verse_number": 1,
      "content": "قل أوحي الي أنه استمع نفر من الجن فقالوا انا سمعنا قرانا عجبا"
    },
    {
      "surah_number": 72,
      "verse_number": 2,
      "content": "يهدي الى الرشد فٔامنا به ولن نشرك بربنا أحدا"
    },
    {
      "surah_number": 72,
      "verse_number": 3,
      "content": "وأنه تعالىا جد ربنا ما اتخذ صاحبه ولا ولدا"
    },
    {
      "surah_number": 72,
      "verse_number": 4,
      "content": "وأنه كان يقول سفيهنا على الله شططا"
    },
    {
      "surah_number": 72,
      "verse_number": 5,
      "content": "وأنا ظننا أن لن تقول الانس والجن على الله كذبا"
    },
    {
      "surah_number": 72,
      "verse_number": 6,
      "content": "وأنه كان رجال من الانس يعوذون برجال من الجن فزادوهم رهقا"
    },
    {
      "surah_number": 72,
      "verse_number": 7,
      "content": "وأنهم ظنوا كما ظننتم أن لن يبعث الله أحدا"
    },
    {
      "surah_number": 72,
      "verse_number": 8,
      "content": "وأنا لمسنا السما فوجدناها ملئت حرسا شديدا وشهبا"
    },
    {
      "surah_number": 72,
      "verse_number": 9,
      "content": "وأنا كنا نقعد منها مقاعد للسمع فمن يستمع الأن يجد له شهابا رصدا"
    },
    {
      "surah_number": 72,
      "verse_number": 10,
      "content": "وأنا لا ندري أشر أريد بمن في الأرض أم أراد بهم ربهم رشدا"
    },
    {
      "surah_number": 72,
      "verse_number": 11,
      "content": "وأنا منا الصالحون ومنا دون ذالك كنا طرائق قددا"
    },
    {
      "surah_number": 72,
      "verse_number": 12,
      "content": "وأنا ظننا أن لن نعجز الله في الأرض ولن نعجزه هربا"
    },
    {
      "surah_number": 72,
      "verse_number": 13,
      "content": "وأنا لما سمعنا الهدىا امنا به فمن يؤمن بربه فلا يخاف بخسا ولا رهقا"
    },
    {
      "surah_number": 72,
      "verse_number": 14,
      "content": "وأنا منا المسلمون ومنا القاسطون فمن أسلم فأولائك تحروا رشدا"
    },
    {
      "surah_number": 72,
      "verse_number": 15,
      "content": "وأما القاسطون فكانوا لجهنم حطبا"
    },
    {
      "surah_number": 72,
      "verse_number": 16,
      "content": "وألو استقاموا على الطريقه لأسقيناهم ما غدقا"
    },
    {
      "surah_number": 72,
      "verse_number": 17,
      "content": "لنفتنهم فيه ومن يعرض عن ذكر ربه يسلكه عذابا صعدا"
    },
    {
      "surah_number": 72,
      "verse_number": 18,
      "content": "وأن المساجد لله فلا تدعوا مع الله أحدا"
    },
    {
      "surah_number": 72,
      "verse_number": 19,
      "content": "وأنه لما قام عبد الله يدعوه كادوا يكونون عليه لبدا"
    },
    {
      "surah_number": 72,
      "verse_number": 20,
      "content": "قل انما أدعوا ربي ولا أشرك به أحدا"
    },
    {
      "surah_number": 72,
      "verse_number": 21,
      "content": "قل اني لا أملك لكم ضرا ولا رشدا"
    },
    {
      "surah_number": 72,
      "verse_number": 22,
      "content": "قل اني لن يجيرني من الله أحد ولن أجد من دونه ملتحدا"
    },
    {
      "surah_number": 72,
      "verse_number": 23,
      "content": "الا بلاغا من الله ورسالاته ومن يعص الله ورسوله فان له نار جهنم خالدين فيها أبدا"
    },
    {
      "surah_number": 72,
      "verse_number": 24,
      "content": "حتىا اذا رأوا ما يوعدون فسيعلمون من أضعف ناصرا وأقل عددا"
    },
    {
      "surah_number": 72,
      "verse_number": 25,
      "content": "قل ان أدري أقريب ما توعدون أم يجعل له ربي أمدا"
    },
    {
      "surah_number": 72,
      "verse_number": 26,
      "content": "عالم الغيب فلا يظهر علىا غيبه أحدا"
    },
    {
      "surah_number": 72,
      "verse_number": 27,
      "content": "الا من ارتضىا من رسول فانه يسلك من بين يديه ومن خلفه رصدا"
    },
    {
      "surah_number": 72,
      "verse_number": 28,
      "content": "ليعلم أن قد أبلغوا رسالات ربهم وأحاط بما لديهم وأحصىا كل شي عددا"
    },
    {
      "surah_number": 73,
      "verse_number": 1,
      "content": "ياأيها المزمل"
    },
    {
      "surah_number": 73,
      "verse_number": 2,
      "content": "قم اليل الا قليلا"
    },
    {
      "surah_number": 73,
      "verse_number": 3,
      "content": "نصفه أو انقص منه قليلا"
    },
    {
      "surah_number": 73,
      "verse_number": 4,
      "content": "أو زد عليه ورتل القران ترتيلا"
    },
    {
      "surah_number": 73,
      "verse_number": 5,
      "content": "انا سنلقي عليك قولا ثقيلا"
    },
    {
      "surah_number": 73,
      "verse_number": 6,
      "content": "ان ناشئه اليل هي أشد وطٔا وأقوم قيلا"
    },
    {
      "surah_number": 73,
      "verse_number": 7,
      "content": "ان لك في النهار سبحا طويلا"
    },
    {
      "surah_number": 73,
      "verse_number": 8,
      "content": "واذكر اسم ربك وتبتل اليه تبتيلا"
    },
    {
      "surah_number": 73,
      "verse_number": 9,
      "content": "رب المشرق والمغرب لا الاه الا هو فاتخذه وكيلا"
    },
    {
      "surah_number": 73,
      "verse_number": 10,
      "content": "واصبر علىا ما يقولون واهجرهم هجرا جميلا"
    },
    {
      "surah_number": 73,
      "verse_number": 11,
      "content": "وذرني والمكذبين أولي النعمه ومهلهم قليلا"
    },
    {
      "surah_number": 73,
      "verse_number": 12,
      "content": "ان لدينا أنكالا وجحيما"
    },
    {
      "surah_number": 73,
      "verse_number": 13,
      "content": "وطعاما ذا غصه وعذابا أليما"
    },
    {
      "surah_number": 73,
      "verse_number": 14,
      "content": "يوم ترجف الأرض والجبال وكانت الجبال كثيبا مهيلا"
    },
    {
      "surah_number": 73,
      "verse_number": 15,
      "content": "انا أرسلنا اليكم رسولا شاهدا عليكم كما أرسلنا الىا فرعون رسولا"
    },
    {
      "surah_number": 73,
      "verse_number": 16,
      "content": "فعصىا فرعون الرسول فأخذناه أخذا وبيلا"
    },
    {
      "surah_number": 73,
      "verse_number": 17,
      "content": "فكيف تتقون ان كفرتم يوما يجعل الولدان شيبا"
    },
    {
      "surah_number": 73,
      "verse_number": 18,
      "content": "السما منفطر به كان وعده مفعولا"
    },
    {
      "surah_number": 73,
      "verse_number": 19,
      "content": "ان هاذه تذكره فمن شا اتخذ الىا ربه سبيلا"
    },
    {
      "surah_number": 73,
      "verse_number": 20,
      "content": "ان ربك يعلم أنك تقوم أدنىا من ثلثي اليل ونصفه وثلثه وطائفه من الذين معك والله يقدر اليل والنهار علم أن لن تحصوه فتاب عليكم فاقروا ما تيسر من القران علم أن سيكون منكم مرضىا واخرون يضربون في الأرض يبتغون من فضل الله واخرون يقاتلون في سبيل الله فاقروا ما تيسر منه وأقيموا الصلواه واتوا الزكواه وأقرضوا الله قرضا حسنا وما تقدموا لأنفسكم من خير تجدوه عند الله هو خيرا وأعظم أجرا واستغفروا الله ان الله غفور رحيم"
    },
    {
      "surah_number": 74,
      "verse_number": 1,
      "content": "ياأيها المدثر"
    },
    {
      "surah_number": 74,
      "verse_number": 2,
      "content": "قم فأنذر"
    },
    {
      "surah_number": 74,
      "verse_number": 3,
      "content": "وربك فكبر"
    },
    {
      "surah_number": 74,
      "verse_number": 4,
      "content": "وثيابك فطهر"
    },
    {
      "surah_number": 74,
      "verse_number": 5,
      "content": "والرجز فاهجر"
    },
    {
      "surah_number": 74,
      "verse_number": 6,
      "content": "ولا تمنن تستكثر"
    },
    {
      "surah_number": 74,
      "verse_number": 7,
      "content": "ولربك فاصبر"
    },
    {
      "surah_number": 74,
      "verse_number": 8,
      "content": "فاذا نقر في الناقور"
    },
    {
      "surah_number": 74,
      "verse_number": 9,
      "content": "فذالك يومئذ يوم عسير"
    },
    {
      "surah_number": 74,
      "verse_number": 10,
      "content": "على الكافرين غير يسير"
    },
    {
      "surah_number": 74,
      "verse_number": 11,
      "content": "ذرني ومن خلقت وحيدا"
    },
    {
      "surah_number": 74,
      "verse_number": 12,
      "content": "وجعلت له مالا ممدودا"
    },
    {
      "surah_number": 74,
      "verse_number": 13,
      "content": "وبنين شهودا"
    },
    {
      "surah_number": 74,
      "verse_number": 14,
      "content": "ومهدت له تمهيدا"
    },
    {
      "surah_number": 74,
      "verse_number": 15,
      "content": "ثم يطمع أن أزيد"
    },
    {
      "surah_number": 74,
      "verse_number": 16,
      "content": "كلا انه كان لأياتنا عنيدا"
    },
    {
      "surah_number": 74,
      "verse_number": 17,
      "content": "سأرهقه صعودا"
    },
    {
      "surah_number": 74,
      "verse_number": 18,
      "content": "انه فكر وقدر"
    },
    {
      "surah_number": 74,
      "verse_number": 19,
      "content": "فقتل كيف قدر"
    },
    {
      "surah_number": 74,
      "verse_number": 20,
      "content": "ثم قتل كيف قدر"
    },
    {
      "surah_number": 74,
      "verse_number": 21,
      "content": "ثم نظر"
    },
    {
      "surah_number": 74,
      "verse_number": 22,
      "content": "ثم عبس وبسر"
    },
    {
      "surah_number": 74,
      "verse_number": 23,
      "content": "ثم أدبر واستكبر"
    },
    {
      "surah_number": 74,
      "verse_number": 24,
      "content": "فقال ان هاذا الا سحر يؤثر"
    },
    {
      "surah_number": 74,
      "verse_number": 25,
      "content": "ان هاذا الا قول البشر"
    },
    {
      "surah_number": 74,
      "verse_number": 26,
      "content": "سأصليه سقر"
    },
    {
      "surah_number": 74,
      "verse_number": 27,
      "content": "وما أدرىاك ما سقر"
    },
    {
      "surah_number": 74,
      "verse_number": 28,
      "content": "لا تبقي ولا تذر"
    },
    {
      "surah_number": 74,
      "verse_number": 29,
      "content": "لواحه للبشر"
    },
    {
      "surah_number": 74,
      "verse_number": 30,
      "content": "عليها تسعه عشر"
    },
    {
      "surah_number": 74,
      "verse_number": 31,
      "content": "وما جعلنا أصحاب النار الا ملائكه وما جعلنا عدتهم الا فتنه للذين كفروا ليستيقن الذين أوتوا الكتاب ويزداد الذين امنوا ايمانا ولا يرتاب الذين أوتوا الكتاب والمؤمنون وليقول الذين في قلوبهم مرض والكافرون ماذا أراد الله بهاذا مثلا كذالك يضل الله من يشا ويهدي من يشا وما يعلم جنود ربك الا هو وما هي الا ذكرىا للبشر"
    },
    {
      "surah_number": 74,
      "verse_number": 32,
      "content": "كلا والقمر"
    },
    {
      "surah_number": 74,
      "verse_number": 33,
      "content": "واليل اذ أدبر"
    },
    {
      "surah_number": 74,
      "verse_number": 34,
      "content": "والصبح اذا أسفر"
    },
    {
      "surah_number": 74,
      "verse_number": 35,
      "content": "انها لاحدى الكبر"
    },
    {
      "surah_number": 74,
      "verse_number": 36,
      "content": "نذيرا للبشر"
    },
    {
      "surah_number": 74,
      "verse_number": 37,
      "content": "لمن شا منكم أن يتقدم أو يتأخر"
    },
    {
      "surah_number": 74,
      "verse_number": 38,
      "content": "كل نفس بما كسبت رهينه"
    },
    {
      "surah_number": 74,
      "verse_number": 39,
      "content": "الا أصحاب اليمين"
    },
    {
      "surah_number": 74,
      "verse_number": 40,
      "content": "في جنات يتسالون"
    },
    {
      "surah_number": 74,
      "verse_number": 41,
      "content": "عن المجرمين"
    },
    {
      "surah_number": 74,
      "verse_number": 42,
      "content": "ما سلككم في سقر"
    },
    {
      "surah_number": 74,
      "verse_number": 43,
      "content": "قالوا لم نك من المصلين"
    },
    {
      "surah_number": 74,
      "verse_number": 44,
      "content": "ولم نك نطعم المسكين"
    },
    {
      "surah_number": 74,
      "verse_number": 45,
      "content": "وكنا نخوض مع الخائضين"
    },
    {
      "surah_number": 74,
      "verse_number": 46,
      "content": "وكنا نكذب بيوم الدين"
    },
    {
      "surah_number": 74,
      "verse_number": 47,
      "content": "حتىا أتىانا اليقين"
    },
    {
      "surah_number": 74,
      "verse_number": 48,
      "content": "فما تنفعهم شفاعه الشافعين"
    },
    {
      "surah_number": 74,
      "verse_number": 49,
      "content": "فما لهم عن التذكره معرضين"
    },
    {
      "surah_number": 74,
      "verse_number": 50,
      "content": "كأنهم حمر مستنفره"
    },
    {
      "surah_number": 74,
      "verse_number": 51,
      "content": "فرت من قسوره"
    },
    {
      "surah_number": 74,
      "verse_number": 52,
      "content": "بل يريد كل امري منهم أن يؤتىا صحفا منشره"
    },
    {
      "surah_number": 74,
      "verse_number": 53,
      "content": "كلا بل لا يخافون الأخره"
    },
    {
      "surah_number": 74,
      "verse_number": 54,
      "content": "كلا انه تذكره"
    },
    {
      "surah_number": 74,
      "verse_number": 55,
      "content": "فمن شا ذكره"
    },
    {
      "surah_number": 74,
      "verse_number": 56,
      "content": "وما يذكرون الا أن يشا الله هو أهل التقوىا وأهل المغفره"
    },
    {
      "surah_number": 75,
      "verse_number": 1,
      "content": "لا أقسم بيوم القيامه"
    },
    {
      "surah_number": 75,
      "verse_number": 2,
      "content": "ولا أقسم بالنفس اللوامه"
    },
    {
      "surah_number": 75,
      "verse_number": 3,
      "content": "أيحسب الانسان ألن نجمع عظامه"
    },
    {
      "surah_number": 75,
      "verse_number": 4,
      "content": "بلىا قادرين علىا أن نسوي بنانه"
    },
    {
      "surah_number": 75,
      "verse_number": 5,
      "content": "بل يريد الانسان ليفجر أمامه"
    },
    {
      "surah_number": 75,
      "verse_number": 6,
      "content": "يسٔل أيان يوم القيامه"
    },
    {
      "surah_number": 75,
      "verse_number": 7,
      "content": "فاذا برق البصر"
    },
    {
      "surah_number": 75,
      "verse_number": 8,
      "content": "وخسف القمر"
    },
    {
      "surah_number": 75,
      "verse_number": 9,
      "content": "وجمع الشمس والقمر"
    },
    {
      "surah_number": 75,
      "verse_number": 10,
      "content": "يقول الانسان يومئذ أين المفر"
    },
    {
      "surah_number": 75,
      "verse_number": 11,
      "content": "كلا لا وزر"
    },
    {
      "surah_number": 75,
      "verse_number": 12,
      "content": "الىا ربك يومئذ المستقر"
    },
    {
      "surah_number": 75,
      "verse_number": 13,
      "content": "ينبؤا الانسان يومئذ بما قدم وأخر"
    },
    {
      "surah_number": 75,
      "verse_number": 14,
      "content": "بل الانسان علىا نفسه بصيره"
    },
    {
      "surah_number": 75,
      "verse_number": 15,
      "content": "ولو ألقىا معاذيره"
    },
    {
      "surah_number": 75,
      "verse_number": 16,
      "content": "لا تحرك به لسانك لتعجل به"
    },
    {
      "surah_number": 75,
      "verse_number": 17,
      "content": "ان علينا جمعه وقرانه"
    },
    {
      "surah_number": 75,
      "verse_number": 18,
      "content": "فاذا قرأناه فاتبع قرانه"
    },
    {
      "surah_number": 75,
      "verse_number": 19,
      "content": "ثم ان علينا بيانه"
    },
    {
      "surah_number": 75,
      "verse_number": 20,
      "content": "كلا بل تحبون العاجله"
    },
    {
      "surah_number": 75,
      "verse_number": 21,
      "content": "وتذرون الأخره"
    },
    {
      "surah_number": 75,
      "verse_number": 22,
      "content": "وجوه يومئذ ناضره"
    },
    {
      "surah_number": 75,
      "verse_number": 23,
      "content": "الىا ربها ناظره"
    },
    {
      "surah_number": 75,
      "verse_number": 24,
      "content": "ووجوه يومئذ باسره"
    },
    {
      "surah_number": 75,
      "verse_number": 25,
      "content": "تظن أن يفعل بها فاقره"
    },
    {
      "surah_number": 75,
      "verse_number": 26,
      "content": "كلا اذا بلغت التراقي"
    },
    {
      "surah_number": 75,
      "verse_number": 27,
      "content": "وقيل من راق"
    },
    {
      "surah_number": 75,
      "verse_number": 28,
      "content": "وظن أنه الفراق"
    },
    {
      "surah_number": 75,
      "verse_number": 29,
      "content": "والتفت الساق بالساق"
    },
    {
      "surah_number": 75,
      "verse_number": 30,
      "content": "الىا ربك يومئذ المساق"
    },
    {
      "surah_number": 75,
      "verse_number": 31,
      "content": "فلا صدق ولا صلىا"
    },
    {
      "surah_number": 75,
      "verse_number": 32,
      "content": "ولاكن كذب وتولىا"
    },
    {
      "surah_number": 75,
      "verse_number": 33,
      "content": "ثم ذهب الىا أهله يتمطىا"
    },
    {
      "surah_number": 75,
      "verse_number": 34,
      "content": "أولىا لك فأولىا"
    },
    {
      "surah_number": 75,
      "verse_number": 35,
      "content": "ثم أولىا لك فأولىا"
    },
    {
      "surah_number": 75,
      "verse_number": 36,
      "content": "أيحسب الانسان أن يترك سدى"
    },
    {
      "surah_number": 75,
      "verse_number": 37,
      "content": "ألم يك نطفه من مني يمنىا"
    },
    {
      "surah_number": 75,
      "verse_number": 38,
      "content": "ثم كان علقه فخلق فسوىا"
    },
    {
      "surah_number": 75,
      "verse_number": 39,
      "content": "فجعل منه الزوجين الذكر والأنثىا"
    },
    {
      "surah_number": 75,
      "verse_number": 40,
      "content": "أليس ذالك بقادر علىا أن يحي الموتىا"
    },
    {
      "surah_number": 76,
      "verse_number": 1,
      "content": "هل أتىا على الانسان حين من الدهر لم يكن شئا مذكورا"
    },
    {
      "surah_number": 76,
      "verse_number": 2,
      "content": "انا خلقنا الانسان من نطفه أمشاج نبتليه فجعلناه سميعا بصيرا"
    },
    {
      "surah_number": 76,
      "verse_number": 3,
      "content": "انا هديناه السبيل اما شاكرا واما كفورا"
    },
    {
      "surah_number": 76,
      "verse_number": 4,
      "content": "انا أعتدنا للكافرين سلاسلا وأغلالا وسعيرا"
    },
    {
      "surah_number": 76,
      "verse_number": 5,
      "content": "ان الأبرار يشربون من كأس كان مزاجها كافورا"
    },
    {
      "surah_number": 76,
      "verse_number": 6,
      "content": "عينا يشرب بها عباد الله يفجرونها تفجيرا"
    },
    {
      "surah_number": 76,
      "verse_number": 7,
      "content": "يوفون بالنذر ويخافون يوما كان شره مستطيرا"
    },
    {
      "surah_number": 76,
      "verse_number": 8,
      "content": "ويطعمون الطعام علىا حبه مسكينا ويتيما وأسيرا"
    },
    {
      "surah_number": 76,
      "verse_number": 9,
      "content": "انما نطعمكم لوجه الله لا نريد منكم جزا ولا شكورا"
    },
    {
      "surah_number": 76,
      "verse_number": 10,
      "content": "انا نخاف من ربنا يوما عبوسا قمطريرا"
    },
    {
      "surah_number": 76,
      "verse_number": 11,
      "content": "فوقىاهم الله شر ذالك اليوم ولقىاهم نضره وسرورا"
    },
    {
      "surah_number": 76,
      "verse_number": 12,
      "content": "وجزىاهم بما صبروا جنه وحريرا"
    },
    {
      "surah_number": 76,
      "verse_number": 13,
      "content": "متكٔين فيها على الأرائك لا يرون فيها شمسا ولا زمهريرا"
    },
    {
      "surah_number": 76,
      "verse_number": 14,
      "content": "ودانيه عليهم ظلالها وذللت قطوفها تذليلا"
    },
    {
      "surah_number": 76,
      "verse_number": 15,
      "content": "ويطاف عليهم بٔانيه من فضه وأكواب كانت قواريرا"
    },
    {
      "surah_number": 76,
      "verse_number": 16,
      "content": "قواريرا من فضه قدروها تقديرا"
    },
    {
      "surah_number": 76,
      "verse_number": 17,
      "content": "ويسقون فيها كأسا كان مزاجها زنجبيلا"
    },
    {
      "surah_number": 76,
      "verse_number": 18,
      "content": "عينا فيها تسمىا سلسبيلا"
    },
    {
      "surah_number": 76,
      "verse_number": 19,
      "content": "ويطوف عليهم ولدان مخلدون اذا رأيتهم حسبتهم لؤلؤا منثورا"
    },
    {
      "surah_number": 76,
      "verse_number": 20,
      "content": "واذا رأيت ثم رأيت نعيما وملكا كبيرا"
    },
    {
      "surah_number": 76,
      "verse_number": 21,
      "content": "عاليهم ثياب سندس خضر واستبرق وحلوا أساور من فضه وسقىاهم ربهم شرابا طهورا"
    },
    {
      "surah_number": 76,
      "verse_number": 22,
      "content": "ان هاذا كان لكم جزا وكان سعيكم مشكورا"
    },
    {
      "surah_number": 76,
      "verse_number": 23,
      "content": "انا نحن نزلنا عليك القران تنزيلا"
    },
    {
      "surah_number": 76,
      "verse_number": 24,
      "content": "فاصبر لحكم ربك ولا تطع منهم اثما أو كفورا"
    },
    {
      "surah_number": 76,
      "verse_number": 25,
      "content": "واذكر اسم ربك بكره وأصيلا"
    },
    {
      "surah_number": 76,
      "verse_number": 26,
      "content": "ومن اليل فاسجد له وسبحه ليلا طويلا"
    },
    {
      "surah_number": 76,
      "verse_number": 27,
      "content": "ان هاؤلا يحبون العاجله ويذرون وراهم يوما ثقيلا"
    },
    {
      "surah_number": 76,
      "verse_number": 28,
      "content": "نحن خلقناهم وشددنا أسرهم واذا شئنا بدلنا أمثالهم تبديلا"
    },
    {
      "surah_number": 76,
      "verse_number": 29,
      "content": "ان هاذه تذكره فمن شا اتخذ الىا ربه سبيلا"
    },
    {
      "surah_number": 76,
      "verse_number": 30,
      "content": "وما تشاون الا أن يشا الله ان الله كان عليما حكيما"
    },
    {
      "surah_number": 76,
      "verse_number": 31,
      "content": "يدخل من يشا في رحمته والظالمين أعد لهم عذابا أليما"
    },
    {
      "surah_number": 77,
      "verse_number": 1,
      "content": "والمرسلات عرفا"
    },
    {
      "surah_number": 77,
      "verse_number": 2,
      "content": "فالعاصفات عصفا"
    },
    {
      "surah_number": 77,
      "verse_number": 3,
      "content": "والناشرات نشرا"
    },
    {
      "surah_number": 77,
      "verse_number": 4,
      "content": "فالفارقات فرقا"
    },
    {
      "surah_number": 77,
      "verse_number": 5,
      "content": "فالملقيات ذكرا"
    },
    {
      "surah_number": 77,
      "verse_number": 6,
      "content": "عذرا أو نذرا"
    },
    {
      "surah_number": 77,
      "verse_number": 7,
      "content": "انما توعدون لواقع"
    },
    {
      "surah_number": 77,
      "verse_number": 8,
      "content": "فاذا النجوم طمست"
    },
    {
      "surah_number": 77,
      "verse_number": 9,
      "content": "واذا السما فرجت"
    },
    {
      "surah_number": 77,
      "verse_number": 10,
      "content": "واذا الجبال نسفت"
    },
    {
      "surah_number": 77,
      "verse_number": 11,
      "content": "واذا الرسل أقتت"
    },
    {
      "surah_number": 77,
      "verse_number": 12,
      "content": "لأي يوم أجلت"
    },
    {
      "surah_number": 77,
      "verse_number": 13,
      "content": "ليوم الفصل"
    },
    {
      "surah_number": 77,
      "verse_number": 14,
      "content": "وما أدرىاك ما يوم الفصل"
    },
    {
      "surah_number": 77,
      "verse_number": 15,
      "content": "ويل يومئذ للمكذبين"
    },
    {
      "surah_number": 77,
      "verse_number": 16,
      "content": "ألم نهلك الأولين"
    },
    {
      "surah_number": 77,
      "verse_number": 17,
      "content": "ثم نتبعهم الأخرين"
    },
    {
      "surah_number": 77,
      "verse_number": 18,
      "content": "كذالك نفعل بالمجرمين"
    },
    {
      "surah_number": 77,
      "verse_number": 19,
      "content": "ويل يومئذ للمكذبين"
    },
    {
      "surah_number": 77,
      "verse_number": 20,
      "content": "ألم نخلقكم من ما مهين"
    },
    {
      "surah_number": 77,
      "verse_number": 21,
      "content": "فجعلناه في قرار مكين"
    },
    {
      "surah_number": 77,
      "verse_number": 22,
      "content": "الىا قدر معلوم"
    },
    {
      "surah_number": 77,
      "verse_number": 23,
      "content": "فقدرنا فنعم القادرون"
    },
    {
      "surah_number": 77,
      "verse_number": 24,
      "content": "ويل يومئذ للمكذبين"
    },
    {
      "surah_number": 77,
      "verse_number": 25,
      "content": "ألم نجعل الأرض كفاتا"
    },
    {
      "surah_number": 77,
      "verse_number": 26,
      "content": "أحيا وأمواتا"
    },
    {
      "surah_number": 77,
      "verse_number": 27,
      "content": "وجعلنا فيها رواسي شامخات وأسقيناكم ما فراتا"
    },
    {
      "surah_number": 77,
      "verse_number": 28,
      "content": "ويل يومئذ للمكذبين"
    },
    {
      "surah_number": 77,
      "verse_number": 29,
      "content": "انطلقوا الىا ما كنتم به تكذبون"
    },
    {
      "surah_number": 77,
      "verse_number": 30,
      "content": "انطلقوا الىا ظل ذي ثلاث شعب"
    },
    {
      "surah_number": 77,
      "verse_number": 31,
      "content": "لا ظليل ولا يغني من اللهب"
    },
    {
      "surah_number": 77,
      "verse_number": 32,
      "content": "انها ترمي بشرر كالقصر"
    },
    {
      "surah_number": 77,
      "verse_number": 33,
      "content": "كأنه جمالت صفر"
    },
    {
      "surah_number": 77,
      "verse_number": 34,
      "content": "ويل يومئذ للمكذبين"
    },
    {
      "surah_number": 77,
      "verse_number": 35,
      "content": "هاذا يوم لا ينطقون"
    },
    {
      "surah_number": 77,
      "verse_number": 36,
      "content": "ولا يؤذن لهم فيعتذرون"
    },
    {
      "surah_number": 77,
      "verse_number": 37,
      "content": "ويل يومئذ للمكذبين"
    },
    {
      "surah_number": 77,
      "verse_number": 38,
      "content": "هاذا يوم الفصل جمعناكم والأولين"
    },
    {
      "surah_number": 77,
      "verse_number": 39,
      "content": "فان كان لكم كيد فكيدون"
    },
    {
      "surah_number": 77,
      "verse_number": 40,
      "content": "ويل يومئذ للمكذبين"
    },
    {
      "surah_number": 77,
      "verse_number": 41,
      "content": "ان المتقين في ظلال وعيون"
    },
    {
      "surah_number": 77,
      "verse_number": 42,
      "content": "وفواكه مما يشتهون"
    },
    {
      "surah_number": 77,
      "verse_number": 43,
      "content": "كلوا واشربوا هنئا بما كنتم تعملون"
    },
    {
      "surah_number": 77,
      "verse_number": 44,
      "content": "انا كذالك نجزي المحسنين"
    },
    {
      "surah_number": 77,
      "verse_number": 45,
      "content": "ويل يومئذ للمكذبين"
    },
    {
      "surah_number": 77,
      "verse_number": 46,
      "content": "كلوا وتمتعوا قليلا انكم مجرمون"
    },
    {
      "surah_number": 77,
      "verse_number": 47,
      "content": "ويل يومئذ للمكذبين"
    },
    {
      "surah_number": 77,
      "verse_number": 48,
      "content": "واذا قيل لهم اركعوا لا يركعون"
    },
    {
      "surah_number": 77,
      "verse_number": 49,
      "content": "ويل يومئذ للمكذبين"
    },
    {
      "surah_number": 77,
      "verse_number": 50,
      "content": "فبأي حديث بعده يؤمنون"
    },
    {
      "surah_number": 78,
      "verse_number": 1,
      "content": "عم يتسالون"
    },
    {
      "surah_number": 78,
      "verse_number": 2,
      "content": "عن النبا العظيم"
    },
    {
      "surah_number": 78,
      "verse_number": 3,
      "content": "الذي هم فيه مختلفون"
    },
    {
      "surah_number": 78,
      "verse_number": 4,
      "content": "كلا سيعلمون"
    },
    {
      "surah_number": 78,
      "verse_number": 5,
      "content": "ثم كلا سيعلمون"
    },
    {
      "surah_number": 78,
      "verse_number": 6,
      "content": "ألم نجعل الأرض مهادا"
    },
    {
      "surah_number": 78,
      "verse_number": 7,
      "content": "والجبال أوتادا"
    },
    {
      "surah_number": 78,
      "verse_number": 8,
      "content": "وخلقناكم أزواجا"
    },
    {
      "surah_number": 78,
      "verse_number": 9,
      "content": "وجعلنا نومكم سباتا"
    },
    {
      "surah_number": 78,
      "verse_number": 10,
      "content": "وجعلنا اليل لباسا"
    },
    {
      "surah_number": 78,
      "verse_number": 11,
      "content": "وجعلنا النهار معاشا"
    },
    {
      "surah_number": 78,
      "verse_number": 12,
      "content": "وبنينا فوقكم سبعا شدادا"
    },
    {
      "surah_number": 78,
      "verse_number": 13,
      "content": "وجعلنا سراجا وهاجا"
    },
    {
      "surah_number": 78,
      "verse_number": 14,
      "content": "وأنزلنا من المعصرات ما ثجاجا"
    },
    {
      "surah_number": 78,
      "verse_number": 15,
      "content": "لنخرج به حبا ونباتا"
    },
    {
      "surah_number": 78,
      "verse_number": 16,
      "content": "وجنات ألفافا"
    },
    {
      "surah_number": 78,
      "verse_number": 17,
      "content": "ان يوم الفصل كان ميقاتا"
    },
    {
      "surah_number": 78,
      "verse_number": 18,
      "content": "يوم ينفخ في الصور فتأتون أفواجا"
    },
    {
      "surah_number": 78,
      "verse_number": 19,
      "content": "وفتحت السما فكانت أبوابا"
    },
    {
      "surah_number": 78,
      "verse_number": 20,
      "content": "وسيرت الجبال فكانت سرابا"
    },
    {
      "surah_number": 78,
      "verse_number": 21,
      "content": "ان جهنم كانت مرصادا"
    },
    {
      "surah_number": 78,
      "verse_number": 22,
      "content": "للطاغين مٔابا"
    },
    {
      "surah_number": 78,
      "verse_number": 23,
      "content": "لابثين فيها أحقابا"
    },
    {
      "surah_number": 78,
      "verse_number": 24,
      "content": "لا يذوقون فيها بردا ولا شرابا"
    },
    {
      "surah_number": 78,
      "verse_number": 25,
      "content": "الا حميما وغساقا"
    },
    {
      "surah_number": 78,
      "verse_number": 26,
      "content": "جزا وفاقا"
    },
    {
      "surah_number": 78,
      "verse_number": 27,
      "content": "انهم كانوا لا يرجون حسابا"
    },
    {
      "surah_number": 78,
      "verse_number": 28,
      "content": "وكذبوا بٔاياتنا كذابا"
    },
    {
      "surah_number": 78,
      "verse_number": 29,
      "content": "وكل شي أحصيناه كتابا"
    },
    {
      "surah_number": 78,
      "verse_number": 30,
      "content": "فذوقوا فلن نزيدكم الا عذابا"
    },
    {
      "surah_number": 78,
      "verse_number": 31,
      "content": "ان للمتقين مفازا"
    },
    {
      "surah_number": 78,
      "verse_number": 32,
      "content": "حدائق وأعنابا"
    },
    {
      "surah_number": 78,
      "verse_number": 33,
      "content": "وكواعب أترابا"
    },
    {
      "surah_number": 78,
      "verse_number": 34,
      "content": "وكأسا دهاقا"
    },
    {
      "surah_number": 78,
      "verse_number": 35,
      "content": "لا يسمعون فيها لغوا ولا كذابا"
    },
    {
      "surah_number": 78,
      "verse_number": 36,
      "content": "جزا من ربك عطا حسابا"
    },
    {
      "surah_number": 78,
      "verse_number": 37,
      "content": "رب السماوات والأرض وما بينهما الرحمان لا يملكون منه خطابا"
    },
    {
      "surah_number": 78,
      "verse_number": 38,
      "content": "يوم يقوم الروح والملائكه صفا لا يتكلمون الا من أذن له الرحمان وقال صوابا"
    },
    {
      "surah_number": 78,
      "verse_number": 39,
      "content": "ذالك اليوم الحق فمن شا اتخذ الىا ربه مٔابا"
    },
    {
      "surah_number": 78,
      "verse_number": 40,
      "content": "انا أنذرناكم عذابا قريبا يوم ينظر المر ما قدمت يداه ويقول الكافر ياليتني كنت ترابا"
    },
    {
      "surah_number": 79,
      "verse_number": 1,
      "content": "والنازعات غرقا"
    },
    {
      "surah_number": 79,
      "verse_number": 2,
      "content": "والناشطات نشطا"
    },
    {
      "surah_number": 79,
      "verse_number": 3,
      "content": "والسابحات سبحا"
    },
    {
      "surah_number": 79,
      "verse_number": 4,
      "content": "فالسابقات سبقا"
    },
    {
      "surah_number": 79,
      "verse_number": 5,
      "content": "فالمدبرات أمرا"
    },
    {
      "surah_number": 79,
      "verse_number": 6,
      "content": "يوم ترجف الراجفه"
    },
    {
      "surah_number": 79,
      "verse_number": 7,
      "content": "تتبعها الرادفه"
    },
    {
      "surah_number": 79,
      "verse_number": 8,
      "content": "قلوب يومئذ واجفه"
    },
    {
      "surah_number": 79,
      "verse_number": 9,
      "content": "أبصارها خاشعه"
    },
    {
      "surah_number": 79,
      "verse_number": 10,
      "content": "يقولون أنا لمردودون في الحافره"
    },
    {
      "surah_number": 79,
      "verse_number": 11,
      "content": "أذا كنا عظاما نخره"
    },
    {
      "surah_number": 79,
      "verse_number": 12,
      "content": "قالوا تلك اذا كره خاسره"
    },
    {
      "surah_number": 79,
      "verse_number": 13,
      "content": "فانما هي زجره واحده"
    },
    {
      "surah_number": 79,
      "verse_number": 14,
      "content": "فاذا هم بالساهره"
    },
    {
      "surah_number": 79,
      "verse_number": 15,
      "content": "هل أتىاك حديث موسىا"
    },
    {
      "surah_number": 79,
      "verse_number": 16,
      "content": "اذ نادىاه ربه بالواد المقدس طوى"
    },
    {
      "surah_number": 79,
      "verse_number": 17,
      "content": "اذهب الىا فرعون انه طغىا"
    },
    {
      "surah_number": 79,
      "verse_number": 18,
      "content": "فقل هل لك الىا أن تزكىا"
    },
    {
      "surah_number": 79,
      "verse_number": 19,
      "content": "وأهديك الىا ربك فتخشىا"
    },
    {
      "surah_number": 79,
      "verse_number": 20,
      "content": "فأرىاه الأيه الكبرىا"
    },
    {
      "surah_number": 79,
      "verse_number": 21,
      "content": "فكذب وعصىا"
    },
    {
      "surah_number": 79,
      "verse_number": 22,
      "content": "ثم أدبر يسعىا"
    },
    {
      "surah_number": 79,
      "verse_number": 23,
      "content": "فحشر فنادىا"
    },
    {
      "surah_number": 79,
      "verse_number": 24,
      "content": "فقال أنا ربكم الأعلىا"
    },
    {
      "surah_number": 79,
      "verse_number": 25,
      "content": "فأخذه الله نكال الأخره والأولىا"
    },
    {
      "surah_number": 79,
      "verse_number": 26,
      "content": "ان في ذالك لعبره لمن يخشىا"
    },
    {
      "surah_number": 79,
      "verse_number": 27,
      "content": "ءأنتم أشد خلقا أم السما بنىاها"
    },
    {
      "surah_number": 79,
      "verse_number": 28,
      "content": "رفع سمكها فسوىاها"
    },
    {
      "surah_number": 79,
      "verse_number": 29,
      "content": "وأغطش ليلها وأخرج ضحىاها"
    },
    {
      "surah_number": 79,
      "verse_number": 30,
      "content": "والأرض بعد ذالك دحىاها"
    },
    {
      "surah_number": 79,
      "verse_number": 31,
      "content": "أخرج منها ماها ومرعىاها"
    },
    {
      "surah_number": 79,
      "verse_number": 32,
      "content": "والجبال أرسىاها"
    },
    {
      "surah_number": 79,
      "verse_number": 33,
      "content": "متاعا لكم ولأنعامكم"
    },
    {
      "surah_number": 79,
      "verse_number": 34,
      "content": "فاذا جات الطامه الكبرىا"
    },
    {
      "surah_number": 79,
      "verse_number": 35,
      "content": "يوم يتذكر الانسان ما سعىا"
    },
    {
      "surah_number": 79,
      "verse_number": 36,
      "content": "وبرزت الجحيم لمن يرىا"
    },
    {
      "surah_number": 79,
      "verse_number": 37,
      "content": "فأما من طغىا"
    },
    {
      "surah_number": 79,
      "verse_number": 38,
      "content": "واثر الحيواه الدنيا"
    },
    {
      "surah_number": 79,
      "verse_number": 39,
      "content": "فان الجحيم هي المأوىا"
    },
    {
      "surah_number": 79,
      "verse_number": 40,
      "content": "وأما من خاف مقام ربه ونهى النفس عن الهوىا"
    },
    {
      "surah_number": 79,
      "verse_number": 41,
      "content": "فان الجنه هي المأوىا"
    },
    {
      "surah_number": 79,
      "verse_number": 42,
      "content": "يسٔلونك عن الساعه أيان مرسىاها"
    },
    {
      "surah_number": 79,
      "verse_number": 43,
      "content": "فيم أنت من ذكرىاها"
    },
    {
      "surah_number": 79,
      "verse_number": 44,
      "content": "الىا ربك منتهىاها"
    },
    {
      "surah_number": 79,
      "verse_number": 45,
      "content": "انما أنت منذر من يخشىاها"
    },
    {
      "surah_number": 79,
      "verse_number": 46,
      "content": "كأنهم يوم يرونها لم يلبثوا الا عشيه أو ضحىاها"
    },
    {
      "surah_number": 80,
      "verse_number": 1,
      "content": "عبس وتولىا"
    },
    {
      "surah_number": 80,
      "verse_number": 2,
      "content": "أن جاه الأعمىا"
    },
    {
      "surah_number": 80,
      "verse_number": 3,
      "content": "وما يدريك لعله يزكىا"
    },
    {
      "surah_number": 80,
      "verse_number": 4,
      "content": "أو يذكر فتنفعه الذكرىا"
    },
    {
      "surah_number": 80,
      "verse_number": 5,
      "content": "أما من استغنىا"
    },
    {
      "surah_number": 80,
      "verse_number": 6,
      "content": "فأنت له تصدىا"
    },
    {
      "surah_number": 80,
      "verse_number": 7,
      "content": "وما عليك ألا يزكىا"
    },
    {
      "surah_number": 80,
      "verse_number": 8,
      "content": "وأما من جاك يسعىا"
    },
    {
      "surah_number": 80,
      "verse_number": 9,
      "content": "وهو يخشىا"
    },
    {
      "surah_number": 80,
      "verse_number": 10,
      "content": "فأنت عنه تلهىا"
    },
    {
      "surah_number": 80,
      "verse_number": 11,
      "content": "كلا انها تذكره"
    },
    {
      "surah_number": 80,
      "verse_number": 12,
      "content": "فمن شا ذكره"
    },
    {
      "surah_number": 80,
      "verse_number": 13,
      "content": "في صحف مكرمه"
    },
    {
      "surah_number": 80,
      "verse_number": 14,
      "content": "مرفوعه مطهره"
    },
    {
      "surah_number": 80,
      "verse_number": 15,
      "content": "بأيدي سفره"
    },
    {
      "surah_number": 80,
      "verse_number": 16,
      "content": "كرام برره"
    },
    {
      "surah_number": 80,
      "verse_number": 17,
      "content": "قتل الانسان ما أكفره"
    },
    {
      "surah_number": 80,
      "verse_number": 18,
      "content": "من أي شي خلقه"
    },
    {
      "surah_number": 80,
      "verse_number": 19,
      "content": "من نطفه خلقه فقدره"
    },
    {
      "surah_number": 80,
      "verse_number": 20,
      "content": "ثم السبيل يسره"
    },
    {
      "surah_number": 80,
      "verse_number": 21,
      "content": "ثم أماته فأقبره"
    },
    {
      "surah_number": 80,
      "verse_number": 22,
      "content": "ثم اذا شا أنشره"
    },
    {
      "surah_number": 80,
      "verse_number": 23,
      "content": "كلا لما يقض ما أمره"
    },
    {
      "surah_number": 80,
      "verse_number": 24,
      "content": "فلينظر الانسان الىا طعامه"
    },
    {
      "surah_number": 80,
      "verse_number": 25,
      "content": "أنا صببنا الما صبا"
    },
    {
      "surah_number": 80,
      "verse_number": 26,
      "content": "ثم شققنا الأرض شقا"
    },
    {
      "surah_number": 80,
      "verse_number": 27,
      "content": "فأنبتنا فيها حبا"
    },
    {
      "surah_number": 80,
      "verse_number": 28,
      "content": "وعنبا وقضبا"
    },
    {
      "surah_number": 80,
      "verse_number": 29,
      "content": "وزيتونا ونخلا"
    },
    {
      "surah_number": 80,
      "verse_number": 30,
      "content": "وحدائق غلبا"
    },
    {
      "surah_number": 80,
      "verse_number": 31,
      "content": "وفاكهه وأبا"
    },
    {
      "surah_number": 80,
      "verse_number": 32,
      "content": "متاعا لكم ولأنعامكم"
    },
    {
      "surah_number": 80,
      "verse_number": 33,
      "content": "فاذا جات الصاخه"
    },
    {
      "surah_number": 80,
      "verse_number": 34,
      "content": "يوم يفر المر من أخيه"
    },
    {
      "surah_number": 80,
      "verse_number": 35,
      "content": "وأمه وأبيه"
    },
    {
      "surah_number": 80,
      "verse_number": 36,
      "content": "وصاحبته وبنيه"
    },
    {
      "surah_number": 80,
      "verse_number": 37,
      "content": "لكل امري منهم يومئذ شأن يغنيه"
    },
    {
      "surah_number": 80,
      "verse_number": 38,
      "content": "وجوه يومئذ مسفره"
    },
    {
      "surah_number": 80,
      "verse_number": 39,
      "content": "ضاحكه مستبشره"
    },
    {
      "surah_number": 80,
      "verse_number": 40,
      "content": "ووجوه يومئذ عليها غبره"
    },
    {
      "surah_number": 80,
      "verse_number": 41,
      "content": "ترهقها قتره"
    },
    {
      "surah_number": 80,
      "verse_number": 42,
      "content": "أولائك هم الكفره الفجره"
    },
    {
      "surah_number": 81,
      "verse_number": 1,
      "content": "اذا الشمس كورت"
    },
    {
      "surah_number": 81,
      "verse_number": 2,
      "content": "واذا النجوم انكدرت"
    },
    {
      "surah_number": 81,
      "verse_number": 3,
      "content": "واذا الجبال سيرت"
    },
    {
      "surah_number": 81,
      "verse_number": 4,
      "content": "واذا العشار عطلت"
    },
    {
      "surah_number": 81,
      "verse_number": 5,
      "content": "واذا الوحوش حشرت"
    },
    {
      "surah_number": 81,
      "verse_number": 6,
      "content": "واذا البحار سجرت"
    },
    {
      "surah_number": 81,
      "verse_number": 7,
      "content": "واذا النفوس زوجت"
    },
    {
      "surah_number": 81,
      "verse_number": 8,
      "content": "واذا الموده سئلت"
    },
    {
      "surah_number": 81,
      "verse_number": 9,
      "content": "بأي ذنب قتلت"
    },
    {
      "surah_number": 81,
      "verse_number": 10,
      "content": "واذا الصحف نشرت"
    },
    {
      "surah_number": 81,
      "verse_number": 11,
      "content": "واذا السما كشطت"
    },
    {
      "surah_number": 81,
      "verse_number": 12,
      "content": "واذا الجحيم سعرت"
    },
    {
      "surah_number": 81,
      "verse_number": 13,
      "content": "واذا الجنه أزلفت"
    },
    {
      "surah_number": 81,
      "verse_number": 14,
      "content": "علمت نفس ما أحضرت"
    },
    {
      "surah_number": 81,
      "verse_number": 15,
      "content": "فلا أقسم بالخنس"
    },
    {
      "surah_number": 81,
      "verse_number": 16,
      "content": "الجوار الكنس"
    },
    {
      "surah_number": 81,
      "verse_number": 17,
      "content": "واليل اذا عسعس"
    },
    {
      "surah_number": 81,
      "verse_number": 18,
      "content": "والصبح اذا تنفس"
    },
    {
      "surah_number": 81,
      "verse_number": 19,
      "content": "انه لقول رسول كريم"
    },
    {
      "surah_number": 81,
      "verse_number": 20,
      "content": "ذي قوه عند ذي العرش مكين"
    },
    {
      "surah_number": 81,
      "verse_number": 21,
      "content": "مطاع ثم أمين"
    },
    {
      "surah_number": 81,
      "verse_number": 22,
      "content": "وما صاحبكم بمجنون"
    },
    {
      "surah_number": 81,
      "verse_number": 23,
      "content": "ولقد راه بالأفق المبين"
    },
    {
      "surah_number": 81,
      "verse_number": 24,
      "content": "وما هو على الغيب بضنين"
    },
    {
      "surah_number": 81,
      "verse_number": 25,
      "content": "وما هو بقول شيطان رجيم"
    },
    {
      "surah_number": 81,
      "verse_number": 26,
      "content": "فأين تذهبون"
    },
    {
      "surah_number": 81,
      "verse_number": 27,
      "content": "ان هو الا ذكر للعالمين"
    },
    {
      "surah_number": 81,
      "verse_number": 28,
      "content": "لمن شا منكم أن يستقيم"
    },
    {
      "surah_number": 81,
      "verse_number": 29,
      "content": "وما تشاون الا أن يشا الله رب العالمين"
    },
    {
      "surah_number": 82,
      "verse_number": 1,
      "content": "اذا السما انفطرت"
    },
    {
      "surah_number": 82,
      "verse_number": 2,
      "content": "واذا الكواكب انتثرت"
    },
    {
      "surah_number": 82,
      "verse_number": 3,
      "content": "واذا البحار فجرت"
    },
    {
      "surah_number": 82,
      "verse_number": 4,
      "content": "واذا القبور بعثرت"
    },
    {
      "surah_number": 82,
      "verse_number": 5,
      "content": "علمت نفس ما قدمت وأخرت"
    },
    {
      "surah_number": 82,
      "verse_number": 6,
      "content": "ياأيها الانسان ما غرك بربك الكريم"
    },
    {
      "surah_number": 82,
      "verse_number": 7,
      "content": "الذي خلقك فسوىاك فعدلك"
    },
    {
      "surah_number": 82,
      "verse_number": 8,
      "content": "في أي صوره ما شا ركبك"
    },
    {
      "surah_number": 82,
      "verse_number": 9,
      "content": "كلا بل تكذبون بالدين"
    },
    {
      "surah_number": 82,
      "verse_number": 10,
      "content": "وان عليكم لحافظين"
    },
    {
      "surah_number": 82,
      "verse_number": 11,
      "content": "كراما كاتبين"
    },
    {
      "surah_number": 82,
      "verse_number": 12,
      "content": "يعلمون ما تفعلون"
    },
    {
      "surah_number": 82,
      "verse_number": 13,
      "content": "ان الأبرار لفي نعيم"
    },
    {
      "surah_number": 82,
      "verse_number": 14,
      "content": "وان الفجار لفي جحيم"
    },
    {
      "surah_number": 82,
      "verse_number": 15,
      "content": "يصلونها يوم الدين"
    },
    {
      "surah_number": 82,
      "verse_number": 16,
      "content": "وما هم عنها بغائبين"
    },
    {
      "surah_number": 82,
      "verse_number": 17,
      "content": "وما أدرىاك ما يوم الدين"
    },
    {
      "surah_number": 82,
      "verse_number": 18,
      "content": "ثم ما أدرىاك ما يوم الدين"
    },
    {
      "surah_number": 82,
      "verse_number": 19,
      "content": "يوم لا تملك نفس لنفس شئا والأمر يومئذ لله"
    },
    {
      "surah_number": 83,
      "verse_number": 1,
      "content": "ويل للمطففين"
    },
    {
      "surah_number": 83,
      "verse_number": 2,
      "content": "الذين اذا اكتالوا على الناس يستوفون"
    },
    {
      "surah_number": 83,
      "verse_number": 3,
      "content": "واذا كالوهم أو وزنوهم يخسرون"
    },
    {
      "surah_number": 83,
      "verse_number": 4,
      "content": "ألا يظن أولائك أنهم مبعوثون"
    },
    {
      "surah_number": 83,
      "verse_number": 5,
      "content": "ليوم عظيم"
    },
    {
      "surah_number": 83,
      "verse_number": 6,
      "content": "يوم يقوم الناس لرب العالمين"
    },
    {
      "surah_number": 83,
      "verse_number": 7,
      "content": "كلا ان كتاب الفجار لفي سجين"
    },
    {
      "surah_number": 83,
      "verse_number": 8,
      "content": "وما أدرىاك ما سجين"
    },
    {
      "surah_number": 83,
      "verse_number": 9,
      "content": "كتاب مرقوم"
    },
    {
      "surah_number": 83,
      "verse_number": 10,
      "content": "ويل يومئذ للمكذبين"
    },
    {
      "surah_number": 83,
      "verse_number": 11,
      "content": "الذين يكذبون بيوم الدين"
    },
    {
      "surah_number": 83,
      "verse_number": 12,
      "content": "وما يكذب به الا كل معتد أثيم"
    },
    {
      "surah_number": 83,
      "verse_number": 13,
      "content": "اذا تتلىا عليه اياتنا قال أساطير الأولين"
    },
    {
      "surah_number": 83,
      "verse_number": 14,
      "content": "كلا بل ران علىا قلوبهم ما كانوا يكسبون"
    },
    {
      "surah_number": 83,
      "verse_number": 15,
      "content": "كلا انهم عن ربهم يومئذ لمحجوبون"
    },
    {
      "surah_number": 83,
      "verse_number": 16,
      "content": "ثم انهم لصالوا الجحيم"
    },
    {
      "surah_number": 83,
      "verse_number": 17,
      "content": "ثم يقال هاذا الذي كنتم به تكذبون"
    },
    {
      "surah_number": 83,
      "verse_number": 18,
      "content": "كلا ان كتاب الأبرار لفي عليين"
    },
    {
      "surah_number": 83,
      "verse_number": 19,
      "content": "وما أدرىاك ما عليون"
    },
    {
      "surah_number": 83,
      "verse_number": 20,
      "content": "كتاب مرقوم"
    },
    {
      "surah_number": 83,
      "verse_number": 21,
      "content": "يشهده المقربون"
    },
    {
      "surah_number": 83,
      "verse_number": 22,
      "content": "ان الأبرار لفي نعيم"
    },
    {
      "surah_number": 83,
      "verse_number": 23,
      "content": "على الأرائك ينظرون"
    },
    {
      "surah_number": 83,
      "verse_number": 24,
      "content": "تعرف في وجوههم نضره النعيم"
    },
    {
      "surah_number": 83,
      "verse_number": 25,
      "content": "يسقون من رحيق مختوم"
    },
    {
      "surah_number": 83,
      "verse_number": 26,
      "content": "ختامه مسك وفي ذالك فليتنافس المتنافسون"
    },
    {
      "surah_number": 83,
      "verse_number": 27,
      "content": "ومزاجه من تسنيم"
    },
    {
      "surah_number": 83,
      "verse_number": 28,
      "content": "عينا يشرب بها المقربون"
    },
    {
      "surah_number": 83,
      "verse_number": 29,
      "content": "ان الذين أجرموا كانوا من الذين امنوا يضحكون"
    },
    {
      "surah_number": 83,
      "verse_number": 30,
      "content": "واذا مروا بهم يتغامزون"
    },
    {
      "surah_number": 83,
      "verse_number": 31,
      "content": "واذا انقلبوا الىا أهلهم انقلبوا فكهين"
    },
    {
      "surah_number": 83,
      "verse_number": 32,
      "content": "واذا رأوهم قالوا ان هاؤلا لضالون"
    },
    {
      "surah_number": 83,
      "verse_number": 33,
      "content": "وما أرسلوا عليهم حافظين"
    },
    {
      "surah_number": 83,
      "verse_number": 34,
      "content": "فاليوم الذين امنوا من الكفار يضحكون"
    },
    {
      "surah_number": 83,
      "verse_number": 35,
      "content": "على الأرائك ينظرون"
    },
    {
      "surah_number": 83,
      "verse_number": 36,
      "content": "هل ثوب الكفار ما كانوا يفعلون"
    },
    {
      "surah_number": 84,
      "verse_number": 1,
      "content": "اذا السما انشقت"
    },
    {
      "surah_number": 84,
      "verse_number": 2,
      "content": "وأذنت لربها وحقت"
    },
    {
      "surah_number": 84,
      "verse_number": 3,
      "content": "واذا الأرض مدت"
    },
    {
      "surah_number": 84,
      "verse_number": 4,
      "content": "وألقت ما فيها وتخلت"
    },
    {
      "surah_number": 84,
      "verse_number": 5,
      "content": "وأذنت لربها وحقت"
    },
    {
      "surah_number": 84,
      "verse_number": 6,
      "content": "ياأيها الانسان انك كادح الىا ربك كدحا فملاقيه"
    },
    {
      "surah_number": 84,
      "verse_number": 7,
      "content": "فأما من أوتي كتابه بيمينه"
    },
    {
      "surah_number": 84,
      "verse_number": 8,
      "content": "فسوف يحاسب حسابا يسيرا"
    },
    {
      "surah_number": 84,
      "verse_number": 9,
      "content": "وينقلب الىا أهله مسرورا"
    },
    {
      "surah_number": 84,
      "verse_number": 10,
      "content": "وأما من أوتي كتابه ورا ظهره"
    },
    {
      "surah_number": 84,
      "verse_number": 11,
      "content": "فسوف يدعوا ثبورا"
    },
    {
      "surah_number": 84,
      "verse_number": 12,
      "content": "ويصلىا سعيرا"
    },
    {
      "surah_number": 84,
      "verse_number": 13,
      "content": "انه كان في أهله مسرورا"
    },
    {
      "surah_number": 84,
      "verse_number": 14,
      "content": "انه ظن أن لن يحور"
    },
    {
      "surah_number": 84,
      "verse_number": 15,
      "content": "بلىا ان ربه كان به بصيرا"
    },
    {
      "surah_number": 84,
      "verse_number": 16,
      "content": "فلا أقسم بالشفق"
    },
    {
      "surah_number": 84,
      "verse_number": 17,
      "content": "واليل وما وسق"
    },
    {
      "surah_number": 84,
      "verse_number": 18,
      "content": "والقمر اذا اتسق"
    },
    {
      "surah_number": 84,
      "verse_number": 19,
      "content": "لتركبن طبقا عن طبق"
    },
    {
      "surah_number": 84,
      "verse_number": 20,
      "content": "فما لهم لا يؤمنون"
    },
    {
      "surah_number": 84,
      "verse_number": 21,
      "content": "واذا قرئ عليهم القران لا يسجدون"
    },
    {
      "surah_number": 84,
      "verse_number": 22,
      "content": "بل الذين كفروا يكذبون"
    },
    {
      "surah_number": 84,
      "verse_number": 23,
      "content": "والله أعلم بما يوعون"
    },
    {
      "surah_number": 84,
      "verse_number": 24,
      "content": "فبشرهم بعذاب أليم"
    },
    {
      "surah_number": 84,
      "verse_number": 25,
      "content": "الا الذين امنوا وعملوا الصالحات لهم أجر غير ممنون"
    },
    {
      "surah_number": 85,
      "verse_number": 1,
      "content": "والسما ذات البروج"
    },
    {
      "surah_number": 85,
      "verse_number": 2,
      "content": "واليوم الموعود"
    },
    {
      "surah_number": 85,
      "verse_number": 3,
      "content": "وشاهد ومشهود"
    },
    {
      "surah_number": 85,
      "verse_number": 4,
      "content": "قتل أصحاب الأخدود"
    },
    {
      "surah_number": 85,
      "verse_number": 5,
      "content": "النار ذات الوقود"
    },
    {
      "surah_number": 85,
      "verse_number": 6,
      "content": "اذ هم عليها قعود"
    },
    {
      "surah_number": 85,
      "verse_number": 7,
      "content": "وهم علىا ما يفعلون بالمؤمنين شهود"
    },
    {
      "surah_number": 85,
      "verse_number": 8,
      "content": "وما نقموا منهم الا أن يؤمنوا بالله العزيز الحميد"
    },
    {
      "surah_number": 85,
      "verse_number": 9,
      "content": "الذي له ملك السماوات والأرض والله علىا كل شي شهيد"
    },
    {
      "surah_number": 85,
      "verse_number": 10,
      "content": "ان الذين فتنوا المؤمنين والمؤمنات ثم لم يتوبوا فلهم عذاب جهنم ولهم عذاب الحريق"
    },
    {
      "surah_number": 85,
      "verse_number": 11,
      "content": "ان الذين امنوا وعملوا الصالحات لهم جنات تجري من تحتها الأنهار ذالك الفوز الكبير"
    },
    {
      "surah_number": 85,
      "verse_number": 12,
      "content": "ان بطش ربك لشديد"
    },
    {
      "surah_number": 85,
      "verse_number": 13,
      "content": "انه هو يبدئ ويعيد"
    },
    {
      "surah_number": 85,
      "verse_number": 14,
      "content": "وهو الغفور الودود"
    },
    {
      "surah_number": 85,
      "verse_number": 15,
      "content": "ذو العرش المجيد"
    },
    {
      "surah_number": 85,
      "verse_number": 16,
      "content": "فعال لما يريد"
    },
    {
      "surah_number": 85,
      "verse_number": 17,
      "content": "هل أتىاك حديث الجنود"
    },
    {
      "surah_number": 85,
      "verse_number": 18,
      "content": "فرعون وثمود"
    },
    {
      "surah_number": 85,
      "verse_number": 19,
      "content": "بل الذين كفروا في تكذيب"
    },
    {
      "surah_number": 85,
      "verse_number": 20,
      "content": "والله من ورائهم محيط"
    },
    {
      "surah_number": 85,
      "verse_number": 21,
      "content": "بل هو قران مجيد"
    },
    {
      "surah_number": 85,
      "verse_number": 22,
      "content": "في لوح محفوظ"
    },
    {
      "surah_number": 86,
      "verse_number": 1,
      "content": "والسما والطارق"
    },
    {
      "surah_number": 86,
      "verse_number": 2,
      "content": "وما أدرىاك ما الطارق"
    },
    {
      "surah_number": 86,
      "verse_number": 3,
      "content": "النجم الثاقب"
    },
    {
      "surah_number": 86,
      "verse_number": 4,
      "content": "ان كل نفس لما عليها حافظ"
    },
    {
      "surah_number": 86,
      "verse_number": 5,
      "content": "فلينظر الانسان مم خلق"
    },
    {
      "surah_number": 86,
      "verse_number": 6,
      "content": "خلق من ما دافق"
    },
    {
      "surah_number": 86,
      "verse_number": 7,
      "content": "يخرج من بين الصلب والترائب"
    },
    {
      "surah_number": 86,
      "verse_number": 8,
      "content": "انه علىا رجعه لقادر"
    },
    {
      "surah_number": 86,
      "verse_number": 9,
      "content": "يوم تبلى السرائر"
    },
    {
      "surah_number": 86,
      "verse_number": 10,
      "content": "فما له من قوه ولا ناصر"
    },
    {
      "surah_number": 86,
      "verse_number": 11,
      "content": "والسما ذات الرجع"
    },
    {
      "surah_number": 86,
      "verse_number": 12,
      "content": "والأرض ذات الصدع"
    },
    {
      "surah_number": 86,
      "verse_number": 13,
      "content": "انه لقول فصل"
    },
    {
      "surah_number": 86,
      "verse_number": 14,
      "content": "وما هو بالهزل"
    },
    {
      "surah_number": 86,
      "verse_number": 15,
      "content": "انهم يكيدون كيدا"
    },
    {
      "surah_number": 86,
      "verse_number": 16,
      "content": "وأكيد كيدا"
    },
    {
      "surah_number": 86,
      "verse_number": 17,
      "content": "فمهل الكافرين أمهلهم رويدا"
    },
    {
      "surah_number": 87,
      "verse_number": 1,
      "content": "سبح اسم ربك الأعلى"
    },
    {
      "surah_number": 87,
      "verse_number": 2,
      "content": "الذي خلق فسوىا"
    },
    {
      "surah_number": 87,
      "verse_number": 3,
      "content": "والذي قدر فهدىا"
    },
    {
      "surah_number": 87,
      "verse_number": 4,
      "content": "والذي أخرج المرعىا"
    },
    {
      "surah_number": 87,
      "verse_number": 5,
      "content": "فجعله غثا أحوىا"
    },
    {
      "surah_number": 87,
      "verse_number": 6,
      "content": "سنقرئك فلا تنسىا"
    },
    {
      "surah_number": 87,
      "verse_number": 7,
      "content": "الا ما شا الله انه يعلم الجهر وما يخفىا"
    },
    {
      "surah_number": 87,
      "verse_number": 8,
      "content": "ونيسرك لليسرىا"
    },
    {
      "surah_number": 87,
      "verse_number": 9,
      "content": "فذكر ان نفعت الذكرىا"
    },
    {
      "surah_number": 87,
      "verse_number": 10,
      "content": "سيذكر من يخشىا"
    },
    {
      "surah_number": 87,
      "verse_number": 11,
      "content": "ويتجنبها الأشقى"
    },
    {
      "surah_number": 87,
      "verse_number": 12,
      "content": "الذي يصلى النار الكبرىا"
    },
    {
      "surah_number": 87,
      "verse_number": 13,
      "content": "ثم لا يموت فيها ولا يحيىا"
    },
    {
      "surah_number": 87,
      "verse_number": 14,
      "content": "قد أفلح من تزكىا"
    },
    {
      "surah_number": 87,
      "verse_number": 15,
      "content": "وذكر اسم ربه فصلىا"
    },
    {
      "surah_number": 87,
      "verse_number": 16,
      "content": "بل تؤثرون الحيواه الدنيا"
    },
    {
      "surah_number": 87,
      "verse_number": 17,
      "content": "والأخره خير وأبقىا"
    },
    {
      "surah_number": 87,
      "verse_number": 18,
      "content": "ان هاذا لفي الصحف الأولىا"
    },
    {
      "surah_number": 87,
      "verse_number": 19,
      "content": "صحف ابراهيم وموسىا"
    },
    {
      "surah_number": 88,
      "verse_number": 1,
      "content": "هل أتىاك حديث الغاشيه"
    },
    {
      "surah_number": 88,
      "verse_number": 2,
      "content": "وجوه يومئذ خاشعه"
    },
    {
      "surah_number": 88,
      "verse_number": 3,
      "content": "عامله ناصبه"
    },
    {
      "surah_number": 88,
      "verse_number": 4,
      "content": "تصلىا نارا حاميه"
    },
    {
      "surah_number": 88,
      "verse_number": 5,
      "content": "تسقىا من عين انيه"
    },
    {
      "surah_number": 88,
      "verse_number": 6,
      "content": "ليس لهم طعام الا من ضريع"
    },
    {
      "surah_number": 88,
      "verse_number": 7,
      "content": "لا يسمن ولا يغني من جوع"
    },
    {
      "surah_number": 88,
      "verse_number": 8,
      "content": "وجوه يومئذ ناعمه"
    },
    {
      "surah_number": 88,
      "verse_number": 9,
      "content": "لسعيها راضيه"
    },
    {
      "surah_number": 88,
      "verse_number": 10,
      "content": "في جنه عاليه"
    },
    {
      "surah_number": 88,
      "verse_number": 11,
      "content": "لا تسمع فيها لاغيه"
    },
    {
      "surah_number": 88,
      "verse_number": 12,
      "content": "فيها عين جاريه"
    },
    {
      "surah_number": 88,
      "verse_number": 13,
      "content": "فيها سرر مرفوعه"
    },
    {
      "surah_number": 88,
      "verse_number": 14,
      "content": "وأكواب موضوعه"
    },
    {
      "surah_number": 88,
      "verse_number": 15,
      "content": "ونمارق مصفوفه"
    },
    {
      "surah_number": 88,
      "verse_number": 16,
      "content": "وزرابي مبثوثه"
    },
    {
      "surah_number": 88,
      "verse_number": 17,
      "content": "أفلا ينظرون الى الابل كيف خلقت"
    },
    {
      "surah_number": 88,
      "verse_number": 18,
      "content": "والى السما كيف رفعت"
    },
    {
      "surah_number": 88,
      "verse_number": 19,
      "content": "والى الجبال كيف نصبت"
    },
    {
      "surah_number": 88,
      "verse_number": 20,
      "content": "والى الأرض كيف سطحت"
    },
    {
      "surah_number": 88,
      "verse_number": 21,
      "content": "فذكر انما أنت مذكر"
    },
    {
      "surah_number": 88,
      "verse_number": 22,
      "content": "لست عليهم بمصيطر"
    },
    {
      "surah_number": 88,
      "verse_number": 23,
      "content": "الا من تولىا وكفر"
    },
    {
      "surah_number": 88,
      "verse_number": 24,
      "content": "فيعذبه الله العذاب الأكبر"
    },
    {
      "surah_number": 88,
      "verse_number": 25,
      "content": "ان الينا ايابهم"
    },
    {
      "surah_number": 88,
      "verse_number": 26,
      "content": "ثم ان علينا حسابهم"
    },
    {
      "surah_number": 89,
      "verse_number": 1,
      "content": "والفجر"
    },
    {
      "surah_number": 89,
      "verse_number": 2,
      "content": "وليال عشر"
    },
    {
      "surah_number": 89,
      "verse_number": 3,
      "content": "والشفع والوتر"
    },
    {
      "surah_number": 89,
      "verse_number": 4,
      "content": "واليل اذا يسر"
    },
    {
      "surah_number": 89,
      "verse_number": 5,
      "content": "هل في ذالك قسم لذي حجر"
    },
    {
      "surah_number": 89,
      "verse_number": 6,
      "content": "ألم تر كيف فعل ربك بعاد"
    },
    {
      "surah_number": 89,
      "verse_number": 7,
      "content": "ارم ذات العماد"
    },
    {
      "surah_number": 89,
      "verse_number": 8,
      "content": "التي لم يخلق مثلها في البلاد"
    },
    {
      "surah_number": 89,
      "verse_number": 9,
      "content": "وثمود الذين جابوا الصخر بالواد"
    },
    {
      "surah_number": 89,
      "verse_number": 10,
      "content": "وفرعون ذي الأوتاد"
    },
    {
      "surah_number": 89,
      "verse_number": 11,
      "content": "الذين طغوا في البلاد"
    },
    {
      "surah_number": 89,
      "verse_number": 12,
      "content": "فأكثروا فيها الفساد"
    },
    {
      "surah_number": 89,
      "verse_number": 13,
      "content": "فصب عليهم ربك سوط عذاب"
    },
    {
      "surah_number": 89,
      "verse_number": 14,
      "content": "ان ربك لبالمرصاد"
    },
    {
      "surah_number": 89,
      "verse_number": 15,
      "content": "فأما الانسان اذا ما ابتلىاه ربه فأكرمه ونعمه فيقول ربي أكرمن"
    },
    {
      "surah_number": 89,
      "verse_number": 16,
      "content": "وأما اذا ما ابتلىاه فقدر عليه رزقه فيقول ربي أهانن"
    },
    {
      "surah_number": 89,
      "verse_number": 17,
      "content": "كلا بل لا تكرمون اليتيم"
    },
    {
      "surah_number": 89,
      "verse_number": 18,
      "content": "ولا تحاضون علىا طعام المسكين"
    },
    {
      "surah_number": 89,
      "verse_number": 19,
      "content": "وتأكلون التراث أكلا لما"
    },
    {
      "surah_number": 89,
      "verse_number": 20,
      "content": "وتحبون المال حبا جما"
    },
    {
      "surah_number": 89,
      "verse_number": 21,
      "content": "كلا اذا دكت الأرض دكا دكا"
    },
    {
      "surah_number": 89,
      "verse_number": 22,
      "content": "وجا ربك والملك صفا صفا"
    },
    {
      "surah_number": 89,
      "verse_number": 23,
      "content": "وجاي يومئذ بجهنم يومئذ يتذكر الانسان وأنىا له الذكرىا"
    },
    {
      "surah_number": 89,
      "verse_number": 24,
      "content": "يقول ياليتني قدمت لحياتي"
    },
    {
      "surah_number": 89,
      "verse_number": 25,
      "content": "فيومئذ لا يعذب عذابه أحد"
    },
    {
      "surah_number": 89,
      "verse_number": 26,
      "content": "ولا يوثق وثاقه أحد"
    },
    {
      "surah_number": 89,
      "verse_number": 27,
      "content": "ياأيتها النفس المطمئنه"
    },
    {
      "surah_number": 89,
      "verse_number": 28,
      "content": "ارجعي الىا ربك راضيه مرضيه"
    },
    {
      "surah_number": 89,
      "verse_number": 29,
      "content": "فادخلي في عبادي"
    },
    {
      "surah_number": 89,
      "verse_number": 30,
      "content": "وادخلي جنتي"
    },
    {
      "surah_number": 90,
      "verse_number": 1,
      "content": "لا أقسم بهاذا البلد"
    },
    {
      "surah_number": 90,
      "verse_number": 2,
      "content": "وأنت حل بهاذا البلد"
    },
    {
      "surah_number": 90,
      "verse_number": 3,
      "content": "ووالد وما ولد"
    },
    {
      "surah_number": 90,
      "verse_number": 4,
      "content": "لقد خلقنا الانسان في كبد"
    },
    {
      "surah_number": 90,
      "verse_number": 5,
      "content": "أيحسب أن لن يقدر عليه أحد"
    },
    {
      "surah_number": 90,
      "verse_number": 6,
      "content": "يقول أهلكت مالا لبدا"
    },
    {
      "surah_number": 90,
      "verse_number": 7,
      "content": "أيحسب أن لم يره أحد"
    },
    {
      "surah_number": 90,
      "verse_number": 8,
      "content": "ألم نجعل له عينين"
    },
    {
      "surah_number": 90,
      "verse_number": 9,
      "content": "ولسانا وشفتين"
    },
    {
      "surah_number": 90,
      "verse_number": 10,
      "content": "وهديناه النجدين"
    },
    {
      "surah_number": 90,
      "verse_number": 11,
      "content": "فلا اقتحم العقبه"
    },
    {
      "surah_number": 90,
      "verse_number": 12,
      "content": "وما أدرىاك ما العقبه"
    },
    {
      "surah_number": 90,
      "verse_number": 13,
      "content": "فك رقبه"
    },
    {
      "surah_number": 90,
      "verse_number": 14,
      "content": "أو اطعام في يوم ذي مسغبه"
    },
    {
      "surah_number": 90,
      "verse_number": 15,
      "content": "يتيما ذا مقربه"
    },
    {
      "surah_number": 90,
      "verse_number": 16,
      "content": "أو مسكينا ذا متربه"
    },
    {
      "surah_number": 90,
      "verse_number": 17,
      "content": "ثم كان من الذين امنوا وتواصوا بالصبر وتواصوا بالمرحمه"
    },
    {
      "surah_number": 90,
      "verse_number": 18,
      "content": "أولائك أصحاب الميمنه"
    },
    {
      "surah_number": 90,
      "verse_number": 19,
      "content": "والذين كفروا بٔاياتنا هم أصحاب المشٔمه"
    },
    {
      "surah_number": 90,
      "verse_number": 20,
      "content": "عليهم نار مؤصده"
    },
    {
      "surah_number": 91,
      "verse_number": 1,
      "content": "والشمس وضحىاها"
    },
    {
      "surah_number": 91,
      "verse_number": 2,
      "content": "والقمر اذا تلىاها"
    },
    {
      "surah_number": 91,
      "verse_number": 3,
      "content": "والنهار اذا جلىاها"
    },
    {
      "surah_number": 91,
      "verse_number": 4,
      "content": "واليل اذا يغشىاها"
    },
    {
      "surah_number": 91,
      "verse_number": 5,
      "content": "والسما وما بنىاها"
    },
    {
      "surah_number": 91,
      "verse_number": 6,
      "content": "والأرض وما طحىاها"
    },
    {
      "surah_number": 91,
      "verse_number": 7,
      "content": "ونفس وما سوىاها"
    },
    {
      "surah_number": 91,
      "verse_number": 8,
      "content": "فألهمها فجورها وتقوىاها"
    },
    {
      "surah_number": 91,
      "verse_number": 9,
      "content": "قد أفلح من زكىاها"
    },
    {
      "surah_number": 91,
      "verse_number": 10,
      "content": "وقد خاب من دسىاها"
    },
    {
      "surah_number": 91,
      "verse_number": 11,
      "content": "كذبت ثمود بطغوىاها"
    },
    {
      "surah_number": 91,
      "verse_number": 12,
      "content": "اذ انبعث أشقىاها"
    },
    {
      "surah_number": 91,
      "verse_number": 13,
      "content": "فقال لهم رسول الله ناقه الله وسقياها"
    },
    {
      "surah_number": 91,
      "verse_number": 14,
      "content": "فكذبوه فعقروها فدمدم عليهم ربهم بذنبهم فسوىاها"
    },
    {
      "surah_number": 91,
      "verse_number": 15,
      "content": "ولا يخاف عقباها"
    },
    {
      "surah_number": 92,
      "verse_number": 1,
      "content": "واليل اذا يغشىا"
    },
    {
      "surah_number": 92,
      "verse_number": 2,
      "content": "والنهار اذا تجلىا"
    },
    {
      "surah_number": 92,
      "verse_number": 3,
      "content": "وما خلق الذكر والأنثىا"
    },
    {
      "surah_number": 92,
      "verse_number": 4,
      "content": "ان سعيكم لشتىا"
    },
    {
      "surah_number": 92,
      "verse_number": 5,
      "content": "فأما من أعطىا واتقىا"
    },
    {
      "surah_number": 92,
      "verse_number": 6,
      "content": "وصدق بالحسنىا"
    },
    {
      "surah_number": 92,
      "verse_number": 7,
      "content": "فسنيسره لليسرىا"
    },
    {
      "surah_number": 92,
      "verse_number": 8,
      "content": "وأما من بخل واستغنىا"
    },
    {
      "surah_number": 92,
      "verse_number": 9,
      "content": "وكذب بالحسنىا"
    },
    {
      "surah_number": 92,
      "verse_number": 10,
      "content": "فسنيسره للعسرىا"
    },
    {
      "surah_number": 92,
      "verse_number": 11,
      "content": "وما يغني عنه ماله اذا تردىا"
    },
    {
      "surah_number": 92,
      "verse_number": 12,
      "content": "ان علينا للهدىا"
    },
    {
      "surah_number": 92,
      "verse_number": 13,
      "content": "وان لنا للأخره والأولىا"
    },
    {
      "surah_number": 92,
      "verse_number": 14,
      "content": "فأنذرتكم نارا تلظىا"
    },
    {
      "surah_number": 92,
      "verse_number": 15,
      "content": "لا يصلىاها الا الأشقى"
    },
    {
      "surah_number": 92,
      "verse_number": 16,
      "content": "الذي كذب وتولىا"
    },
    {
      "surah_number": 92,
      "verse_number": 17,
      "content": "وسيجنبها الأتقى"
    },
    {
      "surah_number": 92,
      "verse_number": 18,
      "content": "الذي يؤتي ماله يتزكىا"
    },
    {
      "surah_number": 92,
      "verse_number": 19,
      "content": "وما لأحد عنده من نعمه تجزىا"
    },
    {
      "surah_number": 92,
      "verse_number": 20,
      "content": "الا ابتغا وجه ربه الأعلىا"
    },
    {
      "surah_number": 92,
      "verse_number": 21,
      "content": "ولسوف يرضىا"
    },
    {
      "surah_number": 93,
      "verse_number": 1,
      "content": "والضحىا"
    },
    {
      "surah_number": 93,
      "verse_number": 2,
      "content": "واليل اذا سجىا"
    },
    {
      "surah_number": 93,
      "verse_number": 3,
      "content": "ما ودعك ربك وما قلىا"
    },
    {
      "surah_number": 93,
      "verse_number": 4,
      "content": "وللأخره خير لك من الأولىا"
    },
    {
      "surah_number": 93,
      "verse_number": 5,
      "content": "ولسوف يعطيك ربك فترضىا"
    },
    {
      "surah_number": 93,
      "verse_number": 6,
      "content": "ألم يجدك يتيما فٔاوىا"
    },
    {
      "surah_number": 93,
      "verse_number": 7,
      "content": "ووجدك ضالا فهدىا"
    },
    {
      "surah_number": 93,
      "verse_number": 8,
      "content": "ووجدك عائلا فأغنىا"
    },
    {
      "surah_number": 93,
      "verse_number": 9,
      "content": "فأما اليتيم فلا تقهر"
    },
    {
      "surah_number": 93,
      "verse_number": 10,
      "content": "وأما السائل فلا تنهر"
    },
    {
      "surah_number": 93,
      "verse_number": 11,
      "content": "وأما بنعمه ربك فحدث"
    },
    {
      "surah_number": 94,
      "verse_number": 1,
      "content": "ألم نشرح لك صدرك"
    },
    {
      "surah_number": 94,
      "verse_number": 2,
      "content": "ووضعنا عنك وزرك"
    },
    {
      "surah_number": 94,
      "verse_number": 3,
      "content": "الذي أنقض ظهرك"
    },
    {
      "surah_number": 94,
      "verse_number": 4,
      "content": "ورفعنا لك ذكرك"
    },
    {
      "surah_number": 94,
      "verse_number": 5,
      "content": "فان مع العسر يسرا"
    },
    {
      "surah_number": 94,
      "verse_number": 6,
      "content": "ان مع العسر يسرا"
    },
    {
      "surah_number": 94,
      "verse_number": 7,
      "content": "فاذا فرغت فانصب"
    },
    {
      "surah_number": 94,
      "verse_number": 8,
      "content": "والىا ربك فارغب"
    },
    {
      "surah_number": 95,
      "verse_number": 1,
      "content": "والتين والزيتون"
    },
    {
      "surah_number": 95,
      "verse_number": 2,
      "content": "وطور سينين"
    },
    {
      "surah_number": 95,
      "verse_number": 3,
      "content": "وهاذا البلد الأمين"
    },
    {
      "surah_number": 95,
      "verse_number": 4,
      "content": "لقد خلقنا الانسان في أحسن تقويم"
    },
    {
      "surah_number": 95,
      "verse_number": 5,
      "content": "ثم رددناه أسفل سافلين"
    },
    {
      "surah_number": 95,
      "verse_number": 6,
      "content": "الا الذين امنوا وعملوا الصالحات فلهم أجر غير ممنون"
    },
    {
      "surah_number": 95,
      "verse_number": 7,
      "content": "فما يكذبك بعد بالدين"
    },
    {
      "surah_number": 95,
      "verse_number": 8,
      "content": "أليس الله بأحكم الحاكمين"
    },
    {
      "surah_number": 96,
      "verse_number": 1,
      "content": "اقرأ باسم ربك الذي خلق"
    },
    {
      "surah_number": 96,
      "verse_number": 2,
      "content": "خلق الانسان من علق"
    },
    {
      "surah_number": 96,
      "verse_number": 3,
      "content": "اقرأ وربك الأكرم"
    },
    {
      "surah_number": 96,
      "verse_number": 4,
      "content": "الذي علم بالقلم"
    },
    {
      "surah_number": 96,
      "verse_number": 5,
      "content": "علم الانسان ما لم يعلم"
    },
    {
      "surah_number": 96,
      "verse_number": 6,
      "content": "كلا ان الانسان ليطغىا"
    },
    {
      "surah_number": 96,
      "verse_number": 7,
      "content": "أن راه استغنىا"
    },
    {
      "surah_number": 96,
      "verse_number": 8,
      "content": "ان الىا ربك الرجعىا"
    },
    {
      "surah_number": 96,
      "verse_number": 9,
      "content": "أريت الذي ينهىا"
    },
    {
      "surah_number": 96,
      "verse_number": 10,
      "content": "عبدا اذا صلىا"
    },
    {
      "surah_number": 96,
      "verse_number": 11,
      "content": "أريت ان كان على الهدىا"
    },
    {
      "surah_number": 96,
      "verse_number": 12,
      "content": "أو أمر بالتقوىا"
    },
    {
      "surah_number": 96,
      "verse_number": 13,
      "content": "أريت ان كذب وتولىا"
    },
    {
      "surah_number": 96,
      "verse_number": 14,
      "content": "ألم يعلم بأن الله يرىا"
    },
    {
      "surah_number": 96,
      "verse_number": 15,
      "content": "كلا لئن لم ينته لنسفعا بالناصيه"
    },
    {
      "surah_number": 96,
      "verse_number": 16,
      "content": "ناصيه كاذبه خاطئه"
    },
    {
      "surah_number": 96,
      "verse_number": 17,
      "content": "فليدع ناديه"
    },
    {
      "surah_number": 96,
      "verse_number": 18,
      "content": "سندع الزبانيه"
    },
    {
      "surah_number": 96,
      "verse_number": 19,
      "content": "كلا لا تطعه واسجد واقترب"
    },
    {
      "surah_number": 97,
      "verse_number": 1,
      "content": "انا أنزلناه في ليله القدر"
    },
    {
      "surah_number": 97,
      "verse_number": 2,
      "content": "وما أدرىاك ما ليله القدر"
    },
    {
      "surah_number": 97,
      "verse_number": 3,
      "content": "ليله القدر خير من ألف شهر"
    },
    {
      "surah_number": 97,
      "verse_number": 4,
      "content": "تنزل الملائكه والروح فيها باذن ربهم من كل أمر"
    },
    {
      "surah_number": 97,
      "verse_number": 5,
      "content": "سلام هي حتىا مطلع الفجر"
    },
    {
      "surah_number": 98,
      "verse_number": 1,
      "content": "لم يكن الذين كفروا من أهل الكتاب والمشركين منفكين حتىا تأتيهم البينه"
    },
    {
      "surah_number": 98,
      "verse_number": 2,
      "content": "رسول من الله يتلوا صحفا مطهره"
    },
    {
      "surah_number": 98,
      "verse_number": 3,
      "content": "فيها كتب قيمه"
    },
    {
      "surah_number": 98,
      "verse_number": 4,
      "content": "وما تفرق الذين أوتوا الكتاب الا من بعد ما جاتهم البينه"
    },
    {
      "surah_number": 98,
      "verse_number": 5,
      "content": "وما أمروا الا ليعبدوا الله مخلصين له الدين حنفا ويقيموا الصلواه ويؤتوا الزكواه وذالك دين القيمه"
    },
    {
      "surah_number": 98,
      "verse_number": 6,
      "content": "ان الذين كفروا من أهل الكتاب والمشركين في نار جهنم خالدين فيها أولائك هم شر البريه"
    },
    {
      "surah_number": 98,
      "verse_number": 7,
      "content": "ان الذين امنوا وعملوا الصالحات أولائك هم خير البريه"
    },
    {
      "surah_number": 98,
      "verse_number": 8,
      "content": "جزاؤهم عند ربهم جنات عدن تجري من تحتها الأنهار خالدين فيها أبدا رضي الله عنهم ورضوا عنه ذالك لمن خشي ربه"
    },
    {
      "surah_number": 99,
      "verse_number": 1,
      "content": "اذا زلزلت الأرض زلزالها"
    },
    {
      "surah_number": 99,
      "verse_number": 2,
      "content": "وأخرجت الأرض أثقالها"
    },
    {
      "surah_number": 99,
      "verse_number": 3,
      "content": "وقال الانسان ما لها"
    },
    {
      "surah_number": 99,
      "verse_number": 4,
      "content": "يومئذ تحدث أخبارها"
    },
    {
      "surah_number": 99,
      "verse_number": 5,
      "content": "بأن ربك أوحىا لها"
    },
    {
      "surah_number": 99,
      "verse_number": 6,
      "content": "يومئذ يصدر الناس أشتاتا ليروا أعمالهم"
    },
    {
      "surah_number": 99,
      "verse_number": 7,
      "content": "فمن يعمل مثقال ذره خيرا يره"
    },
    {
      "surah_number": 99,
      "verse_number": 8,
      "content": "ومن يعمل مثقال ذره شرا يره"
    },
    {
      "surah_number": 100,
      "verse_number": 1,
      "content": "والعاديات ضبحا"
    },
    {
      "surah_number": 100,
      "verse_number": 2,
      "content": "فالموريات قدحا"
    },
    {
      "surah_number": 100,
      "verse_number": 3,
      "content": "فالمغيرات صبحا"
    },
    {
      "surah_number": 100,
      "verse_number": 4,
      "content": "فأثرن به نقعا"
    },
    {
      "surah_number": 100,
      "verse_number": 5,
      "content": "فوسطن به جمعا"
    },
    {
      "surah_number": 100,
      "verse_number": 6,
      "content": "ان الانسان لربه لكنود"
    },
    {
      "surah_number": 100,
      "verse_number": 7,
      "content": "وانه علىا ذالك لشهيد"
    },
    {
      "surah_number": 100,
      "verse_number": 8,
      "content": "وانه لحب الخير لشديد"
    },
    {
      "surah_number": 100,
      "verse_number": 9,
      "content": "أفلا يعلم اذا بعثر ما في القبور"
    },
    {
      "surah_number": 100,
      "verse_number": 10,
      "content": "وحصل ما في الصدور"
    },
    {
      "surah_number": 100,
      "verse_number": 11,
      "content": "ان ربهم بهم يومئذ لخبير"
    },
    {
      "surah_number": 101,
      "verse_number": 1,
      "content": "القارعه"
    },
    {
      "surah_number": 101,
      "verse_number": 2,
      "content": "ما القارعه"
    },
    {
      "surah_number": 101,
      "verse_number": 3,
      "content": "وما أدرىاك ما القارعه"
    },
    {
      "surah_number": 101,
      "verse_number": 4,
      "content": "يوم يكون الناس كالفراش المبثوث"
    },
    {
      "surah_number": 101,
      "verse_number": 5,
      "content": "وتكون الجبال كالعهن المنفوش"
    },
    {
      "surah_number": 101,
      "verse_number": 6,
      "content": "فأما من ثقلت موازينه"
    },
    {
      "surah_number": 101,
      "verse_number": 7,
      "content": "فهو في عيشه راضيه"
    },
    {
      "surah_number": 101,
      "verse_number": 8,
      "content": "وأما من خفت موازينه"
    },
    {
      "surah_number": 101,
      "verse_number": 9,
      "content": "فأمه هاويه"
    },
    {
      "surah_number": 101,
      "verse_number": 10,
      "content": "وما أدرىاك ما هيه"
    },
    {
      "surah_number": 101,
      "verse_number": 11,
      "content": "نار حاميه"
    },
    {
      "surah_number": 102,
      "verse_number": 1,
      "content": "ألهىاكم التكاثر"
    },
    {
      "surah_number": 102,
      "verse_number": 2,
      "content": "حتىا زرتم المقابر"
    },
    {
      "surah_number": 102,
      "verse_number": 3,
      "content": "كلا سوف تعلمون"
    },
    {
      "surah_number": 102,
      "verse_number": 4,
      "content": "ثم كلا سوف تعلمون"
    },
    {
      "surah_number": 102,
      "verse_number": 5,
      "content": "كلا لو تعلمون علم اليقين"
    },
    {
      "surah_number": 102,
      "verse_number": 6,
      "content": "لترون الجحيم"
    },
    {
      "surah_number": 102,
      "verse_number": 7,
      "content": "ثم لترونها عين اليقين"
    },
    {
      "surah_number": 102,
      "verse_number": 8,
      "content": "ثم لتسٔلن يومئذ عن النعيم"
    },
    {
      "surah_number": 103,
      "verse_number": 1,
      "content": "والعصر"
    },
    {
      "surah_number": 103,
      "verse_number": 2,
      "content": "ان الانسان لفي خسر"
    },
    {
      "surah_number": 103,
      "verse_number": 3,
      "content": "الا الذين امنوا وعملوا الصالحات وتواصوا بالحق وتواصوا بالصبر"
    },
    {
      "surah_number": 104,
      "verse_number": 1,
      "content": "ويل لكل همزه لمزه"
    },
    {
      "surah_number": 104,
      "verse_number": 2,
      "content": "الذي جمع مالا وعدده"
    },
    {
      "surah_number": 104,
      "verse_number": 3,
      "content": "يحسب أن ماله أخلده"
    },
    {
      "surah_number": 104,
      "verse_number": 4,
      "content": "كلا لينبذن في الحطمه"
    },
    {
      "surah_number": 104,
      "verse_number": 5,
      "content": "وما أدرىاك ما الحطمه"
    },
    {
      "surah_number": 104,
      "verse_number": 6,
      "content": "نار الله الموقده"
    },
    {
      "surah_number": 104,
      "verse_number": 7,
      "content": "التي تطلع على الأفٔده"
    },
    {
      "surah_number": 104,
      "verse_number": 8,
      "content": "انها عليهم مؤصده"
    },
    {
      "surah_number": 104,
      "verse_number": 9,
      "content": "في عمد ممدده"
    },
    {
      "surah_number": 105,
      "verse_number": 1,
      "content": "ألم تر كيف فعل ربك بأصحاب الفيل"
    },
    {
      "surah_number": 105,
      "verse_number": 2,
      "content": "ألم يجعل كيدهم في تضليل"
    },
    {
      "surah_number": 105,
      "verse_number": 3,
      "content": "وأرسل عليهم طيرا أبابيل"
    },
    {
      "surah_number": 105,
      "verse_number": 4,
      "content": "ترميهم بحجاره من سجيل"
    },
    {
      "surah_number": 105,
      "verse_number": 5,
      "content": "فجعلهم كعصف مأكول"
    },
    {
      "surah_number": 106,
      "verse_number": 1,
      "content": "لايلاف قريش"
    },
    {
      "surah_number": 106,
      "verse_number": 2,
      "content": "الافهم رحله الشتا والصيف"
    },
    {
      "surah_number": 106,
      "verse_number": 3,
      "content": "فليعبدوا رب هاذا البيت"
    },
    {
      "surah_number": 106,
      "verse_number": 4,
      "content": "الذي أطعمهم من جوع وامنهم من خوف"
    },
    {
      "surah_number": 107,
      "verse_number": 1,
      "content": "أريت الذي يكذب بالدين"
    },
    {
      "surah_number": 107,
      "verse_number": 2,
      "content": "فذالك الذي يدع اليتيم"
    },
    {
      "surah_number": 107,
      "verse_number": 3,
      "content": "ولا يحض علىا طعام المسكين"
    },
    {
      "surah_number": 107,
      "verse_number": 4,
      "content": "فويل للمصلين"
    },
    {
      "surah_number": 107,
      "verse_number": 5,
      "content": "الذين هم عن صلاتهم ساهون"
    },
    {
      "surah_number": 107,
      "verse_number": 6,
      "content": "الذين هم يراون"
    },
    {
      "surah_number": 107,
      "verse_number": 7,
      "content": "ويمنعون الماعون"
    },
    {
      "surah_number": 108,
      "verse_number": 1,
      "content": "انا أعطيناك الكوثر"
    },
    {
      "surah_number": 108,
      "verse_number": 2,
      "content": "فصل لربك وانحر"
    },
    {
      "surah_number": 108,
      "verse_number": 3,
      "content": "ان شانئك هو الأبتر"
    },
    {
      "surah_number": 109,
      "verse_number": 1,
      "content": "قل ياأيها الكافرون"
    },
    {
      "surah_number": 109,
      "verse_number": 2,
      "content": "لا أعبد ما تعبدون"
    },
    {
      "surah_number": 109,
      "verse_number": 3,
      "content": "ولا أنتم عابدون ما أعبد"
    },
    {
      "surah_number": 109,
      "verse_number": 4,
      "content": "ولا أنا عابد ما عبدتم"
    },
    {
      "surah_number": 109,
      "verse_number": 5,
      "content": "ولا أنتم عابدون ما أعبد"
    },
    {
      "surah_number": 109,
      "verse_number": 6,
      "content": "لكم دينكم ولي دين"
    },
    {
      "surah_number": 110,
      "verse_number": 1,
      "content": "اذا جا نصر الله والفتح"
    },
    {
      "surah_number": 110,
      "verse_number": 2,
      "content": "ورأيت الناس يدخلون في دين الله أفواجا"
    },
    {
      "surah_number": 110,
      "verse_number": 3,
      "content": "فسبح بحمد ربك واستغفره انه كان توابا"
    },
    {
      "surah_number": 111,
      "verse_number": 1,
      "content": "تبت يدا أبي لهب وتب"
    },
    {
      "surah_number": 111,
      "verse_number": 2,
      "content": "ما أغنىا عنه ماله وما كسب"
    },
    {
      "surah_number": 111,
      "verse_number": 3,
      "content": "سيصلىا نارا ذات لهب"
    },
    {
      "surah_number": 111,
      "verse_number": 4,
      "content": "وامرأته حماله الحطب"
    },
    {
      "surah_number": 111,
      "verse_number": 5,
      "content": "في جيدها حبل من مسد"
    },
    {
      "surah_number": 112,
      "verse_number": 1,
      "content": "قل هو الله أحد"
    },
    {
      "surah_number": 112,
      "verse_number": 2,
      "content": "الله الصمد"
    },
    {
      "surah_number": 112,
      "verse_number": 3,
      "content": "لم يلد ولم يولد"
    },
    {
      "surah_number": 112,
      "verse_number": 4,
      "content": "ولم يكن له كفوا أحد"
    },
    {
      "surah_number": 113,
      "verse_number": 1,
      "content": "قل أعوذ برب الفلق"
    },
    {
      "surah_number": 113,
      "verse_number": 2,
      "content": "من شر ما خلق"
    },
    {
      "surah_number": 113,
      "verse_number": 3,
      "content": "ومن شر غاسق اذا وقب"
    },
    {
      "surah_number": 113,
      "verse_number": 4,
      "content": "ومن شر النفاثات في العقد"
    },
    {
      "surah_number": 113,
      "verse_number": 5,
      "content": "ومن شر حاسد اذا حسد"
    },
    {
      "surah_number": 114,
      "verse_number": 1,
      "content": "قل أعوذ برب الناس"
    },
    {
      "surah_number": 114,
      "verse_number": 2,
      "content": "ملك الناس"
    },
    {
      "surah_number": 114,
      "verse_number": 3,
      "content": "الاه الناس"
    },
    {
      "surah_number": 114,
      "verse_number": 4,
      "content": "من شر الوسواس الخناس"
    },
    {
      "surah_number": 114,
      "verse_number": 5,
      "content": "الذي يوسوس في صدور الناس"
    },
    {
      "surah_number": 114,
      "verse_number": 6,
      "content": "من الجنه والناس"
    }
  ];


}