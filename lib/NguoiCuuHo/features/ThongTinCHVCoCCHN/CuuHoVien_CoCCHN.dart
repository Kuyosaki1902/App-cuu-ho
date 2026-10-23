import 'package:cuhokhancap/NguoiCuuHo/Features/TrangThaiXacThuc/trang_thai_xac_thuc_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/chv_coCCHN_controller.dart';
import 'widgets/section_ekyc.dart';
import 'widgets/section_cchn.dart';
import 'widgets/section_hospital.dart';
import 'widgets/terms_and_info_box.dart';

class CuuhovienCocchn extends StatelessWidget {
  final String? userFullName;
  const CuuhovienCocchn({super.key, this.userFullName});
  final currentUserId = 'nguoidung8';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CuuHoVienCoCCHNController(
        existingFullName: userFullName ?? 'BS. NGUYỄN VĂN A',
      ),
      child: Consumer<CuuHoVienCoCCHNController>(
        builder: (context, controller, child) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Xác Thực Cứu hộ viên (Có CCHN)',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
              actions: const [
                Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFC80815),
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            body: controller.isLoadingApi
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00897B)),
                  )
                : Form(
                    key: controller.formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const SectionEkyc(),
                          const SizedBox(height: 16),
                          const SectionCchn(),
                          const SizedBox(height: 16),
                          const SectionHospital(),
                          const SizedBox(height: 16),
                          const TermsAndInfoBox(),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                // Đổi màu nút sang xám nếu chưa kiểm tra CCHN thành công
                                backgroundColor:
                                    (controller.isAgreed &&
                                        controller.isCchnValid == true)
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
                                      // 1. Kiểm tra mã CCHN đã được xác thực thành công chưa
                                      if (controller.isCchnValid != true) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Vui lòng nhấn "Kiểm tra định dạng CCHN" và đảm bảo mã hợp lệ trước khi gửi!',
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        return;
                                      }

                                      // 2. Kiểm tra điều khoản cam kết
                                      if (!controller.isAgreed) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Vui lòng đồng ý với cam kết trước khi gửi yêu cầu!',
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        return;
                                      }

                                      // 3. Thực hiện gửi lên Firestore
                                      if (controller.formKey.currentState!
                                          .validate()) {
                                        bool success = await controller
                                            .submitHoSoToFirebase(
                                              currentUserId,
                                            );

                                        if (context.mounted) {
                                          if (success) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Lưu hồ sơ Cứu hộ viên thành công!',
                                                ),
                                                backgroundColor: Colors.green,
                                                duration: Duration(seconds: 1),
                                              ),
                                            );

                                            // Chuyển sang màn hình Trạng thái xác thực
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    TrangThaiXacThucScreen(
                                                      userId: currentUserId,
                                                      isCoCCHN: true,
                                                    ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Lưu thất bại. Vui lòng thử lại!',
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
