import 'package:cuhokhancap/user/Models/danhgiamodel.dart';
import 'package:cuhokhancap/user/ThongTInHoanThanhCuuHo/controllers/hoan_thanh_don_controller.dart';
import 'package:flutter/material.dart';
import 'package:cuhokhancap/user/GiaoDienDangTimKiem/service/yeu_cau_storage_service.dart';

class HoanThanhDonCuuHoScreen extends StatefulWidget {
  final String maYeuCau;
  final String currentUserId; // Bác nhớ truyền mã ID người đang dùng nhé

  const HoanThanhDonCuuHoScreen({
    super.key,
    required this.maYeuCau,
    required this.currentUserId,
  });

  @override
  State<HoanThanhDonCuuHoScreen> createState() =>
      _HoanThanhDonCuuHoScreenState();
}

class _HoanThanhDonCuuHoScreenState extends State<HoanThanhDonCuuHoScreen> {
  final Color primaryColor = const Color(0xFF006A55);
  late final HoanThanhDonController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HoanThanhDonController(
      maYeuCau: widget.maYeuCau,
      currentUserId: widget.currentUserId,
    );
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 🌟 Khóa nút back hệ thống
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Có thể hiển thị hướng dẫn ép người dùng hoàn tất hoặc về trang chủ qua nút bấm
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black87,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Hoàn Thành Đơn Cứu Hộ',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // [Phần 1: Khối thông tin đơn - Bác giữ nguyên code UI của phần này]
              _buildThongTinDonWidget(),

              const SizedBox(height: 24),
              const Text(
                '👥 Đội ngũ ứng cứu',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // DANH SÁCH CỨU HỘ VIÊN & FORM ĐÁNH GIÁ
              ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: _controller.danhSachPhanCongNotifier,
                builder: (context, danhSach, child) {
                  if (danhSach.isEmpty)
                    return const Center(child: Text("Đang tải dữ liệu..."));

                  return ValueListenableBuilder<List<DanhGiaModel>>(
                    valueListenable: _controller.danhGiaNotifier,
                    builder: (context, danhSachDanhGia, child) {
                      return Column(
                        children: danhSach.map((thanhVien) {
                          String maNguoiCuuHo = thanhVien['maNguoiCuuHo'];
                          String trangThaiTuyen =
                              thanhVien['maTrangThaiTiepNhan'];

                          // Kiểm tra xem đã có đánh giá cho người này chưa
                          var danhGiaCaNhan = danhSachDanhGia
                              .where((dg) => dg.maNguoiCuuHo == maNguoiCuuHo)
                              .toList();
                          bool isEvaluated = danhGiaCaNhan.isNotEmpty;
                          DanhGiaModel? dGia = isEvaluated
                              ? danhGiaCaNhan.first
                              : null;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildMemberCard(
                              context,
                              maNguoiCuuHo: maNguoiCuuHo,
                              name:
                                  'Đang tải tên...', // Bác có thể ghép FutureBuilder gọi NguoiDungModel để lấy Tên thật
                              roleBadge: 'Lực lượng cứu hộ',
                              roleBadgeColor: primaryColor,
                              isMainRoleColor: true,
                              subTitle: 'Mã: $maNguoiCuuHo',
                              completedTime:
                                  trangThaiTuyen ==
                                      'cuuho_trangthai_phancong_hoanthanh'
                                  ? 'Đã báo cáo hoàn thành'
                                  : 'Đang thực hiện nhiệm vụ',
                              isEvaluated: isEvaluated,
                              ratingStars: dGia?.diemDanhGia ?? 0,
                              comment: dGia?.nhanXet ?? '',
                            ),
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 28),

              // NÚT HOÀN THÀNH (Bị disable nếu cứu hộ chưa xác nhận)
              ValueListenableBuilder<bool>(
                valueListenable: _controller.isButtonEnabledNotifier,
                builder: (context, isEnabled, child) {
                  return Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEnabled
                              ? primaryColor
                              : Colors.grey,
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: Text(
                          isEnabled
                              ? 'Xác nhận hoàn thành đơn cứu hộ'
                              : 'Chờ cứu hộ xác nhận trước...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        onPressed: isEnabled
                            ? () async {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                bool success = await _controller
                                    .hoanThanhChuyenDi();
                                // 🌟 XÓA LOCAL STORAGE ĐỂ APP KHÔNG TỰ ĐỘNG VÀO TRANG NÀY NỮA
                                await YeuCauStorageService.clearActiveRequest();

                                if (context.mounted) {
                                  Navigator.pop(context); // Tắt loading
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Chuyến đi đã hoàn tất!'),
                                      ),
                                    );
                                    // Đá văng ra ngoài trang chủ
                                    Navigator.popUntil(
                                      context,
                                      (route) => route.isFirst,
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Lỗi khi hoàn thành chuyến đi!',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            : null, // null thì nút sẽ bị mờ và không bấm được
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Thẻ Thành Viên
  Widget _buildMemberCard(
    BuildContext context, {
    required String maNguoiCuuHo,
    required String name,
    required String roleBadge,
    required Color roleBadgeColor,
    required bool isMainRoleColor,
    required String subTitle,
    required String completedTime,
    required bool isEvaluated,
    int ratingStars = 0,
    String comment = '',
  }) {
    // Biến state cục bộ cho TextField đánh giá
    int currentRating = 5;
    TextEditingController nhanXetController = TextEditingController();

    return StatefulBuilder(
      builder: (context, setStateCard) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Dòng 1 & 2 (Giữ nguyên UI của bác)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(
                        'https://via.placeholder.com/150',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          completedTime,
                          style: TextStyle(
                            fontSize: 11,
                            color: completedTime.contains('Đã')
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Color(0xFFF0F0F0)),
              ),

              // 2. Khu vực Đánh Giá
              if (isEvaluated)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Đã đánh giá:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: List.generate(
                              ratingStars,
                              (index) => const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (comment.isNotEmpty)
                        Text(
                          comment,
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade800,
                          ),
                        ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      // RATING STARS TƯƠNG TÁC ĐƯỢC
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                          (index) => GestureDetector(
                            onTap: () =>
                                setStateCard(() => currentRating = index + 1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                              ),
                              child: Icon(
                                Icons.star_rounded,
                                color: index < currentRating
                                    ? Colors.amber
                                    : Colors.grey.shade300,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: nhanXetController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Nhập nhận xét...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            bool ok = await _controller.submitDanhGia(
                              maNguoiCuuHo,
                              currentRating,
                              nhanXetController.text,
                            );
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã gửi đánh giá thành công'),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Gửi đánh giá',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Khối thông tin tĩnh (Bác có thể lấy từ Firebase sau)
  Widget _buildThongTinDonWidget() {
    return Container(
      // Giữ nguyên đoạn code Khối màu xanh của bác ở trên đây...
      child: const Text("Khối thông tin đơn (UI cũ)"),
    );
  }
}
