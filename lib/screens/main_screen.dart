import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import 'monitoring_screen.dart';
import 'medicine_screen.dart';
import 'alert_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  Timer? _timer; // 用于定期检查服务器

  static final List<Widget> _pages = <Widget>[
    HomeScreen(),
    MonitoringScreen(),
    MedicineScreen(),
    AlertScreen(
      imageUrl: '',
      alertMessage: '',
    ), // 这里的 AlertScreen 只是占位符，实际跳转时会动态传参
  ];

  @override
  void initState() {
    super.initState();
    // 每 10 秒轮询服务器，检查跌倒警报
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      _checkFallAlert();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 组件销毁时，停止定时器
    super.dispose();
  }

  // 轮询服务器，获取跌倒警报信息
  Future<void> _checkFallAlert() async {
    try {
      final response = await http.get(
        Uri.parse('https://your-server.com/get_fall_alert'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['fall_detected']) {
          String imageUrl = data['image_url'];
          String alertMessage = "检测到老人跌倒，请及时查看！";

          // 跳转到跌倒警报页面
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
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
