import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../app_theme.dart';

// ─── Design Tokens ──────────────────────────────────────────────────────────
const Color _kCoral = Color(0xFFF08A82);

// ─────────────────────────────────────────────────────────────────────────────
// Note model
// ─────────────────────────────────────────────────────────────────────────────
class Note {
  String id, title, content, date, fontFamily;
  double fontSize;
  FontWeight fontWeight;
  TextAlign textAlign;
  Color? color;
  Color highlightColor;
  bool isItalic, isUnderlined, isStrikethrough;
  List<NoteBlock> blocks;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.fontSize = 15.0,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.left,
    this.color,
    this.highlightColor = Colors.transparent,
    this.fontFamily = 'Roboto',
    this.isItalic = false,
    this.isUnderlined = false,
    this.isStrikethrough = false,
    this.blocks = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'date': date,
        'fontSize': fontSize,
        'fontWeight': FontWeight.values.indexOf(fontWeight),
        'textAlign': textAlign.index,
        'color': color?.toARGB32(),
        'highlightColor': highlightColor.toARGB32(),
        'fontFamily': fontFamily,
        'isItalic': isItalic,
        'isUnderlined': isUnderlined,
        'isStrikethrough': isStrikethrough,
        'blocks': blocks.map((b) => b.toJson()).toList(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        date: json['date'] ?? '',
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 15.0,
        fontWeight: FontWeight.values[
            ((json['fontWeight'] as int?) ?? 3)
                .clamp(0, FontWeight.values.length - 1)],
        textAlign: TextAlign.values[
            ((json['textAlign'] as int?) ?? 0)
                .clamp(0, TextAlign.values.length - 1)],
        color: json['color'] != null ? Color(json['color']) : null,
        highlightColor: Color(
            json['highlightColor'] ?? Colors.transparent.toARGB32()),
        fontFamily: json['fontFamily'] ?? 'Roboto',
        isItalic: json['isItalic'] ?? false,
        isUnderlined: json['isUnderlined'] ?? false,
        isStrikethrough: json['isStrikethrough'] ?? false,
        blocks: json['blocks'] != null
            ? (json['blocks'] as List)
                .map((b) => NoteBlock.fromJson(b))
                .toList()
            : [],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Rich Style Span Models (Per-character / selection styling without markdown asterisks)
// ─────────────────────────────────────────────────────────────────────────────
class CharStyle {
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final Color? color;
  final double? fontSize;

  const CharStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.color,
    this.fontSize,
  });

  bool matches(CharStyle other) =>
      bold == other.bold &&
      italic == other.italic &&
      underline == other.underline &&
      strikethrough == other.strikethrough &&
      color == other.color &&
      fontSize == other.fontSize;

  CharStyle copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
    Color? color,
    double? fontSize,
    bool clearColor = false,
    bool clearFontSize = false,
  }) =>
      CharStyle(
        bold: bold ?? this.bold,
        italic: italic ?? this.italic,
        underline: underline ?? this.underline,
        strikethrough: strikethrough ?? this.strikethrough,
        color: clearColor ? null : (color ?? this.color),
        fontSize: clearFontSize ? null : (fontSize ?? this.fontSize),
      );
}

class StyleSpan {
  final int start;
  final int end;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final int? colorValue;
  final double? fontSize;

  StyleSpan({
    required this.start,
    required this.end,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.colorValue,
    this.fontSize,
  });

  Map<String, dynamic> toJson() => {
        's': start,
        'e': end,
        'b': bold,
        'i': italic,
        'u': underline,
        'k': strikethrough,
        'c': colorValue,
        'f': fontSize,
      };

  factory StyleSpan.fromJson(Map<String, dynamic> json) => StyleSpan(
        start: json['s'] ?? 0,
        end: json['e'] ?? 0,
        bold: json['b'] ?? false,
        italic: json['i'] ?? false,
        underline: json['u'] ?? false,
        strikethrough: json['k'] ?? false,
        colorValue: json['c'] as int?,
        fontSize: (json['f'] as num?)?.toDouble(),
      );
}

List<StyleSpan> compressCharStyles(List<CharStyle> styles) {
  final spans = <StyleSpan>[];
  if (styles.isEmpty) return spans;
  int start = 0;
  while (start < styles.length) {
    final style = styles[start];
    int end = start + 1;
    while (end < styles.length && styles[end].matches(style)) {
      end++;
    }
    if (style.bold ||
        style.italic ||
        style.underline ||
        style.strikethrough ||
        style.color != null ||
        style.fontSize != null) {
      spans.add(StyleSpan(
        start: start,
        end: end,
        bold: style.bold,
        italic: style.italic,
        underline: style.underline,
        strikethrough: style.strikethrough,
        colorValue: style.color?.toARGB32(),
        fontSize: style.fontSize,
      ));
    }
    start = end;
  }
  return spans;
}

List<CharStyle> expandStyleSpans(int textLength, List<StyleSpan> spans) {
  final styles = List.generate(textLength, (_) => const CharStyle());
  for (var span in spans) {
    final s = span.start.clamp(0, textLength);
    final e = span.end.clamp(0, textLength);
    for (int i = s; i < e; i++) {
      styles[i] = CharStyle(
        bold: span.bold,
        italic: span.italic,
        underline: span.underline,
        strikethrough: span.strikethrough,
        color: span.colorValue != null ? Color(span.colorValue!) : null,
        fontSize: span.fontSize,
      );
    }
  }
  return styles;
}

// ─────────────────────────────────────────────────────────────────────────────
// Rich block models (Text, Task List, Bullet List, Table)
// ─────────────────────────────────────────────────────────────────────────────
enum NoteBlockType { text, table, taskList, bulletList }

class NoteBlock {
  final String id;
  NoteBlockType type;
  String text;
  List<StyleSpan> spans;
  List<List<String>> tableData;
  List<TaskItem> listItems;

  NoteBlock({
    required this.id,
    required this.type,
    this.text = '',
    List<StyleSpan>? spans,
    List<List<String>>? tableData,
    List<TaskItem>? listItems,
  })  : spans = spans ?? [],
        tableData = tableData ?? [],
        listItems = listItems ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'text': text,
        'spans': spans.map((s) => s.toJson()).toList(),
        'tableData': tableData,
        'listItems': listItems.map((i) => i.toJson()).toList(),
      };

  factory NoteBlock.fromJson(Map<String, dynamic> json) => NoteBlock(
        id: json['id'] ?? '',
        type: NoteBlockType.values[((json['type'] as int?) ?? 0)
            .clamp(0, NoteBlockType.values.length - 1)],
        text: json['text'] ?? '',
        spans: json['spans'] != null
            ? (json['spans'] as List)
                .map((s) => StyleSpan.fromJson(s))
                .toList()
            : [],
        tableData: (json['tableData'] as List?)
                ?.map((r) => List<String>.from(r as List))
                .toList() ??
            [],
        listItems: (json['listItems'] as List?)
                ?.map((i) => TaskItem.fromJson(i))
                .toList() ??
            [],
      );
}

class TaskItem {
  String id;
  String text;
  bool checked;
  List<StyleSpan> spans;

  TaskItem({
    String? id,
    required this.text,
    this.checked = false,
    List<StyleSpan>? spans,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        spans = spans ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'checked': checked,
        'spans': spans.map((s) => s.toJson()).toList(),
      };

  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
        id: j['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
        text: j['text'] ?? '',
        checked: j['checked'] ?? false,
        spans: j['spans'] != null
            ? (j['spans'] as List)
                .map((s) => StyleSpan.fromJson(s))
                .toList()
            : [],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Font catalogue
// ─────────────────────────────────────────────────────────────────────────────
const List<Map<String, String>> kFonts = [
  {'label': 'Roboto', 'family': 'Roboto'},
  {'label': 'Serif', 'family': 'serif'},
  {'label': 'Mono', 'family': 'monospace'},
  {'label': 'Courier', 'family': 'Courier'},
  {'label': 'Georgia', 'family': 'Georgia'},
  {'label': 'Palatino', 'family': 'Palatino'},
  {'label': 'Helvetica', 'family': 'Helvetica'},
  {'label': 'Verdana', 'family': 'Verdana'},
  {'label': 'Trebuchet', 'family': 'Trebuchet MS'},
  {'label': 'Impact', 'family': 'Impact'},
  {'label': 'Arial', 'family': 'Arial'},
];

// ─────────────────────────────────────────────────────────────────────────────
// NotesManager – list screen
// ─────────────────────────────────────────────────────────────────────────────
class NotesManager extends StatefulWidget {
  final List<Note> notes;
  final Function(List<Note>) onNotesChanged;
  const NotesManager(
      {super.key, required this.notes, required this.onNotesChanged});

  @override
  State<NotesManager> createState() => _NotesManagerState();
}

class _NotesManagerState extends State<NotesManager> {
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _addNote(Note note) =>
      widget.onNotesChanged(List<Note>.from(widget.notes)..insert(0, note));

  void _deleteNote(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.themeCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Note',
          style: TextStyle(
              color: context.themeTextPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this note?',
          style: TextStyle(color: context.themeTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(
                    color: context.themeTextSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              widget.onNotesChanged(
                  List<Note>.from(widget.notes)..removeWhere((n) => n.id == id));
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openNoteEditor([Note? note]) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, a, __) => NoteEditor(
        note: note,
        onSave: (newNote) {
          if (note == null) {
            _addNote(newNote);
          } else {
            final updated = List<Note>.from(widget.notes);
            final i = updated.indexWhere((n) => n.id == note.id);
            if (i != -1) {
              updated[i] = newNote;
              widget.onNotesChanged(updated);
            }
          }
        },
      ),
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 280),
    ));
  }

  List<Note> get _filtered => _search.isEmpty
      ? widget.notes
      : widget.notes
          .where((n) =>
              n.title.toLowerCase().contains(_search.toLowerCase()) ||
              n.content.toLowerCase().contains(_search.toLowerCase()))
          .toList();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final totalWords = widget.notes.fold(0, (sum, n) {
      final t = n.content.trim();
      return sum + (t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length);
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 18 : 36,
          16,
          isMobile ? 18 : 36,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header (Fixed) ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Smart ',
                            style: TextStyle(
                              color: context.themeTextPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Text(
                            'Notes',
                            style: TextStyle(
                              color: _kCoral,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Capture and organize your thoughts',
                        style: TextStyle(
                          color: context.themeTextSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _openNoteEditor(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _kCoral,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 18, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'New Note',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ─── Summary Card (Fixed) ───
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.themeCardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.themeTextPrimary.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.description_outlined,
                            size: 16,
                            color: _kCoral,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'KNOWLEDGE BASE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${widget.notes.length} Total Notes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: context.themeTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.themeTextPrimary
                                .withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.themeTextPrimary
                                  .withValues(alpha: 0.04),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.menu_book_rounded,
                                  size: 18, color: Color(0xFF93C5FD)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$totalWords',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: context.themeTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Words Written',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: context.themeTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.themeTextPrimary
                                .withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.themeTextPrimary
                                  .withValues(alpha: 0.04),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.format_shapes_rounded,
                                  size: 18, color: Color(0xFF86EFAC)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${widget.notes.where((n) => n.blocks.isNotEmpty).length}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: context.themeTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Rich Blocks',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: context.themeTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ─── Search (Fixed) ───
            Container(
              decoration: BoxDecoration(
                color: context.themeCardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: context.themeTextPrimary.withValues(alpha: 0.05),
                ),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                style:
                    TextStyle(color: context.themeTextPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: TextStyle(
                    color: context.themeTextSecondary.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 18, color: context.themeTextSecondary),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          const SizedBox(height: 14),

          // ─── Scrollable Notes List ───
          Expanded(
            child: _filtered.isEmpty
                ? SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildEmpty(),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) =>
                        _buildNoteCard(_filtered[i], isMobile),
                  ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildEmpty() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: context.themeCardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.themeTextPrimary.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 36,
              color: _kCoral.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'No Notes Found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: context.themeTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "New Note" above to write down ideas.',
              style: TextStyle(
                fontSize: 12,
                color: context.themeTextSecondary,
              ),
            ),
          ],
        ),
      );

  Widget _buildNoteCard(Note note, bool isMobile) {
    final bool hasTasks = note.blocks.any((b) => b.type == NoteBlockType.taskList) ||
        note.content.contains('[ ]') ||
        note.content.contains('[x]');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.themeCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.themeTextPrimary.withValues(alpha: 0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openNoteEditor(note),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kCoral.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasTasks
                        ? Icons.checklist_rounded
                        : Icons.description_outlined,
                    size: 18,
                    color: _kCoral,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              note.title.isEmpty ? 'Untitled Note' : note.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.themeTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            note.date,
                            style: TextStyle(
                              color: context.themeTextSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildNotePreviewLines(note),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Colors.redAccent.withValues(alpha: 0.6),
                  ),
                  onPressed: () => _deleteNote(note.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotePreviewLines(Note note) {
    List<Widget> previewWidgets = [];

    // 1. If structured blocks exist, render from blocks
    if (note.blocks.isNotEmpty) {
      for (final block in note.blocks) {
        if (previewWidgets.length >= 3) break;

        if (block.type == NoteBlockType.taskList) {
          for (final item in block.listItems) {
            if (previewWidgets.length >= 3) break;
            if (item.text.trim().isEmpty) continue;
            previewWidgets.add(
              Padding(
                padding: const EdgeInsets.only(top: 3.5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      item.checked
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 14,
                      color: item.checked
                          ? _kCoral
                          : context.themeTextSecondary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.text,
                        style: TextStyle(
                          color: item.checked
                              ? context.themeTextSecondary.withValues(alpha: 0.6)
                              : context.themeTextSecondary,
                          fontSize: 12,
                          decoration: item.checked
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        } else if (block.type == NoteBlockType.bulletList) {
          for (final item in block.listItems) {
            if (previewWidgets.length >= 3) break;
            if (item.text.trim().isEmpty) continue;
            previewWidgets.add(
              Padding(
                padding: const EdgeInsets.only(top: 3.5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 4.5,
                      height: 4.5,
                      margin: const EdgeInsets.only(left: 4, right: 8),
                      decoration: const BoxDecoration(
                        color: _kCoral,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.text,
                        style: TextStyle(
                          color: context.themeTextSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        } else if (block.type == NoteBlockType.text) {
          final lines = block.text
              .split('\n')
              .where((l) => l.trim().isNotEmpty)
              .toList();
          for (final line in lines) {
            if (previewWidgets.length >= 3) break;
            previewWidgets.add(
              Padding(
                padding: const EdgeInsets.only(top: 3.5),
                child: Text(
                  line,
                  style: TextStyle(
                    color: context.themeTextSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }
        } else if (block.type == NoteBlockType.table) {
          if (block.tableData.isNotEmpty) {
            final rowSummary =
                block.tableData.first.where((c) => c.isNotEmpty).join(' • ');
            previewWidgets.add(
              Padding(
                padding: const EdgeInsets.only(top: 3.5),
                child: Row(
                  children: [
                    const Icon(Icons.table_chart_outlined,
                        size: 14, color: _kCoral),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        rowSummary.isEmpty ? 'Table data' : rowSummary,
                        style: TextStyle(
                          color: context.themeTextSecondary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      }
    }

    // 2. If no preview from blocks, parse note.content lines
    if (previewWidgets.isEmpty && note.content.isNotEmpty) {
      final rawLines = note.content
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();

      for (final line in rawLines) {
        if (previewWidgets.length >= 3) break;
        final trimmed = line.trim();

        if (trimmed.startsWith('[x]') || trimmed.startsWith('[X]')) {
          final text = trimmed.substring(3).trim();
          previewWidgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 3.5),
              child: Row(
                children: [
                  const Icon(Icons.check_box_rounded,
                      size: 14, color: _kCoral),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        color:
                            context.themeTextSecondary.withValues(alpha: 0.6),
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (trimmed.startsWith('[ ]')) {
          final text = trimmed.substring(3).trim();
          previewWidgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 3.5),
              child: Row(
                children: [
                  Icon(Icons.check_box_outline_blank_rounded,
                      size: 14,
                      color:
                          context.themeTextSecondary.withValues(alpha: 0.7)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        color: context.themeTextSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (trimmed.startsWith('•') ||
            trimmed.startsWith('-') ||
            trimmed.startsWith('*')) {
          final text = trimmed.replaceFirst(RegExp(r'^[•\-\*]\s*'), '');
          previewWidgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 3.5),
              child: Row(
                children: [
                  Container(
                    width: 4.5,
                    height: 4.5,
                    margin: const EdgeInsets.only(left: 4, right: 8),
                    decoration: const BoxDecoration(
                      color: _kCoral,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        color: context.themeTextSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          previewWidgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 3.5),
              child: Text(
                trimmed,
                style: TextStyle(
                  color: context.themeTextSecondary,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }
      }
    }

    if (previewWidgets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: previewWidgets,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SpanStyleRichTextEditingController (WYSIWYG Per-Selection Styling without raw markdown)
// ─────────────────────────────────────────────────────────────────────────────
class SpanStyleRichTextEditingController extends TextEditingController {
  List<CharStyle> charStyles;
  CharStyle activeStyle;
  TextSelection? lastNonCollapsedSelection;

  SpanStyleRichTextEditingController({
    super.text,
    List<CharStyle>? initialStyles,
  })  : charStyles = initialStyles != null
            ? List<CharStyle>.from(initialStyles)
            : List.generate((text ?? '').length, (_) => const CharStyle()),
        activeStyle = const CharStyle();

  TextSelection get _effectiveSelection {
    if (selection.isValid && !selection.isCollapsed) {
      lastNonCollapsedSelection = selection;
      return selection;
    }
    if (lastNonCollapsedSelection != null &&
        lastNonCollapsedSelection!.isValid &&
        !lastNonCollapsedSelection!.isCollapsed &&
        lastNonCollapsedSelection!.start <= text.length &&
        lastNonCollapsedSelection!.end <= text.length) {
      return lastNonCollapsedSelection!;
    }
    return selection;
  }

  @override
  set value(TextEditingValue newValue) {
    if (newValue.selection.isValid && !newValue.selection.isCollapsed) {
      lastNonCollapsedSelection = newValue.selection;
    }
    final oldText = text;
    final newText = newValue.text;

    if (oldText != newText) {
      _adjustStyles(oldText, newText);
      lastNonCollapsedSelection = null;
    }
    super.value = newValue;
  }

  void _adjustStyles(String oldText, String newText) {
    int prefix = 0;
    while (prefix < oldText.length &&
        prefix < newText.length &&
        oldText[prefix] == newText[prefix]) {
      prefix++;
    }

    int suffix = 0;
    while (suffix < (oldText.length - prefix) &&
        suffix < (newText.length - prefix) &&
        oldText[oldText.length - 1 - suffix] ==
            newText[newText.length - 1 - suffix]) {
      suffix++;
    }

    final oldDeletedCount = oldText.length - prefix - suffix;
    final newInsertedCount = newText.length - prefix - suffix;

    if (oldDeletedCount > 0 && prefix < charStyles.length) {
      final removeEnd = (prefix + oldDeletedCount).clamp(0, charStyles.length);
      charStyles.removeRange(prefix, removeEnd);
    }

    if (newInsertedCount > 0) {
      final insertStyle = (prefix > 0 && prefix <= charStyles.length)
          ? charStyles[prefix - 1]
          : activeStyle;
      final toInsert = List.generate(
          newInsertedCount,
          (_) => activeStyle.copyWith(
                bold: activeStyle.bold || insertStyle.bold,
                italic: activeStyle.italic || insertStyle.italic,
                underline: activeStyle.underline || insertStyle.underline,
                strikethrough:
                    activeStyle.strikethrough || insertStyle.strikethrough,
                color: activeStyle.color ?? insertStyle.color,
                fontSize: activeStyle.fontSize ?? insertStyle.fontSize,
              ));
      final safeIndex = prefix.clamp(0, charStyles.length);
      charStyles.insertAll(safeIndex, toInsert);
    }

    if (charStyles.length < newText.length) {
      charStyles.addAll(List.generate(
          newText.length - charStyles.length, (_) => activeStyle));
    } else if (charStyles.length > newText.length) {
      charStyles.removeRange(newText.length, charStyles.length);
    }
  }

  void applyColor(Color? color) {
    final sel = _effectiveSelection;
    if (sel.isValid &&
        !sel.isCollapsed &&
        sel.start >= 0 &&
        sel.end <= text.length) {
      final start = sel.start.clamp(0, charStyles.length);
      final end = sel.end.clamp(0, charStyles.length);
      for (int i = start; i < end; i++) {
        charStyles[i] = charStyles[i].copyWith(
          color: color,
          clearColor: color == null,
        );
      }
      activeStyle = activeStyle.copyWith(
        color: color,
        clearColor: color == null,
      );
      notifyListeners();
    } else {
      activeStyle = activeStyle.copyWith(
        color: color,
        clearColor: color == null,
      );
      notifyListeners();
    }
  }

  void applyFontSize(double size) {
    final sel = _effectiveSelection;
    if (sel.isValid &&
        !sel.isCollapsed &&
        sel.start >= 0 &&
        sel.end <= text.length) {
      final start = sel.start.clamp(0, charStyles.length);
      final end = sel.end.clamp(0, charStyles.length);
      for (int i = start; i < end; i++) {
        charStyles[i] = charStyles[i].copyWith(fontSize: size);
      }
      activeStyle = activeStyle.copyWith(fontSize: size);
      notifyListeners();
    } else {
      activeStyle = activeStyle.copyWith(fontSize: size);
      notifyListeners();
    }
  }

  double getActiveFontSize(double defaultSize) {
    final sel = _effectiveSelection;
    if (sel.isValid &&
        !sel.isCollapsed &&
        sel.start >= 0 &&
        sel.end <= charStyles.length) {
      return charStyles[sel.start].fontSize ?? defaultSize;
    }
    return activeStyle.fontSize ?? defaultSize;
  }

  Color? getActiveColor() {
    final sel = _effectiveSelection;
    if (sel.isValid &&
        !sel.isCollapsed &&
        sel.start >= 0 &&
        sel.end <= charStyles.length) {
      return charStyles[sel.start].color;
    }
    return activeStyle.color;
  }

  void toggleBold() {
    final sel = _effectiveSelection;
    if (sel.isValid &&
        !sel.isCollapsed &&
        sel.start >= 0 &&
        sel.end <= text.length) {
      final start = sel.start.clamp(0, charStyles.length);
      final end = sel.end.clamp(0, charStyles.length);
      final anyNotBold = charStyles.sublist(start, end).any((s) => !s.bold);
      for (int i = start; i < end; i++) {
        charStyles[i] = charStyles[i].copyWith(bold: anyNotBold);
      }
      activeStyle = activeStyle.copyWith(bold: anyNotBold);
      notifyListeners();
    } else {
      activeStyle = activeStyle.copyWith(bold: !activeStyle.bold);
      notifyListeners();
    }
  }

  void toggleItalic() {
    final sel = _effectiveSelection;
    if (sel.isValid &&
        !sel.isCollapsed &&
        sel.start >= 0 &&
        sel.end <= text.length) {
      final start = sel.start.clamp(0, charStyles.length);
      final end = sel.end.clamp(0, charStyles.length);
      final anyNotItalic = charStyles.sublist(start, end).any((s) => !s.italic);
      for (int i = start; i < end; i++) {
        charStyles[i] = charStyles[i].copyWith(italic: anyNotItalic);
      }
      activeStyle = activeStyle.copyWith(italic: anyNotItalic);
      notifyListeners();
    } else {
      activeStyle = activeStyle.copyWith(italic: !activeStyle.italic);
      notifyListeners();
    }
  }

  void toggleUnderline() {
    final sel = _effectiveSelection;
    if (sel.isValid &&
        !sel.isCollapsed &&
        sel.start >= 0 &&
        sel.end <= text.length) {
      final start = sel.start.clamp(0, charStyles.length);
      final end = sel.end.clamp(0, charStyles.length);
      final anyNotUnderline =
          charStyles.sublist(start, end).any((s) => !s.underline);
      for (int i = start; i < end; i++) {
        charStyles[i] = charStyles[i].copyWith(underline: anyNotUnderline);
      }
      activeStyle = activeStyle.copyWith(underline: anyNotUnderline);
      notifyListeners();
    } else {
      activeStyle = activeStyle.copyWith(underline: !activeStyle.underline);
      notifyListeners();
    }
  }

  void toggleStrikethrough() {
    final sel = _effectiveSelection;
    if (sel.isValid &&
        !sel.isCollapsed &&
        sel.start >= 0 &&
        sel.end <= text.length) {
      final start = sel.start.clamp(0, charStyles.length);
      final end = sel.end.clamp(0, charStyles.length);
      final anyNotStrike =
          charStyles.sublist(start, end).any((s) => !s.strikethrough);
      for (int i = start; i < end; i++) {
        charStyles[i] = charStyles[i].copyWith(strikethrough: anyNotStrike);
      }
      activeStyle = activeStyle.copyWith(strikethrough: anyNotStrike);
      notifyListeners();
    } else {
      activeStyle =
          activeStyle.copyWith(strikethrough: !activeStyle.strikethrough);
      notifyListeners();
    }
  }

  bool isBoldActive() {
    final sel = _effectiveSelection;
    if (sel.isValid &&
        !sel.isCollapsed &&
        sel.start >= 0 &&
        sel.end <= charStyles.length) {
      return charStyles.sublist(sel.start, sel.end).every((s) => s.bold);
    }
    return activeStyle.bold;
  }

  bool isItalicActive() {
    final sel = _effectiveSelection;
    if (sel.isValid &&
        !sel.isCollapsed &&
        sel.start >= 0 &&
        sel.end <= charStyles.length) {
      return charStyles.sublist(sel.start, sel.end).every((s) => s.italic);
    }
    return activeStyle.italic;
  }

  bool isUnderlineActive() {
    final sel = _effectiveSelection;
    if (sel.isValid &&
        !sel.isCollapsed &&
        sel.start >= 0 &&
        sel.end <= charStyles.length) {
      return charStyles.sublist(sel.start, sel.end).every((s) => s.underline);
    }
    return activeStyle.underline;
  }

  bool isStrikethroughActive() {
    final sel = _effectiveSelection;
    if (sel.isValid &&
        !sel.isCollapsed &&
        sel.start >= 0 &&
        sel.end <= charStyles.length) {
      return charStyles
          .sublist(sel.start, sel.end)
          .every((s) => s.strikethrough);
    }
    return activeStyle.strikethrough;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();
    final textVal = value.text;
    if (textVal.isEmpty || charStyles.isEmpty) {
      return TextSpan(text: textVal, style: baseStyle);
    }

    final children = <InlineSpan>[];
    int runStart = 0;
    while (runStart < textVal.length) {
      final currentStyle = runStart < charStyles.length
          ? charStyles[runStart]
          : const CharStyle();
      int runEnd = runStart + 1;
      while (runEnd < textVal.length &&
          runEnd < charStyles.length &&
          charStyles[runEnd].matches(currentStyle)) {
        runEnd++;
      }

      final isBold = currentStyle.bold;
      final isItalic = currentStyle.italic;
      final isUnderline = currentStyle.underline;
      final isStrike = currentStyle.strikethrough;
      final effectiveColor = currentStyle.color ?? baseStyle.color;
      final effectiveFontSize = currentStyle.fontSize ?? baseStyle.fontSize;

      children.add(TextSpan(
        text: textVal.substring(runStart, runEnd),
        style: baseStyle.copyWith(
          color: effectiveColor,
          fontSize: effectiveFontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
          decoration: TextDecoration.combine([
            if (isUnderline) TextDecoration.underline,
            if (isStrike) TextDecoration.lineThrough,
          ]),
        ),
      ));
      runStart = runEnd;
    }

    return TextSpan(children: children, style: baseStyle);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NoteEditor (Backspace converts empty task/bullet to normal text block below)
// ─────────────────────────────────────────────────────────────────────────────
class NoteEditor extends StatefulWidget {
  final Note? note;
  final Function(Note) onSave;
  const NoteEditor({super.key, this.note, required this.onSave});

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late TextEditingController _titleCtrl;
  double _fontSize = 15.0;
  FontWeight _fontWeight = FontWeight.normal;
  TextAlign _textAlign = TextAlign.left;
  Color? _textColor;
  Color _highlightColor = Colors.transparent;
  String _fontFamily = 'Roboto';
  bool _isItalic = false, _isUnderlined = false, _isStrikethrough = false;
  final List<NoteBlock> _blocks = [];

  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  String? _focusTargetId;
  SpanStyleRichTextEditingController? _lastActiveSpanController;

  TextEditingController _getTextController(String id, String initialText,
      [List<StyleSpan>? initialSpans]) {
    return _textControllers.putIfAbsent(id, () {
      final styles = expandStyleSpans(initialText.length, initialSpans ?? []);
      return SpanStyleRichTextEditingController(
          text: initialText, initialStyles: styles);
    });
  }

  SpanStyleRichTextEditingController? _getActiveSpanController() {
    for (var b in _blocks) {
      final node = _focusNodes[b.id];
      if (node != null && node.hasFocus) {
        final ctrl = _textControllers[b.id];
        if (ctrl is SpanStyleRichTextEditingController) {
          _lastActiveSpanController = ctrl;
          return ctrl;
        }
      }
      if (b.type == NoteBlockType.taskList ||
          b.type == NoteBlockType.bulletList) {
        for (var item in b.listItems) {
          final itemNode = _focusNodes[item.id];
          if (itemNode != null && itemNode.hasFocus) {
            final ctrl = _textControllers[item.id];
            if (ctrl is SpanStyleRichTextEditingController) {
              _lastActiveSpanController = ctrl;
              return ctrl;
            }
          }
        }
      }
    }
    if (_lastActiveSpanController != null) {
      return _lastActiveSpanController;
    }
    if (_blocks.isNotEmpty && _blocks.first.type == NoteBlockType.text) {
      final ctrl = _textControllers[_blocks.first.id];
      if (ctrl is SpanStyleRichTextEditingController) {
        _lastActiveSpanController = ctrl;
        return ctrl;
      }
    }
    return null;
  }

  int? _getActiveBlockIndex() {
    for (int i = 0; i < _blocks.length; i++) {
      final b = _blocks[i];
      final node = _focusNodes[b.id];
      if (node != null && node.hasFocus) return i;
      if (b.type == NoteBlockType.taskList ||
          b.type == NoteBlockType.bulletList) {
        for (var item in b.listItems) {
          final itemNode = _focusNodes[item.id];
          if (itemNode != null && itemNode.hasFocus) return i;
        }
      }
    }
    return null;
  }

  void _toggleBold() {
    final ctrl = _getActiveSpanController();
    if (ctrl != null) {
      ctrl.toggleBold();
    }
    setState(() {});
  }

  void _toggleItalic() {
    final ctrl = _getActiveSpanController();
    if (ctrl != null) {
      ctrl.toggleItalic();
    }
    setState(() {});
  }

  void _toggleUnderline() {
    final ctrl = _getActiveSpanController();
    if (ctrl != null) {
      ctrl.toggleUnderline();
    }
    setState(() {});
  }

  void _toggleStrikethrough() {
    final ctrl = _getActiveSpanController();
    if (ctrl != null) {
      ctrl.toggleStrikethrough();
    }
    setState(() {});
  }

  void _applyTextColor(Color? c) {
    final ctrl = _getActiveSpanController();
    if (ctrl != null) {
      ctrl.applyColor(c);
    }
    setState(() {});
  }

  void _applyFontSize(double size) {
    final ctrl = _getActiveSpanController();
    if (ctrl != null) {
      ctrl.applyFontSize(size);
    }
    setState(() {});
  }

  void _decreaseFontSize() {
    final currentSize = _getActiveFontSize();
    if (currentSize > 8) {
      _applyFontSize(currentSize - 1);
    }
  }

  void _increaseFontSize() {
    final currentSize = _getActiveFontSize();
    if (currentSize < 72) {
      _applyFontSize(currentSize + 1);
    }
  }

  Color? _getActiveTextColor() {
    final ctrl = _getActiveSpanController();
    if (ctrl != null) {
      return ctrl.getActiveColor();
    }
    return null;
  }

  double _getActiveFontSize() {
    final ctrl = _getActiveSpanController();
    if (ctrl != null) {
      return ctrl.getActiveFontSize(15.0);
    }
    return 15.0;
  }

  bool _isBoldActive() {
    final ctrl = _getActiveSpanController();
    if (ctrl != null) return ctrl.isBoldActive();
    return false;
  }

  bool _isItalicActive() {
    final ctrl = _getActiveSpanController();
    if (ctrl != null) return ctrl.isItalicActive();
    return false;
  }

  bool _isUnderlineActive() {
    final ctrl = _getActiveSpanController();
    if (ctrl != null) return ctrl.isUnderlineActive();
    return false;
  }

  bool _isStrikethroughActive() {
    final ctrl = _getActiveSpanController();
    if (ctrl != null) return ctrl.isStrikethroughActive();
    return false;
  }

  FocusNode _getFocusNode(String id) {
    return _focusNodes.putIfAbsent(id, () => FocusNode());
  }

  int get _wordCount {
    int words = 0;
    for (var b in _blocks) {
      if (b.type == NoteBlockType.text) {
        final ctrl = _textControllers[b.id];
        final t = (ctrl != null ? ctrl.text : b.text).trim();
        if (t.isNotEmpty) words += t.split(RegExp(r'\s+')).length;
      } else if (b.type == NoteBlockType.taskList ||
          b.type == NoteBlockType.bulletList) {
        for (var item in b.listItems) {
          final ctrl = _textControllers[item.id];
          final t = (ctrl != null ? ctrl.text : item.text).trim();
          if (t.isNotEmpty) words += t.split(RegExp(r'\s+')).length;
        }
      }
    }
    return words;
  }

  int get _charCount {
    int chars = 0;
    for (var b in _blocks) {
      if (b.type == NoteBlockType.text) {
        final ctrl = _textControllers[b.id];
        chars += (ctrl != null ? ctrl.text : b.text).length;
      } else if (b.type == NoteBlockType.taskList ||
          b.type == NoteBlockType.bulletList) {
        for (var item in b.listItems) {
          final ctrl = _textControllers[item.id];
          chars += (ctrl != null ? ctrl.text : item.text).length;
        }
      }
    }
    return chars;
  }

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    if (widget.note != null) {
      final n = widget.note!;
      _fontSize = n.fontSize;
      _fontWeight = n.fontWeight;
      _textAlign = n.textAlign;
      _textColor = n.color;
      _highlightColor = n.highlightColor;
      _fontFamily = n.fontFamily;
      _isItalic = n.isItalic;
      _isUnderlined = n.isUnderlined;
      _isStrikethrough = n.isStrikethrough;

      if (n.blocks.isNotEmpty) {
        _blocks.addAll(n.blocks.map((b) => NoteBlock(
              id: b.id,
              type: b.type,
              text: b.text,
              spans: b.spans,
              tableData: b.tableData.map((r) => List<String>.from(r)).toList(),
              listItems: b.listItems
                  .map((i) => TaskItem(
                      id: i.id,
                      text: i.text,
                      checked: i.checked,
                      spans: i.spans))
                  .toList(),
            )));
      } else if (n.content.isNotEmpty) {
        _blocks.add(NoteBlock(
          id: _uid(),
          type: NoteBlockType.text,
          text: n.content,
        ));
      }
    }

    if (_blocks.isEmpty) {
      _blocks.add(NoteBlock(
        id: _uid(),
        type: NoteBlockType.text,
        text: '',
      ));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (var ctrl in _textControllers.values) {
      ctrl.dispose();
    }
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  String _uid() => DateTime.now().microsecondsSinceEpoch.toString();

  void _syncControllersToBlocks() {
    for (var b in _blocks) {
      if (b.type == NoteBlockType.text) {
        final ctrl = _textControllers[b.id];
        if (ctrl != null) {
          b.text = ctrl.text;
          if (ctrl is SpanStyleRichTextEditingController) {
            b.spans = compressCharStyles(ctrl.charStyles);
          }
        }
      } else if (b.type == NoteBlockType.taskList ||
          b.type == NoteBlockType.bulletList) {
        for (var item in b.listItems) {
          final ctrl = _textControllers[item.id];
          if (ctrl != null) {
            item.text = ctrl.text;
            if (ctrl is SpanStyleRichTextEditingController) {
              item.spans = compressCharStyles(ctrl.charStyles);
            }
          }
        }
      } else if (b.type == NoteBlockType.table) {
        for (int ri = 0; ri < b.tableData.length; ri++) {
          for (int ci = 0; ci < b.tableData[ri].length; ci++) {
            final cellId = '${b.id}_${ri}_$ci';
            final ctrl = _textControllers[cellId];
            if (ctrl != null) {
              b.tableData[ri][ci] = ctrl.text;
            }
          }
        }
      }
    }
  }

  // ── Auto-save and Back Navigation ─────────────────────────────────────────
  void _saveNoteSilently() {
    _syncControllersToBlocks();
    final hasContent = _titleCtrl.text.trim().isNotEmpty ||
        _blocks.any((b) =>
            (b.type == NoteBlockType.text && b.text.trim().isNotEmpty) ||
            (b.type == NoteBlockType.taskList &&
                b.listItems.any((i) => i.text.trim().isNotEmpty)) ||
            (b.type == NoteBlockType.bulletList &&
                b.listItems.any((i) => i.text.trim().isNotEmpty)) ||
            (b.type == NoteBlockType.table &&
                b.tableData.any((r) => r.any((c) => c.trim().isNotEmpty))));

    if (hasContent) {
      final now = DateTime.now();
      final compiledContent = _blocks.map((b) {
        if (b.type == NoteBlockType.text) return b.text;
        if (b.type == NoteBlockType.taskList) {
          return b.listItems
              .map((i) => '${i.checked ? "[x]" : "[ ]"} ${i.text}')
              .join('\n');
        }
        if (b.type == NoteBlockType.bulletList) {
          return b.listItems.map((i) => '• ${i.text}').join('\n');
        }
        if (b.type == NoteBlockType.table) {
          return b.tableData.map((r) => r.join(' | ')).join('\n');
        }
        return '';
      }).join('\n\n');

      widget.onSave(Note(
        id: widget.note?.id ?? _uid(),
        title: _titleCtrl.text,
        content: compiledContent,
        date: '${now.day}/${now.month}/${now.year}',
        fontSize: _fontSize,
        fontWeight: _fontWeight,
        textAlign: _textAlign,
        color: _textColor,
        highlightColor: _highlightColor,
        fontFamily: _fontFamily,
        isItalic: _isItalic,
        isUnderlined: _isUnderlined,
        isStrikethrough: _isStrikethrough,
        blocks: List<NoteBlock>.from(_blocks),
      ));
    }
  }

  void _shareNote() {
    _syncControllersToBlocks();
    final compiled = _blocks.map((b) {
      if (b.type == NoteBlockType.text) return b.text;
      if (b.type == NoteBlockType.taskList) {
        return b.listItems
            .map((i) => '${i.checked ? "[x]" : "[ ]"} ${i.text}')
            .join('\n');
      }
      if (b.type == NoteBlockType.bulletList) {
        return b.listItems.map((i) => '• ${i.text}').join('\n');
      }
      if (b.type == NoteBlockType.table) {
        return b.tableData.map((r) => r.join(' | ')).join('\n');
      }
      return '';
    }).join('\n\n');
    Share.share('${_titleCtrl.text}\n\n$compiled', subject: _titleCtrl.text);
  }

  Future<void> _printNote() async {
    _syncControllersToBlocks();
    final doc = pw.Document();

    pw.InlineSpan buildPdfTextSpan(String text, List<StyleSpan> spans,
        {bool isStrikethrough = false, PdfColor? defaultColor}) {
      if (text.isEmpty) return const pw.TextSpan(text: '');
      final styles = expandStyleSpans(text.length, spans);
      final children = <pw.InlineSpan>[];
      int runStart = 0;
      while (runStart < text.length) {
        final currentStyle =
            runStart < styles.length ? styles[runStart] : const CharStyle();
        int runEnd = runStart + 1;
        while (runEnd < text.length &&
            runEnd < styles.length &&
            styles[runEnd].matches(currentStyle)) {
          runEnd++;
        }

        final chunk = text.substring(runStart, runEnd);
        final chunkColor = currentStyle.color != null
            ? PdfColor.fromInt(currentStyle.color!.toARGB32())
            : (defaultColor ?? PdfColors.grey900);
        final chunkFontSize = currentStyle.fontSize ?? 12.0;
        final isUnderline = currentStyle.underline;
        final isStrike = isStrikethrough || currentStyle.strikethrough;
        final isBold = currentStyle.bold;
        final isItalic = currentStyle.italic;

        children.add(pw.TextSpan(
          text: chunk,
          style: pw.TextStyle(
            fontSize: chunkFontSize,
            color: chunkColor,
            fontWeight:
                isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontStyle: isItalic
                ? pw.FontStyle.italic
                : pw.FontStyle.normal,
            decoration: isUnderline && isStrike
                ? pw.TextDecoration.combine([
                    pw.TextDecoration.underline,
                    pw.TextDecoration.lineThrough
                  ])
                : isUnderline
                    ? pw.TextDecoration.underline
                    : isStrike
                        ? pw.TextDecoration.lineThrough
                        : pw.TextDecoration.none,
          ),
        ));
        runStart = runEnd;
      }
      return pw.TextSpan(children: children);
    }

    final pdfWidgets = <pw.Widget>[];

    // Header: Note Title
    final titleText = _titleCtrl.text.trim().isEmpty
        ? 'Untitled Note'
        : _titleCtrl.text.trim();
    pdfWidgets.add(
      pw.Text(
        titleText,
        style: const pw.TextStyle(
          fontSize: 22,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey900,
        ),
      ),
    );
    pdfWidgets.add(pw.SizedBox(height: 4));

    // Note Meta (Date & LifeOS Tag)
    pdfWidgets.add(
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            widget.note?.date ?? DateTime.now().toString().split(' ').first,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'LifeOS Notes',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#F08A82'),
            ),
          ),
        ],
      ),
    );
    pdfWidgets.add(pw.SizedBox(height: 8));
    pdfWidgets.add(pw.Divider(color: PdfColors.grey300, thickness: 0.8));
    pdfWidgets.add(pw.SizedBox(height: 14));

    // Blocks rendering
    for (var b in _blocks) {
      if (b.type == NoteBlockType.text) {
        if (b.text.isNotEmpty) {
          pdfWidgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.RichText(
                text: buildPdfTextSpan(b.text, b.spans),
              ),
            ),
          );
        } else {
          pdfWidgets.add(pw.SizedBox(height: 6));
        }
      } else if (b.type == NoteBlockType.taskList) {
        if (b.listItems.isNotEmpty) {
          pdfWidgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: b.listItems.map((item) {
                  final isChecked = item.checked;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Task Checkbox: Green with checkmark or clean border
                        pw.Container(
                          width: 12,
                          height: 12,
                          margin: const pw.EdgeInsets.only(top: 2, right: 8),
                          decoration: pw.BoxDecoration(
                            color: isChecked
                                ? PdfColor.fromHex('#10B981')
                                : PdfColors.white,
                            borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(3)),
                            border: pw.Border.all(
                              color: isChecked
                                  ? PdfColor.fromHex('#10B981')
                                  : PdfColors.grey500,
                              width: 1.2,
                            ),
                          ),
                          child: isChecked
                              ? pw.Center(
                                  child: pw.SvgImage(
                                    svg:
                                        '<svg viewBox="0 0 16 16" width="8" height="8"><path fill="none" stroke="#FFFFFF" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" d="M3.5 8.5 L6.5 11.5 L12.5 4.5"/></svg>',
                                  ),
                                )
                              : null,
                        ),
                        pw.Expanded(
                          child: pw.RichText(
                            text: buildPdfTextSpan(
                              item.text,
                              item.spans,
                              isStrikethrough: isChecked,
                              defaultColor: isChecked
                                  ? PdfColors.grey500
                                  : PdfColors.grey900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }
      } else if (b.type == NoteBlockType.bulletList) {
        if (b.listItems.isNotEmpty) {
          pdfWidgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: b.listItems.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Bullet point dot
                        pw.Container(
                          width: 5,
                          height: 5,
                          margin: const pw.EdgeInsets.only(top: 5, right: 8),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#10B981'),
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.RichText(
                            text: buildPdfTextSpan(item.text, item.spans),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }
      } else if (b.type == NoteBlockType.table) {
        if (b.tableData.isNotEmpty) {
          pdfWidgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 14),
              child: pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
                children: b.tableData.asMap().entries.map((entry) {
                  final rowIndex = entry.key;
                  final rowData = entry.value;
                  final isHeader = rowIndex == 0;
                  return pw.TableRow(
                    decoration: isHeader
                        ? const pw.BoxDecoration(color: PdfColors.grey100)
                        : null,
                    children: rowData.map((cell) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        child: pw.Text(
                          cell,
                          style: pw.TextStyle(
                            fontSize: 10.5,
                            fontWeight: isHeader
                                ? pw.FontWeight.bold
                                : pw.FontWeight.normal,
                            color: PdfColors.grey900,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          );
        }
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => pdfWidgets,
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat f) async => doc.save());
  }

  // ── Block manipulation ────────────────────────────────────────────────────
  void _addTextBlock([int? atIndex]) {
    _syncControllersToBlocks();
    setState(() {
      final b = NoteBlock(id: _uid(), type: NoteBlockType.text, text: '');
      final targetIndex = atIndex ?? _getActiveBlockIndex();
      if (targetIndex != null && targetIndex < _blocks.length) {
        _blocks.insert(targetIndex + 1, b);
      } else {
        _blocks.add(b);
      }
      _focusTargetId = b.id;
    });
  }

  void _addTaskListBlock([int? atIndex]) {
    _syncControllersToBlocks();
    setState(() {
      final firstItem = TaskItem(text: '');

      // Only if the document is a single empty initial text block, reuse it
      if (_blocks.length == 1 &&
          _blocks.first.type == NoteBlockType.text &&
          _blocks.first.text.trim().isEmpty) {
        _blocks.first.type = NoteBlockType.taskList;
        _blocks.first.listItems = [firstItem];
        _focusTargetId = firstItem.id;
        return;
      }

      // Otherwise ALWAYS INSERT a separate new task block without touching existing blocks
      final b = NoteBlock(
        id: _uid(),
        type: NoteBlockType.taskList,
        listItems: [firstItem],
      );
      final targetIndex = atIndex ?? _getActiveBlockIndex();
      if (targetIndex != null && targetIndex < _blocks.length) {
        _blocks.insert(targetIndex + 1, b);
      } else {
        _blocks.add(b);
      }
      _focusTargetId = firstItem.id;
    });
  }

  void _addBulletListBlock([int? atIndex]) {
    _syncControllersToBlocks();
    setState(() {
      final firstItem = TaskItem(text: '');

      // Only if the document is a single empty initial text block, reuse it
      if (_blocks.length == 1 &&
          _blocks.first.type == NoteBlockType.text &&
          _blocks.first.text.trim().isEmpty) {
        _blocks.first.type = NoteBlockType.bulletList;
        _blocks.first.listItems = [firstItem];
        _focusTargetId = firstItem.id;
        return;
      }

      // Otherwise ALWAYS INSERT a separate new bullet block without touching existing blocks
      final b = NoteBlock(
        id: _uid(),
        type: NoteBlockType.bulletList,
        listItems: [firstItem],
      );
      final targetIndex = atIndex ?? _getActiveBlockIndex();
      if (targetIndex != null && targetIndex < _blocks.length) {
        _blocks.insert(targetIndex + 1, b);
      } else {
        _blocks.add(b);
      }
      _focusTargetId = firstItem.id;
    });
  }

  void _addTableBlock([int? atIndex]) {
    _syncControllersToBlocks();
    setState(() {
      final initialTable = [
        ['Header 1', 'Header 2', 'Header 3'],
        ['', '', ''],
        ['', '', ''],
      ];

      // Only if the document is a single empty initial text block, reuse it
      if (_blocks.length == 1 &&
          _blocks.first.type == NoteBlockType.text &&
          _blocks.first.text.trim().isEmpty) {
        _blocks.first.type = NoteBlockType.table;
        _blocks.first.tableData = initialTable;
        return;
      }

      // Otherwise ALWAYS INSERT a separate new table block without touching existing blocks
      final b = NoteBlock(
        id: _uid(),
        type: NoteBlockType.table,
        tableData: initialTable,
      );
      final targetIndex = atIndex ?? _getActiveBlockIndex();
      if (targetIndex != null && targetIndex < _blocks.length) {
        _blocks.insert(targetIndex + 1, b);
      } else {
        _blocks.add(b);
      }
    });
  }

  void _removeBlock(String id) {
    _syncControllersToBlocks();
    setState(() {
      _blocks.removeWhere((b) => b.id == id);
      if (_blocks.isEmpty) {
        _blocks.add(NoteBlock(id: _uid(), type: NoteBlockType.text, text: ''));
      }
    });
  }

  void _insertIntoActiveText(String snippet) {
    _syncControllersToBlocks();
    final lastText = _blocks.lastWhere(
      (b) => b.type == NoteBlockType.text,
      orElse: () {
        final nb = NoteBlock(id: _uid(), type: NoteBlockType.text, text: '');
        setState(() => _blocks.add(nb));
        return nb;
      },
    );
    final ctrl = _getTextController(lastText.id, lastText.text);
    ctrl.text = '${ctrl.text}$snippet';
    lastText.text = ctrl.text;
    setState(() {
      _focusTargetId = lastText.id;
    });
  }

  // ── Block Builders (Clean, No Placeholder Clutter, Auto-Focus on Enter) ──

  // 1. Text Block
  Widget _buildTextBlock(NoteBlock block, int index) {
    final ctrl = _getTextController(block.id, block.text, block.spans);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _highlightColor == Colors.transparent
              ? Colors.transparent
              : _highlightColor,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: _highlightColor == Colors.transparent
            ? EdgeInsets.zero
            : const EdgeInsets.all(8),
        child: Focus(
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.backspace &&
                ctrl.text.isEmpty &&
                _blocks.length > 1 &&
                index > 0) {
              setState(() {
                _blocks.removeAt(index);
                final prevBlock = _blocks[index - 1];
                if (prevBlock.type == NoteBlockType.text) {
                  _focusTargetId = prevBlock.id;
                } else if (prevBlock.listItems.isNotEmpty) {
                  _focusTargetId = prevBlock.listItems.last.id;
                }
              });
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: TextFormField(
            key: ValueKey(block.id),
            controller: ctrl,
            focusNode: _getFocusNode(block.id),
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textAlign: _textAlign,
            onChanged: (v) {
              block.text = v;
              if (v == '[] ' || v == '[ ] ' || v == '- [ ] ') {
                setState(() {
                  block.type = NoteBlockType.taskList;
                  final newItem = TaskItem(text: '');
                  block.listItems = [newItem];
                  _focusTargetId = newItem.id;
                });
              } else if (v == '- ' || v == '* ' || v == '• ') {
                setState(() {
                  block.type = NoteBlockType.bulletList;
                  final newItem = TaskItem(text: '');
                  block.listItems = [newItem];
                  _focusTargetId = newItem.id;
                });
              }
            },
            style: TextStyle(
              fontSize: 15.0,
              color: context.themeTextPrimary,
              fontFamily: _fontFamily,
              fontWeight: FontWeight.normal,
              fontStyle: FontStyle.normal,
              decoration: TextDecoration.none,
              height: 1.7,
            ),
            decoration: InputDecoration(
              hintText: index == 0 ? 'Start writing your note…' : '',
              hintStyle: TextStyle(
                  color: context.themeTextSecondary.withValues(alpha: 0.4),
                  fontSize: 15),
              border: InputBorder.none,
              isCollapsed: true,
            ),
          ),
        ),
      ),
    );
  }

  // ── Auto-split and focus new task/bullet on Enter ──────────────────────────
  void _handleTaskOrBulletEnter(
      NoteBlock block, int itemIndex, TextEditingController ctrl) {
    final text = ctrl.text;
    final selection = ctrl.selection;

    // If item is empty, convert to normal text block or exit list
    if (text.trim().isEmpty) {
      setState(() {
        if (block.listItems.length > 1) {
          block.listItems.removeAt(itemIndex);
          final newTb =
              NoteBlock(id: _uid(), type: NoteBlockType.text, text: '');
          final blockIndex = _blocks.indexOf(block);
          _blocks.insert(blockIndex + 1, newTb);
          _focusTargetId = newTb.id;
        } else {
          block.type = NoteBlockType.text;
          block.text = '';
          block.listItems = [];
          _focusTargetId = block.id;
        }
      });
      return;
    }

    // Split text at cursor position
    String beforeCursor = text;
    String afterCursor = '';

    if (selection.isValid &&
        selection.baseOffset >= 0 &&
        selection.baseOffset <= text.length) {
      beforeCursor = text.substring(0, selection.baseOffset);
      afterCursor = text.substring(selection.baseOffset);
    }

    final currentItem = block.listItems[itemIndex];
    currentItem.text = beforeCursor;
    ctrl.text = beforeCursor;

    final newItem = TaskItem(text: afterCursor);
    block.listItems.insert(itemIndex + 1, newItem);

    // Pre-initialize controller & focus node for the newly created item
    final nextCtrl = _getTextController(newItem.id, afterCursor, newItem.spans);
    nextCtrl.selection = const TextSelection.collapsed(offset: 0);

    setState(() {
      _focusTargetId = newItem.id;
    });
  }

  // 2. Interactive Task List (Auto-advances to new task on Enter, Backspace on empty converts to text)
  Widget _buildTaskListBlock(NoteBlock block, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(
            block.listItems.length,
            (i) {
              final item = block.listItems[i];
              final ctrl = _getTextController(item.id, item.text, item.spans);

              void convertEmptyTaskToNormalText() {
                setState(() {
                  if (block.listItems.length > 1) {
                    block.listItems.removeAt(i);
                    final newTb = NoteBlock(
                        id: _uid(), type: NoteBlockType.text, text: '');
                    _blocks.insert(index + 1, newTb);
                    _focusTargetId = newTb.id;
                  } else {
                    block.type = NoteBlockType.text;
                    block.text = '';
                    block.listItems = [];
                    _focusTargetId = block.id;
                  }
                });
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: item.checked,
                          onChanged: (v) =>
                              setState(() => item.checked = v ?? false),
                          activeColor: const Color(0xFF10B981),
                          side: BorderSide(
                            color: item.checked
                                ? const Color(0xFF10B981)
                                : context.themeTextSecondary
                                    .withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Focus(
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent) {
                            if (event.logicalKey ==
                                LogicalKeyboardKey.backspace) {
                              if (ctrl.text.isEmpty) {
                                convertEmptyTaskToNormalText();
                                return KeyEventResult.handled;
                              }
                            } else if (event.logicalKey ==
                                    LogicalKeyboardKey.enter ||
                                event.logicalKey ==
                                    LogicalKeyboardKey.numpadEnter) {
                              _handleTaskOrBulletEnter(block, i, ctrl);
                              return KeyEventResult.handled;
                            }
                          }
                          return KeyEventResult.ignored;
                        },
                        child: TextFormField(
                          key: ValueKey(item.id),
                          controller: ctrl,
                          focusNode: _getFocusNode(item.id),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          onChanged: (v) {
                            if (v.contains('\n')) {
                              final lines = v.split('\n');
                              item.text = lines.first;
                              ctrl.text = lines.first;

                              TaskItem? lastItem;
                              for (int k = 1; k < lines.length; k++) {
                                final nextItem = TaskItem(text: lines[k]);
                                block.listItems.insert(i + k, nextItem);
                                lastItem = nextItem;
                              }

                              if (lastItem != null) {
                                _focusTargetId = lastItem.id;
                                final nextCtrl = _getTextController(
                                    lastItem.id, lastItem.text);
                                nextCtrl.selection = TextSelection.collapsed(
                                    offset: lastItem.text.length);
                              }
                              setState(() {});
                            } else {
                              item.text = v;
                            }
                          },
                          textInputAction: TextInputAction.newline,
                          style: TextStyle(
                            color: item.checked
                                ? context.themeTextSecondary
                                : context.themeTextPrimary,
                            fontSize: 15.0,
                            fontFamily: _fontFamily,
                            fontWeight: FontWeight.normal,
                            fontStyle: FontStyle.normal,
                            decoration: item.checked
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: context.themeTextSecondary,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: 'To-do item…',
                            hintStyle: TextStyle(
                              color: context.themeTextSecondary
                                  .withValues(alpha: 0.4),
                              fontSize: 14,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // 3. Interactive Bullet List (Auto-advances to new bullet on Enter, Backspace on empty converts to text)
  Widget _buildBulletListBlock(NoteBlock block, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(
            block.listItems.length,
            (i) {
              final item = block.listItems[i];
              final ctrl = _getTextController(item.id, item.text, item.spans);

              void convertEmptyBulletToNormalText() {
                setState(() {
                  if (block.listItems.length > 1) {
                    block.listItems.removeAt(i);
                    final newTb = NoteBlock(
                        id: _uid(), type: NoteBlockType.text, text: '');
                    _blocks.insert(index + 1, newTb);
                    _focusTargetId = newTb.id;
                  } else {
                    block.type = NoteBlockType.text;
                    block.text = '';
                    block.listItems = [];
                    _focusTargetId = block.id;
                  }
                });
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin:
                          const EdgeInsets.only(right: 10, left: 4, top: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Focus(
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent) {
                            if (event.logicalKey ==
                                LogicalKeyboardKey.backspace) {
                              if (ctrl.text.isEmpty) {
                                convertEmptyBulletToNormalText();
                                return KeyEventResult.handled;
                              }
                            } else if (event.logicalKey ==
                                    LogicalKeyboardKey.enter ||
                                event.logicalKey ==
                                    LogicalKeyboardKey.numpadEnter) {
                              _handleTaskOrBulletEnter(block, i, ctrl);
                              return KeyEventResult.handled;
                            }
                          }
                          return KeyEventResult.ignored;
                        },
                        child: TextFormField(
                          key: ValueKey(item.id),
                          controller: ctrl,
                          focusNode: _getFocusNode(item.id),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          onChanged: (v) {
                            if (v.contains('\n')) {
                              final lines = v.split('\n');
                              item.text = lines.first;
                              ctrl.text = lines.first;

                              TaskItem? lastItem;
                              for (int k = 1; k < lines.length; k++) {
                                final nextItem = TaskItem(text: lines[k]);
                                block.listItems.insert(i + k, nextItem);
                                lastItem = nextItem;
                              }

                              if (lastItem != null) {
                                _focusTargetId = lastItem.id;
                                final nextCtrl = _getTextController(
                                    lastItem.id, lastItem.text);
                                nextCtrl.selection = TextSelection.collapsed(
                                    offset: lastItem.text.length);
                              }
                              setState(() {});
                            } else {
                              item.text = v;
                            }
                          },
                          textInputAction: TextInputAction.newline,
                          style: TextStyle(
                            color: context.themeTextPrimary,
                            fontSize: 15.0,
                            fontFamily: _fontFamily,
                            fontWeight: FontWeight.normal,
                            fontStyle: FontStyle.normal,
                            decoration: TextDecoration.none,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: 'List item…',
                            hintStyle: TextStyle(
                              color: context.themeTextSecondary
                                  .withValues(alpha: 0.4),
                              fontSize: 14,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // 4. Interactive Table with Grid & Add / Delete Rows and Columns
  Widget _buildTableBlock(NoteBlock block, int index) {
    final rowCount = block.tableData.length;
    final colCount =
        block.tableData.isNotEmpty ? block.tableData.first.length : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'TABLE (${rowCount}x$colCount)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: context.themeTextSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                _tableActionBtn(
                  label: '+ Row',
                  color: const Color(0xFF3B82F6),
                  onTap: () => setState(() {
                    final cols = colCount > 0 ? colCount : 3;
                    block.tableData.add(List.generate(cols, (_) => ''));
                  }),
                ),
                const SizedBox(width: 5),
                if (rowCount > 1)
                  _tableActionBtn(
                    label: '- Row',
                    color: Colors.redAccent,
                    onTap: () => setState(() {
                      if (block.tableData.length > 1) {
                        block.tableData.removeLast();
                      }
                    }),
                  ),
                const SizedBox(width: 8),
                _tableActionBtn(
                  label: '+ Col',
                  color: const Color(0xFF10B981),
                  onTap: () => setState(() {
                    for (var r in block.tableData) {
                      r.add('');
                    }
                  }),
                ),
                const SizedBox(width: 5),
                if (colCount > 1)
                  _tableActionBtn(
                    label: '- Col',
                    color: Colors.redAccent,
                    onTap: () => setState(() {
                      for (var r in block.tableData) {
                        if (r.isNotEmpty) r.removeLast();
                      }
                    }),
                  ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _removeBlock(block.id),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline_rounded,
                        size: 16,
                        color: Colors.redAccent.withValues(alpha: 0.8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(110.0),
              border: TableBorder.all(
                color: context.themeTextPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              children: List.generate(block.tableData.length, (ri) {
                final isHeader = ri == 0;
                return TableRow(
                  decoration: BoxDecoration(
                    color: isHeader
                        ? _kCoral.withValues(alpha: 0.08)
                        : Colors.transparent,
                  ),
                  children: List.generate(
                    block.tableData[ri].length,
                    (ci) {
                      final cellId = '${block.id}_${ri}_$ci';
                      final ctrl = _getTextController(
                          cellId, block.tableData[ri][ci]);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: TextFormField(
                          key: ValueKey(cellId),
                          controller: ctrl,
                          onChanged: (v) => block.tableData[ri][ci] = v,
                          style: TextStyle(
                            color: context.themeTextPrimary,
                            fontSize: 13.5,
                            fontWeight:
                                isHeader ? FontWeight.bold : FontWeight.normal,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: isHeader ? 'Header' : '...',
                            hintStyle: TextStyle(
                              color: context.themeTextSecondary
                                  .withValues(alpha: 0.4),
                              fontSize: 13,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 6),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _tableActionBtn({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ── Insert Sheet ──────────────────────────────────────────────────────────
  void _showFeaturesMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.themeCardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.68,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, sc) {
          return ListView(
            controller: sc,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: context.themeTextPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(
                'Insert Blocks & Tools',
                style: TextStyle(
                    color: context.themeTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _insertTile(Icons.notes_rounded, 'Text Paragraph', _kCoral,
                      () {
                    Navigator.pop(context);
                    _addTextBlock();
                  }),
                  _insertTile(
                      Icons.task_alt_rounded, 'Task List', const Color(0xFFF59E0B),
                      () {
                    Navigator.pop(context);
                    _addTaskListBlock();
                  }),
                  _insertTile(
                      Icons.table_chart_rounded, 'Table', const Color(0xFF3B82F6),
                      () {
                    Navigator.pop(context);
                    _addTableBlock();
                  }),
                  _insertTile(Icons.format_list_bulleted_rounded, 'Bullet List',
                      const Color(0xFF10B981), () {
                    Navigator.pop(context);
                    _addBulletListBlock();
                  }),
                  _insertTile(Icons.format_quote_rounded, 'Quote',
                      const Color(0xFFF08A82), () {
                    Navigator.pop(context);
                    _insertIntoActiveText('\n> Quote text\n');
                  }),
                  _insertTile(
                      Icons.code_rounded, 'Code Block', const Color(0xFF8B5CF6),
                      () {
                    Navigator.pop(context);
                    _insertIntoActiveText('\n```\n// code here\n```\n');
                  }),
                  _insertTile(Icons.horizontal_rule_rounded, 'Divider',
                      context.themeTextSecondary, () {
                    Navigator.pop(context);
                    _insertIntoActiveText('\n────────────────\n');
                  }),
                  _insertTile(
                      Icons.calendar_today_rounded, 'Date', const Color(0xFFF08A82),
                      () {
                    Navigator.pop(context);
                    final n = DateTime.now();
                    _insertIntoActiveText(' ${n.day}/${n.month}/${n.year} ');
                  }),
                  _insertTile(
                      Icons.access_time_rounded, 'Time', const Color(0xFF10B981),
                      () {
                    Navigator.pop(context);
                    final n = DateTime.now();
                    _insertIntoActiveText(
                        ' ${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')} ');
                  }),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: context.themeTextPrimary.withValues(alpha: 0.08)),
              const SizedBox(height: 8),
              _sheetSectionLabel('QUICK ACTIONS'),
              const SizedBox(height: 8),
              _toolTile(
                  Icons.copy_rounded, 'Copy All Text', const Color(0xFF3B82F6),
                  () {
                Navigator.pop(context);
                _syncControllersToBlocks();
                final compiled = _blocks.map((b) => b.text).join('\n');
                Clipboard.setData(ClipboardData(text: compiled));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: context.themeCardBackground,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  content: Row(children: [
                    const Icon(Icons.check_circle_outline,
                        color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 8),
                    Text('Copied to clipboard',
                        style: TextStyle(color: context.themeTextPrimary)),
                  ]),
                ));
              }),
              _toolTile(Icons.print_rounded, 'Print Note (PDF)',
                  context.themeTextSecondary, () {
                Navigator.pop(context);
                _printNote();
              }),
              _toolTile(Icons.share_rounded, 'Share Note',
                  context.themeTextSecondary, () {
                Navigator.pop(context);
                _shareNote();
              }),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  // ── Format Sheet ──────────────────────────────────────────────────────────
  void _showFormatMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.themeCardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) {
          void sync(VoidCallback fn) {
            setModal(fn);
            setState(fn);
          }

          return SingleChildScrollView(
            padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: context.themeTextPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text(
                  'Format Typography',
                  style: TextStyle(
                      color: context.themeTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Text style presets
                _sheetSectionLabel('TEXT STYLE PRESETS'),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _stylePreset('Title', 28, sync),
                      const SizedBox(width: 8),
                      _stylePreset('Heading', 22, sync),
                      const SizedBox(width: 8),
                      _stylePreset('Sub', 18, sync),
                      const SizedBox(width: 8),
                      _stylePreset('Body', 15, sync),
                      const SizedBox(width: 8),
                      _stylePreset('Small', 12, sync),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Font family
                _sheetSectionLabel('FONT FAMILY'),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.themeTextPrimary.withValues(alpha: 0.035),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            context.themeTextPrimary.withValues(alpha: 0.08)),
                  ),
                  child: DropdownButton<String>(
                    value: _fontFamily,
                    isExpanded: true,
                    dropdownColor: context.themeCardBackground,
                    underline: const SizedBox(),
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
                        color: context.themeTextSecondary, size: 14),
                    style: TextStyle(
                        color: context.themeTextPrimary, fontSize: 14),
                    onChanged: (v) {
                      if (v != null) sync(() => _fontFamily = v);
                    },
                    items: kFonts
                        .map((f) => DropdownMenuItem<String>(
                              value: f['family'],
                              child: Row(children: [
                                Container(
                                    width: 3,
                                    height: 14,
                                    decoration: BoxDecoration(
                                        color: _kCoral,
                                        borderRadius:
                                            BorderRadius.circular(2))),
                                const SizedBox(width: 10),
                                Text(f['label']!,
                                    style: TextStyle(
                                        fontFamily: f['family'],
                                        color: context.themeTextPrimary,
                                        fontSize: 14)),
                                if (_fontFamily == f['family']) ...[
                                  const Spacer(),
                                  const Icon(Icons.check_rounded,
                                      color: _kCoral, size: 15)
                                ],
                              ]),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Font size
                _sheetSectionLabel('FONT SIZE'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _roundBtn(Icons.remove_rounded, () {
                      sync(_decreaseFontSize);
                    }),
                    const SizedBox(width: 14),
                    Container(
                      width: 50,
                      height: 38,
                      decoration: BoxDecoration(
                        color:
                            context.themeTextPrimary.withValues(alpha: 0.035),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: context.themeTextPrimary
                                .withValues(alpha: 0.08)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${_getActiveFontSize().toInt()}',
                        style: TextStyle(
                            color: context.themeTextPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    _roundBtn(Icons.add_rounded, () {
                      sync(_increaseFontSize);
                    }),
                  ],
                ),
                const SizedBox(height: 20),

                // Style + alignment
                _sheetSectionLabel('STYLE & ALIGNMENT'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _fmtChip('B', _isBoldActive(),
                        fontWeight: FontWeight.bold,
                        onTap: () => sync(_toggleBold)),
                    const SizedBox(width: 6),
                    _fmtChip('I', _isItalicActive(),
                        isItalic: true,
                        onTap: () => sync(_toggleItalic)),
                    const SizedBox(width: 6),
                    _fmtChip('U', _isUnderlineActive(),
                        underline: true,
                        onTap: () => sync(_toggleUnderline)),
                    const SizedBox(width: 6),
                    _fmtChip('S', _isStrikethroughActive(),
                        strikethrough: true,
                        onTap: () => sync(_toggleStrikethrough)),
                    const SizedBox(width: 12),
                    Container(
                        width: 1,
                        height: 28,
                        color:
                            context.themeTextPrimary.withValues(alpha: 0.1)),
                    const SizedBox(width: 12),
                    ...[
                      (Icons.format_align_left_rounded, TextAlign.left),
                      (Icons.format_align_center_rounded, TextAlign.center),
                      (Icons.format_align_right_rounded, TextAlign.right),
                      (Icons.format_align_justify_rounded, TextAlign.justify),
                    ].map((p) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _alignBtn(p.$1, p.$2, sync),
                        )),
                  ],
                ),
                const SizedBox(height: 20),

                // Font color
                _sheetSectionLabel('FONT COLOR'),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      context.themeTextPrimary,
                      _kCoral,
                      const Color(0xFF3B82F6),
                      const Color(0xFF10B981),
                      const Color(0xFFF59E0B),
                      const Color(0xFFEF4444),
                      const Color(0xFF8B5CF6),
                      const Color(0xFFEC4899),
                    ].map((c) {
                      final currentTargetColor =
                          _getActiveTextColor() ?? context.themeTextPrimary;
                      final isSelected = currentTargetColor.toARGB32() ==
                          c.toARGB32();
                      return GestureDetector(
                        onTap: () => sync(() => _applyTextColor(c)),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isSelected
                                    ? context.themeTextPrimary
                                    : Colors.transparent,
                                width: 2.5),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                        color: c.withValues(alpha: 0.5),
                                        blurRadius: 8)
                                  ]
                                : [],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Highlight
                _sheetSectionLabel('HIGHLIGHT BACKGROUND'),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Colors.transparent,
                      _kCoral.withValues(alpha: 0.25),
                      const Color(0xFF3B82F6).withValues(alpha: 0.25),
                      const Color(0xFF10B981).withValues(alpha: 0.25),
                      const Color(0xFFF59E0B).withValues(alpha: 0.25),
                      const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                    ].map((c) {
                      final none = c == Colors.transparent;
                      return GestureDetector(
                        onTap: () => sync(() => _highlightColor = c),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: none ? context.themeCardBackground : c,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _highlightColor == c
                                    ? _kCoral
                                    : context.themeTextPrimary
                                        .withValues(alpha: 0.1),
                                width: 2),
                          ),
                          child: none
                              ? Icon(Icons.do_not_disturb_alt_rounded,
                                  size: 14, color: context.themeTextSecondary)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Sheet widget helpers ───────────────────────────────────────────────────
  Widget _sheetSectionLabel(String t) => Text(
        t,
        style: TextStyle(
          color: context.themeTextSecondary,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      );

  Widget _insertTile(
          IconData icon, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                    color: color, fontSize: 11.5, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _toolTile(
          IconData icon, String label, Color color, VoidCallback onTap) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: color, size: 17),
        ),
        title: Text(label,
            style: TextStyle(
                color: context.themeTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.chevron_right_rounded,
            color: context.themeTextSecondary, size: 18),
        onTap: onTap,
        dense: true,
      );

  Widget _stylePreset(
      String label, double size, Function(VoidCallback) sync) {
    final activeSize = _getActiveFontSize();
    final sel = (activeSize - size).abs() < 0.5;
    return GestureDetector(
      onTap: () => sync(() => _applyFontSize(size)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel
              ? _kCoral
              : context.themeTextPrimary.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: sel
                  ? _kCoral
                  : context.themeTextPrimary.withValues(alpha: 0.08)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel ? Colors.white : context.themeTextPrimary,
            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: context.themeTextPrimary.withValues(alpha: 0.035),
            shape: BoxShape.circle,
            border: Border.all(
                color: context.themeTextPrimary.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, color: context.themeTextSecondary, size: 17),
        ),
      );

  Widget _fmtChip(
    String label,
    bool active, {
    FontWeight? fontWeight,
    bool isItalic = false,
    bool underline = false,
    bool strikethrough = false,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: active
                ? _kCoral.withValues(alpha: 0.15)
                : context.themeTextPrimary.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
                color: active
                    ? _kCoral
                    : context.themeTextPrimary.withValues(alpha: 0.08)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? _kCoral : context.themeTextSecondary,
              fontWeight: fontWeight ?? FontWeight.w700,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              decoration: underline
                  ? TextDecoration.underline
                  : strikethrough
                      ? TextDecoration.lineThrough
                      : null,
              decorationColor: active ? _kCoral : context.themeTextSecondary,
              fontSize: 13,
            ),
          ),
        ),
      );

  Widget _alignBtn(
      IconData icon, TextAlign align, Function(VoidCallback) sync) {
    final active = _textAlign == align;
    return GestureDetector(
      onTap: () => sync(() => _textAlign = align),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: active
              ? _kCoral.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 15,
            color: active ? _kCoral : context.themeTextSecondary),
      ),
    );
  }

  // ── Toolbar atoms ─────────────────────────────────────────────────────────
  Widget _tb(IconData icon, bool active, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: active
                ? _kCoral.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon,
              size: 16,
              color: active ? _kCoral : context.themeTextSecondary),
        ),
      );

  Widget _vDiv() => Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: context.themeTextPrimary.withValues(alpha: 0.1));

  // ── Main build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusTargetId != null) {
        final targetId = _focusTargetId!;
        _focusTargetId = null;
        final node = _focusNodes[targetId];
        if (node != null && mounted) {
          node.requestFocus();
          final ctrl = _textControllers[targetId];
          if (ctrl != null) {
            ctrl.selection =
                TextSelection.collapsed(offset: ctrl.text.length);
          }
        }
      }
    });

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _saveNoteSilently();
      },
      child: Scaffold(
        backgroundColor: context.themeBackground,
        appBar: AppBar(
          backgroundColor: context.themeBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 56,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: context.themeTextPrimary, size: 18),
            onPressed: () {
              _saveNoteSilently();
              Navigator.of(context).pop();
            },
          ),
          title: TextField(
            controller: _titleCtrl,
            style: TextStyle(
                color: context.themeTextPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'Note title…',
              hintStyle: TextStyle(
                  color: context.themeTextSecondary.withValues(alpha: 0.5),
                  fontSize: 17),
              border: InputBorder.none,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.ios_share_rounded,
                  color: context.themeTextSecondary, size: 20),
              onPressed: _shareNote,
            ),
            IconButton(
              icon: Icon(Icons.print_outlined,
                  color: context.themeTextSecondary, size: 20),
              onPressed: _printNote,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
              child: ElevatedButton(
                onPressed: () {
                  _saveNoteSilently();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kCoral,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Save',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(
                color: context.themeTextPrimary.withValues(alpha: 0.05),
                height: 1),
          ),
        ),
        body: Column(children: [
          // ── Scrollable Document Body (Text, Tasks, Tables) ─────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...List.generate(_blocks.length, (i) {
                    final b = _blocks[i];
                    switch (b.type) {
                      case NoteBlockType.text:
                        return _buildTextBlock(b, i);
                      case NoteBlockType.taskList:
                        return _buildTaskListBlock(b, i);
                      case NoteBlockType.bulletList:
                        return _buildBulletListBlock(b, i);
                      case NoteBlockType.table:
                        return _buildTableBlock(b, i);
                    }
                  }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // ── Bottom Toolbar ──────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: context.themeCardBackground,
              border: Border(
                  top: BorderSide(
                      color: context.themeTextPrimary.withValues(alpha: 0.05))),
            ),
            child: SafeArea(
              top: false,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Row 1: font family, size, B/I/U/S, alignment
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      Container(
                        height: 30,
                        constraints: const BoxConstraints(minWidth: 88),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color:
                              context.themeTextPrimary.withValues(alpha: 0.035),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: context.themeTextPrimary
                                  .withValues(alpha: 0.08)),
                        ),
                        child: DropdownButton<String>(
                          value: _fontFamily,
                          underline: const SizedBox(),
                          dropdownColor: context.themeCardBackground,
                          icon: Icon(Icons.keyboard_arrow_down_rounded,
                              color: context.themeTextSecondary, size: 14),
                          style: TextStyle(
                              color: context.themeTextPrimary, fontSize: 12),
                          onChanged: (v) {
                            if (v != null) setState(() => _fontFamily = v);
                          },
                          items: kFonts
                              .map((f) => DropdownMenuItem<String>(
                                    value: f['family'],
                                    child: Text(f['label']!,
                                        style: TextStyle(
                                            fontFamily: f['family'],
                                            color: context.themeTextPrimary,
                                            fontSize: 12)),
                                  ))
                              .toList(),
                        ),
                      ),
                      _vDiv(),
                      GestureDetector(
                        onTap: _decreaseFontSize,
                        child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: context.themeTextPrimary
                                  .withValues(alpha: 0.035),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: context.themeTextPrimary
                                      .withValues(alpha: 0.08)),
                            ),
                            child: Icon(Icons.remove_rounded,
                                size: 13, color: context.themeTextSecondary)),
                      ),
                      SizedBox(
                          width: 28,
                          child: Center(
                            child: Text('${_getActiveFontSize().toInt()}',
                                style: TextStyle(
                                    color: context.themeTextPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          )),
                      GestureDetector(
                        onTap: _increaseFontSize,
                        child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: context.themeTextPrimary
                                  .withValues(alpha: 0.035),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: context.themeTextPrimary
                                      .withValues(alpha: 0.08)),
                            ),
                            child: Icon(Icons.add_rounded,
                                size: 13, color: context.themeTextSecondary)),
                      ),
                      _vDiv(),
                      _tb(
                        Icons.format_bold_rounded,
                        _isBoldActive(),
                        _toggleBold,
                      ),
                      const SizedBox(width: 2),
                      _tb(
                        Icons.format_italic_rounded,
                        _isItalicActive(),
                        _toggleItalic,
                      ),
                      const SizedBox(width: 2),
                      _tb(
                        Icons.format_underlined_rounded,
                        _isUnderlineActive(),
                        _toggleUnderline,
                      ),
                      const SizedBox(width: 2),
                      _tb(
                        Icons.format_strikethrough_rounded,
                        _isStrikethroughActive(),
                        _toggleStrikethrough,
                      ),
                      _vDiv(),
                      _tb(
                          Icons.format_align_left_rounded,
                          _textAlign == TextAlign.left,
                          () => setState(() => _textAlign = TextAlign.left)),
                      const SizedBox(width: 2),
                      _tb(
                          Icons.format_align_center_rounded,
                          _textAlign == TextAlign.center,
                          () => setState(() => _textAlign = TextAlign.center)),
                      const SizedBox(width: 2),
                      _tb(
                          Icons.format_align_right_rounded,
                          _textAlign == TextAlign.right,
                          () => setState(() => _textAlign = TextAlign.right)),
                    ]),
                  ),
                ),

                // Row 2: Insert Button + Format Button + Live Word/Char Count
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Row(children: [
                    GestureDetector(
                      onTap: _showFeaturesMenu,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _kCoral.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _kCoral.withValues(alpha: 0.25)),
                        ),
                        child: const Row(children: [
                          Icon(Icons.add_rounded, color: _kCoral, size: 14),
                          SizedBox(width: 5),
                          Text('Insert',
                              style: TextStyle(
                                  color: _kCoral,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _showFormatMenu,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              context.themeTextPrimary.withValues(alpha: 0.035),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: context.themeTextPrimary
                                  .withValues(alpha: 0.08)),
                        ),
                        child: Row(children: [
                          Icon(Icons.tune_rounded,
                              color: context.themeTextSecondary, size: 14),
                          const SizedBox(width: 5),
                          Text('Format',
                              style: TextStyle(
                                  color: context.themeTextSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                    const Spacer(),
                    Text('$_wordCount w · $_charCount c',
                        style: TextStyle(
                            color: context.themeTextSecondary
                                .withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ]),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}