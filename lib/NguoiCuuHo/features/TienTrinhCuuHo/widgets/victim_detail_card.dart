import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/rescue_process_controller.dart';

class VictimDetailCard extends StatelessWidget {
  const VictimDetailCard({super.key});

  // 🚀 BOTTOM SHEET DANH SÁCH LIÊN HỆ KHẨN CẤP
  void _showContactsBottomSheet(
    BuildContext context,
    String victimName,
    String victimPhone,
  ) {
    final controller = context.read<RescueProcessController>();
    final List<Map<String, String>> emergencyContacts = [
      {
        'name': victimName.isNotEmpty ? victimName : 'Nạn nhân',
        'relation': 'Số điện thoại trực tiếp của nạn nhân',
        'phone': victimPhone.isNotEmpty ? victimPhone : 'Chưa có SĐT',
        'tag': 'Trực tiếp',
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
                        'Danh bạ liên hệ khẩn cấp',
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
              Text(
                'Nạn nhân: $victimName',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                      if (contact['phone'] != 'Chưa có SĐT') {
                        controller.makePhoneCall(contact['phone']!);
                      }
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

  // 🚀 MODAL HIỂN THỊ CHI TIẾT MÔ TẢ HIỆN TRƯỜNG (HIỂN THỊ HÌNH ẢNH THAY CHO VIDEO)
  void _showVictimInfoBottomSheet(
    BuildContext context,
    String victimName,
    String victimAddress,
  ) {
    final rescueController = context.read<RescueProcessController>();
    final TextEditingController chatController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return ChangeNotifierProvider.value(
          value: rescueController,
          child: Consumer<RescueProcessController>(
            builder: (context, controller, child) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.92,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // --- HEADER MODAL ---
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 12,
                        bottom: 8,
                      ),
                      child: Column(
                        children: [
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
                                  Icons.image_rounded,
                                  color: Color(0xFFE52525),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hình ảnh & Tình trạng nạn nhân',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.fiber_manual_record,
                                          color: Colors.green,
                                          size: 10,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Trực tiếp từ hiện trường',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(modalContext),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),

                    // --- NỘI DUNG CHI TIẾT CUỘN ---
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. HÌNH ẢNH HIỆN TRƯỜNG (LẤY TỪ FIRESTORE QUA CONTROLLER)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 200,
                                width: double.infinity,
                                color: const Color(0xFFF1F5F9),
                                child: controller.hinhAnhUrl.isNotEmpty
                                    ? Image.network(
                                        controller.hinhAnhUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Color(0xFFE52525),
                                                    ),
                                              );
                                            },
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.broken_image_outlined,
                                                  color: Colors.grey,
                                                  size: 36,
                                                ),
                                                SizedBox(height: 6),
                                                Text(
                                                  'Không thể tải hình ảnh hiện trường',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      )
                                    : const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: Colors.grey,
                                              size: 36,
                                            ),
                                            SizedBox(height: 6),
                                            Text(
                                              'Không có hình ảnh hiện trường',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Row(
                              children: [
                                Icon(
                                  Icons.verified,
                                  color: Color(0xFF10B981),
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Hình ảnh chụp trực tiếp từ người báo tin tại hiện trường',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // 2. MÔ TẢ CHI TIẾT HIỆN TRƯỜNG
                            const Text(
                              'MÔ TẢ CHI TIẾT HIỆN TRƯỜNG',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF5F5),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFFFCDD2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Color(0xFFE52525),
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Nạn nhân cần hỗ trợ khẩn cấp',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFE52525),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    controller.moTaChiTiet,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF334155),
                                      height: 1.4,
                                    ),
                                  ),
                                  if (controller.trieuChung.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: controller.trieuChung.map((tc) {
                                        return Chip(
                                          label: Text(
                                            tc,
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                          backgroundColor: Colors.white,
                                          labelStyle: const TextStyle(
                                            color: Color(0xFFE52525),
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFFFCDD2),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Colors.orange,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Địa chỉ: $victimAddress',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 3. GHI ÂM CUỘC GỌI BÁO TIN
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.mic,
                                      color: Color(0xFF10B981),
                                      size: 16,
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
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F4EA),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    '00:24s',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: List.generate(16, (index) {
                                        return Container(
                                          width: 3,
                                          height: (index % 3 == 0)
                                              ? 22
                                              : ((index % 2 == 0) ? 14 : 8),
                                          decoration: BoxDecoration(
                                            color: index < 8
                                                ? const Color(0xFF10B981)
                                                : Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
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
                            const SizedBox(height: 20),

                            // 4. BOX CHAT TRAO ĐỔI NHANH
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      color: Color(0xFF00897B),
                                      size: 16,
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
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF1F2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Trao đổi trực tiếp',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFFE52525),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // CONTAINER DANH SÁCH TIN NHẮN
                            Container(
                              height: 250,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: controller.danhSachTinNhan.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Chưa có tin nhắn trao đổi',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      reverse: true,
                                      itemCount:
                                          controller.danhSachTinNhan.length,
                                      itemBuilder: (context, index) {
                                        final tinNhan =
                                            controller.danhSachTinNhan[index];
                                        final isMyMessage =
                                            tinNhan.maNguoiGui ==
                                            controller.currentDoctorId;

                                        return Align(
                                          alignment: isMyMessage
                                              ? Alignment.centerRight
                                              : Alignment.centerLeft,
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: isMyMessage
                                                  ? const Color(0xFF00897B)
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: isMyMessage
                                                  ? null
                                                  : Border.all(
                                                      color: const Color(
                                                        0xFFE2E8F0,
                                                      ),
                                                    ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  isMyMessage
                                                      ? '🟢 Bạn • Vừa xong'
                                                      : '🔴 Người nhà • Vừa xong',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: isMyMessage
                                                        ? Colors.white70
                                                        : Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  tinNhan.noiDung,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isMyMessage
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF0F172A,
                                                          ),
                                                  ),
                                                ),
                                                if (tinNhan.fileDinhKemUrl !=
                                                        null &&
                                                    tinNhan
                                                        .fileDinhKemUrl!
                                                        .isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 8.0,
                                                        ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      child: Image.network(
                                                        tinNhan.fileDinhKemUrl!,
                                                        height: 100,
                                                        width: 150,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),

                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: chatController,
                                    decoration: InputDecoration(
                                      hintText: 'Nhập tin nhắn...',
                                      hintStyle: const TextStyle(fontSize: 12),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                    ),
                                    onSubmitted: (text) {
                                      if (text.trim().isNotEmpty) {
                                        controller.guiTinNhan(text.trim());
                                        chatController.clear();
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    final text = chatController.text;
                                    if (text.trim().isNotEmpty) {
                                      controller.guiTinNhan(text.trim());
                                      chatController.clear();
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00897B),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RescueProcessController>();

    final String vName = controller.victimName;
    final String vPhone = controller.victimPhone;
    final String vAddress = controller.victimAddress;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFFFFF1F2),
                      child: Icon(
                        Icons.person,
                        color: Color(0xFFE52525),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            vPhone.isNotEmpty
                                ? 'SĐT: $vPhone'
                                : 'Đang cập nhật SĐT...',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () =>
                        _showContactsBottomSheet(context, vName, vPhone),
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
                  InkWell(
                    onTap: () =>
                        _showVictimInfoBottomSheet(context, vName, vAddress),
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
                        Icons.message_outlined,
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'ĐỊA CHỈ SỰ CỐ:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  controller.victimAddress,
                  style: const TextStyle(
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
