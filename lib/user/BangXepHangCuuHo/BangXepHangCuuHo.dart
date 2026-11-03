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

  // Biến lưu trữ tập hợp chuyên ngành được chọn để lọc
  Set<String> selectedSpecialties = {};

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
        selectedSpecialties
            .clear(); // Reset bộ lọc chuyên ngành khi đổi Tab thời gian
        _leaderboardFuture = _controller.fetchLeaderboard(index);
      });
    }
  }

  // 🌟 Hàm tính toán & hiển thị mốc thời gian động theo ngày thực tế
  String _getTimeDisplayText() {
    final now = DateTime.now();

    switch (selectedTab) {
      case 0:
        // Tính Thứ 2 đầu tuần và Chủ Nhật cuối tuần hiện tại
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));

        final startStr =
            "${monday.day.toString().padLeft(2, '0')}/${monday.month.toString().padLeft(2, '0')}";
        final endStr =
            "${sunday.day.toString().padLeft(2, '0')}/${sunday.month.toString().padLeft(2, '0')}/${sunday.year}";

        return 'Tuần này ($startStr - $endStr)';

      case 1:
        // Hiển thị Tháng/Năm hiện tại
        final monthStr = now.month.toString().padLeft(2, '0');
        return 'Tháng này ($monthStr/${now.year})';

      case 2:
        return 'Toàn thời gian';

      default:
        return 'Tuần này';
    }
  }

  // Màn hình nhỏ (BottomSheet) cho phép chọn nhiều chuyên ngành cùng lúc
  void _showSpecialtyFilterDialog(List<String> availableSpecialties) {
    Set<String> tempSelected = Set.from(selectedSpecialties);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
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
                      const Text(
                        'Lọc theo Chuyên ngành',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (tempSelected.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              tempSelected.clear();
                            });
                          },
                          child: const Row(
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 14,
                                color: Color(0xFF006A55),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Bỏ chọn',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF006A55),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Chọn một hoặc nhiều chuyên ngành để lọc danh sách:',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Divider(height: 20),

                  if (availableSpecialties.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Không có chuyên ngành nào để lọc',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: availableSpecialties.length,
                        itemBuilder: (context, index) {
                          final specialty = availableSpecialties[index];
                          final isChecked = tempSelected.contains(specialty);

                          return CheckboxListTile(
                            activeColor: const Color(0xFF006A55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            title: Text(
                              specialty,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isChecked
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isChecked
                                    ? const Color(0xFF006A55)
                                    : Colors.black87,
                              ),
                            ),
                            value: isChecked,
                            onChanged: (bool? value) {
                              setModalState(() {
                                if (value == true) {
                                  tempSelected.add(specialty);
                                } else {
                                  tempSelected.remove(specialty);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Hủy',
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006A55),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            setState(() {
                              selectedSpecialties = Set.from(tempSelected);
                            });
                            Navigator.pop(context);
                          },
                          child: Text(
                            tempSelected.isEmpty
                                ? 'Hiển thị tất cả'
                                : 'Áp dụng (${tempSelected.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
          // 1. Thanh chuyển đổi Tab thời gian
          TimeFilterTabsWidget(
            selectedTab: selectedTab,
            tabs: tabs,
            onTabSelected: _onTabChanged,
          ),

          // 🌟 2. CỤM TIÊU ĐỀ + NÚT LỌC SẮP XẾP VÀ MỐC THỜI GIAN
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🌟 HÀNG 1: TIÊU ĐỀ (TRÁI) + CỤM NÚT LỌC & SẮP XẾP (PHẢI) NẰM CHUNG 1 HÀNG
                Row(
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

                    Row(
                      children: [
                        // NÚT LỌC CHUYÊN NGÀNH
                        FutureBuilder<List<RescuerLeaderboardItemModel>>(
                          future: _leaderboardFuture,
                          builder: (context, snapshot) {
                            final rawList = snapshot.data ?? [];
                            final availableSpecialties = rawList
                                .map((e) => e.specialty)
                                .where((s) => s.isNotEmpty)
                                .toSet()
                                .toList();

                            return GestureDetector(
                              onTap: () => _showSpecialtyFilterDialog(
                                availableSpecialties,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedSpecialties.isNotEmpty
                                      ? const Color(0xFF006A55)
                                      : const Color(
                                          0xFF006A55,
                                        ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.filter_alt_outlined,
                                      size: 16,
                                      color: selectedSpecialties.isNotEmpty
                                          ? Colors.white
                                          : const Color(0xFF006A55),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      selectedSpecialties.isEmpty
                                          ? 'Chuyên ngành'
                                          : '${selectedSpecialties.length} ngành',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: selectedSpecialties.isNotEmpty
                                            ? Colors.white
                                            : const Color(0xFF006A55),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(width: 6),

                        // NÚT SẮP XẾP (Số ca / Đánh giá sao)
                        PopupMenuButton<String>(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF006A55).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.swap_vert_rounded,
                              size: 18,
                              color: Color(0xFF006A55),
                            ),
                          ),
                          tooltip: 'Sắp xếp theo',
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

                const SizedBox(height: 4),

                // 🌟 HÀNG 2: HIỂN THỊ MỐC THỜI GIAN NẰM RIÊNG BÊN DƯỚI (CHỮ XÁM, KHÔNG KHUNG)
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Hiển thị: ${_getTimeDisplayText()}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Hiển thị danh sách card sau khi Lọc & Sắp xếp
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

                if (selectedSpecialties.isNotEmpty) {
                  list = list
                      .where(
                        (item) => selectedSpecialties.contains(item.specialty),
                      )
                      .toList();
                }

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_alt_off_outlined,
                          size: 56,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          selectedSpecialties.isNotEmpty
                              ? 'Không có kết quả cho chuyên ngành đã chọn'
                              : 'Chưa có dữ liệu xếp hạng',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (selectedSpecialties.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                selectedSpecialties.clear();
                              });
                            },
                            child: const Text(
                              'Bỏ lọc để xem tất cả',
                              style: TextStyle(
                                color: Color(0xFF006A55),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

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
