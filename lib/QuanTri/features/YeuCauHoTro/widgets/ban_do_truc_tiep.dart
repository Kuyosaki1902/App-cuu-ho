import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/chi_tiet_yeu_cau_controller.dart';
import '../models/yeu_cau_ho_tro_model.dart';
import '../ban_do_yeu_cau_screen.dart' show KhungBanDo;

class BanDoTrucTiep extends StatelessWidget {
  final ChiTietYeuCauController controller;
  const BanDoTrucTiep({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (_, _) {
      final r = controller.request;
      if (r == null) return const Center(child: Text('Chưa có vị trí sự cố.'));
      final incident = YeuCauHoTro(r.id, r.data);
      if (!incident.hasLocation) {
        return const Center(child: Text('Chưa có tọa độ hợp lệ.'));
      }
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
        return Center(
          child: SelectableText(
            'Vị trí sự cố: ${incident.address}\nBản đồ hiển thị trên Android.',
          ),
        );
      }
      final markers = <Marker>{
        Marker(
          markerId: const MarkerId('incident'),
          position: LatLng(incident.latitude!, incident.longitude!),
          infoWindow: const InfoWindow(title: 'Vị trí sự cố'),
        ),
      };
      for (final entry in controller.people.entries) {
        final p = entry.value;
        if (p == null) continue;
        final point = YeuCauHoTro(p.id, p.data);
        if (!point.hasLocation) continue;
        markers.add(
          Marker(
            markerId: MarkerId(entry.key),
            position: LatLng(point.latitude!, point.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: InfoWindow(
              title: p.text('hoTen', p.id),
              snippet: 'Vị trí ghi nhận gần nhất',
            ),
          ),
        );
      }
      return KhungBanDo(markers: markers);
    },
  );
}
