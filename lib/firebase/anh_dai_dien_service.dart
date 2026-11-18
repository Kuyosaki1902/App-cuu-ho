// lib/firebase/anh_dai_dien_service.dart
//
// Lưu/đọc ảnh đại diện theo ĐÚNG cách TrangChuController.getAvatarBase64 đang đọc:
//   1. PhanLoaiAnh có tenPhanLoaiAnh == 'Ảnh đại diện'  -> lấy id làm maPhanLoaiAnh
//   2. LuuAnh có maNguoiDung == uid && maPhanLoaiAnh == id  -> đọc 'base64Image'
// Mỗi người dùng chỉ có đúng một bản ghi ảnh đại diện.
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

class AnhDaiDienService {
  AnhDaiDienService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String tenPhanLoai = 'Ảnh đại diện';
  static const String _maPhanLoaiMacDinh = 'anh_dai_dien';
  static const List<String> _truongAnh = [
    'base64Image',
    'duongDanAnh',
    'duLieuAnh',
    'anhURL',
  ];

  // Cache mã phân loại để không phải tra lại ở mỗi lần gọi.
  static String? _maPhanLoaiDaTra;

  /// Tra mã phân loại 'Ảnh đại diện'. Chưa có và [taoNeuChuaCo] = true thì tạo.
  Future<String> _maPhanLoai({bool taoNeuChuaCo = false}) async {
    if (_maPhanLoaiDaTra != null) return _maPhanLoaiDaTra!;
    final snap = await _db
        .collection('PhanLoaiAnh')
        .where('tenPhanLoaiAnh', isEqualTo: tenPhanLoai)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) return _maPhanLoaiDaTra = snap.docs.first.id;
    if (!taoNeuChuaCo) return '';

    await _db.collection('PhanLoaiAnh').doc(_maPhanLoaiMacDinh).set({
      'maPhanLoaiAnh': _maPhanLoaiMacDinh,
      'tenPhanLoaiAnh': tenPhanLoai,
    }, SetOptions(merge: true));
    return _maPhanLoaiDaTra = _maPhanLoaiMacDinh;
  }

  /// Các mã phân loại có thể chứa ảnh đại diện (theo tên + mã cứng dự phòng).
  Future<List<String>> _cacMaPhanLoai() async {
    final theoTen = await _maPhanLoai();
    return <String>{if (theoTen.isNotEmpty) theoTen, _maPhanLoaiMacDinh}
        .toList();
  }

  Query<Map<String, dynamic>> _truyVanAnh(String maNguoiDung, String maPhanLoai) {
    return _db
        .collection('LuuAnh')
        .where('maNguoiDung', isEqualTo: maNguoiDung)
        .where('maPhanLoaiAnh', isEqualTo: maPhanLoai);
  }

  /// Chuyển giá trị trường ảnh (String / Blob / Uint8List / List) về chuỗi.
  String? _thanhChuoi(Object? v) {
    if (v == null) return null;
    if (v is String) return v.trim().isEmpty ? null : v;
    if (v is Blob) return 'data:image/jpeg;base64,${base64Encode(v.bytes)}';
    if (v is Uint8List) return 'data:image/jpeg;base64,${base64Encode(v)}';
    if (v is List) {
      return 'data:image/jpeg;base64,${base64Encode(List<int>.from(v))}';
    }
    return null;
  }

  String? _docAnh(Map<String, dynamic> d) {
    for (final k in _truongAnh) {
      final s = _thanhChuoi(d[k]);
      if (s != null) return s;
    }
    return null;
  }

  /// Đọc một lần.
  Future<String?> layAnhDaiDien(String maNguoiDung) async {
    if (maNguoiDung.isEmpty) return null;
    for (final ma in await _cacMaPhanLoai()) {
      final snap = await _truyVanAnh(maNguoiDung, ma).limit(1).get();
      if (snap.docs.isEmpty) continue;
      final s = _docAnh(snap.docs.first.data());
      if (s != null) return s;
    }
    return null;
  }

  /// REALTIME: phát ra ảnh mới mỗi khi bản ghi LuuAnh của người dùng thay đổi
  /// (kể cả ngay khi chính thiết bị này vừa ghi, nhờ latency compensation).
  Stream<String?> theoDoiAnhDaiDien(String maNguoiDung) async* {
    if (maNguoiDung.isEmpty) {
      yield null;
      return;
    }
    final cacMa = await _cacMaPhanLoai();
    yield* _db
        .collection('LuuAnh')
        .where('maNguoiDung', isEqualTo: maNguoiDung)
        .where('maPhanLoaiAnh', whereIn: cacMa)
        .snapshots()
        .map((snap) {
      for (final doc in snap.docs) {
        final s = _docAnh(doc.data());
        if (s != null) return s;
      }
      return null;
    });
  }

  /// Lưu (thay thế) ảnh đại diện. [bytes] là ảnh JPEG đã được thu nhỏ.
  Future<void> luuAnhDaiDien(String maNguoiDung, Uint8List bytes) async {
    if (maNguoiDung.isEmpty) throw ArgumentError('maNguoiDung rỗng');
    final ma = await _maPhanLoai(taoNeuChuaCo: true);
    final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';

    final col = _db.collection('LuuAnh');
    final snap = await _truyVanAnh(maNguoiDung, ma).get();
    final batch = _db.batch();

    if (snap.docs.isEmpty) {
      final ref = col.doc();
      batch.set(ref, {
        'maAnh': ref.id,
        'maNguoiDung': maNguoiDung,
        'maPhanLoaiAnh': ma,
        'maMoTa': tenPhanLoai,
        'base64Image': base64Str,
        'capNhatLuc': FieldValue.serverTimestamp(),
      });
    } else {
      batch.update(snap.docs.first.reference, {
        'base64Image': base64Str,
        'duongDanAnh': FieldValue.delete(),
        'duLieuAnh': FieldValue.delete(),
        'anhURL': FieldValue.delete(),
        'capNhatLuc': FieldValue.serverTimestamp(),
      });
      for (final d in snap.docs.skip(1)) {
        batch.delete(d.reference);
      }
    }
    await batch.commit();
  }

  /// Xóa toàn bộ bản ghi ảnh đại diện của người dùng.
  Future<void> xoaAnhDaiDien(String maNguoiDung) async {
    if (maNguoiDung.isEmpty) return;
    final ma = await _maPhanLoai();
    if (ma.isEmpty) return;

    final snap = await _truyVanAnh(maNguoiDung, ma).get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }
}