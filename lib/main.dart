// lib/main.dart
import 'package:flutter/material.dart';
import 'models/note_model.dart';
import 'services/database_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQLite Notes',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const NotesScreen(),
    );
  }
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> notes = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshNotes(); // โหลดข้อมูลเมื่อเปิดหน้าจอ
  }

  // ฟังก์ชันโหลดข้อมูลจาก Database
  Future<void> _refreshNotes() async {
    setState(() => isLoading = true);
    notes = await DatabaseHelper.instance.getAllNotes();
    setState(() => isLoading = false);
  }

  // แสดง Dialog สำหรับเพิ่มหรือแก้ไขข้อมูล
  void _showNoteDialog({Note? note}) {
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note == null ? 'เพิ่มบันทึก' : 'แก้ไขบันทึก'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'หัวข้อ'),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'เนื้อหา'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty || contentController.text.isEmpty) {
                return; // ป้องกันการบันทึกข้อมูลว่าง
              }

              final newNote = Note(
                id: note?.id, // ถ้าเป็นการแก้ไข จะมี id เดิม
                title: titleController.text,
                content: contentController.text,
              );

              if (note == null) {
                await DatabaseHelper.instance.insertNote(newNote); // เพิ่มใหม่
              } else {
                await DatabaseHelper.instance.updateNote(newNote); // แก้ไขของเดิม
              }

              if(mounted) Navigator.pop(context);
              _refreshNotes(); // โหลดข้อมูลใหม่หลังจากบันทึกเสร็จ
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันลบข้อมูล
  Future<void> _deleteNote(int id) async {
    await DatabaseHelper.instance.deleteNote(id);
    _refreshNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมุดบันทึก SQLite')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notes.isEmpty
          ? const Center(child: Text('ยังไม่มีบันทึก กดปุ่ม + เพื่อเพิ่ม'))
          : ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(note.content),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteNote(note.id!),
              ),
              onTap: () => _showNoteDialog(note: note), // กดเพื่อแก้ไข
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteDialog(), // กดเพื่อเพิ่มข้อมูลใหม่
        child: const Icon(Icons.add),
      ),
    );
  }
}