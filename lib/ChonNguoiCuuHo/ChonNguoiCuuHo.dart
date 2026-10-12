// GiaoDienDangTimKiem.dart

import 'package:cuhokhancap/ChonNguoiCuuHo/controllers/chon_nguoi_cuu_ho_controller.dart';
import 'package:cuhokhancap/ChonNguoiCuuHo/views/card_nguoi_cuu_ho.dart';
import 'package:cuhokhancap/ChonNguoiCuuHo/views/chuyen_nganh_filter.dart';
import 'package:flutter/material.dart';

class ChonBacSiTiepNhan extends StatefulWidget {
  final Map<String, dynamic> dsNguoiCuuHo;
  const ChonBacSiTiepNhan({super.key, required this.dsNguoiCuuHo});

  @override
  State<ChonBacSiTiepNhan> createState() => _ChonBacSiTiepNhanState();
}

class _ChonBacSiTiepNhanState extends State<ChonBacSiTiepNhan> {
  final ChonNguoiCuuHoController _controller = ChonNguoiCuuHoController();

  int selectedCategoryIndex = 0;
  int selectedDoctorIndex = 0;
  bool isLoading = true;

  List<ItemNguoiCuuHo> allDoctors = [];
  List<ChuyenNganhModel> dsChuyenNganh = [
    ChuyenNganhModel(maChuyenNganh: "ALL", tenChuyenNganh: "Tất Cả"),
    ChuyenNganhModel(
      maChuyenNganh: 'CuuHoTuDo',
      tenChuyenNganh: "Cứu Hộ Tự Do",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final result = await _controller.fetchDoctorsFromFirestore(
      widget.dsNguoiCuuHo,
    );

    if (mounted) {
      setState(() {
        allDoctors = result['doctors'] as List<ItemNguoiCuuHo>;
        dsChuyenNganh = result['categories'] as List<ChuyenNganhModel>;
        isLoading = false;
      });
    }
  }

  List<ItemNguoiCuuHo> get filteredDoctors {
    if (selectedCategoryIndex == 0) return allDoctors;
    final selectedChuyenNganh =
        dsChuyenNganh[selectedCategoryIndex].maChuyenNganh;
    return allDoctors
        .where((item) => item.maChuyenNganh == selectedChuyenNganh)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final doctors = filteredDoctors;

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 2),
            ],
          ),
          child: Column(
            children: [
              // Thanh gạch xám
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey[100],
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 16,
                          color: Colors.black87,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Text(
                      'Chọn người tiếp nhận',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // Location Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF0C5C4D),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Tìm kiếm lân cận',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2F7F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${doctors.length} lực lượng sẵn sàng',
                        style: const TextStyle(
                          color: Color(0xFF0C5C4D),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chuyên ngành
              ChuyenNganhFilterWidget(
                dsChuyenNganh: dsChuyenNganh,
                allDoctors: allDoctors,
                selectedCategoryIndex: selectedCategoryIndex,
                onCategorySelected: (index) {
                  setState(() {
                    selectedCategoryIndex = index;
                    selectedDoctorIndex = 0;
                  });
                },
              ),

              const SizedBox(height: 12),

              // Danh sách
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0C5C4D),
                        ),
                      )
                    : (doctors.isEmpty
                          ? const Center(
                              child: Text(
                                'Không tìm thấy lực lượng cứu hộ phù hợp.',
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: doctors.length,
                              itemBuilder: (context, index) {
                                final item = doctors[index];
                                return CardNguoiCuuHoWidget(
                                  item: item,
                                  isSelected: selectedDoctorIndex == index,
                                  onTap: () => setState(
                                    () => selectedDoctorIndex = index,
                                  ),
                                );
                              },
                            )),
              ),

              // Confirm Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C5C4D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: doctors.isNotEmpty
                        ? () {
                            final selectedDoctor = doctors[selectedDoctorIndex];
                            Navigator.pop(
                              context,
                              selectedDoctor.nguoiDung.maNguoiDung,
                            );
                          }
                        : null,
                    icon: const Icon(
                      Icons.send_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'XÁC NHẬN CHỌN NGƯỜI CỨU HỘ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
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
