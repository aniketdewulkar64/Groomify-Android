import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../models/user.dart';
import '../../models/recommendation.dart';
import 'package:groomify/services/database/database_stub.dart';

export 'package:groomify/services/database/database_stub.dart';

class DatabaseImplementationMobile implements DatabaseImplementation {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('groomify.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        passwordHash TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Recommendations table
    await db.execute('''
      CREATE TABLE recommendations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        faceShape TEXT NOT NULL,
        hairstyles TEXT NOT NULL,
        beardStyles TEXT NOT NULL,
        rating INTEGER NOT NULL,
        imagePath TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');
  }

  @override
  Future<int> createUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  @override
  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  @override
  Future<User?> loginUser(String email, String password) async {
    final user = await getUserByEmail(email);
    if (user == null) return null;

    final passwordHash = _hashPassword(password);
    if (user.passwordHash == passwordHash) {
      return user;
    }
    return null;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Future<int> saveRecommendation(Recommendation recommendation) async {
    final db = await database;
    return await db.insert('recommendations', recommendation.toMap());
  }

  @override
  Future<List<Recommendation>> getUserRecommendations(int userId) async {
    final db = await database;
    final maps = await db.query(
      'recommendations',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => Recommendation.fromMap(map)).toList();
  }

  @override
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

DatabaseImplementation getImplementation() => DatabaseImplementationMobile();
