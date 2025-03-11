import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:http/http.dart' as http;
import 'main_screen.dart';

class AlertScreen extends StatefulWidget {
  final String imageUrl; // 云端传递的图片地址
  final String alertMessage; // 云端传递的警报消息

  const AlertScreen({
    Key? key,
    required this.imageUrl,
    required this.alertMessage,
  }) : super(key: key);

  @override
  _AlertScreenState createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _showFallAlert();
  }

  // 初始化本地通知
  void _initNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  // 显示跌倒通知
  Future<void> _showFallAlert() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'fall_alert',
          '跌倒警报',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      '跌倒警报',
      widget.alertMessage,
      details,
    );

    // 震动手机提醒
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 1000);
    }
  }

  // 手动关闭警报
  void _dismissAlert() {
    flutterLocalNotificationsPlugin.cancel(0); // 取消通知

    if (Navigator.canPop(context)) {
      Navigator.pop(context); // 关闭当前页面
    } else {
      // 如果 `MainScreen` 没有运行，手动导航回 `MainScreen`
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('跌倒警报'), backgroundColor: Colors.red),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.alertMessage,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            widget.imageUrl.isNotEmpty
                ? Image.network(
                  widget.imageUrl,
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text(
                      '图片加载失败',
                      style: TextStyle(color: Colors.red),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const CircularProgressIndicator();
                  },
                )
                : const Text('无图片信息'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _dismissAlert,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('关闭警报', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
