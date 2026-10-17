import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/chv_khong_cchn_controller.dart';

class SectionExperience extends StatelessWidget {
  const SectionExperience({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CuuHoVienKhongCCHNController>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.stars,
                  color: Color(0xFF00897B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '2. Kinh nghiệm & Đội cứu trợ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildFieldLabel(
            'Đội nhóm / Tổ chức cứu nạn từng tham gia',
            isRequired: true,
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller.organizationController,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Nhập tên đội nhóm hoặc tổ chức...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
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
              suffixIcon: const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.group_outlined, size: 18, color: Colors.teal),
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Số năm kinh nghiệm & Số lần tham gia
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Thâm niên hoạt động'),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 38,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: controller.selectedExperience,
                            isExpanded: true,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                            items: controller.experienceOptions
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) controller.setExperience(val);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Số lần tham gia cứu hộ'),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: controller.rescueTimesController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: '0',
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
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 🟢 KHUNG 1: Chọn kỹ năng sẵn có từ danh mục
          _buildFieldLabel('Kỹ năng sơ cấp cứu thành thạo (Chọn từ danh mục)'),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: controller.availableSkills.map((item) {
                final String code = item['maKyNang']!;
                final String name = item['tenKyNang']!;
                final isSelected = controller.selectedSkillCodes.contains(code);

                return GestureDetector(
                  onTap: () => controller.toggleSkillCode(code),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE0F2F1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00897B)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 14,
                          color: isSelected
                              ? const Color(0xFF00897B)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          name,
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
          ),
          const SizedBox(height: 12),

          // 🟢 KHUNG 2: Ghi thêm kỹ năng khác (Ô riêng biệt)
          _buildFieldLabel('Ghi thêm kỹ năng sơ cấp cứu khác (Nếu có)'),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller.customSkillsController,
            maxLines: 2,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText:
                  'Nhập các kỹ năng khác ngoài danh mục trên (phân cách bằng dấu phẩy)...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 11),
              filled: true,
              fillColor: const Color(0xFFEEF2FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 12),

          // Tóm tắt các ca cứu hộ
          _buildFieldLabel('Tóm tắt các ca cứu hộ thực tế từng tham gia'),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller.summaryController,
            maxLines: 3,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Mô tả tóm tắt tình huống sơ cứu thực tế...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
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

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontSize: 10, color: Colors.grey),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
