// lib/user/HuongDanCuuHo/HuongDanCuuHoScreen.dart
import 'package:cuhokhancap/user/HuongDanCuuHo/controllers/huong_dan_controller.dart';
import 'package:cuhokhancap/user/Models/videohuongdanmodel.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class HuongDanCuuHoScreen extends StatefulWidget {
  const HuongDanCuuHoScreen({super.key});

  @override
  State<HuongDanCuuHoScreen> createState() => _HuongDanCuuHoScreenState();
}

class _HuongDanCuuHoScreenState extends State<HuongDanCuuHoScreen> {
  final HuongDanController _controller = HuongDanController();
  final TextEditingController _searchController = TextEditingController();

  // Màu chủ đạo đồng bộ với thiết kế
  final Color _accentSky = const Color(0xFF7CC7EB);
  final Color _primaryGreen = const Color(0xFF006A55);
  final Color _emergencyRed = const Color(0xFFC81E1E);

  @override
  void initState() {
    super.initState();
    _controller.loadVideos();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openVideoPlayerSheet(VideoHuongDanModel video) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VideoPlayerDetailSheet(video: video),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Video Hướng Dẫn',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. THANH TÌM KIẾM & BỘ LỌC DANH MỤC (CỐ ĐỊNH TRÊN CÙNG)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Ô tìm kiếm
                TextField(
                  controller: _searchController,
                  onChanged: (v) {
                    _controller.updateSearchQuery(v);
                    setState(() {}); // cập nhật nút xóa (x)
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm tình huống, vết thương, CPR, cầm máu...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13.5,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _controller.updateSearchQuery('');
                              setState(() {});
                            },
                          ),
                        // Nút lọc theo mức độ (xanh = đang lọc)
                        ValueListenableBuilder<String?>(
                          valueListenable: _controller.selectedNhanNotifier,
                          builder: (context, nhan, _) => IconButton(
                            icon: Icon(
                              Icons.tune_rounded,
                              color: nhan != null
                                  ? _primaryGreen
                                  : Colors.grey.shade700,
                              size: 20,
                            ),
                            onPressed: _openFilterSheet,
                          ),
                        ),
                      ],
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Hàng ChoiceChip lọc danh mục cuộn ngang
                SizedBox(
                  height: 36,
                  child: ValueListenableBuilder<List<String>>(
                    valueListenable: _controller.categoriesNotifier,
                    builder: (context, categories, _) {
                      return ValueListenableBuilder<String>(
                        valueListenable: _controller.selectedCategoryNotifier,
                        builder: (context, selectedCat, _) {
                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              final bool isSelected = cat == selectedCat;
                              final String label = cat == 'Tất cả'
                                  ? 'Tất cả (${_controller.totalCount})'
                                  : cat;

                              return GestureDetector(
                                onTap: () => _controller.selectCategory(cat),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _accentSky.withOpacity(0.28)
                                        : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? _accentSky
                                          : Colors.transparent,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFF0B4F6C)
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 2. DANH SÁCH THẺ VIDEO HƯỚNG DẪN (dữ liệu thật từ Firestore)
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.isLoadingNotifier,
              builder: (context, isLoading, _) {
                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ValueListenableBuilder<String?>(
                  valueListenable: _controller.errorNotifier,
                  builder: (context, error, _) {
                    // Lỗi mạng / quyền -> báo lỗi + nút thử lại
                    if (error != null) {
                      return _buildStateMessage(
                        icon: Icons.wifi_off_rounded,
                        title: error,
                        actionLabel: 'Thử lại',
                        onAction: _controller.loadVideos,
                      );
                    }

                    return ValueListenableBuilder<List<VideoHuongDanModel>>(
                      valueListenable: _controller.filteredVideosNotifier,
                      builder: (context, videos, _) {
                        if (videos.isEmpty) {
                          // Firestore chưa có video nào
                          if (_controller.totalCount == 0) {
                            return _buildStateMessage(
                              icon: Icons.video_library_outlined,
                              title: 'Chưa có video hướng dẫn nào',
                              subtitle:
                                  'Các video hướng dẫn sơ cứu sẽ xuất hiện ở đây khi được cập nhật.',
                              actionLabel: 'Tải lại',
                              onAction: _controller.loadVideos,
                            );
                          }
                          // Có video nhưng bộ lọc/tìm kiếm không khớp cái nào
                          return _buildStateMessage(
                            icon: Icons.search_off_rounded,
                            title: 'Không tìm thấy video phù hợp',
                            subtitle: 'Thử từ khóa khác hoặc bỏ bớt bộ lọc.',
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: _controller.refresh,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: videos.length,
                            itemBuilder: (context, index) {
                              return _buildVideoCard(videos[index]);
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Bảng chọn lọc theo mức độ (nhanKhanCap lấy từ Firestore)
  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ValueListenableBuilder<List<String>>(
          valueListenable: _controller.nhanOptionsNotifier,
          builder: (context, options, _) {
            return ValueListenableBuilder<String?>(
              valueListenable: _controller.selectedNhanNotifier,
              builder: (context, selected, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lọc theo mức độ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Tất cả'),
                          selected: selected == null,
                          onSelected: (_) {
                            _controller.selectNhan(null);
                            Navigator.pop(sheetCtx);
                          },
                        ),
                        ...options.map(
                          (o) => ChoiceChip(
                            label: Text(o),
                            selected: selected == o,
                            onSelected: (_) {
                              _controller.selectNhan(o);
                              Navigator.pop(sheetCtx);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Khối thông báo giữa màn hình: lỗi / trống / không khớp bộ lọc
  Widget _buildStateMessage({
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryGreen,
                  side: BorderSide(color: _primaryGreen),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(VideoHuongDanModel video) {
    // Hiển thị tối đa 3 bước tóm tắt trên thẻ ngoài cho gọn, bấm vào sẽ xem đủ
    final previewSteps = video.cacBuocThucHien.take(3).toList();

    return GestureDetector(
      onTap: () => _openVideoPlayerSheet(video),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KHUNG THUMBNAIL + BADGE + NÚT PLAY
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      video.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.medical_services_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  // Lớp phủ tối nhẹ để nổi bật nút Play
                  Positioned.fill(
                    child: Container(color: Colors.black.withOpacity(0.18)),
                  ),
                  // Badge góc trên bên trái
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: video.badgeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emergency_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            video.nhanKhanCap,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Thời lượng góc dưới bên trái
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.68),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            video.thoiLuong,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Nút Play tròn ở chính giữa
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 8),
                      ],
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: _emergencyRed,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),

            // 2. TIÊU ĐỀ + HỘP CÁC BƯỚC CỐT LÕI
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.tieuDe,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Khung tóm tắt các bước hành động
                  if (previewSteps.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _emergencyRed.withOpacity(0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.format_list_numbered_rounded,
                                size: 15,
                                color: _emergencyRed,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  video.tieuDeBuoc,
                                  style: TextStyle(
                                    color: _emergencyRed,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ...List.generate(previewSteps.length, (i) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                '${i + 1}. ${previewSteps[i]}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.black87,
                                  height: 1.35,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Dòng chân thẻ gọn gàng: Danh mục + Nút xem video trực tuyến
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _accentSky.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          video.danhMuc,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0B4F6C),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Xem video hướng dẫn',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: _primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: _primaryGreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BOTTOM SHEET TRÌNH PHÁT VIDEO YOUTUBE & HƯỚNG DẪN ĐẦY ĐỦ
// ============================================================================
class _VideoPlayerDetailSheet extends StatefulWidget {
  final VideoHuongDanModel video;

  const _VideoPlayerDetailSheet({required this.video});

  @override
  State<_VideoPlayerDetailSheet> createState() =>
      _VideoPlayerDetailSheetState();
}

class _VideoPlayerDetailSheetState extends State<_VideoPlayerDetailSheet> {
  late YoutubePlayerController _ytController;

  @override
  void initState() {
    super.initState();
    _ytController = YoutubePlayerController.fromVideoId(
      videoId: widget.video.youtubeId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _ytController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.86,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Thanh kéo trên cùng
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Trình phát YouTube ghim cố định ở nửa trên
          YoutubePlayer(controller: _ytController, aspectRatio: 16 / 9),

          // Nửa dưới cuộn xem đầy đủ các bước sơ cứu
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.video.badgeColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.video.nhanKhanCap,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.video.danhMuc,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.video.tieuDe,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.video.tieuDeBuoc,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC81E1E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(widget.video.cacBuocThucHien.length, (i) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: const Color(0xFF006A55),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.video.cacBuocThucHien[i],
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
