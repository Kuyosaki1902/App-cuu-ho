import 'package:cuhokhancap/NguoiCuuHo/Features/DangKy_DangNhap/DieuHuongCuuHo.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVKhongCCHN/CuuHoVien_KhongCCHN.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/TrangChu_NCH.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/trang_thai_xac_thuc_controller.dart';
import 'models/trang_thai_ho_so.dart';
import 'widgets/card_canh_bao_khoa_nhan_ca.dart';
import 'widgets/card_da_gui_yeu_cau.dart';
import 'widgets/card_thoi_gian_tham_dinh.dart';
import 'widgets/card_tien_do_ho_so.dart';
import 'widgets/card_yeu_cau_bo_sung.dart';

class TrangThaiXacThucScreen extends StatefulWidget {
  final String userId;
  final bool isCoCCHN;

  /// Mở lại form để bổ sung / gửi lại hồ sơ. Nếu để trống, nhóm không CCHN dùng
  /// form mặc định; nhóm có CCHN cần truyền callback (không có thì ẩn nút).
  final VoidCallback? onBoSungHoSo;

  /// Đăng xuất (màn này là gốc sau khi đăng nhập nên không có nút Back).
  final VoidCallback? onDangXuat;

  /// Họ tên điền sẵn khi mở lại form bổ sung hồ sơ (nhóm không CCHN).
  final String userFullName;

  const TrangThaiXacThucScreen({
    super.key,
    required this.userId,
    this.isCoCCHN = false,
    this.onBoSungHoSo,
    this.onDangXuat,
    this.userFullName = '',
  });

  @override
  State<TrangThaiXacThucScreen> createState() => _TrangThaiXacThucScreenState();
}

class _TrangThaiXacThucScreenState extends State<TrangThaiXacThucScreen> {
  late final TrangThaiXacThucController _controller;
  bool _daChuyenManHinh = false; // chỉ điều hướng khi được duyệt đúng 1 lần

  @override
  void initState() {
    super.initState();
    _controller = TrangThaiXacThucController(
      userId: widget.userId,
      isCoCCHN: widget.isCoCCHN,
    );
    _controller.addListener(_onControllerChanged);
    // Xin quyền thông báo để nhận kết quả duyệt khi không mở màn này.
    // (Việc gửi push khi đổi trạng thái cần Cloud Function / FCM phía server.)
    _controller.requestNotificationPermission();
  }

  void _onControllerChanged() {
    if (_daChuyenManHinh || _controller.trangThai != TrangThaiHoSo.daDuyet)
      return;
    _daChuyenManHinh = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Chỉ khi hồ sơ đã duyệt mới cấp vai trò cứu hộ cho tài khoản.
      await DieuHuongCuuHo.datVaiTro(widget.userId, widget.isCoCCHN);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hồ sơ của bạn đã được phê duyệt!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => Trangchunguoicuuho(currentUserId: widget.userId),
        ),
        (route) => false,
      );
    });
  }

  bool get _coTheBoSung => widget.onBoSungHoSo != null || !widget.isCoCCHN;

  void _boSungHoSo() {
    if (widget.onBoSungHoSo != null) {
      widget.onBoSungHoSo!();
      return;
    }
    if (!widget.isCoCCHN) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CuuhovienKhongcchn(
            currentUserId: widget.userId,
            userFullName: widget.userFullName,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<TrangThaiXacThucController>(
        builder: (context, c, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              iconTheme: const IconThemeData(color: Colors.black87),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Trạng thái xác thực',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (c.daTaiLanDau && c.hoSoTonTai) _huyHieuTrangThai(c),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.isCoCCHN
                        ? 'Hồ sơ CCHN • 115 Responder'
                        : 'Hồ sơ không CCHN • 115 Responder',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              actions: [
                if (widget.onDangXuat != null)
                  IconButton(
                    tooltip: 'Đăng xuất',
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: widget.onDangXuat,
                  ),
                const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFC80815),
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            body: _body(c),
          );
        },
      ),
    );
  }

  Widget _huyHieuTrangThai(TrangThaiXacThucController c) {
    final t = c.trangThai;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: t.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 3, backgroundColor: t.color),
          const SizedBox(width: 4),
          Text(
            c.trangThaiText,
            style: TextStyle(
              color: t.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(TrangThaiXacThucController c) {
    // Chưa có dữ liệu lần đầu
    if (!c.daTaiLanDau) {
      if (c.loiTaiDuLieu != null) {
        return _khungThongBao(
          icon: Icons.wifi_off_rounded,
          text: c.loiTaiDuLieu!,
          nutText: 'Thử lại',
          onPressed: c.refresh,
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    // Không tìm thấy hồ sơ
    if (!c.hoSoTonTai) {
      return _khungThongBao(
        icon: Icons.search_off_rounded,
        text:
            'Chưa tìm thấy hồ sơ xác thực của bạn. Hãy gửi hồ sơ để được thẩm định.',
        nutText: _coTheBoSung ? 'Gửi hồ sơ' : null,
        onPressed: _coTheBoSung ? _boSungHoSo : null,
      );
    }

    final t = c.trangThai;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (c.loiTaiDuLieu != null) ...[
            _bannerLoi(c.loiTaiDuLieu!),
            const SizedBox(height: 12),
          ],
          CardDaGuiYeuCau(
            maHoSo: c.maHoSo,
            isCoCCHN: widget.isCoCCHN,
            trangThai: t,
            capDoUyTin: c.capDoUyTin,
          ),
          const SizedBox(height: 12),

          if (t.dangCho) ...[
            CardThoiGianThamDinh(
              thoiGianThamDinh: c.thoiGianThamDinh,
              thoiGianConLai: c.thoiGianConLai,
            ),
            const SizedBox(height: 12),
            CardCanhBaoKhoaNhanCa(isCoCCHN: widget.isCoCCHN),
            const SizedBox(height: 12),
          ],

          if (t == TrangThaiHoSo.canBoSung) ...[
            CardYeuCauBoSung(
              trangThai: t,
              tieuDe: 'Người duyệt yêu cầu bổ sung',
              lyDo: c.lyDo,
              nutText: _coTheBoSung ? 'Bổ sung hồ sơ' : null,
              onPressed: _coTheBoSung ? _boSungHoSo : null,
            ),
            const SizedBox(height: 12),
          ],

          if (t == TrangThaiHoSo.tuChoi) ...[
            CardYeuCauBoSung(
              trangThai: t,
              tieuDe: 'Lý do từ chối',
              lyDo: c.lyDo,
              nutText: _coTheBoSung ? 'Cập nhật và gửi lại hồ sơ' : null,
              onPressed: _coTheBoSung ? _boSungHoSo : null,
            ),
            const SizedBox(height: 12),
          ],

          if (t == TrangThaiHoSo.tamKhoa) ...[
            CardYeuCauBoSung(
              trangThai: t,
              tieuDe: 'Lý do tạm khóa',
              lyDo: c.lyDo,
              loiMacDinh:
                  'Tài khoản đang bị khóa tạm, có thể do có phản ánh cần xác minh. '
                  'Vui lòng liên hệ Ban điều phối 115 để được hướng dẫn và khiếu nại.',
            ),
            const SizedBox(height: 12),
          ],

          if (t == TrangThaiHoSo.khongXacDinh) ...[
            CardYeuCauBoSung(
              trangThai: t,
              tieuDe: 'Trạng thái chưa được hỗ trợ',
              lyDo: null,
              loiMacDinh:
                  'Mã trạng thái "${c.maTrangThaiRaw}" chưa được ứng dụng nhận diện. '
                  'Vui lòng cập nhật ứng dụng hoặc liên hệ Ban điều phối 115.',
            ),
            const SizedBox(height: 12),
          ],

          CardTienDoHoSo(items: c.tienDo),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              onPressed: c.isRefreshing ? null : c.refresh,
              child: c.isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Làm mới trạng thái',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _bannerLoi(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 18,
            color: Color(0xFFD97706),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _khungThongBao({
    required IconData icon,
    required String text,
    String? nutText,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            if (nutText != null && onPressed != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: Text(
                  nutText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
