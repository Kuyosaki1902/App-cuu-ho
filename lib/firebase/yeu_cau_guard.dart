import 'package:cloud_firestore/cloud_firestore.dart';

/// Kiểm tra người dùng có đang có yêu cầu cứu hộ còn khả dụng hay không.
///
/// Quy tắc: chỉ khi `maTinhTrangYeuCau` nằm trong [trangThaiChoPhepTaoMoi]
/// thì yêu cầu đó mới được coi là "đã kết thúc" và cho tạo yêu cầu mới.
/// Mọi trạng thái khác => yêu cầu còn khả dụng => chặn.
class YeuCauGuard {
  /// Các trạng thái cho phép người dùng tạo yêu cầu mới.
  /// Hiện tại theo yêu cầu: chỉ "đã hủy".
  /// (Cân nhắc thêm 'user_tinhtrang_hoanthanh' và
  /// 'user_tinhtrang_quahandieuphoi' - xem ghi chú bên dưới.)
  static const Set<String> trangThaiChoPhepTaoMoi = {
    'user_tinhtrang_dahuy',
    'user_tinhtrang_hoanthanh',
    // 'user_tinhtrang_quahandieuphoi',
  };

  static const String _collection = 'YeuCauCuuHo';

  /// Dùng cho cả snapshot realtime lẫn get(): true nếu có ít nhất 1 yêu cầu
  /// của người dùng chưa kết thúc.
  static bool coYeuCauDangHoatDong(QuerySnapshot<Map<String, dynamic>> snap) {
    for (final doc in snap.docs) {
      final String? st = doc.data()['maTinhTrangYeuCau'] as String?;
      // Bỏ qua doc rỗng/chưa có trạng thái để tránh khóa nhầm vĩnh viễn.
      if (st == null || st.isEmpty) continue;
      if (!trangThaiChoPhepTaoMoi.contains(st)) return true;
    }
    return false;
  }

  /// Stream realtime: tự động false -> true -> false khi trạng thái đổi.
  static Stream<bool> theoDoi(String maNguoiDung) {
    return FirebaseFirestore.instance
        .collection(_collection)
        .where('maNguoiYeuCau', isEqualTo: maNguoiDung)
        .snapshots()
        .map(coYeuCauDangHoatDong);
  }

  /// Kiểm tra 1 lần, lấy thẳng từ server (chống trường hợp cache cũ / bấm nhanh).
  /// Nếu lỗi mạng thì trả về true (chặn) để an toàn.
  static Future<bool> kiemTraTuServer(String maNguoiDung) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_collection)
          .where('maNguoiYeuCau', isEqualTo: maNguoiDung)
          .get(const GetOptions(source: Source.server));
      return coYeuCauDangHoatDong(snap);
    } catch (_) {
      return true;
    }
  }
}