// lib/user/LichSuCuuHo/views/lich_su_cuu_ho_components.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cuhokhancap/user/LichSuCuuHo/controllers/lich_su_cuu_ho_controller.dart';
import 'package:cuhokhancap/user/Models/danhgiamodel.dart';

class LichSuHistoryCard extends StatelessWidget {
  final RescueHistoryCardData cardData;
  final VoidCallback onCardTap;
  final VoidCallback onReportTap;
  final VoidCallback onEvaluateTap;

  const LichSuHistoryCard({
    super.key,
    required this.cardData,
    required this.onCardTap,
    required this.onReportTap,
    required this.onEvaluateTap,
  });

  String _formatDateTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$hh:$mm - $dd/$mo/${dt.year}';
  }

  String _formatTimeOnly(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  String _extractInjurySummary() {
    final ghiChu = cardData.moTa?.ghiChuText;
    if (ghiChu is Map) {
      final List<String> trieuChung = List<String>.from(
        ghiChu['trieuChung'] ?? [],
      );
      final String moTaChiTiet = (ghiChu['moTaChiTiet'] ?? '')
          .toString()
          .trim();
      final parts = <String>[];
      if (trieuChung.isNotEmpty) parts.add(trieuChung.join(', '));
      if (moTaChiTiet.isNotEmpty) parts.add(moTaChiTiet);
      if (parts.isNotEmpty) return parts.join(' – ');
    } else if (ghiChu is String && ghiChu.trim().isNotEmpty) {
      return ghiChu.trim();
    }
    return 'Hỗ trợ cấp cứu khẩn cấp';
  }

  @override
  Widget build(BuildContext context) {
    final yeuCau = cardData.yeuCau;
    final bool isCompleted = cardData.isCompleted;
    final bool isCanceled = yeuCau.maTinhTrangYeuCau == 'user_tinhtrang_dahuy';

    final Color stripeColor = isCompleted
        ? const Color(0xFFD92D20)
        : Colors.grey;
    final Color badgeBg = isCompleted
        ? const Color(0xFFD1FADF)
        : Colors.grey.shade200;
    final Color badgeText = isCompleted
        ? const Color(0xFF039855)
        : Colors.grey.shade700;
    final String statusLabel = isCompleted
        ? 'Hoàn tất sơ cứu'
        : 'Đã hủy yêu cầu';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onCardTap,
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: stripeColor, width: 5)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. HEADER: MÃ ĐƠN + BADGE TRẠNG THÁI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${yeuCau.maYeuCau.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF101828),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: badgeText,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // 2. THỜI GIAN YÊU CẦU
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Color(0xFF667085),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Thời gian yêu cầu: ${_formatDateTime(yeuCau.thoiGianTao)}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF475467),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3. KHỐI VỊ TRÍ CHẤN THƯƠNG / TRIỆU CHỨNG
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6CE9A6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.healing_rounded,
                            color: Color(0xFF027A48),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Vị trí chấn thương / Triệu chứng',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF101828),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _extractInjurySummary(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF475467),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 4. KHỐI DANH SÁCH NGƯỜI CỨU HỘ ĐÃ TIẾP NHẬN
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0E7460),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medical_services_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DANH SÁCH NGƯỜI CỨU HỘ (${cardData.rescuers.length})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 0.4,
                                  color: Color(0xFF0E7460),
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (cardData.rescuers.isEmpty)
                                const Text(
                                  'Chưa có cứu hộ viên tiếp nhận',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF475467),
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              else
                                ...cardData.rescuers.map((rescuerItem) {
                                  final uid =
                                      rescuerItem.user.maNguoiDung ?? '';
                                  final bool daDanhGia = cardData.danhGiaMap
                                      .containsKey(uid);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '• ${rescuerItem.user.hoTen}',
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF101828),
                                            ),
                                          ),
                                        ),
                                        if (daDanhGia)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.star_rounded,
                                                color: Colors.amber,
                                                size: 15,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                '${cardData.danhGiaMap[uid]!.diemDanhGia}/5',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFB54708),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 5. NHẬT KÝ ĐIỀU PHỐI (TIMELINE - TỰ ĐỘNG ĐÁNH SỐ)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.monitor_heart_outlined,
                            color: Color(0xFFD92D20),
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Nhật ký điều phối',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: Color(0xFF101828),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isCompleted ? 'Hoàn tất' : 'Đã hủy',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? const Color(0xFF039855)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...() {
                    final steps = <Map<String, dynamic>>[
                      {
                        'time': _formatTimeOnly(yeuCau.thoiGianTao),
                        'text': 'Gửi yêu cầu cứu hộ từ thiết bị',
                        'color': const Color(0xFF039855),
                        'isBold': false,
                      },
                    ];

                    if (cardData.rescuers.isNotEmpty ||
                        yeuCau.thoiGianPhanCong != null) {
                      final acceptedTime =
                          yeuCau.thoiGianPhanCong ?? yeuCau.thoiGianTao;
                      steps.add({
                        'time': _formatTimeOnly(acceptedTime),
                        'text':
                            '${cardData.rescuers.length} cứu hộ viên tiếp nhận điều phối',
                        'color': const Color(0xFF039855),
                        'isBold': false,
                      });
                    }

                    steps.add({
                      'time': _formatTimeOnly(
                        yeuCau.thoiGianHoanThanh ?? yeuCau.thoiGianTao,
                      ),
                      'text': isCompleted
                          ? 'Hoàn tất sơ cứu & kết thúc đơn'
                          : 'Đã hủy yêu cầu cứu hộ',
                      'color': isCompleted
                          ? const Color(0xFFD92D20)
                          : Colors.grey,
                      'isBold': true,
                    });

                    return List.generate(steps.length, (i) {
                      final step = steps[i];
                      return _buildTimelineRow(
                        time: step['time'],
                        text: '${i + 1}. ${step['text']}',
                        dotColor: step['color'],
                        isBold: step['isBold'],
                        isLast: i == steps.length - 1,
                      );
                    });
                  }(),

                  // 6. HAI NÚT CHỨC NĂNG: CHỈ HIỂN THỊ KHI KHÔNG PHẢI ĐƠN ĐÃ HỦY
                  if (!isCanceled) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFF2F4F7),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.flag_outlined,
                              color: Color(0xFF344054),
                              size: 18,
                            ),
                            label: const Text(
                              'Phản ánh yêu cầu',
                              style: TextStyle(
                                color: Color(0xFF101828),
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: onReportTap,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cardData.rescuers.isEmpty
                                  ? Colors.grey.shade400
                                  : (cardData.isAllEvaluated
                                        ? const Color(0xFF039855)
                                        : const Color(0xFF006A55)),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(
                              cardData.isAllEvaluated
                                  ? Icons.check_circle_outline
                                  : Icons.star_outline_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              cardData.isAllEvaluated
                                  ? 'Đã đánh giá'
                                  : 'Đánh giá',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: cardData.rescuers.isEmpty
                                ? null
                                : onEvaluateTap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineRow({
    required String time,
    required String text,
    required Color dotColor,
    bool isBold = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: const Color(0xFF344054),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BOTTOM SHEET XEM CHI TIẾT DỮ LIỆU ĐƠN CỨU HỘ KHI NHẤN VÀO CARD
// ============================================================================
class ChiTietLichSuDonBottomSheet extends StatelessWidget {
  final RescueHistoryCardData cardData;

  const ChiTietLichSuDonBottomSheet({super.key, required this.cardData});

  String _formatFullDateTime(DateTime? dt) {
    if (dt == null) return 'Chưa ghi nhận';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$hh:$mm:$ss - $dd/$mo/${dt.year}';
  }

  String _mapLoaiYeuCau(String code) {
    switch (code) {
      case 'loaiyeucau_sos':
        return 'Cứu hộ khẩn cấp SOS';
      case 'loaiyeucau_timtudong':
        return 'Tìm cứu hộ viên tự động (AI)';
      case 'loaiyeucau_choncuuhovien':
        return 'Chỉ định cứu hộ viên trực tiếp';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final yeuCau = cardData.yeuCau;
    final moTa = cardData.moTa;
    final bool isCompleted = cardData.isCompleted;

    List<String> trieuChungList = [];
    String moTaChiTietStr = 'Không có ghi chú thêm.';
    if (moTa != null && moTa.ghiChuText is Map) {
      trieuChungList = List<String>.from(moTa.ghiChuText['trieuChung'] ?? []);
      final rawNote = (moTa.ghiChuText['moTaChiTiet'] ?? '').toString().trim();
      if (rawNote.isNotEmpty) moTaChiTietStr = rawNote;
    } else if (moTa != null &&
        moTa.ghiChuText is String &&
        moTa.ghiChuText.toString().trim().isNotEmpty) {
      moTaChiTietStr = moTa.ghiChuText.toString().trim();
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.assignment_outlined,
                      color: Color(0xFF006A55),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chi tiết đơn #${yeuCau.maYeuCau.toUpperCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Color(0xFF101828),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Thông tin chung
                  _buildSectionCard(
                    title: 'THÔNG TIN YÊU CẦU',
                    children: [
                      _buildDetailRow(
                        'Trạng thái',
                        isCompleted ? 'Hoàn tất sơ cứu' : 'Đã hủy yêu cầu',
                        valueColor: isCompleted
                            ? const Color(0xFF039855)
                            : Colors.red,
                      ),
                      _buildDetailRow(
                        'Hình thức gọi',
                        _mapLoaiYeuCau(yeuCau.maLoaiYeuCau),
                      ),
                      _buildDetailRow(
                        'Mức độ khẩn cấp',
                        yeuCau.mucDoKhanCap == 1
                            ? 'Mức 1 – SOS (Nguy kịch)'
                            : 'Mức 2 – Hỗ trợ y tế',
                        valueColor: yeuCau.mucDoKhanCap == 1
                            ? Colors.red
                            : Colors.orange.shade800,
                      ),
                      _buildDetailRow(
                        'Tọa độ hiện trường',
                        '${yeuCau.viDo.toStringAsFixed(5)}, ${yeuCau.kinhDo.toStringAsFixed(5)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. Mốc thời gian
                  _buildSectionCard(
                    title: 'MỐC THỜI GIAN XỬ LÝ',
                    children: [
                      _buildDetailRow(
                        'Thời gian tạo đơn',
                        _formatFullDateTime(yeuCau.thoiGianTao),
                      ),
                      _buildDetailRow(
                        'Thời gian tiếp nhận',
                        _formatFullDateTime(yeuCau.thoiGianPhanCong),
                      ),
                      _buildDetailRow(
                        isCompleted
                            ? 'Thời gian hoàn thành'
                            : 'Thời gian kết thúc',
                        _formatFullDateTime(yeuCau.thoiGianHoanThanh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3. Mô tả hiện trường & Triệu chứng
                  _buildSectionCard(
                    title: 'MÔ TẢ HIỆN TRƯỜNG & TRIỆU CHỨNG',
                    children: [
                      if (trieuChungList.isNotEmpty) ...[
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: trieuChungList
                              .map(
                                (tc) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    tc,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade800,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        moTaChiTietStr,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF344054),
                          height: 1.4,
                        ),
                      ),
                      if (moTa?.videoUrl != null &&
                          moTa!.videoUrl!.startsWith('http')) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            moTa.videoUrl!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 4. Lực lượng cứu hộ tham gia (Kèm số sao + nhận xét hoặc nhãn Chưa đánh giá)
                  _buildSectionCard(
                    title:
                        'LỰC LƯỢNG CỨU HỘ THAM GIA (${cardData.rescuers.length})',
                    children: cardData.rescuers.isEmpty
                        ? [
                            const Text(
                              'Không có cứu hộ viên nào tiếp nhận đơn này.',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ]
                        : List.generate(cardData.rescuers.length, (idx) {
                            final item = cardData.rescuers[idx];
                            final uid = item.user.maNguoiDung ?? '';
                            final dg = cardData.danhGiaMap[uid];
                            final bool isLast =
                                idx == cardData.rescuers.length - 1;

                            return Container(
                              margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: dg != null
                                      ? const Color(0xFFABEFC6)
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person_pin,
                                        color: Color(0xFF006A55),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.user.hoTen,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                            Text(
                                              'SĐT: ${item.user.soDienThoai}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (dg != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.star_rounded,
                                                color: Colors.amber,
                                                size: 15,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                '${dg.diemDanhGia}/5',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFB54708),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            'Chưa đánh giá',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (dg != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        dg.nhanXet.trim().isNotEmpty
                                            ? 'Nhận xét: "${dg.nhanXet.trim()}"'
                                            : 'Nhận xét: Không có nhận xét.',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontStyle:
                                              dg.nhanXet.trim().isNotEmpty
                                              ? FontStyle.italic
                                              : FontStyle.normal,
                                          color: dg.nhanXet.trim().isNotEmpty
                                              ? const Color(0xFF344054)
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006A55),
              letterSpacing: 0.4,
            ),
          ),
          const Divider(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF667085)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? const Color(0xFF101828),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BOTTOM SHEET ĐÁNH GIÁ TOÀN BỘ NGƯỜI CỨU HỘ ĐÃ NHẬN ĐƠN
// ============================================================================
class DanhGiaCuuHoBottomSheet extends StatefulWidget {
  final String maYeuCau;
  final LichSuCuuHoController controller;

  const DanhGiaCuuHoBottomSheet({
    super.key,
    required this.maYeuCau,
    required this.controller,
  });

  @override
  State<DanhGiaCuuHoBottomSheet> createState() =>
      _DanhGiaCuuHoBottomSheetState();
}

class _DanhGiaCuuHoBottomSheetState extends State<DanhGiaCuuHoBottomSheet> {
  final Map<String, int> _selectedStars = {};
  final Map<String, TextEditingController> _commentControllers = {};
  final Set<String> _submittingIds = {};

  @override
  void dispose() {
    for (var c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  ImageProvider? _buildAvatarProvider(String? avatarData) {
    if (avatarData == null || avatarData.isEmpty) return null;
    if (avatarData.startsWith('http')) return NetworkImage(avatarData);
    try {
      final base64Str = avatarData.contains(',')
          ? avatarData.split(',').last
          : avatarData;
      return MemoryImage(base64Decode(base64Str));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đánh giá đội ngũ cứu hộ (#${widget.maYeuCau.toUpperCase()})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Flexible(
            child: ValueListenableBuilder<List<RescueHistoryCardData>>(
              valueListenable: widget.controller.historyListNotifier,
              builder: (context, list, _) {
                final cardData = list.firstWhere(
                  (c) => c.yeuCau.maYeuCau == widget.maYeuCau,
                );

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true,
                  itemCount: cardData.rescuers.length,
                  itemBuilder: (context, index) {
                    final rescuerItem = cardData.rescuers[index];
                    final user = rescuerItem.user;
                    final String uid = user.maNguoiDung ?? '';
                    final DanhGiaModel? existingReview =
                        cardData.danhGiaMap[uid];
                    final bool isEvaluated = existingReview != null;

                    _selectedStars.putIfAbsent(uid, () => 5);
                    _commentControllers.putIfAbsent(
                      uid,
                      () => TextEditingController(),
                    );

                    final avatarProvider = _buildAvatarProvider(
                      rescuerItem.avatarUrl,
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isEvaluated
                              ? const Color(0xFFABEFC6)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFF006A55),
                                backgroundImage: avatarProvider,
                                child: avatarProvider == null
                                    ? Text(
                                        user.hoTen.isNotEmpty
                                            ? user.hoTen[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.hoTen,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'SĐT: ${user.soDienThoai}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isEvaluated)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1FADF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Đã đánh giá',
                                    style: TextStyle(
                                      color: Color(0xFF039855),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Divider(height: 22),

                          if (isEvaluated) ...[
                            Row(
                              children: [
                                const Text(
                                  'Mức độ hài lòng: ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                                ...List.generate(
                                  5,
                                  (i) => Icon(
                                    Icons.star_rounded,
                                    size: 20,
                                    color: i < existingReview.diemDanhGia
                                        ? Colors.amber
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              ],
                            ),
                            if (existingReview.nhanXet.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Nhận xét: "${existingReview.nhanXet}"',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: Color(0xFF344054),
                                ),
                              ),
                            ],
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (starIdx) {
                                final starValue = starIdx + 1;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedStars[uid] = starValue;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Icon(
                                      Icons.star_rounded,
                                      size: 32,
                                      color: starValue <= _selectedStars[uid]!
                                          ? Colors.amber
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _commentControllers[uid],
                              maxLines: 2,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText:
                                    'Nhập nhận xét về cứu hộ viên ${user.hoTen}...',
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                contentPadding: const EdgeInsets.all(10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF006A55),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 11,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _submittingIds.contains(uid)
                                    ? null
                                    : () async {
                                        setState(() {
                                          _submittingIds.add(uid);
                                        });
                                        final ok = await widget.controller
                                            .submitEvaluation(
                                              maYeuCau: widget.maYeuCau,
                                              maNguoiCuuHo: uid,
                                              diemDanhGia:
                                                  _selectedStars[uid] ?? 5,
                                              nhanXet: _commentControllers[uid]!
                                                  .text,
                                            );
                                        if (mounted) {
                                          setState(() {
                                            _submittingIds.remove(uid);
                                          });
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                ok
                                                    ? 'Đã gửi đánh giá cho ${user.hoTen}!'
                                                    : 'Cứu hộ viên này đã được đánh giá trước đó.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                child: Text(
                                  _submittingIds.contains(uid)
                                      ? 'Đang gửi...'
                                      : 'Gửi đánh giá',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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
}
