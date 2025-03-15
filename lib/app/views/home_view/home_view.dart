import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_moben/app/views/home_view/quran_page_view.dart';
import 'package:quran_moben/app/views/home_view/widgets/custom_tab_bar.dart';
import 'package:quran_moben/app/views/home_view/widgets/last_read_card.dart';
import 'package:quran_moben/app/views/home_view/widgets/surah_tile.dart';
import 'package:quran_moben/app/views/home_view/widgets/juz_tile.dart';
import 'package:quran_moben/app/views/search_view/search_view.dart';
import 'package:quran_moben/app/views/settings_view/views/settings_view.dart';
import 'package:quran_moben/data/db/surahs_data.dart';

import '../../../data/db/page_data.dart';
import '../../../utils/colors.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/quran_page_controller.dart';
import '../../models/surah_model.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  Map<int, List<Surah>> _groupSurahsByJuz() {
    Map<int, List<Surah>> juzMap = {};
    for (var surah in surahs) {
      if (!juzMap.containsKey(surah.juz)) {
        juzMap[surah.juz] = [];
      }
      juzMap[surah.juz]!.add(surah);
    }
    return juzMap;
  }

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.put(HomeController());
    final juzGroupedSurahs = _groupSurahsByJuz();
    Get.put(QuranPageController());
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Get.to(QuranSearchView());
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Get.to(const SettingsView());
            },
          ),
        ],
        title: Image.asset(
          'assets/images/horLogo.png',
          height: 30,
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        Widget tabContent;
        switch (homeController.selectedTabIndex.value) {
          case 0:
            tabContent = ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: surahs.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: AppColors.divider,
                endIndent: 50,
                indent: 50,
              ),
              itemBuilder: (context, index) {
                final surah = surahs[index];
                return SurahTile(
                  number: surah.id,
                  name: surah.name,
                  origin: surah.type,
                  versesCount: surah.totalVerses,
                  onTap: () {
                    final QuranPageController controller =
                        Get.find<QuranPageController>();

                    if (Get.currentRoute != '/quran_page_view') {
                      Get.to(() => QuranPageView(initialPage: surah.startPage));
                    } else {
                      controller.goToPage(surah.startPage);
                      Get.back();
                    }
                  },
                );
              },
            );
            break;
          case 1:
            tabContent = ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: juzGroupedSurahs.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: AppColors.divider,
                endIndent: 20,
                indent: 20,
              ),
              itemBuilder: (context, index) {
                final juzNumber = juzGroupedSurahs.keys.elementAt(index);
                final surahsInJuz = juzGroupedSurahs[juzNumber]!;
                return JuzTile(
                    juzNumber: juzNumber,
                    surahsInJuz: surahsInJuz,
                  );
              },
            );
            break;
          case 2:
            tabContent = const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'محتوى الختمات',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            );
            break;
          default:
            tabContent = const SizedBox();
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  'السلام عليكم',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 18,
                  ),
                ),
              ),
               Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  homeController.savedName.value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Obx(() {
                  final QuranPageController controller =
                      Get.find<QuranPageController>();

                  String surahName = 'الفاتحة';
                  int ayahNumber = 1;
                  int pageNumber = 1;

                  if (controller.bookmarkedVerses.isNotEmpty) {
                    final lastBookmark = controller.bookmarkedVerses.last;
                    final parts = lastBookmark.split(':');

                    if (parts.length == 2) {
                      final surahId = int.tryParse(parts[0]);
                      final verseId = int.tryParse(parts[1]);

                      if (surahId != null && verseId != null) {
                        surahName = controller.allChapters
                            .firstWhere((s) => s.id == surahId,
                                orElse: () => controller.allChapters.first)
                            .name;
                        ayahNumber = verseId;

                        for (int i = 0; i < controller.totalPages; i++) {
                          final pageDetails = pageData[i];
                          for (var detail in pageDetails) {
                            if (detail['surah'] == surahId &&
                                detail['start'] <= verseId &&
                                detail['end'] >= verseId) {
                              pageNumber = i + 1;
                              break;
                            }
                          }
                        }
                      }
                    }
                  }

                  return LastReadCard(
                    surahName: surahName,
                    ayahNumber: '$ayahNumber',
                    onTap: () {
                      final QuranPageController controller =
                          Get.find<QuranPageController>();

                      if (Get.currentRoute != '/quran_page_view') {
                        Get.to(() => QuranPageView(initialPage: pageNumber));
                      } else {
                        controller.goToPage(pageNumber);
                        Get.back();
                      }
                    },
                  );
                }),
              ),
              const SizedBox(height: 20),
              CustomTabBar(controller: homeController),
              tabContent,
            ],
          ),
        );
      }),
    );
  }
}
