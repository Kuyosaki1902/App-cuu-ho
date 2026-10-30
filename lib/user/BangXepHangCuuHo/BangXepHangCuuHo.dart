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

  // Biến lưu trữ tiêu chí sắp xếp: 'cases' (Số ca) hoặc 'rating' (Đánh giá sao)
  String currentSortOption = 'cases';

  late Future<List<RescuerLeaderboardItemModel>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = _controller.fetchLeaderboard(selectedTab);
  }

  void _onTabChanged(int index) {
    if (selectedTab != index) {
      setState(() {
        selectedTab = index;
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

          // 🌟 2. TIÊU ĐỀ DANH SÁCH + NÚT LỌC & SẮP XẾP VỪA THÊM
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

                // Cụm chứa Text thời gian + Nút Lọc Sắp Xếp
                Row(
                  children: [
                    Text(
                      tabs[selectedTab],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),

                    // 🌟 NÚT LỌC VÀ SẮP XẾP
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006A55).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.tune_rounded, // Icon Lọc & Sắp xếp xịn
                          size: 20,
                          color: Color(0xFF006A55),
                        ),
                      ),
                      tooltip: 'Lọc & Sắp xếp',
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (String result) {
                        setState(() {
                          currentSortOption = result;
                        });
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'cases',
                          child: Row(
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                size: 18,
                                color: currentSortOption == 'cases'
                                    ? const Color(0xFF006A55)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Sắp xếp theo số ca hỗ trợ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: currentSortOption == 'cases'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: currentSortOption == 'cases'
                                      ? const Color(0xFF006A55)
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'rating',
                          child: Row(
                            children: [
                              Icon(
                                Icons.star_outline_rounded,
                                size: 18,
                                color: currentSortOption == 'rating'
                                    ? const Color(0xFF006A55)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Sắp xếp theo đánh giá sao',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: currentSortOption == 'rating'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: currentSortOption == 'rating'
                                      ? const Color(0xFF006A55)
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Hiển thị FutureBuilder
          Expanded(
            child: FutureBuilder<List<RescuerLeaderboardItemModel>>(
              future: _leaderboardFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF006A55)),
                  );
                }

                List<RescuerLeaderboardItemModel> list = List.from(
                  snapshot.data ?? [],
                );

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

                // 🌟 LỌC / SẮP XẾP THEO LỰA CHỌN CỦA NÚT LỌC
                if (currentSortOption == 'rating') {
                  list.sort((a, b) => b.rating.compareTo(a.rating));
                } else {
                  list.sort((a, b) => b.casesCount.compareTo(a.casesCount));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    // Cập nhật lại thứ hạng tạm thời theo tiêu chuẩn sắp xếp mới
                    final item = list[index];
                    final updatedItem = RescuerLeaderboardItemModel(
                      rank: index + 1,
                      user: item.user,
                      casesCount: item.casesCount,
                      specialty: item.specialty,
                      organization: item.organization,
                      rating: item.rating,
                      reviewsCount: item.reviewsCount,
                    );
                    return RescuerCardItemWidget(item: updatedItem);
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
