import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCPage extends StatefulWidget {
  const WebRTCPage({super.key});

  @override
  _WebRTCPageState createState() => _WebRTCPageState();
}

class _WebRTCPageState extends State<WebRTCPage> {
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  late RTCPeerConnection _pc1;
  late RTCPeerConnection _pc2;
  late MediaStream _localStream;

  @override
  void initState() {
    super.initState();
    initRenderers();
  }

  Future<void> initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  void start() async {
    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': true,
      });

      setState(() {
        _localStream = stream;
        _localRenderer.srcObject = _localStream;
      });
    } catch (e) {
      print('Error getting user media: $e');
    }
  }

  void call() async {
    final configuration = <String, dynamic>{};
    _pc1 = await createPeerConnection(configuration);
    _pc2 = await createPeerConnection(configuration);

    _localStream.getTracks().forEach((track) {
      _pc1.addTrack(track, _localStream);
    });

    _pc2.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        setState(() {
          _remoteRenderer.srcObject = event.streams[0];
        });
      }
    };

    _pc1.onIceCandidate = (candidate) async {
      await _pc2.addCandidate(candidate);
    };

    _pc2.onIceCandidate = (candidate) async {
      await _pc1.addCandidate(candidate);
    };

    final offer = await _pc1.createOffer();
    await _pc1.setLocalDescription(offer);
    await _pc2.setRemoteDescription(offer);

    final answer = await _pc2.createAnswer();
    await _pc2.setLocalDescription(answer);
    await _pc1.setRemoteDescription(answer);
  }

  void hangup() {
    _pc1.close();
    _pc2.close();
    setState(() {
      _localRenderer.srcObject = null;
      _remoteRenderer.srcObject = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebRTC Example'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: RTCVideoView(_localRenderer),
          ),
          Expanded(
            child: RTCVideoView(_remoteRenderer),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: start,
                child: Text('Start'),
              ),
              ElevatedButton(
                onPressed: call,
                child: Text('Call'),
              ),
              ElevatedButton(
                onPressed: hangup,
                child: Text('Hangup'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
