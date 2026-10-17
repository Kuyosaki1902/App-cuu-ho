import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/TrangChu_NCH.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangThaiXacThuc/controllers/trang_thai_xac_thuc_controller.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangThaiXacThuc/widgets/card_canh_bao_khoa_nhan_ca.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangThaiXacThuc/widgets/card_da_gui_yeu_cau.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangThaiXacThuc/widgets/card_thoi_gian_tham_dinh.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TrangThaiXacThucScreen extends StatelessWidget {
  final String userId;
  final bool isCoCCHN; //Thêm biến phân biệt
  const TrangThaiXacThucScreen({
    super.key,
    required this.userId,
    this.isCoCCHN = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final controller = TrangThaiXacThucController(
          userId: userId,
          isCoCCHN: isCoCCHN,
        );
        //Chuyển sang Màn hình chính Cứu hộ viên khi Admin đổi thành 'cuuho_trangthai_daduyet'
        controller.onApproved = () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hồ sơ của bạn đã được Admin phê duyệt!'),
              backgroundColor: Colors.green,
            ),
          );
          // TODO: Thay bằng Widget Màn hình chính Cứu hộ viên của bạn
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Trangchunguoicuuho()),
            (route) => false,
          );
        };

        // Chuyển sang Màn hình chính Người dùng khi Admin đổi thành 'cuuho_trangthai_tuchoi'
        controller.onRejected = () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hồ sơ xác thực đã bị từ chối.'),
              backgroundColor: Colors.red,
            ),
          );
          // TODO: Thay bằng Widget Màn hình chính Người dùng của bạn
          // Navigator.pushAndRemoveUntil(
          //   context,
          //   MaterialPageRoute(builder: (context) => const ManHinhChinhNguoiDung()),
          //   (route) => false,
          // );
        };

        return controller;
      },
      child: Consumer<TrangThaiXacThucController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Trạng thái xác thực',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 3,
                              backgroundColor: Color(0xFF137333),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              controller.trangThaiText,
                              style: const TextStyle(
                                color: Color(0xFF137333),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Hồ sơ CCHN • 115 Responder',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              actions: const [
                Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFC80815),
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CardDaGuiYeuCau(maHoSo: controller.maHoSo),
                  const SizedBox(height: 12),
                  CardThoiGianThamDinh(
                    thoiGianThamDinh: controller.thoiGianThamDinh,
                    thoiGianConLai: controller.thoiGianConLai,
                  ),
                  const SizedBox(height: 12),
                  const CardCanhBaoKhoaNhanCa(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      onPressed: controller.isRefreshing
                          ? null
                          : () => controller.listenToTrangThaiHoSo(),
                      child: controller.isRefreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Làm mới trạng thái',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
