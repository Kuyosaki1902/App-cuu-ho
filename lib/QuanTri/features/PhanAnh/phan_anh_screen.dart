import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/xu_ly_loi.dart';
import '../../models/ban_ghi.dart';
import '../../widgets/giao_dien_tai_khoan.dart';
import '../../widgets/trang_cuon.dart';
import '../TaiKhoan/models/tai_khoan_model.dart';
import '../YeuCauHoTro/chi_tiet_yeu_cau_screen.dart';
import 'services/phan_anh_service.dart';

const _reviewInk = Color(0xFF193052);
const _reviewMuted = Color(0xFF71829B);
const _reviewOrange = Color(0xFFB54708);

bool _priority(BanGhi r) => [1, '1'].contains(r.data['diemDanhGia']);
String _state(BanGhi r) => r.text('trangThaiXuLy', 'chua_xu_ly');
String _label(BanGhi r) =>
    const {
      'chua_xu_ly': 'Chưa xử lý',
      'dang_xu_ly': 'Đang xử lý',
      'da_xu_ly': 'Đã xử lý',
    }[_state(r)] ??
    'Chưa rõ trạng thái';

class PhanAnhScreen extends StatefulWidget {
  final String actor;
  const PhanAnhScreen({super.key, required this.actor});
  @override
  State<PhanAnhScreen> createState() => _PhanAnhScreenState();
}

class _PhanAnhScreenState extends State<PhanAnhScreen> {
  final service = PhanAnhService();
  final rows = <BanGhi>[];
  DocumentSnapshot<Map<String, dynamic>>? cursor;
  bool priority = true, busy = false, more = true;
  String? error;
  int generation = 0;
  BanGhi? recipient;
  StreamSubscription<TrangBanGhi>? _firstPageSubscription;
  List<BanGhi> _firstPage = [];
  List<BanGhi> _olderPages = [];

  void _mergeReviewPages() {
    final combined = <String, BanGhi>{};
    for (final row in _firstPage) {
      combined[row.path ?? row.id] = row;
    }
    for (final row in _olderPages) {
      combined.putIfAbsent(row.path ?? row.id, () => row);
    }
    rows
      ..clear()
      ..addAll(combined.values);
  }

  Future<void> chooseRecipient() async {
    final person = await showDialog<BanGhi>(
      context: context,
      builder: (_) => _ChonNguoiCuuHo(service: service),
    );
    if (!mounted || person == null || person.id == recipient?.id) return;
    setState(() => recipient = person);
    await load(reset: true);
  }

  @override
  void initState() {
    super.initState();
    load(reset: true);
  }

  Future<void> load({bool reset = false}) async {
    if (!reset && (busy || !more)) return;
    if (reset) {
      await _firstPageSubscription?.cancel();
      _firstPageSubscription = null;
      final token = ++generation;
      setState(() {
        _firstPage = [];
        _olderPages = [];
        rows.clear();
        cursor = null;
        more = true;
        busy = true;
        error = null;
      });
      if (priority) {
        _firstPageSubscription = service
            .watchFirstOneStar(recipient: recipient?.id)
            .listen(
              (page) {
                if (!mounted || token != generation) return;
                setState(() {
                  _firstPage = page.items;
                  if (_olderPages.isEmpty) {
                    cursor = page.cursor;
                    more = page.hasMore;
                  }
                  _mergeReviewPages();
                  busy = false;
                  error = null;
                });
              },
              onError: (Object failure) async {
                if (!mounted || token != generation) return;
                // Missing collection-group index: use the original one-off query.
                // Real-time mode is restored once the index is created.
                try {
                  final page = await service.page(
                    true,
                    null,
                    recipient: recipient?.id,
                  );
                  if (!mounted || token != generation) return;
                  setState(() {
                    _firstPage = page.items;
                    cursor = page.cursor;
                    more = page.hasMore;
                    _mergeReviewPages();
                    busy = false;
                    error = null;
                  });
                } catch (fallbackError) {
                  if (!mounted || token != generation) return;
                  setState(() {
                    error = friendlyError(fallbackError);
                    busy = false;
                  });
                }
              },
            );
        return;
      }
    }
    final current = generation;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final page = await service.page(
        priority,
        cursor,
        recipient: recipient?.id,
      );
      if (!mounted || current != generation) return;
      setState(() {
        _olderPages = <String, BanGhi>{
          for (final row in _olderPages) row.path ?? row.id: row,
          for (final row in page.items) row.path ?? row.id: row,
        }.values.toList();
        _mergeReviewPages();
        cursor = page.cursor;
        more = page.hasMore;
      });
    } catch (e) {
      if (mounted && current == generation) {
        setState(() => error = friendlyError(e));
      }
    } finally {
      if (mounted && current == generation) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    _firstPageSubscription?.cancel();
    super.dispose();
  }

  Future<void> open(BanGhi review) async {
    final path = review.path;
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không xác định được đường dẫn đánh giá.'),
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            _ChiTietDanhGia(path: path, actor: widget.actor, service: service),
      ),
    );
    // The first-page listener receives the changed review automatically.
    if (mounted && !priority) await load(reset: true);
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: accountTheme(context),
    child: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'Quản lý đánh giá',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'Làm mới',
              onPressed: busy ? null : () => load(reset: true),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE0E7F0))),
            ),
            child: Row(
              children: [
                mucDieuHuong(
                  Icons.emergency_outlined,
                  'Yêu cầu',
                  () => Navigator.pushReplacementNamed(context, '/yeu-cau'),
                ),
                mucDieuHuong(
                  Icons.people_outline,
                  'Tài khoản',
                  () => Navigator.pushReplacementNamed(context, '/tai-khoan'),
                ),
                mucDieuHuong(
                  Icons.verified_user_outlined,
                  'Xác minh',
                  () => Navigator.pushReplacementNamed(context, '/xac-minh'),
                ),
                mucDieuHuong(
                  Icons.query_stats_rounded,
                  'Báo cáo',
                  () => Navigator.pushReplacementNamed(context, '/bao-cao'),
                ),
                mucDieuHuong(
                  Icons.medical_services_outlined,
                  'Kỹ năng',
                  () => Navigator.pushReplacementNamed(context, '/ky-nang'),
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: RefreshIndicator(
                onRefresh: () => load(reset: true),
                child: ScrollPage(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  onMore: () => error == null ? load() : Future.value(),
                  itemCount: rows.length,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ReviewMetric(
                            icon: Icons.star_outline_rounded,
                            label: 'Đã hiển thị',
                            value: '${rows.length}${more ? '+' : ''}',
                            color: accountBlue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ReviewMetric(
                            icon: Icons.flag_outlined,
                            label: 'Chế độ ưu tiên',
                            value: priority ? '1 sao' : 'Tất cả',
                            color: priority
                                ? _reviewOrange
                                : const Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 3,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: accountBlue.withValues(alpha: .09),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_search_outlined,
                            color: accountBlue,
                          ),
                        ),
                        title: Text(
                          recipient == null
                              ? 'Lọc theo người cứu hộ'
                              : _ten(recipient!),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          recipient == null
                              ? 'Đang xem đánh giá của tất cả người cứu hộ'
                              : recipient!.id,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _reviewMuted,
                          ),
                        ),
                        onTap: chooseRecipient,
                        trailing: recipient == null
                            ? const Icon(Icons.chevron_right)
                            : IconButton(
                                tooltip: 'Bỏ bộ lọc',
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() => recipient = null);
                                  load(reset: true);
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          avatar: const Icon(Icons.flag_outlined, size: 16),
                          label: const Text('Ưu tiên · 1 sao'),
                          selected: priority,
                          onSelected: (_) {
                            if (!priority) {
                              setState(() => priority = true);
                              load(reset: true);
                            }
                          },
                        ),
                        ChoiceChip(
                          avatar: const Icon(
                            Icons.view_list_outlined,
                            size: 16,
                          ),
                          label: const Text('Tất cả đánh giá'),
                          selected: !priority,
                          onSelected: (_) {
                            if (priority) {
                              setState(() => priority = false);
                              load(reset: true);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Danh sách đánh giá',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _reviewInk,
                            ),
                          ),
                        ),
                        Text(
                          '${rows.length} bản ghi',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _reviewMuted,
                          ),
                        ),
                      ],
                    ),
                    if (!busy && error == null && rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 22),
                        child: _ReviewEmpty(
                          title: priority
                              ? 'Chưa có đánh giá 1 sao'
                              : 'Chưa có đánh giá',
                          message:
                              'Đánh giá do người dùng gửi sẽ xuất hiện tại đây.',
                        ),
                      ),
                  ],
                  itemBuilder: (_, index) {
                    final review = rows[index];
                    final one = _priority(review);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => open(review),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: one
                                          ? const Color(0xFFFFF1E8)
                                          : const Color(0xFFFFF8E1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.star_rounded,
                                      color: one
                                          ? _reviewOrange
                                          : const Color(0xFFD69E17),
                                    ),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${review.data['diemDanhGia']?.toString() ?? '—'} / 5 sao',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: _reviewInk,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'SOS ${review.text('maYeuCau', '—')} · ${dateText(review.data['ngayTao'])}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: _reviewMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (one)
                                    accountBadge(
                                      _label(review),
                                      _state(review) == 'da_xu_ly'
                                          ? const Color(0xFF0F766E)
                                          : _reviewOrange,
                                    ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: _reviewMuted,
                                  ),
                                ],
                              ),
                              if (review
                                  .text('nhanXet', '')
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  review.text('nhanXet'),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.45,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 14,
                                runSpacing: 5,
                                children: [
                                  _ReviewMeta(
                                    icon: Icons.person_outline,
                                    text:
                                        'Người cứu hộ: ${review.text('maNguoiCuuHo', '—')}',
                                  ),
                                  _ReviewMeta(
                                    icon: Icons.account_circle_outlined,
                                    text:
                                        'Người đánh giá: ${review.text('maNguoiDanhGia', '—')}',
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
                    if (busy)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    if (error != null)
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    if (!busy && (more || error != null))
                      Center(
                        child: TextButton.icon(
                          onPressed: () => load(),
                          icon: const Icon(Icons.expand_more),
                          label: Text(
                            error == null ? 'Tải thêm đánh giá' : 'Thử tải lại',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ChiTietDanhGia extends StatefulWidget {
  final String path;
  final String actor;
  final PhanAnhService service;
  const _ChiTietDanhGia({
    required this.path,
    required this.actor,
    required this.service,
  });
  @override
  State<_ChiTietDanhGia> createState() => _ChiTietDanhGiaState();
}

class _ChiTietDanhGiaState extends State<_ChiTietDanhGia> {
  late final review = widget.service.watch(widget.path);
  final note = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> save(bool finish) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.service.update(
        widget.path,
        widget.actor,
        result: finish ? note.text : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              finish ? 'Đã lưu kết quả xử lý.' : 'Bạn đã tiếp nhận đánh giá.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: accountTheme(context),
    child: Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đánh giá')),
      body: StreamBuilder<BanGhi?>(
        stream: review,
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text(friendlyError(snapshot.error!)));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final r = snapshot.data;
          if (r == null)
            return const Center(child: Text('Đánh giá không còn tồn tại.'));
          final request = r.text('maYeuCau', '').trim();
          final one = _priority(r);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: one
                          ? const Color(0xFFFFF4ED)
                          : const Color(0xFFFFF9E8),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: one
                            ? const Color(0xFFF6D2BF)
                            : const Color(0xFFF2E2B7),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 38,
                          color: Color(0xFFD69E17),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${r.data['diemDanhGia']?.toString() ?? '—'} / 5 sao',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: _reviewInk,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                one
                                    ? 'Đánh giá cần ưu tiên theo dõi'
                                    : 'Đánh giá của người dùng',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _reviewMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (one)
                          accountBadge(
                            _label(r),
                            _state(r) == 'da_xu_ly'
                                ? const Color(0xFF0F766E)
                                : _reviewOrange,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nội dung đánh giá',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _reviewInk,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SelectableText(
                            r.text(
                              'nhanXet',
                              'Người dùng không để lại nhận xét.',
                            ),
                            style: const TextStyle(
                              height: 1.5,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông tin liên quan',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _reviewInk,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _DetailLine(
                            icon: Icons.account_circle_outlined,
                            label: 'Người đánh giá',
                            value: r.text(
                              'maNguoiDanhGia',
                              'Chưa có thông tin',
                            ),
                          ),
                          _DetailLine(
                            icon: Icons.volunteer_activism_outlined,
                            label: 'Người cứu hộ',
                            value: r.text('maNguoiCuuHo', 'Chưa có thông tin'),
                          ),
                          _DetailLine(
                            icon: Icons.calendar_today_outlined,
                            label: 'Ngày đánh giá',
                            value: dateText(r.data['ngayTao']),
                          ),
                          _DetailLine(
                            icon: Icons.route_outlined,
                            label: 'Mã yêu cầu',
                            value: request.isEmpty
                                ? 'Chưa có thông tin'
                                : request,
                          ),
                          if (request.isNotEmpty && !request.contains('/'))
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                icon: const Icon(Icons.open_in_new),
                                label: Text('Xem ca $request'),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        ChiTietYeuCauScreen(id: request),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (one) ...[
                    const SizedBox(height: 4),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quy trình xử lý đánh giá 1 sao',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _reviewInk,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _label(r),
                              style: const TextStyle(
                                fontSize: 12,
                                color: _reviewMuted,
                              ),
                            ),
                            if (r.data['maAdminXuLy'] != null)
                              _DetailLine(
                                icon: Icons.admin_panel_settings_outlined,
                                label: 'Admin phụ trách',
                                value: r.text('maAdminXuLy'),
                              ),
                            if (r.data['ngayCapNhatXuLy'] != null)
                              _DetailLine(
                                icon: Icons.update_outlined,
                                label: 'Cập nhật',
                                value: dateText(r.data['ngayCapNhatXuLy']),
                              ),
                            if (_state(r) == 'chua_xu_ly') ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: busy ? null : () => save(false),
                                  icon: const Icon(
                                    Icons.assignment_turned_in_outlined,
                                  ),
                                  label: const Text('Tiếp nhận xử lý'),
                                ),
                              ),
                            ],
                            if (_state(r) == 'dang_xu_ly' &&
                                r.data['maAdminXuLy'] == widget.actor) ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: note,
                                maxLines: 3,
                                maxLength: 500,
                                enabled: !busy,
                                decoration: const InputDecoration(
                                  labelText: 'Kết quả xử lý',
                                  hintText:
                                      'Ghi lại nội dung đã kiểm tra và kết quả xử lý',
                                  alignLabelWithHint: true,
                                ),
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: busy ? null : () => save(true),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Hoàn tất xử lý'),
                                ),
                              ),
                            ],
                            if (_state(r) == 'dang_xu_ly' &&
                                r.data['maAdminXuLy'] != widget.actor)
                              const Text(
                                'Đánh giá đang do Admin khác phụ trách.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _reviewMuted,
                                ),
                              ),
                            if (_state(r) == 'da_xu_ly')
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Kết quả: ${r.text('ketQuaXuLy', 'Chưa có ghi nhận')}',
                                  style: const TextStyle(
                                    color: Color(0xFF027A48),
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            if (error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _ReviewMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _ReviewMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE0E7F0)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _reviewInk,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: _reviewMuted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ReviewMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ReviewMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: _reviewMuted),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 10, color: _reviewMuted)),
    ],
  );
}

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: accountBlue),
        const SizedBox(width: 9),
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: _reviewMuted),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _reviewInk,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ReviewEmpty extends StatelessWidget {
  final String title;
  final String message;
  const _ReviewEmpty({required this.title, required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE0E7F0)),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.rate_review_outlined,
          size: 36,
          color: Color(0xFF8CA0B8),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: _reviewInk,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: _reviewMuted),
        ),
      ],
    ),
  );
}

String _ten(BanGhi person) {
  final name = person.text('hoTen', '').trim();
  return name.isEmpty ? 'Chưa có tên' : name;
}

class _ChonNguoiCuuHo extends StatefulWidget {
  final PhanAnhService service;
  const _ChonNguoiCuuHo({required this.service});
  @override
  State<_ChonNguoiCuuHo> createState() => _ChonNguoiCuuHoState();
}

class _ChonNguoiCuuHoState extends State<_ChonNguoiCuuHo> {
  final people = <BanGhi>[];
  DocumentSnapshot<Map<String, dynamic>>? cursor;
  bool busy = false, more = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (busy || !more) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final page = await widget.service.rescuers(cursor);
      if (!mounted) return;
      setState(() {
        people.addAll(page.items);
        more = page.hasMore;
        cursor = page.cursor;
      });
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Chọn người cứu hộ'),
    content: SizedBox(
      width: 420,
      height: MediaQuery.sizeOf(context).height * .45,
      child: ScrollPage(
        padding: EdgeInsets.zero,
        children: const [],
        onMore: () => error == null ? load() : Future.value(),
        itemCount: people.length,
        itemBuilder: (_, index) => ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
          title: Text(_ten(people[index])),
          subtitle: Text(people[index].id),
          onTap: () => Navigator.pop(context, people[index]),
        ),
        footer: [
          if (busy) const LinearProgressIndicator(),
          if (error != null) Text(error!),
          if (!busy && more)
            TextButton(
              onPressed: load,
              child: Text(error == null ? 'Tải thêm' : 'Thử lại'),
            ),
          if (!busy && error == null && people.isEmpty)
            const Text('Chưa có người cứu hộ.'),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Đóng'),
      ),
    ],
  );
}
