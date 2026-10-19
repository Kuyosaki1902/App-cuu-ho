// lib/BangXepHangCuuHo/BangXepHangCuuHo.dart

import 'package:flutter/material.dart';
import 'controllers/bang_xep_hang_controller.dart';
import 'views/time_filter_tabs.dart';
import 'views/rescuer_card_item.dart';

class BangXepHangCuuHo extends StatefulWidget {
  const BangXepHangCuuHo({super.key});

  @override
  State<BangXepHangCuuHo> createState() => _BangXepHangCuuHoState();
}

class _BangXepHangCuuHoState extends State<BangXepHangCuuHo> {
  final BangXepHangController _controller = BangXepHangController();

  int selectedTab = 0; // 0: Tuần này, 1: Tháng này, 2: Tất cả
  final List<String> tabs = ['Tuần này', 'Tháng này', 'Tất cả'];

  // Biến lưu trữ Future truy vấn hiện tại
  late Future<List<RescuerLeaderboardItemModel>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    // Khởi tạo truy vấn ban đầu cho Tuần này
    _leaderboardFuture = _controller.fetchLeaderboard(selectedTab);
  }

  void _onTabChanged(int index) {
    if (selectedTab != index) {
      setState(() {
        selectedTab = index;
        // 🌟 GÁN LẠI FUTURE MỚI -> NGẮT TOÀN BỘ KẾT QUẢ TRUY VẤN CŨ TỨC THÌ!
        _leaderboardFuture = _controller.fetchLeaderboard(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bảng xếp hạng cộng đồng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Thanh lọc thời gian
          TimeFilterTabsWidget(
            selectedTab: selectedTab,
            tabs: tabs,
            onTabSelected: _onTabChanged,
          ),

          // 2. Tiêu đề danh sách
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DANH SÁCH CỨU HỘ VIÊN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  tabs[selectedTab],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          // 3. Hiển thị FutureBuilder (Ngắt đè truy vấn hoàn toàn)
          Expanded(
            child: FutureBuilder<List<RescuerLeaderboardItemModel>>(
              future: _leaderboardFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF006A55)),
                  );
                }

                final list = snapshot.data ?? [];

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có dữ liệu xếp hạng',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    return RescuerCardItemWidget(item: list[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
