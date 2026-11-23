String maNanNhan(Map<String, dynamic> data) {
  for (final key in ['maNguoiYeuCau', 'maNguoiDung']) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return '';
}

String normalizeRequestStatus(Object? value) {
  const aliases = {
    'user_tinhtrang_chotiepnhan': 'cho_tiep_nhan',
    'user_tinhtrang_quahandieuphoi': 'qua_han_dieu_phoi',
    'user_tinhtrang_daphancong': 'da_phan_cong',
    'user_tinhtrang_dangcuuho': 'dang_cuu_ho',
    'user_tinhtrang_hoanthanh': 'hoan_thanh',
    'user_tinhtrang_dahuy': 'da_huy',
  };
  final raw = value is String ? value.trim() : '';
  return aliases[raw] ?? raw;
}

const requestStatuses = {
  'cho_tiep_nhan': 'Đang tìm người hỗ trợ',
  'qua_han_dieu_phoi': 'Cần điều phối',
  'da_phan_cong': 'Đã phân công',
  'dang_cuu_ho': 'Đang hỗ trợ',
  'cho_dong': 'Chờ đóng',
  'hoan_thanh': 'Hoàn thành',
  'da_huy': 'Đã hủy',
};

String requestSearchText(String value) {
  const groups = [
    'àáạảãâầấậẩẫăằắặẳẵ',
    'èéẹẻẽêềếệểễ',
    'ìíịỉĩ',
    'òóọỏõôồốộổỗơờớợởỡ',
    'ùúụủũưừứựửữ',
    'ỳýỵỷỹ',
    'đ',
  ];
  var result = value.toLowerCase().trim();
  for (var i = 0; i < groups.length; i++) {
    for (final c in groups[i].split('')) {
      result = result.replaceAll(c, 'aeiouyd'[i]);
    }
  }
  return result;
}

class YeuCauHoTro {
  final String id;
  final Map<String, dynamic> data;
  final String tenNanNhan, typeName, assigneeName;
  final DateTime? createdAt;
  const YeuCauHoTro(
    this.id,
    this.data, {
    this.tenNanNhan = '',
    this.typeName = '',
    this.assigneeName = '',
    this.createdAt,
  });
  String text(String key) =>
      data[key] is String ? (data[key] as String).trim() : '';
  String get code => text('maYeuCau').isEmpty ? id : text('maYeuCau');
  String get status => normalizeRequestStatus(data['maTinhTrangYeuCau']);
  String get statusLabel =>
      requestStatuses[status] ??
      (status.isEmpty ? 'Chưa rõ trạng thái' : 'Chưa rõ trạng thái ($status)');
  bool get closed => ['hoan_thanh', 'da_huy'].contains(status);
  String get tab => closed ? 'closed' : 'active';
  bool get _canIntervene => !closed && status != 'cho_dong';
  bool get needsCheck => _canIntervene && data['canKiemTra'] == true;
  bool get needsDispatch =>
      _canIntervene &&
      (status == 'qua_han_dieu_phoi' || data['canBoSungNhanLuc'] == true);
  bool get needsIntervention => needsCheck || needsDispatch;
  String get title => text('tieuDe').isNotEmpty
      ? text('tieuDe')
      : typeName.isNotEmpty
      ? typeName
      : 'Yêu cầu cứu hộ';
  String get nanNhan => tenNanNhan.isNotEmpty
      ? tenNanNhan
      : maNanNhan(data).isNotEmpty
      ? maNanNhan(data)
      : 'Chưa có thông tin nạn nhân';
  String get assignee =>
      assigneeName.isNotEmpty ? assigneeName : text('tenNguoiCuuHo');
  double? coordinate(String key, double bound) {
    final raw = data[key];
    final value = raw is num ? raw.toDouble() : double.tryParse('$raw');
    return value != null && value.isFinite && value.abs() <= bound
        ? value
        : null;
  }

  double? get latitude => coordinate('viDo', 90);
  double? get longitude => coordinate('kinhDo', 180);
  bool get hasLocation => latitude != null && longitude != null;
  String get address => text('diaChi').isNotEmpty
      ? text('diaChi')
      : hasLocation
      ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
      : 'Chưa có vị trí';
  String get alert => needsCheck
      ? 'Cần kiểm tra tiến trình hỗ trợ'
      : needsDispatch
      ? (data['canBoSungNhanLuc'] == true
            ? 'Cần bổ sung người hỗ trợ'
            : 'Đã quá hạn điều phối tự động')
      : '';

  String get urgencyKey {
    final raw = data['mucDoKhanCap'];
    return raw == null ? '' : raw.toString().trim();
  }

  int? get urgencyLevel {
    final raw = data['mucDoKhanCap'];
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString().trim() ?? '');
  }

  String get urgencyLabel {
    final value = urgencyLevel;
    if (value == null) {
      return 'Chưa xác định';
    }
    if (value == 1) {
      return 'Mức 1 · SOS (Nguy kịch)';
    }
    if (value == 2) {
      return 'Mức 2 · Hỗ trợ y tế';
    }
    return 'Mức $value';
  }

  bool matches(String query) {
    final searchable = [
      id,
      code,
      nanNhan,
      maNanNhan(data),
      address,
      title,
      typeName,
      text('maLoaiYeuCau'),
    ].join(' ');
    return requestSearchText(searchable).contains(requestSearchText(query));
  }
}

String requestAge(DateTime? date, DateTime now) {
  if (date == null) return 'Chưa có thời gian';
  final minutes = now.difference(date).inMinutes;
  if (minutes < 0) return 'Chưa đến thời gian ghi nhận';
  if (minutes < 1) return 'Vừa xong';
  if (minutes < 60) return '$minutes phút trước';
  if (minutes < 1440) return '${minutes ~/ 60} giờ trước';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
