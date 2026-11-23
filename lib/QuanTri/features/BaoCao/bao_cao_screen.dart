import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../widgets/giao_dien_tai_khoan.dart';
import 'bao_cao_service.dart';

const _ink = Color(0xFF193052);
const _muted = Color(0xFF71829B);
const _blue = Color(0xFF1565C0);
const _teal = Color(0xFF0F766E);
const _green = Color(0xFF15803D);
const _orange = Color(0xFFB45309);
const _red = Color(0xFFB42318);
const _purple = Color(0xFF6941C6);
const _border = Color(0xFFE0E7F0);

class BaoCaoScreen extends StatefulWidget {
  const BaoCaoScreen({super.key});
  @override
  State<BaoCaoScreen> createState() => _BaoCaoScreenState();
}

class _BaoCaoScreenState extends State<BaoCaoScreen> {
  final service = BaoCaoService();
  BaoCaoData? data;
  bool loading = false;
  bool detailsLoaded = false;
  bool detailsLoading = false;
  int _loadGeneration = 0;
  String? error;
  String period = '30d';
  DateTimeRange? customRange;
  String? selectedType;
  String? selectedStatus;
  int? selectedUrgency;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final token = ++_loadGeneration;
    // A changed date range supersedes any pending older request.
    setState(() {
      loading = true;
      detailsLoaded = false;
      detailsLoading = false;
      data = null;
      error = null;
    });
    try {
      final result = await service.loadOverview(
        start: rangeStart,
        endExclusive: rangeEndExclusive,
      );
      if (!mounted || token != _loadGeneration) return;
      setState(() => data = result);
    } catch (_) {
      if (mounted && token == _loadGeneration) {
        setState(
          () => error = 'Không thể tải tổng quan báo cáo. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted && token == _loadGeneration) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> loadDetails() async {
    final overview = data;
    if (overview == null || loading || detailsLoading || detailsLoaded) return;
    final token = _loadGeneration;
    setState(() {
      detailsLoading = true;
      error = null;
    });
    try {
      final result = await service.loadDetails(overview);
      if (!mounted || token != _loadGeneration) return;
      setState(() {
        data = result;
        detailsLoaded = true;
      });
    } catch (_) {
      if (mounted && token == _loadGeneration) {
        setState(() => error = 'Không thể tải dữ liệu chi tiết. Hãy thử lại.');
      }
    } finally {
      if (mounted && token == _loadGeneration) {
        setState(() => detailsLoading = false);
      }
    }
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime? get rangeStart {
    if (period == 'all') return null;
    if (period == 'custom') {
      return customRange == null
          ? _today().subtract(const Duration(days: 29))
          : DateTime(
              customRange!.start.year,
              customRange!.start.month,
              customRange!.start.day,
            );
    }
    final days = period == '7d'
        ? 7
        : period == '90d'
        ? 90
        : 30;
    return _today().subtract(Duration(days: days - 1));
  }

  DateTime? get rangeEndExclusive {
    if (period == 'all') return null;
    if (period == 'custom' && customRange != null) {
      final end = customRange!.end;
      return DateTime(end.year, end.month, end.day + 1);
    }
    return _today().add(const Duration(days: 1));
  }

  String get periodLabel {
    if (period == 'all') return 'Toàn thời gian';
    if (period == 'custom' && customRange != null) {
      return '${_dateLabel(customRange!.start)}/${customRange!.start.year} – ${_dateLabel(customRange!.end)}/${customRange!.end.year}';
    }
    return period == '7d'
        ? '7 ngày gần nhất'
        : period == '90d'
        ? '90 ngày gần nhất'
        : '30 ngày gần nhất';
  }

  bool _inPeriod(DateTime? date) {
    if (period == 'all') return true;
    if (date == null) return false;
    final start = rangeStart;
    final end = rangeEndExclusive;
    return (start == null || !date.isBefore(start)) &&
        (end == null || date.isBefore(end));
  }

  List<BaoCaoRow> get periodRequests => (data?.requests ?? [])
      .where((r) => _inPeriod(baoCaoDate(r.data['thoiGianTao'])))
      .toList(growable: false);

  List<BaoCaoRow> get requests => periodRequests
      .where((r) {
        if (selectedType != null &&
            r.data['maLoaiYeuCau']?.toString() != selectedType)
          return false;
        if (selectedStatus != null && _status(r) != selectedStatus)
          return false;
        if (selectedUrgency != null &&
            baoCaoInt(r.data['mucDoKhanCap']) != selectedUrgency)
          return false;
        return true;
      })
      .toList(growable: false);

  List<int> get urgencyOptions =>
      (data?.requests ?? [])
          .map((r) => baoCaoInt(r.data['mucDoKhanCap']))
          .where((v) => v > 0)
          .toSet()
          .toList()
        ..sort();

  List<BaoCaoRow> get rescueRecords => (data?.rescueRecords ?? [])
      .where((r) => _inPeriod(baoCaoDate(r.data['thoiGianHoanThanh'])))
      .toList(growable: false);

  List<BaoCaoRow> get reviews => (data?.reviews ?? [])
      .where((r) => _inPeriod(baoCaoDate(r.data['ngayTao'])))
      .toList(growable: false);

  int get totalRequests => requests.length;
  bool _hasAdminCloseMarker(BaoCaoRow row) =>
      (row.data['maAdminHoanThanh'] is String &&
          (row.data['maAdminHoanThanh'] as String).isNotEmpty) ||
      row.data['nguonXacNhanHoanThanh'] == 'admin';
  int get completedRequests => requests
      .where((r) => _status(r) == 'hoan_thanh' && !_hasAdminCloseMarker(r))
      .length;
  int get adminClosedRequests => requests
      .where((r) => _status(r) == 'hoan_thanh' && _hasAdminCloseMarker(r))
      .length;
  int get cancelledRequests =>
      requests.where((r) => _status(r) == 'da_huy').length;
  bool _isActiveStatus(String status) => const {
    'cho_tiep_nhan',
    'qua_han_dieu_phoi',
    'da_phan_cong',
    'dang_cuu_ho',
    'cho_dong',
  }.contains(status);

  bool _needsIntervention(BaoCaoRow row) {
    final status = _status(row);
    return !['hoan_thanh', 'da_huy', 'cho_dong'].contains(status) &&
        (status == 'qua_han_dieu_phoi' ||
            row.data['canKiemTra'] == true ||
            row.data['canBoSungNhanLuc'] == true);
  }

  int get activeRequests =>
      requests.where((r) => _isActiveStatus(_status(r))).length;
  int get interventionRequests => requests
      .where((r) => _isActiveStatus(_status(r)) && _needsIntervention(r))
      .length;
  int get processingRequests => requests
      .where((r) => _isActiveStatus(_status(r)) && !_needsIntervention(r))
      .length;

  double _rate(int count) =>
      totalRequests == 0 ? 0 : count * 100 / totalRequests;
  double get completionRate => _rate(completedRequests);
  double get adminCloseRate => _rate(adminClosedRequests);
  double get interventionRate => _rate(interventionRequests);
  double get cancellationRate => _rate(cancelledRequests);

  double? get averageDispatchMinutes {
    final values = <double>[];
    for (final row in requests) {
      final created = baoCaoDate(row.data['thoiGianTao']);
      final assigned = baoCaoDate(row.data['thoiGianPhanCong']);
      if (created == null || assigned == null || assigned.isBefore(created))
        continue;
      values.add(assigned.difference(created).inSeconds / 60);
    }
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  Set<String> get rescuerIds => {
    for (final row in data?.users ?? [])
      if (_isRescuer(row.data)) row.id,
    for (final row in data?.professionalProfiles ?? []) row.id,
    for (final row in data?.volunteerProfiles ?? []) row.id,
  };
  int get rescuerCount => rescuerIds.length;
  int get onlineRescuers => (data?.users ?? [])
      .where((r) => rescuerIds.contains(r.id) && r.data['isOnline'] == true)
      .length;
  int get receivingRescuers => (data?.users ?? [])
      .where((r) => rescuerIds.contains(r.id) && r.data['nhanCaCuuHo'] == true)
      .length;
  int get approvedRescuers {
    final ids = <String>{};
    for (final row in data?.professionalProfiles ?? const <BaoCaoRow>[]) {
      if (row.data['maTrangThaiHoSo'] == 'cuuho_trangthai_hoso_daduyet')
        ids.add(row.id);
    }
    for (final row in data?.volunteerProfiles ?? const <BaoCaoRow>[]) {
      if (row.data['maTrangThaiHoSo'] == 'cuuho_trangthai_hoso_daduyet')
        ids.add(row.id);
    }
    return ids.length;
  }

  double? get averageRating {
    final values = reviews
        .map((r) => baoCaoDouble(r.data['diemDanhGia']))
        .where((v) => v >= 1 && v <= 5)
        .toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  int get lowRatings => reviews.where((r) {
    final score = baoCaoDouble(r.data['diemDanhGia']);
    return score > 0 && score <= 2;
  }).length;

  int get averageRescueSeconds {
    final values = rescueRecords
        .map(_recordSeconds)
        .where((v) => v > 0)
        .toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) ~/ values.length;
  }

  String _status(BaoCaoRow row) =>
      baoCaoRequestStatus(row.data['maTinhTrangYeuCau']);
  bool _isRescuer(Map<String, dynamic> d) => const {
    'vaitro_cuuhococc',
    'vaitro_cuuhochuacocc',
  }.contains(d['maVaiTro']);

  int _recordSeconds(BaoCaoRow row) {
    final data = row.data;
    final direct = baoCaoInt(data['tongThoiGianGiay']);
    if (direct > 0) return direct;
    final legacy = baoCaoInt(data['tongThoianGiay']);
    if (legacy > 0) return legacy;
    return _parseDuration(data['tongThoiGianHienThi']);
  }

  int _parseDuration(Object? raw) {
    if (raw is! String) return 0;
    final parts = raw
        .trim()
        .split(':')
        .map((v) => int.tryParse(v.trim()))
        .toList();
    if (parts.isEmpty || parts.any((v) => v == null)) return 0;
    if (parts.length == 2) return parts[0]! * 60 + parts[1]!;
    if (parts.length == 3) return parts[0]! * 3600 + parts[1]! * 60 + parts[2]!;
    return 0;
  }

  Map<String, String> get typeNames => {
    for (final row in data?.requestTypes ?? [])
      row.id:
          (row.data['tenLoaiYeuCau'] is String &&
              (row.data['tenLoaiYeuCau'] as String).isNotEmpty)
          ? row.data['tenLoaiYeuCau'] as String
          : 'Loại yêu cầu khác',
  };

  Map<String, String> get availableTypeNames => {
    ...typeNames,
    for (final row in data?.requests ?? [])
      if ((row.data['maLoaiYeuCau']?.toString() ?? '').isNotEmpty)
        row.data['maLoaiYeuCau'].toString():
            typeNames[row.data['maLoaiYeuCau'].toString()] ??
            'Loại yêu cầu khác',
  };

  List<_Breakdown> get statusBreakdown {
    const labels = {
      'cho_tiep_nhan': 'Chờ tiếp nhận',
      'qua_han_dieu_phoi': 'Quá hạn điều phối',
      'da_phan_cong': 'Đã phân công',
      'dang_cuu_ho': 'Đang cứu hộ',
      'cho_dong': 'Chờ đóng',
      'hoan_thanh': 'Hoàn thành',
      'da_huy': 'Đã hủy',
    };
    const colors = {
      'cho_tiep_nhan': _blue,
      'qua_han_dieu_phoi': _orange,
      'da_phan_cong': _purple,
      'dang_cuu_ho': _teal,
      'cho_dong': _purple,
      'hoan_thanh': _green,
      'da_huy': _muted,
    };
    final counts = <String, int>{};
    for (final row in requests) {
      final status = _status(row);
      counts[status] = (counts[status] ?? 0) + 1;
    }
    final rows = counts.entries
        .map(
          (entry) => _Breakdown(
            labels[entry.key] ??
                (entry.key.isEmpty ? 'Chưa rõ trạng thái' : 'Trạng thái khác'),
            entry.value,
            colors[entry.key] ?? _muted,
          ),
        )
        .toList();
    rows.sort((a, b) => b.count.compareTo(a.count));
    return rows;
  }

  List<_Breakdown> get typeBreakdown {
    final counts = <String, int>{};
    for (final row in requests) {
      final id = row.data['maLoaiYeuCau']?.toString() ?? '';
      final label =
          typeNames[id] ??
          (id.isEmpty ? 'Chưa phân loại' : 'Loại yêu cầu khác');
      counts[label] = (counts[label] ?? 0) + 1;
    }
    final rows = counts.entries
        .map((e) => _Breakdown(e.key, e.value, _blue))
        .toList();
    rows.sort((a, b) => b.count.compareTo(a.count));
    return rows;
  }

  List<_Breakdown> get urgencyBreakdown {
    final counts = <int, int>{};
    for (final row in requests) {
      final level = baoCaoInt(row.data['mucDoKhanCap']);
      counts[level] = (counts[level] ?? 0) + 1;
    }
    final rows = counts.entries
        .map(
          (e) => _Breakdown(
            e.key <= 0 ? 'Chưa xác định' : 'Mức ${e.key}',
            e.value,
            e.key == 1
                ? _red
                : e.key == 2
                ? _orange
                : _blue,
          ),
        )
        .toList();
    rows.sort((a, b) => a.label.compareTo(b.label));
    return rows;
  }

  List<_TrendPoint> get trend {
    final dates = requests
        .map((r) => baoCaoDate(r.data['thoiGianTao']))
        .whereType<DateTime>()
        .toList();
    if (dates.isEmpty) return const [];
    dates.sort();
    final start =
        rangeStart ??
        DateTime(dates.first.year, dates.first.month, dates.first.day);
    final end =
        rangeEndExclusive ??
        DateTime(dates.last.year, dates.last.month, dates.last.day + 1);
    final span = math.max(1, end.difference(start).inDays);
    final bins = math.min(12, math.max(1, span)).toInt();
    final counts = List<int>.filled(bins, 0);
    for (final date in dates) {
      final day = DateTime(date.year, date.month, date.day);
      final index = ((day.difference(start).inDays * bins) / span)
          .floor()
          .clamp(0, bins - 1)
          .toInt();
      counts[index]++;
    }
    final widthDays = span / bins;
    return List.generate(bins, (i) {
      final day = start.add(Duration(days: (i * widthDays).floor()));
      return _TrendPoint(_dateLabel(day), counts[i]);
    });
  }

  List<_RescuerPerformance> get performance {
    final usersById = {for (final u in data?.users ?? []) u.id: u.data};
    final scores = {for (final r in data?.achievements ?? []) r.id: r.data};
    final professionalIds = (data?.professionalProfiles ?? [])
        .map((p) => p.id)
        .toSet();
    final volunteerIds = (data?.volunteerProfiles ?? [])
        .map((p) => p.id)
        .toSet();
    final aggregate = <String, _RescuerPerformance>{};

    _RescuerPerformance rowFor(String uid) => aggregate.putIfAbsent(uid, () {
      final user = usersById[uid] ?? const <String, dynamic>{};
      final scoreData = scores[uid] ?? const <String, dynamic>{};
      final roleId = user['maVaiTro'];
      final hasProfessional = professionalIds.contains(uid);
      final hasVolunteer = volunteerIds.contains(uid);
      final roleLabel = hasProfessional && hasVolunteer
          ? 'Có cả hai hồ sơ'
          : hasProfessional
          ? 'Có CCHN'
          : hasVolunteer
          ? 'Không CCHN'
          : roleId == 'vaitro_cuuhococc'
          ? 'Có CCHN (theo vai trò)'
          : roleId == 'vaitro_cuuhochuacocc'
          ? 'Không CCHN (theo vai trò)'
          : 'Chưa rõ loại hồ sơ';
      return _RescuerPerformance(
        uid: uid,
        name: (user['hoTen'] ?? scoreData['tenHienThi'] ?? uid).toString(),
        role: roleLabel,
        points: scores[uid] == null ? null : baoCaoInt(scoreData['diem']),
      );
    });

    for (final record in rescueRecords) {
      final rawMembers = record.data['DanhSachCuuHoVien'];
      if (rawMembers is! List) continue;
      for (final rawUid in rawMembers) {
        final uid = rawUid.toString();
        if (uid.isEmpty) continue;
        final detailMap = record.data['chiTietTheoCuuHoVien'];
        final detail = detailMap is Map && detailMap[uid] is Map
            ? Map<String, dynamic>.from(detailMap[uid] as Map)
            : const <String, dynamic>{};
        final duration = baoCaoInt(detail['tongThoiGianGiay']) > 0
            ? baoCaoInt(detail['tongThoiGianGiay'])
            : baoCaoInt(detail['tongThoiGianCaGiay']);
        final current = rowFor(uid);
        current.cases++;
        current.durationSeconds += duration;
        if (duration > 0) current.durationSamples++;
      }
    }

    for (final review in reviews) {
      final uid = (review.data['maNguoiCuuHo'] ?? review.id).toString().trim();
      final score = baoCaoDouble(review.data['diemDanhGia']);
      if (uid.isEmpty || score < 1 || score > 5) continue;
      final current = rowFor(uid);
      current.ratingTotal += score;
      current.ratingCount++;
    }

    final rows = aggregate.values.toList()
      ..sort((a, b) {
        final c = b.cases.compareTo(a.cases);
        if (c != 0) return c;
        final rating = (b.averageRating ?? 0).compareTo(a.averageRating ?? 0);
        return rating != 0 ? rating : a.name.compareTo(b.name);
      });
    return rows;
  }

  Future<void> openMap() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _BaoCaoBanDoScreen(requests: requests),
      ),
    );
  }

  Future<void> chooseCustomRange() async {
    final now = _today();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange:
          customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 29)),
            end: now,
          ),
      helpText: 'Chọn khoảng thời gian báo cáo',
      saveText: 'ÁP DỤNG',
      builder: (context, child) =>
          Theme(data: accountTheme(context), child: child!),
    );
    if (picked == null || !mounted) return;
    setState(() {
      customRange = picked;
      period = 'custom';
    });
    load();
  }

  String _csvCell(Object? value) {
    final text = (value ?? '').toString().replaceAll('"', '""');
    return '"$text"';
  }

  Future<void> exportCsv() async {
    final rows = <List<Object?>>[
      ['BÁO CÁO & THỐNG KÊ CỨU HỘ', periodLabel],
      [
        'Lọc loại yêu cầu',
        selectedType == null
            ? 'Tất cả'
            : availableTypeNames[selectedType] ?? selectedType,
      ],
      [
        'Lọc trạng thái',
        selectedStatus == null ? 'Tất cả' : _statusLabel(selectedStatus!),
      ],
      [
        'Lọc mức khẩn cấp',
        selectedUrgency == null ? 'Tất cả' : 'Mức $selectedUrgency',
      ],
      ['Chỉ số', 'Giá trị'],
      ['Tổng yêu cầu', totalRequests],
      ['Đang mở', activeRequests],
      ['Cần can thiệp', interventionRequests],
      ['Hoàn thành', completedRequests],
      ['Admin đóng ca', adminClosedRequests],
      ['Đã hủy', cancelledRequests],
      ['Tỷ lệ hoàn thành (%)', completionRate.toStringAsFixed(1)],
      ['Tỷ lệ Admin đóng ca (%)', adminCloseRate.toStringAsFixed(1)],
      ['Tỷ lệ đang xử lý (%)', _rate(processingRequests).toStringAsFixed(1)],
      ['Tỷ lệ cần can thiệp (%)', interventionRate.toStringAsFixed(1)],
      ['Tỷ lệ đã hủy (%)', cancellationRate.toStringAsFixed(1)],
      [
        'Thời gian điều phối trung bình (phút)',
        averageDispatchMinutes?.toStringAsFixed(1) ?? 'Không đủ dữ liệu',
      ],
      ['Hồ sơ cứu hộ', rescueRecords.length],
      [
        'Thời gian ca trung bình (giây)',
        averageRescueSeconds == 0 ? 'Không đủ dữ liệu' : averageRescueSeconds,
      ],
      ['Người cứu hộ trong hồ sơ', performance.length],
      ['Người cứu hộ đã đăng ký', rescuerCount],
      ['Hồ sơ cứu hộ đã duyệt', approvedRescuers],
      ['Đang trực tuyến', onlineRescuers],
      ['Đang bật nhận ca', receivingRescuers],
      ['Số lượt đánh giá', reviews.length],
      [
        'Điểm đánh giá trung bình',
        averageRating?.toStringAsFixed(2) ?? 'Không đủ dữ liệu',
      ],
      ['Đánh giá 1–2 sao', lowRatings],
      [],
      [
        'MÃ YÊU CẦU',
        'THỜI GIAN TẠO',
        'LOẠI',
        'TRẠNG THÁI',
        'MỨC ĐỘ KHẨN CẤP',
        'THỜI GIAN PHÂN CÔNG',
        'THỜI GIAN HOÀN THÀNH',
      ],
      ...requests.map(
        (r) => [
          r.id,
          _dateTimeText(baoCaoDate(r.data['thoiGianTao'])),
          typeNames[r.data['maLoaiYeuCau']?.toString()] ??
              r.data['maLoaiYeuCau'] ??
              '',
          _statusLabel(_status(r)),
          r.data['mucDoKhanCap'] ?? '',
          _dateTimeText(baoCaoDate(r.data['thoiGianPhanCong'])),
          _dateTimeText(baoCaoDate(r.data['thoiGianHoanThanh'])),
        ],
      ),
      [],
      [
        'NGƯỜI CỨU HỘ',
        'LOẠI HỒ SƠ',
        'SỐ HỒ SƠ THAM GIA',
        'THỜI GIAN GHI NHẬN (GIÂY)',
        'ĐIỂM TÍCH LŨY',
        'ĐIỂM ĐÁNH GIÁ TB',
        'SỐ LƯỢT ĐÁNH GIÁ',
      ],
      ...performance.map(
        (p) => [
          p.name,
          p.role,
          p.cases,
          p.durationSamples == 0 ? '' : p.durationSeconds,
          p.points ?? '',
          p.averageRating?.toStringAsFixed(2) ?? '',
          p.ratingCount,
        ],
      ),
    ];
    final csv =
        '\uFEFF${rows.map((r) => r.map(_csvCell).join(',')).join('\r\n')}';
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép báo cáo.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: accountTheme(context),
    child: Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Báo cáo & thống kê',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Bản đồ phân bố yêu cầu',
            onPressed: data == null ? null : openMap,
            icon: const Icon(Icons.map_outlined),
          ),
          IconButton(
            tooltip: 'Sao chép báo cáo CSV',
            onPressed:
                data == null || loading || detailsLoading || !detailsLoaded
                ? null
                : exportCsv,
            icon: const Icon(Icons.content_copy_rounded),
          ),
          IconButton(
            tooltip: 'Làm mới dữ liệu',
            onPressed: loading || detailsLoading ? null : load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _border)),
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
                null,
                selected: true,
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
      body: error != null && data == null
          ? _ErrorView(onRetry: load)
          : data == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    children: [
                      _periodSelector(),
                      const SizedBox(height: 14),
                      if (error != null)
                        _panel(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: _orange,
                              ),
                              const SizedBox(width: 9),
                              const Expanded(
                                child: Text(
                                  'Không thể cập nhật báo cáo. Vui lòng thử lại.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (loading) const LinearProgressIndicator(minHeight: 2),
                      _sectionTitle('Tổng quan yêu cầu'),
                      const SizedBox(height: 10),
                      _kpiGrid([
                        _Kpi(
                          'Tổng yêu cầu',
                          '$totalRequests',
                          Icons.assignment_outlined,
                          _blue,
                        ),
                        _Kpi(
                          'Đang mở',
                          '$activeRequests',
                          Icons.pending_actions_rounded,
                          _orange,
                        ),
                        _Kpi(
                          'Cần can thiệp',
                          '$interventionRequests',
                          Icons.warning_amber_rounded,
                          _red,
                        ),
                        _Kpi(
                          'Hoàn thành',
                          '$completedRequests',
                          Icons.task_alt_rounded,
                          _green,
                        ),
                        _Kpi(
                          'Admin đóng ca',
                          '$adminClosedRequests',
                          Icons.lock_clock_rounded,
                          _blue,
                        ),
                        _Kpi(
                          'Đã hủy',
                          '$cancelledRequests',
                          Icons.cancel_outlined,
                          _muted,
                        ),
                      ]),
                      const SizedBox(height: 18),
                      _sectionTitle('Tỷ lệ yêu cầu'),
                      const SizedBox(height: 10),
                      _panel(child: _requestRateContent()),
                      const SizedBox(height: 18),
                      _sectionTitle('Xu hướng yêu cầu'),
                      const SizedBox(height: 10),
                      _panel(child: _trendContent()),
                      const SizedBox(height: 12),
                      _panel(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF3FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.location_on_outlined,
                                color: _blue,
                              ),
                            ),
                            const SizedBox(width: 11),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bản đồ phân bố yêu cầu',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _ink,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Quan sát cụm vị trí phát sinh yêu cầu trong kỳ.',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: openMap,
                              icon: const Icon(Icons.open_in_new, size: 15),
                              label: const Text('Mở bản đồ'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle('Cơ cấu yêu cầu'),
                      const SizedBox(height: 10),
                      _responsivePair(
                        _panel(
                          child: _breakdownContent(
                            'Theo loại yêu cầu',
                            typeBreakdown,
                            totalRequests,
                          ),
                        ),
                        _panel(
                          child: _breakdownContent(
                            'Theo trạng thái',
                            statusBreakdown,
                            totalRequests,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _panel(
                        child: _breakdownContent(
                          'Theo mức độ khẩn cấp',
                          urgencyBreakdown,
                          totalRequests,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cập nhật lúc: ${_dateTimeText(data?.loadedAt)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: _muted,
                              ),
                            ),
                            if (!detailsLoaded) ...[
                              const SizedBox(height: 10),
                              FilledButton.icon(
                                onPressed: detailsLoading ? null : loadDetails,
                                icon: detailsLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.analytics_outlined),
                                label: Text(
                                  detailsLoading
                                      ? 'Đang tải dữ liệu chi tiết…'
                                      : 'Tải thống kê cứu hộ và đánh giá',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (detailsLoaded) ...[
                        const SizedBox(height: 18),
                        _sectionTitle('Hiệu quả điều phối & cứu hộ'),
                        const SizedBox(height: 10),
                        _responsivePair(
                          _metricPanel(
                            icon: Icons.timer_outlined,
                            title: 'Thời gian điều phối trung bình',
                            value: averageDispatchMinutes == null
                                ? '—'
                                : '${averageDispatchMinutes!.toStringAsFixed(1)} phút',
                            color: _blue,
                          ),
                          _metricPanel(
                            icon: Icons.medical_services_outlined,
                            title: 'Thời gian ca trong hồ sơ',
                            value: averageRescueSeconds == 0
                                ? '—'
                                : _duration(averageRescueSeconds),
                            color: _teal,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _panel(child: _rescueRecordSummary()),
                        const SizedBox(height: 18),
                        _sectionTitle('Mạng lưới người cứu hộ'),
                        const SizedBox(height: 10),
                        _kpiGrid([
                          _Kpi(
                            'Tài khoản cứu hộ',
                            '$rescuerCount',
                            Icons.people_alt_outlined,
                            _blue,
                          ),
                          _Kpi(
                            'Hồ sơ đã duyệt',
                            '$approvedRescuers',
                            Icons.verified_user_outlined,
                            _green,
                          ),
                          _Kpi(
                            'Đang trực tuyến',
                            '$onlineRescuers',
                            Icons.wifi_tethering_rounded,
                            _teal,
                          ),
                          _Kpi(
                            'Đang bật nhận ca',
                            '$receivingRescuers',
                            Icons.notifications_active_outlined,
                            _purple,
                          ),
                        ]),
                        const SizedBox(height: 18),
                        _sectionTitle('Hiệu suất theo người cứu hộ'),
                        const SizedBox(height: 10),
                        _panel(child: _performanceContent()),
                        const SizedBox(height: 18),
                        _sectionTitle('Chất lượng hỗ trợ'),
                        const SizedBox(height: 10),
                        _ratingPanel(),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    ),
  );

  Widget _periodSelector() => _panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.calendar_month_outlined, size: 18, color: _blue),
            SizedBox(width: 8),
            Text(
              'Khoảng thời gian',
              style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _periodChip('7 ngày', '7d'),
            _periodChip('30 ngày', '30d'),
            _periodChip('90 ngày', '90d'),
            _periodChip('Tất cả', 'all'),
            ActionChip(
              avatar: const Icon(Icons.date_range_outlined, size: 16),
              label: Text(period == 'custom' ? 'Tùy chọn' : 'Chọn ngày'),
              onPressed: chooseCustomRange,
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Lọc dữ liệu yêu cầu',
          style: TextStyle(
            fontSize: 11,
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760
                ? 3
                : constraints.maxWidth >= 520
                ? 2
                : 1;
            final fieldWidth =
                (constraints.maxWidth - (columns - 1) * 8) / columns;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: fieldWidth,
                  child: _filterDropdown<String>(
                    hint: 'Tất cả loại yêu cầu',
                    value: selectedType,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'Tất cả loại yêu cầu',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...availableTypeNames.entries.map(
                        (e) => DropdownMenuItem<String?>(
                          value: e.key,
                          child: Text(
                            e.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => selectedType = v),
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: _filterDropdown<String>(
                    hint: 'Tất cả trạng thái',
                    value: selectedStatus,
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'Tất cả trạng thái',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'cho_tiep_nhan',
                        child: Text('Chờ tiếp nhận'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'qua_han_dieu_phoi',
                        child: Text('Quá hạn điều phối'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'da_phan_cong',
                        child: Text('Đã phân công'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'dang_cuu_ho',
                        child: Text('Đang cứu hộ'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'cho_dong',
                        child: Text('Chờ đóng'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'hoan_thanh',
                        child: Text('Hoàn thành'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'da_huy',
                        child: Text('Đã hủy'),
                      ),
                    ],
                    onChanged: (v) => setState(() => selectedStatus = v),
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: _filterDropdown<int>(
                    hint: 'Mọi mức khẩn cấp',
                    value: selectedUrgency,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          'Mọi mức khẩn cấp',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...urgencyOptions.map(
                        (v) => DropdownMenuItem<int?>(
                          value: v,
                          child: Text('Mức $v'),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => selectedUrgency = v),
                  ),
                ),
                if (selectedType != null ||
                    selectedStatus != null ||
                    selectedUrgency != null)
                  TextButton.icon(
                    onPressed: () => setState(() {
                      selectedType = null;
                      selectedStatus = null;
                      selectedUrgency = null;
                    }),
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                    label: const Text('Xóa bộ lọc'),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );

  Widget _periodChip(String label, String value) => ChoiceChip(
    label: Text(label),
    selected: period == value,
    onSelected: (_) {
      if (period == value) return;
      setState(() => period = value);
      load();
    },
    selectedColor: const Color(0xFFE5F0FF),
    labelStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: period == value ? _blue : _muted,
    ),
    side: BorderSide(
      color: period == value ? const Color(0xFFB9D4F5) : _border,
    ),
    backgroundColor: Colors.white,
  );

  Widget _filterDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T?>> items,
    required ValueChanged<T?> onChanged,
  }) => DropdownButtonFormField<T?>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFFAFBFD),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _border),
      ),
    ),
    items: items,
    onChanged: onChanged,
  );

  Widget _sectionTitle(String title) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: _ink,
      ),
    ),
  );

  Widget _kpiGrid(List<_Kpi> items) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900
          ? 4
          : constraints.maxWidth >= 620
          ? 3
          : 2;
      final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final item in items)
            SizedBox(width: width, child: _KpiCard(item)),
        ],
      );
    },
  );

  Widget _panel({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _border),
    ),
    child: child,
  );

  Widget _responsivePair(Widget first, Widget second) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 560)
        return Column(children: [first, const SizedBox(height: 12), second]);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: 12),
          Expanded(child: second),
        ],
      );
    },
  );

  Widget _trendContent() {
    final points = trend;
    if (points.isEmpty)
      return const _EmptyNote('Chưa có yêu cầu trong khoảng thời gian này.');
    final maxValue = points
        .map((p) => p.count)
        .fold<int>(0, (a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Số yêu cầu được tạo',
                style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
              ),
            ),
            Text(
              '$totalRequests yêu cầu',
              style: const TextStyle(
                color: _blue,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 142,
          width: double.infinity,
          child: CustomPaint(
            painter: _TrendPainter(
              points.map((p) => p.count).toList(),
              maxValue,
            ),
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final visibleLabels = constraints.maxWidth < 430 ? 4 : 8;
            final step = math.max(1, (points.length / visibleLabels).ceil());
            return Row(
              children: [
                for (var i = 0; i < points.length; i++)
                  Expanded(
                    child: Text(
                      i % step == 0 || i == points.length - 1
                          ? points[i].label
                          : '',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _breakdownContent(String title, List<_Breakdown> rows, int total) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, color: _ink),
          ),
          const SizedBox(height: 13),
          if (rows.isEmpty) const _EmptyNote('Chưa có dữ liệu trong kỳ.'),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.label,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${row.count}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : row.count / total,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFF0F3F8),
                      valueColor: AlwaysStoppedAnimation(row.color),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );

  Widget _metricPanel({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) => _panel(
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  color: _ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _requestRateContent() {
    final items = <_RequestRate>[
      _RequestRate('Hoàn thành', completionRate, completedRequests, _green),
      _RequestRate('Admin đóng ca', adminCloseRate, adminClosedRequests, _blue),
      _RequestRate(
        'Đang xử lý',
        _rate(processingRequests),
        processingRequests,
        _blue,
      ),
      _RequestRate(
        'Cần can thiệp',
        interventionRate,
        interventionRequests,
        _red,
      ),
      _RequestRate('Đã hủy', cancellationRate, cancelledRequests, _orange),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 18) / columns;
        return Wrap(
          spacing: 18,
          runSpacing: 18,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                        ),
                        Text(
                          '${item.count}/$totalRequests · ${item.rate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: item.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: (item.rate / 100).clamp(0, 1).toDouble(),
                        minHeight: 9,
                        backgroundColor: const Color(0xFFF0F3F8),
                        valueColor: AlwaysStoppedAnimation(item.color),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _rescueRecordSummary() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Hồ sơ cứu hộ trong kỳ',
        style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _smallStat(
              'Hồ sơ ghi nhận',
              '${rescueRecords.length}',
              Icons.folder_copy_outlined,
              _blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _smallStat(
              'Người cứu hộ tham gia',
              '${performance.length}',
              Icons.groups_2_outlined,
              _teal,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _smallStat(
              'Có xác nhận ký số',
              '${rescueRecords.where((r) => r.data['xacThucKySo'] is Map && (r.data['xacThucKySo'] as Map)['trangThai'] == 'HỢP LỆ').length}',
              Icons.verified_outlined,
              _green,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _smallStat(String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(height: 7),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _ink,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: _muted),
              maxLines: 2,
            ),
          ],
        ),
      );

  Widget _performanceContent() {
    final rows = performance;
    if (rows.isEmpty)
      return const _EmptyNote(
        'Chưa có dữ liệu hiệu suất trong khoảng thời gian này.',
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Xếp theo số hồ sơ tham gia',
                style: TextStyle(fontSize: 10, color: _muted),
              ),
            ),
            Text(
              '${rows.length} người',
              style: const TextStyle(fontSize: 10, color: _muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < math.min(rows.length, 10); i++)
          _performanceRow(i + 1, rows[i]),
        if (rows.length > 10)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Còn ${rows.length - 10} người cứu hộ khác.',
              style: const TextStyle(fontSize: 10, color: _muted),
            ),
          ),
      ],
    );
  }

  Widget _performanceRow(int rank, _RescuerPerformance row) {
    final subtitle = row.points == null
        ? row.role
        : '${row.role} · ${row.points} điểm';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 27,
            height: 27,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank == 1
                  ? const Color(0xFFFFF3D6)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: rank == 1 ? _orange : _muted,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${row.cases} hồ sơ',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: _blue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                row.durationSamples == 0 ? '—' : _duration(row.durationSeconds),
                style: const TextStyle(fontSize: 9, color: _muted),
              ),
              const SizedBox(height: 2),
              Text(
                row.ratingCount == 0
                    ? 'Chưa có đánh giá'
                    : '${row.averageRating!.toStringAsFixed(1)}★ · ${row.ratingCount} lượt',
                style: const TextStyle(fontSize: 9, color: _muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ratingPanel() {
    final avg = averageRating;
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFD69E17),
                  size: 29,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      avg == null ? '— / 5' : '${avg.toStringAsFixed(2)} / 5',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                    const Text(
                      'Điểm trung bình',
                      style: TextStyle(fontSize: 10, color: _muted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${reviews.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                  const Text(
                    'lượt đánh giá',
                    style: TextStyle(fontSize: 9, color: _muted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _ratingBar('1–2 sao', lowRatings, reviews.length, _red),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ratingBar(
                  '3–5 sao',
                  reviews.length - lowRatings,
                  reviews.length,
                  _green,
                ),
              ),
            ],
          ),
          if (data?.reviewLoadError != null)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Không thể tải đánh giá lúc này.',
                style: TextStyle(fontSize: 10, color: _red),
              ),
            ),
          if (data?.reviewLoadError == null && reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Chưa có đánh giá trong khoảng thời gian đã chọn.',
                style: TextStyle(fontSize: 10, color: _muted),
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/danh-gia'),
              icon: const Icon(Icons.open_in_new, size: 15),
              label: const Text('Mở quản lý đánh giá'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingBar(String label, int count, int total, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, color: _muted),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LinearProgressIndicator(
          value: total == 0 ? 0 : count / total,
          minHeight: 7,
          backgroundColor: const Color(0xFFF0F3F8),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    ],
  );

  String _statusLabel(String status) =>
      const {
        'cho_tiep_nhan': 'Chờ tiếp nhận',
        'qua_han_dieu_phoi': 'Quá hạn điều phối',
        'da_phan_cong': 'Đã phân công',
        'dang_cuu_ho': 'Đang cứu hộ',
        'cho_dong': 'Chờ đóng',
        'hoan_thanh': 'Hoàn thành',
        'da_huy': 'Đã hủy',
      }[status] ??
      'Trạng thái khác';

  String _duration(int seconds) {
    final h = seconds ~/ 3600;
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  String _dateTimeText(DateTime? date) {
    if (date == null) return '—';
    final local = date.toLocal();
    return '${_dateLabel(local)}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _BaoCaoMapCluster {
  final LatLng center;
  final List<String> requestIds;
  const _BaoCaoMapCluster(this.center, this.requestIds);
}

class _BaoCaoBanDoScreen extends StatefulWidget {
  final List<BaoCaoRow> requests;
  const _BaoCaoBanDoScreen({required this.requests});

  @override
  State<_BaoCaoBanDoScreen> createState() => _BaoCaoBanDoScreenState();
}

class _BaoCaoBanDoScreenState extends State<_BaoCaoBanDoScreen> {
  List<_BaoCaoMapCluster> get clusters {
    final grouped = <String, List<BaoCaoRow>>{};
    for (final row in widget.requests) {
      final lat = _coordinate(row.data['viDo'], 90);
      final lng = _coordinate(row.data['kinhDo'], 180);
      if (lat == null || lng == null) continue;
      final key = '${lat.toStringAsFixed(3)}|${lng.toStringAsFixed(3)}';
      grouped.putIfAbsent(key, () => []).add(row);
    }
    return grouped.values.map((items) {
      final points = items
          .map(
            (row) => LatLng(
              _coordinate(row.data['viDo'], 90)!,
              _coordinate(row.data['kinhDo'], 180)!,
            ),
          )
          .toList();
      final lat =
          points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
      final lng =
          points.map((p) => p.longitude).reduce((a, b) => a + b) /
          points.length;
      return _BaoCaoMapCluster(
        LatLng(lat, lng),
        items.map((e) => e.id).toList(),
      );
    }).toList();
  }

  static double? _coordinate(Object? value, double bound) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse('${value ?? ''}');
    if (number == null || !number.isFinite || number.abs() > bound) return null;
    return number;
  }

  void onMapCreated(GoogleMapController controller) {
    final points = clusters;
    if (points.length == 1) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: points.first.center, zoom: 13),
        ),
      );
      return;
    }
    if (points.length > 1) {
      final lats = points.map((p) => p.center.latitude);
      final lngs = points.map((p) => p.center.longitude);
      final minLat = lats.reduce((a, b) => a < b ? a : b);
      final maxLat = lats.reduce((a, b) => a > b ? a : b);
      final minLng = lngs.reduce((a, b) => a < b ? a : b);
      final maxLng = lngs.reduce((a, b) => a > b ? a : b);
      final south = minLat == maxLat ? minLat - 0.001 : minLat;
      final north = minLat == maxLat ? maxLat + 0.001 : maxLat;
      final west = minLng == maxLng ? minLng - 0.001 : minLng;
      final east = minLng == maxLng ? maxLng + 0.001 : maxLng;
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(south, west),
            northeast: LatLng(north, east),
          ),
          64,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = clusters;
    return Scaffold(
      appBar: AppBar(title: const Text('Bản đồ phân bố yêu cầu')),
      body: points.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_off_outlined, size: 42, color: _muted),
                    SizedBox(height: 12),
                    Text(
                      'Không có tọa độ hợp lệ',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Chưa có vị trí để hiển thị.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: points.first.center,
                    zoom: 11.5,
                  ),
                  onMapCreated: onMapCreated,
                  mapToolbarEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  markers: {
                    for (var i = 0; i < points.length; i++)
                      Marker(
                        markerId: MarkerId('request_cluster_$i'),
                        position: points[i].center,
                        infoWindow: InfoWindow(
                          title: '${points[i].requestIds.length} yêu cầu',
                          snippet: points[i].requestIds.take(5).join(', '),
                        ),
                      ),
                  },
                  circles: {
                    for (var i = 0; i < points.length; i++)
                      Circle(
                        circleId: CircleId('request_density_$i'),
                        center: points[i].center,
                        radius: 170.0 + points[i].requestIds.length * 55.0,
                        fillColor: _blue.withValues(alpha: .13),
                        strokeColor: _blue.withValues(alpha: .48),
                        strokeWidth: 1,
                      ),
                  },
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .96),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .08),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: _blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.requests.length} yêu cầu · ${points.length} cụm vị trí',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Kpi {
  final String title, value;
  final IconData icon;
  final Color color;
  const _Kpi(this.title, this.value, this.icon, this.color);
}

class _KpiCard extends StatelessWidget {
  final _Kpi item;
  const _KpiCard(this.item);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: _border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, color: item.color, size: 19),
        ),
        const SizedBox(height: 12),
        Text(
          item.value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: _ink,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Text(
          item.title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

class _RequestRate {
  final String label;
  final double rate;
  final int count;
  final Color color;
  const _RequestRate(this.label, this.rate, this.count, this.color);
}

class _Breakdown {
  final String label;
  final int count;
  final Color color;
  const _Breakdown(this.label, this.count, this.color);
}

class _TrendPoint {
  final String label;
  final int count;
  const _TrendPoint(this.label, this.count);
}

class _RescuerPerformance {
  final String uid, name, role;
  final int? points;
  int cases = 0;
  int durationSeconds = 0;
  int durationSamples = 0;
  double ratingTotal = 0;
  int ratingCount = 0;
  double? get averageRating =>
      ratingCount == 0 ? null : ratingTotal / ratingCount;
  _RescuerPerformance({
    required this.uid,
    required this.name,
    required this.role,
    required this.points,
  });
}

class _TrendPainter extends CustomPainter {
  final List<int> values;
  final int maxValue;
  _TrendPainter(this.values, this.maxValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final baseline = size.height - 8;
    final chartHeight = size.height - 20;
    final gridPaint = Paint()
      ..color = const Color(0xFFEAF0F7)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = 8 + chartHeight * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final gap = math.min(8.0, size.width / (values.length * 3));
    final barWidth = (size.width - gap * (values.length - 1)) / values.length;
    for (var i = 0; i < values.length; i++) {
      final height = maxValue == 0 ? 0.0 : chartHeight * values[i] / maxValue;
      final left = i * (barWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, baseline - height, barWidth, height),
        const Radius.circular(6),
      );
      final paint = Paint()
        ..shader =
            const LinearGradient(
              colors: [Color(0xFF2D8BE8), Color(0xFF145AA6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(
              Rect.fromLTWH(
                left,
                baseline - height,
                barWidth,
                height < 1 ? 1.0 : height,
              ),
            );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.maxValue != maxValue;
}

class _ErrorView extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _ErrorView({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: _red, size: 42),
          const SizedBox(height: 12),
          const Text(
            'Không tải được báo cáo',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: _ink,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Vui lòng thử lại sau.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );
}

class _EmptyNote extends StatelessWidget {
  final String message;
  const _EmptyNote(this.message);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        const Icon(Icons.inbox_outlined, color: _muted, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 11, color: _muted),
          ),
        ),
      ],
    ),
  );
}
