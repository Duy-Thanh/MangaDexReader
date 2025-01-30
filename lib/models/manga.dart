class Manga {
  final String id;
  final String title;
  final String? description;
  final String? coverUrl;
  final List<String> tags;
  final String status;

  Manga({
    required this.id,
    required this.title,
    this.description,
    this.coverUrl,
    required this.tags,
    required this.status,
  });

  factory Manga.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'];
    final relationships = json['relationships'] as List<dynamic>;

    // Get the title in English or the first available language
    final titles = attributes['title'] as Map<String, dynamic>;
    final title = titles['en'] ?? titles.values.first;

    // Get cover file name from relationships
    String? coverFileName;
    for (var rel in relationships) {
      if (rel['type'] == 'cover_art') {
        coverFileName = rel['attributes']?['fileName'];
        break;
      }
    }

    return Manga(
      id: json['id'],
      title: title,
      description: attributes['description']?['en'],
      coverUrl: coverFileName != null
          ? 'https://uploads.mangadex.org/covers/${json['id']}/$coverFileName'
          : null,
      tags: (attributes['tags'] as List<dynamic>)
          .map((tag) => tag['attributes']['name']['en'].toString())
          .toList(),
      status: attributes['status'],
    );
  }
}
