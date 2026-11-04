// GiaoDienDangTimKiem.dart

import 'dart:io';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:cuhokhancap/user/ChonNguoiCuuHo/controllers/chon_nguoi_cuu_ho_controller.dart';
import 'package:cuhokhancap/user/ChonNguoiCuuHo/views/card_nguoi_cuu_ho.dart';
import 'package:cuhokhancap/user/ChonNguoiCuuHo/views/chuyen_nganh_filter.dart';
import 'package:cuhokhancap/user/GiaoDienDangTimKiem/GiaoDienDangTimKiem.dart';
import 'package:cuhokhancap/user/Models/mo_ta_tam_thoi.dart'; // 🌟 Đã import MoTaTamThoi
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class ChonBacSiTiepNhan extends StatefulWidget {
  final double banKinhQuet;
  // 🌟 KHÔNG CẦN TRUYỀN dsNguoiCuuHo VÀO NỮA
  const ChonBacSiTiepNhan({super.key, required this.banKinhQuet});

  @override
  State<ChonBacSiTiepNhan> createState() => _ChonBacSiTiepNhanState();
}

class _ChonBacSiTiepNhanState extends State<ChonBacSiTiepNhan> {
  final ChonNguoiCuuHoController _controller = ChonNguoiCuuHoController();
  final FirebaseService _firebaseService = FirebaseService();

  String maNguoiDungHienTai = '';
  Position? currentPosition;

  // 🌟 Biến lưu danh sách mã cứu hộ viên được chọn (Tối đa 3)
  Set<String> selectedRescuerIds = {};
  int selectedCategoryIndex = 0;
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
    _khoiTaoDuLieu(); // 🌟 Đã sửa thành gọi hàm _khoiTaoDuLieu
  }

  // 🌟 HÀM TỰ KHỞI TẠO DỮ LIỆU
  Future<void> _khoiTaoDuLieu() async {
    setState(() => isLoading = true);

    // 1. Lấy mã người dùng từ SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    maNguoiDungHienTai = prefs.getString('maNguoiDung_daLuu') ?? '';

    // 2. Lấy tọa độ GPS (Đảm bảo đã cấp quyền)
    try {
      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint("Không thể lấy GPS: $e");
    }
    // 3. Tự động lấy danh sách bác sĩ xung quanh tọa độ hiện tại
    if (currentPosition != null) {
      final result = await _controller.fetchNearbyDoctors(
        currentPosition!,
        widget.banKinhQuet,
      );

      if (mounted) {
        setState(() {
          allDoctors = result['doctors'] as List<ItemNguoiCuuHo>;
          dsChuyenNganh = result['categories'] as List<ChuyenNganhModel>;
          isLoading = false;
        });
      }
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
      backgroundColor: const Color(0xFFF8FAFC), // Đưa màu nền ra Scaffold luôn
      body: SafeArea(
        child: Column(
          children: [
            // Thanh gạch xám (có thể bỏ luôn cũng được vì đã có AppBar/Header)
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: doctors.length,
                            itemBuilder: (context, index) {
                              final item = doctors[index];
                              final String maBS = item.nguoiDung.maNguoiDung!;
                              // 🌟 Kiểm tra mã Bác sĩ có nằm trong Set không
                              final bool isSelected = selectedRescuerIds
                                  .contains(maBS);

                              return CardNguoiCuuHoWidget(
                                item: item,
                                isSelected: isSelected,
                                onTap: () {
                                  // 🌟 Logic chọn tối đa 3 người
                                  setState(() {
                                    if (isSelected) {
                                      selectedRescuerIds.remove(maBS);
                                    } else {
                                      if (selectedRescuerIds.length < 3) {
                                        selectedRescuerIds.add(maBS);
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Chỉ được chọn tối đa 3 người cứu hộ!',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  });
                                },
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
                  onPressed: selectedRescuerIds.isNotEmpty
                      ? () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          // 1. GỌI HÀM TẠO ĐƠN & MÔ TẢ TỪ RAM
                          String? maYeuCauMoi = await _firebaseService
                              .taoYeuCauTimBacSiTuDong(
                                maNguoiYeuCau: maNguoiDungHienTai,
                                viDo: currentPosition?.latitude ?? 0.0,
                                kinhDo: currentPosition?.longitude ?? 0.0,
                                trieuChung: MoTaTamThoi.trieuChung,
                                moTaChiTiet: MoTaTamThoi.moTaChiTiet,
                                fileAnh: MoTaTamThoi.fileAnh,
                                fileGhiAm: MoTaTamThoi.fileGhiAm,
                                maLoaiYeuCau: 'loaiyeucau_choncuuhovien',
                              );

                          if (context.mounted) {
                            Navigator.pop(context); // Tắt loading
                          }

                          if (maYeuCauMoi != null) {
                            MoTaTamThoi.clear();
                            // 2. TRUYỀN MÃ YÊU CẦU + DANH SÁCH BÁC SĨ SANG MÀN HÌNH TÌM KIẾM
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GiaoDienDangTimKiem(
                                    maYeuCau: maYeuCauMoi,
                                    danhSachChiDinh: selectedRescuerIds
                                        .toList(), // 🌟 Đẩy mảng qua
                                  ),
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Có lỗi xảy ra khi tạo yêu cầu. Vui lòng thử lại!',
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      : null,
                  // 🌟 Khôi phục lại icon và text cho nút bị tàng hình
                  icon: const Icon(
                    Icons.send_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    selectedRescuerIds.isNotEmpty
                        ? 'XÁC NHẬN CHỌN (${selectedRescuerIds.length})'
                        : 'XÁC NHẬN CHỌN',
                    style: const TextStyle(
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
    );
  }
}
