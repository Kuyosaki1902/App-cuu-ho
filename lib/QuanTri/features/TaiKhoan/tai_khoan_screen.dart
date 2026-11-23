import 'quan_ly_admin_screen.dart';
import 'package:flutter/material.dart';

import 'controllers/tai_khoan_controller.dart';
import '../DangNhap/controllers/dang_nhap_controller.dart';
import 'services/tai_khoan_service.dart';
import 'chi_tiet_tai_khoan_screen.dart';
import '../DangNhap/thong_tin_quan_tri_screen.dart';
import '../../widgets/giao_dien_tai_khoan.dart';
import '../../widgets/trang_cuon.dart';

const _sea = Color(0xFF0964BE);
const _canvas = Color(0xFFF6F7FB);

class TaiKhoanScreen extends StatefulWidget {
  final DangNhapController auth;
  final NguonTaiKhoan? repository;
  const TaiKhoanScreen({super.key, required this.auth, this.repository});
  @override
  State<TaiKhoanScreen> createState() => _TaiKhoanScreenState();
}

class _TaiKhoanScreenState extends State<TaiKhoanScreen> {
  late final controller = TaiKhoanController(
    widget.repository ?? TaiKhoanService(),
  );
  final search = TextEditingController();
  final searchFocus = FocusNode();
  bool advanced = false;

  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  void dispose() {
    controller.dispose();
    search.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  void adminInfo() => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ThongTinQuanTriScreen(auth: widget.auth),
    ),
  );

  Future<void> selectNavigation(int index) async {
    if (index == 1) return;
    final route = index == 0
        ? '/yeu-cau'
        : index == 2
        ? '/xac-minh'
        : null;
    if (route != null) Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: accountTheme(context),
    child: Builder(
      builder: (context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final c = controller;
          final filtered = c.filtered;
          return Scaffold(
            backgroundColor: _canvas,
            appBar: AppBar(
              backgroundColor: Colors.white,
              leading: const Icon(
                Icons.local_hospital_outlined,
                color: accountBlue,
              ),
              title: const Text(
                'Tài khoản',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  tooltip: 'Quản lý đánh giá',
                  onPressed: () => Navigator.pushNamed(context, '/danh-gia'),
                  icon: const Icon(Icons.star_outline_rounded),
                ),
                IconButton(
                  tooltip: 'Tìm kiếm nhanh',
                  onPressed: () => searchFocus.requestFocus(),
                  icon: const Icon(Icons.search),
                ),
                IconButton(
                  tooltip: 'Hồ sơ Admin',
                  onPressed: adminInfo,
                  icon: const Icon(Icons.account_circle_outlined),
                ),
              ],
            ),
            bottomNavigationBar: DieuHuongTaiKhoan(
              onReports: () =>
                  Navigator.pushReplacementNamed(context, '/bao-cao'),
              onRequests: () => selectNavigation(0),
              onVerification: () => selectNavigation(2),
              onSkills: () =>
                  Navigator.pushReplacementNamed(context, '/ky-nang'),
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: RefreshIndicator(
                  onRefresh: c.load,
                  child: ScrollPage(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final a = filtered[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: Colors.white,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ChiTietTaiKhoanScreen(
                                  uid: a.uid,
                                  roles: c.roles,
                                  repository: c.repository,
                                ),
                              ),
                            );
                            if (mounted) await c.load();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              children: [
                                AnhDaiDienTaiKhoan(a),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 5,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            a.name,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                a.locked
                                                    ? Icons.lock_outline
                                                    : a.suspended
                                                    ? Icons.pause_circle_outline
                                                    : Icons
                                                          .check_circle_outline,
                                                size: 17,
                                                color: accountStateColor(a),
                                              ),
                                              const SizedBox(width: 4),
                                              accountBadge(
                                                a.locked
                                                    ? 'Bị khóa'
                                                    : a.suspended
                                                    ? 'Tạm ngưng hỗ trợ'
                                                    : 'Đang hoạt động',
                                                accountStateColor(a),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        'Mã: ${a.uid}  ·  ${a.phone.isEmpty
                                            ? "Chưa có SĐT"
                                            : a.phone.length > 5
                                            ? "${a.phone.substring(0, 2)}• ••• ${a.phone.substring(a.phone.length - 3)}"
                                            : "•••"}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 7),
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
                                const Icon(Icons.chevron_right, color: _sea),
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
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.admin_panel_settings_outlined,
                            color: accountBlue,
                          ),
                          title: const Text('Quản lý tài khoản admin'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const QuanLyAdminScreen(),
                            ),
                          ),
                        ),
                      ),
                      if (c.loading) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(),
                      ],
                      if (c.error != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Text(
                                  c.error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const Text(
                                  'Kết quả hiện tại có thể chưa được cập nhật.',
                                ),
                                TextButton(
                                  onPressed: c.loading ? null : c.load,
                                  child: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: search,
                        focusNode: searchFocus,
                        onChanged: c.search,
                        decoration: InputDecoration(
                          hintText: 'Tìm họ tên, số điện thoại, mã tài khoản',
                          helperText: c.hasMore
                              ? 'Tìm và lọc trong ${c.items.length} tài khoản đã tải'
                              : null,
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: search.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Xóa tìm kiếm',
                                  onPressed: () {
                                    search.clear();
                                    c.search('');
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final f in {
                              'all': 'Tất cả',
                              'support': 'Có quyền hỗ trợ',
                              'locked': 'Bị khóa',
                            }.entries)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(f.value),
                                  selected: c.filter == f.key,
                                  selectedColor: const Color(0xFFD7E7FF),
                                  onSelected: (_) => c.setFilter(f.key),
                                ),
                              ),
                            ActionChip(
                              avatar: const Icon(Icons.tune, size: 18),
                              label: const Text('Lọc nâng cao'),
                              onPressed: () =>
                                  setState(() => advanced = !advanced),
                            ),
                          ],
                        ),
                      ),
                      if (advanced)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    for (final f in {
                                      'verified': 'Đã xác minh',
                                      'suspended': 'Tạm ngừng hỗ trợ',
                                    }.entries)
                                      FilterChip(
                                        label: Text(f.value),
                                        selected: c.filter == f.key,
                                        onSelected: (_) => c.setFilter(
                                          c.filter == f.key ? 'all' : f.key,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),
                      if (filtered.isEmpty && !c.loading && c.error == null)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(35),
                            child: Center(
                              child: Text('Không có tài khoản phù hợp.'),
                            ),
                          ),
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
