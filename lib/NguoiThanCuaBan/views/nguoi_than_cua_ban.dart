// lib/views/nguoi_than/nguoi_than_cua_ban.dart

import 'package:cuhokhancap/NguoiThanCuaBan/controllers/nguoi_than_controller.dart';
import 'package:flutter/material.dart';

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
              name: item['name'],
              age: item['age'],
              phone: item['phone'],
              email: item['email'],
              relation: item['relation'],
              avatarUrl: item['avatarUrl'],
            );
          },
        );
      },
    );
  }

  Widget _buildRelativeCard({
    required String name,
    required int age,
    required String phone,
    required String email,
    required String relation,
    required String avatarUrl,
  }) {
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
              const Icon(Icons.more_vert, color: Colors.grey),
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {},
              icon: const Icon(Icons.call, size: 18, color: Colors.white),
              label: const Text(
                'Gọi điện',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
