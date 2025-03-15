class SurahPage {
  final int surah;
  final int page;

  SurahPage({
    required this.surah,
    required this.page,
  });

  factory SurahPage.fromJson(Map<String, dynamic> json) {
    return SurahPage(
      surah: json['surah'],
      page: json['page'],
    );
  }
}