import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // THÊM THƯ VIỆN NÀY
import 'package:cuhokhancap/user/chinh_sua_thong_tin.dart';
import 'DangNhap.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';
import 'package:cuhokhancap/firebase/firebase_service.dart';

class ThongTinTaiKhoan extends StatefulWidget {
  final NguoiDungModel nguoiDung;

  const ThongTinTaiKhoan({super.key, required this.nguoiDung});

  @override
  State<ThongTinTaiKhoan> createState() => _ThongTinTaiKhoanState();
}

class _ThongTinTaiKhoanState extends State<ThongTinTaiKhoan> {
  final FirebaseService _firebaseService = FirebaseService();
  late Stream<NguoiDungModel?> _userStream;

  @override
  void initState() {
    super.initState();
    _userStream = _firebaseService.layThongTinNguoiDungRealTime(widget.nguoiDung.maNguoiDung!);
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "ND";
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
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
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00695C)));
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
                  _buildSectionTitle(icon: Icons.location_on_outlined, iconColor: const Color(0xFF00695C), title: "Địa chỉ đón bác sĩ", actionText: "Mặc định"),
                  const SizedBox(height: 12),
                  _buildAddressCard(userRealTime),
                  const SizedBox(height: 24),
                  _buildSectionTitle(icon: Icons.error, iconColor: const Color(0xFFD32F2F), title: "Người thân khẩn cấp (SOS)", actionText: "+ Thêm"),
                  const SizedBox(height: 12),
                  _buildEmergencyContactCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle(icon: Icons.security, iconColor: const Color(0xFF00695C), title: "Bảo mật & Đăng nhập"),
                  const SizedBox(height: 12),
                  _buildSecurityCard(userRealTime),
                  const SizedBox(height: 32),
                  _buildLogoutButton(context, userRealTime.maNguoiDung!), // TRUYỀN THÊM MÃ NGƯỜI DÙNG VÀO ĐÂY
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
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
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
            Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Color(0xFF69F0AE), shape: BoxShape.circle), child: const Icon(Icons.contact_mail_outlined, color: Color(0xFF004D40), size: 20)),
            const SizedBox(width: 12),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("HỒ SƠ SỨC KHỎE ĐIỆN TỬ", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)), Text("Hồ sơ & Tài khoản", style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w900))]),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(20)),
          child: TextButton(
            onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => ChinhSuaThongTin(manguoiDung: userRealTime))); },
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.edit_note, color: Color(0xFF283593), size: 16), SizedBox(width: 4), Text("Chỉnh sửa", style: TextStyle(color: Color(0xFF283593), fontWeight: FontWeight.bold, fontSize: 12))]),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(NguoiDungModel userRealTime) {
    String tenHienThi = userRealTime.hoTen.isNotEmpty ? userRealTime.hoTen : "Người dùng";
    String avatarInitials = _getInitials(tenHienThi);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(radius: 30, backgroundColor: const Color(0xFF00695C), child: Text(avatarInitials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22))),
                  Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFF00695C), shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 12)),
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
                        Text(tenHienThi, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: const Text("Xác minh", style: TextStyle(color: Colors.grey, fontSize: 10))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(_maskPhoneNumber(userRealTime.soDienThoai), style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Row(children: [Icon(Icons.verified, color: Color(0xFF00C853), size: 14), SizedBox(width: 4), Text("Đã xác thực", style: TextStyle(color: Color(0xFF00C853), fontSize: 12, fontWeight: FontWeight.bold))]),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required IconData icon, required Color iconColor, required String title, String? actionText}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [Icon(icon, color: iconColor, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))]),
        if (actionText != null) Text(actionText, style: const TextStyle(color: Color(0xFF00695C), fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAddressCard(NguoiDungModel userRealTime) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Color(0xFFE0F2F1), shape: BoxShape.circle), child: const Icon(Icons.location_on_outlined, color: Color(0xFF00695C), size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(userRealTime.diaChi.isNotEmpty ? userRealTime.diaChi : "Chưa cập nhật địa chỉ", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))])),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: const BoxDecoration(color: Color(0xFF00897B), shape: BoxShape.circle), child: const Center(child: Text("VH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [const Text("Nguyễn Văn Hùng", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF69F0AE), borderRadius: BorderRadius.circular(4)), child: const Text("Chồng", style: TextStyle(color: Color(0xFF004D40), fontSize: 10, fontWeight: FontWeight.bold)))]),
                const SizedBox(height: 4),
                const Text("0903 123 456", style: TextStyle(fontSize: 12, color: Colors.black54)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildSecurityRow(icon: Icons.phone_android, title: "Số điện thoại đăng nhập", value: userRealTime.soDienThoai),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _buildSecurityRow(icon: Icons.history, title: "Đổi mật khẩu", value: ""),
        ],
      ),
    );
  }

  Widget _buildSecurityRow({required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00695C), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
          Text(value, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
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
            await _firebaseService.capNhatTrangThaiOnline(maNguoiDung, false).timeout(const Duration(seconds: 3));
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
        label: const Text("Đăng xuất", style: TextStyle(color: Color(0xFFD32F2F), fontSize: 14, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF5F3FF),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }
}