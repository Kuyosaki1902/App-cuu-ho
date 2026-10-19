// lib/NguoiThanCuaBan.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cuhokhancap/user/models/nguoidungmodel.dart';
import 'package:cuhokhancap/user/NguoiThanCuaBan/controllers/nguoi_than_controller.dart';
import 'package:cuhokhancap/user/NguoiThanCuaBan/views/nguoi_than_cua_ban.dart';
import 'package:cuhokhancap/user/NguoiThanCuaBan/views/danh_sach_yeu_cau.dart';
import 'package:cuhokhancap/user/NguoiThanCuaBan/views/ket_qua_tim_kiem.dart';
import 'package:cuhokhancap/user/NguoiThanCuaBan/views/thanh_tim_kiem.dart';
import 'package:cuhokhancap/user/NguoiThanCuaBan/views/bottom_sheet_gui_yeu_cau.dart';

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
  bool _isLoadingSearch = false;
  int _selectedFilterIndex = 0;
  SearchUserResult? _searchResult;
  Timer? _debounce;

  final Color primaryColor = const Color(0xFF006A55);

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // 🛠 Hàm tiện ích để dọn dẹp thanh tìm kiếm
  void _clearSearch() {
    _debounce?.cancel();
    setState(() {
      _searchController.clear();
      _isSearching = false;
      _isLoadingSearch = false;
      _searchResult = null;
    });
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final query = value.trim();

    if (query.isEmpty) {
      _clearSearch();
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoadingSearch = true;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final result = await _controller.searchUserByPhoneOrEmail(
        query: query,
        currentUserId: widget.userId,
      );

      if (mounted) {
        setState(() {
          _searchResult = result;
          _isLoadingSearch = false;
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
                        onTap: () {
                          _clearSearch(); // 🛠 Reset thanh tìm kiếm khi bấm chuyển sang Tab Người Thân
                          setState(() => _selectedTab = 0);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTabButton(
                        title: 'Tìm Kiếm Người Thân',
                        isSelected: _selectedTab == 1,
                        onTap: () {
                          _clearSearch(); // 🛠 Reset thanh tìm kiếm khi bấm chọn Tab Tìm Kiếm
                          setState(() => _selectedTab = 1);
                        },
                      ),
                    ),
                  ],
                ),
                if (_selectedTab == 1)
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _controller.getPendingRequestsStream(widget.userId),
                    builder: (context, snapshot) {
                      final allRequests = snapshot.data ?? [];
                      final receivedCount = allRequests
                          .where((req) => req['type'] == 'received')
                          .length;
                      final sentCount = allRequests
                          .where((req) => req['type'] == 'sent')
                          .length;

                      return ThanhTimKiemWidget(
                        searchController: _searchController,
                        isSearching: _isSearching,
                        selectedFilterIndex: _selectedFilterIndex,
                        primaryColor: primaryColor,
                        receivedCount: receivedCount,
                        sentCount: sentCount,
                        onChanged: _onSearchChanged,
                        onClear: _clearSearch,
                        onFilterSelected: (index) {
                          _clearSearch(); // 🛠 Reset thanh tìm kiếm khi bấm chọn các Filter (Tất cả / Đã nhận / Đã gửi)
                          setState(() => _selectedFilterIndex = index);
                        },
                      );
                    },
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
                                searchResult: _searchResult,
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

                                      // 🌟 CẬP NHẬT TRẠNG THÁI TRỰC TIẾP TRÊN LOCAL STATE
                                      // Nút bấm sẽ đổi thành "Đã gửi" lập tức mà KHÔNG CẦN gọi query Firestore lại
                                      if (mounted && _searchResult != null) {
                                        setState(() {
                                          _searchResult = SearchUserResult(
                                            user: _searchResult!.user,
                                            status:
                                                'pending', // Đổi trạng thái sang Chờ phản hồi
                                          );
                                        });
                                      }

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
                          controller: _controller,
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
