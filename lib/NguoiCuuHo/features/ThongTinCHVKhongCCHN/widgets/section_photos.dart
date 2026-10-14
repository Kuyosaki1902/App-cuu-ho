import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVKhongCCHN/controllers/chv_khong_cchn_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SectionPhotos extends StatelessWidget {
  const SectionPhotos({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CuuHoVienKhongCCHNController>();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionIndex('3'),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ảnh thực tế',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              _buildTag(
                'Không bắt buộc bằng Y khoa',
                const Color(0xFFE0F2F1),
                const Color(0xFF00695C),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ảnh hoạt động thiện nguyện thực tế',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Text(
                'Đã chọn 2/4 ảnh',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF00897B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Hình ảnh minh chứng tham gia sơ cứu, diễn tập hoặc hỗ trợ cộng đồng (Tối đa 4 ảnh, định dạng JPG/PNG)',
            style: TextStyle(fontSize: 10, color: Colors.black45),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPhotoThumbnail(
                  'Ảnh sơ cứu tai nạn',
                  'https://picsum.photos/200/200?random=1',
                ),
                const SizedBox(width: 8),
                _buildPhotoThumbnail(
                  'Tập huấn Red Cross',
                  'https://picsum.photos/200/200?random=2',
                ),
                const SizedBox(width: 8),
                _buildAddPhotoButton(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ghi chú thêm & Người xác minh (tùy chọn)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller.noteController,
            maxLines: 3,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText:
                  '............................\n............................',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFEEF2FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionIndex(String number) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Color(0xFFC80815),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        number,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(String label, String imageUrl) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 100,
            height: 100,
            color: Colors.grey.shade300,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image, color: Colors.grey),
            ),
          ),
        ),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
        Positioned(
          bottom: 6,
          left: 6,
          right: 6,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.shade200,
          style: BorderStyle.solid,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, color: Colors.teal, size: 24),
          SizedBox(height: 4),
          Text(
            'Thêm ảnh',
            style: TextStyle(
              fontSize: 10,
              color: Colors.teal,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
