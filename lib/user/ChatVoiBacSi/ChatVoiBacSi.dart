// lib/user/ChatVoiBacSi/ChatVoiBacSi.dart
import 'package:cuhokhancap/user/ChatVoiBacSi/controllers/chat_controller.dart';
import 'package:cuhokhancap/user/ChatVoiBacSi/views/chat_components.dart';
import 'package:flutter/material.dart';
import 'package:cuhokhancap/user/Models/chitiettinnhanmodel.dart';

class ChatVoiBacSiScreen extends StatefulWidget {
  final String maPhongChat; // maYeuCau (KHÔNG phải mã người cứu hộ)
  final String maNguoiCuuHo; // không còn dùng (chat nhóm), giữ để nơi gọi không phải sửa
  final String targetName; // không còn hiển thị trên thanh tiêu đề (chat nhóm)
  final String targetAvatar; // không còn dùng
  final double victimLat;
  final double victimLng;

  /// Không bắt buộc: nếu nơi gọi đã biết mã người dùng hiện tại thì truyền vào,
  /// bỏ trống thì đọc từ bộ nhớ máy như trước.
  final String? currentUserId;

  const ChatVoiBacSiScreen({
    super.key,
    required this.maPhongChat,
    required this.maNguoiCuuHo,
    this.targetName = 'Đội ngũ Cứu hộ',
    // Trước đây mặc định là ảnh ngẫu nhiên của một người lạ (pravatar.cc);
    // để trống thì hiện biểu tượng người mặc định.
    this.targetAvatar = '',
    required this.victimLat,
    required this.victimLng,
    this.currentUserId,
  });

  @override
  State<ChatVoiBacSiScreen> createState() => _ChatVoiBacSiScreenState();
}

class _ChatVoiBacSiScreenState extends State<ChatVoiBacSiScreen> {
  late final ChatController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChatController(
      maPhongChat: widget.maPhongChat,
      maNguoiCuuHo: widget.maNguoiCuuHo,
      victimLat: widget.victimLat,
      victimLng: widget.victimLng,
      currentUserId: widget.currentUserId,
    );
    _controller.errorNotifier.addListener(_onControllerError);
  }

  void _onControllerError() {
    final msg = _controller.errorNotifier.value;
    if (msg == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    _controller.errorNotifier.value = null;
  }

  @override
  void dispose() {
    _controller.errorNotifier.removeListener(_onControllerError);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const ChatAppBar(),
      body: Column(
        children: [
          Expanded(
            // Chờ biết mã người dùng trước khi vẽ tin nhắn (để phân biệt tin của mình)
            child: FutureBuilder<void>(
              future: _controller.ready,
              builder: (context, readySnap) {
                if (readySnap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                return StreamBuilder<List<ChiTietTinNhanModel>>(
                  stream: _controller.messagesStream, // tạo 1 lần, không tạo mới mỗi build
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      debugPrint('❌ Lỗi tải tin nhắn: ${snapshot.error}');
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Không tải được tin nhắn. Vui lòng kiểm tra kết nối.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    final messages = snapshot.data ?? [];
                    _controller.onMessagesChanged(messages);

                    // Tên/avatar người gửi đọc từ cache; tải xong thì chỉ phần này vẽ lại
                    return ValueListenableBuilder<int>(
                      valueListenable: _controller.senderInfoVersion,
                      builder: (context, _, __) {
                        return ListView.builder(
                          controller: _controller.scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                          itemCount: messages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return ValueListenableBuilder<String>(
                                valueListenable: _controller.addressNotifier,
                                builder: (context, address, _) {
                                  return ChatSystemMessage(addressText: address);
                                },
                              );
                            }

                            final msg = messages[index - 1];
                            final isMe =
                                msg.maNguoiGui == _controller.currentUserId;
                            final sender = _controller.senderInfoOf(
                              msg.maNguoiGui,
                            );

                            return ChatMessageBubble(
                              messageText: msg.noiDung,
                              timeText: _controller.formatTime(msg.thoiGianGui),
                              isMe: isMe,
                              senderName: sender['name'] ?? 'Thành viên',
                              senderAvatar: sender['avatar'] ?? '',
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

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
