class Talk {
  final String id;
  final String title;
  final String mainSpeaker;
  final String details;
  final List<String> relatedVideos;

  Talk({
    required this.id,
    required this.title,
    required this.mainSpeaker,
    required this.details,
    required this.relatedVideos,
  });

  factory Talk.fromJSON(Map<String, dynamic> json) {
    return Talk(
      id: json['id_ref'] ?? '',
      title: json['title'] ?? '',
      mainSpeaker: json['mainSpeaker'] ?? '',
      details: json['description'] ?? '',
      relatedVideos: json['related_videos'] != null
          ? List<String>.from(json['related_videos'])
          : [],
    );
  }
}
