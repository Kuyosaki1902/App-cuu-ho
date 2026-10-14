import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVCoCCHN/controllers/chv_coCCHN_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TermsAndInfoBox extends StatelessWidget {
  const TermsAndInfoBox({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CuuHoVienCoCCHNController>();

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: controller.isAgreed,
              activeColor: const Color(0xFFB71C1C),
              onChanged: (val) => controller.setAgreed(val ?? false),
            ),
            const Expanded(
              child: Text(
                'Tôi cam kết tính xác thực của thông tin cung cấp theo Luật Khám bệnh, chữa bệnh 2023 và tự chịu trách nhiệm chuyên môn khi tiếp nhận điều phối cấp cứu khẩn cấp từ Tổng đài 115.',
                style: TextStyle(fontSize: 11, height: 1.3),
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
