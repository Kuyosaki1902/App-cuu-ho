import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/rescue_process_controller.dart';

class VictimDetailCard extends StatelessWidget {
  const VictimDetailCard({super.key});

  // 🚀 HÀM HiỂN THỊ BOTTOM SHEET DANH SÁCH SỐ ĐIỆN THOẠI NGƯỜI NHÀ
  void _showContactsBottomSheet(BuildContext context) {
    final controller = context.read<RescueProcessController>();

    final List<Map<String, String>> emergencyContacts = [
      {
        'name': 'Chị Mai (Vợ)',
        'relation': 'Người liên hệ chính • Đang có mặt ở nhà',
        'phone': '0903826826',
        'tag': 'Ưu tiên 1',
      },
      {
        'name': 'Anh Nguyễn Văn Bình (Anh trai)',
        'relation': 'Người thân • Đang di chuyển đến',
        'phone': '0912345678',
        'tag': 'Ưu tiên 2',
      },
      {
        'name': 'Tổng đài 115 (Điều phối viên)',
        'relation': 'Trực tổng đài hỗ trợ ca trực',
        'phone': '115',
        'tag': 'Tổng đài',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.quick_contacts_dialer,
                        color: Color(0xFFE52525),
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Danh bạ liên hệ người nhà SOS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(modalContext),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Nạn nhân: Nguyễn Văn An (42 tuổi)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 16),
              ...emergencyContacts.map((contact) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: _buildContactItem(
                    name: contact['name']!,
                    relation: contact['relation']!,
                    phone: contact['phone']!,
                    tag: contact['tag']!,
                    onCall: () {
                      Navigator.pop(modalContext);
                      controller.makePhoneCall(contact['phone']!);
                    },
                  ),
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // 🚀 HÀM HiỂN THỊ CHI TIẾT TÌNH TRẠNG NẠN NHÂN (Chuẩn theo mẫu hình ảnh)
  void _showVictimInfoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          height:
              MediaQuery.of(context).size.height *
              0.9, // Chiếm 90% chiều cao màn hình
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header cố định của Bottom Sheet
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: 8,
                ),
                child: Column(
                  children: [
                    // Thanh gạt phía trên
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF1F2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.videocam_outlined,
                            color: Color(0xFFE52525),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Video & Tình trạng nạn nhân',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '• Vừa gửi 1 phút trước • Trực tiếp từ hiện trường',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(modalContext),
                          icon: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Nội dung cuộn chi tiết
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔴 1. KHUNG PHÁT VIDEO HIỆN TRƯỜNG
                      Container(
                        width: double.infinity,
                        height: 190,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            // Overlay mờ / giả lập video
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE52525),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                            // Badge "VIDEO HIỆN TRƯỜNG (0:24S)"
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE52525),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '⚫ VIDEO HIỆN TRƯỜNG (0:24S)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            // Badge 720p
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '720p',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ),
                            // Thanh tiến trình giả lập dưới đáy
                            Positioned(
                              bottom: 8,
                              left: 12,
                              right: 12,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text(
                                    '00:08 / 00:24',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Icon(
                                    Icons.volume_up,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: const [
                          Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF00897B),
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Video quay trực tiếp từ người báo tin tại hiện trường',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 🔴 2. MÔ TẢ CHI TIẾT HIỆN TRƯỜNG
                      const Text(
                        'MÔ TẢ CHI TIẾT HIỆN TRƯỜNG',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5F5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFFCDD2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.warning,
                                  color: Color(0xFFE52525),
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Nạn nhân bất tỉnh, chảy máu thái dương trái',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE52525),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Mô tả người báo: Nạn nhân ngã đập đầu, bất tỉnh khoảng 2 phút, hiện đã tỉnh nhưng lơ mơ, khó thở nhẹ, chảy máu vùng trán và thái dương. Người nhà đang cố định đầu cổ theo hướng dẫn từ tổng đài 115.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF334155),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFFE0B2),
                                ),
                              ),
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.orange,
                                    size: 14,
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Hẻm 142 rất hẹp và đông, xe cứu thương lớn khó vào, ưu tiên tiếp cận bằng xe 2 bánh.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFD84315),
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 🔴 3. GHI ÂM CUỘC GỌI BÁO TIN
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.mic_none,
                                size: 16,
                                color: Color(0xFF475569),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'GHI ÂM CUỘC GỌI BÁO TIN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '00:24s',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00897B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF00897B),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Sóng âm thanh giả lập
                                  Row(
                                    children: List.generate(
                                      15,
                                      (index) => Expanded(
                                        child: Container(
                                          height: 3.0 + (index % 4 * 4),
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 1,
                                          ),
                                          color: index < 7
                                              ? const Color(0xFF00897B)
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text(
                                        '00:09',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        '00:24',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '1.0x',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 🔴 4. TIN NHẮN TRAO ĐỔI NHANH
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 15,
                                color: Color(0xFF475569),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'TIN NHẮN TRAO ĐỔI NHANH',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '2 tin nhắn khẩn',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD32F2F),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            _buildChatBubble(
                              isMe: false,
                              sender: 'Người nhà nạn nhân',
                              time: '1 phút trước',
                              text:
                                  'Cứu với ạ, ba em ngã cầu thang bất tỉnh, máu chảy nhiều ở trán, nhà ở cuối hẻm bên trái cổng xanh!',
                            ),
                            const SizedBox(height: 8),
                            _buildChatBubble(
                              isMe: true,
                              sender: 'Người cứu hộ',
                              time: 'Vừa xong',
                              text:
                                  'Đã điều động Bác sĩ Minh Tuấn gần bạn nhất di chuyển ngay. Vui lòng giữ yên cổ nạn nhân và lấy khăn sạch băng ép trán!',
                            ),
                            const SizedBox(height: 8),
                            _buildChatBubble(
                              isMe: false,
                              sender: 'Người nhà nạn nhân',
                              time: '30 giây trước',
                              text:
                                  'Dạ em đang đè gạc rồi ạ, bác sĩ tới bấm chuông hoặc gọi em chạy ra đón liền nhé!',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget phụ hỗ trợ render Chat Bubble
  Widget _buildChatBubble({
    required bool isMe,
    required String sender,
    required String time,
    required String text,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMe) ...[
                const Icon(Icons.circle, size: 6, color: Colors.red),
                const SizedBox(width: 4),
              ],
              Text(
                '$sender • $time',
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                const Icon(Icons.circle, size: 6, color: Color(0xFF00897B)),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF00897B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: isMe ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔴 HEADER: HỌ TÊN NẠN NHÂN VÀ HÀNG NÚT GỌI / CẤP ĐỘ 2 BÊN PHẢI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Thông tin tên & người nhà bên trái
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nguyễn Văn An\n(Nam • 42 tuổi)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Người nhà: Chị Mai (Vợ)',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // 🟢 CÙNG HÀNG NẰM BÊN PHẢI: BADGE CẤP ĐỘ 2 & NÚT GỌI NGƯỜI NHÀ
              Row(
                children: [
                  // Badge CẤP ĐỘ 2 Khẩn cấp
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'CẤP ĐỘ 2\nKhẩn cấp',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Nút gọi điện / mở Bottom Sheet liên hệ
                  InkWell(
                    onTap: () => _showContactsBottomSheet(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE52525),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.phone_in_talk,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Nút thông tin nạn nhân
                  InkWell(
                    onTap: () => _showVictimInfoBottomSheet(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE52525),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.medical_information,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 🔴 THẺ BỆNH CẢNH SƠ BỘ BAN ĐẦU
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'BỆNH CẢNH SƠ BỘ BAN ĐẦU:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Nạn nhân trượt ngã cầu thang từ tầng 1; gãy kín nghi biến dạng khớp cổ chân trái kèm sưng nề, đau dữ dội; chưa ghi nhận chấn thương sọ não mở; mạch 88 lần/phút, còn tỉnh táo tiếp xúc tốt.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF334155),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required String name,
    required String relation,
    required String phone,
    required String tag,
    required VoidCallback onCall,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFEBEE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_pin,
              color: Color(0xFFE52525),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00897B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  relation,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onCall,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
