import 'package:cuhokhancap/user/Design/anh_dai_dien_widget.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // THÊM THƯ VIỆN NÀY
import 'package:cuhokhancap/user/chinh_sua_thong_tin.dart';
import 'DangNhap.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:cuhokhancap/user/NguoiThanCuaBan/NguoiThanCuaBan.dart';

class ThongTinTaiKhoan extends StatefulWidget {
  final NguoiDungModel nguoiDung;

  const ThongTinTaiKhoan({super.key, required this.nguoiDung});

  @override
  State<ThongTinTaiKhoan> createState() => _ThongTinTaiKhoanState();
}

class _ThongTinTaiKhoanState extends State<ThongTinTaiKhoan> {
  final FirebaseService _firebaseService = FirebaseService();
  late final Stream<NguoiDungModel?> _userStream = _firebaseService
      .layThongTinNguoiDungRealTime(widget.nguoiDung.maNguoiDung!);

  late final Stream<List<NguoiThanKhanCap>> _nguoiThanStream = _firebaseService
      .streamNguoiThanKhanCap(widget.nguoiDung.maNguoiDung!);

  @override
  void initState() {
    super.initState();
  }

  String _maskPhoneNumber(String phone) {
    if (phone.length < 6) return phone;
    return '${phone.substring(0, 4)} ••• ${phone.substring(phone.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: StreamBuilder<NguoiDungModel?>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00695C)),
            );
          }

          NguoiDungModel userRealTime = snapshot.data ?? widget.nguoiDung;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 24),
                  _buildHeader(context, userRealTime),
                  const SizedBox(height: 16),
                  _buildProfileCard(userRealTime),
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                    icon: Icons.location_on_outlined,
                    iconColor: const Color(0xFF00695C),
                    title: "Địa chỉ đón bác sĩ",
                    actionText: "Mặc định",
                  ),
                  const SizedBox(height: 12),
                  _buildAddressCard(userRealTime),
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                    icon: Icons.error,
                    iconColor: const Color(0xFFD32F2F),
                    title: "Người thân khẩn cấp (SOS)",
                    actionText: "+ Thêm",
                    onActionTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NguoiThanCuaBan(
                            userId: widget.nguoiDung.maNguoiDung!,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildEmergencyContactList(),
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                    icon: Icons.security,
                    iconColor: const Color(0xFF00695C),
                    title: "Bảo mật & Đăng nhập",
                  ),
                  const SizedBox(height: 12),
                  _buildSecurityCard(userRealTime),
                  const SizedBox(height: 32),
                  _buildLogoutButton(
                    context,
                    userRealTime.maNguoiDung!,
                  ), // TRUYỀN THÊM MÃ NGƯỜI DÙNG VÀO ĐÂY
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.black87,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, NguoiDungModel userRealTime) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF69F0AE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.contact_mail_outlined,
                color: Color(0xFF004D40),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "HỒ SƠ SỨC KHỎE ĐIỆN TỬ",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Hồ sơ & Tài khoản",
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EAF6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChinhSuaThongTin(manguoiDung: userRealTime),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_note, color: Color(0xFF283593), size: 16),
                SizedBox(width: 4),
                Text(
                  "Chỉnh sửa",
                  style: TextStyle(
                    color: Color(0xFF283593),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(NguoiDungModel userRealTime) {
    String tenHienThi = userRealTime.hoTen.isNotEmpty
        ? userRealTime.hoTen
        : "Người dùng";
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  AnhDaiDienWidget(
                    maNguoiDung: userRealTime.maNguoiDung ?? '',
                    hoTen: tenHienThi,
                    radius: 30,
                    fontSize: 22,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00695C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tenHienThi,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "Xác minh",
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _maskPhoneNumber(userRealTime.soDienThoai),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(
                          Icons.verified,
                          color: Color(0xFF00C853),
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Đã xác thực",
                          style: TextStyle(
                            color: Color(0xFF00C853),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? actionText,
    VoidCallback? onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        if (actionText != null)
          onActionTap != null
              ? TextButton(
                  onPressed: onActionTap,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: const Color(
                      0xFFE0F2F1,
                    ), // Nền xanh nhạt giúp rõ dáng nút
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    actionText,
                    style: const TextStyle(
                      color: Color(0xFF00695C),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Text(
                  actionText,
                  style: const TextStyle(
                    color: Color(0xFF00695C),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ],
    );
  }

  Widget _buildAddressCard(NguoiDungModel userRealTime) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2F1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: Color(0xFF00695C),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userRealTime.diaChi.isNotEmpty
                      ? userRealTime.diaChi
                      : "Chưa cập nhật địa chỉ",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(NguoiDungModel userRealTime) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSecurityRow(
            icon: Icons.phone_android,
            title: "Số điện thoại đăng nhập",
            value: userRealTime.soDienThoai,
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _buildSecurityRow(
            icon: Icons.lock_reset_rounded,
            title: "Đổi mật khẩu",
            value: "",
            onTap: () {
              final String maNguoiDung = widget.nguoiDung.maNguoiDung ?? '';
              if (maNguoiDung.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Không tìm thấy mã người dùng!'),
                  ),
                );
                return;
              }

              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => _FormDoiMatKhauSheet(
                  maNguoiDung: maNguoiDung,
                  firebaseService: _firebaseService,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityRow({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap, // Thêm tham số nhận sự kiện bấm
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF00695C), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              if (value.isNotEmpty) ...[
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(width: 4),
              ],
              // Chỉ hiện mũi tên khi có truyền onTap (có thể bấm được)
              if (onTap != null)
                const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyContactList() {
    return StreamBuilder<List<NguoiThanKhanCap>>(
      stream: _nguoiThanStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF00695C)),
            ),
          );
        }

        final danhSach = snapshot.data ?? [];

        if (danhSach.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              "Chưa có người thân khẩn cấp",
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          );
        }

        return Column(
          children: [
            for (int i = 0; i < danhSach.length; i++) ...[
              _buildEmergencyContactCard(danhSach[i]),
              if (i != danhSach.length - 1) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmergencyContactCard(NguoiThanKhanCap nguoiThan) {
    final ten = nguoiThan.hoTen.isNotEmpty ? nguoiThan.hoTen : "Người thân";
    final sdt = nguoiThan.soDienThoai.isNotEmpty
        ? nguoiThan.soDienThoai
        : "Chưa có số điện thoại";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          AnhDaiDienWidget(
            key: ValueKey(nguoiThan.maNguoiThan),
            maNguoiDung: nguoiThan.maNguoiThan,
            hoTen: ten,
            radius: 22,
            fontSize: 16,
            mauNen: const Color(0xFF00897B),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        ten,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    if (nguoiThan.moiQuanHe != null &&
                        nguoiThan.moiQuanHe!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF69F0AE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          nguoiThan.moiQuanHe!,
                          style: const TextStyle(
                            color: Color(0xFF004D40),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  sdt,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ĐÃ SỬA LẠI LOGIC NÚT ĐĂNG XUẤT
  Widget _buildLogoutButton(BuildContext context, String maNguoiDung) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            // 1. Cập nhật trạng thái Offline (Giới hạn tối đa 3s tránh nghẽn mạng)
            await _firebaseService
                .capNhatTrangThaiOnline(maNguoiDung, false)
                .timeout(const Duration(seconds: 3));
          } catch (_) {
            // Bỏ qua lỗi nếu hết 3s để tiếp tục luồng đăng xuất
          }

          // 2. Xóa thông tin mã người dùng đã lưu trong máy
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('maNguoiDung_daLuu');

          // 3. Chuyển hướng về màn hình Đăng Nhập
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DangNhap()),
              (Route<dynamic> route) => false,
            );
          }
        },
        icon: const Icon(Icons.logout, color: Color(0xFFD32F2F), size: 18),
        label: const Text(
          "Đăng xuất",
          style: TextStyle(
            color: Color(0xFFD32F2F),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF5F3FF),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}

class _FormDoiMatKhauSheet extends StatefulWidget {
  final String maNguoiDung;
  final FirebaseService firebaseService;

  const _FormDoiMatKhauSheet({
    required this.maNguoiDung,
    required this.firebaseService,
  });

  @override
  State<_FormDoiMatKhauSheet> createState() => _FormDoiMatKhauSheetState();
}

class _FormDoiMatKhauSheetState extends State<_FormDoiMatKhauSheet> {
  final TextEditingController _matKhauMoiController = TextEditingController();
  final TextEditingController _nhapLaiMatKhauController =
      TextEditingController();

  bool _anMatKhauMoi = true;
  bool _anNhapLai = true;
  bool _dangCapNhat = false;
  String? _thongBaoLoi;

  @override
  void dispose() {
    _matKhauMoiController.dispose();
    _nhapLaiMatKhauController.dispose();
    super.dispose();
  }

  Future<void> _xuLyCapNhat() async {
    // Hạ bàn phím trước khi xử lý để tránh kẹt giao diện
    FocusScope.of(context).unfocus();

    final String mkMoi = _matKhauMoiController.text.trim();
    final String mkNhapLai = _nhapLaiMatKhauController.text.trim();

    if (mkMoi.isEmpty || mkNhapLai.isEmpty) {
      setState(() => _thongBaoLoi = 'Vui lòng nhập đầy đủ cả 2 ô mật khẩu!');
      return;
    }

    if (mkMoi != mkNhapLai) {
      setState(() => _thongBaoLoi = 'Mật khẩu nhập lại không khớp!');
      return;
    }

    setState(() {
      _thongBaoLoi = null;
      _dangCapNhat = true;
    });

    try {
      final bool thanhCong = await widget.firebaseService.capNhatMatKhau(
        widget.maNguoiDung,
        mkMoi,
      );

      if (!mounted) return;

      if (thanhCong) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Đổi mật khẩu thành công!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _dangCapNhat = false;
          _thongBaoLoi = 'Không thể cập nhật mật khẩu, vui lòng thử lại!';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dangCapNhat = false;
        _thongBaoLoi = 'Lỗi kết nối mạng, vui lòng thử lại!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: Color(0xFF00695C),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Đổi mật khẩu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _dangCapNhat
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mật khẩu mới
            const Text(
              'Mật khẩu mới',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _matKhauMoiController,
              obscureText: _anMatKhauMoi,
              enabled: !_dangCapNhat,
              decoration: InputDecoration(
                hintText: 'Nhập mật khẩu mới',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _anMatKhauMoi
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() => _anMatKhauMoi = !_anMatKhauMoi);
                  },
                ),
                filled: true,
                fillColor: const Color(0xFFF4F6FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Nhập lại mật khẩu mới
            const Text(
              'Nhập lại mật khẩu mới',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nhapLaiMatKhauController,
              obscureText: _anNhapLai,
              enabled: !_dangCapNhat,
              decoration: InputDecoration(
                hintText: 'Nhập lại mật khẩu mới',
                prefixIcon: const Icon(Icons.check_circle_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _anNhapLai
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() => _anNhapLai = !_anNhapLai);
                  },
                ),
                filled: true,
                fillColor: const Color(0xFFF4F6FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            if (_thongBaoLoi != null) ...[
              const SizedBox(height: 12),
              Text(
                _thongBaoLoi!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _dangCapNhat ? null : _xuLyCapNhat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _dangCapNhat
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'CẬP NHẬT MẬT KHẨU',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
