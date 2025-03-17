import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quran_moben/app/views/widgets/custom_textfield.dart';
import 'package:quran_moben/app/views/widgets/glass_container.dart';
import 'package:quran_moben/utils/colors.dart';
import 'package:quran_moben/utils/extensions.dart';

import '../../../data/db/page_data.dart';
import '../../controllers/quran_page_controller.dart';
import '../../controllers/quran_search_controller.dart';
import '../home_view/quran_page_view.dart';

class QuranSearchView extends StatelessWidget {
  final QuranSearchController controller = Get.put(QuranSearchController());

  QuranSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: AppColors.accentColor),
        scrolledUnderElevation: 0,
        title: const Text(
          'البحث في القرآن',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.accentColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.bgColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showSearchTips(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.bgColor,
              AppColors.bgColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomTextField(
                onChanged: (value) => controller.searchQuran(value),
                hint: 'ابحث عن آية أو كلمة',
                obscureText: false,
                height: screenHeight(context) * 0.065,
                icon:  Icons.search,
                suffixIcon: Obx(() => controller.searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.accentColor),
                  onPressed: () {
                    controller.clearSearch();
                  },
                )
                    : const SizedBox()),
              ),
            ),
            Obx(() => _buildFilters(context)),
            Expanded(
              child: Obx(
                    () => controller.isLoading.value
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentColor,
                  ),
                )
                    : controller.filteredQuranText.isEmpty
                    ? _buildEmptyState(context)
                    : _buildSearchResults(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: controller.showFilters.value ? 60 : 0,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            _buildFilterChip(
              context,
              "جزء",
              controller.filterByJuz.value,
                  () => controller.toggleJuzFilter(),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context,
              "سورة",
              controller.filterBySurah.value,
                  () => controller.toggleSurahFilter(),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context,
              "حزب",
              controller.filterByHizb.value,
                  () => controller.toggleHizbFilter(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      BuildContext context, String label, bool isSelected, Function() onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accentColor.withOpacity(0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.accentColor
                : AppColors.accentColor.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: controller.filteredQuranText.length,
      itemBuilder: (context, index) {
        final verse = controller.filteredQuranText[index];
        return GlassContainer(
          //height: screenHeight(context)*0.12, // Allow dynamic height
          //minHeight: screenHeight(context) * 0.12,
          width: screenWidth(context) * 0.9,
          horMargin: screenWidth(context) * 0.05,
          virMargin: screenHeight(context) * 0.01,
          borderRadius: 16,
          // blur: 10,
          // opacity: 0.2,
          // border: 1.5,
          onTap: () => _navigateToQuranPage(verse),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  verse['content'],
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.accentColor,
                    fontFamily: 'KFGQPC Uthmanic Script HAFS',
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.bookmark_border,
                        color: AppColors.accentColor,
                        size: 20,
                      ),
                      onPressed: () => controller.bookmarkVerse(verse),
                    ),
                    Row(
                      children: [
                        Text(
                          'آية ${verse['verse_number']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${verse['surah_name']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentColor,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/icon.png',
            height: 100,
            color: AppColors.accentColor.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            controller.searchQuery.isEmpty
                ? 'ابدأ البحث عن آية أو كلمة'
                : 'لم يتم العثور على نتائج',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.accentColor.withOpacity(0.7),
              fontFamily: 'Amiri',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          if (controller.searchQuery.isNotEmpty)
            ElevatedButton(
              onPressed: () => controller.clearSearch(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentColor.withOpacity(0.2),
                foregroundColor: AppColors.accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('مسح البحث'),
            ),
        ],
      ),
    );
  }

  void _navigateToQuranPage(Map<String, dynamic> verse) {
    final QuranPageController quranController = Get.find<QuranPageController>();

    int surahNumber = verse['surah_number'];
    int verseNumber = verse['verse_number'];

    int? targetPage;
    for (int i = 0; i < pageData.length; i++) {
      for (var detail in pageData[i]) {
        if (detail['surah'] == surahNumber &&
            detail['start'] <= verseNumber &&
            detail['end'] >= verseNumber) {
          targetPage = i + 1;
          break;
        }
      }
      if (targetPage != null) break;
    }

    if (targetPage != null) {
      // Save search history
      controller.addToSearchHistory(verse);

      // Show a snackbar with verse info
      Get.snackbar(
        'الانتقال إلى الصفحة $targetPage',
        'سورة ${verse['surah_name']} - آية ${verse['verse_number']}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.accentColor.withOpacity(0.2),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );

      if (Get.currentRoute != '/quran_page_view') {
        Get.to(() => QuranPageView(
          initialPage: targetPage ?? 1,
          // highlightSurah: surahNumber,
          // highlightVerse: verseNumber,
        ));
      } else {
        quranController.goToPage(targetPage);
       // quranController.highlightVerse(surahNumber, verseNumber);
        Get.back();
      }
    }
  }

  void _showSearchTips(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        height: screenHeight(context) * 0.4,
        width: screenWidth(context),
        // blur: 10,
        // opacity: 0.2,
        borderRadius: 20,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Center(
                child: Text(
                  'نصائح البحث',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentColor,
                    fontFamily: 'Amiri',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '• يمكنك البحث عن كلمة أو جزء من آية',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• يمكنك البحث بدون تشكيل',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• استخدم الفلاتر للبحث في أجزاء محددة',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: Size(screenWidth(context) * 0.5, 40),
                  ),
                  child: const Text(
                    'فهمت',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}