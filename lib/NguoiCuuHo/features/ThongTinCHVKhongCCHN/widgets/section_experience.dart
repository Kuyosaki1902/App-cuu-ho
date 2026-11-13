import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/chv_khong_cchn_controller.dart';
import 'form_widgets.dart';

class SectionExperience extends StatelessWidget {
  const SectionExperience({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CuuHoVienKhongCCHNController>();

    return FormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            icon: Icons.stars,
            title: '2. Kinh nghiệm & Đội cứu trợ',
          ),
          const SizedBox(height: 12),

          // Tổ chức: chọn từ danh sách đã đăng ký, không gõ tự do
          LabeledField(
            label: 'Đội nhóm / Tổ chức (chọn từ danh sách đã đăng ký)',
            isRequired: true,
            controller: c.organizationController,
            readOnly: true,
            hint: 'Chọn đội nhóm / tổ chức...',
            onTap: () async {
              final v = await showSelectionDialog(
                context,
                title: 'Chọn đội nhóm / tổ chức',
                icon: Icons.group_outlined,
                items: c.organizationOptions,
                selected: c.organizationController.text,
              );
              if (v != null) c.organizationController.text = v;
            },
            suffix: const Icon(Icons.group_outlined, size: 18, color: Colors.teal),
            validator: (v) => c.validateRequired(v, 'Vui lòng chọn đội nhóm / tổ chức'),
          ),
          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Thâm niên hoạt động'),
                    const SizedBox(height: 4),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: kFieldFill,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: c.selectedExperience,
                          isExpanded: true,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          items: c.experienceOptions
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) c.setExperience(val);
                          },
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
                    const FieldLabel('Số lần tham gia cứu hộ (tự khai)'),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: c.rescueTimesController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      decoration: fieldDecoration(hint: '0'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const FieldLabel('Kỹ năng sơ cấp cứu (chọn từ danh mục)'),
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
              children: c.availableSkills.map((item) {
                final code = item['maKyNang']!;
                final name = item['tenKyNang']!;
                final isSelected = c.selectedSkillCodes.contains(code);

                return GestureDetector(
                  onTap: () => c.toggleSkillCode(code),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? kTealLight : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? kTeal : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          size: 14,
                          color: isSelected ? kTeal : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? kTealDark : Colors.black87,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Đây là kỹ năng tự khai. Chỉ những kỹ năng được người duyệt xác nhận '
            'qua minh chứng và bài kiểm tra mới được dùng để điều phối ca.',
            style: TextStyle(fontSize: 10, color: Colors.black45),
          ),
          const SizedBox(height: 12),

          LabeledField(
            label: 'Kỹ năng khác (tự khai, nếu có)',
            controller: c.customSkillsController,
            maxLines: 2,
            hint: 'Các kỹ năng ngoài danh mục, phân cách bằng dấu phẩy...',
          ),
          const SizedBox(height: 12),

          LabeledField(
            label: 'Tóm tắt các ca cứu hộ thực tế từng tham gia',
            controller: c.summaryController,
            maxLines: 3,
            hint: 'Mô tả tóm tắt tình huống sơ cứu thực tế...',
          ),
        ],
      ),
    );
  }
}
