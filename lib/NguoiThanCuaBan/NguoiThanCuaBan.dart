// lib/NguoiThanCuaBan.dart

import 'dart:async'; // Cần import để dùng Timer debounce
import 'package:flutter/material.dart';
import 'package:cuhokhancap/models/nguoidungmodel.dart';
import 'package:cuhokhancap/NguoiThanCuaBan/controllers/nguoi_than_controller.dart';
import 'package:cuhokhancap/NguoiThanCuaBan/views/nguoi_than_cua_ban.dart';
import 'package:cuhokhancap/NguoiThanCuaBan/views/danh_sach_yeu_cau.dart';
import 'package:cuhokhancap/NguoiThanCuaBan/views/ket_qua_tim_kiem.dart';
import 'package:cuhokhancap/NguoiThanCuaBan/views/thanh_tim_kiem.dart';
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

  int _selectedTab = 0;
  bool _isSearching = false;
  bool _isLoadingSearch = false; // Trạng thái đang query Firestore
  int _selectedFilterIndex = 0;
  NguoiDungModel? _searchedUser;
  Timer? _debounce; // Chống nháy / mất kết quả khi gõ

  final Color primaryColor = const Color(0xFF006A55);

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final query = value.trim();

    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _isLoadingSearch = false;
        _searchedUser = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoadingSearch = true; // Bật loading
    });

    // Chờ người dùng ngừng gõ 500ms mới tiến hành tìm kiếm trên Firestore
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final result = await _controller.searchUserByPhoneOrEmail(query);
      if (mounted) {
        setState(() {
          _searchedUser = result;
          _isLoadingSearch = false; // Tắt loading
        });
      }
    });
  }

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
                    onChanged: _onSearchChanged,
                    onClear: () {
                      _debounce?.cancel();
                      setState(() {
                        _searchController.clear();
                        _isSearching = false;
                        _isLoadingSearch = false;
                        _searchedUser = null;
                      });
                    },
                    onFilterSelected: (index) =>
                        setState(() => _selectedFilterIndex = index),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

          Expanded(
            child: _selectedTab == 0
                ? NguoiThanCuaBanTab(
                    userId: widget.userId,
                    controller: _controller,
                    primaryColor: primaryColor,
                  )
                : (_isSearching
                      ? (_isLoadingSearch
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: primaryColor,
                                ),
                              )
                            : KetQuaTimKiemWidget(
                                primaryColor: primaryColor,
                                foundUser: _searchedUser,
                                onAddPressed: (user) {
                                  BottomSheetGuiYeuCau.show(
                                    context,
                                    primaryColor,
                                    name: user.hoTen,
                                    phone: user.soDienThoai,
                                    onConfirm: (myRel, targetRel) async {
                                      await _controller.sendRelationRequest(
                                        currentUserId: widget.userId,
                                        targetUserId: user.maNguoiDung!,
                                        myRelation: myRel,
                                        targetRelation: targetRel,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Đã gửi yêu cầu kết nối thành công!',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ))
                      : DanhSachYeuCauWidget(
                          currentUserId: widget.userId,
                          controller: NguoiThanController(),
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
