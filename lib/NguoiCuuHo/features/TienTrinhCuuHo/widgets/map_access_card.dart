import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/rescue_process_controller.dart';

class MapAccessCard extends StatefulWidget {
  const MapAccessCard({super.key});

  @override
  State<MapAccessCard> createState() => _MapAccessCardState();
}

class _MapAccessCardState extends State<MapAccessCard> {
  BitmapDescriptor? _victimCustomIcon;
  BitmapDescriptor? _doctorBlueDotIcon;

  @override
  void initState() {
    super.initState();
    _createVictimMarkerIcon();
    _createBlueDotMarker();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RescueProcessController>().fetchRealtimeRoute();
    });
  }

  // 1. Marker nạn nhân nền trắng bo tròn icon cam
  Future<void> _createVictimMarkerIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(90, 90);
    final finalRadius = size.width / 2;

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(
      Offset(finalRadius, finalRadius + 2),
      finalRadius - 6,
      shadowPaint,
    );

    final Paint paintBg = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(finalRadius, finalRadius),
      finalRadius - 6,
      paintBg,
    );

    final Paint borderPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
      Offset(finalRadius, finalRadius),
      finalRadius - 6,
      borderPaint,
    );

    TextPainter iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
      text: String.fromCharCode(Icons.person.codePoint),
      style: TextStyle(
        fontSize: 42.0,
        fontFamily: Icons.person.fontFamily,
        color: const Color(0xFFF97316),
      ),
    );
    iconPainter.layout();
    iconPainter.paint(canvas, Offset(finalRadius - 21, finalRadius - 21));

    final image = await recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (mounted && byteData != null) {
      setState(() {
        _victimCustomIcon = BitmapDescriptor.fromBytes(
          byteData.buffer.asUint8List(),
        );
      });
    }
  }

  // 2. Chấm xanh định vị kèm hào quang GPS cho Bác sĩ
  Future<void> _createBlueDotMarker() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(140, 140);
    final center = Offset(size.width / 2, size.height / 2);

    final Paint outerHaloPaint = Paint()
      ..color = const Color(0xFF2196F3).withOpacity(0.18)
      ..style = PaintingStyle.fill;

    final Paint outerHaloBorder = Paint()
      ..color = const Color(0xFF2196F3).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, 55.0, outerHaloPaint);
    canvas.drawCircle(center, 55.0, outerHaloBorder);

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawCircle(center + const Offset(0, 2), 14.0, shadowPaint);

    final Paint innerDotPaint = Paint()
      ..color = const Color(0xFF1976D2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 14.0, innerDotPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, 14.0, borderPaint);

    final image = await recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (mounted && byteData != null) {
      setState(() {
        _doctorBlueDotIcon = BitmapDescriptor.fromBytes(
          byteData.buffer.asUint8List(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RescueProcessController>();

    LatLng initialTarget = (controller.doctorLocation.latitude != 0.0)
        ? controller.doctorLocation
        : const LatLng(10.762622, 106.660172);

    final Set<Marker> markers = {
      if (controller.doctorLocation.latitude != 0.0)
        Marker(
          markerId: const MarkerId('doctor'),
          position: controller.doctorLocation,
          icon:
              _doctorBlueDotIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(title: controller.doctorName),
        ),
      if (controller.victimLocation.latitude != 0.0)
        Marker(
          markerId: const MarkerId('victim'),
          position: controller.victimLocation,
          anchor: const Offset(0.5, 0.5),
          icon:
              _victimCustomIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          infoWindow: InfoWindow(title: controller.victimName),
        ),
    };

    final Set<Polyline> polylines = {
      Polyline(
        polylineId: const PolylineId('real_osrm_route'),
        points: controller.polylineCoordinates.isNotEmpty
            ? controller.polylineCoordinates
            : [
                if (controller.doctorLocation.latitude != 0.0 &&
                    controller.victimLocation.latitude != 0.0)
                  controller.doctorLocation,
                if (controller.doctorLocation.latitude != 0.0 &&
                    controller.victimLocation.latitude != 0.0)
                  controller.victimLocation,
              ],
        color: const Color(0xFFDC2626),
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialTarget,
            zoom: 15.5,
          ),
          markers: markers,
          polylines: polylines,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          onMapCreated: (mapCtrl) {
            controller.mapController = mapCtrl;
            if (controller.doctorLocation.latitude != 0.0) {
              mapCtrl.animateCamera(
                CameraUpdate.newLatLngZoom(controller.doctorLocation, 15.5),
              );
            }
          },
        ),
      ),
    );
  }
}
