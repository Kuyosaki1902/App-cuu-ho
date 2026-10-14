import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVCoCCHN/controllers/chv_coCCHN_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SectionHospital extends StatelessWidget {
  const SectionHospital({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CuuHoVienCoCCHNController>();

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.business, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3. Đơn vị công tác & Thẻ ngành',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Bệnh viện tiếp nhận và phối hợp cấp cứu',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFieldLabel(
            'Bệnh viện / Cơ sở khám chữa bệnh hiện tại',
            isRequired: true,
          ),
          const SizedBox(height: 6),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.selectedHospital,
                isExpanded: true,
                style: const TextStyle(fontSize: 13, color: Colors.black),
                items: controller.hospitalList
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) controller.setHospital(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildFormGroup(
            label: 'Chức danh chuyên môn trực tiếp',
            controller: controller.positionController,
            prefixIcon: const Icon(
              Icons.medical_services_outlined,
              color: Colors.teal,
              size: 18,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildFormGroup(
                  label: 'Mã thẻ nhân viên',
                  controller: controller.employeeIdController,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Ảnh thẻ công tác'),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'the_nganh.jpg',
                              style: TextStyle(
                                color: Colors.teal,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(Icons.image, color: Colors.teal, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

  Widget _buildFormGroup({
    required String label,
    required TextEditingController controller,
    Widget? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            isDense: true,
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
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: prefixIcon,
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
        ),
      ],
    );
  }
}
