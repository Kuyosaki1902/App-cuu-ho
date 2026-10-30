// lib/NguoiThanCuaBan/views/nguoi_than_cua_ban.dart

import 'package:flutter/material.dart';
import 'package:cuhokhancap/user/NguoiThanCuaBan/controllers/nguoi_than_controller.dart';

class NguoiThanCuaBanTab extends StatelessWidget {
  final String userId;
  final NguoiThanController controller;
  final Color primaryColor;

  const NguoiThanCuaBanTab({
    super.key,
    required this.userId,
    required this.controller,
    required this.primaryColor,
  });

  // Hàm hiển thị hộp thoại xác nhận xóa
  // lib/NguoiThanCuaBan/views/nguoi_than_cua_ban.dart

  // Hàm hiển thị hộp thoại xác nhận xóa
  Future<void> _showDeleteConfirmDialog(
    BuildContext context, {
    required String relativeId,
    required String relativeName,
  }) async {
    // 1. Lấy trước messengerState từ Context hiện tại (Trước khi mở Dialog)
    final messenger = ScaffoldMessenger.of(context);

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xóa mối quan hệ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa mối quan hệ người thân với $relativeName không?\n\nLưu ý: Thao tác này sẽ xóa mối quan hệ ở cả hai phía.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Xóa',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Thay vì xóa ngay lập tức, chuyển trạng thái thành Yêu Cầu Hủy (sẽ nhảy sang Tab Đã Gửi)
        await controller.requestCancelRelation(userId, relativeId);

        messenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2E7D32), // Xanh lá
            content: Text(
              'Đã gửi yêu cầu hủy kết nối tới $relativeName!',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD32F2F), // Đỏ
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Xóa mối quan hệ thất bại: $e',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: controller.getRelativesStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'Bạn chưa thêm người thân của mình',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Chuyển sang tab "Tìm Kiếm Người Thân" để gửi yêu cầu kết nối.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          );
        }

        final relativesList = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: relativesList.length,
          itemBuilder: (context, index) {
            final item = relativesList[index];
            return _buildRelativeCard(
              context: context,
              relativeId: item['id'],
              name: item['name'],
              age: item['age'],
              phone: item['phone'],
              email: item['email'],
              relation: item['relation'],
              avatarUrl: item['avatarUrl'],
              trangThai: item['trangThai'], // <--- Bổ sung
            );
          },
        );
      },
    );
  }

  Widget _buildRelativeCard({
    required BuildContext context,
    required String relativeId,
    required String name,
    required int age,
    required String phone,
    required String email,
    required String relation,
    required String avatarUrl,
    required String trangThai, // <--- Bổ sung
  }) {
    bool isPendingCancel = trangThai == 'user_trangthai_nguoithan_dongyhuy';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$age tuổi',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // 🌟 MENU 3 DẤU CHẤM THẲNG ĐỨNG ĐỀ LÊN CARD
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteConfirmDialog(
                      context,
                      relativeId: relativeId,
                      relativeName: name,
                    );
                  }
                },
                itemBuilder: (BuildContext ctx) => [
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Xóa mối quan hệ',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 18, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      phone,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(email, style: const TextStyle(color: Colors.black87)),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 18, color: primaryColor),
                    const SizedBox(width: 8),
                    Text.rich(
                      TextSpan(
                        text: 'Mối quan hệ: ',
                        style: const TextStyle(color: Colors.grey),
                        children: [
                          TextSpan(
                            text: relation,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
