// lib/NguoiThanCuaBan/views/nguoi_than_cua_ban.dart

import 'package:cuhokhancap/user/NguoiThanCuaBan/views/custom_avatar.dart';
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

  // Hộp thoại xác nhận yêu cầu hủy kết nối
  Future<void> _showDeleteConfirmDialog(
    BuildContext context, {
    required String relativeId,
    required String relativeName,
  }) async {
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
          'Bạn có chắc chắn muốn gửi yêu cầu hủy mối quan hệ người thân với $relativeName không?',
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
              'Xóa mối quan hệ',
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
        await controller.requestCancelRelation(userId, relativeId);

        messenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2E7D32),
            content: Text(
              'Đã gửi yêu cầu hủy kết nối tới $relativeName!',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD32F2F),
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
                    'Gửi yêu cầu xóa thất bại: $e',
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
                  'Bạn chưa có người thân nào',
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
              trangThai: item['trangThai'],
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
    required String? avatarUrl,
    required String trangThai,
  }) {
    bool isMyCancelRequest = trangThai == 'user_trangthai_nguoithan_dongyhuy';
    bool isOtherCancelRequest =
        trangThai == 'user_trangthai_nguoithan_huynguoithan';
    bool isPendingCancel = isMyCancelRequest || isOtherCancelRequest;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPendingCancel ? Colors.orange.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPendingCancel
              ? Colors.orange.shade300
              : Colors.grey.shade200,
          width: isPendingCancel ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CustomAvatar(
                avatarUrl: avatarUrl,
                name: name,
                radius: 28,
                primaryColor: primaryColor,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$age tuổi',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    if (isPendingCancel) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_filled_rounded,
                              size: 13,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isMyCancelRequest
                                  ? 'Đã gửi yêu cầu hủy kết nối'
                                  : 'Đối phương đã yêu cầu hủy',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

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
                  PopupMenuItem<String>(
                    value: 'delete',
                    enabled: !isPendingCancel,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: isPendingCancel ? Colors.grey : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Xóa mối quan hệ',
                          style: TextStyle(
                            color: isPendingCancel ? Colors.grey : Colors.red,
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
              color: isPendingCancel
                  ? Colors.orange.shade100.withOpacity(0.4)
                  : const Color(0xFFF4F6F8),
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
