import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_notification_example/main.dart';
import 'package:flutter_notification_example/ui/notification_page.dart';
import 'package:flutter_notification_example/utils/log_extensions.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Sử dụng Singleton Pattern để đảm bảo chỉ một instance được tạo ra
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    await _requestPermissionNotification();
    await _getTokenFirebase();
    await _createNotificationChannel();
    _setupNotificationHandlers(navigatorKey);

    // Khởi tạo Flutter Local Notifications và xử lý sự kiện bấm vào thông báo
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          logDebug(
            _notificationResponseToJson(response), // Chuyển đổi thành Map rồi in ra
            header: 'Event Click Push Notification',
          );
          // Điều hướng đến màn hình thông báo và truyền thông tin từ payload
          _handleMessage(navigatorKey, response.payload);
        }
      },
    );
  }

  /// Thêm hàm đăng ký vào topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      logDebug('Đã đăng ký vào topic: $topic', header: 'Subscribe Topic');
    } catch (e) {
      logDebug('Lỗi khi đăng ký vào topic: $topic - $e', header: 'Subscribe Topic');
    }
  }

  /// Yêu cầu quyền nhận thông báo từ người dùng
  Future<void> _requestPermissionNotification() async {
    await _firebaseMessaging.requestPermission();
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Hàm Lấy token FCM để phục vụ cho việc debug hoặc analytics
  Future<void> _getTokenFirebase() async {
    final fcmToken = await _firebaseMessaging.getToken();
    logDebug('$fcmToken', header: 'Firebase Messaging Token');
    subscribeToTopic('all_users');
  }

  /// Xử lý thông báo khi ứng dụng đang hoạt động (foreground)
  void handleFirebaseMessagingInForeGround() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logDebug(message.toMap(), header: 'Firebase messaging in foreground');
      _showLocalNotification(message);
    });
  }

  /// Xử lý thông báo khi ứng dụng bị tắt (terminated)
  void handleFirebaseMessagingInTerminated() {
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      logDebug(message?.toMap(), header: 'Firebase messaging in terminated');
      if (message != null) {
        _handleMessage(navigatorKey, message.data['id']); // Gọi đến payload 'id'
      }
    });
  }

  /// Xử lý thông báo khi ứng dụng ở chế độ nền (background)
  void handleFirebaseMessagingInBackground() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logDebug(message.toMap(), header: 'Firebase messaging background');
      // Truyền payload nếu có khi ứng dụng ở chế độ background
      _handleMessage(navigatorKey, message.data['id']); // Gọi đến payload 'id'
    });
  }

  /// đăng ký một callback để xử lý thông báo khi ứng dụng của bạn đang chạy trong background hoặc bị tắt (terminated).
  void registerCallBackInBackground() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Thiết lập các handler xử lý thông báo
  void _setupNotificationHandlers(GlobalKey<NavigatorState> navigatorKey) {
    registerCallBackInBackground();
    handleFirebaseMessagingInForeGround();
    handleFirebaseMessagingInBackground();
    handleFirebaseMessagingInTerminated();
  }

  /// Khởi tạo Notification Channel
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'channel_id', // ID kênh thông báo
      'channel_name', // Tên kênh
      description: 'Description of the channel',
      importance: Importance.high,
      playSound: true,
    );

    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  /// Hiển thị thông báo local
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      channelDescription: 'Description of the channel',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    // Hiển thị thông báo và thêm payload
    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformDetails,
      payload: message.data['id'], // Lấy thông tin id từ message.data và truyền vào payload
    );
  }

  /// Điều hướng đến màn hình thông báo và truyền dữ liệu từ payload
  void _handleMessage(GlobalKey<NavigatorState> navigatorKey, String? payload) {
    // Nếu payload có giá trị, điều hướng đến màn hình NotificationPage và truyền payload
    if (payload != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => NotificationPage(payload: payload),
        ),
      );
    }
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  logDebug(message.toMap(), header: "Firebase Messaging Background Handler");
}

Map<String, dynamic> _notificationResponseToJson(NotificationResponse response) {
  return {
    'actionId': response.actionId,
    'id': response.id,
    'input': response.input,
    'notificationResponseType': response.notificationResponseType.toString(),
    'payload': response.payload,
  };
}
