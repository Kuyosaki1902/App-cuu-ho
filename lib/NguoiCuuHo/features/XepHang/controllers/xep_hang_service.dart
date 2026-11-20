import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThanhTich/widgets/ma_ky.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/XepHang/models/xep_hang_model.dart';

class XepHangService {
  XepHangService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  static String nhanKy(KyXepHang ky, [DateTime? luc]) {
    final d = luc ?? DateTime.now();
    switch (ky) {
      case KyXepHang.tuan:
        final t = MaKy.tuanIso(d);
        return 'Tuần ${t[1]}/${t[0]}';
      case KyXepHang.thang:
        return 'Tháng ${MaKy.soThang(d)}/${MaKy.namCuaThang(d)}';
      case KyXepHang.tatCa:
        return 'Từ trước đến nay';
    }
  }

  CollectionReference<Map<String, dynamic>> _thanhVienKy(String maKy) =>
      _db.collection('XepHangKy').doc(maKy).collection('ThanhVien');

  CollectionReference<Map<String, dynamic>> _nguon(KyXepHang ky) {
    final now = DateTime.now();
    switch (ky) {
      case KyXepHang.tuan:
        return _thanhVienKy(MaKy.tuan(now));
      case KyXepHang.thang:
        return _thanhVienKy(MaKy.thang(now));
      case KyXepHang.tatCa:
        return _db.collection(
          'ThanhTichCuuHo',
        ); // bản sao công khai do Thành tích làm mới
    }
  }

  String _truongSapXep(KyXepHang ky) =>
      ky == KyXepHang.tatCa ? 'diem' : 'soCaHoanThanh';

  // ── Ghi nhận ───────────────────────────────────────────────────────
  /// Cộng 1 ca vào bảng tuần và tháng. Chống ghi trùng bằng cờ [daGhiXepHang]
  /// ngay trên bản ghi phân công của chính ca đó, nên không cần bảng `ThanhTichCa`.
  ///
  /// [phanCongRef]: `ChiTietPhanCongCuuHo/{uid}/DanhSachNgay/{ngay}/DanhSachPhanCong/{maYeuCau}`.
  /// Trả về false nếu ca này đã được ghi trước đó hoặc có lỗi.
  Future<bool> ghiNhanCaHoanThanh({
    required DocumentReference<Map<String, dynamic>> phanCongRef,
    required String uid,
    required String tenHienThi,
    required String loaiHoSo,
    DateTime? luc,
  }) async {
    if (uid.isEmpty) return false;
    final thoiDiem = luc ?? DateTime.now();
    final tuanRef = _thanhVienKy(MaKy.tuan(thoiDiem)).doc(uid);
    final thangRef = _thanhVienKy(MaKy.thang(thoiDiem)).doc(uid);

    try {
      return await _db.runTransaction<bool>((tx) async {
        final pc = await tx.get(phanCongRef);
        if (pc.data()?['daGhiXepHang'] == true) return false;

        tx.set(phanCongRef, {
          'daGhiXepHang': true,
          'thoiGianGhiXepHang': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final chung = {
          'maNguoiDung': uid,
          'tenHienThi': tenHienThi,
          'loaiHoSo': loaiHoSo,
          'soCaHoanThanh': FieldValue.increment(1),
          'capNhatLuc': FieldValue.serverTimestamp(),
        };
        tx.set(tuanRef, chung, SetOptions(merge: true));
        tx.set(thangRef, chung, SetOptions(merge: true));
        return true;
      });
    } catch (e) {
      // Không nuốt lỗi im lặng như bản cũ: caller cần biết để thử lại.
      debugPrint('XepHang: không ghi được xếp hạng kỳ: $e');
      return false;
    }
  }

  // ── Đọc ────────────────────────────────────────────────────────────
  Future<List<XepHangItem>> layBangXepHang(
    KyXepHang ky, {
    int gioiHan = 10,
  }) async {
    final snap = await _nguon(
      ky,
    ).orderBy(_truongSapXep(ky), descending: true).limit(gioiHan).get();
    final ds = snap.docs
        .map(
          (d) => XepHangItem.fromMap(
            d.data(),
            d.id,
            theoKy: ky != KyXepHang.tatCa,
          ),
        )
        .toList();

    ds.sort((a, b) {
      final c = b.diem.compareTo(a.diem);
      if (c != 0) return c;
      final c2 = b.soCaHoanThanh.compareTo(a.soCaHoanThanh);
      return c2 != 0 ? c2 : a.tenHienThi.compareTo(b.tenHienThi);
    });

    for (var i = 0; i < ds.length; i++) {
      ds[i].hang = (i > 0 && ds[i].diem == ds[i - 1].diem)
          ? ds[i - 1].hang
          : i + 1;
    }
    return ds;
  }

  Future<XepHangItem?> layMucCuaToi(KyXepHang ky, String uid) async {
    if (uid.isEmpty) return null;
    final d = await _nguon(ky).doc(uid).get();
    final data = d.data();
    if (!d.exists || data == null) return null;

    final item = XepHangItem.fromMap(data, d.id, theoKy: ky != KyXepHang.tatCa);
    final truong = _truongSapXep(ky);
    final giaTri = ky == KyXepHang.tatCa ? item.diem : item.soCaHoanThanh;

    final dem = await _nguon(
      ky,
    ).where(truong, isGreaterThan: giaTri).count().get();
    item.hang = (dem.count ?? 0) + 1;
    return item;
  }
}
