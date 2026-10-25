import 'package:flutter/material.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'ThongTinTaiKhoan.dart'; 

class MenuNguoiDung extends StatefulWidget {
  final String maNguoiDung; 
  
  const MenuNguoiDung({super.key, required this.maNguoiDung});

  @override
  State<MenuNguoiDung> createState() => _MenuNguoiDungState();
}

class _MenuNguoiDungState extends State<MenuNguoiDung> {
  bool _isExpanded = false;
  final FirebaseService _firebaseService = FirebaseService();
  late Stream<NguoiDungModel?> _userStream;

  @override
  void initState() {
    super.initState();
    _userStream = _firebaseService.layThongTinNguoiDungRealTime(widget.maNguoiDung);
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "ND";
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  String _maskPhoneNumber(String phone) {
    if (phone.length < 6) return phone;
    return '${phone.substring(0, 4)} ••• ${phone.substring(phone.length - 3)}';
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
            String tenHienThi = user?.hoTen.isNotEmpty == true ? user!.hoTen : "Người dùng";
            String sdtHienThi = user?.soDienThoai.isNotEmpty == true ? _maskPhoneNumber(user!.soDienThoai) : "Chưa cập nhật SĐT";
            String avatarInitials = _getInitials(tenHienThi);

            // Kiểm tra trạng thái vai trò hiện tại từ Firebase
            bool isCuuHo = user?.maVaiTro == 'vaitro_cuuhococc';

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
                        // Header: CẤP CỨU 24/7 & Nút đóng
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

                        // Profile User
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
                                    MaterialPageRoute(builder: (context) => ThongTinTaiKhoan(nguoiDung: user)),
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
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: const Color(0xFF00695C),
                                          child: Text(
                                            avatarInitials,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
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

                        // Đăng ký người cứu hộ
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFB2DFDB)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF004D40),
                                  borderRadius: BorderRadius.vertical(
                                    top: const Radius.circular(14),
                                    bottom: Radius.circular(_isExpanded ? 0 : 14),
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _isExpanded = !_isExpanded;
                                      });
                                    },
                                    borderRadius: BorderRadius.vertical(
                                      top: const Radius.circular(14),
                                      bottom: Radius.circular(_isExpanded ? 0 : 14),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.favorite,
                                            color: Colors.white70,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Text(
                                              "Đăng ký người cứu hộ",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            _isExpanded
                                                ? Icons.keyboard_arrow_up
                                                : Icons.keyboard_arrow_down,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedCrossFade(
                                firstChild: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildHorizontalButton(
                                          icon: Icons.verified_user_outlined,
                                          title: "Người có\nchuyên môn",
                                          tag: "Chứng chỉ",
                                          primaryColor: const Color(0xFF00695C),
                                          bgColor: const Color(0xFFE0F2F1),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildHorizontalButton(
                                          icon: Icons.medical_services_outlined,
                                          title: "Người thiếu\nchuyên môn",
                                          tag: "Cộng đồng",
                                          primaryColor: const Color(0xFF2E7D32),
                                          bgColor: const Color(0xFFE8F5E9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                secondChild: const SizedBox(
                                  width: double.infinity,
                                  height: 0,
                                ),
                                crossFadeState: _isExpanded
                                    ? CrossFadeState.showFirst
                                    : CrossFadeState.showSecond,
                                duration: const Duration(milliseconds: 300),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Menu Items
                        _buildMenuItem(
                          icon: Icons.history,
                          title: "Lịch sử yêu cầu",
                          trailingText: "3 lượt",
                          trailingColor: const Color(0xFFE0F2F1),
                          trailingTextColor: const Color(0xFF00695C),
                        ),
                        _buildMenuItem(
                          icon: Icons.medical_services,
                          title: "Hướng dẫn sơ cứu",
                          trailingText: "OFFLINE",
                          trailingColor: const Color(0xFFFFEBEE),
                          trailingTextColor: Colors.red,
                        ),
                        _buildMenuItem(
                          icon: Icons.support_agent,
                          title: "Hỗ trợ & Trợ giúp",
                          trailingText: "Online",
                          trailingColor: const Color(0xFFE8F5E9),
                          trailingTextColor: const Color(0xFF2E7D32),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        _buildMenuItem(
                          icon: Icons.settings_outlined,
                          title: "Cài đặt ứng dụng",
                          isSimple: true,
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Panel: Chuyển đổi chế độ cứu hộ
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF004D40),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.settings,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "CHUYỂN ĐỔI SANG",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "Người hỗ trợ sơ cứu",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Nút gạt tự động đồng bộ vai trò từ Firestore
                                Switch(
                                  value: isCuuHo,
                                  onChanged: (bool val) async {
                                    String vaTroMoi = val ? 'vaitro_cuuhococc' : 'vaitro_nguoidung';
                                    await _firebaseService.capNhatVaiTro(widget.maNguoiDung, vaTroMoi);
                                  },
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: const Color(0xFF00C853),
                                ),
                              ],
                            ),
                          ],
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

  Widget _buildHorizontalButton({
    required IconData icon,
    required String title,
    required String tag,
    required Color primaryColor,
    required Color bgColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: primaryColor, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
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
  }) {
    return Padding(
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    );
  }
}