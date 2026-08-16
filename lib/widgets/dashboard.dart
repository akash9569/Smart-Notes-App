import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import 'notes_manager.dart';
import 'task_manager.dart';
import 'habit_tracker_view.dart';
import 'expense_manager.dart';

class Dashboard extends StatelessWidget {
  final String userName;
  final List<Note> notes;
  final List<Task> tasks;
  final List<Habit> habits;
  final List<Transaction> transactions;
  final Function(String)? onTabChange;

  const Dashboard({
    super.key,
    required this.userName,
    required this.notes,
    required this.tasks,
    required this.habits,
    required this.transactions,
    this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    final pendingTasks = tasks.where((t) => !t.isCompleted).toList();
    final completedTasksCount = tasks.where((t) => t.isCompleted).length;
    final habitsCompletedToday = habits
        .where((h) => h.completedDates.contains(todayStr))
        .length;

    // Filter today's / overdue tasks first, sorted by actual due time
    final todayAndOverdueTasks = pendingTasks
        .where((t) => t.dueDate.compareTo(todayStr) <= 0)
        .toList()
      ..sort((a, b) => a.dueDateTime.compareTo(b.dueDateTime));

    final upcomingTasks = pendingTasks
        .where((t) => t.dueDate.compareTo(todayStr) > 0)
        .toList()
      ..sort((a, b) => a.dueDateTime.compareTo(b.dueDateTime));

    final timelineTasks = todayAndOverdueTasks.isNotEmpty
        ? todayAndOverdueTasks
        : upcomingTasks;

    final isShowingUpcoming =
        todayAndOverdueTasks.isEmpty && upcomingTasks.isNotEmpty;

    final totalSpentThisMonth = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final balance = totalIncome - totalSpentThisMonth;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 18 : 36,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. TOP DATE & GREETING HEADER ───
            _buildTopHeader(context, now),
            const SizedBox(height: 18),

            // ─── 2. HORIZONTAL 7-DAY CALENDAR STRIP ───
            _buildWeeklyCalendarStrip(context, now),
            const SizedBox(height: 22),

            // ─── 3. QUICK ACTION CIRCLES (STRUCTURED STYLE) ───
            _buildQuickActionShortcuts(context),
            const SizedBox(height: 22),

            // ─── 4. DAILY PULSE / SUMMARY METRICS ───
            _buildDailyPulseCard(
              context,
              balance: balance,
              spentThisMonth: totalSpentThisMonth,
              pendingTasksCount: pendingTasks.length,
              completedTasksCount: completedTasksCount,
              habitsDone: habitsCompletedToday,
              habitsTotal: habits.length,
            ),
            const SizedBox(height: 28),

            // ─── 5. TODAY'S TIMELINE / AGENDA ───
            _buildSectionHeader(
              context,
              title: isShowingUpcoming ? "Upcoming Timeline" : "Today's Timeline",
              actionLabel: 'View All',
              onTap: () => onTabChange?.call('Tasks'),
            ),
            const SizedBox(height: 14),
            _buildTimelineSection(context, timelineTasks, todayStr),
            const SizedBox(height: 28),

            // ─── 6. RECENT NOTES & THOUGHTS ───
            _buildSectionHeader(
              context,
              title: 'Recent Notes',
              actionLabel: 'All Notes',
              onTap: () => onTabChange?.call('Notes'),
            ),
            const SizedBox(height: 14),
            _buildRecentNotesSection(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. Top Header (e.g., "14. August 2026")
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopHeader(BuildContext context, DateTime now) {
    final dayStr = DateFormat('d').format(now);
    final monthStr = DateFormat('MMMM').format(now);
    final yearStr = DateFormat('yyyy').format(now);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$dayStr. $monthStr ',
                  style: TextStyle(
                    color: context.themeTextPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  yearStr,
                  style: const TextStyle(
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
              'Welcome back, $userName',
              style: TextStyle(
                color: context.themeTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: () => _showCalendarModal(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: context.themeTextPrimary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.themeTextPrimary.withValues(alpha: 0.06),
              ),
            ),
            child: Icon(
              Icons.calendar_month_outlined,
              size: 20,
              color: context.themeTextPrimary,
            ),
          ),
        ),
      ],
    );
  }

  void _showCalendarModal(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final monthStr = DateFormat('MMMM yyyy').format(selectedDate);
            final dayHeaderStr = DateFormat('d MMM yyyy').format(selectedDate);
            final selectedDateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
            final firstDayOfMonth =
                DateTime(selectedDate.year, selectedDate.month, 1);
            final daysInMonth =
                DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
            final startingWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

            final selectedDateTasks = tasks
                .where((t) => t.dueDate == selectedDateKey)
                .toList()
              ..sort((a, b) => a.dueDateTime.compareTo(b.dueDateTime));

            return Dialog(
              backgroundColor: context.themeCardBackground,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CALENDAR & SCHEDULE',
                              style: TextStyle(
                                color: Color(0xFFF08A82),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              dayHeaderStr,
                              style: TextStyle(
                                color: context.themeTextPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded,
                              size: 20, color: context.themeTextSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Divider(
                        color: context.themeTextPrimary.withValues(alpha: 0.08),
                        height: 1),
                    const SizedBox(height: 14),

                    // Month Navigator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          monthStr,
                          style: TextStyle(
                            color: context.themeTextPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded,
                                  size: 22),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              color: context.themeTextPrimary,
                              onPressed: () {
                                setModalState(() {
                                  selectedDate = DateTime(selectedDate.year,
                                      selectedDate.month - 1, 1);
                                });
                              },
                            ),
                            const SizedBox(width: 14),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded,
                                  size: 22),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              color: context.themeTextPrimary,
                              onPressed: () {
                                setModalState(() {
                                  selectedDate = DateTime(selectedDate.year,
                                      selectedDate.month + 1, 1);
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Weekdays Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) {
                        return SizedBox(
                          width: 34,
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                color: context.themeTextSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 6),

                    // Grid with Task Dots
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 35,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        childAspectRatio: 1.1,
                      ),
                      itemBuilder: (ctx, i) {
                        final dayNum = i - startingWeekday + 1;
                        if (dayNum < 1 || dayNum > daysInMonth) {
                          return const SizedBox();
                        }
                        final isSelected = dayNum == selectedDate.day;
                        final currentCellDateKey = DateFormat('yyyy-MM-dd')
                            .format(DateTime(
                                selectedDate.year, selectedDate.month, dayNum));
                        final dayTasks = tasks
                            .where((t) => t.dueDate == currentCellDateKey)
                            .toList();
                        final hasPending = dayTasks.any((t) => !t.isCompleted);

                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              selectedDate = DateTime(selectedDate.year,
                                  selectedDate.month, dayNum);
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFF08A82)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$dayNum',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : context.themeTextPrimary,
                                    fontSize: 12.5,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                                if (dayTasks.isNotEmpty)
                                  Container(
                                    width: 4.5,
                                    height: 4.5,
                                    margin: const EdgeInsets.only(top: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : (hasPending
                                              ? const Color(0xFFF08A82)
                                              : const Color(0xFF10B981)),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Divider(
                        color: context.themeTextPrimary.withValues(alpha: 0.08),
                        height: 1),
                    const SizedBox(height: 10),

                    // Tasks for Selected Date Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tasks for ${DateFormat('d MMM').format(selectedDate)}',
                          style: TextStyle(
                            color: context.themeTextPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF08A82)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${selectedDateTasks.length}',
                            style: const TextStyle(
                              color: Color(0xFFF08A82),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Tasks List Container
                    Flexible(
                      child: selectedDateTasks.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                color: context.themeTextPrimary
                                    .withValues(alpha: 0.025),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'No tasks scheduled for this day.',
                                  style: TextStyle(
                                    color: context.themeTextSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: selectedDateTasks.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (ctx, idx) {
                                final task = selectedDateTasks[idx];
                                return InkWell(
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    onTabChange?.call('Tasks');
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: context.themeTextPrimary
                                          .withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: context.themeTextPrimary
                                            .withValues(alpha: 0.04),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          task.isCompleted
                                              ? Icons.check_circle_rounded
                                              : Icons.radio_button_unchecked_rounded,
                                          size: 16,
                                          color: task.isCompleted
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFF08A82),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            task.title,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: context.themeTextPrimary,
                                              decoration: task.isCompleted
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (task.dueTime != null &&
                                            task.dueTime!.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            task.dueTime!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  context.themeTextSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
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
          },
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. 7-Day Calendar Strip (Minimal & Elegant)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildWeeklyCalendarStrip(BuildContext context, DateTime now) {
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: context.themeCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.themeTextPrimary.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final date = startOfWeek.add(Duration(days: index));
          final isToday = date.day == now.day &&
              date.month == now.month &&
              date.year == now.year;

          return Expanded(
            child: Column(
              children: [
                Text(
                  weekDays[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isToday
                        ? const Color(0xFFF08A82)
                        : context.themeTextSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFFF08A82)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                      color: isToday
                          ? Colors.white
                          : context.themeTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Small indicator dot
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFFF08A82)
                        : context.themeTextPrimary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. Quick Action Circular Shortcuts (Structured Screenshot Style)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildQuickActionShortcuts(BuildContext context) {
    final actions = [
      {'title': 'Notes', 'icon': Icons.edit_note_rounded, 'color': const Color(0xFF86EFAC), 'tab': 'Notes'},
      {'title': 'Tasks', 'icon': Icons.check_circle_outline_rounded, 'color': const Color(0xFFF08A82), 'tab': 'Tasks'},
      {'title': 'Expenses', 'icon': Icons.account_balance_wallet_outlined, 'color': const Color(0xFF93C5FD), 'tab': 'Expenses'},
      {'title': 'Habits', 'icon': Icons.local_fire_department_outlined, 'color': const Color(0xFFFDE047), 'tab': 'Habit Tracker'},
      {'title': 'Sticky Notes', 'icon': Icons.push_pin_outlined, 'color': const Color(0xFFC4B5FD), 'tab': 'Sticky Notes'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: actions.map((item) {
          final color = item['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InkWell(
              onTap: () => onTabChange?.call(item['tab'] as String),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: context.isDarkMode ? color : Color.lerp(color, Colors.black, 0.4)!,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['title'] as String,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: context.themeTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. Daily Pulse / Clean Overview Summary Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDailyPulseCard(
    BuildContext context, {
    required double balance,
    required double spentThisMonth,
    required int pendingTasksCount,
    required int completedTasksCount,
    required int habitsDone,
    required int habitsTotal,
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
                  Icon(
                    Icons.insights_rounded,
                    size: 16,
                    color: context.themeTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'DAILY OVERVIEW',
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
                'Balance: ₹${balance.toStringAsFixed(0)}',
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
                child: _buildMetricPill(
                  context,
                  label: 'Pending Tasks',
                  value: '$pendingTasksCount',
                  icon: Icons.checklist_rtl_rounded,
                  accentColor: const Color(0xFFF08A82),
                  onTap: () => onTabChange?.call('Tasks'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricPill(
                  context,
                  label: 'Habits Done',
                  value: '$habitsDone / $habitsTotal',
                  icon: Icons.flash_on_rounded,
                  accentColor: const Color(0xFFF59E0B),
                  onTap: () => onTabChange?.call('Habit Tracker'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.themeTextPrimary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.themeTextPrimary.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: accentColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: context.themeTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 5. Timeline Section (Signature Structured Vertical Flow)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTimelineSection(
      BuildContext context, List<Task> tasks, String todayStr) {
    if (tasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
              Icons.check_circle_outline_rounded,
              size: 32,
              color: const Color(0xFFF08A82).withValues(alpha: 0.6),
            ),
            const SizedBox(height: 10),
            Text(
              'No Timeline Tasks Today',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.themeTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All caught up! Tap above to add a new task.',
              style: TextStyle(
                fontSize: 12,
                color: context.themeTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final displayTasks = tasks.take(5).toList();

    return Column(
      children: displayTasks.asMap().entries.map((entry) {
        final index = entry.key;
        final task = entry.value;
        final isLast = index == (displayTasks.length - 1);
        final isOverdue = task.dueDate.compareTo(todayStr) < 0;

        // Calculate REAL formatted time
        String timeDisplay = 'All Day';
        if (task.dueTime != null && task.dueTime!.contains(':')) {
          final parts = task.dueTime!.split(':');
          final hour = int.tryParse(parts[0]) ?? 9;
          final minute = int.tryParse(parts[1]) ?? 0;
          final dt = DateTime(2026, 1, 1, hour, minute);
          timeDisplay = DateFormat('h:mm a').format(dt); // e.g. 10:00 AM, 2:30 PM
        }

        final Color nodeColor = isOverdue
            ? const Color(0xFFEF4444)
            : (task.dueDate == todayStr
                ? const Color(0xFFF08A82)
                : const Color(0xFF93C5FD));

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Time column
              SizedBox(
                width: 72,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeDisplay,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: context.themeTextPrimary,
                        ),
                      ),
                      Text(
                        isOverdue
                            ? 'Overdue'
                            : (task.dueDate == todayStr ? 'Today' : task.dueDate),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isOverdue
                              ? Colors.redAccent
                              : context.themeTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // Timeline line and Node
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: nodeColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOverdue
                          ? Icons.warning_amber_rounded
                          : Icons.schedule_rounded,
                      size: 16,
                      color: nodeColor,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: context.themeTextPrimary.withValues(alpha: 0.1),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Task Details Card
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                  child: InkWell(
                    onTap: () => onTabChange?.call('Tasks'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: context.themeCardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isOverdue
                              ? Colors.redAccent.withValues(alpha: 0.25)
                              : context.themeTextPrimary
                                  .withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.themeTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (task.category != 'General') ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: context.themeTextPrimary
                                              .withValues(alpha: 0.04),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          task.category,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: context.themeTextSecondary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    if (task.subTasks.isNotEmpty) ...[
                                      Text(
                                        '✓ ${task.subTaskCompleted}/${task.subTasks.length}',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFF08A82),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 6. Recent Notes Section
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRecentNotesSection(BuildContext context) {
    if (notes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: context.themeCardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.themeTextPrimary.withValues(alpha: 0.05),
          ),
        ),
        child: Center(
          child: Text(
            'No notes created yet.',
            style: TextStyle(
              fontSize: 12.5,
              color: context.themeTextSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      children: notes.take(2).map((note) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.themeCardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: context.themeTextPrimary.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.themeTextPrimary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.article_outlined,
                  size: 18,
                  color: context.themeTextPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title.isNotEmpty ? note.title : 'Untitled',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: context.themeTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note.content.replaceAll('\n', ' '),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.themeTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                note.date.split(' ').first,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.iconGrey,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Helper: Section Header with Action
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
            color: context.themeTextPrimary,
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF08A82),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
