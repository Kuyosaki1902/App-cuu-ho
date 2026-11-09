// GiaoDienDangTimKiem.dart

import 'dart:io';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:cuhokhancap/user/ChonNguoiCuuHo/controllers/chon_nguoi_cuu_ho_controller.dart';
import 'package:cuhokhancap/user/ChonNguoiCuuHo/views/card_nguoi_cuu_ho.dart';
import 'package:cuhokhancap/user/ChonNguoiCuuHo/views/chuyen_nganh_filter.dart';
import 'package:cuhokhancap/user/GiaoDienDangTimKiem/GiaoDienDangTimKiem.dart';
import 'package:cuhokhancap/user/Models/mo_ta_tam_thoi.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class ChonBacSiTiepNhan extends StatefulWidget {
  final double banKinhQuet;
  const ChonBacSiTiepNhan({super.key, required this.banKinhQuet});

  @override
  State<ChonBacSiTiepNhan> createState() => _ChonBacSiTiepNhanState();
}

class _ChonBacSiTiepNhanState extends State<ChonBacSiTiepNhan> {
  final ChonNguoiCuuHoController _controller = ChonNguoiCuuHoController();
  final FirebaseService _firebaseService = FirebaseService();

  String maNguoiDungHienTai = '';
  Position? currentPosition;

  Set<String> selectedRescuerIds = {};
  int selectedCategoryIndex = 0; // 0: Tất Cả, 1: Có CCHN, 2: Không CCHN
  bool isLoading = true;

  // Biến phục vụ bộ lọc nâng cao
  String? filterHuong; // 'MoTa', 'ChuyenNganh', 'KyNang'
  String? filterKeyword;

  List<Map<String, dynamic>> allDoctors = [];

  @override
  void initState() {
    super.initState();
    _kiemTraVaKichHoatLuongMoTa();
    _khoiTaoDuLieu();
  }

  void _kiemTraVaKichHoatLuongMoTa() {
    bool coMoTaTuTruoc =
        (MoTaTamThoi.trieuChung != null &&
            MoTaTamThoi.trieuChung!.isNotEmpty) ||
        (MoTaTamThoi.moTaChiTiet != null &&
            MoTaTamThoi.moTaChiTiet!.isNotEmpty);
    if (coMoTaTuTruoc) {
      selectedCategoryIndex = 0;
      filterHuong = 'MoTa';
      filterKeyword = MoTaTamThoi.trieuChung?.join(' ') ?? '';
    }
  }

  Future<void> _khoiTaoDuLieu() async {
    setState(() => isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    maNguoiDungHienTai = prefs.getString('maNguoiDung_daLuu') ?? '';

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint("Không thể lấy GPS: $e");
    }

    if (currentPosition != null) {
      final result = await _controller.fetchNearbyDoctors(
        currentPosition!,
        widget.banKinhQuet,
      );

      if (mounted) {
        setState(() {
          allDoctors = result['doctors'] as List<Map<String, dynamic>>;
          isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Lọc danh sách theo Tab cố định và Bộ lọc nâng cao
  List<Map<String, dynamic>> get filteredDoctors {
    List<Map<String, dynamic>> list = allDoctors;

    // 1. Lọc theo Tab cố định
    if (selectedCategoryIndex == 1) {
      list = list.where((item) => item['coCCHN'] == true).toList();
    } else if (selectedCategoryIndex == 2) {
      list = list.where((item) => item['coCCHN'] == false).toList();
    }

    // 2. Lọc theo Bộ lọc phụ
    if (filterHuong != null) {
      if (filterHuong == 'MoTa') {
        // Luồng mô tả tự động lấy từ RAM
        String trieuChungStr =
            MoTaTamThoi.trieuChung?.join(' ').toLowerCase() ?? '';
        String chiTietStr = MoTaTamThoi.moTaChiTiet?.toLowerCase() ?? '';
        String fullMoTa = '$trieuChungStr $chiTietStr';

        if (fullMoTa.trim().isNotEmpty) {
          list = list.where((item) {
            String cn = (item['tenChuyenNganh'] ?? '').toString().toLowerCase();
            List<String> skills = List<String>.from(
              item['danhSachKyNang'] ?? [ ]);

            // Lọc 2 chiều: Chuyên ngành/Kỹ năng có nằm trong mô tả, hoặc mô tả có chứa Chuyên ngành/Kỹ năng
            bool matchCCHN =
                fullMoTa.contains(cn) || cn.contains(trieuChungStr);
            bool matchKyNang = skills.any((s) {
              String skillLower = s.toLowerCase();
              return fullMoTa.contains(skillLower) ||
                  skillLower.contains(trieuChungStr);
            });

            return matchCCHN || matchKyNang;
          }).toList();
        }
      } else if (filterKeyword != null && filterKeyword!.isNotEmpty) {
        // Xử lý từ khóa thủ công: Tách theo dấu phẩy nếu có
        String kwRaw = filterKeyword!.toLowerCase();
        List<String> keywords = kwRaw.contains(',')
            ? kwRaw
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
            : [kwRaw.trim()];

        list = list.where((item) {
          if (filterHuong == 'ChuyenNganh') {
            String cn = (item['tenChuyenNganh'] ?? '').toString().toLowerCase();
            // Khớp nếu chuyên ngành chứa từ khóa HOẶC từ khóa dài chứa chuyên ngành
            return keywords.any((kw) => cn.contains(kw) || kw.contains(cn));
          } else if (filterHuong == 'KyNang') {
            List<String> skills = List<String>.from(
              item['danhSachKyNang'] ?? [ ]);
            // Khớp nếu kỹ năng chứa từ khóa HOẶC từ khóa dài chứa kỹ năng
            return skills.any((s) {
              String skillLower = s.toLowerCase();
              return keywords.any(
                (kw) => skillLower.contains(kw) || kw.contains(skillLower),
              );
            });
          }
          return true;
        }).toList();
      }
    }

    return list;
  }

  void _showFilterBottomSheet() {
    bool coMoTaTuTruoc =
        (MoTaTamThoi.trieuChung != null &&
            MoTaTamThoi.trieuChung!.isNotEmpty) ||
        (MoTaTamThoi.moTaChiTiet != null &&
            MoTaTamThoi.moTaChiTiet!.isNotEmpty);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String? tempHuong = filterHuong;
        TextEditingController keywordCtrl = TextEditingController(
          text: filterKeyword ?? '',
        );

        if (tempHuong == 'MoTa' && !coMoTaTuTruoc) {
          tempHuong = null;
        }

        // 🌟 TỰ ĐỘNG CHỌN TIÊU CHÍ NẾU CHỈ CÓ 1 LỰA CHỌN DUY NHẤT VÀ CHƯA TỪNG CHỌN
        if (tempHuong == null && !coMoTaTuTruoc) {
          if (selectedCategoryIndex == 1) tempHuong = 'ChuyenNganh';
          if (selectedCategoryIndex == 2) tempHuong = 'KyNang';
        }

        // 🌟 TẠO HINT TEXT ĐỘNG DỰA THEO TAB VÀ TÌNH TRẠNG RAM
        List<String> hintParts = [];
        if (coMoTaTuTruoc) hintParts.add('Mô tả');
        if (selectedCategoryIndex != 2) hintParts.add('Chuyên ngành');
        if (selectedCategoryIndex != 1) hintParts.add('Kỹ năng');
        String dynamicHint = 'Chọn tiêu chí (${hintParts.join(' / ')})';

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bộ lọc nâng cao',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chọn tiêu chí lọc:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: tempHuong,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    hint: Text(
                      dynamicHint, // 🌟 Sử dụng Hint động
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    items: [
                      if (coMoTaTuTruoc)
                        const DropdownMenuItem(
                          value: 'MoTa',
                          child: Text(
                            'Mô Tả (Từ tình huống)',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      if (selectedCategoryIndex != 2)
                        const DropdownMenuItem(
                          value: 'ChuyenNganh',
                          child: Text(
                            'Chuyên Ngành',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      if (selectedCategoryIndex != 1)
                        const DropdownMenuItem(
                          value: 'KyNang',
                          child: Text(
                            'Kỹ Năng',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                    ],
                    onChanged: (val) {
                      setModalState(() {
                        tempHuong = val;
                        if (val == 'MoTa') {
                          keywordCtrl.text =
                              MoTaTamThoi.trieuChung?.join(', ') ??
                              'Dữ liệu từ mô tả';
                        } else if (val != filterHuong) {
                          keywordCtrl.text = '';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keywordCtrl,
                    enabled: tempHuong != 'MoTa',
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: tempHuong == 'MoTa'
                          ? 'Đang tự động dùng mô tả từ trang chủ'
                          : 'Nhập từ khóa cần tìm...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      filled: tempHuong == 'MoTa',
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              filterHuong = null;
                              filterKeyword = null;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Xóa lọc'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0C5C4D),
                          ),
                          onPressed: () {
                            setState(() {
                              filterHuong = tempHuong;
                              if (tempHuong == 'MoTa') {
                                filterKeyword =
                                    MoTaTamThoi.trieuChung?.join(' ') ?? '';
                                selectedCategoryIndex = 0;
                              } else {
                                filterKeyword = keywordCtrl.text;
                              }
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Áp dụng',
                            style: TextStyle(color: Colors.white),
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
    final doctors = filteredDoctors;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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

            ChuyenNganhFilterWidget(
              selectedCategoryIndex: selectedCategoryIndex,
              onCategorySelected: (index) {
                setState(() {
                  selectedCategoryIndex = index;

                  if (index == 2 && filterHuong == 'ChuyenNganh') {
                    filterHuong = null;
                    filterKeyword = null;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Đã tắt bộ lọc Chuyên ngành (không áp dụng cho Cứu Hộ Không Chứng Chỉ).',
                        ),
                      ),
                    );
                  } else if (index == 1 && filterHuong == 'KyNang') {
                    filterHuong = null;
                    filterKeyword = null;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Đã tắt bộ lọc Kỹ năng (không áp dụng cho Cứu Hộ Có Chứng Chỉ).',
                        ),
                      ),
                    );
                  }
                });
              },
              onFilterPressed: _showFilterBottomSheet,
            ),

            const SizedBox(height: 12),
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
                              final nguoiDung = item['nguoiDung'];
                              final String maBS = nguoiDung.maNguoiDung!;
                              final bool isSelected = selectedRescuerIds
                                  .contains(maBS);

                              return CardNguoiCuuHoWidget(
                                item: item,
                                isSelected: isSelected,
                                onTap: () {
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

                          if (context.mounted) Navigator.pop(context);

                          if (maYeuCauMoi != null) {
                            MoTaTamThoi.clear();
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GiaoDienDangTimKiem(
                                    maYeuCau: maYeuCauMoi,
                                    danhSachChiDinh: selectedRescuerIds
                                        .toList(),
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
