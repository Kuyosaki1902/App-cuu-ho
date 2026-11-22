// lib/user/ChatVoiBacSi/views/chat_components.dart
import 'dart:convert';
import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF046450);

// Bộ nhớ đệm: cùng một chuỗi avatar luôn trả về CÙNG một ImageProvider.
// Trước đây mỗi lần vẽ lại tạo MemoryImage mới nên ảnh bị giải mã lại liên tục.
final Map<String, ImageProvider?> _avatarCache = {};

ImageProvider? decodeAvatarImage(String? rawAvatar) {
  if (rawAvatar == null || rawAvatar.trim().isEmpty) return null;
  final cleaned = rawAvatar.trim();

  if (_avatarCache.containsKey(cleaned)) return _avatarCache[cleaned];

  ImageProvider? provider;
  if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
    provider = NetworkImage(cleaned);
  } else {
    try {
      final base64Part = cleaned.contains(',')
          ? cleaned.split(',').last.trim()
          : cleaned;
      provider = MemoryImage(base64Decode(base64Part));
    } catch (_) {
      provider = null;
    }
  }

  if (_avatarCache.length >= 50) _avatarCache.clear(); // giới hạn bộ nhớ
  _avatarCache[cleaned] = provider;
  return provider;
}

/// Thanh tiêu đề cho CHAT NHÓM (nạn nhân + tối đa 3 cứu hộ viên).
/// Không còn avatar/khoảng cách/giờ đến của một người riêng lẻ.
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;

  const ChatAppBar({
    super.key,
    this.title = 'Nhóm cứu hộ',
    this.subtitle = 'Nạn nhân và đội ngũ cứu hộ',
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
          const CircleAvatar(
            radius: 20,
            backgroundColor: primaryColor,
            child: Icon(Icons.groups_rounded, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ChatStatusBanner extends StatelessWidget {
  final String estimatedTimeText;
  final String arrivalClockText;
  final String addressText;

  const ChatStatusBanner({
    super.key,
    this.estimatedTimeText = '-- phút nữa tới',
    this.arrivalClockText = '--:--',
    this.addressText = '',
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
            estimatedTimeText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: primaryColor,
            ),
          ),
          Text(
            ' • Dự kiến: $arrivalClockText',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class ChatSystemMessage extends StatelessWidget {
  final String addressText;
  const ChatSystemMessage({super.key, this.addressText = ''});

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
                  'Đã điều phối Đội ngũ Cấp cứu Lưu động',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Điểm hẹn: $addressText. Đội ngũ y tế được trang bị vali hồi sức tích cực và máy đo sinh hiệu.',
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

class ChatMessageBubble extends StatelessWidget {
  final String messageText;
  final String timeText;
  final bool isMe;
  final String senderName;
  final String senderAvatar;

  const ChatMessageBubble({
    super.key,
    required this.messageText,
    required this.timeText,
    required this.isMe,
    required this.senderName,
    required this.senderAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final avatarProvider = decodeAvatarImage(senderAvatar);

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
              radius: 16,
              backgroundColor: primaryColor,
              backgroundImage: avatarProvider,
              child: avatarProvider == null
                  ? const Icon(Icons.person, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      senderName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
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
        ],
      ),
    );
  }
}

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
                  // maxLines: null (cũ) làm ô nhập thành nhiều dòng: phím Enter chỉ xuống
                  // dòng và onSubmitted không bao giờ được gọi. Đặt keyboardType text
                  // + giới hạn 4 dòng thì phím Gửi hoạt động.
                  minLines: 1,
                  maxLines: 4,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.send,
                  onEditingComplete: () {}, // giữ bàn phím mở sau khi gửi
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn cứu hộ...',
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
          ],
        ),
      ),
    );
  }
}
