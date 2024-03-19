import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회원가입'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          TextField(
            controller: _idController,
            decoration: InputDecoration(labelText: '사용자 아이디'),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: '사용자 이름'),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: '사용자 비밀번호'),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: InputDecoration(labelText: '확인된 비밀번호'),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(labelText: '휴대폰 번호'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            child: Text('가입 완료'),
            onPressed: _signUp,
          ),
        ],
      ),
    );
  }

  Future<void> _signUp() async {
    print('Sending user data: ${_idController.text}, ${_nameController.text}, ${_phoneController.text}, ${_passwordController.text}');

    if (_passwordController.text != _confirmPasswordController.text) {
      _showDialog('가입 오류', '입력한 비밀번호가 서로 일치하지 않습니다.');
      return;
    }
    if (_idController.text.isEmpty) {
      // user_id가 비어 있는 경우, 사용자에게 알림
      _showDialog('오류', '사용자 ID를 입력해야 합니다.');
      return;
    }
    // 서버에 정보를 보내고 응답을 받는 로직
    final response = await http.post(
      Uri.parse('http://192.168.163.117/signup.php'),
      body: {
        'user_id': _idController.text,
        'name': _nameController.text,        
        'password': _passwordController.text,
        'phone': _phoneController.text,
      },
    );
    

    if (response.statusCode == 200) {
      Navigator.pop(context); // 회원가입 성공 시 이전 화면으로 돌아감
    } else {
      print('Error: ${response.statusCode}');
      _showDialog('가입 오류', '회원가입에 실패했습니다. 서버 오류가 발생했을 수 있습니다.');
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
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

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
