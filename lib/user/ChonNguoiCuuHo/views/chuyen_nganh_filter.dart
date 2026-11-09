// views/chuyen_nganh_filter.dart

import 'package:flutter/material.dart';

class ChuyenNganhFilterWidget extends StatelessWidget {
  final int selectedCategoryIndex;
  final Function(int) onCategorySelected;
  final VoidCallback onFilterPressed; // Nút mở bảng lọc phụ bên phải

  const ChuyenNganhFilterWidget({
    super.key,
    required this.selectedCategoryIndex,
    required this.onCategorySelected,
    required this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> tabs = [
      "Tất Cả",
      "Cứu Hộ Có Chứng Chỉ",
      "Cứu Hộ Không Có Chứng Chỉ",
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedCategoryIndex == index;
                  return GestureDetector(
                    onTap: () => onCategorySelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0C5C4D)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tabs[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Nút Lọc bổ sung bên phải
          InkWell(
            onTap: onFilterPressed,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.filter_list, size: 16, color: Color(0xFF0C5C4D)),
                  SizedBox(width: 4),
                  Text(
                    'Lọc',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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
