import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:myapp/services/global.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:convert'; // 导入用于解码的库

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> messages = [];
  final Dio _dio = Dio();
  bool _isLoading = false;
  int? _currentBotMessageIndex; // 当前正在更新的bot消息的索引
  final ScrollController _scrollController = ScrollController(); // 滚动控制器

  // 发送用户消息
  Future<void> _sendMessage() async {
    String userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    // 先显示用户消息并且显示加载圈
    setState(() {
      messages.add({'role': 'user', 'content': userMessage});
      _controller.clear();
      _isLoading = true;
      _currentBotMessageIndex = messages.length; // 记录当前正在显示的bot消息的位置
    });

    // 滚动到最底部
    _scrollToBottom();

    try {
      Response response = await _dio.post(
        'http://120.27.203.77:8000/api/chat',
        data: {'message': userMessage, 'access_token': access_token},
        options: Options(
          responseType: ResponseType.stream, // 告诉 Dio 使用流式响应
        ),
      );

      if (response.statusCode == 200) {
        // 获取流
        final stream = response.data.stream;

        // 用于累积数据的 StringBuffer
        StringBuffer buffer = StringBuffer();

        // 监听流式数据
        await for (var chunk in stream) {
          buffer.write(utf8.decode(chunk)); // 使用 utf8 解码字节流

          // 确保当前bot消息索引有效
          if (_currentBotMessageIndex != null &&
              _currentBotMessageIndex! < messages.length) {
            setState(() {
              messages[_currentBotMessageIndex!]['content'] =
                  buffer.toString(); // 只更新当前bot消息
            });
          } else {
            // 如果索引无效，可以添加新的 bot 消息
            setState(() {
              messages.add({'role': 'bot', 'content': buffer.toString()});
              _currentBotMessageIndex = messages.length - 1; // 更新当前索引
            });
          }

          // 滚动到最后一条消息
          _scrollToBottom();
        }
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

  // 滚动到列表底部
  void _scrollToBottom() {
    // 确保列表被滚动到最底部
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent, // 滚动到列表底部
        duration: Duration(milliseconds: 300), // 滚动持续时间
        curve: Curves.easeOut, // 滚动动画的曲线
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('智能建议助手')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // 绑定滚动控制器
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
                    child:
                        isUser
                            ? Text(
                              message['content']!,
                              style: TextStyle(color: Colors.white),
                            )
                            : MarkdownBody(data: message['content']!),
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
