import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThanhTich/controllers/thanh_tich_controller.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThanhTich/models/thanh_tich_model.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/XepHang/xep_hang_screen.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThanhTich/widgets/thanh_tich_common.dart';

class ThanhTichScreen extends StatelessWidget {
  final String userId;
  const ThanhTichScreen({super.key, required this.userId});

  static Future<void> mo(BuildContext context, String userId) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ThanhTichScreen(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThanhTichController(userId)..taiTatCa(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: kDen,
          elevation: 0.5,
          centerTitle: true,
          title: const Text(
            'Thành tích',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26),
          ),
        ),
        body: const _NoiDungThanhTich(),
      ),
    );
  }
}

class _NoiDungThanhTich extends StatelessWidget {
  const _NoiDungThanhTich();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThanhTichController>();

    if (c.dangTai && c.thanhTich == null)
      return const Center(child: CircularProgressIndicator());
    if (c.loi != null && c.thanhTich == null) {
      return TrangThaiRong(
        icon: Icons.wifi_off_rounded,
        tieuDe: c.loi!,
        nutText: 'Thử lại',
        onNut: c.taiTatCa,
      );
    }

    final tt = c.thanhTich;
    if (tt == null) {
      return const TrangThaiRong(
        icon: Icons.assignment_ind_outlined,
        tieuDe: 'Chưa có hồ sơ cứu hộ viên',
        moTa: 'Hoàn tất đăng ký và chờ duyệt để bắt đầu tích lũy thành tích.',
      );
    }

    return RefreshIndicator(
      onRefresh: c.taiTatCa,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _DiemCaNhan(tt: tt),
          const SizedBox(height: 14),
          _LuoiChiSo(tt: tt),
          const SizedBox(height: 20),
          const _TieuDe('HUY HIỆU'),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
            children: [for (final h in HuyHieu.tatCa) _OHuyHieu(h: h, tt: tt)],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DiemCaNhan extends StatelessWidget {
  final ThanhTichModel tt;
  const _DiemCaNhan({required this.tt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kVien),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng điểm tích luỹ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: kXam,
                ),
              ),
              NhanLoai(loai: tt.loaiHoSo),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFF59E0B),
                size: 36,
              ),
              const SizedBox(width: 8),
              Text(
                '${tt.diem}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: kDen,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'điểm',
                  style: TextStyle(fontSize: 13, color: kXam),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LuoiChiSo extends StatelessWidget {
  final ThanhTichModel tt;
  const _LuoiChiSo({required this.tt});

  @override
  Widget build(BuildContext context) {
    final tyLe = tt.tyLeNhanCa;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ChiSo(
                icon: Icons.task_alt_rounded,
                mau: const Color(0xFF059669),
                nhan: 'Ca hoàn thành',
                giaTri: '${tt.soCaHoanThanh}',
                phu: 'trên ${tt.soCaDaNhan} ca đã nhận',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ChiSo(
                icon: Icons.bolt_rounded,
                mau: const Color(0xFFCA8A04),
                nhan: 'Tỷ lệ nhận ca',
                giaTri: tyLe == null ? '--' : '${(tyLe * 100).round()}%',
                phu: '${tt.soCaDaNhan}/${tt.soCaDuocPhat} ca được phân công',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ChiSo(
                icon: Icons.star_rounded,
                mau: const Color(0xFFDB2777),
                nhan: 'Đánh giá',
                giaTri: tt.soLuotDanhGia == 0
                    ? 'Chưa có'
                    : '${tt.saoTrungBinh.toStringAsFixed(1)} ★',
                phu: '${tt.soLuotDanhGia} lượt đánh giá',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ChiSo(
                icon: Icons.warning_amber_rounded,
                mau: kDo,
                nhan: 'Ca bỏ lỡ',
                giaTri: '${tt.soCaKhongNhan}',
                phu: 'trừ 2 điểm/ca (tối đa 20)',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChiSo extends StatelessWidget {
  final IconData icon;
  final Color mau;
  final String nhan;
  final String giaTri;
  final String phu;
  const _ChiSo({
    required this.icon,
    required this.mau,
    required this.nhan,
    required this.giaTri,
    required this.phu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kVien),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: mau.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: mau, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nhan,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: kXam,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            giaTri,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: kDen,
            ),
          ),
          const SizedBox(height: 2),
          Text(phu, style: const TextStyle(fontSize: 10.5, color: kXamNhat)),
        ],
      ),
    );
  }
}

class _OHuyHieu extends StatelessWidget {
  final HuyHieu h;
  final ThanhTichModel tt;
  const _OHuyHieu({required this.h, required this.tt});

  @override
  Widget build(BuildContext context) {
    final dat = h.daDat(tt);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: dat ? h.mau.withOpacity(0.35) : kVien),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onTap: () => _hienHuyHieu(context, h, tt),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dat
                          ? h.mau.withOpacity(0.14)
                          : const Color(0xFFF1F5F9),
                    ),
                    child: Icon(
                      h.icon,
                      size: 26,
                      color: dat ? h.mau : const Color(0xFFCBD5E1),
                    ),
                  ),
                  if (!dat)
                    const Positioned(
                      right: 0,
                      bottom: 0,
                      child: Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: kXamNhat,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                h.ten,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: dat ? kDen : kXamNhat,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _hienHuyHieu(BuildContext context, HuyHieu h, ThanhTichModel tt) {
  final dat = h.daDat(tt);
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: dat
                ? h.mau.withOpacity(0.14)
                : const Color(0xFFF1F5F9),
            child: Icon(
              h.icon,
              size: 36,
              color: dat ? h.mau : const Color(0xFFCBD5E1),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            h.ten,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: kDen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            h.moTa,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.4, color: kXam),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: dat ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              dat ? 'Đã đạt' : 'Tiến độ: ${h.tienDo(tt)}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: dat ? const Color(0xFF047857) : kXam,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TieuDe extends StatelessWidget {
  final String text;
  const _TieuDe(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: kXam,
      ),
    );
  }
}
