import 'package:flutter/material.dart';

class HuongDanDangKyCuuHoScreen extends StatelessWidget {
  const HuongDanDangKyCuuHoScreen({super.key});

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
          'Hướng dẫn đăng ký Cứu hộ (2/2)',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
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

                  // PHẦN A: Người có chuyên môn
                  _buildRoleGuideCard(
                    badgeText: 'NHÓM 1 • Y TẾ CHUYÊN SÂU',
                    badgeColor: const Color(0xFF00695C),
                    bgColor: const Color(0xFFE0F2F1),
                    icon: Icons.verified_user_outlined,
                    title: 'Đăng ký Người có chuyên môn',
                    targetAudience:
                        'Dành cho Bác sĩ, Y tá, Điều dưỡng, Nhân viên y tế hoặc Sinh viên y khoa có bằng cấp/chứng chỉ hợp lệ.',
                    steps: const [
                      'Bước 1: Mở Menu bên trái tại Trang chủ -> Chọn mục "Đăng ký người cứu hộ".',
                      'Bước 2: Chọn nút "Người có chuyên môn" (Chứng chỉ).',
                      'Bước 3: Điền thông tin chuyên khoa, nơi công tác và tải lên ảnh chụp Chứng chỉ hành nghề (CCHN) / Bằng cấp.',
                      'Bước 4: Gửi hồ sơ và chờ Quản trị viên (Admin) kiểm tra tính xác thực trước khi kích hoạt quyền cứu hộ.',
                    ],
                  ),
                  const SizedBox(height: 16),

                  // PHẦN B: Người không có chuyên môn
                  _buildRoleGuideCard(
                    badgeText: 'NHÓM 2 • HỖ TRỢ CỘNG ĐỒNG',
                    badgeColor: const Color(0xFF2E7D32),
                    bgColor: const Color(0xFFE8F5E9),
                    icon: Icons.medical_services_outlined,
                    title: 'Đăng ký Người không có chuyên môn',
                    targetAudience:
                        'Dành cho người dân, tình nguyện viên có kỹ năng sơ cứu cơ bản hoặc mong muốn hỗ trợ hiện trường trong lúc chờ xe cấp cứu.',
                    steps: const [
                      'Bước 1: Mở Menu bên trái tại Trang chủ -> Chọn mục "Đăng ký người cứu hộ".',
                      'Bước 2: Chọn nút "Người thiếu chuyên môn" (Cộng đồng).',
                      'Bước 3: Cung cấp thông tin cá nhân cơ bản, khu vực thường xuyên hoạt động và xác nhận cam kết hỗ trợ.',
                      'Bước 4: Chờ hệ thống phê duyệt hồ sơ để bắt đầu nhận thông báo hỗ trợ nạn nhân ở khu vực lân cận.',
                    ],
                  ),
                  const SizedBox(height: 20),

                  // KHUNG GHI CHÚ: TẠI SAO LẠI CÓ 2 PHẦN HƯỚNG DẪN NHƯ VẬY?
                  _buildWhyTwoGuidesNote(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Nút hoàn tất ở đáy
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
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Quay về màn hình trước đó (hoặc điều hướng thẳng tới Đăng ký / Trang chủ)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: const Text(
                    'ĐÃ HIỂU & BẮT ĐẦU SỬ DỤNG',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004D40),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
        color: const Color(0xFF0D47A1),
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
              'BƯỚC 2: PHÂN LOẠI VAI TRÒ CỨU HỘ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hướng Dẫn Đăng Ký Lực Lượng Cứu Hộ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Chọn đúng nhóm đăng ký phù hợp với năng lực của bạn để hệ thống điều phối chính xác trong các tình huống khẩn cấp.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleGuideCard({
    required String badgeText,
    required Color badgeColor,
    required Color bgColor,
    required IconData icon,
    required String title,
    required String targetAudience,
    required List<String> steps,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag phân loại
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: badgeColor),
                const SizedBox(width: 6),
                Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            targetAudience,
            style: const TextStyle(
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const Divider(height: 24),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 16, color: badgeColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyTwoGuidesNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1), // Vàng kem nổi bật cho phần Ghi chú
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB300), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Color(0xFFE65100), size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'GHI CHÚ: Tại sao lại chia thành 2 phần hướng dẫn?',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildNoteBullet(
            '1. Khác biệt về hồ sơ & Kiểm duyệt pháp lý:',
            'Người có chuyên môn bắt buộc phải nộp Chứng chỉ hành nghề (CCHN) / bằng cấp y tế để Admin xác minh nhằm đảm bảo an toàn tính mạng nạn nhân. Người không có chuyên môn chỉ cần xác minh thông tin cơ bản để tham gia nhanh.',
          ),
          const SizedBox(height: 8),
          _buildNoteBullet(
            '2. Phân luồng điều phối đúng năng lực ("Thời gian vàng"):',
            'Hệ thống hiển thị 2 biểu tượng khác nhau trên bản đồ để ưu tiên kết nối bác sĩ chuyên khoa cho các ca chấn thương nặng, đồng thời huy động tình nguyện viên gần nhất hỗ trợ bảo vệ hiện trường hoặc sơ cứu cơ bản theo hướng dẫn từ xa.',
          ),
          const SizedBox(height: 8),
          _buildNoteBullet(
            '3. Tránh nhầm lẫn khi thao tác:',
            'Tách bạch 2 luồng hướng dẫn giúp mỗi đối tượng chuẩn bị đúng giấy tờ ngay từ đầu, không bị rối bởi các yêu cầu không thuộc nhóm của mình.',
          ),
        ],
      ),
    );
  }

  Widget _buildNoteBullet(String heading, String content) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.45),
        children: [
          TextSpan(
            text: '$heading ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: content),
        ],
      ),
    );
  }
}