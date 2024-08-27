import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

//DOC: https://firebase.google.com/docs/cloud-messaging/flutter/receive?authuser=0&hl=en

@pragma('vm:entry-point')
//NOTIFICATION WHEN APP IN BACKGROUND
Future<void> onBackgroundMessageHandleMessage(RemoteMessage? message) async {
  debugPrint('Firebase_api: _onBackgroundMessageHandleMessage');
  if (message == null) return;
  debugPrint('Payload: ${message.data}');
  debugPrint('room_id: ${message.data['room_id']}');
  debugPrint('caller_name: ${message.data['caller_name']}');
  debugPrint('uuid: ${message.data['uuid']}');
  debugPrint('has_video: ${message.data['has_video']}'); //== true
}

class FirebaseApi {
  static final FirebaseApi _instance = FirebaseApi._internal();

  factory FirebaseApi() {
    return _instance;
  }

  FirebaseApi._internal();

  final _firebaseMessaging = FirebaseMessaging.instance;
  StreamSubscription? _onMessageSubscription;
  StreamSubscription? _onMessageOpenedAppSubscription;

  //HANDLE CLICK INTO NOTIFICATION
  Future<void> _onOpenAppHandleMessage(RemoteMessage? message) async {
    debugPrint('Firebase_api: _onOpenAppHandleMessage');
    if (message == null) return;

  }

  //NOTIFICATION WHEN APP NOT RUN
  Future<void> _onInitialMessage (RemoteMessage? message) async{
    debugPrint('Firebase_api: _onInitialMessage');
    if (message == null){
      debugPrint('Firebase_api: _onInitialMessage, message null');
      return;
    }

  }

  //NOTIFICATION WHEN APP RUN
  void _onMessageHandleMessage(RemoteMessage? message) {
    debugPrint('Firebase_api: _onMessageHandleMessage');
    if (message == null) {
      debugPrint('Firebase_api: _onInitialMessage, message null');
      return;
    }
  }

  Future initPushNotifications() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.instance.getInitialMessage().then((_onInitialMessage));
    _onMessageSubscription = FirebaseMessaging.onMessage.listen(_onMessageHandleMessage);
    _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_onOpenAppHandleMessage);
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessageHandleMessage);
  }

  Future<void> initNotification() async {
    await _firebaseMessaging.requestPermission();
    AwesomeNotifications().initialize(
        null, //'resource://drawable/res_app_icon',//
        [
          NotificationChannel(
              channelKey: 'basic_channel',
              channelName: 'webRTC demo',
              channelDescription: 'webRTC demo calling',
              defaultColor: Colors.deepPurple,
              ledColor: Colors.deepPurple)
        ],
        channelGroups: [
          NotificationChannelGroup(
              channelGroupKey: 'basic_channel_group',
              channelGroupName: 'basic group')
        ],
        debug: true);
    initPushNotifications();
  }

  Future<String?> getFcmToken() async{
    return await _firebaseMessaging.getToken();
  }

  Future<void> _deleteFcmToken() async {
    await _firebaseMessaging.deleteToken();
  }

  //when logout
  void dispose(){
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    _deleteFcmToken();
  }
}
