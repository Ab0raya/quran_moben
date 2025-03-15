import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran_moben/app/controllers/quran_page_controller.dart';
import 'package:quran_moben/app/models/verse_model.dart';
import 'package:share_plus/share_plus.dart';

import '../../../services/tafsir_service.dart';
import '../../../../utils/extensions.dart';
import '../../../models/surah_model.dart';
import 'action_button.dart';

class ActionButtonsRaw extends StatelessWidget {
  ActionButtonsRaw({super.key, required this.controller, required this.verse});

  final QuranPageController controller;
  final Verse verse;

  @override
  Widget build(BuildContext context) {
    String surahName = controller.allChapters
        .firstWhere((s) => s.id == verse.surahNumber)
        .name;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ActionButton(
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
                  ? Icon(Icons.bookmark, color: controller.textColor.value)
                  : Icon(Icons.bookmark_border,
                      color: controller.textColor.value),
            );
          },
        ),
        ActionButton(
          icon: Icons.volume_up_rounded,
          label: 'إستماع',
          color: controller.textColor.value,
          onTap: () {
            controller.playAudio(
                surahNumber: verse.surahNumber, verseNumber: verse.verseNumber);
          },
        ),
        ActionButton(
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
                      style: TextStyle(color: controller.textColor.value)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          iconColor: controller.textColor.value,
                          fillColor: controller.backgroundColor.value,
                          suffixIconColor: controller.textColor.value,
                          labelText: "السورة",
                          labelStyle:
                              TextStyle(color: controller.textColor.value),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: controller.textColor.value),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: controller.textColor.value),
                          ),
                        ),
                        dropdownColor: controller.backgroundColor.value,
                        value: selectedSurah,
                        items:
                            List.generate(114, (index) => index + 1).map((s) {
                          Surah surah = controller.allChapters
                              .firstWhere((ch) => ch.id == s);
                          return DropdownMenuItem(
                            value: s,
                            child: Text(
                              surah.name,
                              style:
                                  TextStyle(color: controller.textColor.value),
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
                          labelStyle:
                              TextStyle(color: controller.textColor.value),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: controller.textColor.value),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: controller.textColor.value),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        cursorColor: controller.textColor.value,
                        style: TextStyle(color: controller.textColor.value),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "إلغاء",
                        style: TextStyle(color: controller.textColor.value),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        int verseNumber =
                            int.tryParse(verseController.text) ?? 1;

                        TafsirService tafsirService = TafsirService();
                        String? tafsirText = await tafsirService.getTafsir(
                            selectedSurah, verseNumber);

                        if (tafsirText != null) {
                          Get.defaultDialog(
                            title: "تفسير سورة $surahName - آية $verseNumber",
                            titleStyle:
                                TextStyle(color: controller.textColor.value),
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
                            backgroundColor: controller.backgroundColor.value,
                            confirm: TextButton(
                              onPressed: () => Get.back(),
                              child: Text(
                                "إغلاق",
                                style: TextStyle(
                                    color: controller.textColor.value),
                              ),
                            ),
                          );
                        } else {
                          Get.snackbar(
                              "خطأ", "لم يتم العثور على التفسير لهذه الآية");
                        }
                      },
                      child: Text(
                        "عرض",
                        style: TextStyle(color: controller.textColor.value),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        ActionButton(
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
                      color: controller.textColor.value.withOpacity(0.2)),
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
                          style: TextStyle(color: controller.textColor.value)),
                      onTap: () {
                        Navigator.pop(context);
                        final textToShare =
                            '$surahName ${verse.verseNumber}: ${verse.content}';
                        Share.share(textToShare);
                      },
                    ),
                    ListTile(
                      leading:
                          Icon(Icons.image, color: controller.textColor.value),
                      title: Text('مشاركة كصورة',
                          style: TextStyle(color: controller.textColor.value)),
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
    );
  }

  final GlobalKey _verseImageKey = GlobalKey();

  Future<void> _shareVerseAsImage(
      BuildContext context, Verse verse, String surahName) async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: RepaintBoundary(
            key: _verseImageKey,
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: controller.backgroundColor.value,
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
                  Container(
                    height: 40,
                    alignment: Alignment.center,
                    child: Text(
                      'قرآن مبين',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: controller.textColor.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    verse.qcfData,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      height: 1.8,
                      color: controller.textColor.value,
                      fontFamily: controller.fontName,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: controller.textColor.value.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$surahName: آية ${verse.verseNumber}',
                      style: TextStyle(
                        fontSize: 16,
                        color: controller.textColor.value,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SvgPicture.asset(
                    'assets/images/logo.svg',
                    colorFilter: ColorFilter.mode(
                      controller.textColor.value,
                      BlendMode.srcIn,
                    ),
                    height: screenHeight(context) * 0.1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      RenderRepaintBoundary boundary = _verseImageKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File(
            '${tempDir.path}/verse_${verse.surahNumber}_${verse.verseNumber}.png');
        await file.writeAsBytes(byteData.buffer.asUint8List());

        await Share.shareXFiles(
          [XFile(file.path)],
          text: '$surahName: آية ${verse.verseNumber}',
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء مشاركة الصورة',
        backgroundColor: controller.backgroundColor.value,
        colorText: controller.textColor.value,
      );
    }
  }
}
