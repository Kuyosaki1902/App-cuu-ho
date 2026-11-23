import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/luong_truc_tiep.dart';
import '../core/xu_ly_loi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/TaiKhoan/controllers/tai_khoan_controller.dart';
import '../features/TaiKhoan/models/tai_khoan_model.dart';
import '../models/du_lieu_anh.dart';
import '../models/giay_to_ho_so.dart';
import '../models/ban_ghi.dart';
import '../features/YeuCauHoTro/models/chi_tiet_yeu_cau_model.dart';
import '../features/TaiKhoan/services/tai_khoan_service.dart';
import '../features/YeuCauHoTro/chi_tiet_yeu_cau_screen.dart';

class DanhSachBanGhi extends StatefulWidget {
  final NguonTaiKhoan repository;
  final String uid, kind, title;
  final bool initiallyExpanded;
  const DanhSachBanGhi({
    super.key,
    required this.repository,
    required this.uid,
    required this.kind,
    required this.title,
    this.initiallyExpanded = false,
  });
  @override
  State<DanhSachBanGhi> createState() => _DanhSachBanGhiState();
}

class _DanhSachBanGhiState extends State<DanhSachBanGhi> {
  late final controller = BanGhiController(
    widget.repository,
    widget.uid,
    widget.kind,
  );
  @override
  void initState() {
    super.initState();
    if (widget.initiallyExpanded) controller.load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void openSos(String id) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => ChiTietYeuCauScreen(id: id)));
  Widget tile(BanGhi r) {
    switch (widget.kind) {
      case 'sent':
        return ListTile(
          title: Text('SOS ${r.id}'),
          subtitle: Text(
            '${dateText(r.data['thoiGianTao'])} • ${r.text('maTinhTrangYeuCau')}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => openSos(r.id),
        );
      case 'helped':
        final selected =
            assignmentStatus(r.data['maTrangThaiTiepNhan']) == 'duoc_chon';
        return ListTile(
          title: Text('SOS ${r.text('maYeuCau')}'),
          subtitle: Text(
            '${r.text('maTrangThaiTiepNhan')} • ${dateText(r.data['thoiGianGui'])}'
            '${selected ? "\nĐã được chọn; mở SOS để xem tình trạng hiện tại." : "\nBản ghi tiếp nhận, chưa chứng minh đã tham gia hỗ trợ."}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => openSos(r.text('maYeuCau', '')),
        );
      case 'documents':
        return ListTile(
          title: Text(profileDocumentLabel(r.data['maPhanLoaiAnh'])),
          subtitle: Text(
            r.text('trangThaiXacThuc', 'Chưa có kết quả xác thực'),
          ),
          trailing: const Icon(Icons.visibility_outlined),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => XemGiayTo(record: r))),
        );
      case 'ratings':
        return ListTile(
          leading: const Icon(Icons.star_outline),
          title: Text(
            'Điểm: ${r.text('diemDanhGia')} • SOS ${r.text('maYeuCau')}',
          ),
          subtitle: Text(
            '${r.text('nhanXet', '')}\n${dateText(r.data['ngayTao'])} • Người đánh giá: ${r.text('maNguoiDanhGia')}',
          ),
        );
      case 'reports':
        return ExpansionTile(
          title: Text(r.text('tieuDe', 'Bản ghi ${r.id}')),
          subtitle: Text(
            '${r.text('trangThai')} • ${dateText(r.data['ngayTao'])}',
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                '${r.text('noiDung')}\nNgười gửi: ${r.text('maNguoiGui')}\nKết quả xử lý: ${r.text('ketQuaXuLy')}',
              ),
            ),
          ],
        );
      case 'discipline':
        return ListTile(
          title: Text(r.text('hinhThuc')),
          subtitle: Text(
            '${r.text('lyDo')}\nTrạng thái: ${r.text('trangThai')}\n'
            'Từ ${dateText(r.data['tuNgay'])} đến ${dateText(r.data['denNgay'])}',
          ),
        );
      case 'audit':
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 15,
                        backgroundColor: Color(0xFFDCE8FC),
                        child: Icon(
                          Icons.verified_user_outlined,
                          size: 17,
                          color: Color(0xFF0964BE),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: 2,
                          color: const Color(0xFFDCE8FC),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateText(r.data['thoiGian']),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF71829B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${r.text('hanhDong')} • ${r.text('trangThai')}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        r.text('lyDo'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Admin: ${r.text('maAdmin')}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF71829B),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return ListTile(
          title: Text('${r.text('hanhDong')} • ${r.text('trangThai')}'),
          subtitle: Text(
            '${r.text('lyDo')}\nAdmin: ${r.text('maAdmin')}\n${dateText(r.data['thoiGian'])}',
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      initiallyExpanded: widget.initiallyExpanded,
      title: Text(
        widget.title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      onExpansionChanged: (expanded) {
        if (expanded && !controller.loaded) controller.load();
      },
      children: [
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final c = controller;
            return Column(
              children: [
                if (c.loading) const LinearProgressIndicator(),
                if (c.error != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      c.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                if (c.loaded && c.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Chưa có dữ liệu.'),
                  ),
                ...c.items.map(tile),
                if (c.hasMore || c.error != null)
                  TextButton(
                    onPressed: c.loading ? null : () => c.load(),
                    child: Text(c.error != null ? 'Thử lại' : 'Tải thêm'),
                  ),
                if (c.loaded)
                  TextButton(
                    onPressed: c.loading ? null : () => c.load(reset: true),
                    child: const Text('Tải lại'),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class XemGiayTo extends StatefulWidget {
  final BanGhi record;
  const XemGiayTo({super.key, required this.record});

  @override
  State<XemGiayTo> createState() => _XemGiayToState();
}

class _XemGiayToState extends State<XemGiayTo> {
  late Future<DuLieuAnh> image;
  late BanGhi record;
  String? liveError;
  final luong = PhienTheoDoi();

  void watch() {
    record = widget.record;
    load();
    luong.listen(
      'image',
      FirebaseFirestore.instance
          .collection('LuuAnh')
          .doc(record.id)
          .snapshots(),
      (doc) {
        if (!mounted) return;
        setState(() {
          liveError = doc.exists ? null : 'Ảnh đã bị xóa.';
          if (doc.exists) {
            final next = BanGhi.fromDoc(doc);
            final changed =
                documentImageSource(next.data) !=
                documentImageSource(record.data);
            record = next;
            if (changed) load();
          }
        });
      },
      (e) {
        if (mounted) setState(() => liveError = friendlyError(e));
      },
    );
  }

  @override
  void dispose() {
    luong.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    watch();
  }

  @override
  void didUpdateWidget(covariant XemGiayTo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record.id != widget.record.id) watch();
  }

  void load() {
    image = compute(decodeDocumentImage, documentImageSource(record.data));
  }

  Widget failure(String message) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.broken_image_outlined, size: 42, color: Colors.grey),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Giấy tờ xác minh')),
    body: liveError != null
        ? failure(liveError!)
        : Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<DuLieuAnh>(
              future: image,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  return failure(
                    error is FormatException
                        ? error.message
                        : 'Không đọc được ảnh giấy tờ.',
                  );
                }
                final data = snapshot.data!;
                final photo = data.bytes != null
                    ? Image.memory(
                        data.bytes!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => failure(
                          'Ảnh bị lỗi hoặc định dạng chưa được hỗ trợ.',
                        ),
                      )
                    : Image.network(
                        data.url!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => failure(
                          'Không tải được ảnh. Vui lòng kiểm tra kết nối hoặc đường dẫn.',
                        ),
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : const Center(child: CircularProgressIndicator()),
                      );
                return Column(
                  children: [
                    Text(
                      'Loại: ${profileDocumentLabel(record.data['maPhanLoaiAnh'])}',
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 5,
                        child: Center(child: photo),
                      ),
                    ),
                    if (data.url != null)
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: data.url!),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Đã sao chép đường dẫn tài liệu.',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Sao chép đường dẫn'),
                      ),
                  ],
                );
              },
            ),
          ),
  );
}
