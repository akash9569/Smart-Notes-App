import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      try {
        final dynamic tzInfo = await FlutterTimezone.getLocalTimezone();
        final String tzName = tzInfo is String
            ? tzInfo
            : (tzInfo.name ?? tzInfo.identifier ?? tzInfo.toString()).toString();
        tz.setLocalLocation(tz.getLocation(tzName));
      } catch (e) {
        debugPrint('Timezone resolution error: $e');
        try {
          tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
        } catch (_) {
          tz.setLocalLocation(tz.local);
        }
      }

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification tapped: ${details.payload}');
        },
      );

      // Setup Android notification channels & permissions
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        try {
          await androidImplementation.requestExactAlarmsPermission();
        } catch (_) {}

        const AndroidNotificationChannel habitChannel =
            AndroidNotificationChannel(
          'habit_reminder_channel_v2',
          'Habit Reminders & Alerts',
          description:
              'High priority alarms for daily habit reminders and completions',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );
        await androidImplementation.createNotificationChannel(habitChannel);

        const AndroidNotificationChannel taskChannel =
            AndroidNotificationChannel(
          'task_reminder_channel_v2',
          'Task Reminders',
          description: 'Notifications for task reminders and deadlines',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );
        await androidImplementation.createNotificationChannel(taskChannel);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Notification init error: $e');
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    bool repeatsDaily = false,
  }) async {
    final now = DateTime.now();
    DateTime targetDate = scheduledDate;
    if (!targetDate.isAfter(now)) {
      if (repeatsDaily) {
        targetDate = targetDate.add(const Duration(days: 1));
      } else {
        return;
      }
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(targetDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminder_channel_v2',
            'Habit Reminders & Alerts',
            channelDescription:
                'High priority alarms for daily habit reminders and sessions',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            presentBanner: true,
            presentList: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents:
            repeatsDaily ? DateTimeComponents.time : null,
      );
    } catch (e) {
      debugPrint('Error scheduling notification $id: $e');
    }
  }

  /// Schedules all user-selected reminder intervals before the task due date & time:
  /// - '5_days': 5 days before
  /// - '24_hours': 24 hours before (1 day)
  /// - '5_hours': 5 hours before
  /// - '1_hour': 1 hour before
  /// - '30_min': 30 minutes before
  /// - '10_min': 10 minutes before
  /// - 'exact': At exact due time
  Future<void> scheduleTaskReminders({
    required int baseId,
    required String taskTitle,
    required DateTime dueDate,
    List<String>? selectedReminders,
  }) async {
    final int safeBase = baseId.abs() % 10000;

    // Cancel existing notifications for this task first
    await cancelTaskNotifications(safeBase);

    final reminders = selectedReminders ??
        [
          '5_days',
          '24_hours',
          '5_hours',
          '1_hour',
          '30_min',
          '10_min',
          'exact',
        ];

    final now = DateTime.now();

    for (final reminderKey in reminders) {
      DateTime? scheduledDate;
      String title = '';
      String body = '';
      int subId = 0;

      switch (reminderKey) {
        case '5_days':
          scheduledDate = dueDate.subtract(const Duration(days: 5));
          title = '📅 Task in 5 Days';
          body = '"$taskTitle" is scheduled in 5 days.';
          subId = 1;
          break;
        case '24_hours':
          scheduledDate = dueDate.subtract(const Duration(hours: 24));
          title = '⏰ Task Tomorrow (24h)';
          body = '"$taskTitle" is due in 24 hours.';
          subId = 2;
          break;
        case '5_hours':
          scheduledDate = dueDate.subtract(const Duration(hours: 5));
          title = '⏳ Task in 5 Hours';
          body = '"$taskTitle" is due in 5 hours.';
          subId = 3;
          break;
        case '1_hour':
          scheduledDate = dueDate.subtract(const Duration(hours: 1));
          title = '⏰ Task Reminder (1 hour)';
          body = '"$taskTitle" is due in 1 hour. Get ready!';
          subId = 4;
          break;
        case '30_min':
          scheduledDate = dueDate.subtract(const Duration(minutes: 30));
          title = '⚡ Task Reminder (30 min)';
          body = '"$taskTitle" is due in 30 minutes!';
          subId = 5;
          break;
        case '10_min':
          scheduledDate = dueDate.subtract(const Duration(minutes: 10));
          title = '🔔 Task Starting Soon (10 min)';
          body = '"$taskTitle" starts in 10 minutes. Time to focus!';
          subId = 6;
          break;
        case 'exact':
          scheduledDate = dueDate;
          title = '🚨 Task Due Right Now';
          body = '"$taskTitle" is due now!';
          subId = 7;
          break;
      }

      if (scheduledDate != null && scheduledDate.isAfter(now)) {
        await scheduleNotification(
          id: safeBase * 10 + subId,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
        );
      }
    }
  }

  Future<void> cancelTaskNotifications(int baseId) async {
    final int safeBase = baseId.abs() % 10000;
    for (int i = 1; i <= 7; i++) {
      try {
        await _notificationsPlugin.cancel(safeBase * 10 + i);
      } catch (_) {}
    }
  }

  /// Parses "08:00 AM", "8:30 PM", "20:00", etc. into (hour, minute)
  Map<String, int> _parseTime(String timeOfDayStr) {
    int hour = 8;
    int minute = 0;
    try {
      final clean = timeOfDayStr.trim().toUpperCase();
      final isPM = clean.contains('PM');
      final isAM = clean.contains('AM');
      final digits = clean.replaceAll(RegExp(r'[^0-9:]'), '');
      final parts = digits.split(':');
      if (parts.isNotEmpty) {
        int h = int.parse(parts[0]);
        int m = parts.length > 1 ? int.parse(parts[1]) : 0;
        if (isPM && h < 12) h += 12;
        if (isAM && h == 12) h = 0;
        hour = h.clamp(0, 23);
        minute = m.clamp(0, 59);
      }
    } catch (_) {}
    return {'hour': hour, 'minute': minute};
  }

  /// Automatically schedules all 4 notifications for a habit:
  /// 1. 5 min before start (Preparation)
  /// 2. At start time (Begin session)
  /// 3. 5 min before complete (Based on session duration)
  /// 4. At session completion (Mark done)
  ///
  /// Uses matchDateTimeComponents: DateTimeComponents.time and
  /// exactAllowWhileIdle so notifications fire every day whether the
  /// app is open, in the background, or completely closed.
  Future<void> scheduleHabitReminders({
    required int baseId,
    required String habitName,
    required String timeOfDayStr,
    int durationMinutes = 30,
    List<String>? selectedReminders,
  }) async {
    final int safeBase = (baseId.abs() % 10000) + 50000;

    // Cancel existing notifications for this habit first
    await cancelHabitNotifications(baseId);

    final parsed = _parseTime(timeOfDayStr);
    final now = DateTime.now();

    // Start time baseline for today
    final startDt =
        DateTime(now.year, now.month, now.day, parsed['hour']!, parsed['minute']!);
    // Completion time baseline for today
    final endDt = startDt.add(Duration(minutes: durationMinutes));

    final int beforeCompleteOffset = durationMinutes > 10 ? 5 : (durationMinutes > 4 ? 2 : 1);
    final beforeCompleteTime = endDt.subtract(Duration(minutes: beforeCompleteOffset));

    final items = <Map<String, dynamic>>[
      {
        'subId': 1,
        'title': '⏰ Starting in 5 Min: $habitName',
        'body': 'Get ready! "$habitName" starts in 5 minutes.',
        'time': startDt.subtract(const Duration(minutes: 5)),
      },
      {
        'subId': 2,
        'title': '🔥 Habit Time: $habitName',
        'body':
            'It\'s time for "$habitName"! Time to spend $durationMinutes min and keep your streak alive.',
        'time': startDt,
      },
      {
        'subId': 3,
        'title': '⏳ $beforeCompleteOffset Min Remaining: $habitName',
        'body':
            'Almost done! You have $beforeCompleteOffset minutes left in your session for "$habitName". Finish strong! 💪',
        'time': beforeCompleteTime,
      },
      {
        'subId': 4,
        'title': '🎉 Habit Session Complete: $habitName',
        'body':
            'Awesome work! You completed $durationMinutes min for "$habitName". Don\'t forget to mark it done!',
        'time': endDt,
      },
    ];

    for (final item in items) {
      final DateTime scheduledTime = item['time'] as DateTime;
      final int subId = item['subId'] as int;
      final String title = item['title'] as String;
      final String body = item['body'] as String;

      await scheduleNotification(
        id: safeBase * 10 + subId,
        title: title,
        body: body,
        scheduledDate: scheduledTime,
        repeatsDaily: true,
      );
    }
  }

  Future<void> cancelHabitNotifications(int baseId) async {
    final int safeBase = (baseId.abs() % 10000) + 50000;
    for (int i = 1; i <= 6; i++) {
      try {
        await _notificationsPlugin.cancel(safeBase * 10 + i);
      } catch (_) {}
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (_) {}
  }
}