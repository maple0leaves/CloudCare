import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:myapp/services/global.dart';
import 'package:myapp/services/global.dart';

// 对话式首页（类似 ChatGPT, DeepSeek）
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> messages = [];
  final Dio _dio = Dio();
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    String userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      messages.add({'role': 'user', 'content': userMessage});
      _controller.clear();
      _isLoading = true;
    });

    try {
      Response response = await _dio.post(
        'http://120.27.203.77:8000/api/chat',
        data: {'message': userMessage, 'access_token': access_token},
      );
      // message返回的是markdown格式，需要转换
      // 流式对话生成
      if (response.data['status'] == 'success') {
        setState(() {
          messages.add({'role': 'bot', 'content': response.data['msg']});
        });
      } else {
        setState(() {
          messages.add({'role': 'bot', 'content': '服务器未能正确响应'});
        });
      }
    } catch (e) {
      setState(() {
        messages.add({'role': 'bot', 'content': '网络错误，请稍后再试'});
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('智能建议助手')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                bool isUser = message['role'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      message['content']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: '可以向我询问老人相关问题',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
