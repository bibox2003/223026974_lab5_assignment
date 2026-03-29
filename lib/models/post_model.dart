class Post {
  int? id; // Primary key, auto-generated
  String title; // Post title
  String body; // Post content
  String createdAt; // Timestamp

  Post({
    this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  // Convert a Post object to a Map (for database insertion)
  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'body': body, 'created_at': createdAt};
  }

  // Create a Post object from a Map (from database query)
  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      createdAt: map['created_at'],
    );
  }

  @override
  String toString() {
    return 'Post{id: $id, title: $title, body: $body, createdAt: $createdAt}';
  }
}
