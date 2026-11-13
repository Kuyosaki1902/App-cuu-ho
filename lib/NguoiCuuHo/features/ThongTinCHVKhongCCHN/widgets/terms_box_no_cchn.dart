import 'package:cuhokhancap/NguoiCuuHo/Features/TrangThaiXacThuc/models/trang_thai_ho_so.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/chv_khong_cchn_controller.dart';
import 'form_widgets.dart';

class TermsBoxNoCchn extends StatelessWidget {
  const TermsBoxNoCchn({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CuuHoVienKhongCCHNController>();

    const base = TextStyle(fontSize: 11, color: Colors.black87, height: 1.3);
    const red = TextStyle(color: Colors.red, fontWeight: FontWeight.bold);

    return Column(
      children: [
        // Nhãn phạm vi rõ ràng
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: Color(0xFFE65100)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bạn tham gia với tư cách người hỗ trợ sơ cấp cứu, KHÔNG phải nhân viên y tế. '
                  'Phạm vi chỉ gồm sơ cứu ban đầu và giữ an toàn cho nạn nhân; luôn gọi 115 '
                  'khi tình huống nguy hiểm. Không tiêm, truyền, kê hoặc cho dùng thuốc.',
                  style: TextStyle(fontSize: 10.5, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Cam kết phạm vi
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: c.isAgreed,
              activeColor: kTeal,
              onChanged: (v) => c.setAgreed(v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: RichText(
                  text: const TextSpan(
                    style: base,
                    children: [
                      TextSpan(text: 'Tôi cam kết chỉ thực hiện sơ cấp cứu trong '),
                      TextSpan(text: 'giới hạn năng lực được huấn luyện', style: red),
                      TextSpan(
                        text:
                            ', giữ an toàn tuyệt đối cho người bị nạn, không thực hiện thủ thuật '
                            'y khoa chuyên sâu vượt quá thẩm quyền và các thông tin tôi khai là trung thực.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // Đồng ý xử lý dữ liệu cá nhân (checkbox riêng)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: c.isDataConsent,
              activeColor: kTeal,
              onChanged: (v) => c.setDataConsent(v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: RichText(
                  text: const TextSpan(
                    style: base,
                    children: [
                      TextSpan(text: 'Tôi đồng ý cho hệ thống xử lý '),
                      TextSpan(
                        text: 'dữ liệu cá nhân nhạy cảm',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            ' (số CCCD, ảnh giấy tờ, ảnh selfie, số điện thoại người bảo chứng, vị trí khi nhận ca) '
                            'chỉ nhằm mục đích xác minh danh tính, thẩm định hồ sơ và điều phối cứu hộ khẩn cấp. '
                            'Tôi có thể yêu cầu xóa dữ liệu khi không còn tham gia.',
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
            color: kFieldFill,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_outlined, color: kTeal, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thẩm định hồ sơ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: kTealDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ban điều phối 115 đối chiếu giấy tờ, minh chứng và người bảo chứng trước khi '
                      'kích hoạt quyền nhận ca. Thời gian dự kiến tối đa $kThamDinhSlaGio giờ, có thể lâu hơn '
                      'nếu cần bổ sung hồ sơ. Sau khi duyệt bạn bắt đầu ở cấp uy tín 1 (chỉ nhận ca mức nhẹ) '
                      'và được xác minh lại định kỳ.',
                      style: const TextStyle(fontSize: 10, height: 1.3, color: Colors.black87),
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
