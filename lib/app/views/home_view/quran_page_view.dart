import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran_moben/utils/colors.dart';
import 'package:quran_moben/utils/extensions.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/db/surahs_data.dart';
import '../../controllers/quran_page_controller.dart';
import '../../models/surah_model.dart';
import '../../models/verse_model.dart';
import '../../services/tafsir_service.dart';

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
            (screenHeight(context) * 0.03).sh,
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  '${controller.currentPageIndex.value}',
                  style: TextStyle(
                    color: controller.textColor.value,
                    fontSize: 0,
                  ),
                ),
              ],
            ),
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
                        padding: EdgeInsets.only(
                            bottom: screenHeight(context) * 0.01),
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
                            controller.getCountByPageNumber(
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

        var totalAyahs = controller.allChapters
            .firstWhere((s) => s.id == verse.surahNumber)
            .totalVerses;

        spans.add(WidgetSpan(
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  _showAllSurahsBottomSheet(context);
                },
                child: Stack(
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
                            '$totalAyahs آيات',
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
                        controller.goToSurah(index + 1);
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


  //---------------------------------

  Future<void> _shareVerseAsImage(
      BuildContext context, Verse verse, String surahName) async {
    // Create a key for the widget we want to capture
    final GlobalKey repaintKey = GlobalKey();

    // First render the content in an off-screen widget
    final Widget contentWidget = Material(
      color: Colors.transparent,
      child: RepaintBoundary(
        key: repaintKey,
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                verse.qcfData,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.8,
                  color: AppColors.textPrimary,
                  fontFamily: controller.fontName,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$surahName: آية ${verse.verseNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Image.asset(
                'assets/images/horLogo.png',
                // Make sure you have a PNG version of your logo
                height: screenHeight(context) * 0.03,
                width: screenWidth(context) * 0.3,
              ),
            ],
          ),
        ),
      ),
    );

    // Use a completer to handle the dialog closing
    final completer = Completer<void>();

    // Show the dialog first
    showDialog(
      context: context,
      builder: (dialogContext) {
        // We'll use this dialogContext which is valid within this builder
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              contentWidget,
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); // Close dialog
                      completer.complete(); // Signal that dialog is closed
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                      foregroundColor: AppColors.bgColor,
                    ),
                    child: const Text('مشاركة'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); // Close dialog
                      completer
                          .completeError('Cancelled'); // Signal cancellation
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bgColor,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: const Text('إلغاء'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    try {
      // Wait for the dialog to be closed
      await completer.future;

      // Now that the dialog is closed, we can capture the image
      RenderRepaintBoundary boundary = repaintKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File(
            '${tempDir.path}/verse_${verse.surahNumber}_${verse.verseNumber}.png');
        await file.writeAsBytes(byteData.buffer.asUint8List());

        // Share the image
        await Share.shareXFiles(
          [XFile(file.path)],
          text: '$surahName: آية ${verse.verseNumber}',
        );
      }
    } catch (e) {
      if (e != 'Cancelled') {
        print('Error sharing image: $e');
        Get.snackbar(
          'خطأ',
          'حدث خطأ أثناء مشاركة الصورة',
          backgroundColor: controller.backgroundColor.value,
          colorText: controller.textColor.value,
        );
      }
    }
  }

  // Future<void> _shareVerseAsImage(
  //     BuildContext context, Verse verse, String surahName) async {
  //   await showDialog(
  //     context: context,
  //     builder: (context) {
  //       return Dialog(
  //         backgroundColor: Colors.transparent,
  //         child: RepaintBoundary(
  //           key: _verseImageKey,
  //           child: Container(
  //             width: 350,
  //             padding: const EdgeInsets.all(20),
  //             decoration: BoxDecoration(
  //               color: controller.backgroundColor.value,
  //               borderRadius: BorderRadius.circular(15),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.black.withOpacity(0.2),
  //                   blurRadius: 10,
  //                   spreadRadius: 2,
  //                 )
  //               ],
  //             ),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Container(
  //                   height: 40,
  //                   alignment: Alignment.center,
  //                   child: Text(
  //                     'قرآن مبين',
  //                     style: TextStyle(
  //                       fontSize: 18,
  //                       fontWeight: FontWeight.bold,
  //                       color: controller.textColor.value,
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 Text(
  //                   verse.qcfData,
  //                   textAlign: TextAlign.center,
  //                   style: TextStyle(
  //                     fontSize: 24,
  //                     height: 1.8,
  //                     color: controller.textColor.value,
  //                     fontFamily: controller.fontName,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 Container(
  //                   padding:
  //                       const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //                   decoration: BoxDecoration(
  //                     color: controller.textColor.value.withOpacity(0.1),
  //                     borderRadius: BorderRadius.circular(20),
  //                   ),
  //                   child: Text(
  //                     '$surahName: آية ${verse.verseNumber}',
  //                     style: TextStyle(
  //                       fontSize: 16,
  //                       color: controller.textColor.value,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 SvgPicture.asset(
  //                   'assets/images/logo.svg',
  //                   colorFilter: ColorFilter.mode(
  //                     controller.textColor.value,
  //                     BlendMode.srcIn,
  //                   ),
  //                   height: screenHeight(context) * 0.1,
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  //
  //   try {
  //     RenderRepaintBoundary boundary = _verseImageKey.currentContext!
  //         .findRenderObject() as RenderRepaintBoundary;
  //     ui.Image image = await boundary.toImage(pixelRatio: 3.0);
  //     ByteData? byteData =
  //         await image.toByteData(format: ui.ImageByteFormat.png);
  //
  //     if (byteData != null) {
  //       final tempDir = await getTemporaryDirectory();
  //       final file = File(
  //           '${tempDir.path}/verse_${verse.surahNumber}_${verse.verseNumber}.png');
  //       await file.writeAsBytes(byteData.buffer.asUint8List());
  //
  //       await Share.shareXFiles(
  //         [XFile(file.path)],
  //         text: '$surahName: آية ${verse.verseNumber}',
  //       );
  //     }
  //   } catch (e) {
  //     print('Error sharing image: $e');
  //     Get.snackbar(
  //       'خطأ',
  //       'حدث خطأ أثناء مشاركة الصورة',
  //       backgroundColor: controller.backgroundColor.value,
  //       colorText: controller.textColor.value,
  //     );
  //   }
  // }

  //---------------------------------
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
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _actionButton(
                    icon: controller.isVerseBookmarked(verse)
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    label: 'وضع علامة',
                    color: controller.textColor.value,
                    onTap: () async {
                      await controller.toggleBookmark(verse);
                      Get.back();
                      Get.snackbar(
                        'المرجع',
                        controller.isVerseBookmarked(verse)
                            ? 'تمت إضافة العلامة'
                            : 'تمت إزالة العلامة',
                        backgroundColor: controller.backgroundColor.value,
                        colorText: controller.textColor.value,
                        borderWidth: 1,
                        borderRadius: 12,
                        borderColor: controller.textColor.value,
                        icon: controller.isVerseBookmarked(verse)
                            ? Icon(Icons.bookmark,
                                color: controller.textColor.value)
                            : Icon(Icons.bookmark_border,
                                color: controller.textColor.value),
                      );
                    },
                  ),
                  _actionButton(
                    icon: Icons.volume_up_rounded,
                    label: 'إستماع',
                    color: controller.textColor.value,
                    onTap: () {
                      controller.playAudio(
                          surahNumber: verse.surahNumber,
                          verseNumber: verse.verseNumber);
                    },
                  ),
                  _actionButton(
                    icon: Icons.search,
                    label: 'تفسير',
                    color: controller.textColor.value,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          int selectedSurah = 1;
                          TextEditingController verseController =
                              TextEditingController(text: "1");

                          return AlertDialog(
                            backgroundColor: controller.backgroundColor.value,
                            title: Text("عرض التفسير",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: controller.textColor.value)),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DropdownButtonFormField<int>(
                                  decoration: InputDecoration(
                                    iconColor: controller.textColor.value,
                                    fillColor: controller.backgroundColor.value,
                                    suffixIconColor: controller.textColor.value,
                                    labelText: "السورة",
                                    labelStyle: TextStyle(
                                        color: controller.textColor.value),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: controller.textColor.value),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: controller.textColor.value),
                                    ),
                                  ),
                                  dropdownColor:
                                      controller.backgroundColor.value,
                                  value: selectedSurah,
                                  items:
                                      List.generate(114, (index) => index + 1)
                                          .map((s) {
                                    Surah surah = controller.allChapters
                                        .firstWhere((ch) => ch.id == s);
                                    return DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        surah.name,
                                        style: TextStyle(
                                            color: controller.textColor.value),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    selectedSurah = value!;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: verseController,
                                  decoration: InputDecoration(
                                    labelText: "رقم الآية",
                                    labelStyle: TextStyle(
                                        color: controller.textColor.value),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: controller.textColor.value),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: controller.textColor.value),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  cursorColor: controller.textColor.value,
                                  style: TextStyle(
                                      color: controller.textColor.value),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  "إلغاء",
                                  style: TextStyle(
                                      color: controller.textColor.value),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  int verseNumber =
                                      int.tryParse(verseController.text) ?? 1;

                                  TafsirService tafsirService = TafsirService();
                                  String? tafsirText = await tafsirService
                                      .getTafsir(selectedSurah, verseNumber);

                                  if (tafsirText != null) {
                                    Get.defaultDialog(
                                      title:
                                          "تفسير سورة $surahName - آية $verseNumber",
                                      titleStyle: TextStyle(
                                          color: controller.textColor.value),
                                      content: SingleChildScrollView(
                                        child: Text(
                                          tafsirText,
                                          textAlign: TextAlign.right,
                                          textDirection: TextDirection.rtl,
                                          style: TextStyle(
                                            color: controller.textColor.value,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      backgroundColor:
                                          controller.backgroundColor.value,
                                      confirm: TextButton(
                                        onPressed: () => Get.back(),
                                        child: Text(
                                          "إغلاق",
                                          style: TextStyle(
                                              color:
                                                  controller.textColor.value),
                                        ),
                                      ),
                                    );
                                  } else {
                                    Get.snackbar("خطأ",
                                        "لم يتم العثور على التفسير لهذه الآية");
                                  }
                                },
                                child: Text(
                                  "عرض",
                                  style: TextStyle(
                                      color: controller.textColor.value),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  _actionButton(
                    icon: Icons.share,
                    label: 'مشاركة',
                    color: controller.textColor.value,
                    onTap: () async {
                      Get.back();

                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: controller.backgroundColor.value,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(
                                color: controller.textColor.value
                                    .withOpacity(0.2)),
                          ),
                          title: Text(
                            'مشاركة الآية',
                            style: TextStyle(color: controller.textColor.value),
                            textAlign: TextAlign.center,
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: Icon(Icons.text_format,
                                    color: controller.textColor.value),
                                title: Text('مشاركة النص',
                                    style: TextStyle(
                                        color: controller.textColor.value)),
                                onTap: () {
                                  Navigator.pop(context);
                                  final textToShare =
                                      '$surahName ${verse.verseNumber}: ${verse.qcfData}';
                                  Share.share(textToShare);
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.image,
                                    color: controller.textColor.value),
                                title: Text('مشاركة كصورة',
                                    style: TextStyle(
                                        color: controller.textColor.value)),
                                onTap: () {
                                  Navigator.pop(context);
                                  _shareVerseAsImage(context, verse, surahName);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              (screenHeight(context) * 0.1).sh,
            ],
          ),
        );
      },
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
