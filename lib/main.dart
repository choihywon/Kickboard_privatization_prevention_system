import 'package:flutter/material.dart';
import 'package:google_mappp/kickboard_map.dart';
import 'package:google_mappp/login_screen.dart';
//import 'socket_manager.dart'; // SocketManager 클래스를 import 합니다.

void main() => runApp(MyApp());
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '킥보드 위치 앱',
      home: LoginScreen(onLoginSuccess: (BuildContext context, String userId) {
        // 로그인 성공 시 KickBoardMap 화면으로 네비게이트하며 userId 전달
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => KickBoardMap(userId: userId),
          ),
        );
      }),
    );
  }
}

