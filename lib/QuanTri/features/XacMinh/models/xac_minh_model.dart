import 'package:cloud_firestore/cloud_firestore.dart';

import '../../TaiKhoan/models/tai_khoan_model.dart';
import '../../../models/ban_ghi.dart';

const profileCollections = ['HoSoCuuHoCoCCHN', 'HoSoCuuHoKhongCCHN'];
const verificationStatuses = {
  'cho_duyet': 'Chờ duyệt',
  'can_bo_sung': 'Cần bổ sung',
  'da_duyet': 'Đã duyệt',
  'tu_choi': 'Từ chối',
  'khoa': 'Khóa',
};
const verificationTypes = {
  'HoSoCuuHoCoCCHN': 'Có CCHN',
  'HoSoCuuHoKhongCCHN': 'Không CCHN',
};

class HoSoXacMinh {
  final String uid, collection;
  final Map<String, dynamic> data, user;
  final List<BanGhi> documents;
  final bool accountExists;
  HoSoXacMinh(
    this.uid,
    this.collection,
    this.data,
    this.user,
    this.documents, {
    this.accountExists = true,
  });
  String get name => textOf(user, 'hoTen', 'Chưa có họ tên');
  String get phone => textOf(user, 'soDienThoai');
  String get code => textOf(data, 'maHoSo', uid);
  String get status => normalizeProfileStatus(data['maTrangThaiHoSo']);
  String get typeLabel => verificationTypes[collection] ?? 'Chưa xác định';
  int get version => (data['phienBanXacMinh'] as num?)?.toInt() ?? 0;
  Object? get submittedValue =>
      data['thoiGianNop'] ?? data['ngayNop'] ?? data['thoiGianOnline'];
  DateTime? get submitted => submittedValue is Timestamp
      ? (submittedValue as Timestamp).toDate()
      : DateTime.tryParse('${submittedValue ?? ''}');
  String get submittedLabel => submitted == null
      ? 'Chưa có ngày nộp'
      : 'Nộp ${dateText(submittedValue)}';
  bool get actionable =>
      accountExists && ['cho_duyet', 'can_bo_sung'].contains(status);
  bool matches(String q) =>
      normalize('$name $phone $code $uid').contains(normalize(q));
}

class ChiTietXacMinh {
  final HoSoXacMinh profile;
  final List<BanGhi> history;
  final List<String> skills;
  ChiTietXacMinh(this.profile, this.history, this.skills);
}
