// lib/NguoiThanCuaBan.dart

import 'package:cuhokhancap/NguoiThanCuaBan/views/danh_sach_yeu_cau.dart';
import 'package:cuhokhancap/NguoiThanCuaBan/views/ket_qua_tim_kiem.dart';
import 'package:cuhokhancap/NguoiThanCuaBan/views/nguoi_than_cua_ban.dart';
import 'package:cuhokhancap/NguoiThanCuaBan/views/thanh_tim_kiem.dart';
import 'package:flutter/material.dart';
import 'controllers/nguoi_than_controller.dart';
import 'package:cuhokhancap/NguoiThanCuaBan/views/bottom_sheet_gui_yeu_cau.dart';

class NguoiThanCuaBan extends StatefulWidget {
  final String userId;
  const NguoiThanCuaBan({super.key, required this.userId});

  @override
  State<NguoiThanCuaBan> createState() => _NguoiThanCuaBanState();
}

class _NguoiThanCuaBanState extends State<NguoiThanCuaBan> {
  final NguoiThanController _controller = NguoiThanController();
  final TextEditingController _searchController = TextEditingController();

  int _selectedTab = 0; // 0: Tab Người thân, 1: Tab Tìm kiếm
  bool _isSearching = false;
  int _selectedFilterIndex = 0; // 0: Tất cả, 1: Đã nhận, 2: Đã gửi

  final Color primaryColor = const Color(0xFF006A55);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Người Thân Của Bạn',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. CỐ ĐỊNH PHÍA TRÊN: TAB VÀ THANH TÌM KIẾM
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        title: 'Người Thân Của Bạn',
                        isSelected: _selectedTab == 0,
                        onTap: () => setState(() => _selectedTab = 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTabButton(
                        title: 'Tìm Kiếm Người Thân',
                        isSelected: _selectedTab == 1,
                        onTap: () => setState(() => _selectedTab = 1),
                      ),
                    ),
                  ],
                ),
                if (_selectedTab == 1)
                  ThanhTimKiemWidget(
                    searchController: _searchController,
                    isSearching: _isSearching,
                    selectedFilterIndex: _selectedFilterIndex,
                    primaryColor: primaryColor,
                    onChanged: (value) =>
                        setState(() => _isSearching = value.trim().isNotEmpty),
                    onClear: () {
                      setState(() {
                        _searchController.clear();
                        _isSearching = false;
                      });
                    },
                    onFilterSelected: (index) =>
                        setState(() => _selectedFilterIndex = index),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

          // 2. PHẦN HIỂN THỊ THAY ĐỔI
          Expanded(
            child: _selectedTab == 0
                ? NguoiThanCuaBanTab(
                    userId: widget.userId,
                    controller: _controller,
                    primaryColor: primaryColor,
                  )
                : (_isSearching
                      ? KetQuaTimKiemWidget(
                          primaryColor: primaryColor,
                          onAddPressed: () =>
                              BottomSheetGuiYeuCau.show(context, primaryColor),
                        )
                      : DanhSachYeuCauWidget(
                          selectedFilterIndex: _selectedFilterIndex,
                          primaryColor: primaryColor,
                        )),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
