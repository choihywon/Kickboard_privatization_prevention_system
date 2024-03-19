import 'package:flutter/material.dart';

class StopUserScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('계정 정지'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '계정이 정지된 상태입니다.',
                style: TextStyle(fontSize: 24.0),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.0),
              Text(
                '자세한 사항은 고객센터에 문의해 주세요.',
                style: TextStyle(fontSize: 18.0),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
