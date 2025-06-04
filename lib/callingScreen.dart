import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:video_call/constants.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallingScreen extends StatefulWidget {
  const CallingScreen({super.key, required this.callID});

  final String callID;

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  final userID = Random().nextInt(10000);
  String callStatus = "Connecting...";
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _initializeFirebaseMessaging();
    _statusTimer = Timer(Duration(seconds: 3), () {
      setState(() {
        callStatus = "Connected to user";
      });
    });
    sendCallNotification();
  }

  void _initializeFirebaseMessaging() async {
    await FirebaseMessaging.instance.requestPermission();
  }

  void sendCallNotification() async {
    final calleeToken =
        await getCalleeFcmToken(); // Implement this appropriately
    final response = await http.post(
      Uri.parse('https://your-backend.com/send-notification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': calleeToken,
        'title': 'Incoming Video Call',
        'body': 'User user_name_$userID is calling you.',
        'data': {
          'callID': widget.callID,
          'callerID': userID.toString(),
          'callerName': 'user_name_$userID',
        }
      }),
    );
    if (response.statusCode == 200) {
      debugPrint('Notification sent successfully');
    } else {
      debugPrint('Failed to send notification: ${response.body}');
    }
  }

  Future<String> getCalleeFcmToken() async {
    // Fetch this from your database/backend
    return 'TARGET_FCM_TOKEN';
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Call"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          ZegoUIKitPrebuiltCall(
            appID: AppConstants.appId,
            appSign: AppConstants.appSign,
            userID: userID.toString(),
            userName: 'user_name_$userID',
            callID: widget.callID,
            config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
              ..onOnlySelfInRoom = (context) {
                setState(() {
                  callStatus = "Waiting for the other person to join...";
                });
              }
              ..onUserJoin = (List<ZegoUIKitUser> users) {
                setState(() {
                  callStatus = "Connected with ${users.first.name}";
                });
              }
              ..onUserLeave = (List<ZegoUIKitUser> users) {
                setState(() {
                  callStatus = "${users.first.name} left the call.";
                });
              },
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                callStatus,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
