// lib/services/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note_model.dart';

class DatabaseHelper {
  // สร้าง Singleton pattern
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // ดึง instance ของฐานข้อมูล (ถ้ายังไม่มีจะทำการเปิดหรือสร้างใหม่)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  // กำหนด Path และเปิดฐานข้อมูล
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // คำสั่ง SQL สร้างตารางเมื่อเปิดแอปครั้งแรก
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL
      )
    ''');
  }

  // --- ฟังก์ชัน CRUD (Create, Read, Update, Delete) ---

  // 1. Create (เพิ่มข้อมูล)
  Future<int> insertNote(Note note) async {
    final db = await instance.database;
    return await db.insert('notes', note.toMap());
  }

  // 2. Read (อ่านข้อมูลทั้งหมด)
  Future<List<Note>> getAllNotes() async {
    final db = await instance.database;
    final result = await db.query('notes', orderBy: 'id DESC'); // เรียงจากใหม่ไปเก่า

    return result.map((map) => Note.fromMap(map)).toList();
  }

  // 3. Update (แก้ไขข้อมูล)
  Future<int> updateNote(Note note) async {
    final db = await instance.database;
    return db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // 4. Delete (ลบข้อมูล)
  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}