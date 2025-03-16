import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:dio/dio.dart';
import 'package:myapp/services/global.dart';

void main() => runApp(MonitoringApp());

class MonitoringApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '远程监控',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MonitoringScreen(),
    );
  }
}

class MonitoringScreen extends StatefulWidget {
  @override
  _MonitoringScreenState createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  VlcPlayerController? _controller;
  bool _isPlaying = false;
  String _rtspUrl = '';

  final Dio _dio = Dio(); // 实例化Dio

  @override
  void initState() {
    super.initState();
    _fetchRtspLink();
  }

  // 使用Dio发起POST请求获取RTSP流的链接
  Future<void> _fetchRtspLink() async {
    try {
      final response = await _dio.post(
        'http://120.27.203.77:8000/api/get_rtsp_link', // 替换为后端的API地址
        data: {'access_token': access_token},
      );

      if (response.data['status'] == 'success') {
        setState(() {
          _rtspUrl = response.data['rtsp_url']; // 假设后端返回的JSON中包含'rtsp_url'字段
        });
        _initPlayer();
      } else {
        _showError('获取RTSP流失败');
      }
    } catch (e) {
      _showError('请求失败: $e');
    }
  }

  // 初始化播放器
  void _initPlayer() {
    if (_rtspUrl.isEmpty) return; // 等待RTSP链接

    _controller?.dispose();
    _controller = VlcPlayerController.network(
      _rtspUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );

    setState(() {
      _isPlaying = true;
    });
  }

  // 显示错误信息
  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('远程监控')),
      body: Column(
        children: [
          // 视频播放区域
          Expanded(
            child:
                _controller != null
                    ? Center(
                      child: VlcPlayer(
                        controller: _controller!,
                        aspectRatio: 16 / 9,
                        placeholder: Center(child: CircularProgressIndicator()),
                      ),
                    )
                    : Center(child: Text('初始化中...')),
          ),

          // 控制区域
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    if (_isPlaying) {
                      _controller?.pause();
                    } else {
                      _controller?.play();
                    }
                    setState(() {
                      _isPlaying = !_isPlaying;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _fetchRtspLink,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
