// lib/NguoiCuuHo/LuuAnh/anh_dai_dien_service.dart
//
// Lưu ảnh đại diện theo ĐÚNG cách TrangChuController.getAvatarBase64 đang đọc:
//   1. PhanLoaiAnh có tenPhanLoaiAnh == 'Ảnh đại diện'  -> lấy id làm maPhanLoaiAnh
//   2. LuuAnh có maNguoiDung == uid && maPhanLoaiAnh == id  -> đọc 'base64Image'
// Bộ đọc đó chỉ lấy MỘT bản ghi bất kỳ (limit 1, không sắp xếp), nên mỗi người
// dùng chỉ được phép có đúng một bản ghi ảnh đại diện. Hàm lưu dưới đây cập nhật
// bản ghi sẵn có và xóa các bản ghi dư, tránh việc hiện lại ảnh cũ.
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AnhDaiDienService {
  AnhDaiDienService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String tenPhanLoai = 'Ảnh đại diện';
  static const String _maPhanLoaiMacDinh = 'anh_dai_dien';

  /// Tra mã phân loại 'Ảnh đại diện'. Chưa có và [taoNeuChuaCo] = true thì tạo.
  /// Trả về chuỗi rỗng nếu chưa có và không được phép tạo.
  Future<String> _maPhanLoai({bool taoNeuChuaCo = false}) async {
    final snap = await _db
        .collection('PhanLoaiAnh')
        .where('tenPhanLoaiAnh', isEqualTo: tenPhanLoai)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) return snap.docs.first.id;
    if (!taoNeuChuaCo) return '';

    await _db.collection('PhanLoaiAnh').doc(_maPhanLoaiMacDinh).set({
      'maPhanLoaiAnh': _maPhanLoaiMacDinh,
      'tenPhanLoaiAnh': tenPhanLoai,
    }, SetOptions(merge: true));
    return _maPhanLoaiMacDinh;
  }

  Query<Map<String, dynamic>> _truyVanAnh(
    String maNguoiDung,
    String maPhanLoai,
  ) {
    return _db
        .collection('LuuAnh')
        .where('maNguoiDung', isEqualTo: maNguoiDung)
        .where('maPhanLoaiAnh', isEqualTo: maPhanLoai);
  }

  /// Chuỗi base64 hiện tại (có thể kèm tiền tố data:image/...;base64,) hoặc null.
  Future<String?> layAnhDaiDien(String maNguoiDung) async {
    if (maNguoiDung.isEmpty) return null;
    final ma = await _maPhanLoai();
    if (ma.isEmpty) return null;

    final snap = await _truyVanAnh(maNguoiDung, ma).limit(1).get();
    if (snap.docs.isEmpty) return null;
    final d = snap.docs.first.data();
    final v =
        d['base64Image'] ?? d['duongDanAnh'] ?? d['duLieuAnh'] ?? d['anhURL'];
    final s = v?.toString();
    return (s == null || s.isEmpty) ? null : s;
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
      // Giữ đúng một bản ghi; chuyển ảnh về trường base64Image (trường mà bộ đọc
      // ưu tiên) và xóa các trường cũ để không còn dữ liệu thừa (giới hạn 1 MiB/bản ghi).
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
