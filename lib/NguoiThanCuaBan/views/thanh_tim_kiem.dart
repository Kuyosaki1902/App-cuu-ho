// lib/views/nguoi_than/thanh_tim_kiem.dart

import 'package:flutter/material.dart';

class ThanhTimKiemWidget extends StatelessWidget {
  final TextEditingController searchController;
  final bool isSearching;
  final int selectedFilterIndex;
  final Color primaryColor;
  final Function(String) onChanged;
  final VoidCallback onClear;
  final Function(int) onFilterSelected;

  const ThanhTimKiemWidget({
    super.key,
    required this.searchController,
    required this.isSearching,
    required this.selectedFilterIndex,
    required this.primaryColor,
    required this.onChanged,
    required this.onClear,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        TextField(
          controller: searchController,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Tìm theo số điện thoại, email hoặc...',
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: isSearching || searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.grey),
                    onPressed: onClear,
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (!isSearching) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(0, 'Tất cả', count: 4),
                const SizedBox(width: 8),
                _buildFilterChip(1, 'Yêu cầu đã nhận', count: 2),
                const SizedBox(width: 8),
                _buildFilterChip(2, 'Yêu cầu đã gửi', count: 2),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChip(int index, String label, {required int count}) {
    bool isSelected = selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => onFilterSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
