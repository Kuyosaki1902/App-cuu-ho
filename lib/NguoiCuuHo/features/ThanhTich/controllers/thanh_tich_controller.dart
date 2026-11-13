import 'package:flutter/foundation.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThanhTich/services/thanh_tich_service.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThanhTich/models/thanh_tich_model.dart';

class ThanhTichController extends ChangeNotifier {
  ThanhTichController(this.userId, {ThanhTichService? service})
    : _service = service ?? ThanhTichService();

  final String userId;
  final ThanhTichService _service;
  bool _disposed = false;
  bool _dangChay = false;

  ThanhTichModel? thanhTich;
  bool dangTai = true;
  String? loi;

  Future<void> taiTatCa() async {
    if (_dangChay) return;
    _dangChay = true;
    dangTai = true;
    loi = null;
    _thongBao();
    try {
      thanhTich = await _service.dongBoTuHoSo(userId);
    } catch (e) {
      debugPrint('ThanhTich: lỗi tải thành tích: $e');
      loi = 'Không tải được thành tích. Kiểm tra kết nối và thử lại.';
    }
    dangTai = false;
    _dangChay = false;
    _thongBao();
  }

  void _thongBao() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
