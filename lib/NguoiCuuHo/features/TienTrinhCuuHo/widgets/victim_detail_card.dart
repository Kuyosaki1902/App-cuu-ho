import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/rescue_process_controller.dart';
import 'rescue_theme.dart';

/// Thẻ tóm tắt nạn nhân trong bottom sheet chính.
class VictimDetailCard extends StatelessWidget {
  const VictimDetailCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<RescueProcessController>();
    final hasPhone = c.victimPhone.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: rcCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: RC.redSoft,
                child: Icon(Icons.person, color: RC.red, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.victimName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: RC.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasPhone ? c.victimPhone : 'Chưa có số điện thoại',
                      style: const TextStyle(
                        fontSize: 13,
                        color: RC.muted,
                        fontFeatures: RC.tabular,
                      ),
                    ),
                  ],
                ),
              ),
              RcRoundButton(
                icon: Icons.phone,
                color: RC.green,
                tooltip: 'Danh bạ liên hệ',
                onTap: () => _showContactsSheet(context),
              ),
              const SizedBox(width: 8),
              RcRoundButton(
                icon: Icons.chat_bubble_outline,
                color: RC.ink,
                tooltip: 'Tin nhắn',
                onTap: () => _showFieldSheet(context, initialTab: 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RC.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.place, color: RC.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.victimAddress,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.35,
                          color: RC.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                if (c.isVictimLocationApproximate) ...[
                  const SizedBox(height: 8),
                  const RcPill(
                    text: 'Vị trí lấy từ hồ sơ, có thể không chính xác',
                    fg: RC.amber,
                    bg: RC.amberSoft,
                    icon: Icons.info_outline,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: c.hasVictimLocation
                            ? c.openExternalNavigation
                            : null,
                        icon: const Icon(Icons.navigation_outlined, size: 18),
                        label: const Text('Chỉ đường'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: RC.blue,
                          minimumSize: const Size(0, 44),
                          side: const BorderSide(color: RC.line),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: c.victimAddress),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép địa chỉ'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Sao chép'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: RC.body,
                          minimumSize: const Size(0, 44),
                          side: const BorderSide(color: RC.line),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (c.trieuChung.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Triệu chứng người báo tin mô tả',
              style: TextStyle(fontSize: 12.5, color: RC.muted),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in c.trieuChung.take(4))
                  RcPill(text: t, fg: RC.redDark, bg: RC.redSoft),
                if (c.trieuChung.length > 4)
                  RcPill(
                    text: '+${c.trieuChung.length - 4}',
                    fg: RC.body,
                    bg: RC.surface,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _showFieldSheet(context, initialTab: 0),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Xem ảnh, mô tả và ghi âm hiện trường'),
              style: TextButton.styleFrom(
                foregroundColor: RC.blue,
                minimumSize: const Size(0, 44),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Danh bạ liên hệ ────────────────────────────────────────────────
  void _showContactsSheet(BuildContext context) {
    final c = context.read<RescueProcessController>();
    final contacts = <_Contact>[
      _Contact(
        name: c.victimName,
        note: 'Số điện thoại của nạn nhân',
        phone: c.victimPhone,
      ),
      const _Contact(
        name: 'Tổng đài cấp cứu 115',
        note: 'Điều phối viên hỗ trợ ca trực',
        phone: '115',
      ),
      for (final m in c.teamMembers)
        _Contact(
          name: m['name'].toString(),
          note: 'Đồng đội · ${m['role']}',
          phone: m['phone'].toString(),
        ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RcGrabHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Liên hệ khẩn cấp',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: RC.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close, color: RC.muted),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: RC.line),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: contacts.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: RC.line),
                itemBuilder: (_, i) {
                  final ct = contacts[i];
                  final callable = ct.phone.isNotEmpty;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ct.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: RC.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ct.note,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: RC.muted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                callable ? ct.phone : 'Chưa có số điện thoại',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: callable ? RC.body : RC.muted,
                                  fontFeatures: RC.tabular,
                                ),
                              ),
                            ],
                          ),
                        ),
                        RcRoundButton(
                          icon: Icons.phone,
                          color: RC.green,
                          tooltip: 'Gọi ${ct.name}',
                          onTap: callable
                              ? () {
                                  Navigator.pop(sheetContext);
                                  c.makePhoneCall(ct.phone);
                                }
                              : null,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hiện trường + tin nhắn ─────────────────────────────────────────
  void _showFieldSheet(BuildContext context, {required int initialTab}) {
    final rescue = context.read<RescueProcessController>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: rescue,
        child: _FieldSheet(initialTab: initialTab),
      ),
    );
  }
}

class _Contact {
  final String name;
  final String note;
  final String phone;
  const _Contact({required this.name, required this.note, required this.phone});
}

class _FieldSheet extends StatefulWidget {
  final int initialTab;
  const _FieldSheet({required this.initialTab});

  @override
  State<_FieldSheet> createState() => _FieldSheetState();
}

class _FieldSheetState extends State<_FieldSheet> {
  final TextEditingController _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send(RescueProcessController c) {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    c.guiTinNhan(text);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<RescueProcessController>();
    final mq = MediaQuery.of(context);
    // Thu chiều cao theo bàn phím để ô nhập tin nhắn không bị che.
    final available = mq.size.height - mq.viewInsets.bottom - mq.padding.top - 8;
    final height = math.min(mq.size.height * 0.92, available);

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DefaultTabController(
          length: 2,
          initialIndex: widget.initialTab,
          child: Column(
            children: [
              const RcGrabHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.victimName,
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
              const TabBar(
                labelColor: RC.red,
                unselectedLabelColor: RC.muted,
                indicatorColor: RC.red,
                labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                tabs: [Tab(text: 'Hiện trường'), Tab(text: 'Tin nhắn')],
              ),
              const Divider(height: 1, color: RC.line),
              Expanded(
                child: TabBarView(
                  children: [_fieldTab(context, c), _chatTab(context, c)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab hiện trường ────────────────────────────────────────────────
  Widget _fieldTab(BuildContext context, RescueProcessController c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: c.hinhAnhUrl.isEmpty
                ? null
                : () => _openPhoto(context, c.hinhAnhUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 210,
                width: double.infinity,
                color: RC.surface,
                child: c.hinhAnhUrl.isEmpty
                    ? const _ImagePlaceholder(
                        icon: Icons.image_not_supported_outlined,
                        text: 'Người báo tin không gửi ảnh',
                      )
                    : Image.network(
                        c.hinhAnhUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : const Center(
                                child: CircularProgressIndicator(color: RC.red),
                              ),
                        errorBuilder: (_, __, ___) => const _ImagePlaceholder(
                          icon: Icons.broken_image_outlined,
                          text: 'Không tải được ảnh hiện trường',
                        ),
                      ),
              ),
            ),
          ),
          if (c.hinhAnhUrl.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Chạm vào ảnh để phóng to',
                style: TextStyle(fontSize: 12, color: RC.muted),
              ),
            ),
          const SizedBox(height: 18),
          const Text(
            'Mô tả từ người báo tin',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: RC.ink,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: RC.redSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: RC.redLine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.moTaChiTiet,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: RC.ink,
                  ),
                ),
                if (c.trieuChung.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in c.trieuChung)
                        RcPill(text: t, fg: RC.redDark, bg: Colors.white),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Ghi âm cuộc gọi báo tin',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: RC.ink,
            ),
          ),
          const SizedBox(height: 8),
          if (c.ghiAmUrl.isEmpty)
            const Text(
              'Không có bản ghi âm cho ca này.',
              style: TextStyle(fontSize: 13, color: RC.muted),
            )
          else
            OutlinedButton.icon(
              onPressed: () => c.openUrl(c.ghiAmUrl),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Nghe bản ghi âm'),
              style: OutlinedButton.styleFrom(
                foregroundColor: RC.green,
                minimumSize: const Size(0, 48),
                side: const BorderSide(color: RC.greenLine),
              ),
            ),
        ],
      ),
    );
  }

  void _openPhoto(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(child: Image.network(url, fit: BoxFit.contain)),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab tin nhắn ───────────────────────────────────────────────────
  Widget _chatTab(BuildContext context, RescueProcessController c) {
    final maxBubble = MediaQuery.of(context).size.width * 0.78;
    return Column(
      children: [
        if (c.chatError)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: RC.amberSoft,
            child: const Text(
              'Không tải được tin nhắn. Hãy kiểm tra kết nối mạng.',
              style: TextStyle(fontSize: 12.5, color: RC.amber),
            ),
          ),
        Expanded(
          child: c.danhSachTinNhan.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Chưa có tin nhắn. Gửi tin để phối hợp với người báo tin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, color: RC.muted),
                    ),
                  ),
                )
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: c.danhSachTinNhan.length,
                  itemBuilder: (_, i) {
                    final m = c.danhSachTinNhan[i];
                    final mine = m.maNguoiGui == c.currentDoctorId;
                    final dynamic t = m.thoiGianGui;
                    final time = t is DateTime ? clock(t) : '';
                    final file = m.fileDinhKemUrl;

                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxBubble),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
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
                            children: [
                              Text(
                                time.isEmpty
                                    ? c.senderLabel(m.maNguoiGui)
                                    : '${c.senderLabel(m.maNguoiGui)} · $time',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: mine ? Colors.white70 : RC.muted,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                m.noiDung,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  height: 1.3,
                                  color: mine ? Colors.white : RC.ink,
                                ),
                              ),
                              if (file != null && file.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      file,
                                      height: 110,
                                      width: 160,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
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
                    onSubmitted: (_) => _send(c),
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn…',
                      filled: true,
                      fillColor: RC.surface,
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
                  onTap: () => _send(c),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ImagePlaceholder({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: RC.muted, size: 36),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(color: RC.muted, fontSize: 13)),
        ],
      ),
    );
  }
}
