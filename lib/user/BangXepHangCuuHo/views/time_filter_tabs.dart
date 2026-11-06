// lib/BangXepHangCuuHo/views/time_filter_tabs.dart

import 'package:flutter/material.dart';

class TimeFilterTabsWidget extends StatelessWidget {
  final int selectedTab;
  final List<String> tabs;
  final Function(int) onTabSelected;

  const TimeFilterTabsWidget({
    super.key,
    required this.selectedTab,
    required this.tabs,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0).withOpacity(0.6),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = selectedTab == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTabSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.black87 : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
