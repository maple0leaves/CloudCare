import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:myapp/screens/main_screen.dart';
import 'package:myapp/services/global.dart';

void main() {
  runApp(MyApp());
}

// 应用程序入口
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '登录注册示例',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: LoginScreen(), // 进入登录页面
    );
  }
}

// 登录页面
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController =
      TextEditingController(); // 手机号输入框控制器
  final TextEditingController passwordController =
      TextEditingController(); // 密码输入框控制器
  final Dio _dio = Dio(); // 用于网络请求的 Dio 实例

  // 登录方法
  Future<void> _login() async {
    String phone = phoneController.text.trim();
    String password = passwordController.text.trim();

    // 测试登录跳转
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (context) => MainScreen()), // 登录成功进入主界面
    // );

    try {
      Response response = await _dio.post(
        'http://120.27.203.77:8000/api/login',
        data: {'phone': phone, 'password': password},
      );

      if (response.data['status'] == 'success') {
        access_token = response.data['access_token'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()), // 登录成功进入主界面
        );
      } else {
        // _showError('用户名或密码错误');
      }
    } catch (e) {
      print(e);
      _showError('网络错误，请稍后再试');
    }
  }

  // 显示错误信息
  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('登录')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: '手机号',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: '密码',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text(
                '登录',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: Text('没有账号？去注册', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }
}

// 注册页面
class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController phoneController =
      TextEditingController(); // 手机号输入框控制器
  final TextEditingController passwordController =
      TextEditingController(); // 密码输入框控制器
  final Dio _dio = Dio(); // 网络请求实例

  // 注册方法
  Future<void> _register() async {
    String phone = phoneController.text.trim();
    String password = passwordController.text.trim();

    try {
      Response response = await _dio.post(
        // 'https://yourserver.com/api/register',
        'http://120.27.203.77:8000/api/register',
        data: {'phone': phone, 'password': password},
      );

      if (response.data['status'] == 'success') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.data['msg'])));
        Navigator.pop(context); // 注册成功后返回登录界面
      } else {
        _showError('注册失败，请重试');
      }
    } catch (e) {
      _showError('网络错误，请稍后再试');
    }
  }

  // 显示错误信息
  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('注册')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: '手机号',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: '密码',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text(
                '注册',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
