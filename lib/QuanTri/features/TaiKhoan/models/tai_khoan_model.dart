import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/trang_thai_ho_so.dart';

export '../../../models/trang_thai_ho_so.dart';

enum TrangThaiHoSo { cho_duyet, can_bo_sung, da_duyet, tu_choi, khoa }

String textOf(Map<String, dynamic> data, String key, [String fallback = '']) =>
    data[key] is String ? data[key] as String : fallback;
String dateText(dynamic value) {
  final DateTime? date = value is Timestamp
      ? value.toDate()
      : value is String
      ? DateTime.tryParse(value)
      : null;
  if (date == null) return 'Chưa có';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String normalize(String value) {
  const groups = [
    'àáạảãâầấậẩẫăằắặẳẵ',
    'èéẹẻẽêềếệểễ',
    'ìíịỉĩ',
    'òóọỏõôồốộổỗơờớợởỡ',
    'ùúụủũưừứựửữ',
    'ỳýỵỷỹ',
    'đ',
  ];
  const replacements = ['a', 'e', 'i', 'o', 'u', 'y', 'd'];
  var result = value.toLowerCase().trim();
  for (var i = 0; i < groups.length; i++) {
    for (final character in groups[i].split('')) {
      result = result.replaceAll(character, replacements[i]);
    }
  }
  return result;
}

class TaiKhoan {
  final String uid;
  final Map<String, dynamic> data;
  final Map<String, dynamic>? professional;
  final Map<String, dynamic>? volunteer;
  final Map<String, dynamic> restrictions;
  const TaiKhoan(
    this.uid,
    this.data,
    this.professional,
    this.volunteer, {
    this.restrictions = const {},
  });
  String get name => textOf(data, 'hoTen', 'Chưa có họ tên');
  String get phone => textOf(data, 'soDienThoai');
  String get role => textOf(data, 'maVaiTro');
  // NguoiDung/admin is the chat-only identity; Admin accounts live in Admin/.
  // Legacy admin-role records also do not belong to account management.
  bool get isManageableAccount {
    final normalizedRole = role.trim().toLowerCase();
    return uid.trim().toLowerCase() != 'admin' &&
        normalizedRole != 'vaitro_admin' &&
        normalizedRole != 'admin';
  }

  String get status => locked ? 'khoa' : 'hoat_dong';
  bool get locked => restrictions['khoa'] == true;
  bool get suspended => restrictions['tamNgungHoTro'] == true;
  bool get approved => [
    professional,
    volunteer,
  ].any((p) => normalizeProfileStatus(p?['maTrangThaiHoSo']) == 'da_duyet');
  bool get canSupport => !locked && !suspended;
  int get version => (restrictions['phienBan'] as num?)?.toInt() ?? 0;
  String get statusLabel => locked ? 'Bị khóa' : 'Hoạt động';
  bool matches(String query) => normalize(
    '$name $phone $uid ${textOf(data, 'email')}',
  ).contains(normalize(query));
}
