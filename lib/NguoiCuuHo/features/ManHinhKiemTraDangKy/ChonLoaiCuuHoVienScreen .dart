import 'dart:math';

import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVCoCCHN/CuuHoVien_CoCCHN.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVKhongCCHN/CuuHoVien_KhongCCHN.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVKhongCCHN/models/quiz_question.dart';
import 'package:flutter/material.dart';

enum LoaiCuuHoVien { coCCHN, khongCCHN }

typedef FormDangKyBuilder =
    Widget Function(BuildContext context, String userId, String fullName);

/// Hiện ra sau đăng nhập khi tài khoản CHƯA có hồ sơ cứu hộ viên.
/// Người dùng chọn 1 trong 2 loại, rồi vào form đăng ký tương ứng.
class ChonLoaiCuuHoVienScreen extends StatefulWidget {
  final String userId;
  final String fullName;

  /// Dựng form đăng ký CÓ CCHN. Nếu để trống, nút Tiếp tục của lựa chọn này
  /// sẽ báo "chưa được cấu hình".

  /// Bấm "Đăng xuất" (quay lại màn đăng nhập). Để trống thì ẩn nút.
  final VoidCallback? onDangXuat;

  const ChonLoaiCuuHoVienScreen({
    super.key,
    required this.userId,
    this.fullName = '',
    this.onDangXuat,
  });

  @override
  State<ChonLoaiCuuHoVienScreen> createState() =>
      _ChonLoaiCuuHoVienScreenState();
}

class _ChonLoaiCuuHoVienScreenState extends State<ChonLoaiCuuHoVienScreen> {
  static const Color _xanh = Color(0xFF1565C0);
  static const Color _teal = Color(0xFF00897B);
  static const Color _do = Color(0xFFB71C1C);

  LoaiCuuHoVien? _chon;

  void _tiepTuc() {
    final chon = _chon;
    if (chon == null) return;

    if (chon == LoaiCuuHoVien.khongCCHN) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CuuhovienKhongcchn(
            currentUserId: widget.userId,
            userFullName: widget.fullName,
          ),
        ),
      );
      return;
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CuuhovienCocchn(
            currentUserId: widget.userId,
            userFullName: widget.fullName,
          ),
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final coTen = widget.fullName.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Đăng ký Cứu hộ viên',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (widget.onDangXuat != null)
            TextButton.icon(
              onPressed: widget.onDangXuat,
              icon: const Icon(Icons.logout, size: 18, color: Colors.grey),
              label: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (coTen)
                      Text(
                        'Xin chào, ${widget.fullName.trim()}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bạn tham gia với vai trò nào?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tài khoản của bạn chưa có hồ sơ cứu hộ viên. Hãy chọn loại hồ sơ '
                      'đúng với tình trạng của bạn để bắt đầu đăng ký.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _OptionCard(
                      accent: _xanh,
                      icon: Icons.medical_services_outlined,
                      title: 'Tôi có chứng chỉ hành nghề',
                      subtitle:
                          'Bác sĩ, điều dưỡng, hộ sinh, kỹ thuật viên y tế... có CCHN hoặc '
                          'giấy phép hành nghề (GPHN) còn hiệu lực.',
                      chuanBi: const [
                        'Số CCHN hoặc GPHN và nơi cấp',
                        'Căn cước công dân (CCCD)',
                        'Thông tin nơi công tác, chuyên môn',
                      ],
                      ghiChu:
                          'Hồ sơ được đối chiếu với danh sách người hành nghề công khai '
                          'của cơ quan cấp phép.',
                      selected: _chon == LoaiCuuHoVien.coCCHN,
                      onTap: () => setState(() => _chon = LoaiCuuHoVien.coCCHN),
                    ),
                    const SizedBox(height: 12),
                    _OptionCard(
                      accent: _teal,
                      icon: Icons.volunteer_activism_outlined,
                      title: 'Tôi không có chứng chỉ hành nghề',
                      subtitle:
                          'Tình nguyện viên, thành viên đội cứu hộ, người đã học sơ cấp cứu '
                          'và muốn hỗ trợ cộng đồng.',
                      chuanBi: const [
                        'CCCD và ảnh selfie cầm CCCD',
                        'Chứng nhận sơ cấp cứu hoặc thư xác nhận của tổ chức',
                        'Một người bảo chứng (đội cứu hộ, tổ chức, bác sĩ)',
                        'Bài kiểm tra ngắn trong ứng dụng (đúng từ $kQuizPassPercent%)',
                      ],
                      ghiChu:
                          'Bạn là người hỗ trợ sơ cấp cứu, không phải nhân viên y tế. '
                          'Mới duyệt bạn ở cấp 1: chỉ nhận ca mức nhẹ và luôn nhắc gọi 115.',
                      selected: _chon == LoaiCuuHoVien.khongCCHN,
                      onTap: () =>
                          setState(() => _chon = LoaiCuuHoVien.khongCCHN),
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.grey),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Mọi hồ sơ đều được đối chiếu với giấy tờ thật trước khi kích hoạt nhận ca. '
                            'Khai sai thông tin có thể bị từ chối hoặc khóa tài khoản.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Nút cố định phía dưới
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _chon == null ? null : _tiepTuc,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _do,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    _chon == null
                        ? 'CHỌN MỘT LOẠI ĐỂ TIẾP TỤC'
                        : 'TIẾP TỤC ĐĂNG KÝ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _chon == null
                          ? Colors.grey.shade600
                          : Colors.white,
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

class _OptionCard extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> chuanBi;
  final String ghiChu;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.chuanBi,
    required this.ghiChu,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : const Color(0xFFE2E8F0),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(selected ? 0.06 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accent, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected ? accent : Colors.grey,
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              const Text(
                'Cần chuẩn bị',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              for (final item in chuanBi)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline, size: 15, color: accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(fontSize: 12, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ghiChu,
                  style: TextStyle(fontSize: 11, height: 1.4, color: accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
