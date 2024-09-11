// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import '../views/call_page.dart';
//
// class CryptService{
//   final TypeUser typeUser;
//   CryptService(this.typeUser);
//
//   KeyProvider keyProvider;
//
//   void setupEncryptionForSender(RTCRtpSender sender) async {
//     // Tạo KeyProvider và FrameCryptor để mã hóa frame
//     keyProvider = await FrameCryptorFactory.createDefaultKeyProvider(KeyProviderOptions());
//     cryptorSender = await FrameCryptorFactory.createFrameCryptorForRtpSender(
//       participantId: typeUser.name,  // ID của người gọi (A)
//       sender: sender,
//       algorithm: Algorithm.kAesGcm,  // Thuật toán mã hóa
//       keyProvider: keyProvider  ,
//     );
//
//     // Đặt khóa mã hóa cho người nhận (B)
//     keyProvider.setKey(participantId: 'receiver', index: 1, key: 'secret_key'.codeUnits);  // Khóa mã hóa
//   }
//
//   void setupDecryptionForReceiver(RTCRtpReceiver receiver) async {
//     KeyProvider keyProviderA = await FrameCryptorFactory.createDefaultKeyProvider(KeyProviderOptions());
//     FrameCryptor cryptorReceiverA = await FrameCryptorFactory.createFrameCryptorForRtpReceiver(
//       participantId: 'caller', // ID của A
//       receiver: receiver,
//       algorithm: Algorithm.AES_GCM, // Thuật toán mã hóa
//       keyProvider: keyProviderA,
//     );
//
//     // Đặt khóa giải mã cho stream từ B (tương tự như B làm với A)
//     keyProviderA.setKey('receiver', 1, 'secret_key_for_b'.codeUnits);
//   }
//
//   void setupEncryptionForPeerB(RTCRtpSender sender) async {
//     // Tạo KeyProvider và FrameCryptor để mã hóa frame
//     keyProviderB = await FrameCryptorFactory.createDefaultKeyProvider(KeyProviderOptions());
//     cryptorSenderB = await FrameCryptorFactory.createFrameCryptorForRtpSender(
//       participantId: 'reveicer',  // ID của người gọi (A)
//       sender: sender,
//       algorithm: Algorithm.AES_GCM,  // Thuật toán mã hóa
//       keyProvider: keyProviderA,
//     );
//
//     // Đặt khóa mã hóa cho người nhận (B)
//     keyProviderA.setKey('caller', 1, 'secret_key_for_b'.codeUnits);  // Khóa mã hóa
//   }
//
//   void setupDecryptionForPeerB(RTCRtpReceiver receiver) async {
//     // Tạo KeyProvider và FrameCryptor để giải mã frame
//     keyProviderB = await FrameCryptorFactory.createDefaultKeyProvider(KeyProviderOptions());
//     cryptorReceiverB = await FrameCryptorFactory.createFrameCryptorForRtpReceiver(
//       participantId: 'receiver',  // ID của người nhận (B)
//       receiver: receiver,
//       algorithm: Algorithm.AES_GCM,  // Thuật toán mã hóa
//       keyProvider: keyProviderB,
//     );
//
//     // Đặt khóa giải mã được từ người gửi (A)
//     keyProviderB.setKey('caller', 1, 'secret_key_for_b'.codeUnits);  // Khóa giải mã từ A
//   }
// }
//
