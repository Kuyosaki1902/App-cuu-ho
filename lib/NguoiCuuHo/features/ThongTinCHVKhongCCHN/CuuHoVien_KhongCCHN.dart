import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVKhongCCHN/controllers/chv_khong_cchn_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/section_ekyc_no_cchn.dart';
import 'widgets/section_experience.dart';
import 'widgets/section_photos.dart';
import 'widgets/terms_box_no_cchn.dart';

class NguoicuuhoKhongcchn extends StatelessWidget {
  const NguoicuuhoKhongcchn({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CuuHoVienKhongCCHNController(),
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
                'Xác Thực CHV (Không CCHN)',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.black54),
                  onPressed: () {},
                ),
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

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB71C1C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (!controller.isAgreed) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Vui lòng tích chọn cam kết năng lực trước khi gửi!',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          if (controller.formKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đang gửi yêu cầu xác thực...'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, color: Colors.white, size: 18),
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
