import 'package:flutter/material.dart';

import 'controllers/xac_minh_controller.dart';
import '../TaiKhoan/models/tai_khoan_model.dart';
import '../../models/giay_to_ho_so.dart';
import 'models/xac_minh_model.dart';
import '../TaiKhoan/services/tai_khoan_service.dart';
import 'services/xac_minh_service.dart';
import '../TaiKhoan/chi_tiet_tai_khoan_screen.dart';
import '../../widgets/danh_sach_ban_ghi.dart';
import '../../widgets/giao_dien_xac_minh.dart';

class ChiTietXacMinhScreen extends StatefulWidget {
  final String collection, uid;
  final NguonXacMinh repository;
  const ChiTietXacMinhScreen({
    super.key,
    required this.collection,
    required this.uid,
    required this.repository,
  });
  @override
  State<ChiTietXacMinhScreen> createState() => _ChiTietXacMinhScreenState();
}

class _ChiTietXacMinhScreenState extends State<ChiTietXacMinhScreen> {
  bool confirming = false;
  late final c = ChiTietXacMinhController(
    widget.repository,
    widget.collection,
    widget.uid,
  );
  @override
  void initState() {
    super.initState();
    c.load();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> act(String action) async {
    final p = c.detail?.profile;
    if (!mounted ||
        confirming ||
        p == null ||
        !p.actionable ||
        c.busy ||
        c.loading ||
        c.error != null) {
      return;
    }
    confirming = true;
    bool? confirmed;
    final title = {
      'approve': 'Phê duyệt hồ sơ',
      'reject': 'Từ chối hồ sơ',
      'supplement': 'Yêu cầu bổ sung',
    }[action]!;
    try {
      confirmed = action == 'supplement'
          ? await showModalBottomSheet<bool>(
              context: context,
              useRootNavigator: false,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (sheet) => SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_note, color: xmBlue, size: 28),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Yêu cầu bổ sung hồ sơ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheet, false),
                            icon: const Icon(Icons.close),
                            tooltip: 'Đóng',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      XmPanel(
                        label: 'HỒ SƠ CẦN BỔ SUNG',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${p.code} · ${p.typeLabel}',
                              style: const TextStyle(
                                color: xmMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Chuyển hồ sơ sang trạng thái Cần bổ sung để người nộp cập nhật giấy tờ.',
                        style: TextStyle(height: 1.5),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Thông báo tự động chưa khả dụng.',
                        style: TextStyle(color: xmMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheet, false),
                              child: const Text('Hủy'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => Navigator.pop(sheet, true),
                              icon: const Icon(Icons.check),
                              label: const Text('Xác nhận'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          : await showDialog<bool>(
              context: context,
              useRootNavigator: false,
              builder: (context) => AlertDialog(
                title: Text(title),
                content: Text('${p.name} • ${p.typeLabel}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Hủy'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Xác nhận'),
                  ),
                ],
              ),
            );
    } finally {
      confirming = false;
    }
    if (confirmed != true || !mounted) return;
    final error = await c.submit(action);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Đã cập nhật trạng thái hồ sơ.')),
    );
  }

  String value(Object? v) =>
      v == null || v.toString().isEmpty ? 'Chưa khai báo' : v.toString();
  Widget section(String title, List<Widget> children) => XmCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [xmHeading(title), ...children],
    ),
  );
  @override
  Widget build(BuildContext context) => Theme(
    data: verificationTheme(context),
    child: Builder(
      builder: (context) => ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          final d = c.detail, p = d?.profile;
          final enabled =
              p != null &&
              p.actionable &&
              !c.busy &&
              !c.loading &&
              c.error == null;
          return PopScope(
            canPop: !c.busy,
            child: Scaffold(
              appBar: AppBar(
                toolbarHeight: 72,
                titleSpacing: 0,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hồ sơ ${p?.code ?? widget.uid}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Xét duyệt năng lực chuyên môn y tế',
                      style: TextStyle(fontSize: 11, color: xmMuted),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'Tải lại',
                    onPressed: c.busy ? null : () => c.load(),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              bottomNavigationBar: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: xmBorder)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x090F2947),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (c.busy)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: LinearProgressIndicator(),
                              ),
                            LayoutBuilder(
                              builder: (context, box) {
                                final buttons = [
                                  OutlinedButton.icon(
                                    onPressed: enabled
                                        ? () => act('supplement')
                                        : null,
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Yêu cầu bổ sung'),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 50),
                                      side: const BorderSide(
                                        color: xmBlue,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  FilledButton.icon(
                                    onPressed: enabled
                                        ? () => act('approve')
                                        : null,
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                      size: 18,
                                    ),
                                    label: const Text('Phê duyệt'),
                                  ),
                                ];
                                return box.maxWidth < 340
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          buttons[0],
                                          const SizedBox(height: 8),
                                          buttons[1],
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Expanded(child: buttons[0]),
                                          const SizedBox(width: 12),
                                          Expanded(child: buttons[1]),
                                        ],
                                      );
                              },
                            ),
                            TextButton.icon(
                              onPressed: enabled ? () => act('reject') : null,
                              icon: const Icon(Icons.cancel_outlined, size: 17),
                              label: const Text('Từ chối hồ sơ này'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFEF3939),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              body: c.loading
                  ? const Center(child: CircularProgressIndicator())
                  : c.error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(c.error!),
                          TextButton(
                            onPressed: c.load,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    )
                  : d == null || p == null
                  ? const Center(child: Text('Không tìm thấy hồ sơ.'))
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: xmStatusColor(
                                  p.status,
                                ).withValues(alpha: .07),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: xmStatusColor(
                                    p.status,
                                  ).withValues(alpha: .35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(11),
                                    decoration: BoxDecoration(
                                      color: xmStatusColor(
                                        p.status,
                                      ).withValues(alpha: .12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      p.status == 'da_duyet'
                                          ? Icons.verified_outlined
                                          : Icons.hourglass_empty,
                                      color: xmStatusColor(p.status),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Trạng thái: ${verificationStatuses[p.status] ?? p.status}',
                                          style: TextStyle(
                                            color: xmStatusColor(p.status),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          p.submittedLabel,
                                          style: TextStyle(
                                            color: xmStatusColor(p.status),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (p.data['capDoHoSo'] != null)
                                    Chip(
                                      label: Text(
                                        'Cấp độ ${p.data["capDoHoSo"]}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (!p.accountExists)
                              XmCard(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.person_off_outlined,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Không tìm thấy tài khoản của người nộp hồ sơ.',
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            section('Thông tin người nộp', [
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  XmAvatar(p.name, p.collection),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Mã TK: ${p.uid} · SĐT: ${p.phone}',
                                          style: const TextStyle(
                                            color: xmMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: c.busy || !p.accountExists
                                      ? null
                                      : () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  ChiTietTaiKhoanScreen(
                                                    uid: p.uid,
                                                    roles: const {},
                                                    repository:
                                                        TaiKhoanService(),
                                                    fromVerification: true,
                                                  ),
                                            ),
                                          );
                                          if (mounted) await c.load();
                                        },
                                  icon: const Icon(Icons.open_in_new, size: 14),
                                  label: const Text('Xem tài khoản'),
                                ),
                              ),
                            ]),
                            XmCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Wrap(
                                    spacing: 14,
                                    runSpacing: 10,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      xmHeading('Thông tin hồ sơ'),
                                      XmType(p.collection),
                                    ],
                                  ),
                                  XmPanel(
                                    label: 'Đơn vị & vị trí công tác hiện tại',
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.apartment,
                                          color: xmBlue,
                                          size: 19,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            [
                                                      p.data['chucDanh'],
                                                      p.data['donViCongTac'] ??
                                                          p.data['doiNhom'],
                                                    ]
                                                    .where(
                                                      (v) =>
                                                          v != null &&
                                                          v
                                                              .toString()
                                                              .isNotEmpty,
                                                    )
                                                    .map((v) => v.toString())
                                                    .join(' · ')
                                                    .isEmpty
                                                ? 'Chưa khai báo'
                                                : [
                                                        p.data['chucDanh'],
                                                        p.data['donViCongTac'] ??
                                                            p.data['doiNhom'],
                                                      ]
                                                      .where(
                                                        (v) =>
                                                            v != null &&
                                                            v
                                                                .toString()
                                                                .isNotEmpty,
                                                      )
                                                      .join(' · '),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  XmPanel(
                                    label: 'Kỹ năng lâm sàng khai báo',
                                    child: d.skills.isEmpty
                                        ? const Text('Chưa khai báo')
                                        : Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: [
                                              for (final skill in d.skills)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 9,
                                                        vertical: 7,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    border: Border.all(
                                                      color: xmBorder,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          7,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    skill,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                  ),
                                  XmPanel(
                                    label:
                                        'Khu vực hoạt động sẵn sàng tiếp nhận',
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${value(p.data["khuVucHoatDong"])}${p.data["banKinhKm"] != null ? " · Bán kính ${p.data['banKinhKm']} km" : ""}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (p.data['maCCHN'] != null ||
                                      p.data['soCanCuoc'] != null)
                                    ExpansionTile(
                                      tilePadding: EdgeInsets.zero,
                                      title: const Text(
                                        'Thông tin giấy tờ khai báo',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      children: [
                                        for (final e in {
                                          'maCCHN': 'Mã chứng chỉ hành nghề',
                                          'soCanCuoc': 'Số căn cước',
                                          'tenChuyenNganh': 'Chuyên ngành',
                                        }.entries)
                                          if (p.data[e.key] != null)
                                            ListTile(
                                              dense: true,
                                              title: Text(e.value),
                                              subtitle: SelectableText(
                                                value(p.data[e.key]),
                                              ),
                                            ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            section(
                              'Giấy tờ đã nộp (${p.documents.length} tài liệu)',
                              [
                                const SizedBox(height: 10),
                                const Text(
                                  'Mở tài liệu để kiểm tra thông tin.',
                                  style: TextStyle(
                                    color: xmMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                if (p.documents.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: Text(
                                      'Chưa có tài liệu gắn đúng loại hồ sơ.',
                                    ),
                                  ),
                                for (final doc in p.documents)
                                  Container(
                                    margin: const EdgeInsets.only(top: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FBFE),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: xmBorder),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: xmBorder,
                                                borderRadius:
                                                    BorderRadius.circular(9),
                                              ),
                                              child: Icon(
                                                doc.text('maPhanLoaiAnh') ==
                                                        'cccd'
                                                    ? Icons.badge_outlined
                                                    : Icons
                                                          .description_outlined,
                                                color: xmMuted,
                                                size: 23,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    profileDocumentLabel(
                                                      doc.data['maPhanLoaiAnh'],
                                                    ),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    doc.data['ngayCap'] != null
                                                        ? 'Ngày cấp: ${dateText(doc.data["ngayCap"])}'
                                                        : 'Mã tài liệu: ${doc.id}',
                                                    style: const TextStyle(
                                                      color: xmMuted,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        OutlinedButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  XemGiayTo(record: doc),
                                            ),
                                          ),
                                          child: const Text('Xem tài liệu'),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            if (p.accountExists && !p.actionable)
                              const Text(
                                'Hồ sơ đã kết thúc xét duyệt hoặc bị khóa.',
                                style: TextStyle(color: xmMuted),
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    ),
  );
}
