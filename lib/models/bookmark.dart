class Bookmark {
  final String mangaId;
  final String title;
  final String? coverUrl;
  final DateTime timestamp;
  final List<String> tags;
  final String status;
  final String? description;

  Bookmark({
    required this.mangaId,
    required this.title,
    this.coverUrl,
    required this.timestamp,
    required this.tags,
    required this.status,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'mangaId': mangaId,
        'title': title,
        'coverUrl': coverUrl,
        'timestamp': timestamp.toIso8601String(),
        'tags': tags,
        'status': status,
        'description': description,
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        mangaId: json['mangaId'],
        title: json['title'],
        coverUrl: json['coverUrl'],
        timestamp: DateTime.parse(json['timestamp']),
        tags: List<String>.from(json['tags']),
        status: json['status'],
        description: json['description'],
      );
}
