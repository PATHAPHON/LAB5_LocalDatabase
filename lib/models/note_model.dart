// lib/models/note_model.dart

class Note {
  final int? id;
  final String title;
  final String content;

  Note({
    this.id,
    required this.title,
    required this.content,
  });

  // แปลงจาก Object ให้เป็น Map เพื่อเตรียมบันทึกลง SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
    };
  }

  // แปลงจาก Map ที่ได้จาก SQLite กลับมาเป็น Object ของ Note
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
    );
  }
}