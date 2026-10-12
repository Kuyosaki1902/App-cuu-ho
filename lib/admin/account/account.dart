import 'package:cloud_firestore/cloud_firestore.dart';

enum TrangThaiHoSo { cho_duyet, da_duyet, tu_choi, khoa }

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

class Account {
  final String uid;
  final Map<String, dynamic> data;
  final Map<String, dynamic>? professional;
  final Map<String, dynamic>? volunteer;
  const Account(this.uid, this.data, this.professional, this.volunteer);
  String get name => textOf(data, 'hoTen', 'Chưa có họ tên');
  String get phone => textOf(data, 'soDienThoai');
  String get role => textOf(data, 'maVaiTro');
  String get status => textOf(data, 'trangThaiTaiKhoan', 'chua_di_tru');
  bool get locked => status == 'khoa';
  bool get suspended => data['tamNgungHoTro'] == true;
  bool get approved =>
      [professional, volunteer].any((p) => p?['maTrangThaiHoSo'] == 'da_duyet');
  Map<String, dynamic> get sync => data['dongBoAuth'] is Map
      ? Map<String, dynamic>.from(data['dongBoAuth'] as Map)
      : {};
  bool get syncBlocked => ['running', 'failed'].contains(sync['status']);
  bool get canSupport =>
      approved && status == 'hoat_dong' && !suspended && !syncBlocked;
  int get version => (data['phienBanQuanTri'] as num?)?.toInt() ?? 0;
  String get statusLabel => locked
      ? 'Bị khóa'
      : status == 'hoat_dong'
      ? 'Hoạt động'
      : 'Chưa di trú';
  bool matches(String query) =>
      normalize('$name $phone $uid ${textOf(data, 'email')}')
          .contains(normalize(query));
}
