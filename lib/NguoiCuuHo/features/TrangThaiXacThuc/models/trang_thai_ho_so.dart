import 'package:flutter/material.dart';

/// Thời gian thẩm định dự kiến (giờ, tính liên tục). Dùng chung cho form đăng ký
/// và màn trạng thái để hai nơi không bao giờ ghi hai con số khác nhau.
const int kThamDinhSlaGio = 48;

const String _prefix = 'cuuho_trangthai_hoso_';

/// Trạng thái hồ sơ cứu hộ viên. Đây là NGUỒN DUY NHẤT ánh xạ mã Firestore
/// (`maTrangThaiHoSo`) sang nhãn, màu và hành vi trên giao diện.
enum TrangThaiHoSo {
  tiepNhan,
  dangThamDinh,
  canBoSung,
  tuChoi,
  tamKhoa,
  daDuyet,

  /// Mã lạ mà app chưa hiểu. KHÔNG được coi như "đang tiếp nhận".
  khongXacDinh,
}

extension TrangThaiHoSoX on TrangThaiHoSo {
  String get code {
    switch (this) {
      case TrangThaiHoSo.tiepNhan:
        return '${_prefix}tiepnhan';
      case TrangThaiHoSo.dangThamDinh:
        return '${_prefix}dangthamdinh';
      case TrangThaiHoSo.canBoSung:
        return '${_prefix}canbosung';
      case TrangThaiHoSo.tuChoi:
        return '${_prefix}tuchoi';
      case TrangThaiHoSo.tamKhoa:
        return '${_prefix}tamkhoa';
      case TrangThaiHoSo.daDuyet:
        return '${_prefix}daduyet';
      case TrangThaiHoSo.khongXacDinh:
        return '';
    }
  }

  String get label {
    switch (this) {
      case TrangThaiHoSo.tiepNhan:
        return 'Đang tiếp nhận';
      case TrangThaiHoSo.dangThamDinh:
        return 'Đang thẩm định';
      case TrangThaiHoSo.canBoSung:
        return 'Cần bổ sung';
      case TrangThaiHoSo.tuChoi:
        return 'Bị từ chối';
      case TrangThaiHoSo.tamKhoa:
        return 'Tạm khóa';
      case TrangThaiHoSo.daDuyet:
        return 'Đã phê duyệt';
      case TrangThaiHoSo.khongXacDinh:
        return 'Không xác định';
    }
  }

  Color get color {
    switch (this) {
      case TrangThaiHoSo.tiepNhan:
      case TrangThaiHoSo.dangThamDinh:
        return const Color(0xFF0284C7);
      case TrangThaiHoSo.canBoSung:
        return const Color(0xFFD97706);
      case TrangThaiHoSo.tuChoi:
        return const Color(0xFFB91C1C);
      case TrangThaiHoSo.tamKhoa:
        return const Color(0xFF475569);
      case TrangThaiHoSo.daDuyet:
        return const Color(0xFF137333);
      case TrangThaiHoSo.khongXacDinh:
        return const Color(0xFF64748B);
    }
  }

  Color get background {
    switch (this) {
      case TrangThaiHoSo.tiepNhan:
      case TrangThaiHoSo.dangThamDinh:
        return const Color(0xFFE0F2FE);
      case TrangThaiHoSo.canBoSung:
        return const Color(0xFFFEF3C7);
      case TrangThaiHoSo.tuChoi:
        return const Color(0xFFFEE2E2);
      case TrangThaiHoSo.tamKhoa:
        return const Color(0xFFE2E8F0);
      case TrangThaiHoSo.daDuyet:
        return const Color(0xFFE6F4EA);
      case TrangThaiHoSo.khongXacDinh:
        return const Color(0xFFF1F5F9);
    }
  }

  IconData get icon {
    switch (this) {
      case TrangThaiHoSo.tiepNhan:
      case TrangThaiHoSo.dangThamDinh:
        return Icons.hourglass_top_rounded;
      case TrangThaiHoSo.canBoSung:
        return Icons.edit_note_rounded;
      case TrangThaiHoSo.tuChoi:
        return Icons.cancel_outlined;
      case TrangThaiHoSo.tamKhoa:
        return Icons.lock_outline;
      case TrangThaiHoSo.daDuyet:
        return Icons.check_circle_outlined;
      case TrangThaiHoSo.khongXacDinh:
        return Icons.help_outline;
    }
  }

  /// Hồ sơ đang chờ người duyệt (hiện đếm ngược, khóa nhận ca).
  bool get dangCho =>
      this == TrangThaiHoSo.tiepNhan || this == TrangThaiHoSo.dangThamDinh;

  /// Người dùng có thể sửa và gửi lại hồ sơ.
  bool get choPhepGuiLai =>
      this == TrangThaiHoSo.canBoSung || this == TrangThaiHoSo.tuChoi;
}

/// Chuyển mã Firestore thành trạng thái. Chấp nhận mã cũ và mã rút gọn.
/// Chuỗi rỗng (hồ sơ mới) coi là `tiepNhan`; mã lạ trả về `khongXacDinh`.
TrangThaiHoSo trangThaiTuMa(String? raw) {
  final s = (raw ?? '').trim().toLowerCase();
  if (s.isEmpty) return TrangThaiHoSo.tiepNhan;

  final short = s.startsWith(_prefix) ? s.substring(_prefix.length) : s;
  switch (short) {
    case 'tiepnhan':
    case 'cuuho_trangthai_tiepnhan': // mã cũ có lúc từng được dùng làm mặc định
      return TrangThaiHoSo.tiepNhan;
    case 'dangthamdinh':
      return TrangThaiHoSo.dangThamDinh;
    case 'canbosung':
      return TrangThaiHoSo.canBoSung;
    case 'tuchoi':
      return TrangThaiHoSo.tuChoi;
    case 'tamkhoa':
      return TrangThaiHoSo.tamKhoa;
    case 'daduyet':
      return TrangThaiHoSo.daDuyet;
    default:
      return TrangThaiHoSo.khongXacDinh;
  }
}
