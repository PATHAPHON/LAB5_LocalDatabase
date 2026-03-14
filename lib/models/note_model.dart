// lib/models/note_model.dart
import 'dart:convert';

class Note {
  final int? id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? deadline; // ใส่ ? เพราะอาจจะไม่มีการตั้งเดดไลน์ก็ได้
  final List<String> tags; // เก็บป้ายกำกับได้หลายอัน

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.deadline,
    this.tags = const [], // กำหนดค่าเริ่มต้นเป็น List ว่าง
  });

  // แปลงจาก Object ให้เป็น Map เพื่อเตรียมบันทึกลง SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      // แปลง DateTime เป็น String (ISO 8601) เพื่อเก็บใน SQLite
      'createdAt': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      // แปลง List ของป้ายกำกับให้เป็น JSON String
      'tags': jsonEncode(tags),
    };
  }

  // แปลงจาก Map ที่ได้จาก SQLite กลับมาเป็น Object ของ Note
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      // แปลง String กลับเป็น DateTime
      createdAt: DateTime.parse(map['createdAt']),
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'])
          : null,
      // แปลง JSON String กลับเป็น List<String>
      tags: List<String>.from(jsonDecode(map['tags'])),
    );
  }
}
