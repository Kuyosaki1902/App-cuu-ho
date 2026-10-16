import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVKhongCCHN/controllers/chv_khong_cchn_controller.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangThaiXacThuc/trang_thai_xac_thuc_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/section_ekyc_no_cchn.dart';
import 'widgets/section_experience.dart';
import 'widgets/section_photos.dart';
import 'widgets/terms_box_no_cchn.dart';

class CuuhovienKhongcchn extends StatelessWidget {
  const CuuhovienKhongcchn({super.key});
  final String currentUserId = 'nguoidung3';
  @override
  Widget build(BuildContext context) {
    String userFullName = 'BS.Nguyễn Xuân Hanh';
    return ChangeNotifierProvider(
      create: (_) => CuuHoVienKhongCCHNController(
        existingFullName: userFullName, // 🟢 Truyền tên vào đây
      ),
      child: Consumer<CuuHoVienKhongCCHNController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF6F8FA),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {},
              ),
              title: const Text(
                'X.Thực Cứu hộ viên (Không CCHN)',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
              actions: [
                const Padding(
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
                    // Section 1: eKYC
                    const SectionEkycNoCchn(),
                    const SizedBox(height: 16),

                    // Section 2: Kinh nghiệm & Kỹ năng
                    const SectionExperience(),
                    const SizedBox(height: 16),

                    // Section 3: Ảnh thực tế
                    const SectionPhotos(),
                    const SizedBox(height: 16),

                    // Terms Box
                    const TermsBoxNoCchn(),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          // 🟢 Chỉ hiện màu đỏ khi đã nhập ĐỦ THÔNG TIN và tích cam kết
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
                            : () async {
                                // 1. Kiểm tra các điều kiện thông tin còn thiếu
                                if (!controller.isAgreed) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Vui lòng tích chọn cam kết năng lực!',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                if (controller.cccdCardNoController.text
                                    .trim()
                                    .isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Vui lòng nhập số thẻ CCCD/Căn cước!',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                if (controller.organizationController.text
                                    .trim()
                                    .isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Vui lòng nhập Đội nhóm / Tổ chức tham gia!',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                if (controller.selectedPhotos.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Vui lòng tải lên ít nhất 1 ảnh thực tế!',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                // 2. Thực hiện gửi khi tất cả đã hợp lệ
                                if (controller.isFormValid &&
                                    controller.formKey.currentState!
                                        .validate()) {
                                  bool success = await controller
                                      .submitHoSoToFirebase(currentUserId);

                                  if (context.mounted) {
                                    if (success) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Gửi hồ sơ thành công!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );

                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TrangThaiXacThucScreen(
                                                userId: currentUserId,
                                              ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Lưu hồ sơ thất bại. Vui lòng thử lại!',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
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
