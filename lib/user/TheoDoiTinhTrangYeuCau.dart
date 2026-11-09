import 'package:flutter/material.dart';

class TheoDoiTinhTrangYeuCau extends StatelessWidget {
  final int currentStep; // 0: Đã tiếp nhận, 1: Đang đến, 2: Đang cứu hộ, 3: Hoàn thành

  const TheoDoiTinhTrangYeuCau({
    super.key,
    this.currentStep = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tình trạng yêu cầu'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Thẻ sườn hiển thị tiến trình
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.circle, color: Color(0xFF00875A), size: 12),
                        SizedBox(width: 8),
                        Text(
                          "ĐANG DI CHUYỂN ĐẾN BẠN",
                          style: TextStyle(
                            color: Color(0xFF00875A),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Bác sĩ / Cứu hộ đang tiếp cận",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Thanh tiến trình các bước
                    Row(
                      children: List.generate(4, (index) {
                        return Expanded(
                          child: Container(
                            height: 6,
                            margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
                            decoration: BoxDecoration(
                              color: index <= currentStep
                                  ? const Color(0xFF00695C)
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(0xFFE0F2F1),
                        child: Icon(Icons.person, color: Color(0xFF00695C)),
                      ),
                      title: Text("Bác sĩ Nguyễn Văn A"),
                      subtitle: Text("Khoảng cách: ~1.2 km"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}