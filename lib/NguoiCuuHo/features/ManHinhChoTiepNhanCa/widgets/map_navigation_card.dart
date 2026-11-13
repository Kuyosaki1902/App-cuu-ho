import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/emergency_alert_controller.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TienTrinhCuuHo/widgets/alert_style.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TienTrinhCuuHo/widgets/rescue_theme.dart';

/// Bản đồ phủ toàn vùng nội dung, kèm 3 nút thật (vị trí của tôi, xem toàn tuyến, dẫn đường).
class MapNavigationCard extends StatefulWidget {
  const MapNavigationCard({super.key});

  @override
  State<MapNavigationCard> createState() => _MapNavigationCardState();
}

class _MapNavigationCardState extends State<MapNavigationCard> {
  BitmapDescriptor? _victimIcon;
  int? _iconForLevel;
  GoogleMapController? _mapCtrl;
  late final EmergencyAlertController _alert;

  @override
  void initState() {
    super.initState();
    _alert = context.read<EmergencyAlertController>();
  }

  @override
  void dispose() {
    if (identical(_alert.mapController, _mapCtrl)) {
      _alert.mapController = null;
    }
    super.dispose();
  }

  Future<void> _buildVictimIcon(int mucDo) async {
    _iconForLevel = mucDo;
    final color = AlertStyle.of(mucDo).color;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(96, 96);
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
      center + const Offset(0, 2),
      38,
      Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(center, 38, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      38,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    final painter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(Icons.person.codePoint),
        style: TextStyle(
          fontSize: 44,
          fontFamily: Icons.person.fontFamily,
          color: color,
        ),
      )
      ..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );

    final image = await recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (mounted && bytes != null && _iconForLevel == mucDo) {
      setState(() {
        _victimIcon = BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
      });
    }
  }

  Widget _mapButton(IconData icon, String tip, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Tooltip(
        message: tip,
        child: Material(
          color: Colors.white,
          elevation: 3,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, color: RC.ink, size: 21),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EmergencyAlertController>();
    final style = AlertStyle.of(c.mucDoKhanCap);
    if (_iconForLevel != c.mucDoKhanCap) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _buildVictimIcon(c.mucDoKhanCap);
      });
    }

    final target = c.hasVictimLocation
        ? c.victimLocation
        : (c.hasMyLocation
              ? c.myLocation
              : const LatLng(10.762622, 106.660172));

    final markers = <Marker>{
      // Chỉ vẽ marker khi đã có toạ độ (bản cũ vẽ cả tại 0,0 ngoài khơi châu Phi).
      if (c.hasVictimLocation)
        Marker(
          markerId: const MarkerId('victim'),
          position: c.victimLocation,
          icon:
              _victimIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                c.mucDoKhanCap == 1
                    ? BitmapDescriptor.hueRed
                    : BitmapDescriptor.hueOrange,
              ),
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: c.victimName,
            snippet: c.isVictimLocationApproximate ? 'Vị trí gần đúng' : null,
          ),
        ),
    };

    final polylines = <Polyline>{
      if (c.polylineCoordinates.length >= 2) ...[
        Polyline(
          polylineId: const PolylineId('route_casing'),
          points: c.polylineCoordinates,
          color: Colors.white,
          width: 9,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
        Polyline(
          polylineId: const PolylineId('route'),
          points: c.polylineCoordinates,
          color: style.color,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      ],
    };

    final topInset = MediaQuery.of(context).padding.top;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: target,
                  zoom: 15.5,
                ),
                padding: EdgeInsets.only(
                  top: 90 + topInset,
                  bottom: constraints.maxHeight * 0.52,
                ),
                markers: markers,
                polylines: polylines,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                myLocationEnabled: c.hasGpsFix,
                myLocationButtonEnabled: false,
                onMapCreated: (ctrl) {
                  _mapCtrl = ctrl;
                  c.mapController = ctrl;
                  c.fitMapBounds();
                },
              ),
            ),
            Positioned(
              right: 12,
              top: topInset + 92,
              child: Column(
                children: [
                  _mapButton(Icons.my_location, 'Vị trí của tôi', c.focusMe),
                  _mapButton(
                    Icons.zoom_out_map,
                    'Xem toàn tuyến',
                    c.fitMapBounds,
                  ),
                  _mapButton(
                    Icons.navigation,
                    'Dẫn đường bằng Google Maps',
                    c.openExternalNavigation,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
