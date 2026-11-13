import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/thanh_tich_model.dart';

class ThanhTichService {
  ThanhTichService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  static const String _vaiTroCoCCHN = 'vaitro_cuuhococc';

  static List<int> _tuanIso(DateTime d) {
    final ngay = DateTime.utc(d.year, d.month, d.day);
    final thuNam = ngay.add(Duration(days: 4 - ngay.weekday));
    final dauNam = DateTime.utc(thuNam.year, 1, 1);
    final tuan = (thuNam.difference(dauNam).inDays ~/ 7) + 1;
    return [thuNam.year, tuan];
  }

  static String maTuan(DateTime d) {
    final t = _tuanIso(d);
    return 'tuan_${t[0]}-W${t[1].toString().padLeft(2, '0')}';
  }

  static String maThang(DateTime d) =>
      'thang_${d.year}-${d.month.toString().padLeft(2, '0')}';

  static String rutGonTen(String hoTen) {
    final tu = hoTen
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (tu.isEmpty) return 'Cứu hộ viên';
    if (tu.length <= 2) return tu.join(' ');
    final giua = tu
        .sublist(1, tu.length - 1)
        .map((e) => '${e[0].toUpperCase()}.')
        .join(' ');
    return '${tu.first} $giua ${tu.last}';
  }

  Future<ThanhTichModel?> dongBoTuHoSo(String uid) async {
    if (uid.isEmpty) return null;
    final nd = await _db.collection('NguoiDung').doc(uid).get();
    if (!nd.exists) return null;
    final ndData = nd.data() ?? <String, dynamic>{};
    final coCCHN = (ndData['maVaiTro'] ?? '').toString() == _vaiTroCoCCHN;
    final ten = rutGonTen((ndData['hoTen'] ?? '').toString());

    final res = await Future.wait([
      _db.collection('HoSoCuuHoCoCCHN').doc(uid).get(),
      _db.collection('HoSoCuuHoKhongCCHN').doc(uid).get(),
    ]);

    DocumentSnapshot<Map<String, dynamic>>? hs;
    var loai = 'khongcchn';
    if (coCCHN && res[0].exists) {
      hs = res[0];
      loai = 'cchn';
    } else if (res[1].exists) {
      hs = res[1];
      loai = 'khongcchn';
    } else if (res[0].exists) {
      hs = res[0];
      loai = 'cchn';
    }

    if (hs == null) return null;
    final tt = ThanhTichModel.tuHoSo(
      hs.data() ?? {},
      maNguoiDung: uid,
      tenHienThi: ten,
      loaiHoSo: loai,
    );

    try {
      await _db.collection('ThanhTichCuuHo').doc(uid).set({
        ...tt.toMap(),
        'capNhatLuc': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('ThanhTich: không ghi được ThanhTichCuuHo: $e');
    }
    return tt;
  }

  Future<bool> ghiNhanCaHoanThanh(String uid, String maYeuCau) async {
    if (uid.isEmpty || maYeuCau.isEmpty) return false;
    try {
      final tt = await dongBoTuHoSo(uid);
      final ten = tt?.tenHienThi ?? 'Cứu hộ viên';
      final loai = tt?.loaiHoSo ?? 'khongcchn';
      final bay = DateTime.now();

      final marker = _db.collection('ThanhTichCa').doc('${uid}_$maYeuCau');
      final tuanRef = _db
          .collection('XepHangKy')
          .doc(maTuan(bay))
          .collection('ThanhVien')
          .doc(uid);
      final thangRef = _db
          .collection('XepHangKy')
          .doc(maThang(bay))
          .collection('ThanhVien')
          .doc(uid);

      return await _db.runTransaction<bool>((tx) async {
        final daCo = await tx.get(marker);
        if (daCo.exists) return false;

        tx.set(marker, {
          'maNguoiDung': uid,
          'maYeuCau': maYeuCau,
          'luc': FieldValue.serverTimestamp(),
        });
        final chung = {
          'maNguoiDung': uid,
          'tenHienThi': ten,
          'loaiHoSo': loai,
          'soCaHoanThanh': FieldValue.increment(1),
          'capNhatLuc': FieldValue.serverTimestamp(),
        };
        tx.set(tuanRef, chung, SetOptions(merge: true));
        tx.set(thangRef, chung, SetOptions(merge: true));
        return true;
      });
    } catch (e) {
      return false;
    }
  }
}
