import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import các model chính trong project của bạn
import 'package:cuhokhancap/models/nguoidungmodel.dart';
import 'package:cuhokhancap/models/hosocuuhococchnmodel.dart';
import 'package:cuhokhancap/models/hosocuuhokhongcchnmodel.dart';

class ChonBacSiTiepNhan extends StatefulWidget {
  // Map truyền sang: Key = maNguoiDung, Value = khoangCachMet
  final Map<String, int> dsNguoiCuuHo;
  const ChonBacSiTiepNhan({super.key, required this.dsNguoiCuuHo});

  @override
  State<ChonBacSiTiepNhan> createState() => _ChonBacSiTiepNhanState();
}

// 🌟 HARDCODE DANH SÁCH CHUYÊN NGÀNH ĐỂ LỌC (CATEGORY FILTER)
class ChuyenNganhModel {
  final String maChuyenNganh;
  final String tenChuyenNganh;
  ChuyenNganhModel({required this.maChuyenNganh, required this.tenChuyenNganh});
}

final List<ChuyenNganhModel> dsChuyenNganhHardcode = [
  ChuyenNganhModel(maChuyenNganh: 'ALL', tenChuyenNganh: 'Tất cả'),
  ChuyenNganhModel(maChuyenNganh: 'DA_KHOA', tenChuyenNganh: 'Đa khoa'),
  ChuyenNganhModel(maChuyenNganh: 'NHI_KHOA', tenChuyenNganh: 'Nhi khoa'),
  ChuyenNganhModel(maChuyenNganh: 'TIM_MACH', tenChuyenNganh: 'Tim mạch'),
  ChuyenNganhModel(maChuyenNganh: 'HO_HAP', tenChuyenNganh: 'Hô hấp'),
];

// 🌟 CLASS WRAPPER GỘP TRỰC TIẾP MODEL CỦA BẠN
class ItemNguoiCuuHo {
  final NguoiDungModel nguoiDung;
  final HoSoCuuHoCoCCHNModel? hoSoCoCCHN;
  final HoSoCuuHoKhongCCHNModel? hoSoKhongCCHN;
  final int khoangCachMet;
  final String maChuyenNganh;
  final String tenChuyenNganh;

  ItemNguoiCuuHo({
    required this.nguoiDung,
    this.hoSoCoCCHN,
    this.hoSoKhongCCHN,
    required this.khoangCachMet,
    required this.maChuyenNganh,
    required this.tenChuyenNganh,
  });

  bool get coCCHN => hoSoCoCCHN != null;

  double get rating => coCCHN
      ? (hoSoCoCCHN?.diemDanhGia ?? 5.0)
      : (hoSoKhongCCHN?.diemDanhGia ?? 5.0);

  int get reviewsCount => coCCHN
      ? (hoSoCoCCHN?.tongLuotDanhGia ?? 0)
      : (hoSoKhongCCHN?.tongLuotDanhGia ?? 0);

  String get formattedDistance => khoangCachMet >= 1000
      ? '${(khoangCachMet / 1000).toStringAsFixed(1)}km'
      : '${khoangCachMet}m';

  String get timeArrival {
    int phut = (khoangCachMet / 300).round();
    if (phut < 3) phut = 3;
    return '$phut–${phut + 3} phút đến';
  }

  String get initials {
    final parts = nguoiDung.hoTen.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2][0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.isNotEmpty && parts.first.isNotEmpty
        ? parts.first[0].toUpperCase()
        : 'CH';
  }
}

class _ChonBacSiTiepNhanState extends State<ChonBacSiTiepNhan> {
  int selectedCategoryIndex = 0;
  int selectedDoctorIndex = 0;
  bool isLoading = true;

  List<ItemNguoiCuuHo> allDoctors = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctorsFromFirestore();
  }

  // 🌟 QUERY VÀ KHỎI TẠO DANH SÁCH
  Future<void> _fetchDoctorsFromFirestore() async {
    setState(() => isLoading = true);
    List<ItemNguoiCuuHo> loadedList = [];

    int index = 0;
    for (var entry in widget.dsNguoiCuuHo.entries) {
      final String maNguoiDung = entry.key;
      final int khoangCachMet = entry.value;

      // 1. Lấy NguoiDungModel
      final userDoc = await FirebaseFirestore.instance
          .collection('NguoiDung')
          .doc(maNguoiDung)
          .get();

      if (!userDoc.exists || userDoc.data() == null) continue;
      final userModel = NguoiDungModel.fromMap(userDoc.data()!);

      // 2. Tìm Hồ sơ Có CCHN trước
      final cchnQuery = await FirebaseFirestore.instance
          .collection('HoSoCuuHoCoCCHN')
          .where('maNguoiDung', isEqualTo: maNguoiDung)
          .limit(1)
          .get();

      HoSoCuuHoCoCCHNModel? hoSoCoCCHN;
      HoSoCuuHoKhongCCHNModel? hoSoKhongCCHN;

      if (cchnQuery.docs.isNotEmpty) {
        hoSoCoCCHN = HoSoCuuHoCoCCHNModel.fromMap(
          cchnQuery.docs.first.data(),
          cchnQuery.docs.first.id,
        );
      } else {
        // 3. Nếu không có CCHN -> Tìm Hồ sơ Không CCHN
        final khongCchnQuery = await FirebaseFirestore.instance
            .collection('HoSoCuuHoKhongCCHN')
            .where('maNguoiDung', isEqualTo: maNguoiDung)
            .limit(1)
            .get();

        if (khongCchnQuery.docs.isNotEmpty) {
          hoSoKhongCCHN = HoSoCuuHoKhongCCHNModel.fromMap(
            khongCchnQuery.docs.first.data(),
            khongCchnQuery.docs.first.id,
          );
        }
      }

      // Hardcode gán xoay vòng chuyên ngành cho danh sách test
      final chuyenNganhSample =
          dsChuyenNganhHardcode[(index % (dsChuyenNganhHardcode.length - 1)) +
              1];
      index++;

      loadedList.add(
        ItemNguoiCuuHo(
          nguoiDung: userModel,
          hoSoCoCCHN: hoSoCoCCHN,
          hoSoKhongCCHN: hoSoKhongCCHN,
          khoangCachMet: khoangCachMet,
          maChuyenNganh: chuyenNganhSample.maChuyenNganh,
          tenChuyenNganh: chuyenNganhSample.tenChuyenNganh,
        ),
      );
    }

    // 4. Sắp xếp danh sách theo khoảng cách từ gần đến xa
    loadedList.sort((a, b) => a.khoangCachMet.compareTo(b.khoangCachMet));

    if (mounted) {
      setState(() {
        allDoctors = loadedList;
        isLoading = false;
      });
    }
  }

  // Danh sách sau khi lọc qua Tab Chuyên Ngành
  List<ItemNguoiCuuHo> get filteredDoctors {
    if (selectedCategoryIndex == 0) return allDoctors;
    final selectedChuyenNganh =
        dsChuyenNganhHardcode[selectedCategoryIndex].maChuyenNganh;
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
              // Thanh gạch xám nhỏ phía trên
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

              // Location & Count Bar
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

              // 🌟 THANH PHÂN LOẠI THEO CHUYÊN NGÀNH (CATEGORY FILTER)
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: dsChuyenNganhHardcode.length,
                  itemBuilder: (context, index) {
                    final isSelected = selectedCategoryIndex == index;
                    final category = dsChuyenNganhHardcode[index];

                    // Đếm số lượng theo chuyên ngành
                    int count = index == 0
                        ? allDoctors.length
                        : allDoctors
                              .where(
                                (d) =>
                                    d.maChuyenNganh == category.maChuyenNganh,
                              )
                              .length;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategoryIndex = index;
                          selectedDoctorIndex =
                              0; // Reset chọn item đầu tiên của tab mới
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0C5C4D)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${category.tenChuyenNganh} ($count)',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Danh sách hiển thị
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
                                final isSelected = selectedDoctorIndex == index;

                                final avatarBg = item.coCCHN
                                    ? const Color(0xFFD2F5EC)
                                    : const Color(0xFFFEF3C7);
                                final avatarText = item.coCCHN
                                    ? const Color(0xFF0C5C4D)
                                    : const Color(0xFFB45309);
                                final badgeBg = item.coCCHN
                                    ? const Color(0xFFE2F7F2)
                                    : const Color(0xFFFFFBEB);

                                return GestureDetector(
                                  onTap: () => setState(
                                    () => selectedDoctorIndex = index,
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF0C5C4D)
                                            : Colors.transparent,
                                        width: isSelected ? 2 : 0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Avatar
                                            Stack(
                                              children: [
                                                Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: avatarBg,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      item.initials,
                                                      style: TextStyle(
                                                        color: avatarText,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (item.coCCHN)
                                                  Positioned(
                                                    bottom: 0,
                                                    right: 0,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            2,
                                                          ),
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Colors.white,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                      child: const Icon(
                                                        Icons.check_circle,
                                                        color: Color(
                                                          0xFF0C5C4D,
                                                        ),
                                                        size: 14,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(width: 12),

                                            // Chi tiết
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.nguoiDung.hoTen,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: badgeBg,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          item.tenChuyenNganh,
                                                          style: TextStyle(
                                                            color: avatarText,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Icon(
                                                        Icons.star,
                                                        color: Colors.amber,
                                                        size: 12,
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        '${item.rating}',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.amber,
                                                        ),
                                                      ),
                                                      Text(
                                                        ' (${item.reviewsCount})',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .location_on_outlined,
                                                        size: 12,
                                                        color: Colors.grey,
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        item.formattedDistance,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      const Text(
                                                        '  •  ',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                      const Icon(
                                                        Icons.access_time,
                                                        size: 12,
                                                        color: Colors.grey,
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        item.timeArrival,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Radio Button
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? const Color(0xFF0C5C4D)
                                                      : Colors.grey[300]!,
                                                  width: isSelected ? 6 : 1.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          child: Divider(
                                            height: 1,
                                            color: Color(0xFFF1F5F9),
                                          ),
                                        ),

                                        // SĐT & Trạng thái
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.phone_outlined,
                                                    size: 12,
                                                    color: Colors.black54,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    item.nguoiDung.soDienThoai,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Spacer(),
                                            Row(
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Color(
                                                          0xFF10B981,
                                                        ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  item.coCCHN
                                                      ? 'Sẵn sàng ngay'
                                                      : 'Tình nguyện viên',
                                                  style: const TextStyle(
                                                    color: Color(0xFF10B981),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
