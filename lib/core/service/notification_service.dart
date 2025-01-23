import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../firebase_options.dart';
import '../utils/logger.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

@pragma('vm:entry-point')
class NotificationService {
  factory NotificationService() => _singleton;
  static final NotificationService _singleton = NotificationService._internal();

  NotificationService._internal() {
    _initialize();
  }

  int id = 0;
  static final StreamController<ReceivedNotification> didReceiveLocalNotificationStream =
      StreamController<ReceivedNotification>.broadcast();
  static final StreamController<String?> selectNotificationStream =
      StreamController<String?>.broadcast();

  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'new_channel_id',
    "channel_name_new",
    description: "This channel is used important notification",
    groupId: "com.test.alert",
    importance: Importance.max,
  );

  static final AndroidNotificationDetails _androidNotificationDetails = AndroidNotificationDetails(
    _channel.id,
    _channel.name,
    channelDescription: _channel.description,
    importance: _channel.importance,
    priority: Priority.max,
    ticker: 'ticker',
    autoCancel: false,
    color: const Color(0x00000000),
  );

  static const DarwinNotificationDetails _darwinNotificationDetails = DarwinNotificationDetails();

  static final NotificationDetails _notificationDetails = NotificationDetails(
    android: _androidNotificationDetails,
    iOS: _darwinNotificationDetails,
  );

  static Future<void> get cancelAllNotification async =>
      await _flutterLocalNotificationsPlugin.cancelAll();

  static Future<void> cancelIdNotification(int id) async =>
      await _flutterLocalNotificationsPlugin.cancel(id);

  static const InitializationSettings _initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    // android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );

  static Future<void> _initialize() async {
    requestNotificationsPermission();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // FirebaseCrashlytics.instance.recordError('onMessage.RemoteMessage=> $message', null);
      logger.e('RemoteMessage ${message.data}');

      if (message.notification != null) {
        NotificationService().showNotification(
          title: message.notification?.title ?? 'Null',
          body: message.notification?.body,
        );
      }
    });

    tz.initializeTimeZones();
    await _flutterLocalNotificationsPlugin.initialize(
      _initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  Future<void> showNotification({String? title = '', String? body = '', String? payload}) async {
    try {
      await _flutterLocalNotificationsPlugin.show(
        id++,
        title,
        body,
        _notificationDetails,
        payload: payload,
      );
    } catch (e) {
      logger.e(e);
    }
  }

  Future<void> scheduleNotification({
    String title = 'scheduleNotification',
    String? body = '',
    required DateTime dateTime,
  }) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      666,
      title,
      body,
      _nextInstanceOfNotificationTime(dateTime),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  tz.TZDateTime _nextInstanceOfNotificationTime(DateTime dateTime) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static void requestNotificationsPermission() {
    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  @pragma('vm:entry-point')
  static void _onDidReceiveNotificationResponse(NotificationResponse notificationResponse) {
    switch (notificationResponse.notificationResponseType) {
      case NotificationResponseType.selectedNotification:
        selectNotificationStream.add(notificationResponse.payload);
        break;
      case NotificationResponseType.selectedNotificationAction:
        if (notificationResponse.actionId == 'id_1') {
          selectNotificationStream.add(notificationResponse.payload);
        }
        break;
    }
  }
}

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}
