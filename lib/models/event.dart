class Event {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String venue;
  final DateTime startTime;
  final DateTime endTime;
  final String organizerName;
  final String? thumbnailUrl;
  final String? detailedDescription; // Added this
  final Map<String, dynamic>? importantLinks; // Added this

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.venue,
    required this.startTime,
    required this.endTime,
    required this.organizerName,
    required this.thumbnailUrl,
    this.detailedDescription,
    this.importantLinks,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      venue: json['venue'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      // Change this line 👇
      organizerName: json['host'] != null ? json['host']['name'] : 'Unknown Organizer',
      //organizerName: json['organizer'] != null ? json['organizer']['name'] : 'Unknown Organizer',
      thumbnailUrl: json['thumbnail'],
      detailedDescription: json['detailed_description'], // Added this
      importantLinks: json['important_links'], // Added this
    );
  }
}