// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:webrtc_demo/firebase_options.dart';
import 'package:webrtc_demo/firebase_service/firebase_api.dart';
import 'package:webrtc_demo/views/call_e2ee_page.dart';
import 'package:webrtc_demo/views/call_page.dart';
import 'package:webrtc_demo/views/demo_e2ee.dart';
import 'package:webrtc_demo/views/webrtc_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseApi().initNotification();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebRTC Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebRTC Demo')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CallingPageE2EE(typeUser: TypeUser.caller,)),
              );
            },
            child: const Text('Start Call E2EE'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CallingPageE2EE(typeUser: TypeUser.answer,)),
              );
            },
            child: const Text('Receive Call E2EE'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CallingPage2(typeUser: TypeUser.caller,)),
              );
            },
            child: const Text('Start Call'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CallingPage2(typeUser: TypeUser.answer,)),
              );
            },
            child: const Text('Receive Call'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WebRTCPage()),
              );
            },
            child: Text('WebRTC test call'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoopBackSampleUnifiedTracks()),
              );
            },
            child: Text('LoopBackSampleUnifiedTracks'),
          ),
        ],
      ),
    );
  }
}
