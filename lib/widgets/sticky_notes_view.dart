import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';

// ─── Pastel Design Palette ───────────────────────────────────────────────────
const List<int> kNoteColors = [
  0xFFFEF3C7, // Classic Soft Amber / Yellow Post-It
  0xFFFEE2E2, // Soft Peach / Coral
  0xFFD1FAE5, // Soft Mint Green
  0xFFDBEAFE, // Soft Sky Blue
  0xFFEDE9FE, // Soft Lavender
  0xFFFCE7F3, // Soft Rose Pink
  0xFFCCFBF1, // Soft Ocean Teal
  0xFFFEF9C3, // Soft Lemon Lime
];

const List<String> kDefaultTags = [
  'Work',
  'Personal',
  'Urgent',
  'Idea',
  'Shopping',
  'Important',
];

enum NoteFormat { freeText, checklist, bullet, numbered }

// ─── Smart Auto-List Formatter for Numbered & Bullet Lists ─────────────────────
class AutoListTextInputFormatter extends TextInputFormatter {
  final NoteFormat Function() getFormat;
  AutoListTextInputFormatter({required this.getFormat});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length == oldValue.text.length + 1 &&
        newValue.selection.isCollapsed &&
        newValue.selection.baseOffset > 0 &&
        newValue.text[newValue.selection.baseOffset - 1] == '\n') {
      final cursorOffset = newValue.selection.baseOffset;
      final textBeforeCursor = newValue.text.substring(0, cursorOffset - 1);
      final lines = textBeforeCursor.split('\n');
      final previousLine = lines.isNotEmpty ? lines.last : '';

      // 1. Match numbered list: e.g. "1. Something"
      final numberMatch =
          RegExp(r'^(\s*)(\d+)[\.\)]\s*(.*)$').firstMatch(previousLine);
      if (numberMatch != null) {
        final indent = numberMatch.group(1) ?? '';
        final currentNum = int.tryParse(numberMatch.group(2) ?? '1') ?? 1;
        final content = numberMatch.group(3) ?? '';

        if (content.trim().isEmpty) {
          final prefixLength = previousLine.length;
          final startOfLine = cursorOffset - 1 - prefixLength;
          final updatedText =
              newValue.text.replaceRange(startOfLine, cursorOffset, '');
          return TextEditingValue(
            text: updatedText,
            selection: TextSelection.collapsed(offset: startOfLine),
          );
        }

        final nextPrefix = '$indent${currentNum + 1}. ';
        final updatedText =
            newValue.text.replaceRange(cursorOffset, cursorOffset, nextPrefix);
        return TextEditingValue(
          text: updatedText,
          selection: TextSelection.collapsed(
              offset: cursorOffset + nextPrefix.length),
        );
      }

      // 2. Match bullet list: e.g. "• Something"
      final bulletMatch =
          RegExp(r'^(\s*)([•\-\*])\s*(.*)$').firstMatch(previousLine);
      if (bulletMatch != null) {
        final indent = bulletMatch.group(1) ?? '';
        final symbol = bulletMatch.group(2) ?? '•';
        final content = bulletMatch.group(3) ?? '';

        if (content.trim().isEmpty) {
          final prefixLength = previousLine.length;
          final startOfLine = cursorOffset - 1 - prefixLength;
          final updatedText =
              newValue.text.replaceRange(startOfLine, cursorOffset, '');
          return TextEditingValue(
            text: updatedText,
            selection: TextSelection.collapsed(offset: startOfLine),
          );
        }

        final nextPrefix = '$indent$symbol ';
        final updatedText =
            newValue.text.replaceRange(cursorOffset, cursorOffset, nextPrefix);
        return TextEditingValue(
          text: updatedText,
          selection: TextSelection.collapsed(
              offset: cursorOffset + nextPrefix.length),
        );
      }

      if (getFormat() == NoteFormat.numbered && lines.isEmpty) {
        const nextPrefix = '1. ';
        final updatedText =
            newValue.text.replaceRange(cursorOffset, cursorOffset, nextPrefix);
        return TextEditingValue(
          text: updatedText,
          selection: TextSelection.collapsed(
              offset: cursorOffset + nextPrefix.length),
        );
      }
    }

    return newValue;
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────
class StickyNote {
  String id;
  String title;
  String body;
  List<StickyItem> items;
  int colorValue;
  bool isPinned;
  DateTime createdAt;
  NoteFormat format;
  List<String> tags;

  StickyNote({
    required this.id,
    required this.title,
    this.body = '',
    required this.items,
    required this.colorValue,
    this.isPinned = false,
    DateTime? createdAt,
    this.format = NoteFormat.freeText,
    List<String>? tags,
  })  : createdAt = createdAt ?? DateTime.now(),
        tags = tags ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'items': items.map((i) => i.toJson()).toList(),
        'colorValue': colorValue,
        'isPinned': isPinned,
        'createdAt': createdAt.toIso8601String(),
        'format': format.index,
        'tags': tags,
      };

  factory StickyNote.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<StickyItem> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .map((i) => i is Map<String, dynamic> ? StickyItem.fromJson(i) : null)
          .whereType<StickyItem>()
          .toList();
    }

    final rawFormat = json['format'] ?? json['noteType'] ?? 0;
    final fmtIndex = rawFormat is int
        ? rawFormat.clamp(0, NoteFormat.values.length - 1)
        : 0;

    var rawTags = json['tags'];
    List<String> parsedTags = [];
    if (rawTags is List) {
      parsedTags = rawTags.map((t) => t.toString()).toList();
    }

    return StickyNote(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      items: parsedItems,
      colorValue:
          (json['colorValue'] is int) ? json['colorValue'] : 0xFFFEF3C7,
      isPinned: json['isPinned'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      format: NoteFormat.values[fmtIndex],
      tags: parsedTags,
    );
  }

  StickyNote copyWith({
    String? id,
    String? title,
    String? body,
    List<StickyItem>? items,
    int? colorValue,
    bool? isPinned,
    DateTime? createdAt,
    NoteFormat? format,
    List<String>? tags,
  }) =>
      StickyNote(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body ?? this.body,
        items: items ?? this.items,
        colorValue: colorValue ?? this.colorValue,
        isPinned: isPinned ?? this.isPinned,
        createdAt: createdAt ?? this.createdAt,
        format: format ?? this.format,
        tags: tags ?? this.tags,
      );
}

class StickyItem {
  String id;
  String text;
  bool isChecked;

  StickyItem({
    String? id,
    required this.text,
    this.isChecked = false,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isChecked': isChecked,
      };

  factory StickyItem.fromJson(Map<String, dynamic> json) => StickyItem(
        id: json['id']?.toString(),
        text: json['text']?.toString() ?? '',
        isChecked: json['isChecked'] == true,
      );
}

// ─── Main View ────────────────────────────────────────────────────────────────
class StickyNotesView extends StatefulWidget {
  final List<StickyNote> stickyNotes;
  final Function(List<StickyNote>) onStickyNotesChanged;

  const StickyNotesView({
    super.key,
    required this.stickyNotes,
    required this.onStickyNotesChanged,
  });

  @override
  State<StickyNotesView> createState() => _StickyNotesViewState();
}

class _StickyNotesViewState extends State<StickyNotesView> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  NoteFormat? _selectedFormatFilter;
  String _selectedTagFilter = 'All';

  List<StickyNote> get _filteredNotes {
    final query = _searchQuery.toLowerCase().trim();
    final notes = widget.stickyNotes.where((n) {
      final matchesQuery = query.isEmpty ||
          n.title.toLowerCase().contains(query) ||
          n.body.toLowerCase().contains(query) ||
          n.tags.any((t) => t.toLowerCase().contains(query)) ||
          n.items.any((i) => i.text.toLowerCase().contains(query));

      final matchesFormat = _selectedFormatFilter == null ||
          n.format == _selectedFormatFilter;

      final matchesTag = _selectedTagFilter == 'All' ||
          n.tags.contains(_selectedTagFilter);

      return matchesQuery && matchesFormat && matchesTag;
    }).toList();

    notes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return notes;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleCheckItem(StickyNote note, int itemIndex) {
    if (itemIndex < 0 || itemIndex >= note.items.length) return;
    final newItems = List<StickyItem>.from(note.items);
    newItems[itemIndex] = StickyItem(
      id: newItems[itemIndex].id,
      text: newItems[itemIndex].text,
      isChecked: !newItems[itemIndex].isChecked,
    );
    final updated = note.copyWith(items: newItems);
    final newList = widget.stickyNotes
        .map((s) => s.id == updated.id ? updated : s)
        .toList();
    widget.onStickyNotesChanged(newList);
  }

  void _deleteNote(StickyNote note) {
    final newList =
        widget.stickyNotes.where((s) => s.id != note.id).toList();
    widget.onStickyNotesChanged(newList);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sticky note deleted'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _togglePin(StickyNote note) {
    final updated = note.copyWith(isPinned: !note.isPinned);
    final newList = widget.stickyNotes
        .map((s) => s.id == updated.id ? updated : s)
        .toList();
    widget.onStickyNotesChanged(newList);
  }

  void _duplicateNote(StickyNote note) {
    final clone = StickyNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: note.title.isEmpty ? '' : '${note.title} (Copy)',
      body: note.body,
      items: note.items
          .map((i) => StickyItem(text: i.text, isChecked: false))
          .toList(),
      colorValue: note.colorValue,
      format: note.format,
      tags: List<String>.from(note.tags),
      isPinned: false,
    );
    widget.onStickyNotesChanged([clone, ...widget.stickyNotes]);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sticky note duplicated!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyNoteContent(StickyNote note) {
    String textToCopy = '';
    if (note.title.isNotEmpty) {
      textToCopy += '${note.title}\n\n';
    }
    if (note.format == NoteFormat.checklist) {
      textToCopy += note.items
          .map((i) => '${i.isChecked ? '[x]' : '[ ]'} ${i.text}')
          .join('\n');
    } else {
      textToCopy += note.body;
    }

    Clipboard.setData(ClipboardData(text: textToCopy.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied note to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final isMobile = sw < 800;
    final cols = isMobile ? 2 : (sw < 1100 ? 3 : 4);
    final totalChecklists = widget.stickyNotes
        .where((n) => n.format == NoteFormat.checklist)
        .length;
    final pinnedCount =
        widget.stickyNotes.where((n) => n.isPinned).length;
    final listCount = widget.stickyNotes
        .where((n) =>
            n.format == NoteFormat.numbered ||
            n.format == NoteFormat.bullet)
        .length;

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
            // ─── 1. TOP HEADER (Fixed) ───
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
                            'Sticky ',
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
                              color: Color(0xFFF08A82),
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Auto-numbered lists, bullets, tags & checklists',
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
                  onTap: () => _createNewNote(NoteFormat.freeText),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF08A82),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 18, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'New Sticky',
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

            // ─── 2. STICKY PULSE SUMMARY CARD (Fixed) ───
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
                            Icons.push_pin_outlined,
                            size: 16,
                            color: Color(0xFFF08A82),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'STICKY BOARD PULSE',
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
                        '${widget.stickyNotes.length} Total Stickies',
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
                              horizontal: 10, vertical: 8),
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
                              const Icon(Icons.format_list_numbered_rounded,
                                  size: 18, color: Color(0xFF93C5FD)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$listCount',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: context.themeTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Lists & Bullets',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: context.themeTextSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
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
                              const Icon(Icons.check_circle_outline_rounded,
                                  size: 18, color: Color(0xFF86EFAC)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$totalChecklists',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: context.themeTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Checklists',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: context.themeTextSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
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
                              const Icon(Icons.push_pin_rounded,
                                  size: 18, color: Color(0xFFFDE047)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$pinnedCount',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: context.themeTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Pinned',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: context.themeTextSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
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

            // ─── 3. SEARCH BAR (Fixed) ───
            Container(
              decoration: BoxDecoration(
                color: context.themeCardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: context.themeTextPrimary.withValues(alpha: 0.05),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style:
                    TextStyle(color: context.themeTextPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search stickies by text, items or #tags...',
                  hintStyle: TextStyle(
                    color: context.themeTextSecondary.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 18, color: context.themeTextSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ─── 4. FORMAT & TAG FILTER CHIPS (Fixed) ───
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterPill('All', null),
                  _buildFilterPill('🔢 1, 2, 3 Numbered', NoteFormat.numbered),
                  _buildFilterPill('⏺️ Bullets', NoteFormat.bullet),
                  _buildFilterPill('☑️ Checklists', NoteFormat.checklist),
                  _buildFilterPill('📝 Free Memos', NoteFormat.freeText),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 20,
                    color:
                        context.themeTextPrimary.withValues(alpha: 0.1),
                  ),
                  const SizedBox(width: 8),
                  ...kDefaultTags.map((tag) => _buildTagFilterPill(tag)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ─── 5. SCROLLABLE STICKY BOARD SECTION ───
            Expanded(
              child: _filteredNotes.isEmpty
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _buildEmpty(),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      child: _buildMasonryGrid(cols),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, NoteFormat? format) {
    final isSelected = _selectedFormatFilter == format && _selectedTagFilter == 'All';
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFormatFilter = format;
            _selectedTagFilter = 'All';
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFF08A82)
                : context.themeCardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFF08A82)
                  : context.themeTextPrimary.withValues(alpha: 0.05),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : context.themeTextSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagFilterPill(String tag) {
    final isSelected = _selectedTagFilter == tag;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTagFilter = isSelected ? 'All' : tag;
            _selectedFormatFilter = null;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF93C5FD)
                : context.themeCardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF93C5FD)
                  : context.themeTextPrimary.withValues(alpha: 0.05),
            ),
          ),
          child: Text(
            '#$tag',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black87 : context.themeTextSecondary,
            ),
          ),
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
              Icons.push_pin_outlined,
              size: 36,
              color: const Color(0xFFF08A82).withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'No Sticky Notes Found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: context.themeTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "New Sticky" above to pin your thoughts and checklists.',
              style: TextStyle(
                fontSize: 12,
                color: context.themeTextSecondary,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => _createNewNote(NoteFormat.freeText),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create Sticky Note',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF08A82),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildMasonryGrid(int cols) {
    final notes = _filteredNotes;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(cols, (colIndex) {
        return Expanded(
          child: Column(
            children: [
              for (int i = colIndex; i < notes.length; i += cols)
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: _StickyCard(
                    note: notes[i],
                    onTap: () => _showEditModal(notes[i]),
                    onTogglePin: () => _togglePin(notes[i]),
                    onDelete: () => _deleteNote(notes[i]),
                    onDuplicate: () => _duplicateNote(notes[i]),
                    onCopy: () => _copyNoteContent(notes[i]),
                    onToggleCheck: (itemIndex) =>
                        _toggleCheckItem(notes[i], itemIndex),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  void _createNewNote(NoteFormat format) {
    List<StickyItem> initialItems = [];
    String initialBody = '';

    if (format == NoteFormat.checklist) {
      initialItems = [
        StickyItem(text: 'First item'),
        StickyItem(text: 'Second item'),
      ];
    } else if (format == NoteFormat.numbered) {
      initialBody = '1. ';
    } else if (format == NoteFormat.bullet) {
      initialBody = '• ';
    }

    final note = StickyNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '',
      body: initialBody,
      items: initialItems,
      colorValue: kNoteColors[Random().nextInt(kNoteColors.length)],
      format: format,
      tags: [],
    );
    _showEditModal(note, isNew: true);
  }

  void _showEditModal(StickyNote note, {bool isNew = false}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, a1, a2) => _NoteEditDialog(
        note: note,
        onSave: (updated) {
          final newList = isNew
              ? [updated, ...widget.stickyNotes]
              : widget.stickyNotes
                  .map((s) => s.id == updated.id ? updated : s)
                  .toList();
          widget.onStickyNotesChanged(newList);
        },
        onDelete: () => _deleteNote(note),
        onCopy: () => _copyNoteContent(note),
      ),
      transitionBuilder: (ctx, a1, a2, child) => FadeTransition(
        opacity: a1,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: a1, curve: Curves.easeOutCubic),
          child: child,
        ),
      ),
    );
  }
}

// ─── Card Component with Authentic Post-It Aesthetics & High Polish ──────────
class _StickyCard extends StatelessWidget {
  final StickyNote note;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onCopy;
  final Function(int) onToggleCheck;

  const _StickyCard({
    required this.note,
    required this.onTap,
    required this.onTogglePin,
    required this.onDelete,
    required this.onDuplicate,
    required this.onCopy,
    required this.onToggleCheck,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = Color(note.colorValue);
    final angle = (note.id.hashCode % 5 - 2) * (pi / 500);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Transform.rotate(
          angle: angle,
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top Tape / Clip Header
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 42,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.45),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Note Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Title, Pin, Menu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              note.title.isEmpty ? 'Untitled' : note.title,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: onTogglePin,
                            child: Icon(
                              note.isPinned
                                  ? Icons.push_pin_rounded
                                  : Icons.push_pin_outlined,
                              size: 16,
                              color: note.isPinned
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF475569)
                                      .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),

                      // Tags Row (if any)
                      if (note.tags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: note.tags.take(3).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#$tag',
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 8),

                      // Format Specific Content Rendering
                      if (note.format == NoteFormat.checklist)
                        _buildChecklistPreview()
                      else if (note.format == NoteFormat.bullet)
                        _buildBulletPreview()
                      else if (note.format == NoteFormat.numbered)
                        _buildNumberedPreview()
                      else
                        _buildFreeTextPreview(),

                      const SizedBox(height: 10),

                      // Footer actions: Copy, Duplicate, Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(note.createdAt),
                            style: TextStyle(
                              color: const Color(0xFF475569)
                                  .withValues(alpha: 0.65),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: onCopy,
                                child: Icon(
                                  Icons.copy_rounded,
                                  size: 14,
                                  color: const Color(0xFF475569)
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: onDuplicate,
                                child: Icon(
                                  Icons.control_point_duplicate_rounded,
                                  size: 14,
                                  color: const Color(0xFF475569)
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0 && now.day == dt.day) {
      return 'Today';
    }
    return '${dt.day}/${dt.month}';
  }

  // 1. Checklist preview with tap-to-check directly on card
  Widget _buildChecklistPreview() {
    if (note.items.isEmpty) {
      return Text(
        'Empty checklist',
        style: TextStyle(
          color: const Color(0xFF334155).withValues(alpha: 0.6),
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final displayItems = note.items.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(displayItems.length, (idx) {
        final item = displayItems[idx];
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => onToggleCheck(idx),
                child: Container(
                  width: 15,
                  height: 15,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: item.isChecked
                        ? const Color(0xFF10B981)
                        : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: item.isChecked
                          ? const Color(0xFF10B981)
                          : const Color(0xFF475569).withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: item.isChecked
                      ? const Icon(Icons.check, size: 11, color: Colors.white)
                      : null,
                ),
              ),
              Expanded(
                child: Text(
                  item.text,
                  style: TextStyle(
                    color: item.isChecked
                        ? const Color(0xFF475569).withValues(alpha: 0.55)
                        : const Color(0xFF1E293B),
                    fontSize: 12,
                    decoration: item.isChecked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // 2. Bullet list preview
  Widget _buildBulletPreview() {
    final lines =
        note.body.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      return Text(
        'Empty bullet note',
        style: TextStyle(
          color: const Color(0xFF334155).withValues(alpha: 0.6),
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.take(6).map((line) {
        final cleanText = line.replaceFirst(RegExp(r'^[•\-\*]\s*'), '');
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ',
                  style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(
                  cleanText,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 12,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 3. Numbered list preview
  Widget _buildNumberedPreview() {
    final lines =
        note.body.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      return Text(
        'Empty numbered note',
        style: TextStyle(
          color: const Color(0xFF334155).withValues(alpha: 0.6),
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(min(lines.length, 6), (idx) {
        final cleanText =
            lines[idx].replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '');
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${idx + 1}. ',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Expanded(
                child: Text(
                  cleanText,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 12,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // 4. Free text preview
  Widget _buildFreeTextPreview() {
    return Text(
      note.body.isEmpty ? 'Tap to write memo...' : note.body,
      style: TextStyle(
        color: const Color(0xFF1E293B).withValues(alpha: 0.9),
        fontSize: 12.5,
        height: 1.4,
      ),
      maxLines: 7,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ─── Dialog Component with Tagging & Enhanced Formatting ────────────────────
class _NoteEditDialog extends StatefulWidget {
  final StickyNote note;
  final Function(StickyNote) onSave;
  final VoidCallback onDelete;
  final VoidCallback onCopy;

  const _NoteEditDialog({
    required this.note,
    required this.onSave,
    required this.onDelete,
    required this.onCopy,
  });

  @override
  State<_NoteEditDialog> createState() => _NoteEditDialogState();
}

class _NoteEditDialogState extends State<_NoteEditDialog> {
  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _newItemCtrl;
  late FocusNode _newItemFocus;
  late int _color;
  late bool _isPinned;
  late NoteFormat _format;
  late List<StickyItem> _items;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note.title);

    String initialBody = widget.note.body;
    if (widget.note.format == NoteFormat.numbered && initialBody.isEmpty) {
      initialBody = '1. ';
    } else if (widget.note.format == NoteFormat.bullet && initialBody.isEmpty) {
      initialBody = '• ';
    }

    _bodyCtrl = TextEditingController(text: initialBody);
    _newItemCtrl = TextEditingController();
    _newItemFocus = FocusNode();
    _color = widget.note.colorValue;
    _isPinned = widget.note.isPinned;
    _format = widget.note.format;
    _tags = List<String>.from(widget.note.tags);
    _items = widget.note.items
        .map((i) => StickyItem(id: i.id, text: i.text, isChecked: i.isChecked))
        .toList();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _newItemCtrl.dispose();
    _newItemFocus.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _newItemCtrl.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _items.add(StickyItem(text: text));
        _newItemCtrl.clear();
      });
      _newItemFocus.requestFocus();
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_tags.contains(tag)) {
        _tags.remove(tag);
      } else {
        _tags.add(tag);
      }
    });
  }

  void _switchFormat(NoteFormat newFormat) {
    if (_format == newFormat) return;

    setState(() {
      if (_format == NoteFormat.checklist) {
        if (_items.isNotEmpty) {
          if (newFormat == NoteFormat.numbered) {
            _bodyCtrl.text = _items
                .asMap()
                .entries
                .map((e) => '${e.key + 1}. ${e.value.text}')
                .join('\n');
          } else if (newFormat == NoteFormat.bullet) {
            _bodyCtrl.text = _items.map((i) => '• ${i.text}').join('\n');
          } else {
            _bodyCtrl.text = _items.map((i) => i.text).join('\n');
          }
        } else {
          if (newFormat == NoteFormat.numbered) {
            _bodyCtrl.text = '1. ';
          } else if (newFormat == NoteFormat.bullet) {
            _bodyCtrl.text = '• ';
          }
        }
      } else if (newFormat == NoteFormat.checklist) {
        if (_bodyCtrl.text.isNotEmpty) {
          final lines = _bodyCtrl.text
              .split('\n')
              .where((l) => l.trim().isNotEmpty)
              .map((l) =>
                  l.replaceFirst(RegExp(r'^([•\-\*]|\d+[\.\)])\s*'), ''))
              .toList();
          _items = lines.map((l) => StickyItem(text: l)).toList();
        }
      } else {
        final lines = _bodyCtrl.text
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .map((l) =>
                  l.replaceFirst(RegExp(r'^([•\-\*]|\d+[\.\)])\s*'), ''))
            .toList();

        if (newFormat == NoteFormat.numbered) {
          if (lines.isEmpty) {
            _bodyCtrl.text = '1. ';
          } else {
            _bodyCtrl.text = lines
                .asMap()
                .entries
                .map((e) => '${e.key + 1}. ${e.value}')
                .join('\n');
          }
        } else if (newFormat == NoteFormat.bullet) {
          if (lines.isEmpty) {
            _bodyCtrl.text = '• ';
          } else {
            _bodyCtrl.text = lines.map((l) => '• $l').join('\n');
          }
        } else {
          _bodyCtrl.text = lines.join('\n');
        }
      }

      _format = newFormat;
      _bodyCtrl.selection =
          TextSelection.collapsed(offset: _bodyCtrl.text.length);
    });
  }

  void _insertFormatting(String prefix) {
    if (prefix == '1.') {
      _switchFormat(NoteFormat.numbered);
      return;
    }
    if (prefix == '•') {
      _switchFormat(NoteFormat.bullet);
      return;
    }

    final text = _bodyCtrl.text;
    final selection = _bodyCtrl.selection;
    if (selection.isValid && selection.start >= 0) {
      final selectedText = text.substring(selection.start, selection.end);
      if (selectedText.isNotEmpty) {
        final formatted = selectedText
            .split('\n')
            .map((line) => line.trim().isEmpty ? line : '$prefix $line')
            .join('\n');
        final newText =
            text.replaceRange(selection.start, selection.end, formatted);
        _bodyCtrl.text = newText;
        _bodyCtrl.selection = TextSelection(
          baseOffset: selection.start,
          extentOffset: selection.start + formatted.length,
        );
        return;
      }
    }

    if (text.isEmpty || text.endsWith('\n')) {
      _bodyCtrl.text = '$text$prefix ';
    } else {
      _bodyCtrl.text = '$text\n$prefix ';
    }
    _bodyCtrl.selection =
        TextSelection.collapsed(offset: _bodyCtrl.text.length);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: context.themeCardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.themeTextPrimary.withValues(alpha: 0.08),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Top Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.note.title.isEmpty
                        ? 'New Sticky Note'
                        : 'Edit Sticky Note',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 18,
                        ),
                        color: context.themeTextSecondary,
                        onPressed: widget.onCopy,
                      ),
                      IconButton(
                        icon: Icon(
                          _isPinned
                              ? Icons.push_pin_rounded
                              : Icons.push_pin_outlined,
                          color: _isPinned
                              ? const Color(0xFFF08A82)
                              : context.themeTextSecondary,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _isPinned = !_isPinned),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: () {
                          widget.onDelete();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Format Switcher Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _formatTab('🔢 1, 2, 3 Numbered', NoteFormat.numbered),
                    _formatTab('⏺️ • Bullets', NoteFormat.bullet),
                    _formatTab('☑️ Checklist', NoteFormat.checklist),
                    _formatTab('📝 Free Text', NoteFormat.freeText),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Title input
              Container(
                decoration: BoxDecoration(
                  color: context.themeTextPrimary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _titleCtrl,
                  style: TextStyle(
                    color: context.themeTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Note Title',
                    hintStyle: TextStyle(
                      color: context.themeTextSecondary.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Content editor based on format
              if (_format == NoteFormat.checklist)
                _buildChecklistEditor()
              else
                _buildTextEditor(),

              const SizedBox(height: 14),

              // Tags Selector Row
              Text(
                'TAGS',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: context.themeTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: kDefaultTags.map((tag) {
                  final isSelected = _tags.contains(tag);
                  return InkWell(
                    onTap: () => _toggleTag(tag),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF08A82)
                            : context.themeTextPrimary
                                .withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFF08A82)
                              : context.themeTextPrimary
                                  .withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : context.themeTextPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Color Palette Selector
              Text(
                'STICKY COLOR',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: context.themeTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: kNoteColors.map((colorVal) {
                  final isSelected = _color == colorVal;
                  return GestureDetector(
                    onTap: () => setState(() => _color = colorVal),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Color(colorVal),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: const Color(0xFFF08A82), width: 2.5)
                            : Border.all(
                                color: Colors.black.withValues(alpha: 0.1)),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.black87)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: context.themeTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_format == NoteFormat.checklist &&
                          _newItemCtrl.text.trim().isNotEmpty) {
                        _items.add(StickyItem(text: _newItemCtrl.text.trim()));
                        _newItemCtrl.clear();
                      }

                      final updated = widget.note.copyWith(
                        title: _titleCtrl.text.trim(),
                        body: _bodyCtrl.text.trim(),
                        items: _items,
                        colorValue: _color,
                        isPinned: _isPinned,
                        format: _format,
                        tags: _tags,
                      );
                      widget.onSave(updated);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF08A82),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Save Sticky',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formatTab(String label, NoteFormat format) {
    final isSelected = _format == format;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => _switchFormat(format),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFF08A82)
                : context.themeTextPrimary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : context.themeTextPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: context.themeTextPrimary.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No checklist items yet. Add one below!',
                      style: TextStyle(
                        color: context.themeTextSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _items.length,
                  itemBuilder: (ctx, idx) {
                    final item = _items[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Checkbox(
                            value: item.isChecked,
                            activeColor: const Color(0xFF10B981),
                            onChanged: (val) {
                              setState(() => item.isChecked = val ?? false);
                            },
                          ),
                          Expanded(
                            child: TextFormField(
                              initialValue: item.text,
                              onChanged: (val) => item.text = val,
                              style: TextStyle(
                                color: context.themeTextPrimary,
                                fontSize: 13,
                                decoration: item.isChecked
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 16, color: Colors.redAccent),
                            onPressed: () {
                              setState(() => _items.removeAt(idx));
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: context.themeTextPrimary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _newItemCtrl,
                  focusNode: _newItemFocus,
                  onSubmitted: (_) => _addItem(),
                  style:
                      TextStyle(color: context.themeTextPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Add new item (press Enter)...',
                    hintStyle: TextStyle(
                      color: context.themeTextSecondary.withValues(alpha: 0.6),
                      fontSize: 12.5,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _addItem,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF08A82),
              ),
              icon:
                  const Icon(Icons.add_rounded, size: 18, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _toolButton('1. Number', () => _insertFormatting('1.')),
            const SizedBox(width: 6),
            _toolButton('• Bullet', () => _insertFormatting('•')),
            const SizedBox(width: 6),
            _toolButton('★ Star', () => _insertFormatting('★')),
            const SizedBox(width: 6),
            _toolButton('✓ Done', () => _insertFormatting('✓')),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.themeTextPrimary.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: TextField(
            controller: _bodyCtrl,
            maxLines: 7,
            inputFormatters: [
              AutoListTextInputFormatter(getFormat: () => _format),
            ],
            style: TextStyle(
              color: context.themeTextPrimary,
              fontSize: 13.5,
            ),
            decoration: InputDecoration(
              hintText: _format == NoteFormat.numbered
                  ? '1. First step\n(Press Enter for 2, 3...)'
                  : _format == NoteFormat.bullet
                      ? '• Bullet item one\n(Press Enter for next •)'
                      : 'Write your sticky notes here...',
              hintStyle: TextStyle(
                color: context.themeTextSecondary.withValues(alpha: 0.6),
                fontSize: 13,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _toolButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: context.themeTextPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: context.themeTextSecondary,
          ),
        ),
      ),
    );
  }
}