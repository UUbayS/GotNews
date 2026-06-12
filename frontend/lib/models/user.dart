class User {
  final String id;
  final String name;
  final String? username;
  final String email;
  final String? avatarUrl;
  final String? dateOfBirth;
  final String? gender;
  final String? address;
  final int bookmarksCount;
  final int likesCount;
  final String? role;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    this.username,
    required this.email,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.bookmarksCount = 0,
    this.likesCount = 0,
    this.role,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'],
      address: json['address'],
      bookmarksCount: json['_count']?['bookmarks'] ?? 0,
      likesCount: json['_count']?['likes'] ?? 0,
      role: json['role'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}
