import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:quran_moben/app/views/home_view/widgets/action_buttons_raw.dart';
import 'package:quran_moben/utils/extensions.dart';
import '../../../data/db/surahs_data.dart';
import '../../controllers/quran_page_controller.dart';
import '../../models/verse_model.dart';

class QuranPageView extends StatelessWidget {
  final QuranPageController controller = Get.find<QuranPageController>();
  final int initialPage;

  QuranPageView({super.key, required this.initialPage}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.goToPage(initialPage);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const baseFontSize = 23.0;
    const baseScreenWidth = 411.4;
    final fontSizeRatio = screenSize.width / baseScreenWidth;
    final responsiveFontSize = baseFontSize * fontSizeRatio;
    const lineHeight = 2.4;
    final letterSpacing = 2.0 * fontSizeRatio;
    final wordSpacing =
        (controller.containsMultipleSurahs ? 5.0 : 0.0) * fontSizeRatio;
    final horizontalPadding = 10.0 * fontSizeRatio;

    return Obx(
      () => Scaffold(
        backgroundColor: controller.backgroundColor.value,
        body: Column(
          children: [
            (screenHeight(context) * 0.02).sh,

            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  controller.loadPageData(index + 1);
                },
                itemCount: controller.totalPages,
                itemBuilder: (context, index) {
                  return FutureBuilder<List<Verse>>(
                    future: controller.fetchPageData(index + 1),
                    builder: (context, snapshot) {
                      final verses = snapshot.data ??
                          controller.cachedPages[index + 1] ??
                          [];

                      if (verses.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding:
                            EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: _buildTextSpans(
                              context,
                              verses,
                              responsiveFontSize,
                              lineHeight,
                              letterSpacing,
                              wordSpacing,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

          ],
        ),
      ),
    );
  }

  List<InlineSpan> _buildTextSpans(
    BuildContext context,
    List<Verse> verses,
    double fontSize,
    double lineHeight,
    double letterSpacing,
    double wordSpacing,
  ) {
    List<InlineSpan> spans = [];
    int? previousSurah;

    if (verses.isNotEmpty && verses.first.verseNumber != 1) {
      spans.add(
        WidgetSpan(
          child: InkWell(
            onTap: () {
              _showAllSurahsBottomSheet(context);
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(left: 4.0, right: 4.0, top: 8),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              decoration: BoxDecoration(
                color: controller.textColor.value.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الحزب ${controller.getHizbForPage(controller.currentPageIndex.value)}',
                    style: TextStyle(
                      color: controller.textColor.value,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Column(
                    children: [
                      Padding(
                        padding:
                            EdgeInsets.only(bottom: screenHeight(context) * 0.01),
                        child: Text(
                          '${controller.getSurahNameForPage(controller.currentPageIndex.value)} | الجزء ${controller.getJuzForPage(controller.currentPageIndex.value)}',
                          style: TextStyle(
                            color: controller.textColor.value,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (controller.getQuarterForPage(
                              controller.currentPageIndex.value) >
                          0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            controller.getQuarterForPage(
                                controller.currentPageIndex.value),
                            (index) => Container(
                              height: 2,
                              width: 30,
                              decoration: BoxDecoration(
                                color: controller.textColor.value,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      SvgPicture.asset(
                        controller.currentPageIndex.value.isEven
                            ? 'assets/images/left.svg'
                            : 'assets/images/right.svg',
                        colorFilter: ColorFilter.mode(
                          controller.textColor.value,
                          BlendMode.srcIn,
                        ),
                        height: 20,
                      ),
                      (screenWidth(context) * 0.01).sw,
                      Text(
                        'صفحة ${controller.currentPageIndex.value}',
                        style: TextStyle(
                          color: controller.textColor.value,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    for (var verse in verses) {
      if ((previousSurah == null && verse.verseNumber == 1) ||
          (previousSurah != null && verse.surahNumber != previousSurah)) {
        String surahName = controller.allChapters
            .firstWhere((s) => s.id == verse.surahNumber)
            .name;

        spans.add(WidgetSpan(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/border.svg',
                    colorFilter: ColorFilter.mode(
                      controller.textColor.value,
                      BlendMode.srcIn,
                    ),
                    height: fontSize * 3,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          surahName,
                          style: TextStyle(
                            fontSize: fontSize * 1.2,
                            color: controller.textColor.value,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Uthman',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${controller.currentPageIndex.value}',
                          style: TextStyle(
                            color: controller.textColor.value,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${controller.currentPageIndex.value}',
                          style: TextStyle(
                            color: controller.textColor.value,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (verse.surahNumber != 9 &&
                  verse.verseNumber == 1 &&
                  verse.surahNumber != 1)
                SvgPicture.asset(
                  'assets/images/bis.svg',
                  colorFilter: ColorFilter.mode(
                    controller.textColor.value,
                    BlendMode.srcIn,
                  ),
                  height: fontSize * 1.5,
                ),
            ],
          ),
        ));
      }

      String verseText = verse.qcfData.replaceAll(' ', '');

      spans.add(
        TextSpan(
          text: verseText,
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              _showVerseBottomSheet(context, verse);
            },
          style: TextStyle(
            color: controller.textColor.value,
            height: lineHeight,
            letterSpacing: letterSpacing,
            wordSpacing: wordSpacing,
            fontFamily: controller.fontName,
            fontSize: fontSize,
          ),
        ),
      );

      previousSurah = verse.surahNumber;
    }

    return spans;
  }

  void _showAllSurahsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: controller.backgroundColor.value,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  height: 5,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: controller.textColor.value,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: surahs.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        surahs[index].name,
                        style: TextStyle(color: controller.textColor.value),
                      ),
                      onTap: () {
                       controller.goToSurah(index+1);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }




  void _showVerseBottomSheet(BuildContext context, Verse verse) {
    String surahName = controller.allChapters
        .firstWhere((s) => s.id == verse.surahNumber)
        .name;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: controller.backgroundColor.value,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Wrap(
            children: [
              Center(
                child: Container(
                  height: 5,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: controller.textColor.value,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: controller.textColor.value.withOpacity(0.1),
                ),
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              controller.textColor.value.withOpacity(0.15),
                          child: Text(
                            '${verse.verseNumber}',
                            style: TextStyle(
                              color: controller.textColor.value,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          surahName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: controller.textColor.value,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.copy,
                              color: controller.textColor.value),
                          onPressed: () async {
                            await Clipboard.setData(
                                ClipboardData(text: verse.content));
                          },
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        verse.qcfData,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          height: 1.8,
                          color: controller.textColor.value,
                          fontFamily: controller.fontName,
                        ),
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${controller.getQuarter(
                            verse.surahNumber,
                            verse.verseNumber,
                          )}',
                          style: TextStyle(
                            fontSize: 14,
                            color: controller.textColor.value,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              ActionButtonsRaw(
                verse: verse,
                controller: controller,
              ),

              (screenHeight(context) * 0.1).sh,
            ],
          ),
        );
      },
    );
  }
}
