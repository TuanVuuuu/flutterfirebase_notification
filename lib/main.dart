import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_notification_example/api/notification_service.dart';
import 'package:flutter_notification_example/ui/home_page.dart';
import 'package:flutter_notification_example/ui/notification_page.dart';
import 'package:flutter_notification_example/utils/log_extensions.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Khai báo đối tượng FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  logDebug("Initialize Firebase");
  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize local notifications
  const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Initialize NotificationService
  final notificationService = NotificationService();
  await notificationService.initialize(navigatorKey);

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      navigatorKey: navigatorKey,
      home: const HomePage(),
      routes: {
        '/notification_screen': (context) => const NotificationPage(
              payload: '',
            ),
      },
    );
  }
}
