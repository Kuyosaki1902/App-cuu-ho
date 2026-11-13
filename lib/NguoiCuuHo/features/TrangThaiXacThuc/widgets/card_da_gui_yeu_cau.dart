import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/trang_thai_ho_so.dart';

/// Card đầu trang: tiêu đề + lời nhắn theo trạng thái, nhóm CCHN / không CCHN,
/// kèm mã hồ sơ để sao chép.
class CardDaGuiYeuCau extends StatelessWidget {
  final String maHoSo;
  final bool isCoCCHN;
  final TrangThaiHoSo trangThai;
  final int capDoUyTin;

  const CardDaGuiYeuCau({
    super.key,
    required this.maHoSo,
    this.isCoCCHN = false,
    this.trangThai = TrangThaiHoSo.tiepNhan,
    this.capDoUyTin = 0,
  });

  String get _tieuDe {
    switch (trangThai) {
      case TrangThaiHoSo.tiepNhan:
      case TrangThaiHoSo.dangThamDinh:
        return 'Đã gửi yêu cầu xác thực!';
      case TrangThaiHoSo.canBoSung:
        return 'Hồ sơ cần bổ sung';
      case TrangThaiHoSo.tuChoi:
        return 'Hồ sơ chưa được chấp nhận';
      case TrangThaiHoSo.tamKhoa:
        return 'Quyền cứu hộ đang bị khóa tạm';
      case TrangThaiHoSo.daDuyet:
        return 'Hồ sơ đã được phê duyệt';
      case TrangThaiHoSo.khongXacDinh:
        return 'Không xác định được trạng thái';
    }
  }

  String get _loiNhan {
    switch (trangThai) {
      case TrangThaiHoSo.tiepNhan:
      case TrangThaiHoSo.dangThamDinh:
        return isCoCCHN
            ? 'Hệ thống cấp cứu 115 trân trọng cảm ơn tinh thần sẵn sàng cứu trợ của bạn. '
                'Hồ sơ đang được đối chiếu với danh sách người hành nghề.'
            : 'Hệ thống cấp cứu 115 trân trọng cảm ơn tinh thần sẵn sàng hỗ trợ cộng đồng của bạn. '
                'Hồ sơ đang được đối chiếu giấy tờ, minh chứng và người bảo chứng.';
      case TrangThaiHoSo.canBoSung:
        return 'Người duyệt đã xem hồ sơ và cần thêm thông tin trước khi quyết định.';
      case TrangThaiHoSo.tuChoi:
        return 'Hồ sơ hiện chưa đáp ứng điều kiện. Bạn có thể xem lý do và gửi lại.';
      case TrangThaiHoSo.tamKhoa:
        return 'Tài khoản tạm thời không nhận được ca để đảm bảo an toàn cho người bị nạn.';
      case TrangThaiHoSo.daDuyet:
        return 'Bạn có thể bắt đầu nhận ca theo phạm vi của cấp uy tín hiện tại.';
      case TrangThaiHoSo.khongXacDinh:
        return 'Ứng dụng chưa hiểu trạng thái hiện tại của hồ sơ.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mau = trangThai.color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: trangThai.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(trangThai.icon, color: mau, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            _tieuDe,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loiNhan,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
          ),
          if (trangThai == TrangThaiHoSo.daDuyet && !isCoCCHN && capDoUyTin > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: trangThai.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Cấp uy tín $capDoUyTin',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: mau,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEDF2F7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.badge_outlined, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Mã hồ\nsơ:',
                  style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    maHoSo,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: maHoSo));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép mã hồ sơ!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.copy, size: 14, color: Color(0xFF0284C7)),
                        SizedBox(width: 6),
                        Text(
                          'Sao\nchép',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF0284C7),
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
