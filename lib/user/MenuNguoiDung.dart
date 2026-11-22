import 'package:flutter/material.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'ThongTinTaiKhoan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'DangNhap.dart';
import 'package:cuhokhancap/user/Design/anh_dai_dien_widget.dart';
import 'package:cuhokhancap/firebase/anh_dai_dien_service.dart';
import 'package:cuhokhancap/user/LichSuCuuHo/LichSuCuuHoScreen.dart';
import 'package:cuhokhancap/user/BangXepHangCuuHo/BangXepHangCuuHo.dart';
import 'package:cuhokhancap/user/HuongDanCuuHo/HuongDanCuuHoScreen.dart';
import 'package:cuhokhancap/user/huong_dan_tai_app_screen.dart';

class MenuNguoiDung extends StatefulWidget {
  final String maNguoiDung;

  const MenuNguoiDung({super.key, required this.maNguoiDung});

  @override
  State<MenuNguoiDung> createState() => _MenuNguoiDungState();
}

class _MenuNguoiDungState extends State<MenuNguoiDung> {
  final FirebaseService _firebaseService = FirebaseService();
  late Stream<NguoiDungModel?> _userStream;

  @override
  void initState() {
    super.initState();
    _userStream = _firebaseService.layThongTinNguoiDungRealTime(
      widget.maNguoiDung,
    );
  }

  String _maskPhoneNumber(String phone) {
    if (phone.length < 6) return phone;
    return '${phone.substring(0, 4)} ••• ${phone.substring(phone.length - 3)}';
  }

  /// Tạm thời báo "đang phát triển" cho các mục chưa có màn hình.
  void _chuaCoManHinh(String ten) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tính năng "$ten" đang được phát triển')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: StreamBuilder<NguoiDungModel?>(
          stream: _userStream,
          builder: (context, snapshot) {
            NguoiDungModel? user = snapshot.data;
            String tenHienThi = user?.hoTen.isNotEmpty == true
                ? user!.hoTen
                : "Người dùng";
            String sdtHienThi = user?.soDienThoai.isNotEmpty == true
                ? _maskPhoneNumber(user!.soDienThoai)
                : "Chưa cập nhật SĐT";

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Header: CẤP CỨU 24/7 & Nút đóng
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: Color(0xFF00C853),
                                    size: 10,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "CẤP CỨU 24/7",
                                    style: TextStyle(
                                      color: Color(0xFF00695C),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.black54,
                                size: 20,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey.shade100,
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 2. Profile User
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                if (user != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ThongTinTaiKhoan(nguoiDung: user),
                                    ),
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        AnhDaiDienWidget(
                                          maNguoiDung:
                                              user?.maNguoiDung ??
                                              widget.maNguoiDung,
                                          hoTen: tenHienThi,
                                          radius: 24,
                                          fontSize: 18,
                                        ),
                                        Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          child: const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF00C853),
                                            size: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tenHienThi,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            sdtHienThi,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.grey,
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3. NÚT HƯỚNG DẪN TẢI VÀ ĐĂNG KÝ CỨU HỘ VIÊN (THIẾT KẾ MỚI)
                        _buildRescuerGuideBanner(context),
                        const SizedBox(height: 18),

                        // 4. Menu Items
                        _buildMenuItem(
                          icon: Icons.history,
                          title: "Lịch sử yêu cầu",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LichSuCuuHoScreen(
                                currentUserId: widget.maNguoiDung,
                              ),
                            ),
                          ),
                          trailingText: "3 lượt",
                          trailingColor: const Color(0xFFE0F2F1),
                          trailingTextColor: const Color(0xFF00695C),
                        ),
                        _buildMenuItem(
                          icon: Icons.medical_services,
                          title: "Hướng dẫn sơ cứu",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HuongDanCuuHoScreen(),
                            ),
                          ),
                          trailingText: "ONLINE",
                          trailingColor: const Color(0xFFFFEBEE),
                          trailingTextColor: Colors.red,
                        ),
                        _buildMenuItem(
                          icon: Icons.leaderboard,
                          title: "Bảng xếp hạng cứu hộ viên",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BangXepHangCuuHo(),
                            ),
                          ),
                          trailingText: "Mới",
                          trailingColor: const Color.fromARGB(
                            255,
                            219,
                            249,
                            86,
                          ),
                          trailingTextColor: const Color.fromARGB(
                            255,
                            107,
                            107,
                            104,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        _buildMenuItem(
                          icon: Icons.settings_outlined,
                          title: "Cài đặt ứng dụng",
                          onTap: () => _chuaCoManHinh("Cài đặt ứng dụng"),
                          isSimple: true,
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. BOTTOM PANEL: NÚT ĐĂNG XUẤT
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await _firebaseService
                                  .capNhatTrangThaiOnline(
                                    widget.maNguoiDung,
                                    false,
                                  )
                                  .timeout(const Duration(seconds: 3));
                            } catch (_) {}

                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('maNguoiDung_daLuu');

                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DangNhap(),
                                ),
                                (Route<dynamic> route) => false,
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.logout,
                            color: Color(0xFFD32F2F),
                            size: 20,
                          ),
                          label: const Text(
                            "ĐĂNG XUẤT",
                            style: TextStyle(
                              color: Color(0xFFD32F2F),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFEBEE),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Color(0xFFFFCDD2)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Phiên bản v2.4.1",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.verified_user,
                                color: Color(0xFF00695C),
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "MedVerify",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Widget nút bấm nổi bật dẫn tới 2 màn hình Hướng dẫn tải & đăng ký cứu hộ viên
  Widget _buildRescuerGuideBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00796B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HuongDanTaiAppScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng trên: Badge + Mũi tên tròn
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.amberAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.volunteer_activism_rounded,
                            color: Colors.amberAccent,
                            size: 13,
                          ),
                          SizedBox(width: 5),
                          Text(
                            "CẨM NANG CỨU HỘ 115",
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Tiêu đề chính rõ ràng theo đúng yêu cầu
                const Text(
                  "Hướng dẫn tải và đăng ký cứu hộ viên",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 5),

                // Mô tả phụ ngắn gọn
                const Text(
                  "Xem cách cài đặt app & quy trình duyệt hồ sơ chuyên môn / cộng đồng",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? trailingText,
    Color? trailingColor,
    Color? trailingTextColor,
    bool isSimple = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.black54, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSimple ? FontWeight.normal : FontWeight.w500,
                  color: isSimple ? Colors.grey.shade700 : Colors.black87,
                ),
              ),
            ),
            if (trailingText != null && trailingColor != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: trailingColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trailingText,
                  style: TextStyle(
                    color: trailingTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
