import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'monitoring_screen.dart';
import 'medicine_screen.dart';
import 'alert_screen.dart';
import 'fall_alert_placeholder_screen.dart';
import 'package:dio/dio.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:myapp/services/global.dart';

// http返回检测到跌倒，生成FallAlertPlaceholderScreen类之后，就不发送请求
// 直到点击关闭警报返回首页又再开始发送请求

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  Timer? _timer;
  final _dio = Dio();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final List<Widget> _pages = <Widget>[
    HomeScreen(),
    MonitoringScreen(),
    MedicineScreen(),
    FallAlertPlaceholderScreen(), // 默认"跌倒警报"页面
  ];

  @override
  void initState() {
    super.initState();
    initNotifications();
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      _checkFallAlert();
    });
  }

  void initNotifications() {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    AlertScreen(imageUrl: '', alertMessage: '检测到老人跌倒，请查看'),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkFallAlert() async {
    try {
      final response = await _dio.post(
        'http://120.27.203.77:8000/api/get_fall_alert',
        data: {'access_token': access_token},
      );
      if (response.statusCode == 200) {
        if (response.data['fall_detected']) {
          String imageUrl = response.data['image_url'];
          String alertMessage = "检测到老人跌倒，请及时查看！";

          _showFallAlert(alertMessage);
          print(imageUrl);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AlertScreen(
                    imageUrl: imageUrl,
                    alertMessage: alertMessage,
                  ),
            ),
          );
        }
      } else {
        print("服务器请求失败，状态码：${response.statusCode}");
      }
    } catch (e) {
      print("请求失败：$e");
    }
  }

  Future<void> _showFallAlert(String message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'fall_alert',
          '跌倒警报',
          channelDescription: '用于跌倒警报的通知',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(0, '跌倒警报', message, details);

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 1000);
    }
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      _checkFallAlertAndNavigate(); // 处理跌倒警报
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _checkFallAlertAndNavigate() async {
    try {
      final response = await _dio.post(
        'http://120.27.203.77:8000/api/get_fall_alert',
        data: {'access_token': access_token},
      );
      if (response.statusCode == 200) {
        if (response.data['fall_detected']) {
          String imageUrl = response.data['image_url'];
          String alertMessage = "检测到老人跌倒，请及时查看！";

          _showFallAlert(alertMessage);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AlertScreen(
                    imageUrl: imageUrl,
                    alertMessage: alertMessage,
                  ),
            ),
          );
          return; // 提前结束，防止执行 setState
        }
      } else {
        print("服务器请求失败，状态码：${response.statusCode}");
      }
    } catch (e) {
      print("请求失败：$e");
    }
    // try {
    //   String imageUrl = 'image_url';
    //   String alertMessage = "检测到老人跌倒，请及时查看！";

    //   _showFallAlert(alertMessage);

    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //       builder:
    //           (context) =>
    //               AlertScreen(imageUrl: imageUrl, alertMessage: alertMessage),
    //     ),
    //   );
    //   return; // 提前结束，防止执行 setState
    // } catch (e) {
    //   print("请求失败：$e");
    // }
    // **如果没有检测到跌倒，则显示 FallAlertPlaceholderScreen**
    setState(() {
      _selectedIndex = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.videocam), label: '远程监控'),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: '服药提醒',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: '跌倒警报'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
