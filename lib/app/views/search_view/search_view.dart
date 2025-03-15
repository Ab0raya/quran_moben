import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        title: const Text('البحث'),
        backgroundColor: AppColors.bgColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomTextField(
              onChanged: (value) => controller.searchQuran(value),
              hint: 'الايه',
              obscureText: false,
              height: screenHeight(context) * 0.065,
            ),
          ),
          Expanded(
            child: Obx(
              () => ListView.builder(
                itemCount: controller.filteredQuranText.length,
                itemBuilder: (context, index) {
                  final verse = controller.filteredQuranText[index];
                  return GlassContainer(
                    height: screenHeight(context) * 0.12,
                    width: screenWidth(context) * 0.8,
                    horMargin: screenWidth(context) * 0.05,
                    virMargin: screenHeight(context) * 0.005,
                    onTap: () {
                      final QuranPageController quranController =
                          Get.find<QuranPageController>();

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
                        if (Get.currentRoute != '/quran_page_view') {
                          Get.to(() =>
                              QuranPageView(initialPage: targetPage ?? 1));
                        } else {
                          quranController.goToPage(targetPage);
                          Get.back();
                        }
                      }
                    },
                    child: ListTile(
                      title: Text(
                        verse['content'],
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        'Surah ${verse['surah_number']} - Ayah ${verse['verse_number']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
