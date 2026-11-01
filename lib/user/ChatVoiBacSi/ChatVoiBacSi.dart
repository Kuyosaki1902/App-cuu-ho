//lib/user/ChatVoiBacSi/ChatVoiBacSi.dart
import 'package:cuhokhancap/user/ChatVoiBacSi/controllers/chat_controller.dart';
import 'package:cuhokhancap/user/ChatVoiBacSi/views/chat_components.dart';
import 'package:flutter/material.dart';
import 'package:cuhokhancap/user/models/chitiettinnhanmodel.dart';

class ChatVoiBacSiScreen extends StatefulWidget {
  final String maPhongChat;
  final String maNguoiCuuHo;
  final String currentUserId;
  final String targetName;
  final String targetAvatar;

  const ChatVoiBacSiScreen({
    super.key,
    required this.maPhongChat,
    required this.maNguoiCuuHo,
    required this.currentUserId,
    this.targetName = 'BS. CKI. Nguyễn Văn Tuấn',
    this.targetAvatar = 'https://i.pravatar.cc/150?img=11',
  });

  @override
  State<ChatVoiBacSiScreen> createState() => _ChatVoiBacSiScreenState();
}

class _ChatVoiBacSiScreenState extends State<ChatVoiBacSiScreen> {
  late final ChatController _controller;

  @override
  void initState() {
    super.initState();
    // Khởi tạo Controller khi mở màn hình
    _controller = ChatController(
      maPhongChat: widget.maPhongChat,
      maNguoiCuuHo: widget.maNguoiCuuHo,
      currentUserId: widget.currentUserId,
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Xóa bộ nhớ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // Gọi UI AppBar
      appBar: ChatAppBar(
        targetName: widget.targetName,
        targetAvatar: widget.targetAvatar,
      ),
      body: Column(
        children: [
          // Gọi UI Banner
          const ChatStatusBanner(),

          Expanded(
            child: StreamBuilder<List<ChiTietTinNhanModel>>(
              stream: _controller.getMessagesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                // Cuộn xuống cuối
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _controller.scrollToBottom(),
                );

                return ListView.builder(
                  controller: _controller.scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + 1,
                  itemBuilder: (context, index) {
                    // Item đầu tiên luôn là tin nhắn hệ thống
                    if (index == 0) return const ChatSystemMessage();

                    final msg = messages[index - 1];
                    final isMe = msg.maNguoiGui == widget.currentUserId;

                    // Gọi UI Bong bóng Chat
                    return ChatMessageBubble(
                      messageText: msg.noiDung,
                      timeText: _controller.formatTime(msg.thoiGianGui),
                      isMe: isMe,
                      targetAvatar: widget.targetAvatar,
                    );
                  },
                );
              },
            ),
          ),

          // Gọi UI Nhập liệu
          ChatBottomInput(
            controller: _controller.msgController,
            onSend: _controller.sendMessage,
            targetName: widget.targetName,
          ),
        ],
      ),
    );
  }
}
