import 'dart:convert';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:cuhokhancap/user/GiaoDienDangTimKiem/service/yeu_cau_storage_service.dart';
import 'package:cuhokhancap/user/Models/danhgiamodel.dart';
import 'package:cuhokhancap/user/Models/hosocuuhococchnmodel.dart';
import 'package:cuhokhancap/user/Models/hosocuuhokhongcchnmodel.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';
import 'package:cuhokhancap/user/Models/yeucaucuuhomodel.dart';
import 'package:cuhokhancap/user/ThongTInHoanThanhCuuHo/controllers/hoan_thanh_don_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HoanThanhDonCuuHoScreen extends StatefulWidget {
  final String maYeuCau;
  final String currentUserId;

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
  final FirebaseService _fbService = FirebaseService();

  final Map<String, int> _selectedRatings = {};
  final Map<String, String> _draftComments = {};

  late final Future<Map<String, dynamic>> _orderHeaderFuture;
  final Map<String, Future<Map<String, dynamic>>> _rescuerDetailFutures = {};

  @override
  void initState() {
    super.initState();
    _controller = HoanThanhDonController(
      maYeuCau: widget.maYeuCau,
      currentUserId: widget.currentUserId,
    );
    _controller.init();
    _orderHeaderFuture = _loadOrderHeaderData();
  }

  Future<Map<String, dynamic>> _loadOrderHeaderData() async {
    final results = await Future.wait([
      _fbService.getYeuCauCuuHoById(widget.maYeuCau),
      _fbService.getUserById(widget.currentUserId),
    ]);

    final YeuCauCuuHoModel? yeuCau = results[0] as YeuCauCuuHoModel?;
    final NguoiDungModel? nanNhan = results[1] as NguoiDungModel?;

    String diaChiThucTe = 'Vị trí hiện trường GPS';
    if (yeuCau != null && (yeuCau.viDo != 0.0 || yeuCau.kinhDo != 0.0)) {
      diaChiThucTe = await _fbService.getAddressFromLatLng(
        yeuCau.viDo,
        yeuCau.kinhDo,
      );
    }

    return {'yeuCau': yeuCau, 'nanNhan': nanNhan, 'diaChi': diaChiThucTe};
  }

  Future<Map<String, dynamic>> _getRescuerDetailFuture(String maNguoiCuuHo) {
    return _rescuerDetailFutures.putIfAbsent(maNguoiCuuHo, () async {
      final results = await Future.wait([
        _fbService.getUserById(maNguoiCuuHo),
        _fbService.getUserAvatarUrl(maNguoiCuuHo),
        _fbService.getHoSoCoCCHN(maNguoiCuuHo),
        _fbService.getHoSoKhongCCHN(maNguoiCuuHo),
        _fbService.getSkillIdsByUserId(maNguoiCuuHo),
      ]);

      final NguoiDungModel? user = results[0] as NguoiDungModel?;
      final String? avatarRaw = results[1] as String?;
      final HoSoCuuHoCoCCHNModel? hoSoCo = results[2] as HoSoCuuHoCoCCHNModel?;
      final HoSoCuuHoKhongCCHNModel? hoSoKhong =
          results[3] as HoSoCuuHoKhongCCHNModel?;
      final List<String> skillIds = results[4] as List<String>;

      String specialtyText = 'Đội ngũ sơ cứu & cấp cứu ngoại viện';
      if (hoSoCo != null) {
        final parts = <String>[];
        if (hoSoCo.chucDanh.isNotEmpty) parts.add(hoSoCo.chucDanh);
        if (hoSoCo.donViCongTac.isNotEmpty) parts.add(hoSoCo.donViCongTac);
        if (parts.isNotEmpty) specialtyText = parts.join(' • ');
      } else if (hoSoKhong != null &&
          hoSoKhong.doiNhom != null &&
          hoSoKhong.doiNhom!.isNotEmpty) {
        specialtyText = hoSoKhong.doiNhom!;
      } else if (skillIds.isNotEmpty) {
        final skillNames = await _fbService.getSkillNamesByIds(skillIds);
        if (skillNames.isNotEmpty) {
          final firstSkill = skillNames.first;
          specialtyText =
              'Kỹ năng: ${firstSkill[0].toUpperCase()}${firstSkill.substring(1)}';
        }
      }

      return {
        'user': user,
        'avatarRaw': avatarRaw,
        'specialty': specialtyText,
        'hasCCHN': hoSoCo != null,
      };
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ImageProvider? _decodeAvatar(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final cleaned = raw.trim();
    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      return NetworkImage(cleaned);
    }
    try {
      final base64Str = cleaned.contains(',')
          ? cleaned.split(',').last.trim()
          : cleaned;
      return MemoryImage(base64Decode(base64Str));
    } catch (_) {
      return null;
    }
  }

  String _formatLoaiYeuCau(String maLoai) {
    final lower = maLoai.toLowerCase();
    if (lower.contains('sos')) return 'Cấp cứu khẩn cấp SOS';
    if (lower.contains('timtudong')) return 'Cấp cứu y tế tự động';
    if (lower.contains('noikhoa') || lower.contains('yte')) {
      return 'Cấp cứu nội khoa';
    }
    if (lower.contains('tainan')) return 'Tai nạn giao thông';
    if (lower.contains('chayno') || lower.contains('hoahoan')) {
      return 'Hỏa hoạn & Bỏng';
    }
    return maLoai.isNotEmpty ? maLoai : 'Cấp cứu nội khoa';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Hoàn Thành Đơn Cứu Hộ',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThongTinDonWidget(),
              const SizedBox(height: 22),
              ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: _controller.danhSachPhanCongNotifier,
                builder: (context, danhSach, _) {
                  final bool coNguoiHoanThanh = danhSach.any((p) {
                    final st = (p['maTrangThaiTiepNhan'] ?? '')
                        .toString()
                        .trim();
                    return st == 'cuuho_trangthai_phancong_hoanthanh' ||
                        st == 'hoanthanh';
                  });

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Đội ngũ ứng cứu (${danhSach.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      if (coNguoiHoanThanh)
                        Text(
                          'Đánh giá từng thành viên',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<bool>(
                valueListenable: _controller.isLoadingNotifier,
                builder: (context, isLoading, _) {
                  return ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: _controller.danhSachPhanCongNotifier,
                    builder: (context, danhSach, child) {
                      if (isLoading && danhSach.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (danhSach.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'Chưa có cứu hộ viên nào trong đơn này.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      return ValueListenableBuilder<List<DanhGiaModel>>(
                        valueListenable: _controller.danhGiaNotifier,
                        builder: (context, danhSachDanhGia, child) {
                          return Column(
                            children: List.generate(danhSach.length, (index) {
                              final thanhVien = danhSach[index];
                              final bool isLeader = index == 0;
                              String maNguoiCuuHo =
                                  thanhVien['maNguoiCuuHo'] ?? '';
                              String trangThaiTuyen =
                                  (thanhVien['maTrangThaiTiepNhan'] ?? '')
                                      .toString()
                                      .trim();

                              var danhGiaCaNhan = danhSachDanhGia
                                  .where(
                                    (dg) => dg.maNguoiCuuHo == maNguoiCuuHo,
                                  )
                                  .toList();
                              bool isSubmitted = danhGiaCaNhan.isNotEmpty;
                              DanhGiaModel? dGia = isSubmitted
                                  ? danhGiaCaNhan.first
                                  : null;

                              return FutureBuilder<Map<String, dynamic>>(
                                future: _getRescuerDetailFuture(maNguoiCuuHo),
                                builder: (context, snap) {
                                  final NguoiDungModel? user =
                                      snap.data?['user'] as NguoiDungModel?;
                                  final String? avatarRaw =
                                      snap.data?['avatarRaw'] as String?;
                                  final String specialty =
                                      (snap.data?['specialty'] as String?) ??
                                      'Đội ngũ cấp cứu ngoại viện';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _buildMemberCard(
                                      context,
                                      isLeader: isLeader,
                                      maNguoiCuuHo: maNguoiCuuHo,
                                      name: user?.hoTen ?? 'Cứu hộ viên',
                                      specialty: specialty,
                                      phone:
                                          (user != null &&
                                              user.soDienThoai.isNotEmpty)
                                          ? user.soDienThoai
                                          : 'Chưa cập nhật SĐT',
                                      avatarRaw: avatarRaw,
                                      isDone:
                                          trangThaiTuyen ==
                                              'cuuho_trangthai_phancong_hoanthanh' ||
                                          trangThaiTuyen == 'hoanthanh',
                                      isSubmitted: isSubmitted,
                                      submittedStars: dGia?.diemDanhGia ?? 0,
                                      submittedComment: dGia?.nhanXet ?? '',
                                    ),
                                  );
                                },
                              );
                            }),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: _controller.danhSachPhanCongNotifier,
                builder: (context, danhSach, _) {
                  final int tongNguoi = danhSach.length;
                  final int soNguoiDaXong = danhSach.where((p) {
                    final st = (p['maTrangThaiTiepNhan'] ?? '')
                        .toString()
                        .trim();
                    return st == 'cuuho_trangthai_phancong_hoanthanh' ||
                        st == 'hoanthanh';
                  }).length;

                  return ValueListenableBuilder<bool>(
                    valueListenable: _controller.isButtonEnabledNotifier,
                    builder: (context, isEnabled, child) {
                      final String buttonLabel = isEnabled
                          ? 'Xác nhận hoàn thành đơn cứu hộ'
                          : (tongNguoi > 0
                                ? 'Chờ tất cả cứu hộ hoàn thành ($soNguoiDaXong/$tongNguoi)...'
                                : 'Chờ cứu hộ xác nhận hoàn thành...');

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEnabled
                                ? primaryColor
                                : Colors.grey.shade400,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: Text(
                            buttonLabel,
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
                                      .hoanThanhVaGuiTatCaDanhGia(
                                        selectedRatings: _selectedRatings,
                                        draftComments: _draftComments,
                                      );

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    if (success) {
                                      await YeuCauStorageService.clearActiveRequest();
                                      ScaffoldMessenger.of(context)
                                        ..clearSnackBars()
                                        ..showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Đã hoàn tất đơn cứu hộ và gửi đánh giá!',
                                            ),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      Navigator.popUntil(
                                        context,
                                        (route) => route.isFirst,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Vẫn còn cứu hộ viên chưa hoàn thành nhiệm vụ!',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              : null,
                        ),
                      );
                    },
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

  Widget _buildThongTinDonWidget() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _orderHeaderFuture,
      builder: (context, snapshot) {
        final YeuCauCuuHoModel? yeuCau =
            snapshot.data?['yeuCau'] as YeuCauCuuHoModel?;
        final NguoiDungModel? nanNhan =
            snapshot.data?['nanNhan'] as NguoiDungModel?;
        final String diaChi =
            (snapshot.data?['diaChi'] as String?) ?? 'Đang tải vị trí...';

        final String maHienThi = widget.maYeuCau.length > 8
            ? '#${widget.maYeuCau.substring(widget.maYeuCau.length - 6).toUpperCase()}'
            : '#${widget.maYeuCau.toUpperCase()}';

        final String loaiCapCuu = _formatLoaiYeuCau(yeuCau?.maLoaiYeuCau ?? '');
        final String mucDoUuTien = 'Ưu tiên ${yeuCau?.mucDoKhanCap ?? 1}';
        final String tenNanNhan = nanNhan?.hoTen ?? 'Nạn nhân';

        final DateTime thoiGianTao = yeuCau?.thoiGianTao ?? DateTime.now();
        final DateTime thoiGianKetThuc =
            yeuCau?.thoiGianHoanThanh ?? DateTime.now();
        final String formattedTime = DateFormat(
          'HH:mm - dd/MM',
        ).format(thoiGianTao);

        int diffMinutes = thoiGianKetThuc.difference(thoiGianTao).inMinutes;
        if (diffMinutes < 1) diffMinutes = 1;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      maHienThi,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loaiCapCuu,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            diaChi,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            mucDoUuTien,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nạn nhân',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    Text(
                                      tenNanNhan,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Thời gian tạo',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    Text(
                                      formattedTime,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tổng thời gian can thiệp:',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const Spacer(),
                  Text(
                    '$diffMinutes phút',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMemberCard(
    BuildContext context, {
    required bool isLeader,
    required String maNguoiCuuHo,
    required String name,
    required String specialty,
    required String phone,
    String? avatarRaw,
    required bool isDone,
    required bool isSubmitted,
    int submittedStars = 0,
    String submittedComment = '',
  }) {
    final avatarProvider = _decodeAvatar(avatarRaw);
    final int currentStars = isSubmitted
        ? submittedStars
        : (_selectedRatings[maNguoiCuuHo] ?? 5);
    final String displayComment = isSubmitted
        ? submittedComment
        : (_draftComments[maNguoiCuuHo] ?? '');
    final String timeNowStr = DateFormat('HH:mm').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: primaryColor,
                backgroundImage: avatarProvider,
                child: avatarProvider == null
                    ? Text(
                        name.isNotEmpty
                            ? name.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
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
                        fontSize: 15.5,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      specialty,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isLeader)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Cứu hộ phụ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLeader)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: Colors.white,
                          size: 13,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Trưởng kíp cấp cứu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isDone
                            ? Icons.check_circle_outline
                            : Icons.timelapse_rounded,
                        size: 15,
                        color: isDone ? primaryColor : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isDone
                            ? 'Xong: $timeNowStr (Sớm nhất)'
                            : 'Đang thực hiện nhiệm vụ',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDone ? Colors.black87 : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 15, color: primaryColor),
              const SizedBox(width: 6),
              Text(
                phone,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const Spacer(),
              if (!isLeader)
                Row(
                  children: [
                    Icon(
                      isDone
                          ? Icons.check_circle_outline
                          : Icons.timelapse_rounded,
                      size: 15,
                      color: isDone ? primaryColor : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isDone ? 'Hoàn thành: $timeNowStr' : 'Đang thực hiện',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDone ? Colors.black87 : Colors.orange,
                      ),
                    ),
                  ],
                )
              else if (isDone)
                _buildDanhGiaButton(
                  context,
                  maNguoiCuuHo: maNguoiCuuHo,
                  name: name,
                  hasDraftComment: displayComment.isNotEmpty,
                  isSubmitted: isSubmitted,
                ),
            ],
          ),
          // 🌟 Chỉ hiển thị phần đánh giá khi cứu hộ viên này đã hoàn thành nhiệm vụ
          if (isDone) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            Row(
              children: [
                if (!isLeader)
                  _buildDanhGiaButton(
                    context,
                    maNguoiCuuHo: maNguoiCuuHo,
                    name: name,
                    hasDraftComment: displayComment.isNotEmpty,
                    isSubmitted: isSubmitted,
                  )
                else
                  const Text(
                    'Đánh giá chất lượng',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                const Spacer(),
                Row(
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: isSubmitted
                          ? null
                          : () {
                              setState(() {
                                _selectedRatings[maNguoiCuuHo] = i + 1;
                              });
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: Icon(
                          Icons.star_rounded,
                          color: i < currentStars
                              ? primaryColor
                              : Colors.grey.shade300,
                          size: 24,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            if (displayComment.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '“$displayComment”',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDanhGiaButton(
    BuildContext context, {
    required String maNguoiCuuHo,
    required String name,
    required bool hasDraftComment,
    required bool isSubmitted,
  }) {
    final bool isActive = hasDraftComment || isSubmitted;
    return InkWell(
      onTap: isSubmitted
          ? null
          : () => _showDanhGiaDialog(context, maNguoiCuuHo, name),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 16,
              color: isActive ? primaryColor : Colors.black87,
            ),
            const SizedBox(width: 5),
            Text(
              isSubmitted
                  ? 'Đã đánh giá'
                  : (hasDraftComment ? 'Đánh giá (Đã nhập)' : 'Đánh giá'),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isActive ? primaryColor : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDanhGiaDialog(
    BuildContext context,
    String maNguoiCuuHo,
    String name,
  ) {
    int tempStars = _selectedRatings[maNguoiCuuHo] ?? 5;
    final TextEditingController textCtrl = TextEditingController(
      text: _draftComments[maNguoiCuuHo] ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Đánh giá cứu hộ viên\n$name',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (idx) {
                      return IconButton(
                        icon: Icon(
                          Icons.star_rounded,
                          color: idx < tempStars
                              ? primaryColor
                              : Colors.grey.shade300,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() => tempStars = idx + 1);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: textCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Nhập nhận xét về quá trình hỗ trợ...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedRatings[maNguoiCuuHo] = tempStars;
                      _draftComments[maNguoiCuuHo] = textCtrl.text.trim();
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Lưu đánh giá',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
