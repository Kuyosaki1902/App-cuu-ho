import 'package:cuhokhancap/NguoiCuuHo/Features/DangKy_DangNhap/DieuHuongCuuHo.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangThaiXacThuc/trang_thai_xac_thuc_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/chv_khong_cchn_controller.dart';
import 'widgets/section_ekyc_no_cchn.dart';
import 'widgets/section_evidence.dart';
import 'widgets/section_experience.dart';
import 'widgets/section_quiz.dart';
import 'widgets/terms_box_no_cchn.dart';

class CuuhovienKhongcchn extends StatelessWidget {
  /// Mã người dùng đang đăng nhập (truyền từ màn chọn loại / màn trạng thái).
  final String currentUserId;

  /// Họ tên thật lấy từ tài khoản. Không có thì để trống, người dùng sẽ thấy
  /// ô họ tên trống và bị chặn nộp (controller yêu cầu có họ tên).
  final String userFullName;

  const CuuhovienKhongcchn({
    super.key,
    required this.currentUserId,
    this.userFullName = '',
  });

  void _showMessage(BuildContext context, String text, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
  }

  Future<void> _onSubmit(
    BuildContext context,
    CuuHoVienKhongCCHNController controller,
  ) async {
    // 1. Kiểm tra các điều kiện còn thiếu (báo mục đầu tiên chưa đạt)
    final missing = controller.firstMissingMessage;
    if (missing != null) {
      _showMessage(context, missing, Colors.orange);
      // Hiện luôn lỗi dưới từng ô nhập nếu có.
      controller.formKey.currentState?.validate();
      return;
    }
    if (!(controller.formKey.currentState?.validate() ?? false)) {
      _showMessage(
        context,
        'Vui lòng kiểm tra lại các ô còn báo lỗi',
        Colors.orange,
      );
      return;
    }

    // 2. Gửi hồ sơ
    final success = await controller.submitHoSoToFirebase(currentUserId);
    if (!context.mounted) return;

    if (success) {
      _showMessage(
        context,
        'Gửi hồ sơ thành công! Hồ sơ đang chờ thẩm định.',
        Colors.green,
      );
      // Xóa hết các màn đăng ký phía dưới (màn chọn loại, form) để nút Back
      // không đưa người dùng quay lại đăng ký lần nữa.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => TrangThaiXacThucScreen(
            userId: currentUserId,
            isCoCCHN: false,
            onDangXuat: () => DieuHuongCuuHo.dangXuat(context),
          ),
        ),
        (route) => false,
      );
    } else {
      _showMessage(
        context,
        'Lưu hồ sơ thất bại. Vui lòng thử lại!',
        Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tên thật lấy từ tài khoản (controller tự bỏ danh xưng "BS." nếu có).
    return ChangeNotifierProvider(
      create: (_) =>
          CuuHoVienKhongCCHNController(existingFullName: userFullName),
      child: Consumer<CuuHoVienKhongCCHNController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF6F8FA),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.maybePop(context),
              ),
              title: const Text(
                'Xác thực Cứu hộ viên (Không CCHN)',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              centerTitle: true,
              actions: const [
                Padding(
                  padding: EdgeInsets.only(right: 10.0),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFB71C1C),
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            body: Form(
              key: controller.formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionEkycNoCchn(), // 1. Danh tính + ảnh giấy tờ
                    const SizedBox(height: 16),
                    const SectionExperience(), // 2. Kinh nghiệm, tổ chức, kỹ năng tự khai
                    const SizedBox(height: 16),
                    const SectionEvidence(), // 3. Minh chứng + người bảo chứng
                    const SizedBox(height: 16),
                    const SectionQuiz(), // 4. Bài kiểm tra năng lực
                    const SizedBox(height: 16),
                    const TermsBoxNoCchn(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: controller.isFormValid
                              ? const Color(0xFFB71C1C)
                              : Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                          elevation: 0,
                        ),
                        onPressed: controller.isSubmitting
                            ? null
                            : () => _onSubmit(context, controller),
                        child: controller.isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'GỬI YÊU CẦU XÁC THỰC CỨU HỘ VIÊN',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
