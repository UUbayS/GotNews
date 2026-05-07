class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final int bookmarksCount;
  final int likesCount;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.bookmarksCount = 0,
    this.likesCount = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      bookmarksCount: json['_count']?['bookmarks'] ?? 0,
      likesCount: json['_count']?['likes'] ?? 0,
    );
  }
}
