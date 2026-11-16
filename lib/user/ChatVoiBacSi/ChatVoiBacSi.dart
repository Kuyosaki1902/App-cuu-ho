// lib/user/ChatVoiBacSi/ChatVoiBacSi.dart
import 'package:cuhokhancap/user/ChatVoiBacSi/controllers/chat_controller.dart';
import 'package:cuhokhancap/user/ChatVoiBacSi/views/chat_components.dart';
import 'package:flutter/material.dart';
import 'package:cuhokhancap/user/Models/chitiettinnhanmodel.dart';

class ChatVoiBacSiScreen extends StatefulWidget {
  final String maPhongChat; // maYeuCau
  final String maNguoiCuuHo;
  final String targetName;
  final String targetAvatar;
  final double victimLat;
  final double victimLng;

  const ChatVoiBacSiScreen({
    super.key,
    required this.maPhongChat,
    required this.maNguoiCuuHo,
    this.targetName = 'Đội ngũ Cứu hộ',
    this.targetAvatar = 'https://i.pravatar.cc/150?img=11',
    required this.victimLat,
    required this.victimLng,
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
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ValueListenableBuilder<String>(
          valueListenable: _controller.distanceNotifier,
          builder: (context, distance, child) {
            return ChatAppBar(
              targetName: widget.targetName,
              targetAvatar: widget.targetAvatar,
              distanceText: distance,
            );
          },
        ),
      ),
      body: Column(
        children: [
          ValueListenableBuilder<String>(
            valueListenable: _controller.estimatedTimeNotifier,
            builder: (context, estTime, child) {
              return ValueListenableBuilder<String>(
                valueListenable: _controller.arrivalTimeNotifier,
                builder: (context, arrTime, child) {
                  return ValueListenableBuilder<String>(
                    valueListenable: _controller.addressNotifier,
                    builder: (context, addressText, child) {
                      return ChatStatusBanner(
                        estimatedTimeText: estTime,
                        arrivalClockText: arrTime,
                        addressText: addressText,
                      );
                    },
                  );
                },
              );
            },
          ),

          Expanded(
            child: StreamBuilder<List<ChiTietTinNhanModel>>(
              stream: _controller.getMessagesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _controller.scrollToBottom(),
                );

                return ListView.builder(
                  controller: _controller.scrollController,
                  padding: const EdgeInsets.all(16),
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
                    final isMe = msg.maNguoiGui == _controller.currentUserId;

                    return FutureBuilder<Map<String, String>>(
                      future: _controller.getSenderInfo(msg.maNguoiGui),
                      builder: (context, userSnapshot) {
                        final senderInfo = userSnapshot.data ?? {};
                        final senderName = senderInfo['name'] ?? 'Thành viên';
                        final senderAvatar = senderInfo['avatar'] ?? '';

                        return ChatMessageBubble(
                          messageText: msg.noiDung,
                          timeText: _controller.formatTime(msg.thoiGianGui),
                          isMe: isMe,
                          senderName: senderName,
                          senderAvatar: senderAvatar,
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
