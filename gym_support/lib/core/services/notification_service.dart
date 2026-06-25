import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId   = 'workout_reminders';
  static const _channelName = 'Nhắc nhở tập luyện';

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(const InitializationSettings(android: android, iOS: iOS));
    _initialized = true;
  }

  static Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  // Schedule weekly repeating reminders for each workout day.
  // Fires at 08:00 on each scheduled weekday.
  static Future<void> scheduleWorkoutReminders({
    required List<String> days,
    String planName = '',
    String focus = '',
  }) async {
    await cancelWorkoutReminders();
    if (days.isEmpty) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Nhắc nhở buổi tập theo lịch của bạn',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notifDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final body = focus.isNotEmpty
        ? focus
        : planName.isNotEmpty
            ? planName
            : 'Đừng bỏ lỡ buổi tập hôm nay!';

    for (final day in days) {
      final weekday = _dayToWeekday(day);
      if (weekday == null) continue;
      await _plugin.zonedSchedule(
        100 + weekday,
        'Hôm nay là ngày tập! 💪',
        body,
        _nextWeekday(weekday),
        notifDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  static Future<void> cancelWorkoutReminders() async {
    for (var i = 1; i <= 7; i++) {
      await _plugin.cancel(100 + i);
    }
  }

  // Show an immediate PR celebration notification.
  static Future<void> showPRNotification(String exerciseName, String value) async {
    const androidDetails = AndroidNotificationDetails(
      'pr_alerts',
      'Kỷ lục cá nhân',
      importance: Importance.max,
      priority: Priority.high,
    );
    await _plugin.show(
      0,
      '🏆 New Personal Record!',
      '$exerciseName — $value',
      const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static tz.TZDateTime _nextWeekday(int weekday, {int hour = 8}) {
    var candidate = tz.TZDateTime.now(tz.local);
    candidate = tz.TZDateTime(
        tz.local, candidate.year, candidate.month, candidate.day, hour);
    // Advance to the first future occurrence of the target weekday
    for (var i = 0; i < 8; i++) {
      if (candidate.weekday == weekday && candidate.isAfter(tz.TZDateTime.now(tz.local))) {
        return candidate;
      }
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  static int? _dayToWeekday(String day) {
    return switch (day.toLowerCase().trim()) {
      'monday'    => DateTime.monday,
      'tuesday'   => DateTime.tuesday,
      'wednesday' => DateTime.wednesday,
      'thursday'  => DateTime.thursday,
      'friday'    => DateTime.friday,
      'saturday'  => DateTime.saturday,
      'sunday'    => DateTime.sunday,
      _ => null
    };
  }
}
