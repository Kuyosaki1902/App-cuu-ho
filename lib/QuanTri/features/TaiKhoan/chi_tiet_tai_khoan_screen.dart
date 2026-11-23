import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../YeuCauHoTro/chi_tiet_yeu_cau_screen.dart';

import 'controllers/tai_khoan_controller.dart';
import 'models/tai_khoan_model.dart';
import 'services/tai_khoan_service.dart';
import '../XacMinh/services/xac_minh_service.dart';
import '../../widgets/hop_thoai_ly_do.dart';
import '../../widgets/danh_sach_ban_ghi.dart';
import '../XacMinh/chi_tiet_xac_minh_screen.dart';
import '../../widgets/giao_dien_tai_khoan.dart';

class ChiTietTaiKhoanScreen extends StatefulWidget {
  final String uid;
  final Map<String, String> roles;
  final NguonTaiKhoan repository;
  final bool fromVerification;
  const ChiTietTaiKhoanScreen({
    super.key,
    required this.uid,
    required this.roles,
    required this.repository,
    this.fromVerification = false,
  });
  @override
  State<ChiTietTaiKhoanScreen> createState() => _ChiTietTaiKhoanScreenState();
}

class _ChiTietTaiKhoanScreenState extends State<ChiTietTaiKhoanScreen> {
  late final controller = ChiTietTaiKhoanController(
    widget.repository,
    widget.uid,
  );
  int revision = 0;
  bool confirming = false, openingVerification = false;
  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> perform(String action, String title) async {
    final a = controller.account;
    if (!mounted ||
        confirming ||
        a == null ||
        controller.busy ||
        controller.loading ||
        controller.error != null) {
      return;
    }
    confirming = true;
    String? reason;
    try {
      reason = await showDialog<String>(
        useRootNavigator: false,
        context: context,
        builder: (_) => HopThoaiLyDo(title: title, name: a.name),
      );
    } finally {
      confirming = false;
    }
    if (reason == null || !mounted) return;
    final error = await controller.perform(action, reason);
    if (!mounted) return;
    setState(() => revision++);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Đã cập nhật tài khoản.'),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> openVerification() async {
    if (openingVerification ||
        controller.busy ||
        controller.loading ||
        controller.error != null) {
      return;
    }
    final a = controller.account;
    if (a == null) return;
    if (widget.fromVerification) {
      Navigator.pop(context);
      return;
    }
    openingVerification = true;
    try {
      final collections = <String>[
        if (a.professional != null) 'HoSoCuuHoCoCCHN',
        if (a.volunteer != null) 'HoSoCuuHoKhongCCHN',
      ];
      if (collections.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tài khoản chưa nộp hồ sơ hỗ trợ.')),
        );
        return;
      }
      String? collection = collections.length == 1 ? collections.first : null;
      if (collections.length > 1) {
        collection = await showDialog<String>(
          context: context,
          useRootNavigator: false,
          builder: (ctx) => SimpleDialog(
            title: const Text('Chọn hồ sơ cần kiểm tra'),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, collections[0]),
                child: const Text('Hồ sơ có chứng chỉ hành nghề'),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, collections[1]),
                child: const Text('Hồ sơ sơ cứu không có CCHN'),
              ),
            ],
          ),
        );
      }
      if (!mounted || collection == null) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ChiTietXacMinhScreen(
            collection: collection!,
            uid: widget.uid,
            repository: XacMinhService(),
          ),
        ),
      );
      if (!mounted) return;
      await controller.load();
      if (mounted) setState(() => revision++);
    } finally {
      openingVerification = false;
    }
  }

  Widget section(String title, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: title == 'Hạn chế tài khoản · thao tác nhạy cảm'
                  ? const Color(0xFFBF1736)
                  : const Color(0xFF526477),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );
  Widget field(
    String label,
    String value, {
    IconData icon = Icons.info_outline,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: accountPanel,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accountBlue, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF71829B)),
              ),
              const SizedBox(height: 5),
              SelectableText(
                value.isEmpty ? 'Chưa có dữ liệu' : value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget profile(String title, Map<String, dynamic> p) => section(title, [
    Align(
      alignment: Alignment.centerRight,
      child: accountBadge(
        normalizeProfileStatus(p['maTrangThaiHoSo']) == 'da_duyet'
            ? '✓ Đã xác minh'
            : 'Chưa xác minh',
        accountBlue,
      ),
    ),
    const SizedBox(height: 12),
    field(
      'Vị trí & Đơn vị',
      [
        textOf(p, 'chucDanh'),
        textOf(p, 'donViCongTac', textOf(p, 'doiNhom')),
      ].where((v) => v.isNotEmpty).join(' · '),
      icon: Icons.local_hospital_outlined,
    ),
    field(
      'Khu vực thường trực',
      textOf(p, 'khuVucHoatDong'),
      icon: Icons.location_on_outlined,
    ),
    ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text(
        'Thông tin chuyên môn khác',
        style: TextStyle(fontSize: 13),
      ),
      children: [
        for (final entry in {
          'tenChuyenNganh': 'Chuyên ngành',
          'maCCHN': 'Mã chứng chỉ hành nghề',
          'coQuanCapCCHN': 'Cơ quan cấp CCHN',
        }.entries)
          if (p.containsKey(entry.key))
            field(entry.value, textOf(p, entry.key)),
        field(
          'Số ca hoàn thành',
          p['soLuongCaHoanThanh'] == null ? '' : '${p['soLuongCaHoanThanh']}',
        ),
      ],
    ),
  ]);
  Widget ratingSummary() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('DanhGia')
        .doc(widget.uid)
        .collection('DanhSachYeuCau')
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return section('ĐÁNH GIÁ', [
          const Text('Chưa tải được dữ liệu đánh giá.'),
        ]);
      }
      final scores = (snapshot.data?.docs ?? const [])
          .map((doc) => doc.data()['diemDanhGia'])
          .whereType<num>()
          .toList();
      final average = scores.isEmpty
          ? null
          : scores.reduce((a, b) => a + b) / scores.length;
      final oneStar = scores.where((score) => score == 1).length;
      return section('ĐÁNH GIÁ TỪ NGƯỜI DÙNG', [
        Row(
          children: [
            feedbackMetric(
              'Điểm trung bình',
              Icons.star_rounded,
              value: average == null ? '—' : average.toStringAsFixed(1),
              subtitle: 'trên 5 sao',
            ),
            const SizedBox(width: 10),
            feedbackMetric(
              'Tổng lượt',
              Icons.rate_review_outlined,
              value: '${scores.length}',
              subtitle: 'đánh giá',
            ),
            const SizedBox(width: 10),
            feedbackMetric(
              'Đánh giá 1 sao',
              Icons.flag_outlined,
              value: '$oneStar',
              subtitle: 'cần theo dõi',
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Điểm trung bình được tính trực tiếp từ các đánh giá trong DanhGia, không dùng số tổng hợp cũ trên hồ sơ.',
          style: TextStyle(fontSize: 11, color: Color(0xFF71829B), height: 1.4),
        ),
      ]);
    },
  );

  void openRecords(String kind, String title) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => Theme(
        data: accountTheme(context),
        child: Scaffold(
          appBar: AppBar(title: Text(title)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DanhSachBanGhi(
                repository: widget.repository,
                uid: widget.uid,
                kind: kind,
                title: title,
                initiallyExpanded: true,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget recordLink(
    String kind,
    String title,
    String subtitle,
    IconData icon,
  ) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      leading: Icon(icon, color: accountBlue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => openRecords(kind, title),
    ),
  );
  Widget feedbackMetric(
    String title,
    IconData icon, {
    String value = '—',
    String subtitle = 'Chưa có số liệu tổng hợp',
  }) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accountPanel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accountBlue),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          Text(title, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Color(0xFF71829B)),
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Theme(
    data: accountTheme(context),
    child: Builder(
      builder: (context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final c = controller, a = controller.account;
          return PopScope(
            canPop: !c.busy,
            child: Scaffold(
              backgroundColor: const Color(0xFFF8F8FF),
              appBar: AppBar(
                backgroundColor: Colors.white,
                title: const Text('Chi tiết tài khoản'),
                actions: [
                  IconButton(
                    tooltip: 'Tải lại',
                    onPressed: c.loading || c.busy
                        ? null
                        : () async {
                            await c.load();
                            if (mounted) setState(() => revision++);
                          },
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: c.loading
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
                      : a == null
                      ? const Text('Không có tài khoản.')
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                              child: Text(
                                'HỒ SƠ Y TẾ  •  Mã: ${a.uid}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: accountBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Card(
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    AnhDaiDienTaiKhoan(a, radius: 32),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                a.name,
                                                style: const TextStyle(
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              accountBadge(
                                                accountState(a),
                                                accountStateColor(a),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${a.phone.isEmpty ? "Chưa có SĐT" : a.phone}  |  ${a.uid}',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF71829B),
                                            ),
                                          ),
                                          const SizedBox(height: 9),
                                          Wrap(
                                            spacing: 5,
                                            runSpacing: 5,
                                            children: [
                                              accountBadge(
                                                accountTypeLabel(a),
                                                accountTypeColor(a),
                                              ),
                                              if (a.approved)
                                                accountBadge(
                                                  '✓ Đã xác minh',
                                                  accountBlue,
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Card(
                              child: ExpansionTile(
                                title: const Text(
                                  'Thông tin cá nhân',
                                  style: TextStyle(fontSize: 14),
                                ),
                                childrenPadding: const EdgeInsets.all(16),
                                children: [
                                  field('Email', textOf(a.data, 'email')),
                                  field(
                                    'Ngày sinh',
                                    dateText(a.data['ngaySinh']),
                                  ),
                                  field('Địa chỉ', textOf(a.data, 'diaChi')),
                                  field('Quê quán', textOf(a.data, 'queQuan')),
                                  field(
                                    'Ngày tạo',
                                    dateText(a.data['ngayTao']),
                                  ),
                                ],
                              ),
                            ),
                            if (a.professional != null)
                              profile('THÔNG TIN NGHIỆP VỤ', a.professional!),
                            if (a.volunteer != null)
                              profile(
                                'THÔNG TIN NGHIỆP VỤ · SƠ CỨU',
                                a.volunteer!,
                              ),
                            if (a.professional == null && a.volunteer == null)
                              section('Hồ sơ cứu hộ', [
                                const Text('Chưa có hồ sơ cứu hộ.'),
                              ]),
                            if (a.professional != null || a.volunteer != null)
                              ratingSummary(),
                            DanhSachCaHienTai(
                              repository: widget.repository,
                              uid: a.uid,
                              key: ValueKey('current-$revision'),
                            ),
                            Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                leading: const Icon(
                                  Icons.badge_outlined,
                                  color: accountBlue,
                                ),
                                title: const Text(
                                  'Hồ sơ xác minh',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                subtitle: const Text(
                                  'Xem hồ sơ và kết quả xét duyệt',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: openVerification,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => openRecords(
                                  'documents',
                                  'Giấy tờ đã tải lên',
                                ),
                                child: const Text(
                                  'Xem tất cả giấy tờ đã tải lên',
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Lịch sử hoạt động',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LichSuCuuHo(
                              repository: widget.repository,
                              uid: a.uid,
                              revision: revision,
                            ),
                            const SizedBox(height: 18),
                            section('Đánh giá & hồ sơ kỷ luật', [
                              ListTile(
                                tileColor: accountPanel,
                                leading: const Icon(
                                  Icons.verified_outlined,
                                  color: accountBlue,
                                ),
                                title: const Text(
                                  'Hồ sơ kỷ luật',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                subtitle: const Text(
                                  'Xem các bản ghi xử lý đã được ghi nhận.',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () =>
                                    openRecords('discipline', 'Hồ sơ kỷ luật'),
                              ),
                              const SizedBox(height: 10),
                              TextButton.icon(
                                onPressed: () => openRecords(
                                  'ratings',
                                  'Đánh giá liên quan',
                                ),
                                icon: const Icon(Icons.star_outline),
                                label: const Text('Xem các đánh giá liên quan'),
                              ),
                            ]),
                            DanhSachBanGhi(
                              key: ValueKey('audit-$revision'),
                              repository: widget.repository,
                              uid: a.uid,
                              kind: 'audit',
                              title: 'Lịch sử xử lý tài khoản',
                              initiallyExpanded: true,
                            ),
                            section('Hạn chế tài khoản · thao tác nhạy cảm', [
                              const Text(
                                'Chỉ thực hiện khi đã xác minh đúng tài khoản. Mỗi thao tác cần xác nhận lý do.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFBF1736),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ...[
                                    const Text(
                                      'Quyền hỗ trợ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: accountPanel,
                                        foregroundColor: const Color(
                                          0xFFCE3434,
                                        ),
                                      ),
                                      onPressed: c.busy
                                          ? null
                                          : () => perform(
                                              a.suspended
                                                  ? 'khoi_phuc'
                                                  : 'tam_ngung',
                                              a.suspended
                                                  ? 'Khôi phục quyền hỗ trợ'
                                                  : 'Tạm ngừng quyền hỗ trợ',
                                            ),
                                      icon: Icon(
                                        a.suspended
                                            ? Icons.play_circle_outline
                                            : Icons.pause_circle_outline,
                                      ),
                                      label: Text(
                                        a.suspended
                                            ? 'Khôi phục quyền hỗ trợ'
                                            : 'Tạm ngừng quyền hỗ trợ',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Tạm ngừng nhận ca mới; tài khoản vẫn sử dụng các chức năng cá nhân.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF71829B),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                  const Text(
                                    'Quyền truy cập hệ thống',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFDDDA),
                                      foregroundColor: const Color(0xFFBF2525),
                                    ),
                                    onPressed: c.busy
                                        ? null
                                        : () => perform(
                                            a.locked ? 'mo_khoa' : 'khoa',
                                            a.locked
                                                ? 'Mở khóa trong ứng dụng'
                                                : 'Khóa trong ứng dụng',
                                          ),
                                    icon: Icon(
                                      a.locked ? Icons.lock_open : Icons.block,
                                    ),
                                    label: Text(
                                      a.locked
                                          ? 'Mở khóa trong ứng dụng'
                                          : 'Khóa trong ứng dụng',
                                    ),
                                  ),
                                ],
                              ),
                              if (c.busy) const LinearProgressIndicator(),
                            ]),
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

class DanhSachCaHienTai extends StatefulWidget {
  final NguonTaiKhoan repository;
  final String uid;
  const DanhSachCaHienTai({
    super.key,
    required this.repository,
    required this.uid,
  });
  @override
  State<DanhSachCaHienTai> createState() => _DanhSachCaHienTaiState();
}

class _DanhSachCaHienTaiState extends State<DanhSachCaHienTai> {
  late final controller = CaHienTaiController(widget.repository, widget.uid);
  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '● ĐANG THAM GIA CẤP CỨU',
              style: const TextStyle(
                color: accountBlue,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            if (controller.loading) const LinearProgressIndicator(),
            if (controller.error != null) ...[
              Text(controller.error!),
              TextButton(
                onPressed: controller.load,
                child: const Text('Thử lại'),
              ),
            ],
            if (!controller.loading &&
                controller.error == null &&
                controller.items.isEmpty)
              const Text('Không có ca đang xử lý trong dữ liệu hiện tại.'),
            for (final r in controller.items)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accountPanel,
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(
                    left: BorderSide(color: accountBlue, width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'SOS ${r.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: accountBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Tình trạng: ${r.text('maTinhTrangYeuCau')}'),
                    Text(
                      'Vị trí: ${r.text('viDo')}, ${r.text('kinhDo')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF71829B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChiTietYeuCauScreen(id: r.id),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new, size: 17),
                      label: const Text('Xem chi tiết SOS'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class LichSuCuuHo extends StatefulWidget {
  final NguonTaiKhoan repository;
  final String uid;
  final int revision;
  const LichSuCuuHo({
    super.key,
    required this.repository,
    required this.uid,
    required this.revision,
  });
  @override
  State<LichSuCuuHo> createState() => _LichSuCuuHoState();
}

class _LichSuCuuHoState extends State<LichSuCuuHo> {
  int active = 0;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SegmentedButton<int>(
        segments: const [
          ButtonSegment(
            value: 0,
            label: Text('Đã gửi'),
            icon: Icon(Icons.call_made),
          ),
          ButtonSegment(
            value: 1,
            label: Text('Đã hỗ trợ'),
            icon: Icon(Icons.medical_services_outlined),
          ),
        ],
        selected: {active},
        onSelectionChanged: (values) => setState(() => active = values.first),
      ),
      DanhSachBanGhi(
        key: ValueKey('history-${widget.uid}-$active-${widget.revision}'),
        repository: widget.repository,
        uid: widget.uid,
        kind: active == 0 ? 'sent' : 'helped',
        title: active == 0 ? 'Yêu cầu SOS đã gửi' : 'Ca SOS đã hỗ trợ',
        initiallyExpanded: true,
      ),
    ],
  );
}
