class Verse {
  final int surahNumber;
  final int verseNumber;
  final String qcfData;
  final String content;

  Verse({
    required this.surahNumber,
    required this.verseNumber,
    required this.qcfData,
    required this.content,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      surahNumber: json['surah_number'],
      verseNumber: json['verse_number'],
      qcfData: json['qcfData'],
      content: json['content'],
    );
  }
}