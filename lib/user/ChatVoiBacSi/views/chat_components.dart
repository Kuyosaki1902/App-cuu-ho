//lib/user/ChatVoiBacSi/views/chat_components.dart
import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF046450);

// 1. APP BAR
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String targetName;
  final String targetAvatar;
  final String distanceText; // 🌟 Thêm khoảng cách động

  const ChatAppBar({
    super.key,
    required this.targetName,
    required this.targetAvatar,
    this.distanceText = '-- km',
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: CircleAvatar(
          backgroundColor: Colors.grey.shade100,
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black87,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      titleSpacing: 8,
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(targetAvatar),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  targetName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Đang di chuyển (cách $distanceText)', // 🌟 Hiển thị khoảng cách real-time
                      style: const TextStyle(
                        fontSize: 11,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFEAF5F0),
          child: IconButton(
            icon: const Icon(Icons.phone, color: primaryColor, size: 18),
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFEAF5F0),
          child: IconButton(
            icon: const Icon(
              Icons.videocam_rounded,
              color: primaryColor,
              size: 18,
            ),
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// 2. BANNER TRẠNG THÁI (Đã xóa nút Bản đồ)
class ChatStatusBanner extends StatelessWidget {
  final String estimatedTimeText; // 🌟 Nhận thời gian dự kiến động
  final String arrivalClockText; //  Nhận giờ dự kiến động

  const ChatStatusBanner({
    super.key,
    this.estimatedTimeText = '-- phút nữa tới',
    this.arrivalClockText = '--:--',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0FDF4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            estimatedTimeText, // 🌟 Hiển thị thời gian thực
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: primaryColor,
            ),
          ),
          Text(
            ' • Dự kiến: $arrivalClockText', // 🌟 Hiển thị mốc giờ thực
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const Spacer(),
          // 🌟 Nút "Bản đồ" đã được loại bỏ hoàn toàn theo yêu cầu
        ],
      ),
    );
  }
}

// 3. TIN NHẮN HỆ THỐNG GHIM ĐẦU TRANG
class ChatSystemMessage extends StatelessWidget {
  const ChatSystemMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1FAE5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: primaryColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đã điều phối Bác sĩ Cấp cứu Lưu động',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Điểm hẹn: 124 Pasteur, Q.1 (Nhà bạn). Đội ngũ y tế được trang bị vali hồi sức tích cực và máy đo sinh hiệu.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 4. BONG BÓNG TIN NHẮN
class ChatMessageBubble extends StatelessWidget {
  final String messageText;
  final String timeText;
  final bool isMe;
  final String targetAvatar;

  const ChatMessageBubble({
    super.key,
    required this.messageText,
    required this.timeText,
    required this.isMe,
    required this.targetAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage(targetAvatar),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? primaryColor : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    messageText,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.check, size: 14, color: Colors.grey.shade600),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!isMe) const SizedBox(width: 40),
        ],
      ),
    );
  }
}

// 5. KHUNG NHẬP TEXT
class ChatBottomInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final String targetName;

  const ChatBottomInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.targetName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F1F1))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText:
                        'Nhập tin nhắn cho ${targetName.split(' ').last}...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onSend,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ], // syntax fix
        ),
      ),
    );
  }
}
