// lib/signaling_manager.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SignalingManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _callId;
  //String? userId;

  SignalingManager(this._callId);

  Future<void> sendOffer(RTCSessionDescription offer) async {
    await _firestore.collection('calls').doc(_callId).set({
      'offer': offer.toMap()
    });
  }

  Future<void> sendAnswer(RTCSessionDescription answer) async {
    await _firestore.collection('calls').doc(_callId).update({
      'answer': {'sdp': answer.sdp, 'type': answer.type},
    });
  }

  Future<void> sendIceCandidate(RTCIceCandidate candidate, String userId) async {
    await _firestore.collection('calls').doc(_callId).collection('candidates').add(
      candidate.toMap()..['user_id'] = userId
    );
  }

  Stream<List<RTCIceCandidate>> getCandidatesStream({
    required String selfId,
  }) {
    final snapshots = _firestore
        .collection('calls')
        .doc('call_id')
        .collection('candidates')
        .where('user_id', isNotEqualTo: selfId)
        .snapshots();

    final convertedStream = snapshots.map(
          (snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return RTCIceCandidate(
            data['candidate'],
            data['sdpMid'],
            data['sdpMLineIndex'],
          );
        }).toList();
      },
    );

    return convertedStream;
  }

  Future<List<RTCIceCandidate>> getCandidates({
    required String selfId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('calls')
          .doc('call_id')
          .collection('candidates')
          .where('user_id', isNotEqualTo: selfId)
          .get();
      final candidates = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return RTCIceCandidate(
          data['candidate'],
          data['sdpMid'],
          data['sdpMLineIndex'],
        );
      }).toList();

      return candidates;
    } catch (e) {
      print('Error fetching ICE candidates: $e');
      return [];
    }
  }

  Future<RTCSessionDescription?> getOfferIfExists() async {
    try {
      final doc = await _firestore.collection('calls').doc(_callId).get();
      final data = doc.data();
      if (data != null && data['offer'] != null) {
        final offer = data['offer'];
        return RTCSessionDescription(offer['sdp'], offer['type']);
      }
      return null;
    } catch (e) {
      print('Error getting offer: $e');
    }
    return null;
  }

  Stream<RTCSessionDescription?> getAnswer() {
    return _firestore.collection('calls').doc(_callId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data != null && data['answer'] != null) {
        final answer = data['answer'];
        return RTCSessionDescription(answer['sdp'], answer['type']);
      }
      return null;
    });
  }

  Future<void> removeRoomCall() async {
    try {
      await _firestore.collection('calls').doc(_callId).delete();
      print('Room call removed successfully.');
    } catch (e) {
      print('Failed to remove room call: $e');
    }
  }

}
