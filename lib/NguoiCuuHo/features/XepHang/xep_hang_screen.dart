import 'package:cuhokhancap/NguoiCuuHo/Features/DangKy_DangNhap/controllers/anh_dai_dien_service.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThanhTich/widgets/thanh_tich_common.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/XepHang/models/quy_tac_diem.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/XepHang/controllers/xep_hang_controller.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/XepHang/models/xep_hang_model.dart';

class XepHangScreen extends StatelessWidget {
  final String userId;

  /// Việc cần làm trước khi tải bảng "Từ trước đến nay" (ví dụ làm mới điểm tổng),
  /// do nơi mở màn hình truyền vào để Xếp hạng không phải import tính năng Thành tích.
  final Future<void> Function()? lamMoiDiem;

  const XepHangScreen({super.key, required this.userId, this.lamMoiDiem});

  static Future<void> mo(
    BuildContext context,
    String userId, {
    Future<void> Function()? lamMoiDiem,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => XepHangScreen(userId: userId, lamMoiDiem: lamMoiDiem),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          XepHangController(userId, lamMoiTruocKhiTaiTatCa: lamMoiDiem)
            ..taiBangXepHang(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: kDen,
          elevation: 0.5,
          centerTitle: true,
          title: const Text(
            'Bảng xếp hạng',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26),
          ),
          actions: [
            Builder(
              builder: (ctx) => TextButton.icon(
                onPressed: () => _hienCachTinhDiem(ctx),
                icon: const Icon(Icons.info_outline_rounded, size: 18),
                label: const Text('Cách\nxếp hạng'),
              ),
            ),
          ],
        ),
        body: const _NoiDungXepHang(),
      ),
    );
  }
}

class _NoiDungXepHang extends StatelessWidget {
  const _NoiDungXepHang();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<XepHangController>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _ChonKy(ky: c.ky, onChon: c.doiKy),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: Text(
            c.nhanKy,
            style: const TextStyle(
              fontSize: 12,
              color: kXam,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: _noiDung(c)),
        if (c.mucCuaToi != null && !c.toiTrongBang)
          _ThanhHangCuaToi(item: c.mucCuaToi!, theoKy: c.ky != KyXepHang.tatCa),
      ],
    );
  }

  Widget _noiDung(XepHangController c) {
    final theoKy = c.ky != KyXepHang.tatCa;

    if (c.dangTaiBang && c.bangXepHang.isEmpty)
      return const Center(child: CircularProgressIndicator());
    if (c.loiBang != null && c.bangXepHang.isEmpty) {
      return TrangThaiRong(
        icon: Icons.wifi_off_rounded,
        tieuDe: c.loiBang!,
        nutText: 'Thử lại',
        onNut: c.taiBangXepHang,
      );
    }

    final bang = c.bangXepHang;
    final top = bang.take(3).toList();
    final con = bang.skip(3).toList();

    return RefreshIndicator(
      onRefresh: c.taiBangXepHang,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          if (bang.isEmpty)
            const TrangThaiRong(
              icon: Icons.emoji_events_outlined,
              tieuDe: 'Chưa có ai trong kỳ này',
              moTa: 'Hoàn thành ca cứu hộ để có tên trên bảng xếp hạng.',
            )
          else ...[
            _Podium(top: top, userId: c.userId, theoKy: theoKy),
            const SizedBox(height: 14),
            for (final e in con)
              _DongXepHang(
                item: e,
                laToi: e.maNguoiDung == c.userId,
                theoKy: theoKy,
              ),
          ],
        ],
      ),
    );
  }
}

class _ChonKy extends StatelessWidget {
  final KyXepHang ky;
  final ValueChanged<KyXepHang> onChon;
  const _ChonKy({required this.ky, required this.onChon});

  @override
  Widget build(BuildContext context) {
    const nhan = {
      KyXepHang.tuan: 'Tuần này',
      KyXepHang.thang: 'Tháng này',
      KyXepHang.tatCa: 'Mọi thời gian',
    };
    return Wrap(
      spacing: 8,
      children: [
        for (final k in KyXepHang.values)
          ChoiceChip(
            label: Text(nhan[k]!),
            selected: ky == k,
            showCheckmark: false,
            selectedColor: const Color(0xFFFEE2E2),
            labelStyle: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: ky == k ? kDo : kXam,
            ),
            onSelected: (_) => onChon(k),
          ),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  final List<XepHangItem> top;
  final String userId;
  final bool theoKy;
  const _Podium({
    required this.top,
    required this.userId,
    required this.theoKy,
  });

  @override
  Widget build(BuildContext context) {
    XepHangItem? at(int i) => i < top.length ? top[i] : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _CotPodium(
            item: at(1),
            cao: 70,
            mau: const Color(0xFF64748B),
            userId: userId,
            theoKy: theoKy,
          ),
        ),
        Expanded(
          child: _CotPodium(
            item: at(0),
            cao: 96,
            mau: const Color(0xFFCA8A04),
            coVuongMien: true,
            userId: userId,
            theoKy: theoKy,
          ),
        ),
        Expanded(
          child: _CotPodium(
            item: at(2),
            cao: 54,
            mau: const Color(0xFF9A5B2E),
            userId: userId,
            theoKy: theoKy,
          ),
        ),
      ],
    );
  }
}

class _CotPodium extends StatelessWidget {
  final XepHangItem? item;
  final double cao;
  final Color mau;
  final bool coVuongMien;
  final String userId;
  final bool theoKy;
  const _CotPodium({
    required this.item,
    required this.cao,
    required this.mau,
    required this.userId,
    required this.theoKy,
    this.coVuongMien = false,
  });

  @override
  Widget build(BuildContext context) {
    final it = item;
    if (it == null) return SizedBox(height: cao);
    final laToi = it.maNguoiDung == userId;
    AnhDaiDienService avatar = AnhDaiDienService();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (coVuongMien)
          const Icon(
            Icons.emoji_events_rounded,
            color: Color(0xFFCA8A04),
            size: 26,
          )
        else
          const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: laToi ? kDo : Colors.transparent,
              width: 2,
            ),
          ),
          child: _AvatarNguoiDung(
            userId: it.maNguoiDung,
            tenHienThi: it.tenHienThi,
            radius: coVuongMien ? 28 : 24,
            mau: mau,
            fontSize: coVuongMien ? 20 : 17,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            it.tenHienThi,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: laToi ? FontWeight.w900 : FontWeight.w700,
              color: kDen,
            ),
          ),
        ),
        Text(
          theoKy ? '${it.soCaHoanThanh} ca' : '${it.diem} điểm',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: mau,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: cao,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: mau.withOpacity(0.18),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Text(
            '#${it.hang}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: mau,
            ),
          ),
        ),
      ],
    );
  }
}

class _DongXepHang extends StatelessWidget {
  final XepHangItem item;
  final bool laToi;
  final bool theoKy;
  const _DongXepHang({
    required this.item,
    required this.laToi,
    required this.theoKy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: laToi ? const Color(0xFFFFF1F2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: laToi ? const Color(0xFFFECDD3) : kVien),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '${item.hang}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: kXam,
              ),
            ),
          ),
          _AvatarNguoiDung(
            userId: item.maNguoiDung,
            tenHienThi: item.tenHienThi,
            radius: 18,
            mau: kXam,
            fontSize: 14,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  laToi ? '${item.tenHienThi} (Bạn)' : item.tenHienThi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: laToi ? FontWeight.w900 : FontWeight.w700,
                    color: kDen,
                  ),
                ),
                const SizedBox(height: 3),
                NhanLoai(loai: item.loaiHoSo),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                theoKy ? '${item.soCaHoanThanh} ca' : '${item.diem} điểm',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: kDen,
                ),
              ),
              if (!theoKy)
                Text(
                  '${item.soCaHoanThanh} ca hoàn thành',
                  style: const TextStyle(fontSize: 10.5, color: kXamNhat),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThanhHangCuaToi extends StatelessWidget {
  final XepHangItem item;
  final bool theoKy;
  const _ThanhHangCuaToi({required this.item, required this.theoKy});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.person_pin_circle_rounded, color: kDo),
            const SizedBox(width: 8),
            Text(
              'Hạng của bạn: #${item.hang}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: kDen,
              ),
            ),
            const Spacer(),
            Text(
              theoKy ? '${item.soCaHoanThanh} ca' : '${item.diem} điểm',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: kXam,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _hienCachTinhDiem(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cách xếp hạng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: kDen,
            ),
          ),
          const SizedBox(height: 12),
          _DongCongThuc(
            'Tuần, tháng',
            'Xếp theo số ca hoàn thành trong kỳ (${QuyTacDiem.diemMoiCa} điểm/ca).',
          ),
          const _DongCongThuc(
            'Tất cả',
            'Xếp theo tổng điểm tích luỹ, gồm cả chuyên cần, chất lượng và ca bỏ lỡ.',
          ),
          const _DongCongThuc(
            'Đồng hạng',
            'Cùng điểm thì cùng thứ hạng; thứ tự trong nhóm xét theo số ca rồi tên.',
          ),
          const SizedBox(height: 10),
          const Text(
            'Chi tiết công thức điểm và cấp bậc có trong màn hình Thành tích.',
            style: TextStyle(fontSize: 12, height: 1.4, color: kXam),
          ),
        ],
      ),
    ),
  );
}

class _AvatarNguoiDung extends StatelessWidget {
  final String userId;
  final String tenHienThi;
  final double radius;
  final Color mau;
  final double fontSize;

  const _AvatarNguoiDung({
    required this.userId,
    required this.tenHienThi,
    required this.radius,
    required this.mau,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final future = context.read<XepHangController>().layAvatarProvider(userId);
    return FutureBuilder<ImageProvider?>(
      future: future,
      builder: (context, snap) {
        final img = snap.data;
        return CircleAvatar(
          radius: radius,
          backgroundColor: mau.withOpacity(0.15),
          backgroundImage: img,
          child: img != null
              ? null
              : Text(
                  chuCai(tenHienThi),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: mau,
                    fontSize: fontSize,
                  ),
                ),
        );
      },
    );
  }
}

class _DongCongThuc extends StatelessWidget {
  final String dau;
  final String noiDung;
  const _DongCongThuc(this.dau, this.noiDung);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              dau,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: kDo,
              ),
            ),
          ),
          Expanded(
            child: Text(
              noiDung,
              style: const TextStyle(fontSize: 13, height: 1.35, color: kDen),
            ),
          ),
        ],
      ),
    );
  }
}
