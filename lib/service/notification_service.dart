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

  // 🔔 [수정됨] 권한 없으면 설정창으로 '강제 이동' 시키는 함수
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // 1. 일반 알림 팝업 ("알림 보내도 돼?")
        await androidImplementation.requestNotificationsPermission();

        const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'weekly_channel_final_v4', // 채널 ID
    '주간 알림 Final V4',          // 채널 이름
    channelDescription: '매주 새로운 심리테스트 알림입니다.',
    importance: Importance.max, // ★ 중요도: 상단 배너 뜸
    priority: Priority.high,    // ★ 우선순위: 높음
    enableVibration: true,
    playSound: true,
    );
        await androidImplementation.requestExactAlarmsPermission();
      }
    }
  }

  // ⏰ 10초 뒤 알람 예약 (테스트용)
  Future<void> scheduleWeeklyNotification(bool isEnabled) async {
    if (!isEnabled) {
      await flutterLocalNotificationsPlugin.cancelAll();
      return;
    }

    // ★ 예약하기 전에 무조건 권한 체크하고 설정창으로 보냄
    await requestPermissions();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'weekly_channel_final_v4', // 채널 ID 또 변경 (확실하게!)
      '주간 알림 Final V4',
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
        '이제 진짜 울립니다! (10초 뒤)',
        _nextInstanceOfMonday8AM(),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      print("✅ 알람 예약 성공! (10초 뒤에 울림)");
    } catch (e) {
      print("🚨 알람 예약 실패: $e");
    }
  }

// 이 함수 전체를 덮어쓰세요
  tz.TZDateTime _nextInstanceOfMonday8AM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // 오늘 날짜의 '오전 8시'를 기준으로 잡음
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);

    // 1. 일단 다음 '월요일'을 찾음
    while (scheduledDate.weekday != DateTime.monday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // 2. 만약 찾은 시간이 '이미 지난 시간'이라면 (예: 오늘이 월요일 9시임)
    // -> 다음 주 월요일로 7일 미룸
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }
}