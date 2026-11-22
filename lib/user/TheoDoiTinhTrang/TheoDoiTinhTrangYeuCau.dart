// lib/user/TheoDoiTinhTrang/TheoDoiTinhTrangYeuCau.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cuhokhancap/user/TheoDoiTinhTrang/controllers/theo_doi_tinh_trang_controller.dart';
import 'package:cuhokhancap/user/ThongTInHoanThanhCuuHo/HoanThanhCuuHo.dart';
import 'package:cuhokhancap/user/GiaoDienDangTimKiem/GiaoDienDangTimKiem.dart';
import 'package:cuhokhancap/user/TongQuanBacSiTiepNhan/TongQuanBacSiTiepNhan.dart';
import 'package:cuhokhancap/user/GiaoDienDangTimKiem/service/yeu_cau_storage_service.dart';
import 'package:cuhokhancap/user/Models/yeucaucuuhomodel.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';
import 'package:cuhokhancap/user/Models/chitietmotahientruongmodel.dart';

class TheoDoiTinhTrangScreen extends StatefulWidget {
  final String maYeuCau;

  const TheoDoiTinhTrangScreen({super.key, required this.maYeuCau});

  @override
  State<TheoDoiTinhTrangScreen> createState() => _TheoDoiTinhTrangScreenState();
}

class _TheoDoiTinhTrangScreenState extends State<TheoDoiTinhTrangScreen> {
  late final TheoDoiTinhTrangController _controller;
  final Color primaryColor = const Color(0xFF00695C);

  @override
  void initState() {
    super.initState();
    _controller = TheoDoiTinhTrangController(maYeuCau: widget.maYeuCau);
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} - ${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}";
  }

  // 🌟 Hàm helper giải mã Avatar (Hỗ trợ cả URL HTTP lẫn chuỗi Base64 từ LuuAnh)
  ImageProvider? _decodeAvatarProvider(String? rawAvatar) {
    if (rawAvatar == null || rawAvatar.trim().isEmpty) return null;
    final cleaned = rawAvatar.trim();
    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      return NetworkImage(cleaned);
    }
    try {
      final base64Part = cleaned.contains(',')
          ? cleaned.split(',').last.trim()
          : cleaned;
      return MemoryImage(base64Decode(base64Part));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F9),
        appBar: AppBar(
          title: const Text(
            'Chi tiết yêu cầu',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context); // Lệnh quay lại màn hình trước
            },
          ),
          elevation: 0,
        ),
        body: ValueListenableBuilder<Map<String, dynamic>?>(
          valueListenable: _controller.requestDataNotifier,
          builder: (context, data, child) {
            if (data == null) {
              return Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            if (data['isError'] == true) {
              return _buildLoadErrorState();
            }

            if (data['isEmpty'] == true) {
              return _buildErrorState(context);
            }

            // Unpack Data
            final YeuCauCuuHoModel yeuCau = data['yeuCau'];
            final NguoiDungModel? nanNhan = data['nanNhan'];
            final ChiTietMoTaHienTruongModel? moTa = data['moTa'];
            final List<Map<String, dynamic>> listCuuHo = data['listCuuHo'];

            final st = yeuCau.maTinhTrangYeuCau;
            bool choTiepNhan = st == 'user_tinhtrang_chotiepnhan';
            bool daPhanCong = st == 'user_tinhtrang_daphancong';
            bool daHoanThanh = st == 'user_tinhtrang_hoanthanh';

            // Chỉ true khi có ít nhất 1 cứu hộ viên đã hoàn thành
            bool hasCompletedRescuer = listCuuHo.any(
              (item) =>
                  item['trangThai'] == 'cuuho_trangthai_phancong_hoanthanh',
            );

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- 1. THẺ TRẠNG THÁI ---
                        _buildStatusCard(yeuCau, choTiepNhan, daHoanThanh),

                        const SizedBox(height: 16),

                        // --- 2. THẺ THÔNG TIN NẠN NHÂN & MÔ TẢ ---
                        _buildVictimInfoCard(yeuCau, nanNhan, moTa),

                        const SizedBox(height: 16),

                        // --- 3. DANH SÁCH LỰC LƯỢNG CỨU HỘ ---
                        if (listCuuHo.isNotEmpty)
                          _buildRescuerListCard(listCuuHo),
                      ],
                    ),
                  ),
                ),

                // --- 4. THANH NÚT CHỨC NĂNG CỐ ĐỊNH Ở ĐÁY ---
                _buildBottomActions(
                  yeuCau,
                  choTiepNhan,
                  daPhanCong,
                  daHoanThanh,
                  hasCompletedRescuer,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // UI: Thẻ trạng thái đơn
  Widget _buildStatusCard(
    YeuCauCuuHoModel yeuCau,
    bool choTiepNhan,
    bool daHoanThanh,
  ) {
    final st = yeuCau.maTinhTrangYeuCau;
    final bool quaHan = st == 'user_tinhtrang_quahandieuphoi';
    final bool daHuy = st == 'user_tinhtrang_dahuy';

    Color statusColor = quaHan
        ? Colors.red
        : daHuy
        ? Colors.grey
        : choTiepNhan
        ? Colors.orange
        : (daHoanThanh ? Colors.blue : primaryColor);

    IconData statusIcon = quaHan
        ? Icons.error_outline
        : daHuy
        ? Icons.cancel_outlined
        : choTiepNhan
        ? Icons.hourglass_empty
        : (daHoanThanh ? Icons.check_circle : Icons.directions_run);

    String statusText = quaHan
        ? 'QUÁ HẠN ĐIỀU PHỐI - KHÔNG CÓ AI TIẾP NHẬN'
        : daHuy
        ? 'ĐƠN ĐÃ HỦY'
        : choTiepNhan
        ? 'ĐANG CHỜ TIẾP NHẬN'
        : (daHoanThanh ? 'ĐÃ HOÀN THÀNH' : 'ĐANG TRONG QUÁ TRÌNH CỨU HỘ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: statusColor, width: 6)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          _buildInfoRow('Mã yêu cầu', yeuCau.maYeuCau),
          _buildInfoRow('Thời gian tạo', _formatTime(yeuCau.thoiGianTao)),
          _buildInfoRow(
            'Mức độ khẩn cấp',
            yeuCau.maLoaiYeuCau == 'loaiyeucau_sos'
                ? 'SOS (Rất nguy kịch)'
                : 'Hỗ trợ y tế',
            valueColor: yeuCau.maLoaiYeuCau == 'loaiyeucau_sos'
                ? Colors.red
                : Colors.orange,
          ),
        ],
      ),
    );
  }

  // UI: Thẻ thông tin Nạn nhân & Chi tiết triệu chứng
  Widget _buildVictimInfoCard(
    YeuCauCuuHoModel yeuCau,
    NguoiDungModel? nanNhan,
    ChiTietMoTaHienTruongModel? moTa,
  ) {
    List<String> trieuChung = [];
    String ghiChuThem = "Không có";

    if (moTa != null && moTa.ghiChuText is Map) {
      final rawTc = moTa.ghiChuText['trieuChung'];
      trieuChung = rawTc is List
          ? rawTc.map((e) => e.toString()).toList()
          : <String>[];
      ghiChuThem = (moTa.ghiChuText['moTaChiTiet'] ?? "Không có").toString();

      if (ghiChuThem.isEmpty) {
        ghiChuThem = "Không có";
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THÔNG TIN NGƯỜI CẦN HỖ TRỢ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),

          _buildInfoRow('Họ và tên', nanNhan?.hoTen ?? 'Đang tải...'),
          _buildInfoRow('Số điện thoại', nanNhan?.soDienThoai ?? 'Đang tải...'),
          const Divider(height: 24),

          const Text(
            'TRIỆU CHỨNG LÂM SÀNG:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),

          trieuChung.isNotEmpty
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: trieuChung
                      .map(
                        (tc) => Chip(
                          label: Text(tc, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.red.shade50,
                          side: BorderSide.none,
                        ),
                      )
                      .toList(),
                )
              : const Text(
                  'Không có triệu chứng được chọn.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),

          const SizedBox(height: 16),

          const Text(
            'GHI CHÚ THÊM:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),

          Text(ghiChuThem, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  // UI: Thẻ danh sách Lực lượng cứu hộ
  Widget _buildRescuerListCard(List<Map<String, dynamic>> listCuuHo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LỰC LƯỢNG ĐÃ TIẾP NHẬN (${listCuuHo.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),

          ...listCuuHo.map((item) {
            NguoiDungModel user = item['user'];
            String? avatarRaw = item['avatar'];
            final avatarProvider = _decodeAvatarProvider(avatarRaw);

            String status = 'Đang di chuyển';
            Color statusColor = Colors.orange;

            switch (item['trangThai']) {
              case 'cuuho_trangthai_phancong_daden':
                status = 'Đã đến nơi';
                statusColor = Colors.green;
                break;
              case 'cuuho_trangthai_phancong_dangcuuho':
                status = 'Đang tiến hành cứu hộ';
                statusColor = Colors.deepOrange;
                break;
              case 'cuuho_trangthai_phancong_hoanthanh':
                status = 'Đã hoàn thành cứu hộ';
                statusColor = Colors.blueAccent;
                break;
            }

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.1),
                // 🌟 Sử dụng provider đã giải mã (hỗ trợ cả URL lẫn Base64)
                backgroundImage: avatarProvider,
                child: (avatarProvider == null)
                    ? Icon(Icons.person, color: primaryColor)
                    : null,
              ),
              title: Text(
                user.hoTen,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                status,
                style: TextStyle(color: statusColor, fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.phone, color: Colors.green),
                onPressed: () {},
              ),
            );
          }),
        ],
      ),
    );
  }

  // UI: Cụm nút hành động cố định ở đáy
  // UI: Cụm nút hành động cố định ở đáy
  Widget _buildBottomActions(
    YeuCauCuuHoModel yeuCau,
    bool choTiepNhan,
    bool daPhanCong,
    bool daHoanThanh,
    bool hasCompletedRescuer,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (yeuCau.maTinhTrangYeuCau == 'user_tinhtrang_quahandieuphoi' ||
                yeuCau.maTinhTrangYeuCau == 'user_tinhtrang_dahuy')
              _buildActionButton(
                icon: Icons.home_rounded,
                label: 'Về trang chủ',
                color: primaryColor,
                onPressed: () async {
                  await YeuCauStorageService.clearActiveRequest();
                  if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
                },
              )
            else if (choTiepNhan)
              _buildActionButton(
                icon: Icons.search_rounded,
                label: 'Quay lại tìm kiếm cứu hộ viên',
                color: Colors.orange,
                onPressed: () {
                  final chiDinhIds = yeuCau.danhSachPhanCongVien.entries
                      .where(
                        (e) =>
                            e.value != 'cuuho_trangthai_phancong_tuchoi' &&
                            e.value != 'cuuho_trangthai_phancong_dahuy',
                      )
                      .map((e) => e.key)
                      .toList();

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GiaoDienDangTimKiem(
                        maYeuCau: yeuCau.maYeuCau,
                        danhSachChiDinh: chiDinhIds.isNotEmpty
                            ? chiDinhIds
                            : null,
                      ),
                    ),
                  );
                },
              )
            else if (daPhanCong)
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.map_outlined,
                      label: 'Xem chi tiết',
                      color: primaryColor,
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TongQuanBacSiTiepNhan(
                              maYeuCau: yeuCau.maYeuCau,
                              currentUserId: yeuCau.maNguoiYeuCau,
                              victimLat: yeuCau.viDo,
                              victimLng: yeuCau.kinhDo,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (hasCompletedRescuer) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.check_circle_outline,
                        label: 'Hoàn thành cứu hộ',
                        color: Colors.blueAccent,
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HoanThanhDonCuuHoScreen(
                                maYeuCau: yeuCau.maYeuCau,
                                currentUserId: yeuCau.maNguoiYeuCau,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              )
            else if (daHoanThanh)
              _buildActionButton(
                icon: Icons.star_rate,
                label: 'Hoàn thành & Đánh giá chuyến',
                color: Colors.blueAccent,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HoanThanhDonCuuHoScreen(
                        maYeuCau: yeuCau.maYeuCau,
                        currentUserId: yeuCau.maNguoiYeuCau,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        icon: Icon(icon, color: Colors.white, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildLoadErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Không tải được thông tin đơn cứu hộ.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: _controller.restart,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Đơn cứu hộ đã bị hủy hoặc không tồn tại.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await YeuCauStorageService.clearActiveRequest();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Quay về trang chủ'),
          ),
        ],
      ),
    );
  }
}
