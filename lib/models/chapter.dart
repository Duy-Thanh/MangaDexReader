class Chapter {
  final String id;
  final String? title;
  final String? chapter;
  final String? volume;
  final DateTime publishedAt;
  final String? scanlationGroup;
  final int pageCount;
  String? prevChapterId;
  String? nextChapterId;

  Chapter({
    required this.id,
    this.title,
    this.chapter,
    this.volume,
    required this.publishedAt,
    this.scanlationGroup,
    required this.pageCount,
    this.prevChapterId,
    this.nextChapterId,
  });

  Chapter copyWith({
    String? id,
    String? title,
    String? chapter,
    String? volume,
    DateTime? publishedAt,
    String? scanlationGroup,
    int? pageCount,
    String? prevChapterId,
    String? nextChapterId,
  }) {
    return Chapter(
      id: id ?? this.id,
      title: title ?? this.title,
      chapter: chapter ?? this.chapter,
      volume: volume ?? this.volume,
      publishedAt: publishedAt ?? this.publishedAt,
      scanlationGroup: scanlationGroup ?? this.scanlationGroup,
      pageCount: pageCount ?? this.pageCount,
      prevChapterId: prevChapterId ?? this.prevChapterId,
      nextChapterId: nextChapterId ?? this.nextChapterId,
    );
  }

  factory Chapter.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'];
    final relationships = json['relationships'] as List<dynamic>;

    String? groupName;
    for (var rel in relationships) {
      if (rel['type'] == 'scanlation_group') {
        groupName = rel['attributes']?['name'];
        break;
      }
    }

    return Chapter(
      id: json['id'],
      title: attributes['title'],
      chapter: attributes['chapter'],
      volume: attributes['volume'],
      publishedAt: DateTime.parse(attributes['publishAt']),
      scanlationGroup: groupName,
      pageCount: attributes['pages'] ?? 0,
      prevChapterId: null,
      nextChapterId: null,
    );
  }
}
