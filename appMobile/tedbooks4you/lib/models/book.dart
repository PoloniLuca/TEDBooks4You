// models/book.dart
class Book {
  final String title;
  final String? description;
  final String? thumbnail;
  final String link;
  final List<String> authors;

  Book({
    required this.title,
    this.description,
    this.thumbnail,
    required this.link,
    this.authors = const [],
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'] as String,
      description: json['description'] as String?,
      thumbnail: json['image']?['thumbnail'] as String?,
      link: json['link'] as String,
      authors: List<String>.from(json['authors'] as List<dynamic>),
    );
  }
}
