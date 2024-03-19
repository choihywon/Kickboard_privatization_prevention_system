import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import 'package:location/location.dart';

class KickBoardMap extends StatefulWidget {
  final String userId;

   KickBoardMap({Key? key, required this.userId}) : super(key: key);
  @override
  _KickBoardMapState createState() => _KickBoardMapState();
}

enum KickboardStatus { notInUse, inUse }

class _KickBoardMapState extends State<KickBoardMap> {
  GoogleMapController? mapController;
   String? selectedKickboardId;
  LocationData? _currentLocation;
  DateTime? _startUseTime;
  Set<Marker> _markers = {};
  final LatLng _center = const LatLng(35.830660 , 128.754283);
  KickboardStatus kickboardStatus = KickboardStatus.notInUse; // 킥보드 상태 변수 추가
  bool isReservationAvailable = true; // 예약 가능 상태를 추적하는 변수를 추가
  bool isUseButtonVisible = false; // '사용하기' 버튼을 표시할지 결정하는 상태 변수
  bool isReturnButtonVisible = false;
  Location location = Location();
   String _message = '';
  @override
  void initState() {
    super.initState();
    print("Received User ID: ${widget.userId}");
    // 킥보드 마커 초기화
     initLocationService();
    //_initKickBoardMarkers();
    _getCurrentLocation(); // 현재 위치를 가져오는 함수 호출
    //connectToServer();
  }

  void _getCurrentLocation() async {
    LocationData? locationResult = await location.getLocation();
    if (locationResult != null) {
      setState(() {
        _currentLocation = locationResult;
        _updateCurrentLocationMarker();
        _moveCameraToCurrentLocation();
        _initKickBoardMarkers();
      });
    } else {
      // 위치 정보를 가져오지 못했을 때의 처리 로직을 추가하세요.
      print("Location data is not available.");
    }
  }
  void _updateCurrentLocationMarker() {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });
  }
  void _moveCameraToCurrentLocation() {
    if (mapController != null && _currentLocation != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
            zoom: 17.0,
          ),
        ),
      );
    }
  }

  void initLocationService() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    //_getCurrentLocation();
  }

  void startUseKickboard() {
    setState(() {
      _startUseTime = DateTime.now();
      isUseButtonVisible = false;
      isReturnButtonVisible = true;
    });
  }

  void connectToServer() {
  Socket.connect('192.168.163.6', 8000).then((socket) {
    print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
    listenToServer(socket);
  }).catchError((error) {
    print('Error: $error');
  });
}

void listenToServer(Socket socket) {
  socket.listen(
    (List<int> event) {
      String message = utf8.decode(event).trim();
      print('Received: $message');

      if (message == 'notuse') {
        setState(() {
          _message = 'Kickboard is not in use';
          kickboardStatus = KickboardStatus.notInUse;
        });
        print('Not in use');
        // 'notuse' 메시지를 받으면 자동으로 반납 처리
        autoReturnKickboard();
      } else {
        setState(() {
          kickboardStatus = KickboardStatus.inUse;
        });
      }
    },
    onError: (error) {
      print('Error: $error');
      socket.destroy();
    },
    onDone: () {
      print('Connection closed by server.');
      socket.destroy();
    },
  );
}

void autoReturnKickboard() async {
  // 반납 처리 코드 작성
  if (_startUseTime != null && selectedKickboardId != null) {
    DateTime endUseTime = DateTime.now();
    print('Sending data: ${widget.userId}, $selectedKickboardId, ${_startUseTime!.toIso8601String()}, ${endUseTime.toIso8601String()}');

    var response = await http.post(
      Uri.parse('http://192.168.163.117/record_kickboard_use.php'),
      body: {
        'user_id': widget.userId,
        'kickboard_id': selectedKickboardId!,
        'start_time': _startUseTime!.toIso8601String(),
        'end_time': endUseTime.toIso8601String(),
      },
    );

    if (response.statusCode == 200) {
      print('Success: ${response.body}');
    } else {
      print('Error: ${response.statusCode} - ${response.body}');
    }
  }
}



   // 더미 데이터를 사용하여 마커를 생성합니다.
  Future<void> _initKickBoardMarkers() async {
    final response = await http.get(Uri.parse('http://192.168.163.117/get_kickboard.php'));
    if (response.statusCode == 200) {
      List<dynamic> kickBoardList = json.decode(response.body);

      setState(() {
        _markers.clear(); // 기존 마커를 클리어하고 새로운 마커를 추가합니다.

        for (var kickBoard in kickBoardList) {
          final markerId = 'kickboard_${kickBoard['kickboard_id']}';
          final position = LatLng(
          double.parse(kickBoard['latitude']),
          double.parse(kickBoard['longitude']),
          );
          _markers.add(
            Marker(
              markerId: MarkerId(markerId),
              //markerId: MarkerId('kickboard_${kickBoard['kickboard_id']}'),
              //position: kickBoard['position'] as LatLng, // LatLng 객체를 여기에 할당합니다.
              position: position,
              onTap: () {
                  selectedKickboardId = kickBoard['kickboard_id'];
//                selectedKickboardId = kickBoard['id'] as String?; // 사용자가 마커를 탭하면 선택된 킥보드 ID를 저장합니다.
                _showReservationSheet(context, kickBoard);
              },
              icon: BitmapDescriptor.defaultMarker,
            ),
          );
          print('Marker added: $markerId'); // 디버깅 메시지
        }
      });
    } else {
      print('Failed to load kickboard data: ${response.statusCode}');
    }
  }
  
  


  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveCameraToMarker(_center); // 맵 컨트롤러가 생성될 때 카메라를 마커 위치로 이동
  }

  void _moveCameraToMarker(LatLng? markerPosition) {
    if (markerPosition != null && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: markerPosition,
            zoom: 17.0,
          ),
        ),
      );
    }
  }
  Future<void> _sendKickboardStatusUpdate(String userId, String kickboardId, String newStatus) async {
    print('Sending status update to server...');
    var url = Uri.parse('http://192.168.163.117/update_kickboard_status.php');
    var response = await http.post(
      url,
      body: {
        'user_id': userId,
        'kickboard_id': kickboardId,
        'new_status': newStatus,
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
  }
  

  Future<void> returnKickboard() async {
  if (_startUseTime == null || selectedKickboardId == null) {
    print("Error: No start time or kickboard ID.");
    return;
  }

  DateTime endUseTime = DateTime.now();
  print('Sending data: ${widget.userId}, $selectedKickboardId, ${_startUseTime!.toIso8601String()}, ${endUseTime.toIso8601String()}');
    
  var response = await http.post(
        Uri.parse('http://192.168.163.117/record_kickboard_use.php'),
        body: {
            'user_id': widget.userId,
            'kickboard_id': selectedKickboardId!,
            'start_time': _startUseTime!.toIso8601String(),
            'end_time': endUseTime.toIso8601String(),
        },
    );

    if (response.statusCode == 200) {
    print('Success: ${response.body}');
    setState(() {
      // 반납 처리가 완료되면 메시지를 비웁니다.
      _message = '';
      // 필요한 추가 상태 업데이트가 있으면 여기에 추가합니다.
    });
  } else {
    print('Error: ${response.statusCode} - ${response.body}');
  }
}


  Future<String> getUserStatus(String userId) async {
    try {
      final response = await http.get(Uri.parse('http://192.168.163.117/send_rapsberrypi.php?user_id=$userId'));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        return data['status'];
      } else {
        print('Server error: ${response.statusCode}');
        throw Exception('Failed to load user status');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  Future<void> _startSocketCommunication() async {
    Socket? _socket;
    var _status;
    try {
      // 서버에 연결
      _socket = await Socket.connect('192.168.35.107', 9994);
      setState(() {
        _status = 'Connected';
      });

      // 서버로부터 데이터 수신
      _socket!.listen(
        (List<int> data) {
          print(String.fromCharCodes(data).trim());
        },
      
      );
    } catch (e) {
      print("Socket connection error: $e");
      setState(() {
        _status = 'Connection Failed';
      });
    }
  }

  Future<void> sendStopSignalToRaspberryIfStopped() async {
    try {
      String status = await getUserStatus(widget.userId);
      if (status == 'stop') {
        await sendStopSignalToRaspberry();
      }
    } catch (e) {
      print('Error sending stop signal to Raspberry Pi: $e');
    }
  }
  

  Future<void> sendStopSignalToRaspberry() async {
    Socket? socket;
    try {
      socket = await Socket.connect('192.168.163.6', 8000, timeout: Duration(seconds: 5));
      socket.write('stop'); // 'stop' 메시지 전송
      print('Stop signal sent to Raspberry Pi');

      // Raspberry Pi로부터의 응답을 기다립니다.
      socket.listen(
        (List<int> data) {
          String response = String.fromCharCodes(data).trim();
          print('Response from Raspberry Pi: $response');
        },
        onDone: () {
          print('Socket is closed');
          socket?.close(); // 소켓 연결 종료
        },
        onError: (error) {
          print('Socket error: $error');
          socket?.close(); // 에러 발생 시 소켓 닫기
        },
      );
    } catch (e) {
      print('Error sending stop signal to Raspberry Pi: $e');
      socket?.close(); // 예외 발생 시 소켓 닫기
    }
  }



  Future<void> sendWarningSignalToRaspberryIfWarning() async {
    try {
      String status = await getUserStatus(widget.userId);
      if (status == 'warning') {
        await sendWarningSignalToRaspberry();
      }
    } catch (e) {
      print('Error sending warning signal to Raspberry Pi: $e');
    }
  }

  Future<void> sendWarningSignalToRaspberry() async {
    Socket socket;
    try {
      socket = await Socket.connect('192.168.163.6', 8000, timeout: Duration(seconds: 5));
      socket.write('warning');
      print('Warning signal sent to Raspberry Pi');

      await socket.flush();
      await socket.close();
    } catch (e) {

      print('Error sending warning signal to Raspberry Pi: $e');
    }
  }



  Future<void> sendReservationToRaspberry(String ipAddress, int port, int reservationNumber) async {
    try {
      final socket = await Socket.connect(ipAddress, port, timeout: Duration(seconds: 5));
      socket.write(reservationNumber.toString());
      print('Reservation sent: $reservationNumber');
      await socket.flush();
      await socket.close();
    } catch (e) {
      print('Error sending reservation: $e');
    }
  }

  Future<void> _sendUseSignalToRaspberry(String ipAddress, int port) async {
    try {
      final socket = await Socket.connect(ipAddress, port, timeout: Duration(seconds: 5));
      socket.write('3'); // '3'을 전송
      print('Use signal sent');
      await socket.flush();
      await socket.close();
    } catch (e) {
      print('Error sending use signal: $e');
    }
  }

  Future<void> _sendReturnSignalToRaspberry(String ipAddress, int port) async {
    try {
      final socket = await Socket.connect(ipAddress, port, timeout: Duration(seconds: 5));
      socket.write('4'); // '4'를 전송 (반납 신호)
      print('Return signal sent');
      await socket.flush();
      await socket.close();
    } catch (e) {
      print('Error sending return signal: $e');
    }
  }

  Future<void> _sendReservationToServer(String userId, String kickboardId) async {
    try {
      var response = await http.post(
        Uri.parse('http://192.168.163.117/reservation.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'user_id': userId,
          'kickboard_id': kickboardId,
        },
      );
      if (response.statusCode == 200) {
        print('Reservation successful');
      } else {
        print('Reservation failed: ${response.body}');
        print('Failed to send data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending reservation: $e');
    }
  }


  Future<void> _showReservationSheet(BuildContext context, Map<String, dynamic> kickBoard) async {
    double distance = await getDistanceBetween(
      _currentLocation!.latitude!,
      _currentLocation!.longitude!,
      double.parse(kickBoard['latitude']),
      double.parse(kickBoard['longitude']),
    );

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.5,
          child: Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                const Text('킥보드 예약', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('킥보드 ID: ${kickBoard['kickboard_id']}'),
                Text('거리: ${distance.toStringAsFixed(2)}m'),
                ElevatedButton(
                  child: Text('예약 확정하기'),
                  onPressed: isReservationAvailable ? () async {
                    String kickboardId = kickBoard['kickboard_id'] ?? '';

                    if (widget.userId.isEmpty || kickboardId.isEmpty) {
                      print("Error: Missing user_id or kickboard_id");
                      _showErrorDialog(context, "Missing user_id or kickboard_id");
                      return;
                    }

                    await _sendReservationToServer(widget.userId, kickboardId);
                    _showReservationCompleteDialog(context);
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return Center(child: CircularProgressIndicator());
                      },
                    );

                    try {
                      await sendReservationToRaspberry('192.168.163.6', 8000, 2);
                      Navigator.of(context).pop(); // 로딩 인디케이터 제거
                      _moveCameraToMarker(LatLng(double.parse(kickBoard['latitude']), double.parse(kickBoard['longitude'])));
                      _showReservationCompleteDialog(context);
                    } catch (e) {
                      Navigator.of(context).pop(); // 오류 시 로딩 인디케이터 제거
                      _showErrorDialog(context, e.toString());
                    }
                  } :  null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Future<double> getDistanceBetween(
      double startLatitude,
      double startLongitude,
      double endLatitude,
      double endLongitude,
  ) async {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }


  void _showReservationCompleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('예약 완료'),
          content: Text('예약이 완료됐습니다!'),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () {
                setState(() {
                  isReservationAvailable = false;
                  isUseButtonVisible = true;
                });
                Navigator.of(context).pop(); // 대화 상자 닫기
                Navigator.of(context).pop(); // 바텀 시트 닫기
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('오류 발생'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('닫기'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: Stack(
          children: <Widget>[
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 14.0,
              ),
              markers: _markers,
            ),
            if (_message == 'Kickboard is not in use')
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.red,
              child: Text('not', style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
          ),
          if (kickboardStatus == KickboardStatus.inUse) //not to use 자동반납
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton(
                onPressed: () async {
                  // 킥보드 반납 처리
                  await _sendKickboardStatusUpdate(widget.userId, selectedKickboardId!, 'active');
                  await _sendReturnSignalToRaspberry('192.168.163.6', 8000);
                  await returnKickboard();
                },
                child: Icon(Icons.undo),
                backgroundColor: Colors.green,
              ),
            ),
            if (isUseButtonVisible) // '사용하기' 버튼 조건부 표시
              Positioned(
                right: 20,
                bottom: 80,
                child: FloatingActionButton(
                  onPressed: ()  {
                    startUseKickboard(); // 사용 시작 시간 기록
                    connectToServer();
                    _sendUseSignalToRaspberry('192.168.163.6', 8000);
                    _sendKickboardStatusUpdate(widget.userId, selectedKickboardId!, 'using');
                    setState(() {
                      isUseButtonVisible = false;
                      isReturnButtonVisible = true; // 반납 버튼을 표시합니다
                    });
                  },
                  child: Icon(Icons.skateboarding),
                ),
              ),
            if (isReturnButtonVisible) // '반납하기' 버튼 조건부 표시
              Positioned(
                right: 20,
                bottom: 20,
                child: FloatingActionButton(
                  onPressed: () async {
                    await _sendKickboardStatusUpdate(widget.userId, selectedKickboardId!, 'active');
                    await _sendReturnSignalToRaspberry('192.168.163.6', 8000);
                    await returnKickboard();
                    setState(() {
                      isReturnButtonVisible = false;
                      isReservationAvailable = true;
                    });
                  },
                  child: Icon(Icons.undo),
                  backgroundColor: Colors.green,
                ),
              ),
          ],
        ),
      );
    }
}