// lib/user/BangXepHangCuuHo/BangXepHangCuuHo.dart

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
  static const Color _green = Color(0xFF006A55);

  final BangXepHangController _controller = BangXepHangController();

  int selectedTab = 0; // 0: Tuần này, 1: Tháng này, 2: Tất cả
  final List<String> tabs = ['Tuần này', 'Tháng này', 'Tất cả'];

  String currentSortOption = 'cases';

  // Bộ lọc (giữ nguyên khi đổi tab vì lựa chọn lấy từ toàn bộ dữ liệu)
  Set<String> selectedSpecialties = {};
  Set<String> selectedSkills = {};

  late Future<List<RescuerLeaderboardItemModel>> _leaderboardFuture;
  late Future<LeaderboardFilterOptions> _optionsFuture;

  int get _filterCount => selectedSpecialties.length + selectedSkills.length;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = _controller.fetchLeaderboard(selectedTab);
    _optionsFuture = _controller.loadFilterOptions();
  }

  void _onTabChanged(int index) {
    if (selectedTab != index) {
      setState(() {
        selectedTab = index;
        _leaderboardFuture = _controller.fetchLeaderboard(index);
      });
    }
  }

  /// Tải lại toàn bộ (nút "Thử lại" / kéo để làm mới)
  Future<void> _reload() async {
    _controller.refresh();
    setState(() {
      _leaderboardFuture = _controller.fetchLeaderboard(selectedTab);
      _optionsFuture = _controller.loadFilterOptions();
    });
    try {
      await _leaderboardFuture;
    } catch (_) {}
  }

  String _getTimeDisplayText() {
    final now = DateTime.now();

    switch (selectedTab) {
      case 0:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));

        final startStr =
            "${monday.day.toString().padLeft(2, '0')}/${monday.month.toString().padLeft(2, '0')}";
        final endStr =
            "${sunday.day.toString().padLeft(2, '0')}/${sunday.month.toString().padLeft(2, '0')}/${sunday.year}";

        return 'Tuần này ($startStr - $endStr)';

      case 1:
        final monthStr = now.month.toString().padLeft(2, '0');
        return 'Tháng này ($monthStr/${now.year})';

      case 2:
        return 'Toàn thời gian';

      default:
        return 'Tuần này';
    }
  }

  // ===========================================================================
  // BẢNG LỌC: CHUYÊN NGÀNH + KỸ NĂNG
  // ===========================================================================
  Future<void> _showFilterSheet() async {
    LeaderboardFilterOptions options;
    try {
      options = await _optionsFuture;
    } catch (_) {
      options = const LeaderboardFilterOptions(specialties: [], skills: []);
    }
    if (!mounted) return;

    final Set<String> tempSpecialties = Set.from(selectedSpecialties);
    final Set<String> tempSkills = Set.from(selectedSkills);

    // Gom kỹ năng theo nhóm, giữ thứ tự xuất hiện
    final Map<String, List<KyNangOption>> skillGroups = {};
    for (final k in options.skills) {
      skillGroups.putIfAbsent(k.tenNhom, () => []).add(k);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final int total = tempSpecialties.length + tempSkills.length;

            Widget chip({
              required String label,
              required bool selected,
              required VoidCallback onTap,
            }) {
              return FilterChip(
                label: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? _green : Colors.black87,
                  ),
                ),
                selected: selected,
                showCheckmark: false,
                selectedColor: _green.withOpacity(0.12),
                backgroundColor: Colors.grey.shade100,
                side: BorderSide(color: selected ? _green : Colors.transparent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                onSelected: (_) => setModalState(onTap),
              );
            }

            Widget sectionTitle(String text, {String? hint}) {
              return Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (hint != null)
                      Text(
                        hint,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
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
                        'Bộ lọc cứu hộ viên',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (total > 0)
                        GestureDetector(
                          onTap: () => setModalState(() {
                            tempSpecialties.clear();
                            tempSkills.clear();
                          }),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 14,
                                color: _green,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Bỏ chọn',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _green,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ---- CHUYÊN NGÀNH ----
                          sectionTitle(
                            'Chuyên ngành',
                            hint: 'Chọn một hoặc nhiều chuyên ngành',
                          ),
                          if (options.specialties.isEmpty)
                            Text(
                              'Chưa có dữ liệu chuyên ngành',
                              style: TextStyle(color: Colors.grey.shade500),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: options.specialties.map((s) {
                                return chip(
                                  label: s,
                                  selected: tempSpecialties.contains(s),
                                  onTap: () {
                                    if (!tempSpecialties.remove(s)) {
                                      tempSpecialties.add(s);
                                    }
                                  },
                                );
                              }).toList(),
                            ),

                          // ---- KỸ NĂNG (theo nhóm) ----
                          sectionTitle(
                            'Kỹ năng cứu hộ',
                            hint:
                                'Hiển thị người có ít nhất một kỹ năng đã chọn',
                          ),
                          if (skillGroups.isEmpty)
                            Text(
                              'Chưa có dữ liệu kỹ năng',
                              style: TextStyle(color: Colors.grey.shade500),
                            )
                          else
                            ...skillGroups.entries.map((g) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      g.key,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: g.value.map((k) {
                                        return chip(
                                          label: k.ten.isNotEmpty
                                              ? k.ten
                                              : k.ma,
                                          selected: tempSkills.contains(k.ma),
                                          onTap: () {
                                            if (!tempSkills.remove(k.ma)) {
                                              tempSkills.add(k.ma);
                                            }
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                          onPressed: () => Navigator.pop(sheetContext),
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
                            backgroundColor: _green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            setState(() {
                              selectedSpecialties = Set.from(tempSpecialties);
                              selectedSkills = Set.from(tempSkills);
                            });
                            Navigator.pop(sheetContext);
                          },
                          child: Text(
                            total == 0 ? 'Hiển thị tất cả' : 'Áp dụng ($total)',
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

  // ===========================================================================
  // GIAO DIỆN CHÍNH
  // ===========================================================================
  Widget _buildFilterButton() {
    final bool active = _filterCount > 0;
    return GestureDetector(
      onTap: _showFilterSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _green : _green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.filter_alt_outlined,
              size: 16,
              color: active ? Colors.white : _green,
            ),
            const SizedBox(width: 4),
            Text(
              active ? 'Bộ lọc ($_filterCount)' : 'Bộ lọc',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : _green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortMenu() {
    PopupMenuItem<String> item(String value, IconData icon, String text) {
      final bool selected = currentSortOption == value;
      return PopupMenuItem<String>(
        value: value,
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? _green : Colors.grey),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? _green : Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _green.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.swap_vert_rounded, size: 18, color: _green),
      ),
      tooltip: 'Sắp xếp theo',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (String result) => setState(() => currentSortOption = result),
      itemBuilder: (BuildContext context) => [
        item(
          'cases',
          Icons.medical_services_outlined,
          'Sắp xếp theo số ca hỗ trợ',
        ),
        item('rating', Icons.star_outline_rounded, 'Sắp xếp theo đánh giá sao'),
      ],
    );
  }

  Widget _buildStateMessage({
    required IconData icon,
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    color: _green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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
          TimeFilterTabsWidget(
            selectedTab: selectedTab,
            tabs: tabs,
            onTabSelected: _onTabChanged,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        _buildFilterButton(),
                        const SizedBox(width: 6),
                        _buildSortMenu(),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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
          Expanded(
            child: FutureBuilder<List<RescuerLeaderboardItemModel>>(
              future: _leaderboardFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _green),
                  );
                }

                // Lỗi tải: báo lỗi thật + nút thử lại (không giả vờ là "chưa có dữ liệu")
                if (snapshot.hasError) {
                  debugPrint('❌ Bảng xếp hạng: ${snapshot.error}');
                  return _buildStateMessage(
                    icon: Icons.cloud_off_rounded,
                    title: 'Không tải được bảng xếp hạng',
                    actionLabel: 'Thử lại',
                    onAction: _reload,
                  );
                }

                final all = snapshot.data ?? [];

                List<RescuerLeaderboardItemModel> list =
                    BangXepHangController.applyFilters(
                      all,
                      specialties: selectedSpecialties,
                      skills: selectedSkills,
                    );

                if (list.isEmpty) {
                  final bool dangLoc = _filterCount > 0;
                  return _buildStateMessage(
                    icon: dangLoc
                        ? Icons.filter_alt_off_outlined
                        : Icons.leaderboard_outlined,
                    title: dangLoc
                        ? 'Không có cứu hộ viên phù hợp với bộ lọc'
                        : 'Chưa có dữ liệu xếp hạng',
                    actionLabel: dangLoc ? 'Bỏ lọc để xem tất cả' : null,
                    onAction: dangLoc
                        ? () => setState(() {
                            selectedSpecialties.clear();
                            selectedSkills.clear();
                          })
                        : null,
                  );
                }

                if (currentSortOption == 'rating') {
                  list.sort((a, b) {
                    final byRating = b.rating.compareTo(a.rating);
                    return byRating != 0
                        ? byRating
                        : b.casesCount.compareTo(a.casesCount);
                  });
                } else {
                  list.sort((a, b) {
                    final byCases = b.casesCount.compareTo(a.casesCount);
                    return byCases != 0
                        ? byCases
                        : b.rating.compareTo(a.rating);
                  });
                }

                return RefreshIndicator(
                  color: _green,
                  onRefresh: _reload,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      return RescuerCardItemWidget(
                        item: list[index].copyWithRank(index + 1),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
