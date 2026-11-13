import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/XepHang/models/xep_hang_model.dart';

class XepHangService {
  XepHangService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

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

  static String nhanKy(KyXepHang ky, [DateTime? luc]) {
    final d = luc ?? DateTime.now();
    final t = _tuanIso(d);
    switch (ky) {
      case KyXepHang.tuan:
        return 'Tuần ${t[1]}/${t[0]}';
      case KyXepHang.thang:
        return 'Tháng ${d.month}/${d.year}';
      case KyXepHang.tatCa:
        return 'Từ trước đến nay';
    }
  }

  CollectionReference<Map<String, dynamic>> _nguon(KyXepHang ky) {
    final now = DateTime.now();
    switch (ky) {
      case KyXepHang.tuan:
        return _db
            .collection('XepHangKy')
            .doc(maTuan(now))
            .collection('ThanhVien');
      case KyXepHang.thang:
        return _db
            .collection('XepHangKy')
            .doc(maThang(now))
            .collection('ThanhVien');
      case KyXepHang.tatCa:
        return _db.collection('ThanhTichCuuHo');
    }
  }

  String _truongSapXep(KyXepHang ky) =>
      ky == KyXepHang.tatCa ? 'diem' : 'soCaHoanThanh';

  Future<List<XepHangItem>> layBangXepHang(
    KyXepHang ky, {
    int gioiHan = 50,
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
