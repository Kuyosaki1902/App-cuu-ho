import 'package:flutter/foundation.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/XepHang/models/xep_hang_model.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/XepHang/services/xep_hang_service.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThanhTich/services/thanh_tich_service.dart';

class XepHangController extends ChangeNotifier {
  XepHangController(this.userId) {
    _ttService = ThanhTichService();
    _xhService = XepHangService();
  }

  final String userId;
  late final ThanhTichService _ttService;
  late final XepHangService _xhService;

  bool _disposed = false;
  int _lanTai = 0;

  KyXepHang ky = KyXepHang.tuan;
  List<XepHangItem> bangXepHang = const [];
  XepHangItem? mucCuaToi;
  XepHangItem?
  rankCaNhan; // Chứa dữ liệu xếp hạng mọi thời gian để sinh Cấp bậc
  bool dangTaiBang = false;
  String? loiBang;

  String get nhanKy => XepHangService.nhanKy(ky);
  bool get toiTrongBang =>
      mucCuaToi != null && bangXepHang.any((e) => e.maNguoiDung == userId);

  Future<void> doiKy(KyXepHang moi) async {
    if (moi == ky) return;
    ky = moi;
    bangXepHang = const [];
    mucCuaToi = null;
    await taiBangXepHang();
  }

  Future<void> taiBangXepHang() async {
    final kyHienTai = ky;
    final lan = ++_lanTai;
    dangTaiBang = true;
    loiBang = null;
    notifyListeners();

    try {
      if (kyHienTai == KyXepHang.tatCa) {
        try {
          await _ttService.dongBoTuHoSo(userId);
        } catch (e) {
          debugPrint('$e');
        }
      }

      // Load data bảng và item hiện tại
      final fBang = _xhService.layBangXepHang(kyHienTai);
      final fMuc = _xhService.layMucCuaToi(kyHienTai, userId);
      // Luôn load All-Time Rank của user để đổ vào UI _TheCapBac
      final fRank = _xhService.layMucCuaToi(KyXepHang.tatCa, userId);

      final bang = await fBang;
      final muc = await fMuc;
      final rank = await fRank;

      if (lan != _lanTai) return;
      bangXepHang = bang;
      mucCuaToi = muc;
      rankCaNhan = rank;
    } catch (e) {
      if (lan == _lanTai)
        loiBang = 'Không tải được bảng xếp hạng. Thử lại sau.';
    }

    if (lan == _lanTai) dangTaiBang = false;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
