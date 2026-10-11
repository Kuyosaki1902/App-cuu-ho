import 'package:flutter/material.dart';

class MenuNguoiDung extends StatefulWidget {
  const MenuNguoiDung({super.key});

  @override
  State<MenuNguoiDung> createState() => _MenuNguoiDungState();
}

class _MenuNguoiDungState extends State<MenuNguoiDung> {
  // Biến trạng thái để kiểm soát việc đóng/mở thẻ "Đăng ký người cứu hộ"
  bool _isExpanded = false; 

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      // Bo góc thanh menu
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header: CẤP CỨU 24/7 & Nút đóng
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.circle, color: Color(0xFF00C853), size: 10),
                              SizedBox(width: 6),
                              Text("CẤP CỨU 24/7", style: TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context), // Tắt menu
                          icon: const Icon(Icons.close, color: Colors.black54, size: 20),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                backgroundColor: Color(0xFF00695C),
                                child: Text("NA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                              ),
                              Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: const Icon(Icons.check_circle, color: Color(0xFF00C853), size: 14),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Nguyễn Văn An", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text("0912 ••• 789", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Đăng ký người cứu hộ (Có thể bấm để thu/mở)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFB2DFDB)),
                      ),
                      child: Column(
                        children: [
                          // Phần Header (bấm vào đây để đóng mở)
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF004D40), 
                              // Nếu đang đóng thì bo góc ở dưới, nếu mở thì bỏ bo góc dưới
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
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.favorite, color: Colors.white70, size: 18),
                                      const SizedBox(width: 8),
                                      const Expanded(child: Text("Đăng ký người cứu hộ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                      // Đổi icon mũi tên tùy theo trạng thái
                                      Icon(
                                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, 
                                        color: Colors.white
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Nội dung bên trong (2 nút nằm ngang) có hiệu ứng thu/mở
                          AnimatedCrossFade(
                            firstChild: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nút 1
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
                                  // Nút 2
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
                            secondChild: const SizedBox(width: double.infinity, height: 0),
                            crossFadeState: _isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                            duration: const Duration(milliseconds: 300), // Thời gian chạy hiệu ứng
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Danh sách các chức năng (Menu items)
                    _buildMenuItem(icon: Icons.history, title: "Lịch sử yêu cầu", trailingText: "3 lượt", trailingColor: const Color(0xFFE0F2F1), trailingTextColor: const Color(0xFF00695C)),
                    _buildMenuItem(icon: Icons.medical_services, title: "Hướng dẫn sơ cứu", trailingText: "OFFLINE", trailingColor: const Color(0xFFFFEBEE), trailingTextColor: Colors.red),
                    _buildMenuItem(icon: Icons.support_agent, title: "Hỗ trợ & Trợ giúp", trailingText: "Online", trailingColor: const Color(0xFFE8F5E9), trailingTextColor: const Color(0xFF2E7D32)),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    _buildMenuItem(icon: Icons.settings_outlined, title: "Cài đặt ứng dụng", isSimple: true),
                  ],
                ),
              ),
            ),
            
            // Bottom Panel: Chế độ cứu hộ
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF004D40), // Xanh rêu đậm
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
                              child: const Icon(Icons.settings, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("CHUYỂN ĐỔI SANG", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                  Text("Người hỗ trợ sơ cứu", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Switch(
                              value: true,
                              onChanged: (val) {},
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
                      Text("Phiên bản v2.4.1", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Row(
                        children: [
                          Icon(Icons.verified_user, color: Color(0xFF00695C), size: 14),
                          SizedBox(width: 4),
                          Text("MedVerify", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget vẽ nút 2 bên theo phong cách Button (nổi bật, có hiệu ứng bấm)
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
            offset: const Offset(0, 3), // Hiệu ứng đổ bóng giúp giống nút bấm
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Xử lý khi nhấn đăng ký
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon nằm trong viền tròn trắng
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: primaryColor, size: 24),
                ),
                const SizedBox(height: 10),
                // Tiêu đề nút
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87, height: 1.3),
                ),
                const SizedBox(height: 8),
                // Tag nhỏ bên dưới
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(tag, style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, String? trailingText, Color? trailingColor, Color? trailingTextColor, bool isSimple = false}) {
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
          Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: isSimple ? FontWeight.normal : FontWeight.w500, color: isSimple ? Colors.grey.shade700 : Colors.black87))),
          if (trailingText != null && trailingColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: trailingColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(trailingText, style: TextStyle(color: trailingTextColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}