import 'package:flutter/material.dart';

import '../DangNhap/controllers/dang_nhap_controller.dart';
import 'controllers/xac_minh_controller.dart';
import 'models/xac_minh_model.dart';
import 'services/xac_minh_service.dart';
import '../DangNhap/thong_tin_quan_tri_screen.dart';
import 'chi_tiet_xac_minh_screen.dart';
import '../../widgets/giao_dien_tai_khoan.dart';
import '../../widgets/trang_cuon.dart';
import '../../widgets/giao_dien_xac_minh.dart';

class XacMinhScreen extends StatefulWidget {
  final DangNhapController auth;
  final NguonXacMinh? repository;
  const XacMinhScreen({super.key, required this.auth, this.repository});
  @override
  State<XacMinhScreen> createState() => _XacMinhScreenState();
}

class _XacMinhScreenState extends State<XacMinhScreen> {
  late final c = XacMinhController(widget.repository ?? XacMinhService());
  final focus = FocusNode();
  @override
  void initState() {
    super.initState();
    c.load();
  }

  @override
  void dispose() {
    focus.dispose();
    c.dispose();
    super.dispose();
  }

  void adminInfo() => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ThongTinQuanTriScreen(auth: widget.auth),
    ),
  );

  Widget filterButton<T>(
    String label,
    IconData icon,
    List<PopupMenuEntry<T>> entries,
    void Function(T) select,
  ) => Container(
    margin: const EdgeInsets.only(right: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: xmBorder),
      borderRadius: BorderRadius.circular(9),
    ),
    child: PopupMenuButton<T>(
      onSelected: select,
      itemBuilder: (_) => entries,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: xmMuted),
            const SizedBox(width: 7),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Icon(Icons.arrow_drop_down, color: xmMuted),
          ],
        ),
      ),
    ),
  );
  String _waitingLabel(HoSoXacMinh profile) {
    final submitted = profile.submitted;
    if (submitted == null) return 'Chưa có ngày nộp';
    final hours = DateTime.now().difference(submitted).inHours;
    if (hours < 0) return 'Vừa nộp';
    if (hours < 24) return 'Chờ ${hours < 1 ? 1 : hours} giờ';
    return 'Chờ ${hours ~/ 24} ngày';
  }

  String _documentHint(HoSoXacMinh profile) {
    // Danh sách không tải LuuAnh chứa payload ảnh; không suy đoán
    // giấy tờ còn thiếu khi chưa có dữ liệu tổng hợp trong hồ sơ.
    final missing = profile.data['giayToConThieu'];
    if (missing is List && missing.isNotEmpty) {
      return 'Cần xem: ${missing.map((v) => v.toString()).take(2).join(', ')}';
    }
    return 'Chạm để kiểm tra giấy tờ và ảnh hồ sơ';
  }

  Future<void> open(HoSoXacMinh p) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChiTietXacMinhScreen(
          collection: p.collection,
          uid: p.uid,
          repository: c.repository,
        ),
      ),
    );
    if (mounted) await c.load();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: verificationTheme(context),
    child: Builder(
      builder: (context) => ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          final results = c.filtered;
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text(
                'Xác minh người hỗ trợ',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              actions: [
                IconButton(
                  tooltip: 'Tìm kiếm',
                  onPressed: focus.requestFocus,
                  icon: const Icon(Icons.search),
                ),
                IconButton(
                  tooltip: 'Hồ sơ Admin',
                  onPressed: adminInfo,
                  icon: const Icon(Icons.account_circle_outlined),
                ),
              ],
            ),
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: xmBorder)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    nav(
                      Icons.emergency_outlined,
                      'Yêu cầu',
                      false,
                      () => Navigator.pushReplacementNamed(context, '/yeu-cau'),
                    ),
                    nav(
                      Icons.people_outline,
                      'Tài khoản',
                      false,
                      () =>
                          Navigator.pushReplacementNamed(context, '/tai-khoan'),
                    ),
                    nav(Icons.verified_user, 'Xác minh', true, () {}, badge: 0),
                    nav(
                      Icons.query_stats_rounded,
                      'Báo cáo',
                      false,
                      () => Navigator.pushReplacementNamed(context, '/bao-cao'),
                    ),
                    nav(
                      Icons.medical_services_outlined,
                      'Kỹ năng',
                      false,
                      () => Navigator.pushReplacementNamed(context, '/ky-nang'),
                    ),
                  ],
                ),
              ),
            ),
            body: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: RefreshIndicator(
                    onRefresh: c.load,
                    child: ScrollPage(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final p = results[index];
                        return Semantics(
                          button: true,
                          label: 'Mở hồ sơ ${p.name}',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => open(p),
                            child: XmCard(
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      XmAvatar(p.name, p.collection),
                                      const SizedBox(width: 12),
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
                                                  p.name,
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                XmStatus(p.status),
                                              ],
                                            ),
                                            const SizedBox(height: 7),
                                            Text(
                                              '${p.typeLabel} · ${_waitingLabel(p)}',
                                              style: const TextStyle(
                                                color: xmMuted,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              'Mã: ${p.code}',
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
                                  const SizedBox(height: 7),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _documentHint(p),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: xmMuted,
                                      ),
                                    ),
                                  ),
                                  const Divider(),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Wrap(
                                          spacing: 12,
                                          runSpacing: 8,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            accountBadge(
                                              p.collection ==
                                                      profileCollections.first
                                                  ? 'Có CCHN'
                                                  : 'Không CCHN',
                                              p.collection ==
                                                      profileCollections.first
                                                  ? const Color(0xFF1D4ED8)
                                                  : const Color(0xFF0F766E),
                                            ),
                                            if (!p.accountExists)
                                              accountBadge(
                                                'Thiếu tài khoản',
                                                const Color(0xFFB91C1C),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: xmMuted,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      footer: [
                        if (c.hasMore)
                          OutlinedButton(
                            onPressed: c.loading ? null : c.more,
                            child: Text(c.loading ? 'Đang tải…' : 'Tải thêm'),
                          ),
                      ],
                      onMore: c.more,
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                      children: [
                        if (c.status == 'cho_duyet')
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              'Hàng đợi chờ duyệt · ${results.length} hồ sơ đã tải',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: xmBlue,
                              ),
                            ),
                          ),
                        TextField(
                          focusNode: focus,
                          onChanged: (v) => c.filter(q: v),
                          decoration: InputDecoration(
                            hintText: 'Tìm tên, số điện thoại, mã hồ sơ',
                            helperText: c.hasMore
                                ? 'Tìm, lọc và sắp xếp trong ${c.items.length} hồ sơ đã tải'
                                : null,
                            prefixIcon: const Icon(
                              Icons.search,
                              color: xmMuted,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(32),
                              borderSide: const BorderSide(color: xmBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(32),
                              borderSide: const BorderSide(color: xmBorder),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final key in [
                                'cho_duyet',
                                'can_bo_sung',
                                'da_duyet',
                              ])
                                InkWell(
                                  onTap: () => c.filter(s: key),
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(
                                      0,
                                      14,
                                      18,
                                      14,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: c.status == key
                                              ? xmBlue
                                              : Colors.transparent,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          verificationStatuses[key]!,
                                          style: TextStyle(
                                            color: c.status == key
                                                ? xmBlue
                                                : xmMuted,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Tooltip(
                                          message: 'Số hồ sơ đã tải',
                                          child: accountBadge(
                                            '${c.items.where((p) => p.status == key).length}',
                                            c.status == key ? xmBlue : xmMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              filterButton<String>(
                                'Loại hồ sơ: ${verificationTypes[c.type] ?? "Tất cả"}',
                                Icons.medical_services_outlined,
                                [
                                  const PopupMenuItem(
                                    value: '',
                                    child: Text('Tất cả'),
                                  ),
                                  ...verificationTypes.entries.map(
                                    (r) => PopupMenuItem(
                                      value: r.key,
                                      child: Text(r.value),
                                    ),
                                  ),
                                ],
                                (v) => c.filter(t: v),
                              ),
                              if (c.items.any((p) => p.submitted != null))
                                filterButton<bool>(
                                  'Ngày nộp: ${c.newest ? "Mới nhất" : "Cũ nhất"}',
                                  Icons.calendar_today_outlined,
                                  const [
                                    PopupMenuItem(
                                      value: true,
                                      child: Text('Mới nhất'),
                                    ),
                                    PopupMenuItem(
                                      value: false,
                                      child: Text('Cũ nhất'),
                                    ),
                                  ],
                                  (v) => c.filter(n: v),
                                ),
                              filterButton<String>(
                                verificationStatuses[c.status] ??
                                    'Tất cả trạng thái',
                                Icons.fact_check_outlined,
                                [
                                  const PopupMenuItem(
                                    value: '',
                                    child: Text('Tất cả trạng thái'),
                                  ),
                                  ...verificationStatuses.entries.map(
                                    (s) => PopupMenuItem(
                                      value: s.key,
                                      child: Text(s.value),
                                    ),
                                  ),
                                ],
                                (v) => c.filter(s: v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (c.loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: LinearProgressIndicator(),
                          ),
                        if (c.error != null)
                          XmCard(
                            child: Column(
                              children: [
                                Text(
                                  c.error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const Text('Dữ liệu có thể chưa cập nhật.'),
                                TextButton(
                                  onPressed: c.load,
                                  child: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                        if (results.isEmpty && !c.loading && c.error == null)
                          const XmCard(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.folder_open,
                                  size: 42,
                                  color: xmMuted,
                                ),
                                SizedBox(height: 10),
                                Text('Không có hồ sơ phù hợp.'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
  Widget nav(
    IconData icon,
    String label,
    bool selected,
    VoidCallback? action, {
    int badge = 0,
  }) => mucDieuHuong(icon, label, action, selected: selected, badge: badge);
}
