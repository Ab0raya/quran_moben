import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_moben/app/models/surah_model.dart';
import 'package:quran_moben/app/views/home_view/quran_page_view.dart';
import 'package:quran_moben/app/controllers/quran_page_controller.dart';
import 'package:quran_moben/utils/colors.dart';
import '../../../../data/db/page_data.dart';

class JuzTile extends StatelessWidget {
  final int juzNumber;
  final List<Surah> surahsInJuz;

  const JuzTile({
    super.key,
    required this.juzNumber,
    required this.surahsInJuz,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'الجزء $juzNumber',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      collapsedBackgroundColor: AppColors.bgColor,
      backgroundColor: AppColors.textPrimary.withOpacity(0.1),
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: surahsInJuz.map((surah) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: InkWell(
          onTap: () {
            final QuranPageController quranController = Get.find<QuranPageController>();
            int? targetPage;

            for (int i = 0; i < pageData.length; i++) {
              for (var detail in pageData[i]) {
                if (detail['surah'] == surah.id) {
                  targetPage = i + 1;
                  break;
                }
              }
              if (targetPage != null) break;
            }

            if (targetPage != null) {
              if (Get.currentRoute != '/quran_page_view') {
                Get.to(() => QuranPageView(initialPage: targetPage?? 1));
              } else {
                quranController.goToPage(targetPage);
                Get.back();
              }
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'سورة ${surah.name}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              Text(
                'آيات: ${surah.totalVerses}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }
}
