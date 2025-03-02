import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// 服药提醒界面
class MedicineScreen extends StatefulWidget {
  @override
  _MedicineScreenState createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  final Dio _dio = Dio();
  final List<Map<String, dynamic>> reminders = [];
  TimeOfDay? selectedTime;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones(); // 初始化时区
    _initializeNotifications();
    _fetchReminders();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(settings);
  }

  Future<void> _fetchReminders() async {
    try {
      Response response = await _dio.get('https://yourserver.com/api/reminders');
      if (response.data['status'] == 'success') {
        setState(() {
          reminders.clear();
          reminders.addAll(List<Map<String, dynamic>>.from(response.data['reminders']));
        });
      }
    } catch (e) {
      print('获取服药提醒失败: $e');
    }
  }

  Future<void> _addReminder() async {
    if (selectedTime == null) return;
    String formattedTime = '${selectedTime!.hour}:${selectedTime!.minute}';
    try {
      Response response = await _dio.post(
        'https://yourserver.com/api/add_reminder',
        data: {'time': formattedTime},
      );
      if (response.data['status'] == 'success') {
        setState(() {
          reminders.add({'time': formattedTime});
        });
        _scheduleNotification(formattedTime);
      }
    } catch (e) {
      print('添加服药提醒失败: $e');
    }
  }

  Future<void> _scheduleNotification(String time) async {
    final List<String> parts = time.split(':');
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);
    final DateTime now = DateTime.now();
    final DateTime scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medicine_reminder_channel',
      '服药提醒',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      0,
      '服药时间到了！',
      '请按时服药，保持健康！',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // 这里是新参数
    );

  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('服药提醒')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    leading: Icon(Icons.alarm, color: Colors.blue),
                    title: Text('提醒时间: ${reminders[index]['time']}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => _selectTime(context),
                  child: Text(selectedTime == null
                      ? '选择提醒时间'
                      : '已选择: ${selectedTime!.format(context)}'),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _addReminder,
                  child: Text('添加提醒'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
