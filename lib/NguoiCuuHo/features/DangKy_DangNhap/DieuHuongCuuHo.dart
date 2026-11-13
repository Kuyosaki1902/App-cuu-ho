import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/BackgroundService/background_service.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ManHinhKiemTraDangKy/ChonLoaiCuuHoVienScreen%20.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/TrangChu_NCH.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangThaiXacThuc/models/trang_thai_ho_so.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangThaiXacThuc/trang_thai_xac_thuc_screen.dart';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'DangNhap.dart';
import 'package:cuhokhancap/firebase/presence_service.dart';

// Mã vai trò. LƯU Ý: DangNhap.dart cũ ghi 'vaitro_cuhococc' (thiếu chữ "u"),
// còn FirebaseService.chuyenSangManHinhCuuHo ghi 'vaitro_cuuhococc'.
// Ở đây dùng cách viết của FirebaseService; hãy xác nhận đúng mã app đang dùng.
const String kVaiTroCuuHoCoCCHN = 'vaitro_cuuhococc';
const String kVaiTroCuuHoKhongCCHN = 'vaitro_cuuhochuacocc';

/// Kết quả kiểm tra hồ sơ cứu hộ của một tài khoản.
class KetQuaHoSoCuuHo {
  final bool tonTai;
  final bool coCCHN;
  final TrangThaiHoSo trangThai;

  const KetQuaHoSoCuuHo({
    required this.tonTai,
    required this.coCCHN,
    required this.trangThai,
  });

  static const chuaDangKy = KetQuaHoSoCuuHo(
    tonTai: false,
    coCCHN: false,
    trangThai: TrangThaiHoSo.tiepNhan,
  );

  bool get daDuyet => tonTai && trangThai == TrangThaiHoSo.daDuyet;
}

/// Một chỗ duy nhất quyết định người dùng đi đâu sau khi đăng nhập:
///   chưa có hồ sơ  -> màn chọn loại cứu hộ viên -> form -> màn trạng thái
///   có hồ sơ, chưa duyệt -> màn trạng thái
///   hồ sơ đã duyệt -> trang chủ
/// Màn khởi động / tự đăng nhập (ghi nhớ đăng nhập) cũng nên gọi các hàm này.
class DieuHuongCuuHo {
  /// TODO: gắn form đăng ký CÓ CCHN của bạn, ví dụ:
  /// (ctx, userId, fullName) => FormCoCCHN(currentUserId: userId, userFullName: fullName)
  static final FormDangKyBuilder? formCoCCHN = null;

  /// Đọc hồ sơ trong 2 bảng. Có lỗi mạng thì ném ngoại lệ (KHÔNG coi là "chưa
  /// đăng ký", vì sẽ cho người đã có hồ sơ đăng ký đè lên).
  static Future<KetQuaHoSoCuuHo> kiemTraHoSo(String userId) async {
    final db = FirebaseFirestore.instance;
    final cc = await db.collection('HoSoCuuHoCoCCHN').doc(userId).get();
    final kc = await db.collection('HoSoCuuHoKhongCCHN').doc(userId).get();

    KetQuaHoSoCuuHo tu(DocumentSnapshot<Map<String, dynamic>> d, bool coCCHN) {
      return KetQuaHoSoCuuHo(
        tonTai: true,
        coCCHN: coCCHN,
        trangThai: trangThaiTuMa(d.data()?['maTrangThaiHoSo']?.toString()),
      );
    }

    if (!cc.exists && !kc.exists) return KetQuaHoSoCuuHo.chuaDangKy;
    if (cc.exists && !kc.exists) return tu(cc, true);
    if (!cc.exists && kc.exists) return tu(kc, false);

    // Có cả hai (từng đổi loại hồ sơ): ưu tiên hồ sơ đã duyệt, rồi hồ sơ nộp gần nhất.
    final a = tu(cc, true);
    final b = tu(kc, false);
    if (a.daDuyet) return a;
    if (b.daDuyet) return b;
    final ta = _thoiGian(cc.data());
    final tb = _thoiGian(kc.data());
    if (ta != null && tb != null) return tb.isAfter(ta) ? b : a;
    return a;
  }

  static DateTime? _thoiGian(Map<String, dynamic>? d) {
    final v = d?['thoiGianNop'] ?? d?['thoiGianOnline'];
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  /// Họ tên hiển thị / điền sẵn vào form. Đoán các tên trường thường gặp,
  /// hãy chỉnh lại theo đúng trường trong bảng NguoiDung của bạn.
  static Future<String> layHoTen(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('NguoiDung')
          .doc(userId)
          .get();
      final d = doc.data();
      if (d == null) return '';
      for (final k in const ['hoTen', 'hoVaTen', 'tenNguoiDung', 'ten']) {
        final v = (d[k] ?? '').toString().trim();
        if (v.isNotEmpty) return v;
      }
    } catch (_) {}
    return '';
  }

  /// Chỉ đặt vai trò cứu hộ khi hồ sơ ĐÃ DUYỆT (trước đây có hồ sơ là được).
  static Future<void> datVaiTro(String userId, bool coCCHN) async {
    try {
      await FirebaseService().capNhatVaiTro(
        userId,
        coCCHN ? kVaiTroCuuHoCoCCHN : kVaiTroCuuHoKhongCCHN,
      );
    } catch (e) {
      debugPrint('Không đặt được vai trò: $e');
    }
  }

  static Future<void> dangXuat(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('maNguoiDung_daLuu');
      await PresenceService().stop();
      EmergencyNotificationService().stopListening();
    } catch (_) {}
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DangNhap()),
      (route) => false,
    );
  }

  /// Điều hướng theo kết quả kiểm tra hồ sơ.
  static Future<void> diTiep(
    BuildContext context, {
    required String userId,
    required KetQuaHoSoCuuHo ketQua,
    required String maThietBi,
  }) async {
    if (!ketQua.tonTai) {
      final ten = await layHoTen(userId);
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (ctx) => ChonLoaiCuuHoVienScreen(
            userId: userId,
            fullName: ten,
            onDangXuat: () => dangXuat(ctx),
          ),
        ),
        (route) => false,
      );
      return;
    }

    if (ketQua.daDuyet) {
      await datVaiTro(userId, ketQua.coCCHN);
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => Trangchunguoicuuho(currentUserId: userId),
        ),
        (route) => false,
      );
      return;
    }

    // Đã nộp hồ sơ nhưng chưa được duyệt (chờ, cần bổ sung, từ chối, tạm khóa...)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TrangThaiXacThucScreen(userId: userId, isCoCCHN: ketQua.coCCHN),
      ),
      (route) => false,
    );
  }
}
