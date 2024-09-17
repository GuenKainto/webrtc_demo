import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_demo/firebase_service/signaling_manager.dart';

import 'call_page.dart';

const List<String> audioCodecList = <String>[
  'OPUS',
  'ISAC',
  'PCMA',
  'PCMU',
  'G729'
];
const List<String> videoCodecList = <String>['VP8', 'VP9', 'H264', 'AV1'];

class CallingPageE2EE extends HookWidget {
  const CallingPageE2EE({super.key, required this.typeUser});

  final TypeUser typeUser;

  @override
  Widget build(BuildContext context) {
    String audioDropdownValue = audioCodecList.first;
    String videoDropdownValue = videoCodecList.first;
    final peerConnection = useState<RTCPeerConnection?>(null);
    final localStream = useState<MediaStream?>(null);
    final localRenderer = useMemoized(() => RTCVideoRenderer());
    final remoteRenderer = useMemoized(() => RTCVideoRenderer());
    final signalingManager = useMemoized(() => SignalingManager('call_id')); //your id

    late StreamSubscription<RTCSessionDescription?> subscription;

    Set<RTCIceCandidate> addedCandidates = {};

    final FrameCryptorFactory _frameCyrptorFactory = frameCryptorFactory;
    KeyProvider? _keySharedProvider;
    final Map<String, FrameCryptor> _frameCyrptors = {};

    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun.relay.metered.ca:80'},
        {
          'urls': 'turn:global.relay.metered.ca:80',
          'username': 'f569bd93a263ccf285fe61f3',
          'credential': 'QM/MfGs5VZaX6jLF',
        },
        {
          'urls': 'turn:global.relay.metered.ca:80?transport=tcp',
          'username': 'f569bd93a263ccf285fe61f3',
          'credential': 'QM/MfGs5VZaX6jLF',
        },
        {
          'urls': 'turn:global.relay.metered.ca:443',
          'username': 'f569bd93a263ccf285fe61f3',
          'credential': 'QM/MfGs5VZaX6jLF',
        },
        {
          'urls': 'turns:global.relay.metered.ca:443?transport=tcp',
          'username': 'f569bd93a263ccf285fe61f3',
          'credential': 'QM/MfGs5VZaX6jLF',
        },
      ],
      'sdpSemantics': 'unified-plan',
      'encodedInsertableStreams': true,
    };

    final constraints = <String, dynamic>{
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': false},
      ],
    };

    final demoRatchetSalt = 'flutter-webrtc-ratchet-salt';

    final aesKey = Uint8List.fromList([
      200,
      244,
      58,
      72,
      214,
      245,
      86,
      82,
      192,
      127,
      23,
      153,
      167,
      172,
      122,
      234,
      140,
      70,
      175,
      74,
      61,
      11,
      134,
      58,
      185,
      102,
      172,
      17,
      11,
      6,
      119,
      253
    ]);

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

    void _enableEncryption({bool video = false, bool enabled = true}) async {
      var senders = await peerConnection.value?.senders;

      var kind = video ? 'video' : 'audio';

      senders?.forEach((element) async {
        if (kind != element.track?.kind) return;

        var trackId = element.track?.id;
        var id = kind + '_' + trackId! + '_sender';
        if (!_frameCyrptors.containsKey(id)) {
          var frameCyrptor =
          await _frameCyrptorFactory.createFrameCryptorForRtpSender(
              participantId: id,
              sender: element,
              algorithm: Algorithm.kAesGcm,
              keyProvider: _keySharedProvider!);
          frameCyrptor.onFrameCryptorStateChanged = (participantId, state) =>
              print('EN onFrameCryptorStateChanged $participantId $state');
          _frameCyrptors[id] = frameCyrptor;
          await frameCyrptor.setKeyIndex(0);
        }

        var _frameCyrptor = _frameCyrptors[id];
        await _frameCyrptor?.setEnabled(enabled);
        await _frameCyrptor?.updateCodec(
            kind == 'video' ? videoDropdownValue : audioDropdownValue);
      });
    }

    void _enableDecryption({bool video = false, bool enabled = true}) async {
      var receivers = await peerConnection.value?.receivers;
      var kind = video ? 'video' : 'audio';
      receivers?.forEach((element) async {
        if (kind != element.track?.kind) return;
        var trackId = element.track?.id;
        var id = kind + '_' + trackId! + '_receiver';
        if (!_frameCyrptors.containsKey(id)) {
          var frameCyrptor =
          await _frameCyrptorFactory.createFrameCryptorForRtpReceiver(
              participantId: id,
              receiver: element,
              algorithm: Algorithm.kAesGcm,
              keyProvider: _keySharedProvider!);
          frameCyrptor.onFrameCryptorStateChanged = (participantId, state) =>
              print('DE onFrameCryptorStateChanged $participantId $state');
          _frameCyrptors[id] = frameCyrptor;
          await frameCyrptor.setKeyIndex(0);
        }

        var _frameCyrptor = _frameCyrptors[id];
        await _frameCyrptor?.setEnabled(enabled);
        await _frameCyrptor?.updateCodec(
            kind == 'video' ? videoDropdownValue : audioDropdownValue);
      });
    }

    useEffect(() {
      Future<void> init() async {
        //RTCVideoRenderer Objects
        await initRenderer();

        //Turning on Camera and Micro
        localStream.value = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': true});
        localRenderer.srcObject = localStream.value;

        peerConnection.value = await createPeerConnection(configuration,constraints);

        localStream.value?.getTracks().forEach((track) {
          peerConnection.value?.addTrack(track, localStream.value!);
        });

        var keyProviderOptions = KeyProviderOptions(
          sharedKey: true,
          ratchetSalt: Uint8List.fromList(demoRatchetSalt.codeUnits),
          ratchetWindowSize: 16,
          failureTolerance: -1,
        );

        _keySharedProvider ??=
        await _frameCyrptorFactory.createDefaultKeyProvider(keyProviderOptions);
        await _keySharedProvider?.setSharedKey(key: aesKey);

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

          final offer = await peerConnection.value?.createOffer();
          peerConnection.value?.setLocalDescription(offer!);
          signalingManager.sendOffer(offer!);
        }
        else{
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

        _enableEncryption(enabled: true,video: true);
        _enableEncryption(enabled: true,video: false);
        _enableDecryption(enabled: true,video: true);
        _enableDecryption(enabled: true,video: false);
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
        addedCandidates.clear();
      };
    }, []);

    return Scaffold(
      appBar: AppBar(title: const Text('Call Page')),
      body: Column(
        children: [
          Expanded(child: RTCVideoView(localRenderer)),
          Expanded(child: RTCVideoView(remoteRenderer)),
          ElevatedButton(
            onPressed: () async {
              await signalingManager.removeRoomCall();
              Navigator.pop(context);
            },
            child: const Text('Hang Up'),
          ),
        ],
      ),
    );
  }
}
