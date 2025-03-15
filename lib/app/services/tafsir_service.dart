import 'dart:convert';
import 'package:flutter/services.dart';

class TafsirService {
  List<dynamic> bookItems = [];
  List<dynamic> itemsAyat = [];
  List<int> verseCounts = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111,
    110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45,
    83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55,
    78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20,
    56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21,
    11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3
  ];

  Future<void> loadJsonData() async {
    try {
      final bookItemsJson = await rootBundle.loadString('assets/json/BookItems.json');
      final itemsAyatJson = await rootBundle.loadString('assets/json/ItemsAyat.json');

      bookItems = json.decode(bookItemsJson);
      itemsAyat = json.decode(itemsAyatJson);
    } catch (e) {
      print('Error loading JSON data: $e');
    }
  }

  int getAbsoluteVerseNumber(int surahNumber, int verseNumber) {
    int absoluteNumber = verseNumber;
    for (int i = 0; i < surahNumber - 1; i++) {
      absoluteNumber += verseCounts[i];
    }
    return absoluteNumber;
  }

  Future<String?> getTafsir(int surahNumber, int verseNumber) async {
    if (bookItems.isEmpty || itemsAyat.isEmpty) {
      await loadJsonData();
    }

    int absoluteVerseNumber = getAbsoluteVerseNumber(surahNumber, verseNumber);

    var ayaEntry = itemsAyat.firstWhere(
          (entry) => entry['AyaID'] == absoluteVerseNumber,
      orElse: () => null,
    );

    if (ayaEntry == null) return null;

    int itemID = ayaEntry['ItemID'];

    var tafsirEntry = bookItems.firstWhere(
          (item) => item['ItemID'] == itemID,
      orElse: () => null,
    );

    return tafsirEntry != null ? tafsirEntry['ItemText'] : null;
  }
}