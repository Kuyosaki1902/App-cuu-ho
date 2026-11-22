import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'huong_dan_dang_ky_cuu_ho_screen.dart';

class HuongDanTaiAppScreen extends StatelessWidget {
  const HuongDanTaiAppScreen({super.key});

  void _copyLinkTaiApp(BuildContext context, String platform, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép link tải cho $platform!'),
        backgroundColor: const Color(0xFF00695C),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Hướng dẫn sử dụng (1/2)',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFB71C1C),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.emergency, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  '115',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Header
                  _buildHeaderBanner(),
                  const SizedBox(height: 20),

                  // Phần 1: Cách tải và cài đặt ứng dụng
                  const Text(
                    '1. Cách tải & Cài đặt ứng dụng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDownloadCard(
                    context: context,
                    icon: Icons.android,
                    iconColor: const Color(0xFF2E7D32),
                    title: 'Dành cho Android (CH Play / File APK)',
                    subtitle:
                        'Tìm kiếm từ khóa "Cứu Hộ Khẩn Cấp 115" trên Google Play hoặc tải trực tiếp gói cài đặt APK từ trang chủ và bật "Cho phép cài đặt từ nguồn này".',
                    linkUrl: 'https://cuhokhancap115.vn/download/android',
                  ),
                  const SizedBox(height: 10),
                  _buildDownloadCard(
                    context: context,
                    icon: Icons.apple,
                    iconColor: Colors.black87,
                    title: 'Dành cho iOS (App Store / TestFlight)',
                    subtitle:
                        'Mở App Store hoặc ứng dụng TestFlight trên iPhone, nhập tên ứng dụng "Cứu Hộ Khẩn Cấp 115" và nhấn Nhận (Get) để cài đặt.',
                    linkUrl: 'https://cuhokhancap115.vn/download/ios',
                  ),
                  const SizedBox(height: 24),

                  // Phần 2: Thiết lập ban đầu sau khi tải
                  const Text(
                    '2. Thiết lập bắt buộc khi mở app lần đầu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStepItem(
                    stepNumber: 'B1',
                    title: 'Cấp quyền Vị trí (GPS) & Thông báo',
                    description:
                        'Chọn "Luôn cho phép" hoặc "Trong khi dùng ứng dụng" đối với GPS và bật Thông báo để nhận tín hiệu cầu cứu khẩn cấp theo thời gian thực.',
                    icon: Icons.location_on_outlined,
                  ),
                  _buildStepItem(
                    stepNumber: 'B2',
                    title: 'Đăng ký tài khoản người dùng cơ bản',
                    description:
                        'Nhập Họ tên, Số điện thoại, Ngày sinh và Mật khẩu. Hệ thống sẽ cấp mặc định tài khoản Người dùng để bạn có thể gọi cứu hộ ngay lập tức.',
                    icon: Icons.person_add_alt_1_outlined,
                  ),
                  _buildStepItem(
                    stepNumber: 'B3',
                    title: 'Nâng cấp lên tài khoản Cứu hộ (Nếu muốn)',
                    description:
                        'Sau khi đăng nhập, mở Menu bên trái và chọn mục "Đăng ký người cứu hộ" để đăng ký tham gia hỗ trợ cộng đồng (xem chi tiết ở trang sau).',
                    icon: Icons.volunteer_activism_outlined,
                  ),
                ],
              ),
            ),
          ),

          // Thanh điều hướng dưới cùng sang Màn hình 2
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HuongDanDangKyCuuHoScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00695C),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Tiếp theo: Hướng dẫn đăng ký Cứu hộ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00695C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'BƯỚC 1: CÀI ĐẶT & KHỞI ĐỘNG',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tải Ứng Dụng & Thiết Lập Tài Khoản',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hướng dẫn cài đặt ứng dụng Cứu hộ 115 trên điện thoại và chuẩn bị tài khoản trước khi đăng ký vai trò cứu hộ.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String linkUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Sao chép liên kết tải',
                onPressed: () => _copyLinkTaiApp(context, title, linkUrl),
                icon: const Icon(Icons.copy, size: 18, color: Color(0xFF00695C)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12.5,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFE0F2F1),
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: Color(0xFF00695C),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: const Color(0xFF00695C)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}