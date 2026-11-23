import 'package:flutter/material.dart';

import '../../core/xu_ly_loi.dart';
import '../../widgets/trang_cuon.dart';
import 'chi_tiet_yeu_cau_screen.dart';
import 'controllers/thong_bao_yeu_cau_controller.dart';
import 'services/thong_bao_yeu_cau_service.dart';

class ThongBaoYeuCauScreen extends StatefulWidget {
  final String uid;

  const ThongBaoYeuCauScreen({super.key, required this.uid});

  @override
  State<ThongBaoYeuCauScreen> createState() => _ThongBaoYeuCauScreenState();
}

class _ThongBaoYeuCauScreenState extends State<ThongBaoYeuCauScreen> {
  late final ThongBaoYeuCauController c = ThongBaoYeuCauController(
    ThongBaoYeuCauService(widget.uid),
  );

  List<ThongBaoAdmin> get rows => c.rows;
  int get _totalCount => c.totalCount;
  int get _unreadCount => c.unreadTotal;
  int get _readCount => c.readCount;
  bool get loading => c.loading;
  bool get hasMore => c.hasMore;
  bool get _markingAll => c.markingAll;
  String? get error => c.error;
  Set<String> get _markingIds => c.markingIds;
  BoLocThongBao get _filter => c.filter;

  @override
  void initState() {
    super.initState();
    c.start();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  void _changeFilter(BoLocThongBao next) => c.changeFilter(next);
  Future<void> _loadMore() => c.loadMore();
  Future<void> _refresh() => c.refresh();

  Future<void> _markRead(ThongBaoAdmin item) async {
    try {
      await c.markRead(item);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể đánh dấu đã đọc: ${friendlyError(e)}'),
          ),
        );
      }
    }
  }

  Future<void> _markAllRead() async {
    try {
      final count = await c.markAllRead();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã đánh dấu $count thông báo đã đọc.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể đánh dấu tất cả: ${friendlyError(e)}'),
          ),
        );
      }
    }
  }

  Future<void> _openNotification(ThongBaoAdmin item) async {
    await _markRead(item);
    if (!mounted) return;
    final requestId = item.data['maYeuCau'];
    if (requestId is String &&
        requestId.isNotEmpty &&
        !requestId.contains('/')) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ChiTietYeuCauScreen(id: requestId),
        ),
      );
    }
  }

  DateTime? _vietnamTime(DateTime? instant) =>
      instant?.toUtc().add(const Duration(hours: 7));

  String _two(int value) => value.toString().padLeft(2, '0');

  String _dateKey(DateTime? time) => time == null
      ? 'unknown'
      : '${time.year}-${_two(time.month)}-${_two(time.day)}';

  String _dayLabel(DateTime? time) {
    if (time == null) return 'Chưa rõ ngày';

    final day = DateTime.utc(time.year, time.month, time.day);
    final now = _vietnamTime(DateTime.now())!;
    final today = DateTime.utc(now.year, now.month, now.day);
    final difference = today.difference(day).inDays;
    final date = '${_two(time.day)}/${_two(time.month)}/${time.year}';

    if (difference == 0) return 'Hôm nay · $date';
    if (difference == 1) return 'Hôm qua · $date';
    return date;
  }

  IconData _iconFor(String type, String eventCode) {
    switch (eventCode) {
      case 'yeu_cau_moi':
        return Icons.emergency_outlined;
      case 'loi_moi_da_nhan':
        return Icons.check_circle_outline;
      case 'loi_moi_tu_choi':
        return Icons.cancel_outlined;
      case 'loi_moi_het_han':
        return Icons.hourglass_empty;
      case 'can_bo_sung_nhan_luc':
        return Icons.groups_outlined;
      case 'can_kiem_tra':
      case 'can_xac_minh_hoan_thanh':
        return Icons.fact_check_outlined;
      case 'qua_han_dieu_phoi':
      case 'xac_nhan_qua_han':
        return Icons.warning_amber_rounded;
    }

    switch (type) {
      case 'ca_moi':
        return Icons.emergency_outlined;
      case 'can_can_thiep':
      case 'qua_han_xac_nhan':
        return Icons.warning_amber_rounded;
      case 'phan_hoi_dieu_phoi':
        return Icons.groups_outlined;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _colorFor(String type, String eventCode) {
    switch (eventCode) {
      case 'loi_moi_da_nhan':
        return const Color(0xFF15803D);
      case 'loi_moi_tu_choi':
        return const Color(0xFFB91C1C);
      case 'loi_moi_het_han':
      case 'qua_han_dieu_phoi':
        return const Color(0xFFB45309);
      case 'can_bo_sung_nhan_luc':
      case 'can_kiem_tra':
      case 'can_xac_minh_hoan_thanh':
      case 'xac_nhan_qua_han':
        return const Color(0xFFC2410C);
    }

    switch (type) {
      case 'can_can_thiep':
      case 'qua_han_xac_nhan':
        return const Color(0xFFC2410C);
      case 'ca_moi':
        return const Color(0xFF1565C0);
      case 'phan_hoi_dieu_phoi':
        return const Color(0xFF0F766E);
      default:
        return const Color(0xFF64748B);
    }
  }

  Widget _filterChip(String label, int count, BoLocThongBao value) {
    final selected = _filter == value;
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      label: Text('$label ($count)'),
      onSelected: (_) => _changeFilter(value),
      selectedColor: const Color(0xFFDCEBFF),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? const Color(0xFF8CB9F2) : const Color(0xFFE0E7F0),
      ),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF1559A6) : const Color(0xFF475569),
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  Widget _notificationCard(ThongBaoAdmin doc, int index) {
    final data = doc.data;
    final time = _vietnamTime(doc.instant);
    final previous = index > 0 ? _vietnamTime(rows[index - 1].instant) : null;
    final firstOfDay = index == 0 || _dateKey(time) != _dateKey(previous);
    final unread = data['daDoc'] != true;
    final type = '${data['loai'] ?? ''}';
    final eventCode = '${data['maSuKien'] ?? ''}';
    final color = _colorFor(type, eventCode);
    final title = '${data['tieuDe'] ?? 'Thông báo'}';
    final body = '${data['noiDung'] ?? ''}';
    final requestId = data['maYeuCau'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (firstOfDay)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 7),
            child: Text(
              _dayLabel(time),
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        Card(
          margin: const EdgeInsets.only(bottom: 9),
          color: unread ? const Color(0xFFF4F8FF) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: unread ? const Color(0xFFC9DDF8) : const Color(0xFFE0E7F0),
            ),
          ),
          child: ListTile(
            onTap: () => _openNotification(doc),
            contentPadding: const EdgeInsets.fromLTRB(13, 7, 7, 7),
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: .12),
              child: Icon(_iconFor(type, eventCode), color: color),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                      color: const Color(0xFF1E3555),
                    ),
                  ),
                ),
                if (unread)
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(left: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2878D2),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (body.isNotEmpty)
                    Text(body, maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 10,
                    runSpacing: 3,
                    children: [
                      if (time != null)
                        Text(
                          '${_two(time.hour)}:${_two(time.minute)}',
                          style: const TextStyle(
                            color: Color(0xFF71829B),
                            fontSize: 11,
                          ),
                        ),
                      if (requestId is String && requestId.isNotEmpty)
                        Text(
                          'Mã yêu cầu: $requestId',
                          style: const TextStyle(
                            color: Color(0xFF71829B),
                            fontSize: 11,
                          ),
                        ),
                      Text(
                        unread ? 'Chưa đọc' : 'Đã đọc',
                        style: TextStyle(
                          color: unread
                              ? const Color(0xFF1559A6)
                              : const Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            trailing: unread
                ? IconButton(
                    tooltip: 'Đánh dấu đã đọc',
                    onPressed: _markingIds.contains(doc.id)
                        ? null
                        : () => _markRead(doc),
                    icon: _markingIds.contains(doc.id)
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.mark_email_read_outlined,
                            color: Color(0xFF2878D2),
                          ),
                  )
                : const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF7A899D),
                    size: 21,
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text(
          'Push Notify',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ScrollPage(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          onMore: _loadMore,
          itemCount: rows.length,
          itemBuilder: (_, index) => _notificationCard(rows[index], index),
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Hộp thông báo',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E3555),
                    ),
                  ),
                ),
                if (_unreadCount > 0)
                  TextButton.icon(
                    onPressed: _markingAll ? null : _markAllRead,
                    icon: _markingAll
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.done_all, size: 18),
                    label: const Text('Đánh dấu tất cả đã đọc'),
                  ),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Tất cả', _totalCount, BoLocThongBao.tatCa),
                  const SizedBox(width: 7),
                  _filterChip('Chưa đọc', _unreadCount, BoLocThongBao.chuaDoc),
                  const SizedBox(width: 7),
                  _filterChip('Đã đọc', _readCount, BoLocThongBao.daDoc),
                ],
              ),
            ),
            const SizedBox(height: 6),
            if (rows.isEmpty && !loading && error == null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 42,
                  horizontal: 18,
                ),
                child: Column(
                  children: [
                    Icon(
                      _filter == BoLocThongBao.chuaDoc
                          ? Icons.mark_email_read_outlined
                          : Icons.notifications_none_rounded,
                      size: 42,
                      color: const Color(0xFF9AA8BA),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _filter == BoLocThongBao.chuaDoc
                          ? 'Bạn đã đọc hết thông báo.'
                          : _filter == BoLocThongBao.daDoc
                          ? 'Chưa có thông báo đã đọc.'
                          : 'Chưa có thông báo nào.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF71829B)),
                    ),
                  ],
                ),
              ),
          ],
          footer: [
            if (loading) const Center(child: CircularProgressIndicator()),
            if (error != null)
              Column(
                children: [
                  Text(error!, textAlign: TextAlign.center),
                  TextButton(onPressed: _refresh, child: const Text('Thử lại')),
                ],
              ),
            if (hasMore && !loading && error == null)
              Center(
                child: OutlinedButton(
                  onPressed: _loadMore,
                  child: const Text('Tải thêm'),
                ),
              ),
            if (!_markingAll && _unreadCount == 0 && c.hasAnyRows)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    'Bạn đã đọc tất cả thông báo.',
                    style: TextStyle(color: Color(0xFF71829B), fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
