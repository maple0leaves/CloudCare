import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class MonitoringScreen extends StatefulWidget {
  @override
  _MonitoringScreenState createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  late VlcPlayerController _vlcController;

  @override
  void initState() {
    super.initState();
    _vlcController = VlcPlayerController.network(
      'rtsp://admin:1@192.168.41.117:8554/live', // 替换为你的 RTSP 地址
      hwAcc: HwAcc.full, // 启用硬件加速
      autoPlay: true, // 自动播放
      options: VlcPlayerOptions(),
    );
  }

  @override
  void dispose() {
    _vlcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('远程监控')),
      body: Stack(
        children: [
          VlcPlayer(
            controller: _vlcController,
            aspectRatio: 16 / 9,
            placeholder: Center(child: CircularProgressIndicator()), // 加载时显示进度条
          ),
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.blue,
              onPressed: () => _vlcController.play(), // 重新播放
              child: Icon(Icons.play_arrow, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
