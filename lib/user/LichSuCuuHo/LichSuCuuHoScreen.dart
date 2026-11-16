// lib/user/LichSuCuuHo/LichSuCuuHoScreen.dart
import 'package:flutter/material.dart';
import 'package:cuhokhancap/user/LichSuCuuHo/controllers/lich_su_cuu_ho_controller.dart';
import 'package:cuhokhancap/user/LichSuCuuHo/views/lich_su_cuu_ho_components.dart';

class LichSuCuuHoScreen extends StatefulWidget {
  final String currentUserId;

  const LichSuCuuHoScreen({super.key, required this.currentUserId});

  @override
  State<LichSuCuuHoScreen> createState() => _LichSuCuuHoScreenState();
}

class _LichSuCuuHoScreenState extends State<LichSuCuuHoScreen> {
  late final LichSuCuuHoController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LichSuCuuHoController(currentUserId: widget.currentUserId);
    _controller.loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openDetailSheet(RescueHistoryCardData cardData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChiTietLichSuDonBottomSheet(cardData: cardData),
    );
  }

  void _openEvaluationSheet(String maYeuCau) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DanhGiaCuuHoBottomSheet(
          maYeuCau: maYeuCau,
          controller: _controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF101828)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lịch Sử Cứu Hộ',
          style: TextStyle(
            color: Color(0xFF101828),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _controller.isLoadingNotifier,
        builder: (context, isLoading, _) {
          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF006A55)),
            );
          }

          return ValueListenableBuilder<List<RescueHistoryCardData>>(
            valueListenable: _controller.historyListNotifier,
            builder: (context, historyList, _) {
              if (historyList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có lịch sử cứu hộ nào.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: const Color(0xFF006A55),
                onRefresh: _controller.loadHistory,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: historyList.length,
                  itemBuilder: (context, index) {
                    final cardData = historyList[index];
                    return LichSuHistoryCard(
                      cardData: cardData,
                      onCardTap: () {
                        _openDetailSheet(cardData);
                      },
                      onReportTap: () {
                        // Để trống nút Phản ánh yêu cầu theo yêu cầu
                      },
                      onEvaluateTap: () {
                        _openEvaluationSheet(cardData.yeuCau.maYeuCau);
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
