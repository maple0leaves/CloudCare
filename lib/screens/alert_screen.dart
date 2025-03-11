import 'package:flutter/material.dart';

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
  @override
  void initState() {
    super.initState();
    // **移除 _showFallAlert()，防止进入此页面就触发通知**
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
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('关闭警报', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
