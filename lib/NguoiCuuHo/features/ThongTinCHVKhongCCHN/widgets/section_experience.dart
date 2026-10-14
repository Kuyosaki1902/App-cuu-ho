import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVKhongCCHN/controllers/chv_khong_cchn_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SectionExperience extends StatelessWidget {
  const SectionExperience({super.key});

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
              _buildSectionIndex('2'),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Kinh nghiệm & Đội cứu trợ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              _buildTag(
                '• Xét duyệt thực chiến \n• Không cần CCHN',
                const Color(0xFFE0F2F1),
                const Color(0xFF00695C),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Đội nhóm / Tổ chức cứu nạn từng tham gia',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          _buildInputField(
            controller: controller.organizationController,
            hintText: '............................',
            suffixIcon: const Icon(
              Icons.group_outlined,
              size: 18,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ghi rõ tên nhóm tự quản, câu lạc bộ tình nguyện hoặc tổ chức trực thuộc',
            style: TextStyle(fontSize: 10, color: Colors.black45),
          ),
          const SizedBox(height: 10),
          const Text(
            'Số năm / Thâm niên hoạt động cứu hộ',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.selectedExperience,
                        isExpanded: true,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        items: controller.experienceOptions
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) controller.setExperience(val);
                        },
                      ),
                    ),
                  ),
                  const Icon(Icons.history, size: 18, color: Colors.teal),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Các kỹ năng sơ cấp cứu thành thạo',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Text(
                'Tự do kê khai kỹ năng',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF00897B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            maxLines: 3,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText:
                  '............................\n............................\n............................',
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: controller.availableSkills.map((skill) {
              final isSelected = controller.selectedSkills.contains(skill);
              return GestureDetector(
                onTap: () => controller.toggleSkill(skill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE0F2F1)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        size: 14,
                        color: isSelected
                            ? const Color(0xFF00897B)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        skill,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? const Color(0xFF00695C)
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tóm tắt các ca cứu hộ thực tế từng tham gia',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller.summaryController,
            maxLines: 4,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText:
                  '............................\n............................\n............................',
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
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Giúp điều phối viên ưu tiên phân công đúng tình huống',
                style: TextStyle(fontSize: 10, color: Colors.black45),
              ),
              Text(
                '178/500 ký tự',
                style: TextStyle(fontSize: 10, color: Colors.black45),
              ),
            ],
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

  Widget _buildInputField({
    required TextEditingController controller,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        filled: true,
        fillColor: const Color(0xFFEEF2FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}
