import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/NguoiCuuHo/LuuAnh/luu_anh_model.dart';
import 'package:flutter/foundation.dart';

class LuuAnhService {
  final CollectionReference _luuAnhRef = FirebaseFirestore.instance.collection(
    'LuuAnh',
  );

  /// 1. Chuyển đổi File ảnh thành chuỗi Base64 (Kèm header data:image/jpeg;base64,)
  Future<String?> convertFileToBase64(File imageFile) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64String = base64Encode(imageBytes);

      // Thêm tiền tố định dạng hình ảnh Base64 tiêu chuẩn
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      debugPrint('🔴 Lỗi chuyển đổi ảnh sang Base64: $e');
      return null;
    }
  }

  /// 2. Tạo record và lưu chuỗi Base64 vào collection LuuAnh trên Firestore
  Future<bool> saveLuuAnh({
    required String maNguoiDung,
    required String? base64Image,
    required String maPhanLoaiAnh, // 'THE_CONG_TAC'
    String? maMoTa,
  }) async {
    try {
      // Tự động sinh Primary Key maAnh
      String maAnh = _luuAnhRef.doc().id;

      LuuAnhModel luuAnh = LuuAnhModel(
        maAnh: maAnh,
        anhURL: base64Image, // Lưu chuỗi Base64 trực tiếp
        maNguoiDung: maNguoiDung,
        maPhanLoaiAnh: maPhanLoaiAnh,
        maMoTa: maMoTa,
      );

      await _luuAnhRef.doc(maAnh).set(luuAnh.toMap());
      debugPrint('🟢 Đã lưu chuỗi Base64 vào collection LuuAnh thành công!');
      return true;
    } catch (e) {
      debugPrint('🔴 Lỗi lưu vào collection LuuAnh: $e');
      return false;
    }
  }
}
