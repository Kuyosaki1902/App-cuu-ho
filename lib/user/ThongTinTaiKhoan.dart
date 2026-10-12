import 'package:flutter/material.dart';
import 'DangNhap.dart';

class ThongTinTaiKhoan extends StatelessWidget {
  const ThongTinTaiKhoan({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB), // Màu nền tổng thể sáng (hơi xanh tím)
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context),
              const SizedBox(height: 24),
              _buildHeader(),
              const SizedBox(height: 16),
              _buildProfileCard(),
              const SizedBox(height: 24),
              
              // Địa chỉ đón bác sĩ
              _buildSectionTitle(
                icon: Icons.location_on_outlined,
                iconColor: const Color(0xFF00695C),
                title: "Địa chỉ đón bác sĩ",
                actionText: "Mặc định",
              ),
              const SizedBox(height: 12),
              _buildAddressCard(),
              const SizedBox(height: 24),

              // Người thân khẩn cấp (SOS)
              _buildSectionTitle(
                icon: Icons.error, // Có thể dùng icon hình thoi nếu có file SVG
                iconColor: const Color(0xFFD32F2F),
                title: "Người thân khẩn cấp (SOS)",
                actionText: "+ Thêm",
              ),
              const SizedBox(height: 12),
              _buildEmergencyContactCard(),
              const SizedBox(height: 24),

              // Bảo mật & Đăng nhập
              _buildSectionTitle(
                icon: Icons.security,
                iconColor: const Color(0xFF00695C),
                title: "Bảo mật & Đăng nhập",
              ),
              const SizedBox(height: 12),
              _buildSecurityCard(),
              const SizedBox(height: 32),

              // Nút Đăng xuất
              _buildLogoutButton(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Thanh Top Bar
  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Nút Back
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
          ),
        ),
      ],
    );
  }

  // 2. Phần Header (Tiêu đề + Nút chỉnh sửa)
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF69F0AE), // Xanh lá mạ
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.contact_mail_outlined, color: Color(0xFF004D40), size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("HỒ SƠ SỨC KHỎE ĐIỆN TỬ", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                Text("Hồ sơ & Tài khoản", style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EAF6), // Xanh nhạt
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.edit_note, color: Color(0xFF283593), size: 16),
              SizedBox(width: 4),
              Text("Chỉnh sửa", style: TextStyle(color: Color(0xFF283593), fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  // 3. Khối Thông tin cá nhân
  Widget _buildProfileCard() {
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
              // Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=32'), // Thay bằng ảnh thật
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFF00695C), shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Thông tin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Trần Mai Anh", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text("#CT-88921", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text("0918 245 889", style: TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.verified, color: Color(0xFF00C853), size: 14),
                        SizedBox(width: 4),
                        Text("Đã xác thực", style: TextStyle(color: Color(0xFF00C853), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tag sức khỏe
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE), // Đỏ nhạt
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medical_services, color: Color(0xFFD32F2F), size: 14),
                SizedBox(width: 6),
                Text("Nhóm máu A+ • Dị ứng Penicillin", style: TextStyle(color: Color(0xFFD32F2F), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget hỗ trợ: Tiêu đề các mục
  Widget _buildSectionTitle({required IconData icon, required Color iconColor, required String title, String? actionText}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          ],
        ),
        if (actionText != null)
          Text(actionText, style: const TextStyle(color: Color(0xFF00695C), fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // 4. Khối Địa chỉ
  Widget _buildAddressCard() {
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
            decoration: const BoxDecoration(color: Color(0xFFE0F2F1), shape: BoxShape.circle), // Xanh lợt
            child: const Icon(Icons.location_on_outlined, color: Color(0xFF00695C), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("124 Pasteur, P. Bến Nghé, Q.1", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                SizedBox(height: 4),
                Text("Chung cư lầu 4, thang máy số 2", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. Khối Người thân SOS
  Widget _buildEmergencyContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF), // Tím cực nhạt
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: Color(0xFF00897B), shape: BoxShape.circle),
            child: const Center(child: Text("VH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text("Nguyễn Văn Hùng", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF69F0AE), borderRadius: BorderRadius.circular(4)),
                      child: const Text("Chồng", style: TextStyle(color: Color(0xFF004D40), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text("0903 123 456", style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFF69F0AE), shape: BoxShape.circle),
            child: const Icon(Icons.phone, color: Color(0xFF004D40), size: 18),
          ),
        ],
      ),
    );
  }

  // 6. Khối Bảo mật & Đăng nhập
  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSecurityRow(icon: Icons.phone_android, title: "Số điện thoại đăng nhập", value: "0918 245 889"),
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

  // 7. Nút Đăng xuất
  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Chuyển sang màn hình Đăng nhập
          Navigator.push(context, MaterialPageRoute(builder: (context) => const DangNhap()));
        },
        icon: const Icon(Icons.logout, color: Color(0xFFD32F2F), size: 18),
        label: const Text("Đăng xuất", style: TextStyle(color: Color(0xFFD32F2F), fontSize: 14, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF5F3FF), // Tím lợt
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