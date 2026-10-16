import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVCoCCHN/models/ho_so_cuu_ho_co_cchn_model.dart';
import 'package:flutter/foundation.dart';

class HoSoCuuHoService {
  // 🟢 Tương tác trực tiếp với Firestore Collection không cần dùng URL
  final CollectionReference _collectionRef = FirebaseFirestore.instance
      .collection('HoSoCuuHoCoCCHN');

  /// Lưu/Cập nhật hồ sơ Cứu hộ viên lên Cloud Firestore
  /// Firestore sẽ TỰ ĐỘNG TẠO collection 'HoSoCuuHoCoCCHN' nếu chưa có trong Database!
  Future<bool> saveHoSoCuuHo(HoSoCuuHoCoCCHNModel hoSo) async {
    try {
      // Dùng doc(maNguoiDung) làm ID của Document
      await _collectionRef
          .doc(hoSo.maNguoiDung)
          .set(
            hoSo.toMap(),
            SetOptions(merge: true), // Merge dữ liệu nếu document đã tồn tại
          );
      debugPrint(
        'Đã lưu hồ sơ Firestore thành công cho mã: ${hoSo.maNguoiDung}',
      );
      return true;
    } catch (e) {
      debugPrint('Lỗi lưu Firestore: $e');
      return false;
    }
  }

  /// Đọc thông tin hồ sơ từ Cloud Firestore theo maNguoiDung
  Future<HoSoCuuHoCoCCHNModel?> getHoSoByUserId(String maNguoiDung) async {
    try {
      final DocumentSnapshot doc = await _collectionRef.doc(maNguoiDung).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return HoSoCuuHoCoCCHNModel.fromMap(data);
      }
    } catch (e) {
      debugPrint('🔴 Lỗi đọc dữ liệu Firestore: $e');
    }
    return null;
  }
}
