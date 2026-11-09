import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/LichSuCaCuuHo/controller/man_hinh_lich_su_ca_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ManHinhLichSuCa extends StatelessWidget {
  final String currentUserId;

  const ManHinhLichSuCa({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ManHinhLichSuCaController(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              const _CustomAppBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      const _SearchBarSection(),
                      const SizedBox(height: 4),
                      const _TimeModeFilterRow(),
                      const SizedBox(height: 4),
                      const _DatePickerWithArrowsRow(),
                      const SizedBox(height: 4),
                      Expanded(
                        child: _RescueHistoryList(currentUserId: currentUserId),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomAppBar extends StatelessWidget {
  const _CustomAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'LỊCH SỬ CA',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBarSection extends StatelessWidget {
  const _SearchBarSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (val) {
                context.read<ManHinhLichSuCaController>().setSearchQuery(val);
              },
              decoration: const InputDecoration(
                hintText: 'Tìm mã ca hoặc địa chỉ...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeModeFilterRow extends StatelessWidget {
  const _TimeModeFilterRow();

  @override
  Widget build(BuildContext context) {
    final modeIndex = context.select<ManHinhLichSuCaController, int>(
      (c) => c.timeModeIndex,
    );
    List<String> options = ['Hôm nay', 'Tuần này', 'Tháng này'];

    return Row(
      children: List.generate(options.length, (index) {
        bool isSelected = modeIndex == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == options.length - 1 ? 0 : 8.0,
            ),
            child: InkWell(
              onTap: () => context
                  .read<ManHinhLichSuCaController>()
                  .setTimeModeIndex(index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  options[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DatePickerWithArrowsRow extends StatelessWidget {
  const _DatePickerWithArrowsRow();

  Future<void> _selectDate(BuildContext context) async {
    final controller = context.read<ManHinhLichSuCaController>();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('vi', 'VN'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E293B),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.setSelectedDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateRangeText = context.select<ManHinhLichSuCaController, String>(
      (c) => c.getFormattedDateRange(),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: Color(0xFF1E293B),
            ),
            onPressed: () =>
                context.read<ManHinhLichSuCaController>().navigateDate(false),
          ),
          InkWell(
            onTap: () => _selectDate(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: Color(0xFF1E293B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateRangeText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF1E293B),
            ),
            onPressed: () =>
                context.read<ManHinhLichSuCaController>().navigateDate(true),
          ),
        ],
      ),
    );
  }
}

class _RescueHistoryList extends StatelessWidget {
  final String currentUserId;

  const _RescueHistoryList({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ManHinhLichSuCaController>();
    final searchQuery = context.select<ManHinhLichSuCaController, String>(
      (c) => c.searchQuery,
    );
    final statusFilterIndex = context.select<ManHinhLichSuCaController, int>(
      (c) => c.statusFilterIndex,
    );

    return StreamBuilder<QuerySnapshot>(
      stream: controller.getRescueHistoryStream(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1E293B)),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
        }

        var allDocs = snapshot.data?.docs ?? [];
        Map<String, int> stats = controller.calculateStatistics(allDocs);

        if (allDocs.isEmpty) {
          return Column(
            children: [
              _StatisticSummaryRow(stats: stats),
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_toggle_off_rounded,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text('Không có dữ liệu ca cứu hộ trong ngày'),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        var docs = List<QueryDocumentSnapshot>.from(allDocs);

        // Lọc tìm kiếm local
        if (searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String idStr = doc.id.toLowerCase();
            String diaChi = (data['diaChiCuaVictim'] ?? '')
                .toString()
                .toLowerCase();
            String query = searchQuery.toLowerCase();
            return idStr.contains(query) || diaChi.contains(query);
          }).toList();
        }

        // Lọc trạng thái trực tiếp từ các nút Thống kê bấm chọn
        if (statusFilterIndex == 1) {
          docs = docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return data['maTrangThaiTiepNhan'] ==
                'cuuho_trangthai_phancong_hoanthanh';
          }).toList();
        } else if (statusFilterIndex == 2) {
          docs = docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return data['maTrangThaiTiepNhan'] ==
                'cuuho_trangthai_phancong_dahuy';
          }).toList();
        } else if (statusFilterIndex == 3) {
          docs = docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String st = data['maTrangThaiTiepNhan'] ?? '';
            return st != 'cuuho_trangthai_phancong_hoanthanh' &&
                st != 'cuuho_trangthai_phancong_dahuy';
          }).toList();
        }

        return Column(
          children: [
            _StatisticSummaryRow(stats: stats),
            const SizedBox(height: 12),
            Expanded(
              child: docs.isEmpty
                  ? const Center(
                      child: Text('Không có ca nào phù hợp với bộ lọc'),
                    )
                  : ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        var itemData =
                            docs[index].data() as Map<String, dynamic>;
                        String idPhanCong = docs[index].id;
                        return _RescueCardItem(
                          docId: idPhanCong,
                          data: itemData,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _RescueCardItem extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _RescueCardItem({required this.docId, required this.data});

  // Truy vấn động Tên nạn nhân và Địa chỉ từ YeuCauCuuHo & NguoiDung
  Future<Map<String, String>> _fetchVictimAndAddressInfo(
    BuildContext context,
  ) async {
    String victimName = (data['tenVictim'] ?? '').toString();
    String address = (data['diaChiCuaVictim'] ?? '').toString();

    if (victimName.isNotEmpty && address.isNotEmpty) {
      return {'victimName': victimName, 'address': address};
    }

    String maYeuCau = (data['maYeuCau'] ?? docId).toString();
    final firestore = FirebaseFirestore.instance;
    final controller = context.read<ManHinhLichSuCaController>();

    try {
      DocumentSnapshot yeuCauSnap = await firestore
          .collection('YeuCauCuuHo')
          .doc(maYeuCau)
          .get();

      if (yeuCauSnap.exists && yeuCauSnap.data() != null) {
        var ycData = yeuCauSnap.data() as Map<String, dynamic>;

        // 1. Lấy tên địa chỉ hoặc Reverse Geocode từ tọa độ
        if (address.isEmpty) {
          address = (ycData['diaChi'] ?? ycData['diaChiCuaVictim'] ?? '')
              .toString();
          if (address.isEmpty &&
              ycData['viDo'] != null &&
              ycData['kinhDo'] != null) {
            double lat = (ycData['viDo'] as num).toDouble();
            double lng = (ycData['kinhDo'] as num).toDouble();
            address = await controller.getAddressFromLatLng(lat, lng);
          }
        }

        // 2. Lấy tên nạn nhân từ NguoiDung
        if (victimName.isEmpty) {
          String maVictim = (ycData['maNguoiYeuCau'] ?? '').toString();

          if (maVictim.isNotEmpty) {
            DocumentSnapshot userSnap = await firestore
                .collection('NguoiDung')
                .doc(maVictim)
                .get();
            if (userSnap.exists && userSnap.data() != null) {
              var uData = userSnap.data() as Map<String, dynamic>;
              victimName = (uData['hoTen'] ?? 'Nạn nhân khẩn cấp').toString();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi truy vấn thông tin nạn nhân: $e');
    }

    return {
      'victimName': victimName.isNotEmpty ? victimName : 'Nạn nhân khẩn cấp',
      'address': address.isNotEmpty ? address : 'Chưa cập nhật địa chỉ',
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ManHinhLichSuCaController>();
    String maTrangThai = data['maTrangThaiTiepNhan'] ?? '';
    Map<String, dynamic> statusStyle = controller.getStatusStyle(maTrangThai);

    String code = '#${docId.toUpperCase()}';
    String timeBadgeText = controller.formatTimeText(data['thoiGianTao']);

    String t1 =
        'Tiếp nhận: ${controller.formatTimeText(data['thoiGianTiepNhan'])}';
    String t2 = 'Đến nơi: ${controller.formatTimeText(data['thoiGianDenNoi'])}';
    String t3 =
        'Hoàn thành: ${controller.formatTimeText(data['thoiGianHoanThanh'])}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: statusStyle['borderColor'], width: 5),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: Color(0xFFDC2626),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              code,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                timeBadgeText,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Yêu cầu cứu hộ khẩn cấp',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusStyle['bgColor'],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusStyle['text'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusStyle['textColor'],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dùng FutureBuilder để load và hiển thị Tên & Địa chỉ thực tế
              FutureBuilder<Map<String, String>>(
                future: _fetchVictimAndAddressInfo(context),
                builder: (context, infoSnapshot) {
                  String address = infoSnapshot.hasData
                      ? infoSnapshot.data!['address']!
                      : 'Đang tải địa chỉ...';
                  String victimName = infoSnapshot.hasData
                      ? infoSnapshot.data!['victimName']!
                      : 'Đang tải tên nạn nhân...';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Nạn nhân: $victimName',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t1,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFF475569),
                          ),
                        ),
                        Text(
                          t2,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        Text(
                          t3,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: statusStyle['ratio'],
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          statusStyle['borderColor'],
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatisticSummaryRow extends StatelessWidget {
  final Map<String, int> stats;

  const _StatisticSummaryRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final statusFilterIndex = context.select<ManHinhLichSuCaController, int>(
      (c) => c.statusFilterIndex,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            context: context,
            title: 'Tổng ca',
            count: '${stats['tong']}',
            textColor: const Color(0xFF0F172A),
            bgColor: Colors.grey.shade100,
            filterIndex: 0,
            isSelected: statusFilterIndex == 0,
          ),
          _buildDivider(),
          _buildStatItem(
            context: context,
            title: 'Hoàn thành',
            count: '${stats['hoanThanh']}',
            textColor: const Color(0xFF047857),
            bgColor: const Color(0xFFECFDF5),
            filterIndex: 1,
            isSelected: statusFilterIndex == 1,
          ),
          _buildDivider(),
          _buildStatItem(
            context: context,
            title: 'Đã hủy',
            count: '${stats['daHuy']}',
            textColor: const Color(0xFFB91C1C),
            bgColor: const Color(0xFFFEF2F2),
            filterIndex: 2,
            isSelected: statusFilterIndex == 2,
          ),
          _buildDivider(),
          _buildStatItem(
            context: context,
            title: 'Chờ/Đang xử lý',
            count:
                '${(stats['dangCuuTro'] ?? 0) + (stats['choTiepNhan'] ?? 0)}',
            textColor: const Color(0xFFB45309),
            bgColor: const Color(0xFFFFFBEB),
            filterIndex: 3,
            isSelected: statusFilterIndex == 3,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required String title,
    required String count,
    required Color textColor,
    required Color bgColor,
    required int filterIndex,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          context.read<ManHinhLichSuCaController>().setStatusFilterIndex(
            filterIndex,
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? textColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? textColor : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 24, width: 1, color: const Color(0xFFE2E8F0));
  }
}
