import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVKhongCCHN/controllers/chv_khong_cchn_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TermsBoxNoCchn extends StatelessWidget {
  const TermsBoxNoCchn({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CuuHoVienKhongCCHNController>();

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: controller.isAgreed,
              activeColor: const Color(0xFF00897B),
              onChanged: (val) => controller.setAgreed(val ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(
                        text: 'Tôi cam kết thực hiện hỗ trợ sơ cứu trong ',
                      ),
                      TextSpan(
                        text: 'giới hạn năng lực ban đầu',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            ', giữ an toàn tuyệt đối cho người bị nạn và không thực hiện các thủ thuật y khoa chuyên sâu vượt quá thẩm quyền.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_outlined,
                color: Color(0xFF00897B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thẩm định năng lực thực tế siêu tốc (2 - 4 giờ)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00695C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                        children: [
                          TextSpan(
                            text:
                                'Hồ sơ Cứu hộ viên không có CCHN y tế được Ban điều phối 115 xác minh kỹ năng sơ cứu và kích hoạt quyền cứu nạn khẩn cấp trong vòng ',
                          ),
                          TextSpan(
                            text: '2 - 4 giờ làm việc.',
                            style: TextStyle(
                              color: Color(0xFF00897B),
                              fontWeight: FontWeight.bold,
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
        ),
      ],
    );
  }
}
