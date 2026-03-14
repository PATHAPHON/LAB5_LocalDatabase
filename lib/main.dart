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
      title: 'Note App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const NotesScreen(),
    );
  }
}

// ==========================================
// 1. หน้าจอหลัก (แสดงรายการทั้งหมด และตัวกรอง)
// ==========================================
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> notes = [];
  List<String> allTags = [];
  String? selectedTag; // เก็บค่า Tag ที่กำลังใช้กรองอยู่
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshNotes();
  }

  Future<void> _refreshNotes() async {
    setState(() => isLoading = true);

    // โหลดโน้ตตาม Filter
    if (selectedTag == null) {
      notes = await DatabaseHelper.instance.getAllNotes();
    } else {
      notes = await DatabaseHelper.instance.getNotesByTag(selectedTag!);
    }

    // โหลดป้ายกำกับทั้งหมดที่มีในระบบมาทำตัวเลือก Filter
    final allNotes = await DatabaseHelper.instance.getAllNotes();
    final tagsSet = <String>{};
    for (var note in allNotes) {
      tagsSet.addAll(note.tags);
    }
    allTags = tagsSet.toList();

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สมุดบันทึก'),
        actions: [
          // ปุ่ม Filter ป้ายกำกับ
          if (allTags.isNotEmpty)
            PopupMenuButton<String?>(
              icon: const Icon(Icons.filter_list),
              onSelected: (String? tag) {
                setState(() => selectedTag = tag);
                _refreshNotes();
              },
              itemBuilder: (context) {
                return [
                  const PopupMenuItem(value: null, child: Text('แสดงทั้งหมด')),
                  ...allTags.map(
                    (tag) => PopupMenuItem(
                      value: tag,
                      child: Text('ป้ายกำกับ: $tag'),
                    ),
                  ),
                ];
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notes.isEmpty
          ? const Center(child: Text('ไม่พบบันทึก กดปุ่ม + เพื่อเพิ่ม'))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(
                      note.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (note.tags.isNotEmpty)
                          Wrap(
                            spacing: 4.0,
                            children: note.tags
                                .map(
                                  (tag) => Chip(
                                    label: Text(
                                      tag,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                    onTap: () async {
                      // เปิดไปหน้าดูรายละเอียด
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NoteDetailScreen(noteId: note.id!),
                        ),
                      );
                      _refreshNotes();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // เปิดไปหน้าสร้างโน้ต
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditNoteScreen()),
          );
          _refreshNotes();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ==========================================
// 2. หน้าจออ่านบันทึกแบบรายละเอียด
// ==========================================
class NoteDetailScreen extends StatefulWidget {
  final int noteId;
  const NoteDetailScreen({super.key, required this.noteId});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  Note? note;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshNote();
  }

  Future<void> _refreshNote() async {
    setState(() => isLoading = true);
    note = await DatabaseHelper.instance.getNoteById(widget.noteId);
    setState(() => isLoading = false);
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (note == null)
      return const Scaffold(body: Center(child: Text('ไม่พบข้อมูล')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียด'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditNoteScreen(note: note),
                ),
              );
              _refreshNote();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () async {
              await DatabaseHelper.instance.deleteNote(note!.id!);
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note!.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "สร้างเมื่อ: ${_formatDate(note!.createdAt)}",
              style: const TextStyle(color: Colors.grey),
            ),
            if (note!.deadline != null)
              Text(
                "เดดไลน์: ${_formatDate(note!.deadline!)}",
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 12),
            if (note!.tags.isNotEmpty)
              Wrap(
                spacing: 8.0,
                children: note!.tags
                    .map((tag) => Chip(label: Text(tag)))
                    .toList(),
              ),
            const Divider(),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  note!.content,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. หน้าจอสร้าง/แก้ไขบันทึก
// ==========================================
class AddEditNoteScreen extends StatefulWidget {
  final Note? note;
  const AddEditNoteScreen({super.key, this.note});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _tagsController.text = widget.note!.tags.join(
        ', ',
      ); // นำ tags มาต่อกันเพื่อแสดงใน TextField
      _deadline = widget.note!.deadline;
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _saveNote() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty)
      return;

    // แปลงข้อความจากช่อง Tags ให้กลายเป็น List (แยกด้วยลูกน้ำ)
    final tagsList = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final newNote = Note(
      id: widget.note?.id,
      title: _titleController.text,
      content: _contentController.text,
      createdAt:
          widget.note?.createdAt ?? DateTime.now(), // ถ้าสร้างใหม่ให้ใช้วันนี้
      deadline: _deadline,
      tags: tagsList,
    );

    if (widget.note == null) {
      await DatabaseHelper.instance.insertNote(newNote);
    } else {
      await DatabaseHelper.instance.updateNote(newNote);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'เพิ่มบันทึกใหม่' : 'แก้ไขบันทึก'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'หัวข้อ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'เนื้อหา',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _deadline == null
                        ? 'ยังไม่ได้ตั้งเดดไลน์'
                        : 'เดดไลน์: ${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickDeadline,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('เลือกเดดไลน์'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'ป้ายกำกับ (คั่นด้วยลูกน้ำ)',
                hintText: 'เช่น งาน, สำคัญ, ไอเดีย',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveNote,
                child: const Text(
                  'บันทึกข้อมูล',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
