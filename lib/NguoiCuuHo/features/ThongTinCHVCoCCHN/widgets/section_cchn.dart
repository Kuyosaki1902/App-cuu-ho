import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVCoCCHN/controllers/chv_coCCHN_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SectionCchn extends StatelessWidget {
  const SectionCchn({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CuuHoVienCoCCHNController>();

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '2. Chứng chỉ hành nghề y tế (CCHN)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Bắt buộc theo Luật Khám chữa bệnh',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFieldLabel('Số hiệu chứng chỉ hành nghề', isRequired: true),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: controller.cchnNoController,
                  suffixIcon: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00897B),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 1, 121, 101),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                ),
                onPressed: () {},
                icon: const Icon(Icons.sync, size: 16, color: Colors.white),
                label: const Text(
                  'Đối soát BYT',
                  style: TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF00897B),
                  size: 16,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Đã đối soát cổng CSDL Quốc gia Y tế: Hợp lệ & Đang hiệu lực',
                    style: TextStyle(fontSize: 11, color: Color(0xFF004D40)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildFieldLabel('Phạm vi hoạt động chuyên môn', isRequired: true),
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
                value: controller.selectedScope,
                isExpanded: true,
                style: const TextStyle(fontSize: 13, color: Colors.black),
                items: controller.scopeList
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) controller.setScope(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Cơ quan cấp', isRequired: true),
                    const SizedBox(height: 4),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.only(left: 8, right: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: controller.selectedCchnIssuer,
                          isExpanded: true,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black,
                          ),
                          items: controller.cchnIssuerList
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) controller.setCchnIssuer(val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFormGroup(
                  label: 'Ngày cấp',
                  isRequired: true,
                  controller: controller.cchnIssueDateController,
                  readOnly: true,
                  onTap: () => controller.selectDate(
                    context,
                    controller.cchnIssueDateController,
                  ),
                  suffixIcon: const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
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
      child: child,
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
    bool isRequired = false,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, isRequired: isRequired),
        const SizedBox(height: 4),
        _buildInputField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          suffixIcon: suffixIcon,
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
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
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 6),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}
