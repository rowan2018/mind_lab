import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final timeZoneResult = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneResult.toString()));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 초기화 설정 (여기서 true로 하면 앱 켜자마자 권한 물어봄)
    // 나중에 버튼 눌러서 물어보게 하려면 아래를 false로 바꾸고 requestPermissions()를 호출하면 됩니다.
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // 🔔 [수정 완료] 안드로이드 & iOS 모두 권한 요청하는 함수
  Future<void> requestPermissions() async {
    // 1. 안드로이드 권한 요청
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }
    }
    // 2. iOS 권한 요청 (추가됨)
    else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    }
  }

  // ⏰ 알람 예약 함수
  Future<void> scheduleWeeklyNotification(bool isEnabled) async {
    if (!isEnabled) {
      await flutterLocalNotificationsPlugin.cancelAll();
      return;
    }

    // 권한 체크 및 요청
    await requestPermissions();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'weekly_channel_final_v4', // 채널 ID
      '주간 알림 Final V4',          // 채널 이름
      channelDescription: '매주 새로운 심리테스트 알림입니다.',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        '마음쉼표 도착 💌',
        '이번 주 나를 위한 심리테스트가 도착했어요!', // 문구 수정함
        _nextInstanceOfMonday8AM(),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      print("✅ 알람 예약 성공! (다음 월요일 오전 8시)");
    } catch (e) {
      print("🚨 알람 예약 실패: $e");
    }
  }

  tz.TZDateTime _nextInstanceOfMonday8AM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);

    while (scheduledDate.weekday != DateTime.monday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }
}