import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

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

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    _controller?.dispose();

    // 初始化播放器控制器，使用固定的视频URL
    _controller = VlcPlayerController.network(
      'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );

    setState(() {
      _isPlaying = true;
    });
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
                IconButton(icon: Icon(Icons.refresh), onPressed: _initPlayer),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
