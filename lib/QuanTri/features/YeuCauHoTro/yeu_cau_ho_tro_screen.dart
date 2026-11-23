import 'dart:async';

import 'package:flutter/material.dart';

import '../DangNhap/controllers/dang_nhap_controller.dart';
import '../DangNhap/thong_tin_quan_tri_screen.dart';
import '../TaiKhoan/services/tai_khoan_service.dart';
import '../../widgets/giao_dien_tai_khoan.dart';
import '../../widgets/trang_cuon.dart';
import 'ban_do_yeu_cau_screen.dart';
import 'chi_tiet_yeu_cau_screen.dart';
import 'controllers/yeu_cau_ho_tro_controller.dart';
import 'dieu_phoi_screen.dart';
import 'models/dieu_phoi_model.dart';
import 'models/yeu_cau_ho_tro_model.dart';
import 'services/dieu_phoi_service.dart';
import 'services/yeu_cau_ho_tro_service.dart';
import 'thong_bao_yeu_cau_screen.dart';

class YeuCauHoTroScreen extends StatefulWidget {
  final DangNhapController auth;
  final NguonYeuCauHoTro? repository;
  final NguonTaiKhoan? accountRepository;

  const YeuCauHoTroScreen({
    super.key,
    required this.auth,
    this.repository,
    this.accountRepository,
  });

  @override
  State<YeuCauHoTroScreen> createState() => _YeuCauHoTroScreenState();
}

class _YeuCauHoTroScreenState extends State<YeuCauHoTroScreen> {
  late final YeuCauHoTroController c = YeuCauHoTroController(
    widget.repository ?? YeuCauHoTroService(),
  );
  final search = TextEditingController();
  final ScrollController _listScroll = ScrollController();
  final _searchFocus = FocusNode();
  final Set<String> _claiming = <String>{};
  bool _searchVisible = false;
  Timer? clock;

  static const _ink = Color(0xFF172B4D);
  static const _muted = Color(0xFF64748B);
  static const _danger = Color(0xFFC62828);
  static const _warning = Color(0xFFB66A00);

  @override
  void initState() {
    super.initState();
    c.adminId = widget.auth.session?.uid ?? '';
    c.load();
    clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    clock?.cancel();
    search.dispose();
    _listScroll.dispose();
    _searchFocus.dispose();
    c.dispose();
    super.dispose();
  }

  Future<void> open(YeuCauHoTro request) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChiTietYeuCauScreen(id: request.id),
      ),
    );
    // Live streams update the case; keep loaded pages and scroll position.
  }

  Future<void> dispatchInfo(YeuCauHoTro request) => Navigator.push<void>(
    context,
    MaterialPageRoute<void>(builder: (_) => DieuPhoiScreen(id: request.id)),
  );

  void _toggleSearch() {
    setState(() => _searchVisible = !_searchVisible);
    if (_searchVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    } else {
      _searchFocus.unfocus();
    }
  }

  void _clearFilters() {
    search.clear();
    c.resetFilters();
    c.search('');
  }

  List<String> get _activeFilterLabels => [
    if (c.query.trim().isNotEmpty) 'Tìm: ${c.query.trim()}',
    if (c.status.isNotEmpty)
      'Trạng thái: ${requestStatuses[c.status] ?? c.status}',
    if (c.urgencyFilter.isNotEmpty) _urgencyLabel(c.urgencyFilter),
    if (c.typeFilter.isNotEmpty)
      'Loại: ${c.availableTypes[c.typeFilter] ?? c.typeFilter}',
    if (c.interventionFilter == 'all') 'Cần can thiệp',
    if (c.interventionFilter == 'dispatch') 'Cần điều phối',
    if (c.interventionFilter == 'check') 'Cần kiểm tra',
    if (c.ownerFilter == 'mine') 'Tôi phụ trách',
    if (c.ownerFilter == 'others') 'Admin khác',
    if (c.ownerFilter == 'unassigned') 'Chưa có Admin',
    if (c.timeFilter == 'today') 'Hôm nay',
    if (c.timeFilter == '7days') '7 ngày',
    if (c.timeFilter == '30days') '30 ngày',
    if (c.sortMode != 'priority') 'Sắp xếp: $_sortLabel',
  ];

  Future<void> _claimAndDispatch(YeuCauHoTro request) async {
    if (_claiming.contains(request.id)) return;
    setState(() => _claiming.add(request.id));
    var claimed = false;
    try {
      // Existing transaction checks Admin status, ownership and case status.
      await DieuPhoiService().act(request.id, 'claim');
      claimed = true;
    } catch (error) {
      if (mounted) {
        final message = error is StateError
            ? error.message.toString()
            : 'Không nhận được ca. Ca có thể đã được Admin khác phụ trách.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _claiming.remove(request.id));
    }
    if (!mounted) return;
    if (claimed) await dispatchInfo(request);
    // Do not reset pagination after claiming/returning from dispatch.
  }

  Future<void> openAdvancedFilters() async {
    var draftStatus = c.status;
    var draftUrgency = c.urgencyFilter;
    var draftType = c.typeFilter;
    var draftOwner = c.ownerFilter;
    var draftTime = c.timeFilter;
    var draftIntervention = c.interventionFilter;
    var draftSort = c.sortMode;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, updateSheet) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: .86,
          minChildSize: .58,
          maxChildSize: .96,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Lọc yêu cầu',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Đóng',
                        onPressed: () => Navigator.pop(sheetContext, false),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    children: [
                      _filterSection(
                        'Trạng thái',
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _choice(
                              'Tất cả',
                              draftStatus.isEmpty,
                              () => updateSheet(() => draftStatus = ''),
                            ),
                            for (final entry in requestStatuses.entries)
                              if (entry.key != 'cho_dong' &&
                                  YeuCauHoTro('', {
                                        'maTinhTrangYeuCau': entry.key,
                                      }).tab ==
                                      c.tab)
                                _choice(
                                  entry.value,
                                  draftStatus == entry.key,
                                  () => updateSheet(
                                    () => draftStatus = entry.key,
                                  ),
                                ),
                          ],
                        ),
                      ),
                      _filterSection(
                        'Mức độ khẩn cấp',
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _choice(
                              'Tất cả',
                              draftUrgency.isEmpty,
                              () => updateSheet(() => draftUrgency = ''),
                            ),
                            for (final value in c.availableUrgencies)
                              _choice(
                                _urgencyLabel(value),
                                draftUrgency == value,
                                () => updateSheet(() => draftUrgency = value),
                              ),
                          ],
                        ),
                      ),
                      _filterSection(
                        'Loại sự cố',
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _choice(
                              'Tất cả',
                              draftType.isEmpty,
                              () => updateSheet(() => draftType = ''),
                            ),
                            for (final entry in c.availableTypes.entries)
                              _choice(
                                entry.value,
                                draftType == entry.key,
                                () => updateSheet(() => draftType = entry.key),
                              ),
                          ],
                        ),
                      ),
                      _filterSection(
                        'Tình trạng xử lý',
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _choice(
                              'Tất cả',
                              draftIntervention.isEmpty,
                              () => updateSheet(() => draftIntervention = ''),
                            ),
                            _choice(
                              'Cần can thiệp',
                              draftIntervention == 'all',
                              () =>
                                  updateSheet(() => draftIntervention = 'all'),
                            ),
                            _choice(
                              'Cần điều phối',
                              draftIntervention == 'dispatch',
                              () => updateSheet(
                                () => draftIntervention = 'dispatch',
                              ),
                            ),
                            _choice(
                              'Cần kiểm tra',
                              draftIntervention == 'check',
                              () => updateSheet(
                                () => draftIntervention = 'check',
                              ),
                            ),
                          ],
                        ),
                      ),
                      _filterSection(
                        'Admin phụ trách',
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _choice(
                              'Tất cả',
                              draftOwner == 'all',
                              () => updateSheet(() => draftOwner = 'all'),
                            ),
                            _choice(
                              'Tôi phụ trách',
                              draftOwner == 'mine',
                              () => updateSheet(() => draftOwner = 'mine'),
                            ),
                            _choice(
                              'Admin khác',
                              draftOwner == 'others',
                              () => updateSheet(() => draftOwner = 'others'),
                            ),
                            _choice(
                              'Chưa có',
                              draftOwner == 'unassigned',
                              () =>
                                  updateSheet(() => draftOwner = 'unassigned'),
                            ),
                          ],
                        ),
                      ),
                      _filterSection(
                        'Thời gian phát sinh',
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _choice(
                              'Tất cả',
                              draftTime == 'all',
                              () => updateSheet(() => draftTime = 'all'),
                            ),
                            _choice(
                              'Hôm nay',
                              draftTime == 'today',
                              () => updateSheet(() => draftTime = 'today'),
                            ),
                            _choice(
                              '7 ngày',
                              draftTime == '7days',
                              () => updateSheet(() => draftTime = '7days'),
                            ),
                            _choice(
                              '30 ngày',
                              draftTime == '30days',
                              () => updateSheet(() => draftTime = '30days'),
                            ),
                          ],
                        ),
                      ),
                      _filterSection(
                        'Sắp xếp',
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _choice(
                              'Ưu tiên xử lý',
                              draftSort == 'priority',
                              () => updateSheet(() => draftSort = 'priority'),
                            ),
                            _choice(
                              'Chờ lâu nhất',
                              draftSort == 'oldest',
                              () => updateSheet(() => draftSort = 'oldest'),
                            ),
                            _choice(
                              'Mới phát sinh',
                              draftSort == 'newest',
                              () => updateSheet(() => draftSort = 'newest'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => updateSheet(() {
                              draftStatus = '';
                              draftUrgency = '';
                              draftType = '';
                              draftOwner = 'all';
                              draftTime = 'all';
                              draftIntervention = '';
                              draftSort = 'priority';
                            }),
                            child: const Text('Đặt lại'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(sheetContext, true),
                            child: const Text('Áp dụng bộ lọc'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true && mounted) {
      c.applyFilters(
        status: draftStatus,
        urgency: draftUrgency,
        type: draftType,
        owner: draftOwner,
        time: draftTime,
        intervention: draftIntervention,
        sort: draftSort,
      );
    }
  }

  Widget _filterSection(String title, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );

  Widget _choice(String label, bool selected, VoidCallback onTap) => ChoiceChip(
    label: Text(label),
    selected: selected,
    showCheckmark: false,
    onSelected: (_) => onTap(),
    selectedColor: const Color(0xFFE5F0FF),
    side: BorderSide(color: selected ? accountBlue : const Color(0xFFE2E8F0)),
    labelStyle: TextStyle(
      color: selected ? accountBlue : _ink,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    ),
  );

  Widget _quickFilter(
    String label,
    bool selected,
    VoidCallback onTap,
  ) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      minimumSize: const Size(0, 38),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: selected ? accountBlue : _ink,
      backgroundColor: selected
          ? const Color(0xFFE5F0FF)
          : const Color(0xFFF5F7FB),
      side: BorderSide(color: selected ? accountBlue : const Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );

  String _urgencyLabel(String value) {
    final level = int.tryParse(value);
    if (level == 1) {
      return 'Mức 1 · SOS';
    }
    if (level == 2) {
      return 'Mức 2 · Hỗ trợ y tế';
    }
    return level == null ? value : 'Mức $level';
  }

  String get _sortLabel => switch (c.sortMode) {
    'oldest' => 'Chờ lâu nhất',
    'newest' => 'Mới phát sinh',
    _ => 'Ưu tiên xử lý',
  };

  @override
  Widget build(BuildContext context) => Theme(
    data: accountTheme(context),
    child: ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final rows = c.filtered;
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            title: _searchVisible
                ? TextField(
                    controller: search,
                    focusNode: _searchFocus,
                    onChanged: c.search,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Tìm mã ca, địa chỉ, nạn nhân…',
                      isDense: true,
                      border: InputBorder.none,
                    ),
                  )
                : const Text(
                    'Yêu cầu cứu hộ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
            actions: [
              IconButton(
                tooltip: _searchVisible ? 'Đóng tìm kiếm' : 'Tìm kiếm',
                icon: Icon(_searchVisible ? Icons.close : Icons.search),
                onPressed: _toggleSearch,
              ),
              IconButton(
                tooltip: 'Thông báo',
                icon: const Icon(Icons.notifications_outlined),
                onPressed: widget.auth.session == null
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ThongBaoYeuCauScreen(
                            uid: widget.auth.session!.uid,
                          ),
                        ),
                      ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Thao tác khác',
                onSelected: (value) {
                  if (value == 'map') {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => BanDoYeuCauScreen(
                          controller: c,
                          requests: c.filtered,
                          onOpen: open,
                        ),
                      ),
                    );
                  } else if (value == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ThongTinQuanTriScreen(auth: widget.auth),
                      ),
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'map',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.map_outlined),
                      title: Text('Bản đồ yêu cầu'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'profile',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.account_circle_outlined),
                      title: Text('Hồ sơ Admin'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              child: Row(
                children: [
                  nav(Icons.emergency, 'Yêu cầu', () {}, selected: true),
                  nav(
                    Icons.people_outline,
                    'Tài khoản',
                    () => Navigator.pushReplacementNamed(context, '/tai-khoan'),
                  ),
                  nav(
                    Icons.verified_user_outlined,
                    'Xác minh',
                    () => Navigator.pushReplacementNamed(context, '/xac-minh'),
                  ),
                  nav(
                    Icons.query_stats_rounded,
                    'Báo cáo',
                    () => Navigator.pushReplacementNamed(context, '/bao-cao'),
                  ),
                  nav(
                    Icons.medical_services_outlined,
                    'Kỹ năng',
                    () => Navigator.pushReplacementNamed(context, '/ky-nang'),
                  ),
                ],
              ),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: RefreshIndicator(
                onRefresh: c.load,
                child: ScrollPage(
                  controller: _listScroll,
                  padding: const EdgeInsets.fromLTRB(16, 5, 16, 18),
                  onMore: c.error == null ? c.more : () async {},
                  itemCount: rows.length,
                  itemBuilder: (_, index) => requestCard(rows[index]),
                  children: [
                    Row(
                      children: [
                        tab('active', 'Đang hoạt động'),
                        tab('closed', 'Đã đóng'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (c.tab == 'active') ...[
                          Expanded(
                            child: _quickFilter(
                              'Cần điều phối',
                              c.interventionFilter == 'dispatch',
                              () => c.setInterventionFilter('dispatch'),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: _quickFilter(
                              'Cần kiểm tra',
                              c.interventionFilter == 'check',
                              () => c.setInterventionFilter('check'),
                            ),
                          ),
                          const SizedBox(width: 5),
                        ] else
                          const Spacer(),
                        OutlinedButton.icon(
                          onPressed: openAdvancedFilters,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.tune, size: 17),
                          label: Text(
                            c.activeFilterCount == 0
                                ? 'Bộ lọc'
                                : 'Bộ lọc (${c.activeFilterCount})',
                          ),
                        ),
                      ],
                    ),
                    if (_activeFilterLabels.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 3),
                        child: Container(
                          padding: const EdgeInsets.only(left: 10, right: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF2FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.filter_alt_outlined,
                                color: accountBlue,
                                size: 17,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _activeFilterLabels.join(' · '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _clearFilters,
                                child: const Text('Xóa lọc'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 5),
                    if (!c.loading && rows.isEmpty && c.error == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 34),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 42,
                              color: Colors.blueGrey.shade300,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              c.hasMore
                                  ? 'Chưa có yêu cầu phù hợp trong phần đã tải.'
                                  : 'Không có yêu cầu phù hợp.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: _muted),
                            ),
                            if (c.hasMore)
                              TextButton(
                                onPressed: c.more,
                                child: const Text('Tải thêm dữ liệu'),
                              ),
                          ],
                        ),
                      ),
                  ],
                  footer: [
                    if (c.loading)
                      const Padding(
                        padding: EdgeInsets.all(18),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (c.error != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text(c.error!, textAlign: TextAlign.center),
                            TextButton(
                              onPressed: c.loading ? null : c.retry,
                              child: const Text('Thử lại'),
                            ),
                            if (c.items.isNotEmpty)
                              TextButton(
                                onPressed: c.loading ? null : c.load,
                                child: const Text('Tải lại danh sách'),
                              ),
                          ],
                        ),
                      ),
                    if (c.hasMore && !c.loading && c.error == null)
                      OutlinedButton(
                        onPressed: c.more,
                        child: const Text('Tải thêm yêu cầu'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget nav(
    IconData icon,
    String label,
    VoidCallback? action, {
    bool selected = false,
  }) => mucDieuHuong(icon, label, action, selected: selected);

  Widget tab(String value, String label) => Expanded(
    child: TextButton(
      onPressed: () => c.selectTab(value),
      style: TextButton.styleFrom(
        foregroundColor: c.tab == value ? accountBlue : Colors.blueGrey,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      ),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: c.tab == value ? accountBlue : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: c.tab == value ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    ),
  );

  Widget requestCard(YeuCauHoTro r) => _requestCardBody(r);

  Widget _requestCardBody(YeuCauHoTro r) {
    final owner = r.text('maAdminDieuPhoi');
    final mine = owner.isNotEmpty && owner == widget.auth.session?.uid;
    final canDispatch =
        r.tab == 'active' && coTheDieuPhoi(r.data['maTinhTrangYeuCau']);
    final canClaim = canDispatch && owner.isEmpty;
    final canContinue = canDispatch && mine;
    final claiming = _claiming.contains(r.id);
    final isSos = r.urgencyLevel == 1;
    final statusText = r.needsDispatch
        ? 'Cần điều phối'
        : r.needsCheck
        ? 'Cần kiểm tra'
        : r.status == 'cho_tiep_nhan'
        ? 'Chưa có người nhận'
        : r.statusLabel;
    final color = isSos || r.needsDispatch
        ? _danger
        : r.needsCheck
        ? _warning
        : r.closed
        ? _muted
        : accountBlue;
    final personCount = r.data['soNguoiCanCuuHo'];
    final age = requestAge(r.createdAt, DateTime.now());
    final waitingAge = canClaim && age.endsWith(' trước')
        ? 'Chờ ${age.substring(0, age.length - ' trước'.length)}'
        : age;

    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: r.needsIntervention
              ? color.withValues(alpha: .30)
              : const Color(0xFFE7EDF4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => open(r),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isSos
                        ? Icons.priority_high_rounded
                        : r.needsCheck
                        ? Icons.fact_check_outlined
                        : Icons.circle,
                    size: isSos || r.needsCheck ? 17 : 11,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${isSos ? 'SOS · ' : ''}$statusText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _muted,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                r.address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                [
                  r.code,
                  waitingAge,
                  if (personCount != null) '$personCount người cần hỗ trợ',
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (r.assignee.isNotEmpty && !r.closed) ...[
                const SizedBox(height: 5),
                Text(
                  'Người hỗ trợ: ${r.assignee}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
              if (owner.isNotEmpty && !mine) ...[
                const SizedBox(height: 7),
                TenAdminDieuPhoi(owner, mine: false, label: 'Đang phụ trách'),
              ],
              if (canClaim || canContinue) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      minimumSize: const Size.fromHeight(40),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: claiming
                        ? null
                        : canClaim
                        ? () => _claimAndDispatch(r)
                        : () => dispatchInfo(r),
                    icon: claiming
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            canClaim
                                ? Icons.group_add_outlined
                                : Icons.route_outlined,
                            size: 18,
                          ),
                    label: Text(
                      claiming
                          ? 'Đang nhận điều phối…'
                          : canClaim
                          ? 'Nhận điều phối'
                          : 'Tiếp tục điều phối',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
