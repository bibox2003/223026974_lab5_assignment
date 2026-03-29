import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';
import '../models/post_model.dart';

class DatabaseService {
  // Singleton pattern - only one instance of DatabaseService
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Database instance
  static Database? _database;
  final Logger _logger = Logger();

  // Getter for database - initializes if not exists
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    try {
      // Get the documents directory path
      String databasesPath = await getDatabasesPath();
      String path = join(databasesPath, 'posts_database.db');

      _logger.i('Database path: $path');

      // Open/create database with version 1
      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate, // Called when database is created for first time
        onUpgrade: _onUpgrade, // Called when database version increases
        onOpen: (db) {
          _logger.i('Database opened successfully');
        },
      );
    } catch (e) {
      _logger.e('Error initializing database: $e');
      throw Exception('Failed to initialize database: $e');
    }
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    try {
      _logger.i('Creating database tables...');

      // Create posts table
      await db.execute('''
        CREATE TABLE posts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      _logger.i('Posts table created successfully');

      // Insert some sample data
      await _insertSampleData(db);
    } catch (e) {
      _logger.e('Error creating tables: $e');
      throw Exception('Failed to create tables: $e');
    }
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      _logger.i('Upgrading database from version $oldVersion to $newVersion');

      // Add migration logic here for future versions
      if (oldVersion < 2) {
        // Example: Add new column
        // await db.execute('ALTER TABLE posts ADD COLUMN is_favorite INTEGER DEFAULT 0');
      }
    } catch (e) {
      _logger.e('Error upgrading database: $e');
      throw Exception('Failed to upgrade database: $e');
    }
  }

  // Insert sample data
  Future<void> _insertSampleData(Database db) async {
    try {
      List<Map<String, dynamic>> samplePosts = [
        {
          'title': 'Welcome to SQLite',
          'body':
              'This is your first post stored locally using SQLite database in Flutter.',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'title': 'CRUD Operations',
          'body': 'You can Create, Read, Update, and Delete posts in this app.',
          'created_at': DateTime.now()
              .subtract(Duration(hours: 1))
              .toIso8601String(),
        },
        {
          'title': 'Local Storage',
          'body':
              'All data is stored locally on your device using SQLite database.',
          'created_at': DateTime.now()
              .subtract(Duration(hours: 2))
              .toIso8601String(),
        },
      ];

      for (var post in samplePosts) {
        await db.insert('posts', post);
      }

      _logger.i('Sample data inserted successfully');
    } catch (e) {
      _logger.e('Error inserting sample data: $e');
    }
  }

  // CREATE - Add a new post
  Future<Post> createPost(Post post) async {
    try {
      final Database db = await database;

      // Check if database is initialized
      if (db == null) {
        throw Exception('Database not initialized');
      }

      // Insert post and get the generated id
      int id = await db.insert(
        'posts',
        post.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace, // Replace if conflict
      );

      _logger.i('Post created with id: $id');

      // Return the created post with id
      return Post(
        id: id,
        title: post.title,
        body: post.body,
        createdAt: post.createdAt,
      );
    } catch (e) {
      _logger.e('Error creating post: $e');
      throw Exception('Failed to create post: $e');
    }
  }

  // READ - Get all posts
  Future<List<Post>> getAllPosts() async {
    try {
      final Database db = await database;

      // Query all posts ordered by id descending (newest first)
      final List<Map<String, dynamic>> maps = await db.query(
        'posts',
        orderBy: 'id DESC',
      );

      _logger.i('Retrieved ${maps.length} posts from database');

      // Convert List<Map> to List<Post>
      return List.generate(maps.length, (i) {
        return Post.fromMap(maps[i]);
      });
    } catch (e) {
      _logger.e('Error getting posts: $e');
      throw Exception('Failed to get posts: $e');
    }
  }

  // READ - Get a single post by id
  Future<Post?> getPostById(int id) async {
    try {
      final Database db = await database;

      final List<Map<String, dynamic>> maps = await db.query(
        'posts',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        _logger.i('Retrieved post with id: $id');
        return Post.fromMap(maps.first);
      }

      _logger.w('Post with id $id not found');
      return null;
    } catch (e) {
      _logger.e('Error getting post by id: $e');
      throw Exception('Failed to get post: $e');
    }
  }

  // UPDATE - Update an existing post
  Future<int> updatePost(Post post) async {
    try {
      if (post.id == null) {
        throw Exception('Post id cannot be null for update');
      }

      final Database db = await database;

      int result = await db.update(
        'posts',
        post.toMap(),
        where: 'id = ?',
        whereArgs: [post.id],
      );

      if (result > 0) {
        _logger.i('Updated post with id: ${post.id}');
      } else {
        _logger.w('No post found with id: ${post.id} to update');
      }

      return result;
    } catch (e) {
      _logger.e('Error updating post: $e');
      throw Exception('Failed to update post: $e');
    }
  }

  // DELETE - Delete a post
  Future<int> deletePost(int id) async {
    try {
      final Database db = await database;

      int result = await db.delete('posts', where: 'id = ?', whereArgs: [id]);

      if (result > 0) {
        _logger.i('Deleted post with id: $id');
      } else {
        _logger.w('No post found with id: $id to delete');
      }

      return result;
    } catch (e) {
      _logger.e('Error deleting post: $e');
      throw Exception('Failed to delete post: $e');
    }
  }

  // DELETE - Delete all posts
  Future<void> deleteAllPosts() async {
    try {
      final Database db = await database;
      await db.delete('posts');
      _logger.i('Deleted all posts');
    } catch (e) {
      _logger.e('Error deleting all posts: $e');
      throw Exception('Failed to delete all posts: $e');
    }
  }

  // Check if database is open
  Future<bool> isDatabaseOpen() async {
    try {
      final db = await database;
      return db.isOpen;
    } catch (e) {
      return false;
    }
  }

  // Close database
  Future<void> closeDatabase() async {
    try {
      if (_database != null && _database!.isOpen) {
        await _database!.close();
        _database = null;
        _logger.i('Database closed');
      }
    } catch (e) {
      _logger.e('Error closing database: $e');
    }
  }
}
