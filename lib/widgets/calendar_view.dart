import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'task_manager.dart';

class CalendarView extends StatefulWidget {
  final List<Task> tasks;
  final Function(String, String, DateTime)? onAddTask;

  const CalendarView({super.key, required this.tasks, this.onAddTask});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Removed local _glassDecoration, using AppTheme.premiumDecoration

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 800;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 18 : 36,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 18),

          if (isMobile) ...[
            _buildCalendarCard(isMobile),
            const SizedBox(height: 18),
            _buildTasksForSelectedDate(isMobile),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: _buildCalendarCard(isMobile)),
                const SizedBox(width: 20),
                Expanded(flex: 5, child: _buildTasksForSelectedDate(isMobile)),
              ],
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
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
                  'Smart ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: context.themeTextPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const Text(
                  'Calendar',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFF08A82),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Manage your schedule & daily agenda',
              style: TextStyle(
                color: context.themeTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        InkWell(
          onTap: _showAddEventDialog,
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
                Icon(Icons.add_rounded, color: Colors.white, size: 18),
                SizedBox(width: 4),
                Text(
                  'New Event',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarCard(bool isMobile) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.themeCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeTextPrimary.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(anim), child: child)),
                child: Text(
                  '${months[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                  key: ValueKey<String>('${_focusedMonth.month}${_focusedMonth.year}'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.themeTextPrimary, letterSpacing: -0.3),
                ),
              ),
              Row(
                children: [
                  _buildNavButton(Icons.chevron_left_rounded, () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1))),
                  const SizedBox(width: 8),
                  _buildNavButton(Icons.chevron_right_rounded, () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildDaysOfWeek(isMobile),
          const SizedBox(height: 12),
          _buildCalendarGrid(isMobile),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.themeTextPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.themeTextPrimary.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: context.themeTextPrimary, size: 20),
      ),
    );
  }

  Widget _buildDaysOfWeek(bool isMobile) {
    final days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((day) => Expanded(
        child: Center(
          child: Text(day, style: TextStyle(color: AppColors.iconGrey.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarGrid(bool isMobile) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday % 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: isMobile ? 8 : 12,
        crossAxisSpacing: isMobile ? 8 : 12,
        childAspectRatio: 1,
      ),
      itemCount: 42,
      itemBuilder: (context, index) {
        final day = index - startingWeekday + 1;
        if (day < 1 || day > daysInMonth) return const SizedBox();

        final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
        final dateStr = _formatDate(date);

        final dayTasks = widget.tasks.where((t) {
          try {
            final parts = t.dueDate.split('-');
            if (parts.length == 3) {
              final taskDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
              return _formatDate(taskDate) == dateStr;
            }
          } catch (_) {}
          return t.dueDate == dateStr;
        }).toList();

        final isSelected = _selectedDate.year == date.year && _selectedDate.month == date.month && _selectedDate.day == date.day;
        final today = DateTime.now();
        final isToday = today.year == date.year && today.month == date.month && today.day == date.day;

        return GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                  : null,
              color: !isSelected && isToday ? context.themeTextPrimary.withValues(alpha: 0.05) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.transparent : (isToday ? AppColors.accentBlue.withValues(alpha: 0.5) : Colors.transparent),
                width: isToday && !isSelected ? 1.5 : 0,
              ),
              boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))] : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    color: isSelected ? context.themeTextPrimary : (isToday ? AppColors.accentBlue : context.themeTextPrimary.withValues(alpha: 0.8)),
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: (isSelected || isToday) ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
                if (dayTasks.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isSelected ? context.themeTextPrimary : Colors.amberAccent,
                      shape: BoxShape.circle,
                      boxShadow: [if (!isSelected) BoxShadow(color: Colors.amberAccent.withValues(alpha: 0.6), blurRadius: 4)],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTasksForSelectedDate(bool isMobile) {
    final dateStr = _formatDate(_selectedDate);
    final dayTasks = widget.tasks.where((t) {
      try {
        final parts = t.dueDate.split('-');
        if (parts.length == 3) {
          final taskDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          return _formatDate(taskDate) == dateStr;
        }
      } catch (_) {}
      return t.dueDate == dateStr;
    }).toList();

    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: AppTheme.premiumDecoration(context: context, radius: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.event_note_rounded, color: Color(0xFF8B5CF6), size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Daily Itinerary", style: TextStyle(color: AppColors.iconGrey, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  Text(
                    "${_selectedDate.day} ${_focusedMonth.month == _selectedDate.month ? 'This Month' : '${_selectedDate.month}/${_selectedDate.year}'}",
                    style: TextStyle(fontSize: isMobile ? 20 : 22, fontWeight: FontWeight.w900, color: context.themeTextPrimary, letterSpacing: -0.5),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          dayTasks.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.event_available_rounded, size: 56, color: context.themeTextPrimary.withValues(alpha: 0.05)),
                  const SizedBox(height: 16),
                  Text("No events scheduled", style: TextStyle(color: context.themeTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text("Enjoy your free time!", style: TextStyle(color: AppColors.iconGrey, fontSize: 13)),
                ],
              ),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dayTasks.length,
            itemBuilder: (context, index) {
              final task = dayTasks[index];
              final pColor = task.priority == 'High' ? Colors.redAccent : (task.priority == 'Medium' ? Colors.amberAccent : Colors.lightBlueAccent);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.themeTextPrimary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.themeTextPrimary.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 32,
                      decoration: BoxDecoration(
                        color: pColor,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [BoxShadow(color: pColor.withValues(alpha: 0.4), blurRadius: 8)],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: task.isCompleted ? context.themeTextPrimary.withValues(alpha: 0.3) : context.themeTextPrimary,
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('${task.priority} Priority', style: TextStyle(color: pColor.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    if (task.isCompleted)
                      Container(
                          padding: const EdgeInsets.all(6),
                          // FIX: Used custom hex color instead of Colors.emerald
                          decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 16)
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog() {
    String title = '';
    String priority = 'Medium';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Event',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              padding: const EdgeInsets.all(32),
              decoration: AppTheme.premiumDecoration(context: context, radius: 32, isElevated: true),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Event', style: TextStyle(color: context.themeTextPrimary, fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    Text('Scheduled for ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: TextStyle(color: AppColors.accentBlue.withValues(alpha: 0.8), fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 32),
                    TextField(
                      onChanged: (value) => title = value,
                      style: TextStyle(color: context.themeTextPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'What needs to be done?',
                        hintStyle: TextStyle(color: context.themeTextPrimary.withValues(alpha: 0.2)),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.2),
                        contentPadding: const EdgeInsets.all(20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.accentBlue, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text('PRIORITY LEVEL', style: TextStyle(color: AppColors.iconGrey, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    Row(
                      children: ['Low', 'Medium', 'High'].map((p) {
                        final isSel = priority == p;
                        Color pColor = p == 'High' ? Colors.redAccent : (p == 'Medium' ? Colors.amberAccent : Colors.lightBlueAccent);

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkWell(
                              onTap: () => setDialogState(() => priority = p),
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSel ? pColor.withValues(alpha: 0.15) : context.themeTextPrimary.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isSel ? pColor : Colors.transparent),
                                ),
                                alignment: Alignment.center,
                                child: Text(p, style: TextStyle(color: isSel ? pColor : context.themeTextPrimary.withValues(alpha: 0.54), fontWeight: FontWeight.w800, fontSize: 13)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(color: AppColors.iconGrey, fontWeight: FontWeight.bold))
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (title.trim().isNotEmpty) {
                              widget.onAddTask?.call(title, priority, _selectedDate);
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentBlue,
                            foregroundColor: context.themeTextPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Add to Schedule', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }
}