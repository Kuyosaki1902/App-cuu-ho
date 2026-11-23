import 'yeu_cau_ho_tro_model.dart';

String assignmentStatus(Object? raw) {
  const aliases = {
    'cuuho_trangthai_chophanhoi': 'da_gui_thong_bao',
    'cuuho_trangthai_phancong_chotiepnhan': 'da_gui_thong_bao',
    'cuuho_trangthai_phancong_tiepnhan': 'duoc_chon',
    'da_dong_y': 'duoc_chon',
    'cuuho_trangthai_phancong_daphancong': 'duoc_chon',
    'cuuho_trangthai_phancong_daden': 'duoc_chon',
    'cuuho_trangthai_phancong_dangcuuho': 'duoc_chon',
    'cuuho_trangthai_phancong_tuchoi': 'tu_choi',
    'cuuho_trangthai_phancong_dahuy': 'da_huy',
    'cuuho_trangthai_phancong_hoanthanh': 'hoan_thanh',
  };
  return aliases[raw] ?? (raw is String ? raw : '');
}

Map<String, String> phanCongTrongCa(Map<String, dynamic> data) {
  final raw = data['danhSachPhanCongVien'];
  if (raw is! Map) return {};
  return {
    for (final entry in raw.entries)
      if (entry.key is String &&
          (entry.key as String).isNotEmpty &&
          !(entry.key as String).contains('/') &&
          entry.value is String)
        entry.key as String: entry.value as String,
  };
}

String assignmentLabel(Object? raw) =>
    const {
      'da_gui_thong_bao': 'Chờ tiếp nhận',
      'duoc_chon': 'Đang phụ trách',
      'tu_choi': 'Đã từ chối',
      'da_huy': 'Đã hủy',
      'hoan_thanh': 'Hoàn thành',
    }[assignmentStatus(raw)] ??
    'Chưa rõ trạng thái';

const selectedAssignmentCodes = [
  'cuuho_trangthai_phancong_tiepnhan',
  'da_dong_y',
  'duoc_chon',
  'cuuho_trangthai_phancong_daphancong',
  'cuuho_trangthai_phancong_daden',
  'cuuho_trangthai_phancong_dangcuuho',
];
bool reviewableRequest(Object? status) =>
    ['da_phan_cong', 'dang_cuu_ho'].contains(normalizeRequestStatus(status));

void validateCheckResult(String outcome, String note) {
  if (!['tiep_tuc', 'can_thay_nguoi'].contains(outcome)) {
    throw StateError('Chọn kết quả kiểm tra.');
  }
  if (note.trim().length > 500 ||
      (outcome == 'can_thay_nguoi' && note.trim().length < 10)) {
    throw StateError('Lý do thay người cần từ 10 đến 500 ký tự.');
  }
}

String incidentDescription(Object? raw) {
  if (raw is String) return raw.trim();
  if (raw is Map) {
    final symptoms = raw['trieuChung'];
    final detail = raw['moTaChiTiet'];
    return [
      if (symptoms is List) symptoms.whereType<String>().join(' · '),
      if (symptoms is String) symptoms,
      if (detail is String) detail,
    ].where((s) => s.trim().isNotEmpty).join('\n');
  }
  return '';
}

bool staleLocation(DateTime? updated, DateTime now, Duration threshold) =>
    updated == null ||
    updated.isAfter(now) ||
    now.difference(updated) > threshold;
