import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class EmergencyCallListenerService {
  final FlutterTts _flutterTts = FlutterTts();
  StreamSubscription<QuerySnapshot>? _callSubscription;

  // Lắng nghe cuộc gọi khẩn cấp
  void startListeningForCalls(
    String currentRelativeUserId,
    Function(Map<String, dynamic> callData, DocumentReference docRef)
    onCallReceived,
  ) {
    _callSubscription = FirebaseFirestore.instance
        .collectionGroup('DanhSachNguoiThan')
        .where('maNguoiThan', isEqualTo: currentRelativeUserId)
        .where('trangThai', isEqualTo: 'dangGoi')
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            var doc = snapshot.docs.first;
            var callData = doc.data() as Map<String, dynamic>;
            String textToSpeechMessage = callData['noiDungDoc'] ?? '';

            // 1. Tự động đọc văn bản bằng Text-to-Speech
            _speakEmergencyText(textToSpeechMessage);

            // 2. Trả về dữ liệu và DocumentReference để thao tác nút bấm sau này
            onCallReceived(callData, doc.reference);
          }
        });
  }

  Future<void> _speakEmergencyText(String message) async {
    try {
      await _flutterTts.setLanguage("vi-VN");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      await _flutterTts.speak(message);
    } catch (e) {
      debugPrint('Lỗi Text-to-Speech: $e');
    }
  }

  // Dừng đọc Text-to-Speech
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  // Cập nhật trạng thái cuộc gọi thành daNghe (đã xử lý xong)
  Future<void> updateCallStatusToFinished(DocumentReference docRef) async {
    try {
      await docRef.update({'trangThai': 'daNghe'});
      await stopSpeaking();
    } catch (e) {
      debugPrint('Lỗi cập nhật trạng thái: $e');
    }
  }

  void dispose() {
    _callSubscription?.cancel();
    _flutterTts.stop();
  }
}
