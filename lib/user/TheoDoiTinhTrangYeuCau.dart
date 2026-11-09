import 'package:flutter/material.dart';

class StatusStepWidget extends StatefulWidget {
  final int currentStep; // 0: Đã nhận đơn, 1: Đang đến, 2: Đang chờ, 3: Điểm đến
  final VoidCallback onButtonPressed; // Xử lý sự kiện khi bấm nút

  const StatusStepWidget({
    super.key,
    this.currentStep = 1, // Mặc định ở bước "Đang đến"
    required this.onButtonPressed,
  });

  @override
  State<StatusStepWidget> createState() => _StatusStepWidgetState();
}

class _StatusStepWidgetState extends State<StatusStepWidget> {
  // Danh sách các trạng thái
  final List<String> _steps = [
    "Đang tìm kiếm",
    "Đã tiếp nhận",
    "Đang đến",
    "Đang cứu hộ",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        // Bo tròn cả 4 góc của khung hình chữ nhật
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Thanh gạt hình chữ nhật nhỏ bo tròn ở đỉnh
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDCE3ED),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Dòng trạng thái phụ: Chấm tròn xanh + Nhãn chữ hoa & Khoảng cách
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00875A), // Màu xanh lá lục đậm
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "ĐANG DI CHUYỂN ĐẾN BẠN",
                    style: TextStyle(
                      color: Color(0xFF00875A),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              // Nút hiển thị khoảng cách 1.2 km
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.near_me_outlined,
                      size: 14,
                      color: Color(0xFF0052CC),
                    ),
                    SizedBox(width: 4),
                    Text(
                      "1.2 km",
                      style: TextStyle(
                        color: Color(0xFF0052CC),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 3. Tiêu đề chính tiêu điểm
          const Text(
            "Người cứu hộ đang đến",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF091E42),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Các thanh tiến trình màu sắc
          Row(
            children: List.generate(_steps.length, (index) {
              Color barColor;
              if (index < widget.currentStep) {
                barColor = const Color(0xFF00875A); // Đã xong: Xanh đậm
              } else if (index == widget.currentStep) {
                barColor = const Color(0xFF57D9A3); // Trạng thái hiện tại: Xanh nhạt
              } else {
                barColor = const Color(0xFFE4E8EE); // Chưa đến: Xám nhạt
              }

              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(
                    right: index == _steps.length - 1 ? 0 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),

          // 5. Tên của từng bước bên dưới thanh tiến trình
          Row(
            children: List.generate(_steps.length, (index) {
              bool isCurrent = index == widget.currentStep;
              bool isDone = index < widget.currentStep;

              Color textColor;
              if (isDone || isCurrent) {
                textColor = isDone ? const Color(0xFF091E42) : const Color(0xFF00875A);
              } else {
                textColor = const Color(0xFF6B778C);
              }

              return Expanded(
                child: Text(
                  _steps[index],
                  textAlign: index == 0
                      ? TextAlign.start
                      : (index == _steps.length - 1 ? TextAlign.end : TextAlign.center),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ),
          const SizedBox(height: 18),

          // 6. Nút bấm bổ sung cho widget
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: widget.onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00695C), // Thay đổi màu theo theme app
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Theo dõi tình trạng yêu cầu",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}