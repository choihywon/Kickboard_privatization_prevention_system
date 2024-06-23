import 'package:flutter/material.dart';
import 'package:google_mappp/kickboard_map.dart';
import 'package:google_mappp/signup_screen.dart';
import 'package:google_mappp/stop.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatelessWidget {
 // final VoidCallback onLoginSuccess; // 로그인 성공 시 호출할 콜백
  final Function(BuildContext, String) onLoginSuccess;
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

 
  LoginScreen({required this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('로그인'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
             'assets/images/kickboard.png', // 'kickboard_image.png'를 실제 파일명으로 변경해야 합니다.
              width: 200,
              height: 200,
            ),
            SizedBox(height: 48),
            TextField(
              controller: _userIdController,
              decoration: InputDecoration(
                hintText: '사용자 아이디',
                fillColor: Colors.grey[200],
                filled: true,
              ),
            ),
            SizedBox(height: 16),
            TextField(
               controller: _passwordController,
              decoration: InputDecoration(
                hintText: '비밀번호',
                fillColor: Colors.grey[200],
                filled: true,
              ),
              obscureText: true,
            ),
            SizedBox(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpScreen()),
                     ); // 회원가입 로직 구현
                    },
                    child: Text('회원가입'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _tryLogin(context), // 로그인 시도 메서드를 버튼에 연결
                    child: Text('로그인'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  
 void _tryLogin(BuildContext context) async {
  // 사용자 ID와 비밀번호 입력 확인
  final userId = _userIdController.text;
  final password = _passwordController.text;

  if (userId.isEmpty || password.isEmpty) {
    _showLoginError(context, '사용자 ID와 비밀번호를 입력해주세요.');
    return;
  }

  final response = await http.post(
    Uri.parse('http://192.168.218.117/login.php'),
    body: {
      'user_id': userId,
      'password': password,
    },
  );

  if (response.statusCode == 200) {
    final responseData = json.decode(response.body);
    if (responseData['message'] == 'Login successful') {
      String userId = _userIdController.text;
      if (responseData['status'].toLowerCase() == 'stop') {
        // 'stop' 상태일 때 StopUserScreen으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => StopUserScreen()),
        );
      } else {
        // 'active' 상태일 때 기존 로직 실행
        onLoginSuccess(context, userId);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => KickBoardMap(userId: userId),
          ),
        );
      }
    } else {
      _showLoginError(context, '로그인 실패: ${responseData['message']}');
    }
  } else {
    _showLoginError(context, '서버 오류: ${response.statusCode}');
  }
}

void _showLoginError(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('로그인 오류'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('확인'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}
}
