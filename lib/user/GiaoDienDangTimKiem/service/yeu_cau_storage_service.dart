// lib/user/GiaoDienDangTimKiem/service/yeu_cau_storage_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class YeuCauStorageService {
  static const String _keyActiveMaYeuCau = 'active_ma_yeu_cau';
  static const String _keyElapsedSeconds = 'active_elapsed_seconds';
  static const String _keyManualSelectedIds = 'active_manual_selected_ids';

  // Gọi khi vừa bấm nút tạo đơn / tìm kiếm
  static Future<void> saveActiveRequest(String maYeuCau) async {
    final prefs = await SharedPreferences.getInstance();
    final oldMa = prefs.getString(_keyActiveMaYeuCau);
    // Nếu là đơn mới khác đơn cũ thì dọn sạch cache cũ trước
    if (oldMa != null && oldMa != maYeuCau) {
      await prefs.remove(_keyElapsedSeconds);
      await prefs.remove(_keyManualSelectedIds);
    }
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

  // Lưu thời gian quét (giây) theo mã yêu cầu
  static Future<void> saveElapsedSeconds(String maYeuCau, int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    final currentMa = prefs.getString(_keyActiveMaYeuCau);
    if (currentMa == maYeuCau) {
      await prefs.setInt(_keyElapsedSeconds, seconds);
    }
  }

  // Lấy thời gian quét đã trôi qua
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

  // Lưu danh sách ID cứu hộ viên do người dùng chọn thủ công lần đầu
  static Future<void> saveManualSelectedIds(
    String maYeuCau,
    List<String> ids,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final currentMa = prefs.getString(_keyActiveMaYeuCau);
    if (currentMa == maYeuCau) {
      await prefs.setStringList(_keyManualSelectedIds, ids);
      debugPrint(
        '💾 [StorageService] Đã lưu ${ids.length} cứu hộ viên chọn thủ công cho đơn $maYeuCau',
      );
    }
  }

  // Lấy lại danh sách ID cứu hộ viên đã chọn thủ công
  static Future<List<String>> getManualSelectedIds(String maYeuCau) async {
    final prefs = await SharedPreferences.getInstance();
    final currentMa = prefs.getString(_keyActiveMaYeuCau);
    if (currentMa == maYeuCau) {
      final ids = prefs.getStringList(_keyManualSelectedIds) ?? [];
      debugPrint(
        '🔄 [StorageService] Khôi phục ${ids.length} cứu hộ viên chọn thủ công',
      );
      return ids;
    }
    return [];
  }

  // Gọi khi đã hoàn thành chuyến đi hoặc khi người dùng chủ động Hủy đơn
  static Future<void> clearActiveRequest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActiveMaYeuCau);
    await prefs.remove(_keyElapsedSeconds);
    await prefs.remove(_keyManualSelectedIds);

    debugPrint(
      '🗑️ [StorageService] Đã xóa sạch mã yêu cầu, thời gian và danh sách chỉ định khỏi bộ nhớ!',
    );
  }
}
