import 'package:dart_ping/dart_ping.dart';

void pingServer() async {
  final ping = Ping('120.27.203.77', count: 4);
  ping.stream.listen((event) {
    print(event); // 输出 ping 结果
  });
}

void main() {
  pingServer();
}
// http://120.27.203.77:8000/api/register