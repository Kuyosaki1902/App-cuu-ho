import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/chv_coCCHN_controller.dart';

class SectionCchn extends StatelessWidget {
  const SectionCchn({super.key});

  /// Hàm dùng chung hiển thị Dialog chọn dữ liệu có ô tìm kiếm
  void _showSelectionDialog({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<String> items,
    required String? currentValue,
    required ValueChanged<String> onSelected,
  }) {
    List<String> filteredItems = List.from(items);
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.redAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chọn $title',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    // Ô tìm kiếm
                    TextField(
                      controller: searchController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm $title...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: Colors.redAccent,
                        ),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  searchController.clear();
                                  setStateDialog(() {
                                    filteredItems = List.from(items);
                                  });
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (query) {
                        setStateDialog(() {
                          filteredItems = items
                              .where(
                                (item) => item.toLowerCase().contains(
                                  query.toLowerCase(),
                                ),
                              )
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Danh sách lựa chọn
                    Flexible(
                      child: filteredItems.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 40,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Không tìm thấy kết quả phù hợp',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filteredItems.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                final isSelected = currentValue == item;

                                return InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    onSelected(item);
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFFFEBEE)
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.redAccent
                                            : Colors.grey.shade200,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          icon,
                                          size: 18,
                                          color: isSelected
                                              ? Colors.redAccent
                                              : Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            item,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? Colors.red.shade900
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.check_circle,
                                            size: 18,
                                            color: Colors.redAccent,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

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

          // 🟢 Chuyên ngành & Chức vụ (Mở Dialog chọn)
          Row(
            children: [
              Expanded(
                child: _buildSelectField(
                  label: 'Chuyên ngành',
                  isRequired: true,
                  value: controller.selectedScope,
                  placeholder: 'Chọn chuyên ngành',
                  onTap: () => _showSelectionDialog(
                    context: context,
                    title: 'chuyên ngành',
                    icon: Icons.medical_services_outlined,
                    items: controller.scopeList,
                    currentValue: controller.selectedScope,
                    onSelected: (val) => controller.setScope(val),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSelectField(
                  label: 'Chức vụ',
                  isRequired: true,
                  value: controller.selectedPosition,
                  placeholder: 'Chọn chức vụ',
                  onTap: () => _showSelectionDialog(
                    context: context,
                    title: 'chức vụ',
                    icon: Icons.work_outline,
                    items: controller.positionList,
                    currentValue: controller.selectedPosition,
                    onSelected: (val) => controller.setPosition(val),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 🟢 Cơ quan cấp (Mở Dialog chọn) & Ngày cấp
          Row(
            children: [
              Expanded(
                child: _buildSelectField(
                  label: 'Cơ quan cấp',
                  isRequired: true,
                  value: controller.selectedCchnIssuer,
                  placeholder: 'Chọn cơ quan cấp',
                  onTap: () => _showSelectionDialog(
                    context: context,
                    title: 'cơ quan cấp',
                    icon: Icons.account_balance_outlined,
                    items: controller.cchnIssuerList,
                    currentValue: controller.selectedCchnIssuer,
                    onSelected: (val) => controller.setCchnIssuer(val),
                  ),
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

  /// Widget tùy chỉnh cho các ô chọn kích hoạt Dialog
  Widget _buildSelectField({
    required String label,
    required bool isRequired,
    required String? value,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, isRequired: isRequired),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: value != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: value != null
                          ? Colors.black87
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
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
