// lib/NguoiThanCuaBan/views/danh_sach_yeu_cau.dart

import 'package:flutter/material.dart';
import 'package:cuhokhancap/models/nguoidungmodel.dart';
import 'package:cuhokhancap/NguoiThanCuaBan/controllers/nguoi_than_controller.dart';

class DanhSachYeuCauWidget extends StatelessWidget {
  final String currentUserId;
  final int selectedFilterIndex;
  final Color primaryColor;
  final NguoiThanController controller;

  const DanhSachYeuCauWidget({
    super.key,
    required this.currentUserId,
    required this.selectedFilterIndex,
    required this.primaryColor,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: controller.getPendingRequestsStream(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        final allRequests = snapshot.data ?? [];
        final receivedRequests = allRequests
            .where((req) => req['type'] == 'received')
            .toList();
        final sentRequests = allRequests
            .where((req) => req['type'] == 'sent')
            .toList();

        if (allRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'Không có yêu cầu kết nối nào',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if ((selectedFilterIndex == 0 || selectedFilterIndex == 1) &&
                receivedRequests.isNotEmpty) ...[
              Text(
                'Yêu cầu đã nhận (${receivedRequests.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ...receivedRequests.map(
                (req) => _buildReceivedCard(
                  context,
                  user: req['user'],
                  relation: req['moiQuanHe'],
                  senderId: req['senderId'],
                ),
              ),
            ],
            if ((selectedFilterIndex == 0 || selectedFilterIndex == 2) &&
                sentRequests.isNotEmpty) ...[
              if (selectedFilterIndex == 0 && receivedRequests.isNotEmpty)
                const SizedBox(height: 16),
              Text(
                'Yêu cầu đã gửi (${sentRequests.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ...sentRequests.map(
                (req) => _buildSentCard(
                  context,
                  user: req['user'],
                  relation: req['moiQuanHe'],
                  targetId: req['targetId'],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildReceivedCard(
    BuildContext context, {
    required NguoiDungModel user,
    required String relation,
    required String senderId,
  }) {
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
                backgroundImage: NetworkImage('https://i.pravatar.cc/150'),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.hoTen,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${controller.tinhTuoi(user.ngaySinh)} tuổi',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: 'Muốn thành lập mối quan hệ: ',
              children: [
                TextSpan(
                  text: relation,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    // TỪ CHỐI -> XÓA YÊU CẦU BÊN NGƯỜI GỬI
                    await controller.rejectOrCancelRequest(
                      senderId,
                      currentUserId,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã từ chối yêu cầu!')),
                      );
                    }
                  },
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
                  onPressed: () async {
                    // CHẤP NHẬN -> CHUYỂN THÀNH 'dongy' BÊN NGƯỜI GỬI VÀ TẠO BẢN GHI CHO MÌNH
                    await controller.acceptRequest(currentUserId, senderId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã chấp nhận kết nối!')),
                      );
                    }
                  },
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
    BuildContext context, {
    required NguoiDungModel user,
    required String relation,
    required String targetId,
  }) {
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
                backgroundImage: NetworkImage('https://i.pravatar.cc/150'),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.hoTen,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${controller.tinhTuoi(user.ngaySinh)} tuổi',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  text: 'Thiết lập: ',
                  children: [
                    TextSpan(
                      text: relation,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () async {
                  // THU HỒI -> XÓA YÊU CẦU TRÊN FIRESTORE
                  await controller.rejectOrCancelRequest(
                    currentUserId,
                    targetId,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã thu hồi yêu cầu!')),
                    );
                  }
                },
                child: const Text(
                  'Thu hồi',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
