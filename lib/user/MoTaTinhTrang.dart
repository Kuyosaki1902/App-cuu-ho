import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class VictimConditionSheet extends StatefulWidget {
  const VictimConditionSheet({super.key});

  @override
  State<VictimConditionSheet> createState() => _VictimConditionSheetState();
}

class _VictimConditionSheetState extends State<VictimConditionSheet> {
  // Lưu trữ các triệu chứng được chọn
  final Set<String> _selectedSymptoms = {};
  
  // --- BIẾN TRẠNG THÁI HÌNH ẢNH & ÂM THANH ---
  File? _capturedImage;
  String? _audioPath;
  bool _isRecording = false;
  final AudioRecorder _audioRecorder = AudioRecorder();

  final List<Map<String, dynamic>> _symptoms = [
    {'name': 'Khó thở', 'color': Colors.red},
    {'name': 'Bất tỉnh', 'color': Colors.orange},
    {'name': 'Chảy máu', 'color': Colors.red},
    {'name': 'Gãy xương / Chấn thương', 'color': Colors.blue},
    {'name': 'Co giật', 'color': Colors.purple},
  ];

  // --- HÀM XỬ LÝ CHỤP ẢNH (Giới hạn 1 tấm, < 10MB) ---
  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    // imageQuality giúp giảm dung lượng ảnh ngay từ lúc chụp
    final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    
    if (photo != null) {
      final file = File(photo.path);
      final sizeInBytes = file.lengthSync();
      final sizeInMb = sizeInBytes / (1024 * 1024);

      if (sizeInMb > 10) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kích thước ảnh vượt quá 10MB. Vui lòng chụp lại.')),
          );
        }
        return;
      }

      setState(() {
        _capturedImage = file; // Chỉ lưu 1 tấm, chụp lại sẽ ghi đè
      });
    }
  }

  // --- HÀM XỬ LÝ GHI ÂM (Giới hạn < 15MB) ---
  // --- HÀM XỬ LÝ GHI ÂM ---
  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        // Dừng ghi âm
        final path = await _audioRecorder.stop();
        if (path != null) {
          final file = File(path);
          final sizeInBytes = file.lengthSync();
          final sizeInMb = sizeInBytes / (1024 * 1024);

          if (sizeInMb > 15) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File ghi âm vượt quá 15MB. Vui lòng ghi âm ngắn hơn.')),
              );
            }
            file.deleteSync(); // Xóa file quá dung lượng
            setState(() => _isRecording = false);
            return;
          }

          setState(() {
            _audioPath = path;
            _isRecording = false;
          });
        }
      } else {
        // Kiểm tra quyền và bắt đầu ghi âm
        if (await _audioRecorder.hasPermission()) {
          setState(() => _isRecording = true);
          
          // --- THAY ĐỔI ĐƯỜNG DẪN TẠI ĐÂY ---
          // Sử dụng path_provider để lấy thư mục cache chuẩn xác
          final Directory tempDir = await getTemporaryDirectory();
          final String tempPath = '${tempDir.path}/temp_audio.m4a'; 
          
          await _audioRecorder.start(const RecordConfig(), path: tempPath);
        }
      }
    } catch (e) {
      debugPrint('Lỗi ghi âm: $e');
      setState(() => _isRecording = false);
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

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
                  const TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
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
                // Khối Chụp ảnh
                Expanded(
                  child: GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _capturedImage != null ? const Color(0xFFE8F5E9) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _capturedImage != null ? Colors.green : Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _capturedImage != null ? Colors.green : const Color(0xFFE0F2F1), 
                              shape: BoxShape.circle
                            ),
                            child: Icon(
                              _capturedImage != null ? Icons.check : Icons.camera_alt, 
                              color: _capturedImage != null ? Colors.white : const Color(0xFF00695C)
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(_capturedImage != null ? "Đã chụp 1 ảnh" : "Chụp ảnh / Video", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(_capturedImage != null ? "Bấm để chụp lại" : "Hiện trường, vết thương", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Khối Ghi âm
                Expanded(
                  child: GestureDetector(
                    onTap: _toggleRecording,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _audioPath != null ? const Color(0xFFE8F5E9) : const Color(0xFFFFF9F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _audioPath != null ? Colors.green : const Color(0xFFFFEBEE)),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _isRecording ? Colors.red : (_audioPath != null ? Colors.green : const Color(0xFFFFEBEE)), 
                                  shape: BoxShape.circle
                                ),
                                child: Icon(
                                  _isRecording ? Icons.stop : (_audioPath != null ? Icons.check : Icons.mic), 
                                  color: _isRecording || _audioPath != null ? Colors.white : Colors.red
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isRecording ? "Đang ghi âm..." : (_audioPath != null ? "Đã ghi âm" : "Ghi âm nhanh"), 
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 13, 
                                  color: _isRecording ? Colors.red : (_audioPath != null ? Colors.green : Colors.red)
                                )
                              ),
                              Text(
                                _audioPath != null ? "Bấm để ghi đè" : "Nhấn để nói", 
                                style: const TextStyle(color: Colors.grey, fontSize: 11)
                              ),
                            ],
                          ),
                          if (_isRecording)
                            const Positioned(
                              top: 0,
                              right: 12,
                              child: Icon(Icons.circle, color: Colors.red, size: 8),
                            )
                        ],
                      ),
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