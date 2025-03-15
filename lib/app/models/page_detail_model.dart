class PageDetail {
  final int surah;
  final int start;
  final int end;

  PageDetail({
    required this.surah,
    required this.start,
    required this.end,
  });

  factory PageDetail.fromJson(Map<String, dynamic> json) {
    return PageDetail(
      surah: json['surah'],
      start: json['start'],
      end: json['end'],
    );
  }
}
