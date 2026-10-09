import 'package:flutter/material.dart';

class VictimConditionSheet extends StatefulWidget {
  const VictimConditionSheet({super.key});

  @override
  State<VictimConditionSheet> createState() => _VictimConditionSheetState();
}

class _VictimConditionSheetState extends State<VictimConditionSheet> {
  // Lưu trữ các triệu chứng được chọn
  final Set<String> _selectedSymptoms = {};

  final List<Map<String, dynamic>> _symptoms = [
    {'name': 'Khó thở', 'color': Colors.red},
    {'name': 'Bất tỉnh', 'color': Colors.orange},
    {'name': 'Chảy máu', 'color': Colors.red},
    {'name': 'Gãy xương / Chấn thương', 'color': Colors.blue},
    {'name': 'Co giật', 'color': Colors.purple},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thanh gạt (Drag handle)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header: Tiêu đề và nút tắt
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEE), // Đỏ nhạt
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Tình trạng người bị nạn", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Cập nhật ngay để bác sĩ chuẩn bị trước", style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context), // Đóng BottomSheet
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.black54, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Chọn nhanh triệu chứng
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("CHỌN NHANH TRIỆU CHỨNG", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                Text("Có thể chọn nhiều", style: TextStyle(fontSize: 11, color: Color(0xFF00695C))),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: _symptoms.map((symptom) {
                final isSelected = _selectedSymptoms.contains(symptom['name']);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedSymptoms.remove(symptom['name']);
                      } else {
                        _selectedSymptoms.add(symptom['name']);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF004D40) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF004D40) : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: symptom['color'], size: 10),
                        const SizedBox(width: 6),
                        Text(
                          symptom['name'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Mô tả chi tiết bổ sung
            const Text("MÔ TẢ CHI TIẾT BỔ SUNG", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Mô tả cụ thể biểu hiện: nạn nhân còn tỉnh hay mê man, vị trí vết thương hở, nhịp thở...",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF00695C), size: 16),
                          SizedBox(width: 4),
                          Text("Chia sẻ trực tiếp tới 6 bác sĩ lân cận", style: TextStyle(color: Color(0xFF00695C), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text("Tùy chọn", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Chứng cứ hình ảnh và âm thanh
            const Text("CHỨNG CỨ HÌNH ẢNH & ÂM THANH", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFE0F2F1), shape: BoxShape.circle), // Xanh nhạt
                          child: const Icon(Icons.camera_alt, color: Color(0xFF00695C)),
                        ),
                        const SizedBox(height: 8),
                        const Text("Chụp ảnh / Video", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const Text("Hiện trường, vết thương", style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9F9), // Đỏ cực nhạt
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFEBEE)),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
                              child: const Icon(Icons.mic, color: Colors.red),
                            ),
                            const SizedBox(height: 8),
                            const Text("Ghi âm nhanh", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                            const Text("Nhấn giữ để nói", style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                        const Positioned(
                          top: 0,
                          right: 12,
                          child: Icon(Icons.circle, color: Colors.red, size: 8),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Nút Xác nhận
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004D40), // Xanh rêu đậm
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text("Xác nhận & Gửi bác sĩ ngay", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Nút để sau
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Để sau, tôi sẽ trao đổi qua điện thoại", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}