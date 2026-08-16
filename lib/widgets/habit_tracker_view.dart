import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habit Model
// ─────────────────────────────────────────────────────────────────────────────
class Habit {
  final String id;
  final String name;
  final List<String> completedDates; // Format: YYYY-MM-DD
  final int total; // Target goal (e.g. 21, 30, 60 days)
  final Color color;
  final String frequency; // 'daily', 'weekly', 'monthly'
  final int durationMinutes; // e.g. 15, 30, 45, 60
  final String timeOfDay; // e.g. "08:00 AM"
  final List<String> reminders; // Automatically scheduled ['30_min', '10_min', 'exact']
  final List<String> targetDays; // For weekly habits: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

  Habit({
    required this.id,
    required this.name,
    required this.completedDates,
    required this.total,
    required this.color,
    this.frequency = 'daily',
    this.durationMinutes = 30,
    this.timeOfDay = '08:00 AM',
    this.reminders = const [
      '5_min_before',
      'exact',
      '5_min_before_complete'
    ],
    this.targetDays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      completedDates: List<String>.from(json['completedDates'] ?? []),
      total: json['total'] ?? 21,
      color: Color(json['colorValue'] ?? 0xFFF08A82),
      frequency: json['frequency'] ?? 'daily',
      durationMinutes: json['durationMinutes'] ?? 30,
      timeOfDay: json['timeOfDay'] ?? '08:00 AM',
      reminders: json['reminders'] != null
          ? List<String>.from(json['reminders'])
          : const ['5_min_before', 'exact', '5_min_before_complete'],
      targetDays: json['targetDays'] != null
          ? List<String>.from(json['targetDays'])
          : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'completedDates': completedDates,
      'total': total,
      'colorValue': color.toARGB32(),
      'frequency': frequency,
      'durationMinutes': durationMinutes,
      'timeOfDay': timeOfDay,
      'reminders': reminders,
      'targetDays': targetDays,
    };
  }

  Habit copyWith({
    String? name,
    List<String>? completedDates,
    int? total,
    Color? color,
    String? frequency,
    int? durationMinutes,
    String? timeOfDay,
    List<String>? reminders,
    List<String>? targetDays,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      completedDates: completedDates ?? this.completedDates,
      total: total ?? this.total,
      color: color ?? this.color,
      frequency: frequency ?? this.frequency,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      reminders: reminders ?? this.reminders,
      targetDays: targetDays ?? this.targetDays,
    );
  }

  int get currentStreak {
    if (completedDates.isEmpty) return 0;

    DateTime now = DateTime.now();
    String todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    DateTime yesterday = now.subtract(const Duration(days: 1));
    String yesterdayStr =
        "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

    bool completedToday = completedDates.contains(todayStr);
    bool completedYesterday = completedDates.contains(yesterdayStr);

    if (!completedToday && !completedYesterday) return 0;

    int streak = 0;
    DateTime checkDate = completedToday ? now : yesterday;

    for (int i = 0; i < 1000; i++) {
      String dateStr =
          "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
      if (completedDates.contains(dateStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HabitTrackerView
// ─────────────────────────────────────────────────────────────────────────────
class HabitTrackerView extends StatefulWidget {
  final List<Habit> habits;
  final Function(List<Habit>) onHabitsChanged;

  const HabitTrackerView({
    super.key,
    required this.habits,
    required this.onHabitsChanged,
  });

  @override
  State<HabitTrackerView> createState() => _HabitTrackerViewState();
}

class _HabitTrackerViewState extends State<HabitTrackerView> {
  String _selectedFilter = 'all'; // 'all', 'daily', 'weekly', 'monthly'

  final List<Color> _themeColors = [
    const Color(0xFFF08A82), // Coral Salmon
    const Color(0xFF86EFAC), // Mint Green
    const Color(0xFF93C5FD), // Sky Blue
    const Color(0xFFFDE047), // Pastel Yellow
    const Color(0xFFC4B5FD), // Lavender
    const Color(0xFFF472B6), // Rose Pink
    const Color(0xFF10B981), // Emerald
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF6366F1), // Royal Indigo
    const Color(0xFF14B8A6), // Teal
  ];

  String _getTodayStr() {
    DateTime now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  List<Habit> get _filteredHabits {
    if (_selectedFilter == 'all') return widget.habits;
    return widget.habits.where((h) => h.frequency == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final todayStr = _getTodayStr();

    final filteredList = List<Habit>.from(_filteredHabits);
    filteredList.sort((a, b) {
      bool aDone = a.completedDates.contains(todayStr);
      bool bDone = b.completedDates.contains(todayStr);
      if (aDone && !bDone) return 1;
      if (!aDone && bDone) return -1;
      return 0;
    });

    final habitsDoneToday =
        widget.habits.where((h) => h.completedDates.contains(todayStr)).length;
    final bestStreak = widget.habits.isEmpty
        ? 0
        : widget.habits
            .map((h) => h.currentStreak)
            .reduce((a, b) => a > b ? a : b);

    final dailyCount =
        widget.habits.where((h) => h.frequency == 'daily').length;
    final weeklyCount =
        widget.habits.where((h) => h.frequency == 'weekly').length;
    final monthlyCount =
        widget.habits.where((h) => h.frequency == 'monthly').length;

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
          // ─── Header (Fixed) ───
          _buildHeader(context),
          const SizedBox(height: 14),

          // ─── Summary Card (Fixed) ───
          _buildHabitSummaryCard(
            context,
            habitsDone: habitsDoneToday,
            totalHabits: widget.habits.length,
            bestStreak: bestStreak,
          ),
          const SizedBox(height: 14),

          // ─── Frequency Filter Tabs (Fixed) ───
          _buildFilterTabs(
            context,
            totalCount: widget.habits.length,
            dailyCount: dailyCount,
            weeklyCount: weeklyCount,
            monthlyCount: monthlyCount,
          ),
          const SizedBox(height: 14),

          // ─── Scrollable Habit List ───
          Expanded(
            child: filteredList.isEmpty
                ? SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildEmptyState(context),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      return _buildHabitItem(
                          context, filteredList[index], isMobile);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Header
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
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
                    'Habit ',
                    style: TextStyle(
                      color: context.themeTextPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    'Tracker',
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
                'Track daily, weekly & monthly consistency',
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
        const SizedBox(width: 10),
        InkWell(
          onTap: () => _showHabitDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  'New Habit',
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
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Summary Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHabitSummaryCard(
    BuildContext context, {
    required int habitsDone,
    required int totalHabits,
    required int bestStreak,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                    Icons.local_fire_department_rounded,
                    size: 16,
                    color: Color(0xFFF08A82),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PROGRESS OVERVIEW',
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
                'Streak: $bestStreak Days',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.themeTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.themeTextPrimary.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.themeTextPrimary.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          size: 18, color: Color(0xFF86EFAC)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$habitsDone / $totalHabits',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: context.themeTextPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Completed Today',
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
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.themeTextPrimary.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.themeTextPrimary.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded,
                          size: 18, color: Color(0xFFFDE047)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              totalHabits > 0
                                  ? '${((habitsDone / totalHabits) * 100).toInt()}%'
                                  : '0%',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: context.themeTextPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Daily Rate',
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
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Frequency Filter Tabs (All / Daily / Weekly / Monthly)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFilterTabs(
    BuildContext context, {
    required int totalCount,
    required int dailyCount,
    required int weeklyCount,
    required int monthlyCount,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _filterChip('all', 'All Habits', totalCount),
          const SizedBox(width: 8),
          _filterChip('daily', 'Daily', dailyCount),
          const SizedBox(width: 8),
          _filterChip('weekly', 'Weekly', weeklyCount),
          const SizedBox(width: 8),
          _filterChip('monthly', 'Monthly', monthlyCount),
        ],
      ),
    );
  }

  Widget _filterChip(String key, String label, int count) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF08A82)
              : context.themeCardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF08A82)
                : context.themeTextPrimary.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : context.themeTextPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : context.themeTextPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : context.themeTextSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Habit Item Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHabitItem(BuildContext context, Habit habit, bool isMobile) {
    final todayStr = _getTodayStr();
    final isCompletedToday = habit.completedDates.contains(todayStr);
    final now = DateTime.now();
    final last7Days =
        List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    String freqLabel = 'Daily';
    Color freqColor = const Color(0xFF10B981);
    if (habit.frequency == 'weekly') {
      final daysSummary = habit.targetDays.length == 7
          ? 'Every day'
          : habit.targetDays.join(', ');
      freqLabel = 'Weekly ($daysSummary)';
      freqColor = const Color(0xFF3B82F6);
    } else if (habit.frequency == 'monthly') {
      freqLabel = 'Monthly';
      freqColor = const Color(0xFF8B5CF6);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Check button
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: GestureDetector(
                  onTap: () {
                    final newHabits = List<Habit>.from(widget.habits);
                    final index =
                        newHabits.indexWhere((h) => h.id == habit.id);
                    if (index == -1) return;

                    final List<String> newDates =
                        List<String>.from(habit.completedDates);
                    if (isCompletedToday) {
                      newDates.remove(todayStr);
                    } else {
                      newDates.add(todayStr);
                    }

                    newHabits[index] =
                        habit.copyWith(completedDates: newDates);
                    widget.onHabitsChanged(newHabits);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompletedToday
                          ? habit.color
                          : context.themeTextPrimary.withValues(alpha: 0.04),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompletedToday
                            ? habit.color
                            : context.themeTextPrimary
                                .withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                    ),
                    child: isCompletedToday
                        ? const Icon(Icons.check_rounded,
                            size: 18, color: Colors.white)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            habit.name,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: isCompletedToday
                                  ? context.themeTextSecondary
                                  : context.themeTextPrimary,
                              decoration: isCompletedToday
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Metadata tags: Frequency, Duration, Time, Goal, Streak
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Frequency badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: freqColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            freqLabel,
                            style: TextStyle(
                              color: freqColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // Duration badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.themeTextPrimary
                                .withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer_outlined,
                                  size: 11,
                                  color: context.themeTextSecondary),
                              const SizedBox(width: 3),
                              Text(
                                '${habit.durationMinutes}m',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Time badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.themeTextPrimary
                                .withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time_rounded,
                                  size: 11,
                                  color: context.themeTextSecondary),
                              const SizedBox(width: 3),
                              Text(
                                habit.timeOfDay,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Target goal badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.themeTextPrimary
                                .withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flag_outlined,
                                  size: 11,
                                  color: context.themeTextSecondary),
                              const SizedBox(width: 3),
                              Text(
                                '${habit.total}d goal',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Streak badge
                        if (habit.currentStreak > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF08A82)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                    Icons.local_fire_department_rounded,
                                    size: 11,
                                    color: Color(0xFFF08A82)),
                                const SizedBox(width: 3),
                                Text(
                                  '${habit.currentStreak}d streak',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF08A82),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    size: 18, color: context.themeTextSecondary),
                color: context.themeCardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: context.themeTextPrimary.withValues(alpha: 0.08),
                  ),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showHabitDialog(context, existingHabit: habit);
                  } else if (value == 'delete') {
                    _deleteHabit(habit);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit',
                        style: TextStyle(
                            color: context.themeTextPrimary, fontSize: 13)),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(
                            color: Colors.redAccent, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 7-day mini tracker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: context.themeTextPrimary.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: last7Days.map((date) {
                String dStr =
                    "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                bool isDone = habit.completedDates.contains(dStr);
                final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                String dayName = dayLabels[date.weekday - 1];

                return InkWell(
                  onTap: () {
                    final newHabits = List<Habit>.from(widget.habits);
                    final index =
                        newHabits.indexWhere((h) => h.id == habit.id);
                    if (index == -1) return;

                    final List<String> newDates =
                        List<String>.from(habit.completedDates);
                    if (isDone) {
                      newDates.remove(dStr);
                    } else {
                      newDates.add(dStr);
                    }
                    newHabits[index] =
                        habit.copyWith(completedDates: newDates);
                    widget.onHabitsChanged(newHabits);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isDone ? habit.color : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDone
                                ? habit.color
                                : context.themeTextPrimary
                                    .withValues(alpha: 0.12),
                            width: 1.2,
                          ),
                        ),
                        child: isDone
                            ? const Icon(Icons.check,
                                size: 13, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDone
                              ? context.themeTextPrimary
                              : context.themeTextSecondary,
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

  // ───────────────────────────────────────────────────────────────────────────
  // Empty State
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Container(
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
            Icons.local_fire_department_outlined,
            size: 36,
            color: const Color(0xFFF08A82).withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'No Habits in This View',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: context.themeTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "New Habit" above to create daily, weekly, or monthly habits.',
            style: TextStyle(
              fontSize: 12,
              color: context.themeTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Create / Edit Habit Dialog
  // ───────────────────────────────────────────────────────────────────────────
  void _showHabitDialog(BuildContext context, {Habit? existingHabit}) {
    final isEditing = existingHabit != null;
    final nameController =
        TextEditingController(text: isEditing ? existingHabit.name : '');
    int total = isEditing ? existingHabit.total : 21;
    Color selectedColor = isEditing ? existingHabit.color : _themeColors[0];
    String frequency = isEditing ? existingHabit.frequency : 'daily';
    int durationMinutes = isEditing ? existingHabit.durationMinutes : 30;
    String timeOfDayStr = isEditing ? existingHabit.timeOfDay : '08:00 AM';
    List<String> targetDays = isEditing
        ? List<String>.from(existingHabit.targetDays)
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final allDaysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final durationOptions = [10, 15, 20, 30, 45, 60, 90];
    final goalPresetOptions = [21, 30, 60, 90, 100, 365];
    final timePresets = [
      '06:00 AM',
      '07:00 AM',
      '08:00 AM',
      '12:00 PM',
      '05:00 PM',
      '07:00 PM',
      '09:00 PM'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: context.themeCardBackground,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Edit Habit' : 'New Habit',
                    style: TextStyle(
                      color: context.themeTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Habit Title
                  TextField(
                    controller: nameController,
                    style: TextStyle(
                        color: context.themeTextPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. Read 20 Pages, Morning Jog, Meditation',
                      hintStyle: TextStyle(
                        color: context.themeTextSecondary
                            .withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor:
                          context.themeTextPrimary.withValues(alpha: 0.03),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── 1. FREQUENCY (Daily / Weekly / Monthly) ──
                  _dialogSectionTitle('FREQUENCY'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _frequencyBtn('daily', 'Daily', frequency, (f) {
                        setDialogState(() => frequency = f);
                      }),
                      const SizedBox(width: 8),
                      _frequencyBtn('weekly', 'Weekly', frequency, (f) {
                        setDialogState(() => frequency = f);
                      }),
                      const SizedBox(width: 8),
                      _frequencyBtn('monthly', 'Monthly', frequency, (f) {
                        setDialogState(() => frequency = f);
                      }),
                    ],
                  ),

                  // Weekly Days Selector (Mon - Sun)
                  if (frequency == 'weekly') ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _dialogSectionTitle('SELECT DAYS'),
                        Text(
                          '${targetDays.length} / 7 Days Selected',
                          style: const TextStyle(
                            color: Color(0xFF3B82F6),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: allDaysOfWeek.map((day) {
                        final isSel = targetDays.contains(day);
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              if (isSel) {
                                if (targetDays.length > 1) {
                                  targetDays.remove(day);
                                }
                              } else {
                                targetDays.add(day);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFF3B82F6)
                                  : context.themeTextPrimary
                                      .withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFF3B82F6)
                                    : context.themeTextPrimary
                                        .withValues(alpha: 0.1),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSel
                                    ? Colors.white
                                    : context.themeTextPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // ── 2. HOW LONG (DURATION) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _dialogSectionTitle('HOW LONG (DURATION)'),
                      Text(
                        '$durationMinutes mins',
                        style: const TextStyle(
                          color: Color(0xFFF08A82),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: durationOptions.map((m) {
                        final isSel = durationMinutes == m;
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => durationMinutes = m),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFFF08A82)
                                  : context.themeTextPrimary
                                      .withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFFF08A82)
                                    : context.themeTextPrimary
                                        .withValues(alpha: 0.08),
                              ),
                            ),
                            child: Text(
                              '${m}m',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isSel
                                    ? Colors.white
                                    : context.themeTextPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── 3. TIME / SCHEDULE (INTERACTIVE CLOCK) ──
                  _dialogSectionTitle('TIME / SCHEDULE'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final localizations = MaterialLocalizations.of(context);
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 8, minute: 0),
                      );
                      if (picked != null) {
                        final formatted = localizations.formatTimeOfDay(
                            picked,
                            alwaysUse24HourFormat: false);
                        setDialogState(() => timeOfDayStr = formatted);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            context.themeTextPrimary.withValues(alpha: 0.035),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFF08A82)
                              .withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF08A82)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.access_time_filled_rounded,
                              color: Color(0xFFF08A82),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  timeOfDayStr,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: context.themeTextPrimary,
                                  ),
                                ),
                                Text(
                                  'Tap clock to set exact time',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: context.themeTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.edit_calendar_rounded,
                            size: 18,
                            color: Color(0xFFF08A82),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: timePresets.map((t) {
                        final isSel = timeOfDayStr == t;
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => timeOfDayStr = t),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFFF08A82)
                                  : context.themeTextPrimary
                                      .withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSel
                                  ? const Color(0xFFF08A82)
                                  : context.themeTextPrimary
                                      .withValues(alpha: 0.08),
                              ),
                            ),
                            child: Text(
                              t,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSel
                                    ? Colors.white
                                    : context.themeTextPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── 4. GOAL TARGET (USER SET) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _dialogSectionTitle('GOAL TARGET'),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF08A82)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$total Days Goal',
                          style: const TextStyle(
                            color: Color(0xFFF08A82),
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: goalPresetOptions.map((g) {
                        final isSel = total == g;
                        return GestureDetector(
                          onTap: () => setDialogState(() => total = g),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFFF08A82)
                                  : context.themeTextPrimary
                                      .withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFFF08A82)
                                    : context.themeTextPrimary
                                        .withValues(alpha: 0.08),
                              ),
                            ),
                            child: Text(
                              '${g}d',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSel
                                    ? Colors.white
                                    : context.themeTextPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFFF08A82),
                      inactiveTrackColor: context.themeTextPrimary
                          .withValues(alpha: 0.08),
                      thumbColor: const Color(0xFFF08A82),
                      overlayColor: const Color(0xFFF08A82)
                          .withValues(alpha: 0.15),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7.0),
                    ),
                    child: Slider(
                      value: total.toDouble(),
                      min: 7,
                      max: 365,
                      divisions: 358,
                      onChanged: (v) =>
                          setDialogState(() => total = v.toInt()),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── 5. COLOR TAG ──
                  _dialogSectionTitle('COLOR TAG'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _themeColors.map((c) {
                      final isSelected = selectedColor == c;
                      return GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedColor = c),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? context.themeTextPrimary
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                        color: c.withValues(alpha: 0.5),
                                        blurRadius: 6)
                                  ]
                                : [],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 15, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
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
                        onPressed: () async {
                          if (nameController.text.trim().isNotEmpty) {
                            final updatedList =
                                List<Habit>.from(widget.habits);
                            final habitId = isEditing
                                ? existingHabit.id
                                : DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString();
                            final habitName = nameController.text.trim();
                            const autoReminders = [
                              '5_min_before',
                              'exact',
                              '5_min_before_complete',
                              'complete'
                            ];

                            final newHabit = Habit(
                              id: habitId,
                              name: habitName,
                              completedDates: isEditing
                                  ? existingHabit.completedDates
                                  : [],
                              total: total,
                              color: selectedColor,
                              frequency: frequency,
                              durationMinutes: durationMinutes,
                              timeOfDay: timeOfDayStr,
                              reminders: autoReminders,
                              targetDays: targetDays,
                            );

                            if (isEditing) {
                              final index = updatedList.indexWhere(
                                  (h) => h.id == existingHabit.id);
                              if (index != -1) {
                                updatedList[index] = newHabit;
                              }
                            } else {
                              updatedList.add(newHabit);
                            }

                            // Automatically schedule habit reminder notifications in background
                            final numericId =
                                int.tryParse(habitId) ?? habitId.hashCode;
                            await NotificationService().scheduleHabitReminders(
                              baseId: numericId,
                              habitName: habitName,
                              timeOfDayStr: timeOfDayStr,
                              durationMinutes: durationMinutes,
                              selectedReminders: autoReminders,
                            );

                            widget.onHabitsChanged(updatedList);
                            if (ctx.mounted) Navigator.pop(ctx);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF08A82),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isEditing ? 'Save' : 'Create',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogSectionTitle(String t) {
    return Text(
      t,
      style: TextStyle(
        color: context.themeTextSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _frequencyBtn(
      String key, String label, String current, Function(String) onSelect) {
    final isSel = current == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel
                ? const Color(0xFFF08A82)
                : context.themeTextPrimary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSel
                  ? const Color(0xFFF08A82)
                  : context.themeTextPrimary.withValues(alpha: 0.08),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSel ? Colors.white : context.themeTextPrimary,
            ),
          ),
        ),
      ),
    );
  }

  void _deleteHabit(Habit habit) {
    final numericId = int.tryParse(habit.id) ?? habit.id.hashCode;
    NotificationService().cancelHabitNotifications(numericId);

    final updatedList =
        widget.habits.where((h) => h.id != habit.id).toList();
    widget.onHabitsChanged(updatedList);
  }
}