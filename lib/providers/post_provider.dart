import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/database_service.dart';

class PostProvider with ChangeNotifier {
  List<Post> _posts = [];
  bool _isLoading = false;
  String? _error;
  final DatabaseService _databaseService = DatabaseService();

  // Getters
  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all posts
  Future<void> loadPosts() async {
    _setLoading(true);
    _clearError();

    try {
      _posts = await _databaseService.getAllPosts();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load posts: $e');
      _setLoading(false);
    }
  }

  // Create new post
  Future<bool> createPost(String title, String body) async {
    _setLoading(true);
    _clearError();

    try {
      if (title.isEmpty || body.isEmpty) {
        throw Exception('Title and body cannot be empty');
      }

      Post newPost = Post(
        title: title,
        body: body,
        createdAt: DateTime.now().toIso8601String(),
      );

      Post createdPost = await _databaseService.createPost(newPost);
      _posts.insert(0, createdPost); // Add to beginning of list
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create post: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update post
  Future<bool> updatePost(int id, String title, String body) async {
    _setLoading(true);
    _clearError();

    try {
      Post updatedPost = Post(
        id: id,
        title: title,
        body: body,
        createdAt: DateTime.now().toIso8601String(),
      );

      int result = await _databaseService.updatePost(updatedPost);

      if (result > 0) {
        // Update in local list
        int index = _posts.indexWhere((post) => post.id == id);
        if (index != -1) {
          _posts[index] = updatedPost;
          notifyListeners();
        }
        _setLoading(false);
        return true;
      } else {
        throw Exception('Post not found');
      }
    } catch (e) {
      _setError('Failed to update post: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete post
  Future<bool> deletePost(int id) async {
    _setLoading(true);
    _clearError();

    try {
      int result = await _databaseService.deletePost(id);

      if (result > 0) {
        _posts.removeWhere((post) => post.id == id);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        throw Exception('Post not found');
      }
    } catch (e) {
      _setError('Failed to delete post: $e');
      _setLoading(false);
      return false;
    }
  }

  // Get single post
  Future<Post?> getPost(int id) async {
    try {
      return await _databaseService.getPostById(id);
    } catch (e) {
      _setError('Failed to get post: $e');
      return null;
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Clear error manually
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
