import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/chv_coCCHN_controller.dart';
import 'widgets/section_ekyc.dart';
import 'widgets/section_cchn.dart';
import 'widgets/section_hospital.dart';
import 'widgets/terms_and_info_box.dart';

class Nguoicuuhococchn extends StatelessWidget {
  final String? userFullName; // Họ tên đã đăng ký tài khoản trước đó

  const Nguoicuuhococchn({super.key, this.userFullName});

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
                'Xác Thực NCV (Có CCHN)',
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
                                        'Vui lòng đồng ý với cam kết trước khi gửi yêu cầu!',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                if (controller.formKey.currentState!
                                    .validate()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Đang gửi yêu cầu xác thực...',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                              child: const Row(
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
