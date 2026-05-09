class NewsItem {
  final String id;
  final String title;
  final String summary;
  final String? originalContent;
  final String? imageUrl;
  final String? sourceName;
  final String? category;
  final String? language;
  final DateTime? publishedAt;
  
  int likesCount;
  bool isLiked;
  bool isBookmarked;

  NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    this.originalContent,
    this.imageUrl,
    this.sourceName,
    this.category,
    this.language,
    this.publishedAt,
    this.likesCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id'],
      title: json['title'],
      summary: json['summary'],
      originalContent: json['originalContent'],
      imageUrl: json['imageUrl'],
      sourceName: json['sourceName'],
      category: json['category'],
      language: json['language'],
      publishedAt: json['publishedAt'] != null 
          ? DateTime.parse(json['publishedAt']) 
          : null,
      likesCount: json['likesCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      isBookmarked: json['isBookmarked'] ?? false,
    );
  }

  void toggleLike() {
    isLiked = !isLiked;
    likesCount += isLiked ? 1 : -1;
  }

  void toggleBookmark() {
    isBookmarked = !isBookmarked;
  }
}
