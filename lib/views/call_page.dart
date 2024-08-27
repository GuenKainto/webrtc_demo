import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_demo/firebase_service/signaling_manager.dart';

enum TypeUser {caller, answer}

class CallingPage2 extends HookWidget {
  const CallingPage2({super.key, required this.typeUser});

  final TypeUser typeUser;

  @override
  Widget build(BuildContext context) {
    final peerConnection = useState<RTCPeerConnection?>(null);
    final localStream = useState<MediaStream?>(null);
    final remoteStream = useState<MediaStream?>(null);
    final localRenderer = useMemoized(() => RTCVideoRenderer());
    final remoteRenderer = useMemoized(() => RTCVideoRenderer());
    final signalingManager = useMemoized(() => SignalingManager('call_id')); //your id

    late StreamSubscription<RTCSessionDescription?> subscription;

    Set<RTCIceCandidate> addedCandidates = {};

    Future<void> initRenderer() async {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
    }
    void registerPeerConnectionListeners(){
      peerConnection.value?.onIceCandidate = (candidate) {
        print("SEND IceCandidate : ${candidate.toString()}");
        signalingManager.sendIceCandidate(candidate,typeUser.name);
      };

      peerConnection.value?.onAddStream = (stream) {
        localStream.value = stream;
      };

      peerConnection.value?.onTrack = (event) {
        print("Tho test onTrack run");
        if (event.streams.isNotEmpty) {
          remoteRenderer.srcObject = event.streams[0];
          print("Tho test onTrack remote srcObject oke");
        }
      };

      peerConnection.value?.onConnectionState = (connectionState){
        print("THO TEST CONNECTION STATE"+connectionState.name);
      };

      peerConnection.value?.onSignalingState = (signalingState){
        print("THO TEST SIGNALING STATE"+signalingState.name);
      };

      peerConnection.value?.onIceGatheringState = (iceGatheringState){
        print("THO TEST ICE GATHERING STATE"+iceGatheringState.name);
      };

      peerConnection.value?.onIceConnectionState = (iceConnectionState){
        print("THO TEST ICECONNECTION STATE"+iceConnectionState.name);
      };
    }

    useEffect(() {
      Future<void> init() async {
        //RTCVideoRenderer Objects
        await initRenderer();

        //Turning on Camera and Micro
        localStream.value = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': true});
        localRenderer.srcObject = localStream.value;

        final configuration = {
          'iceServers': [
            {'urls': 'stun:stun.l.google.com:19302'}, // STUN server
          ]
        };
        peerConnection.value = await createPeerConnection(configuration);

        localStream.value?.getTracks().forEach((track) {
          peerConnection.value?.addTrack(track, localStream.value!);
        });

        registerPeerConnectionListeners();

        if(typeUser == TypeUser.caller){
          subscription = signalingManager.getAnswer().listen((answer) async {
            if (answer != null) {
              print('Tho test set answer: ${answer.sdp}, ${answer.type}');
              await peerConnection.value?.setRemoteDescription(answer);
              await subscription.cancel();
            }
          });

          signalingManager.getCandidatesStream(selfId: typeUser.name).listen(
                (candidates) {
              int i =0;
              for (final candidate in candidates) {
                if(!addedCandidates.contains(candidate)){
                  peerConnection.value?.addCandidate(candidate);
                  addedCandidates.add(candidate);
                  print('OFFER Added ICE CANDIDATE [$i]: ${candidate.toString()}');
                }
                i++;
              }
            },
          );

          // signalingManager.getCandidatesAddedToRoomStream( listenCaller: false,selfId: typeUser.name).listen(
          //       (candidates) {
          //     for (final candidate in candidates) {
          //       if(!addedCandidates.contains(candidate)){
          //         peerConnection.value?.addCandidate(candidate);
          //         addedCandidates.add(candidate);
          //         print('OFFER Added ICE CANDIDATE: ${candidate.candidate}, ${candidate.sdpMid}, ${candidate.sdpMLineIndex}');
          //       }
          //     }
          //   },
          // );

          final offer = await peerConnection.value?.createOffer();
          peerConnection.value?.setLocalDescription(offer!);
          signalingManager.sendOffer(offer!);
        }
        else{
          // final callerCandidate = await signalingManager.getCandidatesAddedToRoomStream(
          //     listenCaller: true,
          //     selfId: typeUser.name
          // ).first;
          // if (callerCandidate.isNotEmpty) {
          //   print('GET ICE CANDIDATE FIRST: ${callerCandidate.toString()}');
          //   int i = 0;
          //   for (final candidate in callerCandidate) {
          //     if(!addedCandidates.contains(candidate)){
          //       peerConnection.value?.addCandidate(candidate);
          //       addedCandidates.add(candidate);
          //       print('ANSWER ADDED ICE CANDIDATE [$i]: ${candidate.candidate}, ${candidate.sdpMid}, ${candidate.sdpMLineIndex}');
          //     }
          //     i++;
          //   }
          // }

          // signalingManager.getCandidatesStream(selfId: typeUser.name).listen(
          //       (candidates) {
          //     int i =0;
          //     for (final candidate in candidates) {
          //       if(!addedCandidates.contains(candidate)){
          //         peerConnection.value?.addCandidate(candidate);
          //         addedCandidates.add(candidate);
          //         print('ANSWER ADDED ICE CANDIDATE [$i]: ${candidate.toString()}');
          //       }
          //       i++;
          //     }
          //   },
          // );

          final listCandidate = await signalingManager.getCandidates(selfId: typeUser.name);
          int i =0;
          for (final candidate in listCandidate) {
            if(!addedCandidates.contains(candidate)){
              peerConnection.value?.addCandidate(candidate);
              addedCandidates.add(candidate);
              print('ANSWER ADDED ICE CANDIDATE [$i]: ${candidate.toString()}');
            }
            i++;
          }

          final offer = await signalingManager.getOfferIfExists();
          await peerConnection.value?.setRemoteDescription(offer!);
          final answer = await peerConnection.value?.createAnswer();
          await peerConnection.value?.setLocalDescription(answer!);
          signalingManager.sendAnswer(answer!);
        }
      }
      try{
        init();
      }catch(e){
        print('ERROR : $e'); 
      }
      return () {
        localRenderer.dispose();
        remoteRenderer.dispose();
        peerConnection.value?.dispose();
        localStream.value?.dispose();
        remoteStream.value?.dispose();
      };
    }, []);

    return Scaffold(
      appBar: AppBar(title: const Text('Call Page')),
      body: Column(
        children: [
          Expanded(child: RTCVideoView(localRenderer)),
          Expanded(child: RTCVideoView(remoteRenderer)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Hang Up'),
          ),
        ],
      ),
    );
  }
}
