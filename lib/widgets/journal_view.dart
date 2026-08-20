import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Auto-continuation List Text Input Formatter
// ─────────────────────────────────────────────────────────────────────────────
class JournalAutoListTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Check if a newline was just inserted
    if (newValue.selection.isCollapsed &&
        newValue.selection.baseOffset > 0 &&
        newValue.text[newValue.selection.baseOffset - 1] == '\n') {
      final selectionLength =
          oldValue.selection.isValid && !oldValue.selection.isCollapsed
              ? (oldValue.selection.end - oldValue.selection.start)
              : 0;
      if (newValue.text.length != oldValue.text.length - selectionLength + 1) {
        return newValue;
      }

      final cursorOffset = newValue.selection.baseOffset;
      final textBeforeCursor = newValue.text.substring(0, cursorOffset - 1);
      final lines = textBeforeCursor.split('\n');
      final previousLine = lines.isNotEmpty ? lines.last : '';

      // 1. Numbered list: e.g. "1. Item" or "  1) Item"
      final numMatch =
          RegExp(r'^(\s*)(\d+)([\.\)])\s*(.*)$').firstMatch(previousLine);
      if (numMatch != null) {
        final indent = numMatch.group(1) ?? '';
        final num = int.tryParse(numMatch.group(2) ?? '1') ?? 1;
        final delim = numMatch.group(3) ?? '.';

        final nextPrefix = '$indent${num + 1}$delim ';
        final updatedText =
            newValue.text.replaceRange(cursorOffset, cursorOffset, nextPrefix);
        return TextEditingValue(
          text: updatedText,
          selection:
              TextSelection.collapsed(offset: cursorOffset + nextPrefix.length),
        );
      }

      // 2. Checkbox list: e.g. "[ ] Task" or "[x] Done"
      final checkMatch =
          RegExp(r'^(\s*)(\[\s*\]|\[x\])\s*(.*)$', caseSensitive: false)
              .firstMatch(previousLine);
      if (checkMatch != null) {
        final indent = checkMatch.group(1) ?? '';

        final nextPrefix = '$indent[ ] ';
        final updatedText =
            newValue.text.replaceRange(cursorOffset, cursorOffset, nextPrefix);
        return TextEditingValue(
          text: updatedText,
          selection:
              TextSelection.collapsed(offset: cursorOffset + nextPrefix.length),
        );
      }

      // 3. Bullet list: e.g. "• Item", "- Item", "* Item", "+ Item"
      final bulletMatch =
          RegExp(r'^(\s*)([•\-\*\+])\s*(.*)$').firstMatch(previousLine);
      if (bulletMatch != null) {
        final indent = bulletMatch.group(1) ?? '';
        final symbol = bulletMatch.group(2) ?? '•';

        final nextPrefix = '$indent$symbol ';
        final updatedText =
            newValue.text.replaceRange(cursorOffset, cursorOffset, nextPrefix);
        return TextEditingValue(
          text: updatedText,
          selection:
              TextSelection.collapsed(offset: cursorOffset + nextPrefix.length),
        );
      }
    }

    return newValue;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Text Editing Controller for Journal Question & Answer Styling
// ─────────────────────────────────────────────────────────────────────────────
class JournalTextEditingController extends TextEditingController {
  final BuildContext Function() contextGetter;

  JournalTextEditingController({
    super.text,
    required this.contextGetter,
  });

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = this.text;
    final ctx = contextGetter();
    final defaultStyle = style ??
        TextStyle(
          color: ctx.themeTextPrimary,
          fontSize: 15,
          height: 1.7,
        );
    final isDark = Theme.of(ctx).brightness == Brightness.dark;

    final headerStyle = defaultStyle.copyWith(
      fontWeight: FontWeight.w800,
      fontSize: 15.5,
      color: const Color(0xFFF08A82),
      letterSpacing: 0.5,
    );

    final questionStyle = defaultStyle.copyWith(
      fontWeight: FontWeight.w700,
      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
    );

    final bulletPrefixStyle = defaultStyle.copyWith(
      fontWeight: FontWeight.bold,
      color: const Color(0xFFF08A82),
    );

    final answerStyle = defaultStyle.copyWith(
      fontWeight: FontWeight.normal,
      color: ctx.themeTextPrimary,
    );

    final lines = text.split('\n');
    final spans = <InlineSpan>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isLast = i == lines.length - 1;
      final lineWithNewline = isLast ? line : '$line\n';

      final trimmed = line.trim();
      if (trimmed.startsWith('🌅') ||
          trimmed.startsWith('⚡') ||
          trimmed.startsWith('🌙') ||
          trimmed.startsWith('🌸') ||
          trimmed.startsWith('🚀') ||
          trimmed.startsWith('🌿') ||
          trimmed.startsWith('☀️') ||
          trimmed.startsWith('🏆') ||
          trimmed.startsWith('🎯') ||
          trimmed.startsWith('🔋') ||
          trimmed.startsWith('💡') ||
          trimmed.startsWith('📈') ||
          trimmed.startsWith('📅')) {
        spans.add(TextSpan(text: lineWithNewline, style: headerStyle));
      } else if (trimmed.startsWith('Q:') ||
          trimmed.startsWith('Q1:') ||
          trimmed.startsWith('Q2:') ||
          trimmed.startsWith('Q3:') ||
          trimmed.startsWith('Q4:') ||
          trimmed.startsWith('Q5:') ||
          trimmed.startsWith('Q6:') ||
          trimmed.startsWith('Q7:') ||
          trimmed.startsWith('Q8:') ||
          trimmed.startsWith('Q9:') ||
          RegExp(r'^Q\d+:').hasMatch(trimmed) ||
          RegExp(r'^\d+\.\s.*(\?|:)$').hasMatch(trimmed) ||
          (trimmed.endsWith('?') &&
              !trimmed.startsWith('•') &&
              !trimmed.startsWith('-') &&
              !trimmed.startsWith('*'))) {
        spans.add(TextSpan(text: lineWithNewline, style: questionStyle));
      } else if (trimmed.startsWith('• ') ||
          trimmed.startsWith('- ') ||
          trimmed.startsWith('* ') ||
          RegExp(r'^\d+[\.\)]\s').hasMatch(trimmed) ||
          trimmed.startsWith('[ ] ') ||
          trimmed.startsWith('[x] ')) {
        final prefixMatch =
            RegExp(r'^(\s*)([•\-\*]|\d+[\.\)]|\[\s*\]|\[x\])\s*')
                .firstMatch(line);
        if (prefixMatch != null) {
          final prefix = prefixMatch.group(0)!;
          final answer = line.substring(prefix.length);
          spans.add(TextSpan(text: prefix, style: bulletPrefixStyle));
          spans.add(TextSpan(
              text: isLast ? answer : '$answer\n', style: answerStyle));
        } else {
          spans.add(TextSpan(text: lineWithNewline, style: answerStyle));
        }
      } else {
        spans.add(TextSpan(text: lineWithNewline, style: answerStyle));
      }
    }

    return TextSpan(children: spans);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Journal Entry Model
// ─────────────────────────────────────────────────────────────────────────────
class JournalEntry {
  String id;
  String title;
  String content;
  String date;
  String mood;
  String templateType; // e.g. 'Daily', 'Gratitude', 'Productivity', 'Wellness', 'Ideas', 'Freeform'

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.mood = '😊',
    this.templateType = 'Daily',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'date': date,
        'mood': mood,
        'templateType': templateType,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        date: json['date'] ?? '',
        mood: json['mood'] ?? '😊',
        templateType: json['templateType'] ?? 'Daily',
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Journal Template Definition
// ─────────────────────────────────────────────────────────────────────────────
class JournalTemplate {
  final String id;
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final Color color;
  final String defaultContent;

  const JournalTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.color,
    required this.defaultContent,
  });
}

const List<JournalTemplate> kJournalTemplates = [
  JournalTemplate(
    id: 'daily_full',
    title: 'Daily Journal (Full Day)',
    category: 'Daily',
    description: 'All-in-one daily journal with morning intentions, daily gratitude, and evening reflection in one place.',
    icon: Icons.wb_twilight_rounded,
    color: Color(0xFFF08A82),
    defaultContent: '''🌅 MORNING INTENTIONS & GRATITUDE
Q: What are 3 things you are grateful for this morning?
• 
• 
• 

Q: What are your top 3 priority goals for today?
• 
• 
• 

Q: What is your positive affirmation or mindset for today?
• 


🌙 EVENING REVIEW & GRATITUDE
Q: What are 3 great things that happened today?
• 
• 
• 

Q: What moments of gratitude, joy, or kindness did you experience today?
• 
• 

Q: What did you learn today, or what could be improved?
• 

Q: What is your #1 focus and intention for tomorrow?
• 
''',
  ),
  JournalTemplate(
    id: 'morning_reflection',
    title: 'Morning Reflection',
    category: 'Daily',
    description: 'Set your intentions, gratitude, and top priorities for the day ahead.',
    icon: Icons.wb_sunny_rounded,
    color: Color(0xFFF59E0B),
    defaultContent: '''☀️ MORNING REFLECTION
Q: What are 3 things you are grateful for this morning?
• 

Q: What would make today great and meaningful?
• 

Q: What is your daily affirmation for today?
• 

Q: What is your #1 top priority today?
• 
''',
  ),
  JournalTemplate(
    id: 'evening_review',
    title: 'Evening Review',
    category: 'Daily',
    description: 'Reflect on your wins, key learnings, and unwind peacefully before sleep.',
    icon: Icons.nights_stay_rounded,
    color: Color(0xFF8B5CF6),
    defaultContent: '''🌙 EVENING REVIEW
Q: What are 3 amazing things that happened today?
• 

Q: What did you learn or discover today?
• 

Q: How could you have made today even better?
• 

Q: What is your #1 intention for tomorrow?
• 
''',
  ),
  JournalTemplate(
    id: 'gratitude_journal',
    title: '5-Min Gratitude',
    category: 'Gratitude',
    description: 'Cultivate deep positivity and appreciation for everyday moments.',
    icon: Icons.favorite_rounded,
    color: Color(0xFFF472B6),
    defaultContent: '''🌸 5-MIN GRATITUDE
Q: What is a small everyday joy you noticed today?
• 

Q: Who is someone you truly appreciate and why?
• 

Q: What is something about yourself you are proud of?
• 

Q: What comfort or opportunity are you thankful for?
• 
''',
  ),
  JournalTemplate(
    id: 'brain_dump',
    title: 'Brain Dump & Declutter',
    category: 'Freeform',
    description: 'Clear mental clutter, worries, thoughts, and stream of consciousness.',
    icon: Icons.psychology_rounded,
    color: Color(0xFF3B82F6),
    defaultContent: '''⚡ BRAIN DUMP & DECLUTTER
Q: What is on your mind right now? (unfiltered thoughts, worries, tasks, ideas)
• 
''',
  ),
  JournalTemplate(
    id: 'goal_checkin',
    title: 'Goal & Habit Check-in',
    category: 'Productivity',
    description: 'Track momentum, celebrate progress, and identify high-impact next steps.',
    icon: Icons.flag_rounded,
    color: Color(0xFF10B981),
    defaultContent: '''🚀 GOAL & HABIT CHECK-IN
Q: Which key goal or habit did you advance today?
• 

Q: What challenge or obstacle did you encounter & how did you handle it?
• 

Q: What is your #1 highest-leverage action step for tomorrow?
• 
''',
  ),
  JournalTemplate(
    id: 'self_care',
    title: 'Self-Care & Wellness',
    category: 'Wellness',
    description: 'Check in on your emotional health, energy levels, and personal boundaries.',
    icon: Icons.spa_rounded,
    color: Color(0xFF14B8A6),
    defaultContent: '''🌿 SELF-CARE & WELLNESS
Q: How would you rate your energy & mood today (1 to 10)?
• 

Q: What energized and revitalized you today?
• 

Q: What drained your mental or physical energy?
• 

Q: What is one kind thing you did (or will do) for yourself?
• 

Q: What do you need to let go of right now?
• 
''',
  ),
  JournalTemplate(
    id: 'creative_ideas',
    title: 'Creative Spark & Ideas',
    category: 'Ideas',
    description: 'Capture innovative thoughts, project concepts, and sparks of inspiration.',
    icon: Icons.lightbulb_rounded,
    color: Color(0xFFFBBF24),
    defaultContent: '''💡 CREATIVE SPARK & IDEAS
Q: What is the core idea or concept?
• 

Q: Why does this excite or inspire you?
• 

Q: How could you test or prototype this simply?
• 

Q: What are the key references or next steps?
• 
''',
  ),
  JournalTemplate(
    id: 'weekly_retro',
    title: 'Weekly Retrospective',
    category: 'Productivity',
    description: 'Review the past 7 days, distill key lessons, and align for next week.',
    icon: Icons.insights_rounded,
    color: Color(0xFF6366F1),
    defaultContent: '''📈 WEEKLY RETROSPECTIVE
Q: What were your biggest achievements & wins this week?
• 

Q: What didn't go as planned & what did you learn?
• 

Q: What were your major insights or personal breakthroughs?
• 

Q: What is your #1 priority focus for next week?
• 
''',
  ),
  JournalTemplate(
    id: 'freeform',
    title: 'Blank Freeform Journal',
    category: 'Freeform',
    description: 'A clean, open canvas for completely unstructured writing and notes.',
    icon: Icons.edit_note_rounded,
    color: Color(0xFFF08A82),
    defaultContent: '',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// JournalView
// ─────────────────────────────────────────────────────────────────────────────
class JournalView extends StatefulWidget {
  final List<JournalEntry> entries;
  final Function(List<JournalEntry>) onEntriesChanged;

  const JournalView({
    super.key,
    required this.entries,
    required this.onEntriesChanged,
  });

  @override
  State<JournalView> createState() => _JournalViewState();
}

class _JournalViewState extends State<JournalView> {
  String _selectedFilter = 'All'; // 'All', 'Daily', 'Gratitude', 'Productivity', 'Wellness', 'Ideas', 'Freeform'

  void _showTemplatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.themeCardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          String activeCategory = 'All';
          final modalCategories = [
            'All',
            'Daily',
            'Gratitude',
            'Productivity',
            'Wellness',
            'Ideas',
            'Freeform'
          ];

          return DraggableScrollableSheet(
            initialChildSize: 0.78,
            maxChildSize: 0.94,
            minChildSize: 0.50,
            expand: false,
            builder: (_, scrollController) => StatefulBuilder(
              builder: (context, setInnerState) {
                final filteredTemplates = activeCategory == 'All'
                    ? kJournalTemplates
                    : kJournalTemplates
                        .where((t) => t.category == activeCategory)
                        .toList();

                return Column(
                  children: [
                    // Sheet handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 14),
                      decoration: BoxDecoration(
                        color: context.themeTextPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Journal Template',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: context.themeTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Choose a template below to start writing',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pop(ctx);
                              _openEditor(
                                template: kJournalTemplates.firstWhere(
                                    (t) => t.id == 'freeform'),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: context.themeTextPrimary
                                    .withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Blank Page',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF08A82),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter category bar inside modal
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: modalCategories.map((c) {
                          final isSel = activeCategory == c;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () =>
                                  setInnerState(() => activeCategory = c),
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? const Color(0xFFF08A82)
                                      : context.themeTextPrimary
                                          .withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  c,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSel
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSel
                                        ? Colors.white
                                        : context.themeTextPrimary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Template list
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        itemCount: filteredTemplates.length,
                        itemBuilder: (context, index) {
                          final tmpl = filteredTemplates[index];
                          final isDailyFull = tmpl.id == 'daily_full';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isDailyFull
                                  ? const Color(0xFFF08A82).withValues(alpha: 0.05)
                                  : context.themeTextPrimary.withValues(alpha: 0.025),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDailyFull
                                    ? const Color(0xFFF08A82).withValues(alpha: 0.35)
                                    : context.themeTextPrimary.withValues(alpha: 0.06),
                                width: isDailyFull ? 1.5 : 1.0,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _openEditor(template: tmpl);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: tmpl.color
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(tmpl.icon,
                                            color: tmpl.color, size: 22),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    tmpl.title,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: context
                                                          .themeTextPrimary,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: tmpl.color
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    tmpl.category,
                                                    style: TextStyle(
                                                      color: tmpl.color,
                                                      fontSize: 9.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                if (isDailyFull) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF08A82),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.star_rounded,
                                                            size: 10, color: Colors.white),
                                                        SizedBox(width: 2),
                                                        Text(
                                                          'All-in-One Daily',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.w800,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              tmpl.description,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color:
                                                    context.themeTextSecondary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: context.themeTextSecondary
                                            .withValues(alpha: 0.6),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openEditor({JournalEntry? entry, JournalTemplate? template}) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, a, __) => JournalEditor(
        entry: entry,
        initialTemplate: template,
        onSave: (newEntry) {
          if (entry == null) {
            widget.onEntriesChanged([newEntry, ...widget.entries]);
          } else {
            final updated = List<JournalEntry>.from(widget.entries);
            final i = updated.indexWhere((e) => e.id == entry.id);
            if (i != -1) {
              updated[i] = newEntry;
              widget.onEntriesChanged(updated);
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

  void _deleteEntry(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.themeCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Entry',
          style: TextStyle(
            color: context.themeTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this journal entry?',
          style: TextStyle(color: context.themeTextSecondary),
        ),
        actions: [
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
          TextButton(
            onPressed: () {
              widget.onEntriesChanged(
                List<JournalEntry>.from(widget.entries)
                  ..removeWhere((e) => e.id == id),
              );
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<JournalEntry> get _filteredEntries {
    if (_selectedFilter == 'All') return widget.entries;
    return widget.entries.where((e) {
      if (_selectedFilter == 'Daily') {
        return e.templateType == 'Daily' ||
            e.title.toLowerCase().contains('daily') ||
            e.title.toLowerCase().contains('morning') ||
            e.title.toLowerCase().contains('evening');
      }
      return e.templateType == _selectedFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final filtered = _filteredEntries;

    final categories = [
      'All',
      'Daily',
      'Gratitude',
      'Productivity',
      'Wellness',
      'Ideas',
      'Freeform'
    ];

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
                            'Daily ',
                            style: TextStyle(
                              color: context.themeTextPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Text(
                            'Journal',
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
                        'Reflect on your days with guided templates & moods',
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
                  onTap: _showTemplatePicker,
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
                          'New Entry',
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

            // ─── Summary Pulse Card (Fixed) ───
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
                            Icons.auto_stories_outlined,
                            size: 16,
                            color: Color(0xFFF08A82),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'JOURNAL PULSE',
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
                        '${widget.entries.length} Total Entries',
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
                            color:
                                context.themeTextPrimary.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.themeTextPrimary
                                  .withValues(alpha: 0.04),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.edit_calendar_rounded,
                                  size: 18, color: Color(0xFF93C5FD)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${widget.entries.length}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: context.themeTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Reflections',
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
                            color:
                                context.themeTextPrimary.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.themeTextPrimary
                                  .withValues(alpha: 0.04),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                widget.entries.isNotEmpty
                                    ? widget.entries.first.mood
                                    : '✨',
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.entries.isNotEmpty
                                          ? widget.entries.first.mood
                                          : '✨',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Latest Mood',
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

            // ─── Filter Chips (Fixed) ───
            const SizedBox(height: 14),

            // ─── Filter Category Chips ───
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedFilter == cat;
                  final count = cat == 'All'
                      ? widget.entries.length
                      : cat == 'Daily'
                          ? widget.entries
                              .where((e) =>
                                  e.templateType == 'Daily' ||
                                  e.title.toLowerCase().contains('daily') ||
                                  e.title.toLowerCase().contains('morning') ||
                                  e.title.toLowerCase().contains('evening'))
                              .length
                          : widget.entries
                              .where((e) => e.templateType == cat)
                              .length;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF08A82)
                            : context.themeCardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFF08A82)
                              : context.themeTextPrimary
                                  .withValues(alpha: 0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : context.themeTextPrimary,
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : context.themeTextPrimary
                                        .withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : context.themeTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // ─── Scrollable Entries List ───
            Expanded(
              child: filtered.isEmpty
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: context.themeCardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: context.themeTextPrimary
                                .withValues(alpha: 0.05),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.auto_stories_outlined,
                              size: 36,
                              color: const Color(0xFFF08A82)
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No Journal Entries in This View',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: context.themeTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Choose from guided templates or start freeform writing.',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.themeTextSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: _showTemplatePicker,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Choose Template & Write',
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
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final entry = filtered[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: context.themeCardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: context.themeTextPrimary
                                  .withValues(alpha: 0.05),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _openEditor(entry: entry),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: context.themeTextPrimary
                                            .withValues(alpha: 0.04),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(entry.mood,
                                          style:
                                              const TextStyle(fontSize: 20)),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  entry.title.isEmpty
                                                      ? 'Untitled Entry'
                                                      : entry.title,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: context
                                                        .themeTextPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow
                                                      .ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                entry.date,
                                                style: TextStyle(
                                                  color: context
                                                      .themeTextSecondary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF08A82)
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              entry.templateType,
                                              style: const TextStyle(
                                                color: Color(0xFFF08A82),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (entry
                                              .content.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              entry.content
                                                  .replaceAll('\n', ' '),
                                              style: TextStyle(
                                                color: context
                                                    .themeTextSecondary,
                                                fontSize: 12,
                                              ),
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: Colors.redAccent
                                            .withValues(alpha: 0.6),
                                      ),
                                      onPressed: () =>
                                          _deleteEntry(entry.id),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// JournalEditor with Template Chooser & Mood Selection
// ─────────────────────────────────────────────────────────────────────────────
class JournalEditor extends StatefulWidget {
  final JournalEntry? entry;
  final JournalTemplate? initialTemplate;
  final Function(JournalEntry) onSave;

  const JournalEditor({
    super.key,
    this.entry,
    this.initialTemplate,
    required this.onSave,
  });

  @override
  State<JournalEditor> createState() => _JournalEditorState();
}

class _JournalEditorState extends State<JournalEditor> {
  late TextEditingController _titleCtrl;
  late JournalTextEditingController _contentCtrl;
  String _mood = '😊';
  String _templateType = 'Daily';

  final List<Map<String, String>> _moods = [
    {'emoji': '😊', 'label': 'Happy'},
    {'emoji': '😌', 'label': 'Peaceful'},
    {'emoji': '💪', 'label': 'Energized'},
    {'emoji': '🔥', 'label': 'Inspired'},
    {'emoji': '🤩', 'label': 'Excited'},
    {'emoji': '😐', 'label': 'Neutral'},
    {'emoji': '😔', 'label': 'Low'},
    {'emoji': '😡', 'label': 'Frustrated'},
  ];

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (widget.entry != null) {
      _titleCtrl = TextEditingController(text: widget.entry!.title);
      _contentCtrl = JournalTextEditingController(
        text: widget.entry!.content,
        contextGetter: () => context,
      );
      _mood = widget.entry!.mood;
      _templateType = widget.entry!.templateType;
    } else if (widget.initialTemplate != null) {
      final tmpl = widget.initialTemplate!;
      _titleCtrl = TextEditingController(
        text: tmpl.id == 'daily_full'
            ? 'Daily Journal - ${_formatDate(now)}'
            : tmpl.title,
      );
      _contentCtrl = JournalTextEditingController(
        text: tmpl.defaultContent,
        contextGetter: () => context,
      );
      _templateType = tmpl.category;
    } else {
      final defaultTmpl = kJournalTemplates.first;
      _titleCtrl = TextEditingController(
        text: 'Daily Journal - ${_formatDate(now)}',
      );
      _contentCtrl = JournalTextEditingController(
        text: defaultTmpl.defaultContent,
        contextGetter: () => context,
      );
      _templateType = defaultTmpl.category;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _applyTemplate(JournalTemplate template) {
    setState(() {
      final now = DateTime.now();
      _titleCtrl.text = template.id == 'daily_full'
          ? 'Daily Journal - ${_formatDate(now)}'
          : template.title;
      _contentCtrl.text = template.defaultContent;
      _templateType = template.category;
    });
  }

  void _showTemplatesModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.themeCardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.68,
        maxChildSize: 0.90,
        minChildSize: 0.40,
        expand: false,
        builder: (_, sc) => ListView(
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Switch Template',
              style: TextStyle(
                color: context.themeTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            ...kJournalTemplates.map((t) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: context.themeTextPrimary.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: context.themeTextPrimary.withValues(alpha: 0.06),
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: t.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(t.icon, color: t.color, size: 20),
                    ),
                    title: Text(
                      t.title,
                      style: TextStyle(
                        color: context.themeTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      t.description,
                      style: TextStyle(
                        color: context.themeTextSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                    trailing:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      Navigator.pop(ctx);
                      _applyTemplate(t);
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _saveEntry() {
    final now = DateTime.now();
    final entry = JournalEntry(
      id: widget.entry?.id ?? now.millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim().isEmpty
          ? 'Untitled Entry'
          : _titleCtrl.text.trim(),
      content: _contentCtrl.text,
      date: widget.entry?.date ?? '${now.day}/${now.month}/${now.year}',
      mood: _mood,
      templateType: _templateType,
    );
    widget.onSave(entry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final wordCount = _contentCtrl.text.trim().isEmpty
        ? 0
        : _contentCtrl.text.trim().split(RegExp(r'\s+')).length;
    final charCount = _contentCtrl.text.length;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (_titleCtrl.text.trim().isNotEmpty ||
            _contentCtrl.text.trim().isNotEmpty) {
          final now = DateTime.now();
          widget.onSave(JournalEntry(
            id: widget.entry?.id ?? now.millisecondsSinceEpoch.toString(),
            title: _titleCtrl.text.trim().isEmpty
                ? 'Untitled Entry'
                : _titleCtrl.text.trim(),
            content: _contentCtrl.text,
            date: widget.entry?.date ?? '${now.day}/${now.month}/${now.year}',
            mood: _mood,
            templateType: _templateType,
          ));
        }
      },
      child: Scaffold(
        backgroundColor: context.themeBackground,
        appBar: AppBar(
          backgroundColor: context.themeBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 56,
          title: Text(
            widget.entry == null ? 'New Journal Entry' : 'Edit Journal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.themeTextPrimary,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: context.themeTextPrimary, size: 18),
            onPressed: () {
              if (_titleCtrl.text.trim().isNotEmpty ||
                  _contentCtrl.text.trim().isNotEmpty) {
                final now = DateTime.now();
                widget.onSave(JournalEntry(
                  id: widget.entry?.id ??
                      now.millisecondsSinceEpoch.toString(),
                  title: _titleCtrl.text.trim().isEmpty
                      ? 'Untitled Entry'
                      : _titleCtrl.text.trim(),
                  content: _contentCtrl.text,
                  date: widget.entry?.date ??
                      '${now.day}/${now.month}/${now.year}',
                  mood: _mood,
                  templateType: _templateType,
                ));
              }
              Navigator.pop(context);
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
              child: ElevatedButton(
                onPressed: _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF08A82),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text('Save',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(
              color: context.themeTextPrimary.withValues(alpha: 0.05),
              height: 1,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Template Selector Bar ───
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF08A82)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_stories_rounded,
                                  size: 13, color: Color(0xFFF08A82)),
                              const SizedBox(width: 4),
                              Text(
                                'Template: $_templateType',
                                style: const TextStyle(
                                  color: Color(0xFFF08A82),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _showTemplatesModal,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.themeTextPrimary
                                  .withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: context.themeTextPrimary
                                    .withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.tune_rounded,
                                    size: 12,
                                    color: context.themeTextSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  'Change Template',
                                  style: TextStyle(
                                    color: context.themeTextPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ─── Mood Selector ───
                    Text(
                      'HOW ARE YOU FEELING?',
                      style: TextStyle(
                        color: context.themeTextSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _moods.map((m) {
                          final isSel = _mood == m['emoji'];
                          return GestureDetector(
                            onTap: () => setState(() => _mood = m['emoji']!),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? const Color(0xFFF08A82)
                                        .withValues(alpha: 0.15)
                                    : context.themeTextPrimary
                                        .withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel
                                      ? const Color(0xFFF08A82)
                                      : context.themeTextPrimary
                                          .withValues(alpha: 0.06),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(m['emoji']!,
                                      style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 5),
                                  Text(
                                    m['label']!,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: isSel
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSel
                                          ? const Color(0xFFF08A82)
                                          : context.themeTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── Title Input ───
                    TextField(
                      controller: _titleCtrl,
                      style: TextStyle(
                        color: context.themeTextPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Entry Title…',
                        hintStyle: TextStyle(
                          color: context.themeTextSecondary
                              .withValues(alpha: 0.4),
                          fontWeight: FontWeight.w600,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // ─── Content Input with Auto-List Continuation ───
                    TextField(
                      controller: _contentCtrl,
                      maxLines: null,
                      inputFormatters: [JournalAutoListTextInputFormatter()],
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(
                        color: context.themeTextPrimary,
                        fontSize: 15,
                        height: 1.7,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Write your thoughts, daily reflections or notes…\n(Press Enter on a bullet point to automatically create the next point)',
                        hintStyle: TextStyle(
                          color: context.themeTextSecondary
                              .withValues(alpha: 0.4),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Bottom Status Bar ───
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: context.themeCardBackground,
                border: Border(
                  top: BorderSide(
                    color: context.themeTextPrimary.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(_mood, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          _templateType,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$wordCount words · $charCount chars',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.themeTextSecondary
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
