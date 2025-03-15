import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:myapp/services/global.dart';

Future<void> requestExactAlarmPermission() async {
  if (await Permission.scheduleExactAlarm.isDenied) {
    final AndroidIntent intent = AndroidIntent(
      action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
    );
    await intent.launch();
  }
}

// 服药提醒界面
class MedicineScreen extends StatefulWidget {
  @override
  _MedicineScreenState createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  final Dio _dio = Dio(); // 用于与服务器通信的 Dio 实例
  final List<Map<String, dynamic>> reminders = []; // 存储服药提醒的列表
  TimeOfDay? selectedTime; // 选中的服药时间
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin(); // 本地通知插件

  @override
  void initState() {
    super.initState();
    requestExactAlarmPermission(); // 请求精准定时通知权限
    tz.initializeTimeZones(); // 初始化时区
    _initializeNotifications(); // 初始化通知
    _fetchReminders(); // 获取服务器上的服药提醒
  }

  // 初始化本地通知
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(settings);

    // Android 13+ 设备请求通知权限
    if (await Permission.notification.request().isDenied) {
      print("用户未授予通知权限");
    }
  }

  // 从服务器获取服药提醒
  // 从服务器获取服药提醒
  Future<void> _fetchReminders() async {
    try {
      // Response response = await _dio.get(
      //   'http://yourserver.com/api/reminders',
      // );
      Response response = await _dio.post(
        'http://120.27.203.77:8000/api/get_reminders',
        data: {'access_token': access_token},
      );
      print(response.data);
      if (response.data['status'] == 'success') {
        setState(() {
          reminders.clear();
          reminders.addAll(
            List<Map<String, dynamic>>.from(response.data['timelist']),
          );
        });
      }
    } catch (e) {
      _showError('获取服药提醒失败: $e');
    }
  }
  // Future<void> _fetchReminders() async {
  //   await Future.delayed(Duration(seconds: 1)); // 模拟网络请求延迟
  //   setState(() {
  //     reminders.clear();
  //     reminders.addAll([
  //       {'id': 1, 'time': '08:00'},
  //       {'id': 2, 'time': '12:00'},
  //       {'id': 3, 'time': '18:00'},
  //     ]);
  //   });
  // }

  // 显示错误信息
  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // 添加新的服药提醒
  // 添加新的服药提醒，并存储到服务器
  Future<void> _addReminder() async {
    print(selectedTime);
    if (selectedTime == null) return;
    String formattedTime =
        '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
    print(formattedTime);
    try {
      // Response response = await _dio.post(
      //   'http://yourserver.com/api/add_reminder',
      //   data: {'time': formattedTime},
      // );
      Response response = await _dio.post(
        'http://120.27.203.77:8000/api/add_reminder',
        data: {'time': formattedTime, 'access_token': access_token},
      );
      print(response.data);
      if (response.data['status'] == 'success') {
        setState(() {
          reminders.add({'id': response.data['id'], 'time': formattedTime});
        });
        _scheduleNotification(response.data['id'], formattedTime); // 设置本地通知
      }
    } catch (e) {
      _showError('添加服药提醒失败: $e');
    }
  }
  // Future<void> _addReminder() async {
  //   if (selectedTime == null) return;
  //   String formattedTime = '${selectedTime!.hour}:${selectedTime!.minute}';

  //   setState(() {
  //     int newId = reminders.isEmpty ? 1 : reminders.last['id'] + 1; // 自动生成ID
  //     reminders.add({'id': newId, 'time': formattedTime});
  //   });

  //   _scheduleNotification(reminders.last['id'], formattedTime);
  //   _showError("提醒已添加，时间: $formattedTime"); // 调试信息
  // }

  // 删除服药提醒
  // 删除服药提醒
  Future<void> _deleteReminder(int id) async {
    try {
      // Response response = await _dio.post(
      //   'http://yourserver.com/api/delete_reminder',
      //   data: {'id': id},
      // );
      Response response = await _dio.post(
        'http://120.27.203.77:8000/api/delete_reminder',
        data: {'id': id, 'access_token': access_token},
      );
      if (response.data['status'] == 'success') {
        setState(() {
          reminders.removeWhere((reminder) => reminder['id'] == id);
        });
        _notificationsPlugin.cancel(id); // 取消本地通知
      }
    } catch (e) {
      _showError('删除服药提醒失败: $e');
    }
  }
  // Future<void> _deleteReminder(int id) async {
  //   setState(() {
  //     reminders.removeWhere((reminder) => reminder['id'] == id);
  //   });
  //   _notificationsPlugin.cancel(id);
  // }

  // 计划本地通知
  Future<void> _scheduleNotification(int id, String time) async {
    //time 是预设时间，scheduledTime是预设时间
    final List<String> parts = time.split(':');
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);
    final DateTime now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      0,
    );
    // // 🛠️ 如果设定的时间已过，则推迟到次日
    // if (scheduledTime.isBefore(now)) {
    //   scheduledTime = scheduledTime.add(Duration(days: 1));
    // }
    // 🛠️ 显示当前时间和预设时间进行对比（使用 SnackBar 代替 print）
    _showError("当前时间: ${now.hour}:${now.minute} | 预设时间: $hour:$minute");

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'medicine_reminder_channel',
          '服药提醒',
          importance: Importance.high,
          priority: Priority.high,
          fullScreenIntent: true,
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        '服药时间到了！',
        '请按时服药，保持健康！',
        tz.TZDateTime.from(scheduledTime, tz.local), // 使用时区处理时间,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents:
            DateTimeComponents.time, // To repeat daily at the same time
      );
      _showError("通知已成功安排在 ${hour}:${minute}");
    } catch (e) {
      _showError("安排通知出错: $e");
    }
  }

  // 选择提醒时间
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
                    title: Text(
                      '提醒时间: ${reminders[index]['time']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteReminder(reminders[index]['id']),
                    ),
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
                  child: Text(
                    selectedTime == null
                        ? '选择提醒时间'
                        : '已选择: ${selectedTime!.format(context)}',
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(onPressed: _addReminder, child: Text('添加提醒')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
