// lib/views/nguoi_than/danh_sach_yeu_cau.dart

import 'package:flutter/material.dart';

class DanhSachYeuCauWidget extends StatelessWidget {
  final int selectedFilterIndex;
  final Color primaryColor;

  const DanhSachYeuCauWidget({
    super.key,
    required this.selectedFilterIndex,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (selectedFilterIndex == 0 || selectedFilterIndex == 1) ...[
          const Text(
            'Yêu cầu đã nhận',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildReceivedCard(
            'Khang Nguyễn',
            '0912 345 678',
            'khang.nguyen@gmail.com',
            'Con trai',
            '10 phút trước',
          ),
          _buildReceivedCard(
            'Thùy Linh',
            '0988 765 432',
            'thuylinh.pham@gmail.com',
            'Em gái',
            '1 giờ trước',
          ),
        ],
        if (selectedFilterIndex == 0 || selectedFilterIndex == 2) ...[
          const SizedBox(height: 8),
          const Text(
            'Yêu cầu đã gửi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildSentCard(
            'Thu Hà',
            29,
            '0987 654 321',
            'thuha.tran@gmail.com',
            '15 phút trước',
          ),
          _buildSentCard(
            'Lê Quốc Bảo',
            42,
            '0934 567 890',
            'baole.med@gmail.com',
            '2 giờ trước',
          ),
        ],
      ],
    );
  }

  Widget _buildReceivedCard(
    String name,
    String phone,
    String email,
    String rel,
    String time,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=33'),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      phone,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text(email),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: 'Muốn thành lập mối quan hệ: ',
              children: [
                TextSpan(
                  text: rel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Text(
            'Đã nhận $time',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text(
                    'Từ chối',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  onPressed: () {},
                  child: const Text(
                    'Chấp nhận',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentCard(
    String name,
    int age,
    String phone,
    String email,
    String time,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?img=47',
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('$age tuổi', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Chờ xem xét',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      phone,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text(email),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã gửi $time',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Thu hồi',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
