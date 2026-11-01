//lib/user/ChatVoiBacSi/controllers/chat_controller.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:cuhokhancap/user/models/chitiettinnhanmodel.dart';

class ChatController {
  final String maPhongChat;
  final String maNguoiCuuHo;
  final String currentUserId;

  final TextEditingController msgController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FirebaseService _fbService = FirebaseService();

  ChatController({
    required this.maPhongChat,
    required this.maNguoiCuuHo,
    required this.currentUserId,
  });

  // Hủy bộ nhớ khi tắt màn hình
  void dispose() {
    msgController.dispose();
    scrollController.dispose();
  }

  // Stream lấy dữ liệu tin nhắn
  Stream<List<ChiTietTinNhanModel>> getMessagesStream() {
    return _fbService.streamTinNhan(
      maPhongChat: maPhongChat,
      maNguoiCuuHo: maNguoiCuuHo,
    );
  }

  // Hàm gửi tin nhắn
  Future<void> sendMessage() async {
    final text = msgController.text.trim();
    if (text.isEmpty) return;

    msgController.clear(); // Xóa khung nhập ngay lập tức để UX mượt

    final tinNhan = ChiTietTinNhanModel(
      maTinNhan: '',
      maPhongChat: maPhongChat,
      maNguoiGui: currentUserId,
      noiDung: text,
      loaiTinNhan: 'text',
      thoiGianGui: DateTime.now(),
    );

    await _fbService.guiTinNhan(
      maPhongChat: maPhongChat,
      maNguoiCuuHo: maNguoiCuuHo,
      tinNhan: tinNhan,
    );

    scrollToBottom();
  }

  // Hàm cuộn xuống tin nhắn mới nhất
  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Format thời gian
  String formatTime(DateTime time) {
    String formatted = DateFormat('hh:mm a').format(time);
    return formatted.replaceAll('AM', 'SA').replaceAll('PM', 'CH');
  }
}
