import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThanhTich/models/thanh_tich_model.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThanhTich/widgets/thong_tin_cuu_ho.dart';

/// Thành tích cá nhân. Nguồn sự thật = hồ sơ cứu hộ (HoSoCuuHoCoCCHN / HoSoCuuHoKhongCCHN).
///
/// Dịch vụ này KHÔNG biết gì về xếp hạng theo kỳ và không ghi marker chống trùng
/// (bảng `ThanhTichCa` đã bỏ). `ThanhTichCuuHo` chỉ là bản sao công khai, chỉ-đọc
/// để bảng xếp hạng "Từ trước đến nay" sắp xếp theo điểm; được làm mới bằng [dongBoTuHoSo].
class ThanhTichService {
  ThanhTichService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  /// Đọc hồ sơ, tính điểm, rồi làm mới bản sao công khai. Trả về null nếu chưa có hồ sơ.
  Future<ThanhTichModel?> dongBoTuHoSo(String uid) async {
    if (uid.isEmpty) return null;
    final nd = await _db.collection('NguoiDung').doc(uid).get();
    if (!nd.exists) return null;
    final ndData = nd.data() ?? <String, dynamic>{};
    final maVaiTro = (ndData['maVaiTro'] ?? '').toString();
    final coCCHN = maVaiTro == vaiTroCoCCHN;
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
    } else if (res[0].exists) {
      hs = res[0];
      loai = 'cchn';
    }
    if (hs == null) return null;

    // 1. Gọi lấy thống kê đánh giá từ Firestore
    final danhGia = await ThanhTichModel.layThongKeDanhGia(uid);

    // 2. Truyền vào tuHoSo
    final tt = ThanhTichModel.tuHoSo(
      hs.data() ?? {},
      maNguoiDung: uid,
      tenHienThi: ten,
      loaiHoSo: loai,
      saoTrungBinh: danhGia.saoTrungBinh,
      soLuotDanhGia: danhGia.soLuotDanhGia,
    );

    try {
      await _db.collection('ThanhTichCuuHo').doc(uid).set({
        ...tt.toBangXepHang(),
        'capNhatLuc': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('ThanhTich: không làm mới ThanhTichCuuHo: $e');
    }
    return tt;
  }
}
