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
  bool _isAlertActive = false; // 用于控制请求的标志

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
    _startCheckingFallAlert();
  }

  void initNotifications() {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _navigateToAlertScreen('', '检测到老人跌倒，请查看');
      },
    );
  }

  void _startCheckingFallAlert() {
    _timer?.cancel(); // 确保不重复创建定时任务
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (!_isAlertActive) {
        _checkFallAlert();
      }
    });
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
      if (response.statusCode == 200 && response.data['fall_detected']) {
        setState(() {
          _isAlertActive = true; // 停止后续请求
        });
        String imageUrl = response.data['image_url'];
        _showFallAlert("检测到老人跌倒，请及时查看！");
        _navigateToAlertScreen(imageUrl, "检测到老人跌倒，请及时查看！");
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

  void _navigateToAlertScreen(String imageUrl, String alertMessage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                AlertScreen(imageUrl: imageUrl, alertMessage: alertMessage),
      ),
    ).then((_) {
      // 当警报界面关闭时，恢复定时请求
      setState(() {
        _isAlertActive = false;
        _selectedIndex = 0; // 返回首页
      });
      _startCheckingFallAlert();
    });
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      _checkFallAlertAndNavigate();
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
      if (response.statusCode == 200 && response.data['fall_detected']) {
        setState(() {
          _isAlertActive = true;
        });
        String imageUrl = response.data['image_url'];
        _showFallAlert("检测到老人跌倒，请及时查看！");
        _navigateToAlertScreen(imageUrl, "检测到老人跌倒，请及时查看！");
        return;
      }
    } catch (e) {
      print("请求失败：$e");
    }
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
