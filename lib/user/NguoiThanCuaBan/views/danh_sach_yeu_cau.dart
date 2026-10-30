// lib/NguoiThanCuaBan/views/danh_sach_yeu_cau.dart

import 'package:flutter/material.dart';
import 'package:cuhokhancap/user/models/nguoidungmodel.dart';
import 'package:cuhokhancap/user/NguoiThanCuaBan/controllers/nguoi_than_controller.dart';

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
    return StreamBuilder<List>(
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

        bool showReceived =
            (selectedFilterIndex == 0 || selectedFilterIndex == 1) &&
            receivedRequests.isNotEmpty;
        bool showSent =
            (selectedFilterIndex == 0 || selectedFilterIndex == 2) &&
            sentRequests.isNotEmpty;

        bool isFilterEmpty = false;
        String emptyMessage = 'Không có yêu cầu kết nối nào';

        if (selectedFilterIndex == 0 && allRequests.isEmpty) {
          isFilterEmpty = true;
          emptyMessage = 'Không có yêu cầu nào';
        } else if (selectedFilterIndex == 1 && receivedRequests.isEmpty) {
          isFilterEmpty = true;
          emptyMessage = 'Không có yêu cầu đã nhận nào';
        } else if (selectedFilterIndex == 2 && sentRequests.isEmpty) {
          isFilterEmpty = true;
          emptyMessage = 'Không có yêu cầu đã gửi nào';
        }

        if (isFilterEmpty) {
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
                  emptyMessage,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ================= KHỐI YÊU CẦU ĐÃ NHẬN =================
            if (showReceived) ...[
              Text(
                'Yêu cầu đã nhận (${receivedRequests.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ...receivedRequests.map(
                (req) => req['subType'] == 'cancel'
                    ? _buildReceivedCancelCard(
                        context,
                        user: req['user'],
                        senderId: req['senderId'],
                      )
                    : _buildReceivedCard(
                        context,
                        user: req['user'],
                        relation: req['moiQuanHe'],
                        senderId: req['senderId'],
                      ),
              ),
            ],

            if (showReceived && showSent) const SizedBox(height: 16),

            // ================= KHỐI YÊU CẦU ĐÃ GỬI =================
            if (showSent) ...[
              Text(
                'Yêu cầu đã gửi (${sentRequests.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ...sentRequests.map(
                (req) => req['subType'] == 'cancel'
                    ? _buildSentCancelCard(
                        context,
                        user: req['user'],
                        targetId: req['targetId'],
                      )
                    : _buildSentCard(
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

  // ---------------------------------------------------------------------------
  // CÁC THẺ UI DÀNH CHO YÊU CẦU KẾT NỐI
  // ---------------------------------------------------------------------------
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
                    await controller.rejectConnectRequest(
                      currentUserId,
                      senderId,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã từ chối yêu cầu kết nối!'),
                        ),
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
                    await controller.acceptConnectRequest(
                      currentUserId,
                      senderId,
                    );
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
                  await controller.cancelConnectRequest(
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

  // ---------------------------------------------------------------------------
  // CÁC THẺ UI DÀNH CHO YÊU CẦU HỦY KẾT NỐI
  // ---------------------------------------------------------------------------
  Widget _buildReceivedCancelCard(
    BuildContext context, {
    required NguoiDungModel user,
    required String senderId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.hoTen,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'Đã gửi yêu cầu hủy kết nối',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await controller.rejectCancelRelation(
                      currentUserId,
                      senderId,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã từ chối hủy kết nối!'),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Giữ lại',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    await controller.acceptCancelRelation(
                      currentUserId,
                      senderId,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã đồng ý hủy kết nối!')),
                      );
                    }
                  },
                  child: const Text(
                    'Đồng ý hủy',
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

  Widget _buildSentCancelCard(
    BuildContext context, {
    required NguoiDungModel user,
    required String targetId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.hoTen,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Chờ đối phương xác nhận hủy',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await controller.cancelCancelRequest(currentUserId, targetId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã thu hồi yêu cầu hủy kết nối!'),
                  ),
                );
              }
            },
            child: const Text(
              'Hủy bỏ',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
