import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVCoCCHN/CuuHoVien_CoCCHN.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVKhongCCHN/CuuHoVien_KhongCCHN.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVKhongCCHN/models/quiz_question.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangThaiXacThuc/models/trang_thai_ho_so.dart';
import 'package:flutter/material.dart';

enum LoaiCuuHoVien { coCCHN, khongCCHN }

/// Dựng form đăng ký của nhóm CÓ CCHN. Form đó phải tự đi tiếp sang
/// TrangThaiXacThucScreen (và xóa các màn đăng ký khỏi ngăn xếp) sau khi gửi.
typedef FormDangKyBuilder =
    Widget Function(BuildContext context, String userId, String fullName);

/// Màn hình cho người dùng CHƯA có hồ sơ chọn đăng ký là cứu hộ viên có CCHN
/// hay không có CCHN, rồi chuyển sang form tương ứng.
class ChonLoaiCuuHoVienScreen extends StatefulWidget {
  final String userId;
  final String fullName;

  /// Form đăng ký nhóm CÓ CCHN. Để `null` thì nhóm này báo "chưa mở đăng ký".
  final FormDangKyBuilder? coCCHNFormBuilder;

  /// Đăng xuất. Màn này là gốc sau đăng nhập nên không có nút Back.
  final VoidCallback? onDangXuat;

  const ChonLoaiCuuHoVienScreen({
    super.key,
    required this.userId,
    required this.fullName,
    this.coCCHNFormBuilder,
    this.onDangXuat,
  });

  @override
  State<ChonLoaiCuuHoVienScreen> createState() =>
      _ChonLoaiCuuHoVienScreenState();
}

class _ChonLoaiCuuHoVienScreenState extends State<ChonLoaiCuuHoVienScreen> {
  static const Color _xanhDuong = Color(0xFF1565C0);
  static const Color _xanhLa = Color(0xFF00897B);
  static const Color _do = Color(0xFFB71C1C);

  LoaiCuuHoVien? _chon;

  void _tiepTuc() {
    final loai = _chon;
    if (loai == null) return;

    final builder = widget.coCCHNFormBuilder;
    // form sẽ xóa các màn đăng ký khỏi ngăn xếp.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => loai == LoaiCuuHoVien.coCCHN
            ? CuuhovienCocchn(
                currentUserId: widget.userId,
                userFullName: widget.fullName,
              )
            : CuuhovienKhongcchn(
                currentUserId: widget.userId,
                userFullName: widget.fullName,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coTen = widget.fullName.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Đăng ký cứu hộ viên',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                    Text(
                      coTen ? 'Xin chào, ${widget.fullName}' : 'Xin chào',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tài khoản của bạn chưa đăng ký hồ sơ cứu hộ viên. '
                      'Hãy chọn nhóm phù hợp với bạn để bắt đầu.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LoaiCard(
                      selected: _chon == LoaiCuuHoVien.coCCHN,
                      mau: _xanhDuong,
                      icon: Icons.medical_services_outlined,
                      tieuDe: 'Cứu hộ viên có CCHN',
                      moTa:
                          'Dành cho người đã có chứng chỉ / giấy phép hành nghề khám bệnh, chữa bệnh '
                          '(bác sĩ, điều dưỡng, kỹ thuật viên...).',
                      cacYeuCau: const [
                        'Thông tin CCCD',
                        'Số CCHN/GPHN, nơi cấp, chuyên ngành',
                        'Nơi công tác để đối chiếu',
                      ],
                      onTap: () => setState(() => _chon = LoaiCuuHoVien.coCCHN),
                    ),
                    const SizedBox(height: 12),
                    _LoaiCard(
                      selected: _chon == LoaiCuuHoVien.khongCCHN,
                      mau: _xanhLa,
                      icon: Icons.volunteer_activism_outlined,
                      tieuDe: 'Cứu hộ viên không có CCHN',
                      moTa:
                          'Dành cho tình nguyện viên, thành viên đội cứu hộ đã được huấn luyện sơ cấp cứu. '
                          'Bạn không phải nhân viên y tế, chỉ hỗ trợ sơ cấp cứu ban đầu.',
                      cacYeuCau: [
                        'CCCD hai mặt và ảnh selfie cầm CCCD',
                        'Chứng nhận sơ cấp cứu hoặc thư xác nhận của tổ chức',
                        'Người bảo chứng',
                        'Bài kiểm tra ${kQuizBank.length} câu, đạt từ $kQuizPassPercent%',
                      ],
                      onTap: () =>
                          setState(() => _chon = LoaiCuuHoVien.khongCCHN),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Color(0xFFD97706),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Hãy chọn đúng nhóm. Giấy tờ sẽ được đối chiếu, khai không đúng có thể '
                              'khiến hồ sơ bị từ chối. Hồ sơ cần được thẩm định (dự kiến tối đa '
                              '$kThamDinhSlaGio giờ) trước khi bạn nhận được ca.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF92400E),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
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
                            ? 'CHỌN MỘT NHÓM ĐỂ TIẾP TỤC'
                            : 'TIẾP TỤC',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoaiCard extends StatelessWidget {
  final bool selected;
  final Color mau;
  final IconData icon;
  final String tieuDe;
  final String moTa;
  final List<String> cacYeuCau;
  final VoidCallback onTap;

  const _LoaiCard({
    required this.selected,
    required this.mau,
    required this.icon,
    required this.tieuDe,
    required this.moTa,
    required this.cacYeuCau,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: tieuDe,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? mau : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: mau.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: mau, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tieuDe,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected ? mau : Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                moTa,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bạn cần chuẩn bị:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              for (final y in cacYeuCau)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check, size: 14, color: mau),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          y,
                          style: const TextStyle(fontSize: 11.5, height: 1.3),
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
