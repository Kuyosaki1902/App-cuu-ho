// lib/user/GiaoDienDangTimKiem/service/yeu_cau_storage_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class YeuCauStorageService {
  static const String _keyActiveMaYeuCau = 'active_ma_yeu_cau';
  static const String _keyElapsedSeconds =
      'active_elapsed_seconds'; // 🌟 Khóa lưu thời gian

  // Gọi khi vừa bấm nút tạo đơn / tìm kiếm
  static Future<void> saveActiveRequest(String maYeuCau) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveMaYeuCau, maYeuCau);

    debugPrint('💾 [StorageService] Đã lưu thành công mã yêu cầu: $maYeuCau');
  }

  // Gọi ở màn hình khởi động (Splash / Home) để check
  static Future<String?> getActiveMaYeuCau() async {
    final prefs = await SharedPreferences.getInstance();
    final maYeuCau = prefs.getString(_keyActiveMaYeuCau);

    debugPrint(
      '🔍 [StorageService] Lấy mã yêu cầu đang active: ${maYeuCau ?? "Không có"}',
    );
    return maYeuCau;
  }

  // 🌟 MỚI: Lưu thời gian quét (giây) theo mã yêu cầu
  static Future<void> saveElapsedSeconds(String maYeuCau, int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    // Chỉ lưu nếu mã yêu cầu khớp với mã đang active
    final currentMa = prefs.getString(_keyActiveMaYeuCau);
    if (currentMa == maYeuCau) {
      await prefs.setInt(_keyElapsedSeconds, seconds);
    }
  }

  // 🌟 MỚI: Lấy thời gian quét đã trôi qua
  static Future<int?> getElapsedSeconds(String maYeuCau) async {
    final prefs = await SharedPreferences.getInstance();
    final currentMa = prefs.getString(_keyActiveMaYeuCau);
    if (currentMa == maYeuCau) {
      final secs = prefs.getInt(_keyElapsedSeconds);
      debugPrint(
        '⏱️ [StorageService] Đã khôi phục bộ đếm thời gian: ${secs ?? 0} giây',
      );
      return secs;
    }
    return 0;
  }

  // Gọi khi đã hoàn thành chuyến đi hoặc khi người dùng chủ động Hủy đơn
  static Future<void> clearActiveRequest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActiveMaYeuCau);
    await prefs.remove(_keyElapsedSeconds); // Xóa sạch bộ đếm thời gian

    debugPrint(
      '🗑️ [StorageService] Đã xóa sạch mã yêu cầu và thời gian khỏi bộ nhớ!',
    );
  }
}
