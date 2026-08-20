import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../services/notification_service.dart';

// ─── TASK MODELS ─────────────────────────────────────────────────────────────
class SubTask {
  String id;
  String title;
  bool isCompleted;

  SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
      };

  factory SubTask.fromJson(Map<String, dynamic> json) => SubTask(
        id: json['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: json['title']?.toString() ?? '',
        isCompleted: json['isCompleted'] == true,
      );
}

class Task {
  String id;
  String title;
  String? description;
  String category;
  String priority;
  String dueDate;
  String? dueTime;
  int durationMinutes; // 0 for untimed / check-in, or >0 for timed tasks (e.g. 15, 30, 45, 60 min)
  String recurrence; // 'Once', 'Daily', 'Weekly', 'Monthly'
  List<String> selectedWeekDays; // ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
  bool isCompleted;
  int streak;
  String? lastCompletedDate;
  List<SubTask> subTasks;

  bool get hasDuration => durationMinutes > 0;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.category = 'General',
    required this.priority,
    required this.dueDate,
    this.dueTime,
    this.durationMinutes = 0,
    this.recurrence = 'Once',
    List<String>? selectedWeekDays,
    this.isCompleted = false,
    this.streak = 0,
    this.lastCompletedDate,
    List<SubTask>? subTasks,
  })  : selectedWeekDays = selectedWeekDays ?? [],
        subTasks = subTasks ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
        'dueDate': dueDate,
        'dueTime': dueTime,
        'durationMinutes': durationMinutes,
        'recurrence': recurrence,
        'selectedWeekDays': selectedWeekDays,
        'isCompleted': isCompleted,
        'streak': streak,
        'lastCompletedDate': lastCompletedDate,
        'subTasks': subTasks.map((s) => s.toJson()).toList(),
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    var rawSubtasks = json['subTasks'];
    List<SubTask> parsedSubtasks = [];
    if (rawSubtasks is List) {
      parsedSubtasks = rawSubtasks
          .map((s) => s is Map<String, dynamic> ? SubTask.fromJson(s) : null)
          .whereType<SubTask>()
          .toList();
    }

    var rawDays = json['selectedWeekDays'];
    List<String> parsedDays = [];
    if (rawDays is List) {
      parsedDays = rawDays.map((d) => d.toString()).toList();
    }

    return Task(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      category: json['category']?.toString() ?? 'General',
      priority: json['priority']?.toString() ?? 'Medium',
      dueDate: json['dueDate']?.toString() ??
          DateFormat('yyyy-MM-dd').format(DateTime.now()),
      dueTime: json['dueTime']?.toString(),
      durationMinutes:
          (json['durationMinutes'] is int) ? json['durationMinutes'] : 0,
      recurrence: json['recurrence']?.toString() ?? 'Once',
      selectedWeekDays: parsedDays,
      isCompleted: json['isCompleted'] == true,
      streak: (json['streak'] is int) ? json['streak'] : 0,
      lastCompletedDate: json['lastCompletedDate']?.toString(),
      subTasks: parsedSubtasks,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? priority,
    String? dueDate,
    String? dueTime,
    int? durationMinutes,
    String? recurrence,
    List<String>? selectedWeekDays,
    bool? isCompleted,
    int? streak,
    String? lastCompletedDate,
    List<SubTask>? subTasks,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      recurrence: recurrence ?? this.recurrence,
      selectedWeekDays: selectedWeekDays ?? this.selectedWeekDays,
      isCompleted: isCompleted ?? this.isCompleted,
      streak: streak ?? this.streak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      subTasks: subTasks ?? this.subTasks,
    );
  }

  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    if (dueDate.compareTo(todayStr) < 0) return true;
    if (dueDate == todayStr && dueTime != null && dueTime!.contains(':')) {
      final parts = dueTime!.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final dueDateTime =
          DateTime(now.year, now.month, now.day, hour, minute);
      return now.isAfter(dueDateTime);
    }
    return false;
  }

  int get subTaskCompleted => subTasks.where((s) => s.isCompleted).length;

  DateTime get dueDateTime {
    final dateParts = dueDate.split('-');
    final year = int.tryParse(dateParts[0]) ?? DateTime.now().year;
    final month = int.tryParse(dateParts[1]) ?? DateTime.now().month;
    final day = int.tryParse(dateParts[2]) ?? DateTime.now().day;

    int hour = 9;
    int minute = 0;
    if (dueTime != null && dueTime!.contains(':')) {
      final timeParts = dueTime!.split(':');
      hour = int.tryParse(timeParts[0]) ?? 9;
      minute = int.tryParse(timeParts[1]) ?? 0;
    }

    return DateTime(year, month, day, hour, minute);
  }
}

// ─── TASK MANAGER VIEW ───────────────────────────────────────────────────────
class TaskManager extends StatefulWidget {
  final List<Task> tasks;
  final Function(List<Task>) onTasksChanged;

  const TaskManager({
    super.key,
    required this.tasks,
    required this.onTasksChanged,
  });

  @override
  State<TaskManager> createState() => _TaskManagerState();
}

class _TaskManagerState extends State<TaskManager> {
  String _selectedFilter = 'Today';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    NotificationService().init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _todayStr() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  int _getNotificationId(String taskId) {
    try {
      return int.parse(taskId.substring(taskId.length - 6)) % 9999;
    } catch (_) {
      return taskId.hashCode.abs() % 9999;
    }
  }

  void _scheduleRemindersForTask(Task task) {
    if (task.isCompleted) return;
    NotificationService().scheduleTaskReminders(
      baseId: _getNotificationId(task.id),
      taskTitle: task.title,
      dueDate: task.dueDateTime,
      durationMinutes: task.durationMinutes,
    );
  }

  void _cancelRemindersForTask(Task task) {
    NotificationService().cancelTaskNotifications(_getNotificationId(task.id));
  }

  void _toggleTaskCompletion(Task task) {
    final nowStr = _todayStr();
    final willComplete = !task.isCompleted;

    if (willComplete) {
      _cancelRemindersForTask(task);

      // If recurring task: advance to next cycle
      if (task.recurrence != 'Once') {
        final currentDue = task.dueDateTime;
        DateTime nextDue;
        if (task.recurrence == 'Daily') {
          nextDue = currentDue.add(const Duration(days: 1));
        } else if (task.recurrence == 'Weekly') {
          nextDue = currentDue.add(const Duration(days: 7));
        } else {
          // Monthly
          nextDue = DateTime(
              currentDue.year, currentDue.month + 1, currentDue.day, currentDue.hour, currentDue.minute);
        }

        final nextDueStr = DateFormat('yyyy-MM-dd').format(nextDue);
        final updatedSubtasks = task.subTasks
            .map((s) => SubTask(id: s.id, title: s.title, isCompleted: false))
            .toList();

        final updatedTask = Task(
          id: task.id,
          title: task.title,
          description: task.description,
          category: task.category,
          priority: task.priority,
          dueDate: nextDueStr,
          dueTime: task.dueTime,
          recurrence: task.recurrence,
          selectedWeekDays: task.selectedWeekDays,
          isCompleted: false,
          streak: task.streak + 1,
          lastCompletedDate: nowStr,
          subTasks: updatedSubtasks,
        );

        _scheduleRemindersForTask(updatedTask);

        final newList = widget.tasks
            .map((t) => t.id == task.id ? updatedTask : t)
            .toList();
        widget.onTasksChanged(newList);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '🎉 Task completed! Streak: ${updatedTask.streak} • Next due: $nextDueStr'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    final updated = Task(
      id: task.id,
      title: task.title,
      description: task.description,
      category: task.category,
      priority: task.priority,
      dueDate: task.dueDate,
      dueTime: task.dueTime,
      recurrence: task.recurrence,
      selectedWeekDays: task.selectedWeekDays,
      isCompleted: willComplete,
      streak: willComplete ? task.streak + 1 : task.streak,
      lastCompletedDate: willComplete ? nowStr : task.lastCompletedDate,
      subTasks: task.subTasks,
    );

    if (!willComplete) {
      _scheduleRemindersForTask(updated);
    }

    final newList =
        widget.tasks.map((t) => t.id == task.id ? updated : t).toList();
    widget.onTasksChanged(newList);
  }

  void _toggleSubTask(Task task, String subTaskId) {
    final updatedSubtasks = task.subTasks.map((s) {
      if (s.id == subTaskId) {
        return SubTask(id: s.id, title: s.title, isCompleted: !s.isCompleted);
      }
      return s;
    }).toList();

    final updated = Task(
      id: task.id,
      title: task.title,
      description: task.description,
      category: task.category,
      priority: task.priority,
      dueDate: task.dueDate,
      dueTime: task.dueTime,
      recurrence: task.recurrence,
      selectedWeekDays: task.selectedWeekDays,
      isCompleted: task.isCompleted,
      streak: task.streak,
      lastCompletedDate: task.lastCompletedDate,
      subTasks: updatedSubtasks,
    );

    final newList =
        widget.tasks.map((t) => t.id == task.id ? updated : t).toList();
    widget.onTasksChanged(newList);
  }

  void _deleteTask(Task task) {
    _cancelRemindersForTask(task);
    final newList = widget.tasks.where((t) => t.id != task.id).toList();
    widget.onTasksChanged(newList);
  }

  List<Task> get _filteredTasks {
    final query = _searchQuery.toLowerCase().trim();
    final today = _todayStr();

    return widget.tasks.where((t) {
      // 1. Text search
      final matchesSearch = query.isEmpty ||
          t.title.toLowerCase().contains(query) ||
          (t.description?.toLowerCase().contains(query) ?? false) ||
          t.subTasks.any((s) => s.title.toLowerCase().contains(query));

      if (!matchesSearch) return false;

      // 2. Filter selection
      switch (_selectedFilter) {
        case 'Today':
          return t.dueDate == today && !t.isCompleted;
        case 'Upcoming':
          return t.dueDate.compareTo(today) > 0 && !t.isCompleted;
        case 'Recurring':
          return t.recurrence != 'Once' && !t.isCompleted;
        case 'Subtasks':
          return t.subTasks.isNotEmpty && !t.isCompleted;
        case 'Completed':
          return t.isCompleted;
        case 'Overdue':
          return t.isOverdue;
        default:
          return true;
      }
    }).toList()
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        return a.dueDate.compareTo(b.dueDate);
      });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final today = _todayStr();
    final todayTasks = widget.tasks.where((t) => t.dueDate == today).toList();
    final completedCount = widget.tasks.where((t) => t.isCompleted).length;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 18 : 36,
        16,
        isMobile ? 18 : 36,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Header (Fixed) ──
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
                          'Task ',
                          style: TextStyle(
                            color: context.themeTextPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Text(
                          'Manager',
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
                      'Automated reminder countdowns, subtasks & goals',
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
                onTap: () => _showTaskDialog(null),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
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
                        'New Task',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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

          // ── Task Overview Card (Fixed) ──
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
                          Icons.dashboard_outlined,
                          size: 16,
                          color: Color(0xFFF08A82),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'TASK OVERVIEW',
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
                      '${widget.tasks.length} Total Tasks',
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
                            const Icon(Icons.today_rounded,
                                size: 18, color: Color(0xFF93C5FD)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${todayTasks.where((t) => !t.isCompleted).length}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: context.themeTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Today Pending',
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
                            const Icon(Icons.check_circle_rounded,
                                size: 18, color: Color(0xFF86EFAC)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$completedCount',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: context.themeTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Completed',
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
                            const Icon(Icons.repeat_rounded,
                                size: 18, color: Color(0xFFFDE047)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.tasks.where((t) => t.recurrence != 'Once').length}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: context.themeTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Recurring',
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

          // ── Search Bar (Fixed) ──
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
              style: TextStyle(color: context.themeTextPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search tasks, subtasks & categories...',
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

          // ── Filter Chips (Fixed) ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip('Today', 'Today'),
                _buildFilterChip('Upcoming', 'Upcoming'),
                _buildFilterChip('🔁 Recurring', 'Recurring'),
                _buildFilterChip('📋 With Subtasks', 'Subtasks'),
                _buildFilterChip('⚠️ Overdue', 'Overdue'),
                _buildFilterChip('✅ Completed', 'Completed'),
                _buildFilterChip('All Tasks', 'All'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Scrollable Task List ──
          Expanded(
            child: _filteredTasks.isEmpty
                ? SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildEmptyState(),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: _filteredTasks.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final task = _filteredTasks[idx];
                      return _TaskCard(
                        task: task,
                        onToggle: () => _toggleTaskCompletion(task),
                        onToggleSubTask: (subId) =>
                            _toggleSubTask(task, subId),
                        onEdit: () => _showTaskDialog(task),
                        onDelete: () => _deleteTask(task),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = value),
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

  Widget _buildEmptyState() => Container(
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
              Icons.task_alt_rounded,
              size: 36,
              color: const Color(0xFFF08A82).withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'No Tasks Found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: context.themeTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "New Task" above to add goals with automatic reminders.',
              style: TextStyle(
                fontSize: 12,
                color: context.themeTextSecondary,
              ),
            ),
          ],
        ),
      );

  void _showTaskDialog(Task? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TaskEditDialog(
        task: existing,
        onSave: (saved) {
          final isNew = existing == null;
          List<Task> updatedList;
          if (isNew) {
            updatedList = [saved, ...widget.tasks];
          } else {
            updatedList = widget.tasks
                .map((t) => t.id == saved.id ? saved : t)
                .toList();
          }

          _scheduleRemindersForTask(saved);
          widget.onTasksChanged(updatedList);
        },
      ),
    );
  }
}

// ─── TASK CARD WIDGET ────────────────────────────────────────────────────────
class _TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onToggle;
  final Function(String) onToggleSubTask;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onToggleSubTask,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool _isExpanded = false;

  Color _getPriorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'urgent':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final priorityColor = _getPriorityColor(t.priority);
    final hasSubtasks = t.subTasks.isNotEmpty;
    final completedSubs = t.subTaskCompleted;

    return Container(
      decoration: BoxDecoration(
        color: context.themeCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: t.isCompleted
              ? Colors.transparent
              : t.isOverdue
                  ? Colors.redAccent.withValues(alpha: 0.3)
                  : context.themeTextPrimary.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          // Main task row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Completion Checkbox
                GestureDetector(
                  onTap: widget.onToggle,
                  child: Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: t.isCompleted
                          ? const Color(0xFF10B981)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: t.isCompleted
                            ? const Color(0xFF10B981)
                            : context.themeTextSecondary
                                .withValues(alpha: 0.4),
                        width: 1.8,
                      ),
                    ),
                    child: t.isCompleted
                        ? const Icon(Icons.check,
                            size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Title, Description, Subtasks Progress, Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.title,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: t.isCompleted
                                    ? context.themeTextSecondary
                                    : context.themeTextPrimary,
                                decoration: t.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          // Priority badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              t.priority.toUpperCase(),
                              style: TextStyle(
                                color: priorityColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (t.description != null &&
                          t.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          t.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.themeTextSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Meta tags & schedule info
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Due date badge
                          _buildTag(
                            icon: Icons.calendar_today_rounded,
                            label: t.dueDate,
                            color: t.isOverdue
                                ? Colors.redAccent
                                : const Color(0xFF93C5FD),
                          ),

                          // Due time badge
                          if (t.dueTime != null && t.dueTime!.isNotEmpty)
                            _buildTag(
                              icon: Icons.access_time_rounded,
                              label: t.dueTime!,
                              color: const Color(0xFFFDE047),
                            ),

                          // Recurrence badge
                          if (t.recurrence != 'Once')
                            _buildTag(
                              icon: Icons.repeat_rounded,
                              label: t.recurrence == 'Weekly' &&
                                      t.selectedWeekDays.isNotEmpty
                                  ? 'Weekly (${t.selectedWeekDays.join(", ")})'
                                  : t.recurrence,
                              color: const Color(0xFFC4B5FD),
                            ),

                          // Category
                          if (t.category != 'General')
                            _buildTag(
                              icon: Icons.label_outline_rounded,
                              label: t.category,
                              color: context.themeTextSecondary,
                            ),

                          // Auto notification status badge
                          _buildTag(
                            icon: Icons.notifications_active_outlined,
                            label: 'Auto Alert',
                            color: const Color(0xFFF08A82),
                          ),
                        ],
                      ),

                      // Subtasks progress summary bar
                      if (hasSubtasks) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () =>
                              setState(() => _isExpanded = !_isExpanded),
                          child: Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: t.subTasks.isEmpty
                                        ? 0
                                        : completedSubs / t.subTasks.length,
                                    backgroundColor: context.themeTextPrimary
                                        .withValues(alpha: 0.08),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Color(0xFF10B981)),
                                    minHeight: 4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$completedSubs/${t.subTasks.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                              Icon(
                                _isExpanded
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                size: 18,
                                color: context.themeTextSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Popup menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      size: 18, color: context.themeTextSecondary),
                  padding: EdgeInsets.zero,
                  color: context.themeCardBackground,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'edit') widget.onEdit();
                    if (val == 'delete') widget.onDelete();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Edit Task'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 16, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text('Delete Task',
                              style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Expandable Subtasks List
          if (hasSubtasks && _isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(46, 0, 14, 12),
              child: Column(
                children: t.subTasks.map((sub) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => widget.onToggleSubTask(sub.id),
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: sub.isCompleted
                                  ? const Color(0xFF10B981)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: sub.isCompleted
                                    ? const Color(0xFF10B981)
                                    : context.themeTextSecondary
                                        .withValues(alpha: 0.4),
                                width: 1.4,
                              ),
                            ),
                            child: sub.isCompleted
                                ? const Icon(Icons.check,
                                    size: 10, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sub.title,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: sub.isCompleted
                                  ? context.themeTextSecondary
                                  : context.themeTextPrimary,
                              decoration: sub.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PROFESSIONAL TASK EDIT / CREATE MODAL ────────────────────────────────────
class _TaskEditDialog extends StatefulWidget {
  final Task? task;
  final Function(Task) onSave;

  const _TaskEditDialog({
    this.task,
    required this.onSave,
  });

  @override
  State<_TaskEditDialog> createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<_TaskEditDialog> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _newSubtaskCtrl;
  late String _dueDate;
  String? _dueTime;
  late String _priority;
  late String _category;
  late String _recurrence;
  late List<String> _selectedWeekDays;
  late List<SubTask> _subtasks;

  static const List<String> _priorities = ['Low', 'Medium', 'High', 'Urgent'];
  static const List<String> _categories = [
    'General',
    'Personal',
    'Work',
    'Study',
    'Health',
    'Finance'
  ];
  static const List<String> _recurrences = [
    'Once',
    'Daily',
    'Weekly',
    'Monthly'
  ];

  static const List<String> _allWeekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _newSubtaskCtrl = TextEditingController();
    _dueDate = t?.dueDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    _dueTime = t?.dueTime ?? '10:00';
    _priority = t?.priority ?? 'Medium';
    _category = t?.category ?? 'General';
    _recurrence = t?.recurrence ?? 'Once';
    _selectedWeekDays =
        List<String>.from(t?.selectedWeekDays ?? ['Mon', 'Wed', 'Fri']);
    _subtasks = t?.subTasks
            .map((s) => SubTask(
                id: s.id, title: s.title, isCompleted: s.isCompleted))
            .toList() ??
        [];
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _newSubtaskCtrl.dispose();
    super.dispose();
  }

  void _addSubtask() {
    final text = _newSubtaskCtrl.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _subtasks.add(SubTask(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: text,
        ));
        _newSubtaskCtrl.clear();
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final parsed = DateTime.tryParse(_dueDate) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: parsed,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFFF08A82),
              surface: context.themeCardBackground,
              onSurface: context.themeTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dueDate = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  Future<void> _pickTime() async {
    int initialHour = 10;
    int initialMinute = 0;
    if (_dueTime != null && _dueTime!.contains(':')) {
      final parts = _dueTime!.split(':');
      initialHour = int.tryParse(parts[0]) ?? 10;
      initialMinute = int.tryParse(parts[1]) ?? 0;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFFF08A82),
              surface: context.themeCardBackground,
              onSurface: context.themeTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      setState(() => _dueTime = '$h:$m');
    }
  }

  String _getAutoNotificationScheduleText() {
    final dateParts = _dueDate.split('-');
    final y = int.tryParse(dateParts[0]) ?? DateTime.now().year;
    final m = int.tryParse(dateParts[1]) ?? DateTime.now().month;
    final d = int.tryParse(dateParts[2]) ?? DateTime.now().day;

    int hour = 10;
    int minute = 0;
    if (_dueTime != null && _dueTime!.contains(':')) {
      final timeParts = _dueTime!.split(':');
      hour = int.tryParse(timeParts[0]) ?? 10;
      minute = int.tryParse(timeParts[1]) ?? 0;
    }

    final target = DateTime(y, m, d, hour, minute);
    final now = DateTime.now();

    List<String> list = [];
    if (target.subtract(const Duration(days: 5)).isAfter(now)) {
      list.add('5 days before');
    }
    if (target.subtract(const Duration(hours: 24)).isAfter(now)) {
      list.add('24h before');
    }
    if (target.subtract(const Duration(hours: 5)).isAfter(now)) {
      list.add('5h before');
    }
    if (target.subtract(const Duration(hours: 1)).isAfter(now)) {
      list.add('1h before');
    }
    if (target.subtract(const Duration(minutes: 30)).isAfter(now)) {
      list.add('30m before');
    }
    if (target.subtract(const Duration(minutes: 10)).isAfter(now)) {
      list.add('10m before');
    }
    if (target.isAfter(now)) list.add('at exact time');

    if (list.isEmpty) return 'Immediate reminder scheduled';
    return list.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final totalScreenHeight = MediaQuery.of(context).size.height;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final availableHeight = totalScreenHeight - bottomInset;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: (availableHeight * 0.90).clamp(300.0, 720.0),
          ),
          margin: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: context.themeCardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.themeTextPrimary.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 36,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // ── Header (Always Pinned) ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: context.themeTextPrimary.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF08A82)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.task_alt_rounded,
                            size: 18,
                            color: Color(0xFFF08A82),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.task == null ? 'Create New Task' : 'Edit Task',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: context.themeTextPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: context.themeTextPrimary
                            .withValues(alpha: 0.04),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // ── Scrollable Form Fields ──
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title input
                      _buildFieldLabel('TASK TITLE'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _titleCtrl,
                        style: TextStyle(
                          color: context.themeTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _inputDecoration(
                          hint: 'What needs to be done?',
                          prefixIcon: Icons.edit_note_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Description input
                      _buildFieldLabel('DESCRIPTION / NOTES'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _descCtrl,
                        maxLines: 2,
                        style: TextStyle(
                          color: context.themeTextPrimary,
                          fontSize: 13.5,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Add context or details (optional)...',
                          prefixIcon: Icons.notes_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Date & Time Pickers ──
                      _buildFieldLabel('DUE DATE & TIME'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: context.themeTextPrimary
                                      .withValues(alpha: 0.035),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: context.themeTextPrimary
                                        .withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_month_rounded,
                                        size: 17, color: Color(0xFFF08A82)),
                                    const SizedBox(width: 8),
                                    Text(
                                      _dueDate,
                                      style: TextStyle(
                                        color: context.themeTextPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: _pickTime,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: context.themeTextPrimary
                                      .withValues(alpha: 0.035),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: context.themeTextPrimary
                                        .withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded,
                                        size: 17, color: Color(0xFFFDE047)),
                                    const SizedBox(width: 8),
                                    Text(
                                      _dueTime ?? 'Set Time',
                                      style: TextStyle(
                                        color: context.themeTextPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Automatic Notification Countdown Schedule Box ──
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF08A82)
                              .withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFF08A82)
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.auto_awesome_rounded,
                                size: 16, color: Color(0xFFF08A82)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'AUTOMATIC NOTIFICATION TIMELINE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFF08A82),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _getAutoNotificationScheduleText(),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: context.themeTextPrimary,
                                      height: 1.3,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Recurrence Frequency ("How Often") ──
                      _buildFieldLabel('HOW OFTEN (RECURRENCE)'),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _recurrences.map((r) {
                            final isSel = _recurrence == r;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(r),
                                selected: isSel,
                                selectedColor: const Color(0xFFF08A82),
                                backgroundColor: context.themeTextPrimary
                                    .withValues(alpha: 0.035),
                                labelStyle: TextStyle(
                                  color: isSel
                                      ? Colors.white
                                      : context.themeTextSecondary,
                                  fontSize: 12,
                                  fontWeight:
                                      isSel ? FontWeight.bold : FontWeight.w500,
                                ),
                                onSelected: (_) =>
                                    setState(() => _recurrence = r),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // ── 7-Day Selector for Weekly Recurrence ──
                      if (_recurrence == 'Weekly') ...[
                        const SizedBox(height: 12),
                        _buildFieldLabel('REPEAT ON DAYS'),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _allWeekDays.map((day) {
                            final isChecked =
                                _selectedWeekDays.contains(day);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isChecked) {
                                    if (_selectedWeekDays.length > 1) {
                                      _selectedWeekDays.remove(day);
                                    }
                                  } else {
                                    _selectedWeekDays.add(day);
                                  }
                                });
                              },
                              child: Container(
                                width: 38,
                                height: 38,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isChecked
                                      ? const Color(0xFFF08A82)
                                      : context.themeTextPrimary
                                          .withValues(alpha: 0.04),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isChecked
                                        ? const Color(0xFFF08A82)
                                        : context.themeTextPrimary
                                            .withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isChecked
                                        ? Colors.white
                                        : context.themeTextSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // ── Subtasks Section ──
                      _buildFieldLabel('SUBTASKS (${_subtasks.length})'),
                      const SizedBox(height: 6),
                      if (_subtasks.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 140),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _subtasks.length,
                            itemBuilder: (ctx, idx) {
                              final sub = _subtasks[idx];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 2),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: sub.isCompleted,
                                      activeColor: const Color(0xFF10B981),
                                      onChanged: (v) {
                                        setState(() =>
                                            sub.isCompleted = v ?? false);
                                      },
                                    ),
                                    Expanded(
                                      child: Text(
                                        sub.title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: context.themeTextPrimary,
                                          decoration: sub.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded,
                                          size: 16, color: Colors.redAccent),
                                      onPressed: () {
                                        setState(
                                            () => _subtasks.removeAt(idx));
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newSubtaskCtrl,
                              onSubmitted: (_) => _addSubtask(),
                              style: TextStyle(
                                  color: context.themeTextPrimary,
                                  fontSize: 13),
                              decoration: _inputDecoration(
                                hint: 'Add subtask (press Enter)...',
                                prefixIcon: Icons.playlist_add_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _addSubtask,
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFF08A82),
                            ),
                            icon: const Icon(Icons.add_rounded,
                                size: 18, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Priority & Category ──
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('PRIORITY'),
                                const SizedBox(height: 6),
                                _buildDropdown<String>(
                                  value: _priority,
                                  items: _priorities,
                                  onChanged: (val) => setState(
                                      () => _priority = val ?? 'Medium'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('CATEGORY'),
                                const SizedBox(height: 6),
                                _buildDropdown<String>(
                                  value: _category,
                                  items: _categories,
                                  onChanged: (val) => setState(
                                      () => _category = val ?? 'General'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Pinned Footer Actions ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: context.themeTextPrimary.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Row(
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
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        final title = _titleCtrl.text.trim();
                        if (title.isEmpty) return;

                        if (_newSubtaskCtrl.text.trim().isNotEmpty) {
                          _subtasks.add(SubTask(
                            id: DateTime.now()
                                .microsecondsSinceEpoch
                                .toString(),
                            title: _newSubtaskCtrl.text.trim(),
                          ));
                        }

                        final task = Task(
                          id: widget.task?.id ??
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          title: title,
                          description: _descCtrl.text.trim().isEmpty
                              ? null
                              : _descCtrl.text.trim(),
                          category: _category,
                          priority: _priority,
                          dueDate: _dueDate,
                          dueTime: _dueTime,
                          recurrence: _recurrence,
                          selectedWeekDays: _selectedWeekDays,
                          isCompleted: widget.task?.isCompleted ?? false,
                          streak: widget.task?.streak ?? 0,
                          lastCompletedDate: widget.task?.lastCompletedDate,
                          subTasks: _subtasks,
                        );

                        widget.onSave(task);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF08A82),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save Task',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13.5)),
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

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: context.themeTextSecondary,
      ),
    );
  }

  InputDecoration _inputDecoration(
      {required String hint, required IconData prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: context.themeTextSecondary.withValues(alpha: 0.6),
        fontSize: 13,
      ),
      prefixIcon: Icon(prefixIcon, size: 18, color: context.themeTextSecondary),
      filled: true,
      fillColor: context.themeTextPrimary.withValues(alpha: 0.035),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: context.themeTextPrimary.withValues(alpha: 0.06),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: context.themeTextPrimary.withValues(alpha: 0.06),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFF08A82),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.themeTextPrimary.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.themeTextPrimary.withValues(alpha: 0.06),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: context.themeCardBackground,
          items: items.map((i) {
            return DropdownMenuItem<T>(
              value: i,
              child: Text(
                i.toString(),
                style: TextStyle(
                  color: context.themeTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}