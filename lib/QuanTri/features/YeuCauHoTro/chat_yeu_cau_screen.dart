import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatYeuCauScreen extends StatefulWidget {
  final String maYeuCau;

  const ChatYeuCauScreen({super.key, required this.maYeuCau});

  @override
  State<ChatYeuCauScreen> createState() => _ChatYeuCauScreenState();
}

class _ChatYeuCauScreenState extends State<ChatYeuCauScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _input = TextEditingController();
  final Map<String, Future<String>> _senderNameCache = {};
  late final Future<bool> _permission = _verifyAdmin();
  bool _sending = false;
  String? _error;
  int _localMessageSequence = 0;
  String? _pendingMessageId;
  String? _pendingMessageText;

  String _messageIdFor(String message) {
    if (_pendingMessageId != null && _pendingMessageText == message) {
      return _pendingMessageId!;
    }
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final micros = DateTime.now().toUtc().microsecondsSinceEpoch;
    final seq = ++_localMessageSequence;
    final id = 'tinnhan_${widget.maYeuCau}_${uid}_${micros}_$seq';
    _pendingMessageId = id;
    _pendingMessageText = message;
    return id;
  }

  CollectionReference<Map<String, dynamic>> get _messages => _firestore
      .collection('PhongChatCuuHo')
      .doc(widget.maYeuCau)
      .collection('DanhSachTinNhan');

  Future<bool> _verifyAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return false;
    final snap = await _firestore.collection('Admin').doc(uid).get();
    if (!snap.exists) return false;
    final status = (snap.data()?['trangThai'] ?? '').toString();
    return status == 'hoat_dong';
  }

  Future<String> _senderName(String id) async {
    if (id == 'admin') return 'Điều phối';
    if (id.trim().isEmpty) return 'Không rõ người gửi';
    try {
      final doc = await _firestore.collection('NguoiDung').doc(id).get();
      final name = (doc.data()?['hoTen'] ?? '').toString().trim();
      if (name.isNotEmpty) return name;
    } catch (_) {}
    return id;
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (_sending || text.isEmpty) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      if (!await _verifyAdmin()) {
        throw StateError('Tài khoản không có quyền quản trị.');
      }
      final request = await _firestore
          .collection('YeuCauCuuHo')
          .doc(widget.maYeuCau)
          .get();
      if (!request.exists) {
        throw StateError('Yêu cầu cứu hộ không còn tồn tại.');
      }
      final mirror = await _firestore
          .collection('NguoiDung')
          .doc('admin')
          .get();
      if (!mirror.exists) {
        throw StateError('Chưa có NguoiDung/admin. Hãy đăng nhập lại Admin.');
      }
      final id = _messageIdFor(text);
      final messageRef = _messages.doc(id);
      await _firestore.runTransaction((tx) async {
        final existing = await tx.get(messageRef);
        if (existing.exists) {
          final old = existing.data();
          if (old?['maNguoiGui'] == 'admin' &&
              old?['noiDung'] == text &&
              old?['maPhongChat'] == widget.maYeuCau) {
            return;
          }
          throw StateError('Trùng mã tin nhắn. Vui lòng thử lại.');
        }
        tx.set(messageRef, {
          'maPhongChat': widget.maYeuCau,
          'maNguoiGui': 'admin',
          'noiDung': text,
          'fileDinhKemUrl': null,
          'loaiTinNhan': 'text',
          'thoiGianGui': FieldValue.serverTimestamp(),
        });
      });
      _pendingMessageId = null;
      _pendingMessageText = null;
      if (mounted) _input.clear();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is StateError
              ? error.message.toString()
              : 'Không gửi được tin nhắn. Kiểm tra mạng và quyền truy cập.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  static DateTime? _parseTime(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  Widget _messageBubble(Map<String, dynamic> msg, double maxBubble) {
    final sender = (msg['maNguoiGui'] ?? '').toString();
    final mine = sender == 'admin';
    final time = _parseTime(msg['thoiGianGui']);
    final timestamp = time == null ? '' : clock(time.toLocal());
    final body = (msg['noiDung'] ?? '').toString();
    final attachment = (msg['fileDinhKemUrl'] ?? '').toString();

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxBubble),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: mine ? RC.ink : RC.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(mine ? 14 : 4),
              bottomRight: Radius.circular(mine ? 4 : 14),
            ),
          ),
          child: Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<String>(
                future: _senderNameCache.putIfAbsent(
                  sender,
                  () => _senderName(sender),
                ),
                builder: (_, snapshot) {
                  final name = mine ? 'Bạn' : (snapshot.data ?? sender);
                  return Text(
                    timestamp.isEmpty ? name : '$name · $timestamp',
                    style: TextStyle(
                      fontSize: 11,
                      color: mine ? Colors.white70 : RC.muted,
                    ),
                  );
                },
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.3,
                  color: mine ? Colors.white : RC.ink,
                ),
              ),
              if (attachment.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      onTap: () async {
                        final uri = Uri.tryParse(attachment);
                        if (uri != null &&
                            (uri.scheme == 'https' || uri.scheme == 'http')) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      child: Image.network(
                        attachment,
                        height: 110,
                        width: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          'Mở tệp đính kèm',
                          style: TextStyle(
                            fontSize: 12,
                            color: mine ? Colors.white70 : RC.body,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatTab() {
    final maxBubble = MediaQuery.of(context).size.width * 0.78;
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _messages
                .orderBy('thoiGianGui', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Không tải được tin nhắn. Hãy kiểm tra kết nối mạng.',
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final messages = snapshot.data!.docs;
              if (messages.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Chưa có tin nhắn. Gửi tin để phối hợp cứu hộ.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, color: RC.muted),
                    ),
                  ),
                );
              }
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (_, index) =>
                    _messageBubble(messages[index].data(), maxBubble),
              );
            },
          ),
        ),
        if (_error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: RC.amberSoft,
            child: Text(_error!, style: const TextStyle(color: RC.amber)),
          ),
        const Divider(height: 1, color: RC.line),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn…',
                      filled: true,
                      fillColor: RC.surface,
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                RcRoundButton(
                  icon: Icons.send_rounded,
                  color: RC.red,
                  tooltip: 'Gửi',
                  onTap: _sending ? null : _send,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final available =
        mq.size.height - mq.viewInsets.bottom - mq.padding.top - 8;
    final height = math.max(220.0, math.min(mq.size.height * 0.92, available));
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const RcGrabHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tin nhắn · ${widget.maYeuCau}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: RC.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: RC.muted),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tin nhắn',
                  style: TextStyle(
                    color: RC.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: RC.line),
            Expanded(
              child: FutureBuilder<bool>(
                future: _permission,
                builder: (context, permission) {
                  if (permission.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (permission.hasError || permission.data != true) {
                    return const Center(
                      child: Text('Tài khoản không có quyền xem chat Admin.'),
                    );
                  }
                  return _chatTab();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RC {
  RC._();
  static const ink = Color(0xFF1D2939);
  static const body = Color(0xFF475467);
  static const muted = Color(0xFF667085);
  static const line = Color(0xFFE4E7EC);
  static const surface = Color(0xFFF2F4F7);
  static const red = Color(0xFFD92D20);
  static const amber = Color(0xFFB54708);
  static const amberSoft = Color(0xFFFFFAEB);
}

String clock(DateTime? t) => t == null
    ? '--:--'
    : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

class RcRoundButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String tooltip;

  const RcRoundButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: onTap == null ? RC.line : color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    ),
  );
}

class RcGrabHandle extends StatelessWidget {
  const RcGrabHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(top: 10, bottom: 12),
      decoration: BoxDecoration(
        color: RC.line,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}
