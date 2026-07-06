import 'dart:convert';

class Notice {
  final String id;
  final String title;
  final String content;
  final String category;
  final String authorName;
  final DateTime createdAt;
  final String? thumbnailUrl;
  final String? detailedDescription; // Added this
  final Map<String, dynamic>? importantLinks; // Added this

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.authorName,
    required this.createdAt,
    required this.thumbnailUrl,
    this.detailedDescription,
    this.importantLinks,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    // Helper to handle links whether they come back as a JSON Map or a raw String
    Map<String, dynamic>? parsedLinks;
    if (json['important_links'] != null) {
      if (json['important_links'] is Map) {
        parsedLinks = Map<String, dynamic>.from(json['important_links']);
      } else if (json['important_links'] is String) {
        try { parsedLinks = jsonDecode(json['important_links']); } catch (_) {}
      }
    }

    return Notice(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      category: json['category'],
      // authorName: json['posted_by'] != null ? json['posted_by']['name'] : 'Unknown Author',
      // Change this line 👇
      authorName: json['author'] != null ? json['author']['name'] : 'Unknown Author',
      createdAt: DateTime.parse(json['created_at']),
      thumbnailUrl: json['thumbnail'],
      detailedDescription: json['detailed_description'],
      importantLinks: parsedLinks,
    );
  }
}